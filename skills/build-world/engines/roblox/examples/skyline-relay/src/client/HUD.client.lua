local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)
local player = Players.LocalPlayer
local stateRoot = ReplicatedStorage:WaitForChild("SkylineRelayState")
local state = stateRoot:WaitForChild("Players"):WaitForChild(tostring(player.UserId))
local checkpoints = workspace:WaitForChild(Config.RuntimeName):WaitForChild("Checkpoints")
local checkpointViews = {}
for index = 1, Config.CheckpointCount do
    local model = checkpoints:WaitForChild(("Checkpoint_%02d"):format(index))
    local gateBeam = model:WaitForChild("GateBeam")
    checkpointViews[index] = {
        Model = model,
        Pad = model:WaitForChild("Pad"),
        GateBeam = gateBeam,
        Label = gateBeam:WaitForChild("CheckpointLabel"):WaitForChild("Text"),
    }
end

local CYAN = Color3.fromRGB(50, 225, 255)
local GOLD = Color3.fromRGB(255, 194, 72)
local GREEN = Color3.fromRGB(67, 255, 157)
local RED = Color3.fromRGB(255, 76, 82)
local LOCKED = Color3.fromRGB(43, 70, 92)
local INK = Color3.fromRGB(6, 12, 24)
local PAPER = Color3.fromRGB(226, 241, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "SkylineRelayHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "MissionPanel"
panel.Size = UDim2.fromOffset(460, 190)
panel.Position = UDim2.fromOffset(26, 26)
panel.BackgroundColor3 = INK
panel.BackgroundTransparency = 0.06
panel.BorderSizePixel = 0
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Color = CYAN
panelStroke.Thickness = 2
panelStroke.Transparency = 0.12
local panelGradient = Instance.new("UIGradient", panel)
panelGradient.Color = ColorSequence.new(Color3.fromRGB(13, 25, 43), Color3.fromRGB(5, 10, 20))
panelGradient.Rotation = 25

local panelScale = Instance.new("UIScale", panel)
local camera = workspace.CurrentCamera
local function resizePanel()
    panelScale.Scale = math.clamp(camera.ViewportSize.X / 1050, 0.68, 1)
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizePanel)
resizePanel()

local function text(parent, name, position, size, font, color, scaled)
    local value = Instance.new("TextLabel")
    value.Name = name
    value.Position = position
    value.Size = size
    value.BackgroundTransparency = 1
    value.TextXAlignment = Enum.TextXAlignment.Left
    value.Font = font
    value.TextColor3 = color
    value.TextScaled = scaled
    value.Parent = parent
    return value
end

local title = text(panel, "Title", UDim2.fromOffset(18, 12), UDim2.fromOffset(270, 30), Enum.Font.GothamBlack, PAPER, true)
title.Text = "SKYLINE RELAY"
local subtitle = text(panel, "Subtitle", UDim2.fromOffset(20, 41), UDim2.fromOffset(260, 17), Enum.Font.GothamMedium, Color3.fromRGB(120, 154, 182), true)
subtitle.Text = "EMERGENCY CELL // DISTRICT 07"

local timerBox = Instance.new("Frame")
timerBox.Name = "TimerBox"
timerBox.Position = UDim2.fromOffset(318, 12)
timerBox.Size = UDim2.fromOffset(124, 49)
timerBox.BackgroundColor3 = Color3.fromRGB(17, 28, 42)
timerBox.BorderSizePixel = 0
timerBox.Parent = panel
Instance.new("UICorner", timerBox).CornerRadius = UDim.new(0, 7)
local timer = text(timerBox, "Timer", UDim2.fromOffset(8, 7), UDim2.fromOffset(108, 34), Enum.Font.RobotoMono, GOLD, true)
timer.TextXAlignment = Enum.TextXAlignment.Center

local objective = text(panel, "Objective", UDim2.fromOffset(20, 71), UDim2.fromOffset(420, 38), Enum.Font.GothamBold, PAPER, false)
objective.TextSize = 17
objective.TextWrapped = true

