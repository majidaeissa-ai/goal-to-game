local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local state = Instance.new("Folder")
state.Name = "SkylineRelayState"
state:SetAttribute("Checkpoint", 0)
state:SetAttribute("TimeLeft", Config.TimeLimit)
state.Parent = ReplicatedStorage

task.spawn(function()
    while state:GetAttribute("TimeLeft") > 0 do
        task.wait(1)
        state:SetAttribute("TimeLeft", state:GetAttribute("TimeLeft") - 1)
    end
end)
