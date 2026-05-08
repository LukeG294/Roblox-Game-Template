local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Store = require(ServerScriptService.Store)

local REMOTE_FOLDER_NAME = "Remotes"
local JOIN_ROUND_EVENT_NAME = "JoinRound"
local ROUND_STATE_EVENT_NAME = "RoundStateUpdate"
local CURRENCY_EVENT_NAME = "CurrencyUpdate"

local Local = {}
local Shared = {}

Local.Phase = "Lobby"
Local.TimeRemaining = 0
Local.RoundId = 0
Local.JoinedPlayers = {}
Local.ActivePlayers = {}
Local.PlayerSacks = {}
Local.JuggleCounts = {}
Local.DropDeadlines = {}

-- Remotes are created by the server so the game never depends on Studio-only objects.
function Local.GetRemoteEvent(name: string): RemoteEvent
    local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = REMOTE_FOLDER_NAME
        remoteFolder.Parent = ReplicatedStorage
    end

    local remoteEvent = remoteFolder:FindFirstChild(name)
    if not remoteEvent then
        remoteEvent = Instance.new("RemoteEvent")
        remoteEvent.Name = name
        remoteEvent.Parent = remoteFolder
    end

    return remoteEvent :: RemoteEvent
end

function Local.GetPlayerFromUserId(userId: number): Player?
    return Players:GetPlayerByUserId(userId)
end

function Local.CountDictionary(dictionary): number
    local count = 0
    for _ in dictionary do
        count += 1
    end
    return count
end

function Local.BuildPlayerPayload(player: Player)
    local userId = player.UserId

    return {
        phase = Local.Phase,
        status = Local.GetStatusText(),
        timeRemaining = Local.TimeRemaining,
        joined = Local.JoinedPlayers[userId] == true or Local.ActivePlayers[userId] == true,
        inRound = Local.ActivePlayers[userId] == true,
        juggleCount = Local.JuggleCounts[userId] or 0,
        queuedCount = Local.CountDictionary(Local.JoinedPlayers),
        activeCount = Local.CountDictionary(Local.ActivePlayers),
    }
end

function Local.GetStatusText(): string
    if Local.Phase == "Lobby" then
        return "Lobby - click Join Round to play"
    elseif Local.Phase == "Intermission" then
        return "Round starting soon"
    elseif Local.Phase == "Round" then
        return "Juggle the hacky sack!"
    elseif Local.Phase == "RoundEnded" then
        return "Round ended"
    end

    return "Loading..."
end

function Local.SendState(player: Player)
    Local.RoundStateUpdate:FireClient(player, Local.BuildPlayerPayload(player))
end

function Local.BroadcastState()
    for _, player in Players:GetPlayers() do
        Local.SendState(player)
    end
end

function Local.AwardCoins(player: Player, amount: number)
    if amount <= 0 then
        return
    end

    Store.updateBalance(tostring(player.UserId), "coins", amount)
    Local.CurrencyUpdate:FireClient(player, {
        coinsAwarded = amount,
        reason = "Juggle",
    })
end

function Local.DestroySack(player: Player)
    local sack = Local.PlayerSacks[player.UserId]
    if sack then
        sack:Destroy()
    end

    Local.PlayerSacks[player.UserId] = nil
end

function Local.EndPlayerRound(player: Player, reason: string)
    local userId = player.UserId
    if not Local.ActivePlayers[userId] then
        return
    end

    Local.ActivePlayers[userId] = nil
    Local.DropDeadlines[userId] = nil
    Local.DestroySack(player)

    Local.RoundStateUpdate:FireClient(player, {
        phase = Local.Phase,
        status = reason,
        timeRemaining = Local.TimeRemaining,
        joined = false,
        inRound = false,
        juggleCount = Local.JuggleCounts[userId] or 0,
        queuedCount = Local.CountDictionary(Local.JoinedPlayers),
        activeCount = Local.CountDictionary(Local.ActivePlayers),
    })

    Local.BroadcastState()
end

function Local.GetSpawnCFrame(player: Player): CFrame
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if rootPart and rootPart:IsA("BasePart") then
        return rootPart.CFrame * CFrame.new(0, 2, -5)
    end

    return CFrame.new(0, 8, 0)
end

function Local.Juggle(player: Player)
    local userId = player.UserId
    if Local.Phase ~= "Round" or not Local.ActivePlayers[userId] then
        return
    end

    local sack = Local.PlayerSacks[userId]
    if not sack or not sack.Parent then
        return
    end

    Local.JuggleCounts[userId] = (Local.JuggleCounts[userId] or 0) + 1
    Local.DropDeadlines[userId] = os.clock() + GameConfig.DropTimeout

    -- Coins are only awarded from real server-validated juggle interactions.
    Local.AwardCoins(player, GameConfig.CoinsPerJuggle)

    local spawnCFrame = Local.GetSpawnCFrame(player)
    sack.AssemblyLinearVelocity = Vector3.new(0, GameConfig.SackBounceVelocity, 0)
    sack.CFrame = spawnCFrame

    Local.SendState(player)
end

