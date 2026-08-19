local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local RuntimeBuilder = require(script.Parent.RuntimeBuilder)

local oldState = ReplicatedStorage:FindFirstChild("SignalBelowState")
if oldState then oldState:Destroy() end
local state = Instance.new("Folder")
state.Name = "SignalBelowState"
state.Parent = ReplicatedStorage

local retry = Instance.new("RemoteEvent")
retry.Name = "RequestRetry"
retry.Parent = state

local runtime, prompts = RuntimeBuilder.build(Config)
local dish = workspace:WaitForChild("ThrixelAssets"):WaitForChild(Config.MovingAsset)
assert(dish:GetAttribute("GoalToGameAsset") == true, "TrackingSignalDish is missing GoalToGameAsset=true")
local yoke = dish:WaitForChild("AzimuthYoke_Group")
local assembly = dish:WaitForChild("DishAssembly_Group")
assert(yoke:GetAttribute("GoalToGameMovingPart") == true, "AzimuthYoke_Group is not tagged as moving")
assert(assembly:GetAttribute("GoalToGameMovingPart") == true, "DishAssembly_Group is not tagged as moving")
local yokeOrigin = yoke:GetPivot()
local assemblyOrigin = assembly:GetPivot()

local repaired = {}
local phase = "Repair"
local remaining = Config.RoundSeconds
local activationStarted = 0

local function objectiveText()
    if phase == "Repair" then
        return "Restore the four perimeter relays"
    elseif phase == "Activating" then
        return "Dish aligning — stand by for signal lock"
    elseif phase == "Victory" then
        return "SIGNAL LOCKED — rescue beacon acquired"
    end
    return "SIGNAL LOST — retry the emergency sequence"
end

local function publish()
    local count = 0
    for _ in repaired do count += 1 end
    state:SetAttribute("RelaysRestored", count)
    state:SetAttribute("RoundSeconds", remaining)
    state:SetAttribute("Phase", phase)
    state:SetAttribute("Objective", objectiveText())
end

local function setPromptsEnabled(enabled)
    for index, prompt in prompts do
        prompt.Enabled = enabled and not repaired[index]
    end
end

local function restore(index)
    if phase ~= "Repair" or repaired[index] then return end
    repaired[index] = true
    local model = runtime.Relays:FindFirstChild(("Relay_%s"):format(string.char(64 + index)))
    RuntimeBuilder.setRelayVisual(model, true)
    local count = 0
    for _ in repaired do count += 1 end
    if count >= Config.RequiredRelays then
        phase = "Activating"
        activationStarted = workspace:GetServerTimeNow()
        setPromptsEnabled(false)
    end
    publish()
end

for index, prompt in prompts do
    prompt.Triggered:Connect(function(_player)
        restore(index)
    end)
end

local function resetRound()
    repaired = {}
    phase = "Repair"
    remaining = Config.RoundSeconds
    yoke:PivotTo(yokeOrigin)
    assembly:PivotTo(assemblyOrigin)
    for index = 1, Config.RequiredRelays do
        RuntimeBuilder.setRelayVisual(runtime.Relays:FindFirstChild(("Relay_%s"):format(string.char(64 + index))), false)
    end
    setPromptsEnabled(true)
    publish()
end

retry.OnServerEvent:Connect(function(player)
    if phase == "Failed" or phase == "Victory" then
        resetRound()
        local character = player.Character
        if character then character:PivotTo(runtime.StationSpawn.CFrame + Vector3.new(0, 4, 0)) end
    end
end)

if RunService:IsStudio() then
    local testControl = Instance.new("BindableEvent")
    testControl.Name = "StudioTestControl"
    testControl.Parent = runtime
    testControl.Event:Connect(function(command, value)
        if command == "Repair" then restore(value) end
        if command == "Fail" and phase == "Repair" then remaining = 0 phase = "Failed" setPromptsEnabled(false) publish() end
        if command == "Reset" then resetRound() end
    end)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait()
        character:PivotTo(runtime.StationSpawn.CFrame + Vector3.new(0, 4, 0))
    end)
end)

publish()
task.spawn(function()
    while task.wait(1) do
        if phase == "Repair" then
            remaining = math.max(0, remaining - 1)
            if remaining == 0 then phase = "Failed" setPromptsEnabled(false) end
            publish()
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if phase ~= "Activating" and phase ~= "Victory" then return end
    local elapsed = workspace:GetServerTimeNow() - activationStarted
    if phase == "Activating" then
        local alpha = math.clamp(elapsed / 6, 0, 1)
        local eased = 1 - (1 - alpha) ^ 3
        local sweep = math.rad(-40 + 78 * eased + math.sin(elapsed * 2.4) * (1 - alpha) * 8)
        local elevation = math.rad(-18 + 42 * eased)
        yoke:PivotTo(yokeOrigin * CFrame.Angles(0, sweep, 0))
        assembly:PivotTo(assemblyOrigin * CFrame.Angles(elevation, 0, 0))
        if alpha >= 1 then phase = "Victory" publish() end
    else
        local track = math.sin(elapsed * 0.8) * math.rad(1.2)
        yoke:PivotTo(yokeOrigin * CFrame.Angles(0, math.rad(38) + track, 0))
        assembly:PivotTo(assemblyOrigin * CFrame.Angles(math.rad(24) + track * 0.35, 0, 0))
    end
end)
