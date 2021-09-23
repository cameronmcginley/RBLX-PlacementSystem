local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent

-- Wait for message from Select remote event, triggered by guibutton
ReplicatedStorage:WaitForChild('Select').OnClientEvent:Connect(function(tycoon, id, uuid, cost)
    local module = require(game.ReplicatedStorage.Common:FindFirstChild("PlacementSystem"))

    -- Run placement system module
    local newComp = module.new(tycoon, id, uuid, cost)
    newComp:Init()
end)