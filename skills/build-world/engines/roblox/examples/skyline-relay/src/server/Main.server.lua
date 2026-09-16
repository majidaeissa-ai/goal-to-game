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

local function getPivot(object)
    if object:IsA("Model") then
        return object:GetPivot()
    elseif object:IsA("BasePart") then
        return object.CFrame
    end
    return nil
end

local function setPivot(object, cframe)
    if object:IsA("Model") then
        object:PivotTo(cframe)
    elseif object:IsA("BasePart") then
        object.CFrame = cframe
    end
end

local animatedAssets = {}
local runtimeAssets = runtime:FindFirstChild("ThrixelAssets")
local drone = runtimeAssets and runtimeAssets:FindFirstChild("CargoDrone")
if drone then
    for index, rotorName in { "Rotor_FL", "Rotor_FR", "Rotor_RL", "Rotor_RR" } do
        local rotor = drone:FindFirstChild(rotorName, true)
        local pivot = rotor and getPivot(rotor)
        if pivot then
            table.insert(animatedAssets, { object = rotor, pivot = pivot, kind = "Rotor", phase = index * 0.35 })
            rotor:SetAttribute("GoalToGameMovingPart", true)
        end
    end
end

local gantry = runtimeAssets and runtimeAssets:FindFirstChild("FreightGantry")
if gantry then
    for _, spec in {
        { name = "Trolley", kind = "Trolley" },
        { name = "Hoist", kind = "Hoist" },
    } do
        local object = gantry:FindFirstChild(spec.name, true)
        local pivot = object and getPivot(object)
        if pivot then
            table.insert(animatedAssets, { object = object, pivot = pivot, kind = spec.kind, phase = 0 })
            object:SetAttribute("GoalToGameMovingPart", true)
        end
    end
end

local animationElapsed = 0
RunService.Heartbeat:Connect(function(deltaTime)
    animationElapsed += deltaTime
    local elapsed = animationElapsed
    for _, animation in animatedAssets do
        if animation.object.Parent then
            if animation.kind == "Rotor" then
                setPivot(animation.object, animation.pivot * CFrame.Angles(0, elapsed * 8 + animation.phase, 0))
            elseif animation.kind == "Trolley" then
                setPivot(animation.object, animation.pivot * CFrame.new(math.sin(elapsed * 0.8) * 2, 0, 0))
            elseif animation.kind == "Hoist" then
                setPivot(animation.object, animation.pivot * CFrame.new(0, math.sin(elapsed * 0.8) * 0.8, 0))
            end
        end
    end
end)

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

    local assetLibrary = workspace:FindFirstChild("ThrixelAssets")
    local assetSource = assetLibrary and assetLibrary:FindFirstChild("EmergencyPowerCellCarrier")
    if assetSource and (assetSource:IsA("Model") or assetSource:IsA("BasePart")) then
        local cargo = Instance.new("Model")
        if assetSource:IsA("Model") then
            cargo:Destroy()
            cargo = assetSource:Clone()
        elseif assetSource:IsA("BasePart") then
            assetSource:Clone().Parent = cargo
        end
        cargo.Name = "EmergencyPowerCell"
        cargo:SetAttribute("GameplayCargo", true)
        cargo:SetAttribute("GoalToGameAsset", true)
        cargo:SetAttribute("ThrixelAssetName", "EmergencyPowerCellCarrier")
        cargo.Parent = character

        if cargo:FindFirstChildWhichIsA("BasePart", true) then
            local _, size = cargo:GetBoundingBox()
            local scale = math.min(2.2 / size.X, 2.8 / size.Y, 1.1 / size.Z)
            cargo:ScaleTo(cargo:GetScale() * scale)
            local boundsCFrame = cargo:GetBoundingBox()
            local target = root.CFrame * CFrame.new(0, 0.35, 1.25)
            local boundsFromPivot = cargo:GetPivot():ToObjectSpace(boundsCFrame)
            cargo:PivotTo(target * boundsFromPivot:Inverse())
            for _, descendant in cargo:GetDescendants() do
                if descendant:IsA("BasePart") then
                    descendant.Anchored = false
                    descendant.CanCollide = false
                    descendant.CanTouch = false
                    descendant.CanQuery = false
                    descendant.Massless = true
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = root
                    weld.Part1 = descendant
                    weld.Parent = descendant
                end
            end
            return
        end
        cargo:Destroy()
    end

    local cargo = Instance.new("Model")
    cargo.Name = "EmergencyPowerCell"
    cargo:SetAttribute("GameplayCargo", true)
    cargo:SetAttribute("GoalToGamePlaceholder", true)
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
