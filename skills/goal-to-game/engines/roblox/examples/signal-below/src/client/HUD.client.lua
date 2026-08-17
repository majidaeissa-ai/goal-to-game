local ReplicatedStorage = game:GetService("ReplicatedStorage")
local state = ReplicatedStorage:WaitForChild("SignalBelowState")

local gui = Instance.new("ScreenGui")
gui.Name = "SignalBelowHUD"
gui.ResetOnSpawn = false
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(330, 58)
label.Position = UDim2.fromOffset(24, 24)
label.BackgroundTransparency = 0.18
label.TextScaled = true
label.Parent = gui

local function refresh()
    label.Text = ("RELAYS %d/4   TIME %03d"):format(
        state:GetAttribute("RelaysRestored") or 0,
        state:GetAttribute("RoundSeconds") or 0
    )
end
state.AttributeChanged:Connect(refresh)
refresh()