local progressRow = Instance.new("Frame")
progressRow.Name = "CheckpointProgress"
progressRow.Position = UDim2.fromOffset(20, 120)
progressRow.Size = UDim2.fromOffset(420, 24)
progressRow.BackgroundTransparency = 1
progressRow.Parent = panel
local progressLayout = Instance.new("UIListLayout", progressRow)
progressLayout.FillDirection = Enum.FillDirection.Horizontal
progressLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
progressLayout.Padding = UDim.new(0, 7)
local progressNodes = {}
for index = 1, Config.CheckpointCount do
    local node = Instance.new("Frame")
    node.Name = ("Checkpoint%02d"):format(index)
    node.Size = UDim2.fromOffset(53, 22)
    node.BackgroundColor3 = LOCKED
    node.BorderSizePixel = 0
    node.LayoutOrder = index
    node.Parent = progressRow
    Instance.new("UICorner", node).CornerRadius = UDim.new(1, 0)
    local number = text(node, "Number", UDim2.fromScale(0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBold, PAPER, true)
    number.TextXAlignment = Enum.TextXAlignment.Center
    number.Text = ("%02d"):format(index)
    progressNodes[index] = node
end

local split = text(panel, "Split", UDim2.fromOffset(20, 155), UDim2.fromOffset(210, 20), Enum.Font.RobotoMono, Color3.fromRGB(135, 170, 195), true)
local status = text(panel, "Status", UDim2.fromOffset(270, 155), UDim2.fromOffset(170, 20), Enum.Font.GothamBold, CYAN, true)
status.TextXAlignment = Enum.TextXAlignment.Right

local waypoint = Instance.new("TextLabel")
waypoint.Name = "Waypoint"
waypoint.AnchorPoint = Vector2.new(0.5, 0)
waypoint.Position = UDim2.fromScale(0.5, 0.035)
waypoint.Size = UDim2.new(0.56, 0, 0, 46)
waypoint.BackgroundColor3 = INK
waypoint.BackgroundTransparency = 0.16
waypoint.BorderSizePixel = 0
waypoint.Font = Enum.Font.GothamBold
waypoint.TextColor3 = GOLD
waypoint.TextScaled = true
waypoint.Parent = gui
Instance.new("UICorner", waypoint).CornerRadius = UDim.new(0, 8)
local waypointSize = Instance.new("UISizeConstraint", waypoint)
waypointSize.MinSize = Vector2.new(240, 38)
waypointSize.MaxSize = Vector2.new(620, 46)

local function resizeWaypoint()
    if camera.ViewportSize.X < 850 then
        waypoint.Position = UDim2.new(0.5, 0, 0, 158)
        waypoint.Size = UDim2.new(0.76, 0, 0, 42)
    else
        waypoint.Position = UDim2.fromScale(0.5, 0.035)
        waypoint.Size = UDim2.new(0.56, 0, 0, 46)
    end
end
camera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeWaypoint)
resizeWaypoint()

local speed = Instance.new("TextLabel")
speed.Name = "Speed"
speed.AnchorPoint = Vector2.new(1, 1)
speed.Position = UDim2.new(1, -24, 1, -24)
speed.Size = UDim2.fromOffset(170, 42)
speed.BackgroundColor3 = INK
speed.BackgroundTransparency = 0.18
speed.BorderSizePixel = 0
speed.Font = Enum.Font.RobotoMono
speed.TextColor3 = CYAN
speed.TextScaled = true
speed.Text = "00 STUDS/S"
speed.Parent = gui
Instance.new("UICorner", speed).CornerRadius = UDim.new(0, 7)

local banner = Instance.new("TextLabel")
banner.Name = "EndState"
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.45)
banner.Size = UDim2.new(0.76, 0, 0, 128)
banner.BackgroundColor3 = INK
banner.BackgroundTransparency = 1
banner.BorderSizePixel = 0
banner.TextTransparency = 1
banner.Font = Enum.Font.GothamBlack
banner.TextScaled = true
banner.TextWrapped = true
banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)
local bannerSize = Instance.new("UISizeConstraint", banner)
bannerSize.MinSize = Vector2.new(300, 100)
bannerSize.MaxSize = Vector2.new(700, 128)

local retry = Instance.new("TextButton")
retry.Name = "Retry"
retry.AnchorPoint = Vector2.new(0.5, 0)
retry.Position = UDim2.fromScale(0.5, 0.56)
retry.Size = UDim2.fromOffset(236, 52)
retry.BackgroundColor3 = Color3.fromRGB(33, 135, 170)
retry.Text = "RUN IT AGAIN"
retry.TextColor3 = Color3.new(1, 1, 1)
retry.Font = Enum.Font.GothamBold
retry.TextScaled = true
retry.Visible = false
retry.Parent = gui
Instance.new("UICorner", retry).CornerRadius = UDim.new(0, 8)
retry.Activated:Connect(function()
    stateRoot.RequestRetry:FireServer()
end)

