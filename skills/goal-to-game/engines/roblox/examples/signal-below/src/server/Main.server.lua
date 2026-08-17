local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local state = Instance.new("Folder")
state.Name = "SignalBelowState"
state:SetAttribute("RelaysRestored", 0)
state:SetAttribute("RoundSeconds", Config.RoundSeconds)
state.Parent = ReplicatedStorage

-- Final asset pass: a Thrixel-generated dish under Workspace.ThrixelAssets/SignalDish
-- must be tagged GoalToGameAsset=true, with its rotating dish tagged GoalToGameMovingPart=true.
task.spawn(function()
    while state:GetAttribute("RoundSeconds") > 0 do
        task.wait(1)
        state:SetAttribute("RoundSeconds", state:GetAttribute("RoundSeconds") - 1)
    end
end)
