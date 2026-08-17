local ReplicatedStorage = game:GetService("ReplicatedStorage")
local state = ReplicatedStorage:WaitForChild("SkylineRelayState")

local gui = Instance.new("ScreenGui")
gui.Name = "SkylineRelayHUD"
gui.ResetOnSpawn = false
gui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local label = Instance.new("TextLabel")
label.Size = UDim2.fromOffset(360, 58)
label.Position = UDim2.fromOffset(24, 24)
label.BackgroundTransparency = 0.18
label.TextScaled = true
label.Parent = gui

local function refresh()
    label.Text = ("CHECKPOINT %d/7   %03ds"):format(
        state:GetAttribute("Checkpoint") or 0,
        state:GetAttribute("TimeLeft") or 0
    )
end
state.AttributeChanged:Connect(refresh)
refresh()
