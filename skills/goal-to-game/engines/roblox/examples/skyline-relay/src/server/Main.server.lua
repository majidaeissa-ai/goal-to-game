local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local RuntimeBuilder = require(script.Parent.RuntimeBuilder)

assert(#Config.Course == Config.CheckpointCount, "Skyline Relay course and checkpoint counts differ")

local oldState = ReplicatedStorage:FindFirstChild("SkylineRelayState")
if oldState then
    oldState:Destroy()
end

local stateRoot = Instance.new("Folder")
stateRoot.Name = "SkylineRelayState"
stateRoot.Parent = ReplicatedStorage

local playerStates = Instance.new("Folder")
playerStates.Name = "Players"
playerStates.Parent = stateRoot

local retry = Instance.new("RemoteEvent")
retry.Name = "RequestRetry"
retry.Parent = stateRoot

local runtime, touchZones, killPlane, spawn = RuntimeBuilder.build(Config)
local sessions = {}

local function stateFor(player)
    local state = playerStates:FindFirstChild(tostring(player.UserId))
    if state then
        return state
    end
    state = Instance.new("Folder")
    state.Name = tostring(player.UserId)
    state:SetAttribute("DisplayName", player.DisplayName)
    state:SetAttribute("Checkpoint", 0)
    state:SetAttribute("TimeLeft", Config.TimeLimit)
    state:SetAttribute("Phase", "Racing")
    state:SetAttribute("Objective", "Carry the emergency cell to checkpoint 01")
    state:SetAttribute("SplitSeconds", 0)
    state:SetAttribute("CompletionSeconds", 0)
    state:SetAttribute("BestSeconds", 0)
    state.Parent = playerStates
    return state
end

local function objectiveFor(session)
    if session.phase == "Delivered" then
        return "POWER RESTORED — emergency grid online"
    elseif session.phase == "Failed" then
        return "DELIVERY MISSED — restart from dispatch"
    end
    local nextIndex = session.checkpoint + 1
    local name = Config.Course[nextIndex].Name
    return ("Reach checkpoint %02d — %s"):format(nextIndex, name)
end

local function publish(player, force)
    local session = sessions[player]
    if not session then
        return
    end
    local timeLeft = session.phase == "Racing" and math.max(0, math.ceil(session.deadline - workspace:GetServerTimeNow())) or session.timeLeft
    if not force and session.lastPublishedSecond == timeLeft then
        return
    end
    session.timeLeft = timeLeft
    session.lastPublishedSecond = timeLeft
    local state = stateFor(player)
    state:SetAttribute("Checkpoint", session.checkpoint)
    state:SetAttribute("TimeLeft", timeLeft)
    state:SetAttribute("Phase", session.phase)
    state:SetAttribute("Objective", objectiveFor(session))
    state:SetAttribute("SplitSeconds", session.splitSeconds)
    state:SetAttribute("CompletionSeconds", session.completionSeconds)
    state:SetAttribute("BestSeconds", session.bestSeconds)
end

local function destroyCargo(character)
    if not character then
        return
    end
    local oldCargo = character:FindFirstChild("EmergencyPowerCell")
    if oldCargo then
        oldCargo:Destroy()
    end
end

local function attachCargo(character)
    destroyCargo(character)
    local root = character:WaitForChild("HumanoidRootPart", 5)
    if not root then
        return
    end

    local cargo = Instance.new("Model")
    cargo.Name = "EmergencyPowerCell"
    cargo:SetAttribute("GameplayCargo", true)
    cargo.Parent = character

    local function cargoPart(name, size, offset, color, material)
        local object = Instance.new("Part")
        object.Name = name
        object.Size = size
        object.CFrame = root.CFrame * offset
        object.Color = color
        object.Material = material
        object.CanCollide = false
        object.CanTouch = false
        object.CanQuery = false
        object.Massless = true
        object.Parent = cargo
        local weld = Instance.new("WeldConstraint")
        weld.Part0 = root
        weld.Part1 = object
        weld.Parent = object
        return object
    end

    cargoPart("CellBody", Vector3.new(2.2, 2.8, 1.1), CFrame.new(0, 0.35, 1.25), Color3.fromRGB(28, 38, 52), Enum.Material.Metal)
    cargoPart("UpperClamp", Vector3.new(2.5, 0.35, 1.35), CFrame.new(0, 1.55, 1.25), Color3.fromRGB(255, 178, 55), Enum.Material.Metal)
    cargoPart("LowerClamp", Vector3.new(2.5, 0.35, 1.35), CFrame.new(0, -0.85, 1.25), Color3.fromRGB(255, 178, 55), Enum.Material.Metal)
    local core = cargoPart("EnergyCore", Vector3.new(0.45, 1.8, 1.25), CFrame.new(0, 0.35, 1.85), Color3.fromRGB(50, 225, 255), Enum.Material.Neon)
    local light = Instance.new("PointLight")
    light.Color = core.Color
    light.Range = 10
    light.Brightness = 1.4
    light.Parent = core
end

local function resetRound(player, character)
    local previous = sessions[player]
    local bestSeconds = previous and previous.bestSeconds or 0
    local now = workspace:GetServerTimeNow()
    sessions[player] = {
        checkpoint = 0,
        phase = "Racing",
        startedAt = now,
        deadline = now + Config.TimeLimit,
        timeLeft = Config.TimeLimit,
        splitSeconds = 0,
        completionSeconds = 0,
        bestSeconds = bestSeconds,
        lastPublishedSecond = nil,
    }
    publish(player, true)

    character = character or player.Character
    if character then
        local root = character:WaitForChild("HumanoidRootPart", 5)
        if root then
            character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
            attachCargo(character)
        end
    end
end

local function failRound(player)
    local session = sessions[player]
    if not session or session.phase ~= "Racing" then
        return
    end
    session.phase = "Failed"
    session.timeLeft = 0
    destroyCargo(player.Character)
    publish(player, true)
end

local function advance(player, checkpointIndex)
    local session = sessions[player]
    if not session or session.phase ~= "Racing" or checkpointIndex ~= session.checkpoint + 1 then
        return
    end
    local now = workspace:GetServerTimeNow()
    if now >= session.deadline then
        failRound(player)
        return
    end

    session.checkpoint = checkpointIndex
    session.splitSeconds = math.floor((now - session.startedAt) * 10 + 0.5) / 10
    if checkpointIndex == Config.CheckpointCount then
        session.phase = "Delivered"
        session.completionSeconds = session.splitSeconds
        session.timeLeft = math.max(0, math.ceil(session.deadline - now))
        if session.bestSeconds == 0 or session.completionSeconds < session.bestSeconds then
            session.bestSeconds = session.completionSeconds
        end
        destroyCargo(player.Character)
    end
    publish(player, true)
end

local function characterFromTouch(hit)
    local ancestor = hit.Parent
    while ancestor and ancestor ~= workspace do
        if ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid") then
            return ancestor
        end
        ancestor = ancestor.Parent
    end
    return nil
end

local function playerFromTouch(hit)
    local character = characterFromTouch(hit)
    return character and Players:GetPlayerFromCharacter(character) or nil
end

for index, touchZone in touchZones do
    touchZone.Touched:Connect(function(hit)
        local player = playerFromTouch(hit)
        if player then
            advance(player, index)
        end
    end)
end

killPlane.Touched:Connect(function(hit)
    local character = characterFromTouch(hit)
    if not character then
        return
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Health = 0
    end
end)

retry.OnServerEvent:Connect(function(player)
    local session = sessions[player]
    if session and (session.phase == "Failed" or session.phase == "Delivered") then
        resetRound(player)
    end
end)

local function onPlayerAdded(player)
    stateFor(player)
    player.RespawnLocation = spawn
    player.CharacterAdded:Connect(function(character)
        task.defer(resetRound, player, character)
    end)
    if player.Character then
        task.defer(resetRound, player, player.Character)
    end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    sessions[player] = nil
    local state = playerStates:FindFirstChild(tostring(player.UserId))
    if state then
        state:Destroy()
    end
end)
for _, player in Players:GetPlayers() do
    onPlayerAdded(player)
end

if RunService:IsStudio() then
    local testControl = Instance.new("BindableEvent")
    testControl.Name = "StudioTestControl"
    testControl.Parent = runtime
    testControl.Event:Connect(function(command, value, userId)
        local player = userId and Players:GetPlayerByUserId(userId) or Players:GetPlayers()[1]
        if not player then
            return
        end
        if command == "Checkpoint" then
            advance(player, value)
        elseif command == "Fail" then
            failRound(player)
        elseif command == "Reset" then
            resetRound(player)
        end
    end)
end

task.spawn(function()
    while task.wait(0.2) do
        local now = workspace:GetServerTimeNow()
        for player, session in sessions do
            if session.phase == "Racing" and now >= session.deadline then
                failRound(player)
            else
                publish(player, false)
            end
        end
    end
end)
