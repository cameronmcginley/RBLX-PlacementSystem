local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
--local componentFolder = game:GetService('ServerScriptService').Server.Components

-- Don't put player here, OnClienTevent only needs the other parameters
-- including player first will mess things up
ReplicatedStorage:WaitForChild('Select').OnClientEvent:Connect(function(tycoon, id, cost)
    -- local module = require(componentFolder:FindFirstChild("Placeable"))
    local module = require(game.ReplicatedStorage.Common:FindFirstChild("Placeable"))

    local newComp = module.new(tycoon, id, cost)
    newComp:Init()
end)