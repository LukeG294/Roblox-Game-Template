local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Shared = {}

-- Creates the whole MVP HUD from code so Rojo/Studio never need a prebuilt ScreenGui.
function Shared.GetHud(): ScreenGui
    local existingGui = PlayerGui:FindFirstChild("HackySackHud")
    if existingGui then
        return existingGui :: ScreenGui
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HackySackHud"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.Parent = PlayerGui

    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.Position = UDim2.fromScale(0.5, 0.04)
    panel.Size = UDim2.fromOffset(380, 230)
    panel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0
    panel.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = panel

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 14)
    padding.PaddingBottom = UDim.new(0, 14)
    padding.PaddingLeft = UDim.new(0, 18)
    padding.PaddingRight = UDim.new(0, 18)
    padding.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = panel

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.LayoutOrder = 1
    titleLabel.BackgroundTransparency = 1
    titleLabel.Size = UDim2.new(1, 0, 0, 28)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Text = "Hacky Sack MVP"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextScaled = true
    titleLabel.Parent = panel

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.LayoutOrder = 2
    statusLabel.BackgroundTransparency = 1
    statusLabel.Size = UDim2.new(1, 0, 0, 34)
    statusLabel.Font = Enum.Font.GothamSemibold
    statusLabel.Text = "Connecting to round service..."
    statusLabel.TextColor3 = Color3.fromRGB(255, 241, 178)
    statusLabel.TextScaled = true
    statusLabel.Parent = panel

    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "TimerLabel"
    timerLabel.LayoutOrder = 3
    timerLabel.BackgroundTransparency = 1
    timerLabel.Size = UDim2.new(1, 0, 0, 26)
    timerLabel.Font = Enum.Font.Gotham
    timerLabel.Text = "Timer: 00:00"
    timerLabel.TextColor3 = Color3.fromRGB(165, 220, 255)
    timerLabel.TextScaled = true
    timerLabel.Parent = panel

    local juggleLabel = Instance.new("TextLabel")
    juggleLabel.Name = "JuggleLabel"
    juggleLabel.LayoutOrder = 4
    juggleLabel.BackgroundTransparency = 1
    juggleLabel.Size = UDim2.new(1, 0, 0, 26)
    juggleLabel.Font = Enum.Font.Gotham
    juggleLabel.Text = "Juggles: 0"
    juggleLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
    juggleLabel.TextScaled = true
    juggleLabel.Parent = panel

    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name = "CoinsLabel"
    coinsLabel.LayoutOrder = 5
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Size = UDim2.new(1, 0, 0, 26)
    coinsLabel.Font = Enum.Font.Gotham
    coinsLabel.Text = "Coins: 0"
    coinsLabel.TextColor3 = Color3.fromRGB(255, 225, 96)
    coinsLabel.TextScaled = true
    coinsLabel.Parent = panel

    local joinButton = Instance.new("TextButton")
    joinButton.Name = "JoinRoundButton"
    joinButton.LayoutOrder = 6
    joinButton.Size = UDim2.new(1, 0, 0, 42)
    joinButton.BackgroundColor3 = Color3.fromRGB(47, 145, 255)
    joinButton.BorderSizePixel = 0
    joinButton.Font = Enum.Font.GothamBold
    joinButton.Text = "Join Round"
    joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinButton.TextScaled = true
    joinButton.Parent = panel

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 10)
    buttonCorner.Parent = joinButton

    local hintLabel = Instance.new("TextLabel")
    hintLabel.Name = "HintLabel"
    hintLabel.LayoutOrder = 7
    hintLabel.BackgroundTransparency = 1
    hintLabel.Size = UDim2.new(1, 0, 0, 24)
    hintLabel.Font = Enum.Font.Gotham
    hintLabel.Text = "Press E near the sack to juggle before it drops."
    hintLabel.TextColor3 = Color3.fromRGB(210, 220, 235)
    hintLabel.TextScaled = true
    hintLabel.Parent = panel

    return screenGui
end

return Shared
