-- Goal-to-Game secondary deterministic audit/failure-evidence plugin.
-- Roblox Studio MCP is the primary self-check and screenshot path. This plugin preserves a
-- localhost audit ledger and attempts StudioCaptureService captures when that API is supported.

local HttpService = game:GetService("HttpService")
local StudioCaptureService = game:GetService("StudioCaptureService")
local EncodingService = game:GetService("EncodingService")
local Workspace = game:GetService("Workspace")

local PORT = 43119
local TOKEN_PLACEHOLDER = "REPLACE_WITH_COLLECTOR_SESSION_TOKEN"
local TOKEN = TOKEN_PLACEHOLDER -- GOAL_TO_GAME_TOKEN_ASSIGNMENT
local BASE = ("http://127.0.0.1:%d"):format(PORT)

local toolbar = plugin:CreateToolbar("Goal to Game")
local button = toolbar:CreateButton(
    "Audit + Capture",
    "Audit imported Thrixel assets and capture reproducible evidence",
    ""
)

local function request(path, payload)
    assert(TOKEN ~= TOKEN_PLACEHOLDER, "Set TOKEN with inject_collector_token.py")
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

local function stageError(stage, detail)
    error(("[%s] %s"):format(stage, contentString(detail)), 0)
end

local function stageCall(stage, callback)
    local results = table.pack(pcall(callback))
    if not results[1] then
        stageError(stage, results[2])
    end
    return table.unpack(results, 2, results.n)
end

local function recordCaptureFailure(stage, detail)
    local ok, err = pcall(function()
        request("/v1/record", {
            name = "capture-failure",
            record = {
                schema = "goal-to-game-roblox-capture-failure-v1",
                capturedAtUnix = os.time(),
                stage = stage,
                error = contentString(detail),
                screenshotsComplete = false,
            },
        })
    end)
    if not ok then
        stageError("collector-record", ("could not record %s failure: %s"):format(
            stage, contentString(err)
        ))
    end
    stageError(stage, detail)
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

    local shot = stageCall("CaptureScreenshot", function()
        return StudioCaptureService:CaptureScreenshot({
            UICaptureMode = Enum.UICaptureMode.None,
            ScreenshotFormat = Enum.StudioCaptureScreenshotFormat.PNG,
        })
    end)
    local errors = stageCall("CaptureScreenshot", function() return shot:GetErrors() end)
    if #errors > 0 then
        local messages = {}
        for _, captureError in ipairs(errors) do
            table.insert(messages, contentString(captureError))
        end
        stageError("CaptureScreenshot", "capture returned errors: " .. table.concat(messages, "; "))
    end
    if shot.BufferFormat ~= Enum.StudioCaptureScreenshotFormat.PNG then
        stageError("CaptureScreenshot", "capture was not returned as PNG")
    end

    local pixels = stageCall("GetBuffer", function() return shot:GetBuffer() end)
    local base64 = stageCall("Base64Encode", function()
        return buffer.tostring(EncodingService:Base64Encode(pixels))
    end)
    stageCall("collector-capture", function()
        request("/v1/capture", {
            name = name,
            format = "PNG",
            base64 = base64,
            resolution = {shot.Resolution.X, shot.Resolution.Y},
        })
    end)
end

local function run()
    local a = stageCall("audit", audit)
    stageCall("collector-record", function()
        request("/v1/record", {name = "studio-audit", record = a})
    end)
    if #a.errors > 0 then
        stageError("audit", "Studio audit contains errors; inspect collector output")
    end

    local canCaptureOk, canCapture = pcall(function()
        return StudioCaptureService:CanCaptureScreenshot()
    end)
    if not canCaptureOk then
        recordCaptureFailure("CanCaptureScreenshot", canCapture)
    end

    if not canCapture then
        local permissionOk, permissionGranted = pcall(function()
            return StudioCaptureService:RequestScreenshotPermissionAsync()
        end)
        if not permissionOk then
            recordCaptureFailure("RequestScreenshotPermissionAsync", permissionGranted)
        end
        if not permissionGranted then
            recordCaptureFailure(
                "RequestScreenshotPermissionAsync",
                "Studio screenshot permission was not granted"
            )
        end
    end

    local center, size = stageCall("audit", function()
        local container = assert(
            Workspace:FindFirstChild("ThrixelAssets"),
            "Workspace.ThrixelAssets is missing"
        )
        return bounds(container)
    end)
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
        local ok, err = pcall(function() captureOne(name, pos, center) end)
        if not ok then
            local stage = contentString(err):match("^%[([^%]]+)%]") or "CaptureScreenshot"
            recordCaptureFailure(stage, err)
        end
    end

    print("[GoalToGame] evidence audit and captures sent to local collector")
end

button.Click:Connect(function()
    local ok, err = pcall(run)
    if not ok then
        warn("[GoalToGame] verification failed: " .. tostring(err))
    end
end)