function Local.SpawnSack(player: Player)
    Local.DestroySack(player)

    local sack = Instance.new("Part")
    sack.Name = `HackySack_{player.UserId}`
    sack.Shape = Enum.PartType.Ball
    sack.Size = Vector3.new(GameConfig.SackSize, GameConfig.SackSize, GameConfig.SackSize)
    sack.Color = GameConfig.SackColor
    sack.Material = Enum.Material.SmoothPlastic
    sack.CanCollide = true
    sack.Anchored = false
    sack.CFrame = Local.GetSpawnCFrame(player)
    sack.Parent = Workspace
    sack:SetNetworkOwner(nil)

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "JugglePrompt"
    prompt.ActionText = "Juggle"
    prompt.ObjectText = "Hacky Sack"
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = GameConfig.JugglePromptDistance
    prompt.RequiresLineOfSight = false
    prompt.Parent = sack

    prompt.Triggered:Connect(function(triggeringPlayer)
        if triggeringPlayer == player then
            Local.Juggle(player)
        end
    end)

    sack.Touched:Connect(function(hit)
        if Local.Phase ~= "Round" or not Local.ActivePlayers[player.UserId] then
            return
        end

        if hit:IsA("BasePart") and hit.Name == "Baseplate" then
            Local.EndPlayerRound(player, "Dropped! Click Join Round to try again.")
        end
    end)

    Local.PlayerSacks[player.UserId] = sack
end

function Local.StartRound()
    Local.Phase = "Round"
    Local.RoundId += 1
    Local.ActivePlayers = Local.JoinedPlayers
    Local.JoinedPlayers = {}

    for userId in Local.ActivePlayers do
        local player = Local.GetPlayerFromUserId(userId)
        if player then
            Local.JuggleCounts[userId] = 0
            Local.DropDeadlines[userId] = os.clock() + GameConfig.DropTimeout
            Local.SpawnSack(player)
        else
            Local.ActivePlayers[userId] = nil
        end
    end

    for timeRemaining = GameConfig.RoundDuration, 0, -1 do
        Local.TimeRemaining = timeRemaining
        Local.BroadcastState()

        local now = os.clock()
        for userId in Local.ActivePlayers do
            local player = Local.GetPlayerFromUserId(userId)
            if not player then
                Local.ActivePlayers[userId] = nil
            elseif (Local.DropDeadlines[userId] or 0) <= now then
                Local.EndPlayerRound(player, "Missed too long! Click Join Round to try again.")
            end
        end

        if Local.CountDictionary(Local.ActivePlayers) == 0 then
            break
        end

        task.wait(1)
    end

    for userId in Local.ActivePlayers do
        local player = Local.GetPlayerFromUserId(userId)
        if player then
            Local.EndPlayerRound(player, "Time's up! Click Join Round to play again.")
        end
    end

    Local.ActivePlayers = {}
    Local.Phase = "RoundEnded"
    Local.TimeRemaining = 0
    Local.BroadcastState()
    task.wait(GameConfig.PostRoundDelay)
end

function Local.RunRoundLoop()
    while true do
        Local.Phase = "Lobby"
        Local.TimeRemaining = 0
        Local.BroadcastState()

        while Local.CountDictionary(Local.JoinedPlayers) == 0 do
            task.wait(0.5)
        end

        Local.Phase = "Intermission"
        for timeRemaining = GameConfig.IntermissionDuration, 0, -1 do
            Local.TimeRemaining = timeRemaining
            Local.BroadcastState()
            task.wait(1)
        end

        if Local.CountDictionary(Local.JoinedPlayers) > 0 then
            Local.StartRound()
        end
    end
end

function Local.JoinRound(player: Player)
    if Local.Phase == "Round" then
        Local.RoundStateUpdate:FireClient(player, {
            phase = Local.Phase,
            status = "Round already in progress - wait for the next one!",
            timeRemaining = Local.TimeRemaining,
            joined = false,
            inRound = false,
            juggleCount = Local.JuggleCounts[player.UserId] or 0,
            queuedCount = Local.CountDictionary(Local.JoinedPlayers),
            activeCount = Local.CountDictionary(Local.ActivePlayers),
        })
        return
    end

    Local.JoinedPlayers[player.UserId] = true
    Local.JuggleCounts[player.UserId] = 0
    Local.SendState(player)
    Local.BroadcastState()
end

function Local.RemovePlayer(player: Player)
    Local.JoinedPlayers[player.UserId] = nil
    Local.ActivePlayers[player.UserId] = nil
    Local.JuggleCounts[player.UserId] = nil
    Local.DropDeadlines[player.UserId] = nil
    Local.DestroySack(player)
end

function Shared.OnStart()
    Local.JoinRoundEvent = Local.GetRemoteEvent(JOIN_ROUND_EVENT_NAME)
    Local.RoundStateUpdate = Local.GetRemoteEvent(ROUND_STATE_EVENT_NAME)
    Local.CurrencyUpdate = Local.GetRemoteEvent(CURRENCY_EVENT_NAME)

    Local.JoinRoundEvent.OnServerEvent:Connect(Local.JoinRound)
    Players.PlayerAdded:Connect(Local.SendState)
    Players.PlayerRemoving:Connect(Local.RemovePlayer)

    for _, player in Players:GetPlayers() do
        Local.SendState(player)
    end

    print("[RoundService] Hacky sack round loop initialized.")
    task.spawn(Local.RunRoundLoop)
end

return Shared
