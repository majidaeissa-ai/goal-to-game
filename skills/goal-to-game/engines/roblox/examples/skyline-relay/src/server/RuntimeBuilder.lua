local Lighting = game:GetService("Lighting")

local RuntimeBuilder = {}

local LOCKED = Color3.fromRGB(40, 80, 105)
local CYAN = Color3.fromRGB(50, 225, 255)
local GOLD = Color3.fromRGB(255, 194, 72)

local function part(parent, name, size, cframe, color, material)
    local object = Instance.new("Part")
    object.Name = name
    object.Size = size
    object.CFrame = cframe
    object.Color = color
    object.Material = material or Enum.Material.Metal
    object.Anchored = true
    object.TopSurface = Enum.SurfaceType.Smooth
    object.BottomSurface = Enum.SurfaceType.Smooth
    object.Parent = parent
    return object
end

local function billboard(adornee, name, text, offset, size)
    local gui = Instance.new("BillboardGui")
    gui.Name = name
    gui.Adornee = adornee
    gui.Size = size or UDim2.fromOffset(230, 54)
    gui.StudsOffset = offset or Vector3.new(0, 4, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 180
    gui.Parent = adornee

    local value = Instance.new("TextLabel")
    value.Name = "Text"
    value.Size = UDim2.fromScale(1, 1)
    value.BackgroundColor3 = Color3.fromRGB(7, 14, 25)
    value.BackgroundTransparency = 0.12
    value.BorderSizePixel = 0
    value.TextColor3 = Color3.fromRGB(225, 242, 255)
    value.Font = Enum.Font.GothamBold
    value.TextScaled = true
    value.Text = text
    value.Parent = gui
    Instance.new("UICorner", value).CornerRadius = UDim.new(0, 6)
    return value
end

local function partBetween(parent, name, startPosition, endPosition, width, thickness, color, material)
    local delta = endPosition - startPosition
    local object = part(
        parent,
        name,
        Vector3.new(width, thickness, delta.Magnitude),
        CFrame.lookAt((startPosition + endPosition) / 2, endPosition),
        color,
        material
    )
    return object
end

local function addBridge(parent, index, startPosition, endPosition)
    local bridge = Instance.new("Model")
    bridge.Name = ("Skybridge_%02d"):format(index)
    bridge.Parent = parent

    local raisedStart = startPosition + Vector3.new(0, 1.15, 0)
    local raisedEnd = endPosition + Vector3.new(0, 1.15, 0)
    partBetween(bridge, "Walkway", raisedStart, raisedEnd, 9, 1.15, Color3.fromRGB(49, 59, 70), Enum.Material.DiamondPlate)

    local delta = endPosition - startPosition
    local horizontal = Vector3.new(delta.X, 0, delta.Z)
    if horizontal.Magnitude > 0 then
        local right = Vector3.new(-horizontal.Z, 0, horizontal.X).Unit
        for _, side in { -1, 1 } do
            local offset = right * (side * 4.25) + Vector3.new(0, 1.05, 0)
            local rail = partBetween(bridge, "RouteLight", raisedStart + offset, raisedEnd + offset, 0.28, 0.28, CYAN, Enum.Material.Neon)
            rail.CanCollide = false
        end
    end
end

local function addFacadeDetails(model, roof)
    local bodyHeight = math.max(8, roof.Position.Y - 0.75)
    local body = part(
        model,
        "TowerBody",
        Vector3.new(roof.Size.X - 2, bodyHeight, roof.Size.Z - 2),
        CFrame.new(roof.Position.X, bodyHeight / 2, roof.Position.Z),
        Color3.fromRGB(24, 32, 44),
        Enum.Material.Concrete
    )
    body:SetAttribute("DistrictStructure", true)

    for band = 1, 3 do
        local y = math.max(2.5, bodyHeight * band / 4)
        local front = part(
            model,
            "WindowBand",
            Vector3.new(math.max(10, roof.Size.X - 5), 0.55, 0.15),
            CFrame.new(roof.Position.X, y, roof.Position.Z - (roof.Size.Z - 1.8) / 2),
            Color3.fromRGB(36, 150, 190),
            Enum.Material.Neon
        )
        front.CanCollide = false
        local side = part(
            model,
            "WindowBand",
            Vector3.new(0.15, 0.55, math.max(10, roof.Size.Z - 5)),
            CFrame.new(roof.Position.X + (roof.Size.X - 1.8) / 2, y, roof.Position.Z),
            Color3.fromRGB(255, 169, 62),
            Enum.Material.Neon
        )
        side.CanCollide = false
    end
end

local function addRoofDetails(model, roof, index)
    local roofTop = roof.Position + Vector3.new(0, roof.Size.Y / 2, 0)
    local ventOffset = Vector3.new(index % 2 == 0 and 8 or -8, 1.6, index % 3 == 0 and -7 or 7)
    part(model, "ServiceVent", Vector3.new(5, 3, 5), CFrame.new(roofTop + ventOffset), Color3.fromRGB(72, 82, 90), Enum.Material.Metal)

    local mastPosition = roofTop + Vector3.new(index % 2 == 0 and -10 or 10, 4, -8)
    local mast = part(model, "RouteMast", Vector3.new(0.7, 8, 0.7), CFrame.new(mastPosition), Color3.fromRGB(77, 89, 100), Enum.Material.Metal)
    local light = Instance.new("PointLight")
    light.Name = "RouteLight"
    light.Color = index == 7 and GOLD or CYAN
    light.Range = 22
    light.Brightness = 1.8
    light.Parent = mast
    local beacon = part(model, "RouteBeacon", Vector3.new(1.5, 1.5, 1.5), CFrame.new(mastPosition + Vector3.new(0, 4.4, 0)), light.Color, Enum.Material.Neon)
    beacon.Shape = Enum.PartType.Ball
    beacon.CanCollide = false
end

local function addCheckpoint(parent, courseEntry, index, count)
    local model = Instance.new("Model")
    model.Name = ("Checkpoint_%02d"):format(index)
    model:SetAttribute("CheckpointIndex", index)
    model:SetAttribute("CheckpointName", courseEntry.Name)
    model.Parent = parent

    local roofTop = courseEntry.Position + Vector3.new(0, courseEntry.Size.Y / 2, 0)
    local padColor = index == count and GOLD or LOCKED
    local pad = part(model, "Pad", Vector3.new(12, 0.3, 9), CFrame.new(roofTop + Vector3.new(0, 0.2, 0)), padColor, Enum.Material.Neon)
    pad.CanCollide = false
    pad.Transparency = 0.22

    for _, side in { -1, 1 } do
        part(model, "GatePost", Vector3.new(0.7, 8, 0.7), CFrame.new(roofTop + Vector3.new(side * 6, 4, 0)), Color3.fromRGB(80, 95, 110), Enum.Material.Metal)
    end
    local beam = part(model, "GateBeam", Vector3.new(12.7, 0.8, 0.8), CFrame.new(roofTop + Vector3.new(0, 7.7, 0)), padColor, Enum.Material.Neon)
    beam.CanCollide = false
    billboard(beam, "CheckpointLabel", ("%02d  /  %s"):format(index, string.upper(courseEntry.Name)), Vector3.new(0, 2.1, 0))

    local touch = part(model, "TouchZone", Vector3.new(13, 8, 10), CFrame.new(roofTop + Vector3.new(0, 4, 0)), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
    touch.Transparency = 1
    touch.CanCollide = false
    touch.CanTouch = true
    return touch
end

local function addAssetPlaceholder(parent, name, position, size)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("GoalToGamePlaceholder", true)
    model:SetAttribute("IntendedAsset", name)
    model.Parent = parent
    local block = part(model, "Placeholder", size, CFrame.new(position), Color3.fromRGB(105, 78, 130), Enum.Material.SmoothPlastic)
    block.Transparency = 0.18
    billboard(block, "PlaceholderLabel", "THRIXEL PLACEHOLDER\n" .. string.upper(name), Vector3.new(0, size.Y / 2 + 1.8, 0), UDim2.fromOffset(260, 72))
end

function RuntimeBuilder.build(config)
    local old = workspace:FindFirstChild(config.RuntimeName)
    if old then
        old:Destroy()
    end
    for _, effectName in { "SkylineRelayAtmosphere", "SkylineRelayBloom", "SkylineRelayGrade" } do
        local oldEffect = Lighting:FindFirstChild(effectName)
        if oldEffect then
            oldEffect:Destroy()
        end
    end

    local runtime = Instance.new("Folder")
    runtime.Name = config.RuntimeName
    runtime.Parent = workspace

    local skyline = Instance.new("Folder")
    skyline.Name = "District"
    skyline.Parent = runtime

    local roofModels = {}
    for index, roof in config.Course do
        local model = Instance.new("Model")
        model.Name = ("Roof_%02d_%s"):format(index, roof.Name:gsub("%s+", ""))
        model:SetAttribute("CourseIndex", index)
        model.Parent = skyline
        addFacadeDetails(model, roof)
        part(model, "Roof", roof.Size, CFrame.new(roof.Position), Color3.fromRGB(44, 54, 65), Enum.Material.Concrete)
        addRoofDetails(model, roof, index)
        roofModels[index] = model
    end

    local bridges = Instance.new("Folder")
    bridges.Name = "Skybridges"
    bridges.Parent = runtime
    for index = 1, #config.Course - 1 do
        addBridge(bridges, index, config.Course[index].Position, config.Course[index + 1].Position)
    end

    local checkpoints = Instance.new("Folder")
    checkpoints.Name = "Checkpoints"
    checkpoints.Parent = runtime
    local touchZones = {}
    for index, roof in config.Course do
        touchZones[index] = addCheckpoint(checkpoints, roof, index, config.CheckpointCount)
    end

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "DispatchSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(config.SpawnPosition)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Neon
    spawn.Color = CYAN
    spawn.Transparency = 0.18
    spawn.Parent = runtime

    local killPlane = part(runtime, "VoidReset", Vector3.new(360, 2, 300), CFrame.new(18, config.KillPlaneY, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic)
    killPlane.Transparency = 1
    killPlane.CanCollide = false

    local placeholders = Instance.new("Folder")
    placeholders.Name = "ThrixelAssetPlaceholders"
    placeholders.Parent = runtime
    addAssetPlaceholder(placeholders, "EmergencyPowerCellCarrier", Vector3.new(-10, 19, 4), Vector3.new(3, 4, 2))
    addAssetPlaceholder(placeholders, "CargoDrone", Vector3.new(50, 26, 63), Vector3.new(8, 3, 8))
    addAssetPlaceholder(placeholders, "FreightGantry", Vector3.new(70, 34, 30), Vector3.new(10, 7, 4))
    addAssetPlaceholder(placeholders, "DeliveryTerminal", Vector3.new(-47, 30, 14), Vector3.new(5, 5, 3))

    Lighting.ClockTime = 18.4
    Lighting.Brightness = 2.2
    Lighting.Ambient = Color3.fromRGB(50, 56, 78)
    Lighting.OutdoorAmbient = Color3.fromRGB(72, 76, 100)
    Lighting.EnvironmentDiffuseScale = 0.35
    Lighting.EnvironmentSpecularScale = 0.65
    Lighting.FogColor = Color3.fromRGB(65, 77, 110)
    Lighting.FogStart = 150
    Lighting.FogEnd = 430

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "SkylineRelayAtmosphere"
    atmosphere.Density = 0.3
    atmosphere.Haze = 1.6
    atmosphere.Glare = 0.08
    atmosphere.Color = Color3.fromRGB(155, 170, 220)
    atmosphere.Decay = Color3.fromRGB(72, 50, 95)
    atmosphere.Parent = Lighting

    local bloom = Instance.new("BloomEffect")
    bloom.Name = "SkylineRelayBloom"
    bloom.Intensity = 0.45
    bloom.Size = 28
    bloom.Threshold = 1.15
    bloom.Parent = Lighting

    local grade = Instance.new("ColorCorrectionEffect")
    grade.Name = "SkylineRelayGrade"
    grade.Brightness = 0.015
    grade.Contrast = 0.09
    grade.Saturation = -0.02
    grade.TintColor = Color3.fromRGB(235, 228, 255)
    grade.Parent = Lighting

    return runtime, touchZones, killPlane, spawn, roofModels
end

return RuntimeBuilder
