-- Goal-to-Game Roblox verification plugin.
-- Requires a localhost evidence collector. Configure TOKEN before a bounty evidence run.

local HttpService = game:GetService("HttpService")
local StudioCaptureService = game:GetService("StudioCaptureService")
local EncodingService = game:GetService("EncodingService")
local Workspace = game:GetService("Workspace")

local PORT = 43119
local TOKEN = "REPLACE_WITH_COLLECTOR_SESSION_TOKEN"
local BASE = ("http://127.0.0.1:%d"):format(PORT)

local toolbar = plugin:CreateToolbar("Goal to Game")
local button = toolbar:CreateButton(
    "Audit + Capture",
    "Audit imported Thrixel assets and capture reproducible evidence",
    ""
)

local function request(path, payload)
    assert(TOKEN ~= "REPLACE_WITH_COLLECTOR_SESSION_TOKEN", "Set TOKEN from evidence_collector.py")
    local response = HttpService:RequestAsync({
        Url = BASE .. path,
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json",
            ["X-GoalToGame-Token"] = TOKEN,
        },
        Body = HttpService:JSONEncode(payload),
    })
    assert(response.Success, ("collector request failed: %d %s"):format(
        response.StatusCode, response.StatusMessage
    ))
end

local function contentString(value)
    local ok, s = pcall(function() return tostring(value) end)
    return ok and s or ""
end

local function audit()
    local container = Workspace:FindFirstChild("ThrixelAssets")
    local out = {
        schema = "goal-to-game-roblox-studio-audit-v1",
        placeId = game.PlaceId,
        universeId = game.GameId,
        capturedAtUnix = os.time(),
        assets = {},
        errors = {},
    }
    if not container then
        table.insert(out.errors, "Workspace.ThrixelAssets is missing")
        return out
    end

    for _, asset in ipairs(container:GetChildren()) do
        if asset:GetAttribute("GoalToGameAsset") == true then
            local row = {
                name = asset.Name,
                className = asset.ClassName,
                meshPartCount = 0,
                movingPartCount = 0,
                meshParts = {},
            }
            for _, inst in ipairs(asset:GetDescendants()) do
                if inst:GetAttribute("GoalToGameMovingPart") == true then
                    row.movingPartCount += 1
                end
                if inst:IsA("MeshPart") then
                    row.meshPartCount += 1
                    local surf = inst:FindFirstChildOfClass("SurfaceAppearance")
                    table.insert(row.meshParts, {
                        name = inst:GetFullName(),
                        meshId = contentString(inst.MeshId),
                        size = {inst.Size.X, inst.Size.Y, inst.Size.Z},
                        anchored = inst.Anchored,
                        canCollide = inst.CanCollide,
                        collisionFidelity = inst.CollisionFidelity.Name,
                        renderFidelity = inst.RenderFidelity.Name,
                        moving = inst:GetAttribute("GoalToGameMovingPart") == true,
                        surfaceAppearance = surf and {
                            colorMap = contentString(surf.ColorMap),
                            normalMap = contentString(surf.NormalMap),
                            roughnessMap = contentString(surf.RoughnessMap),
                            metalnessMap = contentString(surf.MetalnessMap),
                        } or nil,
                    })
                    if contentString(inst.MeshId) == "" then
                        table.insert(out.errors, inst:GetFullName() .. " has empty MeshId")
                    end
                end
            end
            if row.meshPartCount == 0 then
                table.insert(out.errors, asset.Name .. " contains no MeshParts")
            end
            table.insert(out.assets, row)
        end
    end

    if #out.assets == 0 then
        table.insert(out.errors, "no direct child of ThrixelAssets has GoalToGameAsset=true")
    end
    return out
end

local function bounds(container)
    local minv, maxv = nil, nil
    for _, inst in ipairs(container:GetDescendants()) do
        if inst:IsA("BasePart") then
            local half = inst.Size * 0.5
            local lo, hi = inst.Position - half, inst.Position + half
            minv = minv and Vector3.new(
                math.min(minv.X, lo.X), math.min(minv.Y, lo.Y), math.min(minv.Z, lo.Z)
            ) or lo
            maxv = maxv and Vector3.new(
                math.max(maxv.X, hi.X), math.max(maxv.Y, hi.Y), math.max(maxv.Z, hi.Z)
            ) or hi
        end
    end
    assert(minv and maxv, "no BaseParts available for camera framing")
    return (minv + maxv) * 0.5, maxv - minv
end

local function captureOne(name, position, target)
    local camera = Workspace.CurrentCamera
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.lookAt(position, target)
    task.wait(0.35)

    local shot = StudioCaptureService:CaptureScreenshot({
        UICaptureMode = Enum.UICaptureMode.None,
        ScreenshotFormat = Enum.StudioCaptureScreenshotFormat.PNG,
    })
    local errors = shot:GetErrors()
    assert(#errors == 0, "capture returned errors")
    assert(shot.BufferFormat == Enum.StudioCaptureScreenshotFormat.PNG,
        "capture was not returned as PNG")

    local encoded = EncodingService:Base64Encode(shot:GetBuffer())
    request("/v1/capture", {
        name = name,
        format = "PNG",
        base64 = buffer.tostring(encoded),
        resolution = {shot.Resolution.X, shot.Resolution.Y},
    })
end

local function run()
    assert(StudioCaptureService:CanCaptureScreenshot()
        or StudioCaptureService:RequestScreenshotPermissionAsync(),
        "Studio screenshot permission was not granted")

    local a = audit()
    request("/v1/record", {name = "studio-audit", record = a})
    assert(#a.errors == 0, "Studio audit contains errors; inspect collector output")

    local container = assert(Workspace:FindFirstChild("ThrixelAssets"))
    local center, size = bounds(container)
    local span = math.max(size.X, size.Y, size.Z, 12)
    local d = span * 1.35

    local views = {
        front = center + Vector3.new(0, span * 0.22, d),
        rear = center + Vector3.new(0, span * 0.22, -d),
        left = center + Vector3.new(-d, span * 0.22, 0),
        right = center + Vector3.new(d, span * 0.22, 0),
        top = center + Vector3.new(0, d, 0.01),
        gameplay = center + Vector3.new(d * 0.72, span * 0.38, d * 0.72),
    }
    for name, pos in pairs(views) do
        captureOne(name, pos, center)
    end

    print("[GoalToGame] evidence audit and captures sent to local collector")
end

button.Click:Connect(function()
    local ok, err = pcall(run)
    if not ok then
        warn("[GoalToGame] verification failed: " .. tostring(err))
    end
end)
