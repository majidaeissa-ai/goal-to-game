local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local state = ReplicatedStorage:WaitForChild("SignalBelowState")
local gui = Instance.new("ScreenGui")
gui.Name = "SignalBelowHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(430, 142)
panel.Position = UDim2.fromOffset(28, 28)
panel.BackgroundColor3 = Color3.fromRGB(5, 12, 20)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(43, 164, 210)
stroke.Thickness = 2

local function text(name, position, size, font, color, scaled)
    local value = Instance.new("TextLabel")
    value.Name = name
    value.Position = position
    value.Size = size
    value.BackgroundTransparency = 1
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Font = font
    value.TextColor3 = color
    value.TextScaled = scaled
    value.Parent = panel
    return value
end

local title = text("Title", UDim2.fromOffset(18, 12), UDim2.fromOffset(394, 34), Enum.Font.GothamBlack, Color3.fromRGB(225, 245, 255), true)
title.Text = "SIGNAL BELOW"
local progress = text("Progress", UDim2.fromOffset(18, 52), UDim2.fromOffset(245, 28), Enum.Font.GothamBold, Color3.fromRGB(75, 220, 255), true)
local timer = text("Timer", UDim2.fromOffset(285, 52), UDim2.fromOffset(126, 28), Enum.Font.RobotoMono, Color3.fromRGB(255, 205, 80), true)
timer.TextXAlignment = Enum.TextXAlignment.Right
local objective = text("Objective", UDim2.fromOffset(18, 92), UDim2.fromOffset(394, 34), Enum.Font.GothamMedium, Color3.fromRGB(195, 215, 225), false)
objective.TextSize = 17
objective.TextWrapped = true

local banner = Instance.new("TextLabel")
banner.Name = "EndState"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.46)
banner.Size = UDim2.fromOffset(650, 125)
banner.BackgroundColor3 = Color3.fromRGB(5, 12, 20)
banner.BackgroundTransparency = 1
banner.TextTransparency = 1
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.TextWrapped = true
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)

local retry = Instance.new("TextButton")
retry.Name = "Retry"
retry.AnchorPoint = Vector2.new(0.5, 0)
retry.Position = UDim2.fromScale(0.5, 0.58)
retry.Size = UDim2.fromOffset(240, 52)
retry.BackgroundColor3 = Color3.fromRGB(30, 130, 165)
retry.Text = "RESTART SEQUENCE"
retry.TextColor3 = Color3.new(1, 1, 1)
retry.Font = Enum.Font.GothamBold
retry.TextScaled = true
retry.Visible = false
retry.Parent = gui
Instance.new("UICorner", retry).CornerRadius = UDim.new(0, 8)
retry.Activated:Connect(function() state.RequestRetry:FireServer() end)

local lastPhase = ""
local function refresh()
    local count = state:GetAttribute("RelaysRestored") or 0
    local seconds = state:GetAttribute("RoundSeconds") or 0
    local phase = state:GetAttribute("Phase") or "Repair"
    progress.Text = ("RELAYS RESTORED   %d / 4"):format(count)
    timer.Text = ("%02d:%02d"):format(math.floor(seconds / 60), seconds % 60)
    objective.Text = state:GetAttribute("Objective") or "Reach the perimeter relays"
    timer.TextColor3 = seconds <= 30 and Color3.fromRGB(255, 80, 70) or Color3.fromRGB(255, 205, 80)
    stroke.Color = phase == "Victory" and Color3.fromRGB(50, 255, 150) or (phase == "Failed" and Color3.fromRGB(255, 60, 55) or Color3.fromRGB(43, 164, 210))
    if phase ~= lastPhase and (phase == "Victory" or phase == "Failed") then
        banner.Text = phase == "Victory" and "SIGNAL LOCKED\nRESCUE BEACON ACQUIRED" or "SIGNAL LOST\nTHE STATION WENT DARK"
        banner.TextColor3 = phase == "Victory" and Color3.fromRGB(65, 255, 155) or Color3.fromRGB(255, 75, 65)
        retry.Visible = true
        TweenService:Create(banner, TweenInfo.new(0.5), {BackgroundTransparency = 0.08, TextTransparency = 0}):Play()
    elseif phase == "Repair" then
        retry.Visible = false
        banner.BackgroundTransparency = 1
        banner.TextTransparency = 1
    end
    lastPhase = phase
end
state.AttributeChanged:Connect(refresh)
refresh()
