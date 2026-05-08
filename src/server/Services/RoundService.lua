local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundConfig = require(ReplicatedStorage.Configs.RoundConfig)

local REMOTE_FOLDER_NAME = "RemoteEvents"
local ROUND_STATUS_EVENT_NAME = "RoundStatusUpdate"

local Local = {}
local Shared = {}

Local.CurrentState = {
    phase = "Booting",
    status = "Starting game...",
    timeRemaining = 0,
}

-- Creates a standard Roblox RemoteEvent under ReplicatedStorage so clients can
-- listen for server-controlled round updates after Rojo syncs the project.
function Local.GetRoundStatusEvent(): RemoteEvent
    local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
    if not remoteFolder then
        remoteFolder = Instance.new("Folder")
        remoteFolder.Name = REMOTE_FOLDER_NAME
        remoteFolder.Parent = ReplicatedStorage
    end

    local roundStatusEvent = remoteFolder:FindFirstChild(ROUND_STATUS_EVENT_NAME)
    if not roundStatusEvent then
        roundStatusEvent = Instance.new("RemoteEvent")
        roundStatusEvent.Name = ROUND_STATUS_EVENT_NAME
        roundStatusEvent.Parent = remoteFolder
    end

    return roundStatusEvent :: RemoteEvent
end

function Local.BroadcastState(phase: string, status: string, timeRemaining: number)
    Local.CurrentState = {
        phase = phase,
        status = status,
        timeRemaining = timeRemaining,
    }

    Local.RoundStatusEvent:FireAllClients(Local.CurrentState)
    print(`[RoundService] {status}: {timeRemaining}s remaining`)
end

function Local.SendStateToPlayer(player: Player)
    Local.RoundStatusEvent:FireClient(player, Local.CurrentState)
end

function Local.RunTimer(phase: string, status: string, duration: number)
    for timeRemaining = duration, 0, -1 do
        Local.BroadcastState(phase, status, timeRemaining)
        task.wait(1)
    end
end

function Local.RunRoundLoop()
    while true do
        Local.RunTimer("Intermission", RoundConfig.IntermissionStatus, RoundConfig.IntermissionDuration)
        Local.RunTimer("Round", RoundConfig.RoundStatus, RoundConfig.RoundDuration)
    end
end

function Shared.OnStart()
    Local.RoundStatusEvent = Local.GetRoundStatusEvent()

    Players.PlayerAdded:Connect(Local.SendStateToPlayer)
    for _, player in Players:GetPlayers() do
        Local.SendStateToPlayer(player)
    end

    print("[RoundService] Initialized simple round loop.")
    task.spawn(Local.RunRoundLoop)
end

return Shared
