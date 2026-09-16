local Lighting = game:GetService("Lighting")

local RuntimeBuilder = {}

local OFFLINE = Color3.fromRGB(225, 55, 45)
local ONLINE = Color3.fromRGB(55, 255, 155)

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

local function label(adornee, text)
    local gui = Instance.new("BillboardGui")
    gui.Name = "RelayLabel"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(180, 48)
    gui.StudsOffset = Vector3.new(0, 5.5, 0)
    gui.AlwaysOnTop = true
    gui.MaxDistance = 90
    gui.Parent = adornee

    local value = Instance.new("TextLabel")
    value.Name = "Text"
    value.Size = UDim2.fromScale(1, 1)
    value.BackgroundColor3 = Color3.fromRGB(7, 14, 22)
    value.BackgroundTransparency = 0.15
    value.TextColor3 = Color3.fromRGB(230, 245, 255)
    value.Font = Enum.Font.GothamBold
    value.TextScaled = true
    value.Text = text
    value.Parent = gui
end

local function buildRelay(parent, index, position)
    local model = Instance.new("Model")
    model.Name = ("Relay_%s"):format(string.char(64 + index))
    model:SetAttribute("RelayIndex", index)
    model:SetAttribute("Restored", false)
    model.Parent = parent

    part(model, "Platform", Vector3.new(18, 1, 18), CFrame.new(position - Vector3.new(0, 3.5, 0)), Color3.fromRGB(30, 40, 48), Enum.Material.DiamondPlate)
    part(model, "Tower", Vector3.new(3, 10, 3), CFrame.new(position + Vector3.new(0, 1.5, 0)), Color3.fromRGB(55, 68, 76))
    local console = part(model, "Console", Vector3.new(5, 4, 2), CFrame.new(position + Vector3.new(0, -0.5, -3)), Color3.fromRGB(32, 42, 48))
    local beacon = part(model, "Beacon", Vector3.new(2.4, 2.4, 2.4), CFrame.new(position + Vector3.new(0, 7.5, 0)), OFFLINE, Enum.Material.Neon)
    beacon.Shape = Enum.PartType.Ball
    local light = Instance.new("PointLight")
    light.Name = "StatusLight"
    light.Color = OFFLINE
    light.Range = 18
    light.Brightness = 2
    light.Parent = beacon

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name = "RepairPrompt"
    prompt.ActionText = "Repair relay"
    prompt.ObjectText = ("RELAY %s — OFFLINE"):format(string.char(64 + index))
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 1.1
    prompt.MaxActivationDistance = 11
    prompt.RequiresLineOfSight = false
    prompt.Parent = console
    label(beacon, ("RELAY %s  •  OFFLINE"):format(string.char(64 + index)))
    return model, prompt
end

function RuntimeBuilder.setRelayVisual(model, restored)
    model:SetAttribute("Restored", restored)
    local color = restored and ONLINE or OFFLINE
    local beacon = model:FindFirstChild("Beacon")
    local prompt = model:FindFirstChild("RepairPrompt", true)
    if beacon then
        beacon.Color = color
        beacon.StatusLight.Color = color
        beacon.StatusLight.Brightness = restored and 4 or 2
        local text = beacon.RelayLabel.Text
        text.Text = ("RELAY %s  •  %s"):format(string.char(64 + model:GetAttribute("RelayIndex")), restored and "RESTORED" or "OFFLINE")
        text.TextColor3 = color
    end
    if prompt then
        prompt.Enabled = not restored
        prompt.ObjectText = restored and "RELAY RESTORED" or (("RELAY %s — OFFLINE"):format(string.char(64 + model:GetAttribute("RelayIndex"))))
    end
end

function RuntimeBuilder.build(config)
    local old = workspace:FindFirstChild(config.RuntimeName)
    if old then old:Destroy() end
    local runtime = Instance.new("Folder")
    runtime.Name = config.RuntimeName
    runtime.Parent = workspace

    part(runtime, "StationGround", Vector3.new(180, 2, 180), CFrame.new(0, -1, 0), Color3.fromRGB(18, 28, 34), Enum.Material.Slate)
    part(runtime, "DishDeck", Vector3.new(44, 1.5, 44), CFrame.new(0, 0, 0), Color3.fromRGB(39, 49, 56), Enum.Material.DiamondPlate)
    for _, position in config.RelayPositions do
        local direction = Vector3.new(position.X, 0, position.Z)
        local distance = direction.Magnitude
        part(runtime, "LitPath", Vector3.new(8, 0.35, distance), CFrame.lookAt(direction / 2 + Vector3.new(0, 0.2, 0), direction), Color3.fromRGB(55, 75, 82), Enum.Material.Concrete)
        for step = 0, 3 do
            local p = direction.Unit * (12 + step * ((distance - 18) / 3))
            part(runtime, "PathLight", Vector3.new(1, 0.25, 2), CFrame.lookAt(p + Vector3.new(0, 0.42, 0), direction), Color3.fromRGB(50, 185, 255), Enum.Material.Neon).CanCollide = false
        end
    end

    local spawn = Instance.new("SpawnLocation")
    spawn.Name = "StationSpawn"
    spawn.Size = Vector3.new(8, 1, 8)
    spawn.CFrame = CFrame.new(0, 1, 31)
    spawn.Anchored = true
    spawn.Neutral = true
    spawn.Material = Enum.Material.Neon
    spawn.Color = Color3.fromRGB(35, 115, 145)
    spawn.Transparency = 0.25
    spawn.Parent = runtime

    local relays = Instance.new("Folder")
    relays.Name = "Relays"
    relays.Parent = runtime
    local prompts = {}
    for index, position in config.RelayPositions do
        local _, prompt = buildRelay(relays, index, position)
        table.insert(prompts, prompt)
    end

    local mast = part(runtime, "EmergencyMast", Vector3.new(2, 15, 2), CFrame.new(0, 7.5, 24), Color3.fromRGB(55, 62, 66))
    local alarm = Instance.new("PointLight")
    alarm.Color = OFFLINE
    alarm.Range = 45
    alarm.Brightness = 2
    alarm.Shadows = true
    alarm.Parent = mast

    Lighting.ClockTime = 1.5
    Lighting.Brightness = 1.2
    Lighting.Ambient = Color3.fromRGB(15, 25, 38)
    Lighting.OutdoorAmbient = Color3.fromRGB(22, 32, 45)
    Lighting.FogColor = Color3.fromRGB(18, 29, 42)
    Lighting.FogStart = 70
    Lighting.FogEnd = 210
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "SignalBelowAtmosphere"
    atmosphere.Density = 0.35
    atmosphere.Haze = 2
    atmosphere.Color = Color3.fromRGB(130, 165, 190)
    atmosphere.Decay = Color3.fromRGB(20, 35, 55)
    atmosphere.Parent = runtime
    return runtime, prompts
end

return RuntimeBuilder