local checkpointHighlight = Instance.new("Highlight")
checkpointHighlight.Name = "NextCheckpointHighlight"
checkpointHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
checkpointHighlight.FillColor = GOLD
checkpointHighlight.FillTransparency = 0.82
checkpointHighlight.OutlineColor = GOLD
checkpointHighlight.OutlineTransparency = 0.08
checkpointHighlight.Parent = gui

local function setCheckpointVisual(index, checkpoint, phase)
    local view = checkpointViews[index]
    local isComplete = index <= checkpoint
    local isNext = phase == "Racing" and index == checkpoint + 1
    local color = isComplete and GREEN or (isNext and GOLD or LOCKED)
    view.Pad.Color = color
    view.GateBeam.Color = color
    view.Label.TextColor3 = color
    progressNodes[index].BackgroundColor3 = color
end

local lastPhase = ""
local function refresh()
    local checkpoint = state:GetAttribute("Checkpoint") or 0
    local seconds = state:GetAttribute("TimeLeft") or 0
    local phase = state:GetAttribute("Phase") or "Racing"
    local splitSeconds = state:GetAttribute("SplitSeconds") or 0
    timer.Text = ("%02d:%02d"):format(math.floor(seconds / 60), seconds % 60)
    timer.TextColor3 = seconds <= 25 and RED or GOLD
    objective.Text = state:GetAttribute("Objective") or "Reach checkpoint 01"
    split.Text = checkpoint > 0 and ("LAST SPLIT  %05.1fs"):format(splitSeconds) or "CELL SECURED  //  GO"
    status.Text = phase == "Racing" and ("CHECKPOINT %d / %d"):format(checkpoint, Config.CheckpointCount) or string.upper(phase)
    status.TextColor3 = phase == "Delivered" and GREEN or (phase == "Failed" and RED or CYAN)
    panelStroke.Color = status.TextColor3

    for index = 1, Config.CheckpointCount do
        setCheckpointVisual(index, checkpoint, phase)
    end
    if phase == "Racing" then
        local nextView = checkpointViews[checkpoint + 1]
        checkpointHighlight.Adornee = nextView and nextView.Model or nil
    else
        checkpointHighlight.Adornee = nil
    end

    if phase ~= lastPhase and (phase == "Delivered" or phase == "Failed") then
        if phase == "Delivered" then
            local completion = state:GetAttribute("CompletionSeconds") or 0
            local best = state:GetAttribute("BestSeconds") or completion
            banner.Text = ("POWER RESTORED\nDELIVERY %05.1fs  //  BEST %05.1fs"):format(completion, best)
            banner.TextColor3 = GREEN
        else
            banner.Text = "DELIVERY MISSED\nTHE GRID IS STILL DARK"
            banner.TextColor3 = RED
        end
        retry.Visible = true
        TweenService:Create(banner, TweenInfo.new(0.45), { BackgroundTransparency = 0.06, TextTransparency = 0 }):Play()
    elseif phase == "Racing" then
        retry.Visible = false
        banner.BackgroundTransparency = 1
        banner.TextTransparency = 1
    end
    lastPhase = phase
end
state.AttributeChanged:Connect(refresh)
refresh()

local characterRoot
local function bindCharacter(character)
    characterRoot = character:WaitForChild("HumanoidRootPart", 5)
end
player.CharacterAdded:Connect(bindCharacter)
if player.Character then
    task.defer(bindCharacter, player.Character)
end

RunService.RenderStepped:Connect(function()
    local checkpoint = state:GetAttribute("Checkpoint") or 0
    local phase = state:GetAttribute("Phase") or "Racing"
    if characterRoot and characterRoot.Parent then
        local horizontalVelocity = Vector3.new(characterRoot.AssemblyLinearVelocity.X, 0, characterRoot.AssemblyLinearVelocity.Z)
        speed.Text = ("%02d STUDS/S"):format(math.floor(horizontalVelocity.Magnitude + 0.5))
    end
    if phase ~= "Racing" or checkpoint >= Config.CheckpointCount then
        waypoint.Visible = false
        return
    end
    waypoint.Visible = true
    local target = checkpointViews[checkpoint + 1]
    if target and characterRoot and characterRoot.Parent then
        local distance = (target.Pad.Position - characterRoot.Position).Magnitude
        waypoint.Text = ("NEXT  %02d  //  %s  //  %dm"):format(checkpoint + 1, string.upper(Config.Course[checkpoint + 1].Name), math.floor(distance + 0.5))
    else
        waypoint.Text = ("NEXT CHECKPOINT  %02d"):format(checkpoint + 1)
    end
end)
