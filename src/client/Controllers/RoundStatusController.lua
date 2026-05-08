local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiController = require(script.Parent.GuiController)

local REMOTE_FOLDER_NAME = "Remotes"
local JOIN_ROUND_EVENT_NAME = "JoinRound"
local ROUND_STATE_EVENT_NAME = "RoundStateUpdate"
local CURRENCY_EVENT_NAME = "CurrencyUpdate"

local Player = Players.LocalPlayer

local Local = {}
local Shared = {}

function Local.FormatTime(totalSeconds: number): string
    local safeSeconds = math.max(0, math.floor(totalSeconds or 0))
    local minutes = math.floor(safeSeconds / 60)
    local seconds = safeSeconds % 60

    return string.format("%02d:%02d", minutes, seconds)
end

function Local.SetJoinButtonEnabled(enabled: boolean, text: string?)
    Local.JoinButton.Active = enabled
    Local.JoinButton.AutoButtonColor = enabled
    Local.JoinButton.Text = text or "Join Round"
    Local.JoinButton.BackgroundColor3 = if enabled then Color3.fromRGB(47, 145, 255) else Color3.fromRGB(90, 98, 110)
end

function Local.UpdateCoinsFromLeaderstats()
    local leaderstats = Player:FindFirstChild("leaderstats")
    local coins = leaderstats and leaderstats:FindFirstChild("Coins")

    if coins and coins:IsA("NumberValue") then
        Local.CoinsLabel.Text = `Coins: {coins.Value}`
    end
end

function Local.HookLeaderstats()
    local function hookCoins(coins)
        if coins and coins:IsA("NumberValue") then
            Local.UpdateCoinsFromLeaderstats()
            coins.Changed:Connect(Local.UpdateCoinsFromLeaderstats)
        end
    end

    local leaderstats = Player:FindFirstChild("leaderstats")
    if leaderstats then
        hookCoins(leaderstats:FindFirstChild("Coins"))
        leaderstats.ChildAdded:Connect(function(child)
            if child.Name == "Coins" then
                hookCoins(child)
            end
        end)
    end

    Player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            hookCoins(child:FindFirstChild("Coins"))
            child.ChildAdded:Connect(function(grandchild)
                if grandchild.Name == "Coins" then
                    hookCoins(grandchild)
                end
            end)
        end
    end)
end

function Local.UpdateStatusGui(state)
    Local.StatusLabel.Text = state.status or "Waiting for round..."
    Local.TimerLabel.Text = `Timer: {Local.FormatTime(state.timeRemaining)}`
    Local.JuggleLabel.Text = `Juggles: {state.juggleCount or 0}`

    if state.inRound then
        Local.SetJoinButtonEnabled(false, "In Round")
    elseif state.joined then
        Local.SetJoinButtonEnabled(false, "Joined")
    elseif state.phase == "Round" then
        Local.SetJoinButtonEnabled(false, "Round Active")
    else
        Local.SetJoinButtonEnabled(true, "Join Round")
    end
end

function Local.ConnectRemotes()
    local remoteFolder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME, 10)
    if not remoteFolder then
        Local.StatusLabel.Text = "Round remotes not found. Is the server running?"
        warn("[RoundStatusController] ReplicatedStorage.Remotes was not created by the server.")
        return
    end

    local joinRoundEvent = remoteFolder:WaitForChild(JOIN_ROUND_EVENT_NAME, 10)
    local roundStateUpdate = remoteFolder:WaitForChild(ROUND_STATE_EVENT_NAME, 10)
    local currencyUpdate = remoteFolder:WaitForChild(CURRENCY_EVENT_NAME, 10)

    if not joinRoundEvent or not roundStateUpdate then
        Local.StatusLabel.Text = "Round remotes are incomplete."
        warn("[RoundStatusController] Missing JoinRound or RoundStateUpdate RemoteEvent.")
        return
    end

    Local.JoinButton.MouseButton1Click:Connect(function()
        Local.SetJoinButtonEnabled(false, "Joining...")
        joinRoundEvent:FireServer()
    end)

    roundStateUpdate.OnClientEvent:Connect(Local.UpdateStatusGui)

    if currencyUpdate then
        currencyUpdate.OnClientEvent:Connect(function()
            Local.UpdateCoinsFromLeaderstats()
        end)
    end
end

function Shared.OnStart()
    local gui = GuiController.GetHud()
    local panel = gui:WaitForChild("Panel")

    Local.StatusLabel = panel:WaitForChild("StatusLabel")
    Local.TimerLabel = panel:WaitForChild("TimerLabel")
    Local.JuggleLabel = panel:WaitForChild("JuggleLabel")
    Local.CoinsLabel = panel:WaitForChild("CoinsLabel")
    Local.JoinButton = panel:WaitForChild("JoinRoundButton")

    Local.HookLeaderstats()
    Local.UpdateCoinsFromLeaderstats()
    Local.ConnectRemotes()

    print("[RoundStatusController] Hacky sack HUD initialized.")
end

return Shared
