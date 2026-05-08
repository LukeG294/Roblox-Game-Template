local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_FOLDER_NAME = "RemoteEvents"
local ROUND_STATUS_EVENT_NAME = "RoundStatusUpdate"

local Player = Players.LocalPlayer

local Local = {}
local Shared = {}

function Local.FormatTime(totalSeconds: number): string
    local safeSeconds = math.max(0, math.floor(totalSeconds))
    local minutes = math.floor(safeSeconds / 60)
    local seconds = safeSeconds % 60

    return string.format("%02d:%02d", minutes, seconds)
end

function Local.CreateStatusGui(): ScreenGui
    local playerGui = Player:WaitForChild("PlayerGui")

    local existingGui = playerGui:FindFirstChild("RoundStatusGui")
    if existingGui then
        return existingGui :: ScreenGui
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RoundStatusGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = playerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.Position = UDim2.fromScale(0.5, 0.04)
    panel.Size = UDim2.fromOffset(320, 86)
    panel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
    panel.BackgroundTransparency = 0.1
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.BackgroundTransparency = 1
    statusLabel.Position = UDim2.fromOffset(16, 10)
    statusLabel.Size = UDim2.new(1, -32, 0, 34)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.Text = "Loading round..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.TextScaled = true
    statusLabel.Parent = panel

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.BackgroundTransparency = 1
    timerLabel.Position = UDim2.fromOffset(16, 48)
    timerLabel.Size = UDim2.new(1, -32, 0, 26)
    timerLabel.Font = Enum.Font.Gotham
    timerLabel.Text = "00:00"
    timerLabel.TextColor3 = Color3.fromRGB(165, 220, 255)
    timerLabel.TextScaled = true
    timerLabel.Parent = panel

    return screenGui
end

function Local.UpdateStatusGui(state)
    Local.StatusLabel.Text = state.status or "Waiting for round..."
    Local.TimerLabel.Text = Local.FormatTime(state.timeRemaining or 0)
end

function Shared.OnStart()
    local gui = Local.CreateStatusGui()
    local panel = gui:WaitForChild("Panel")
    Local.StatusLabel = panel:WaitForChild("StatusLabel")
    Local.TimerLabel = panel:WaitForChild("TimerLabel")

    local remoteFolder = ReplicatedStorage:WaitForChild(REMOTE_FOLDER_NAME)
    local roundStatusEvent = remoteFolder:WaitForChild(ROUND_STATUS_EVENT_NAME)

    roundStatusEvent.OnClientEvent:Connect(Local.UpdateStatusGui)

    print("[RoundStatusController] UI initialized and listening for round updates.")
end

return Shared
