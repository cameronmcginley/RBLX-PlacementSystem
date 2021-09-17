local Tycoon = require(script.Tycoon)
local PlayerManager = require(script.PlayerManager)
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local function FindSpawn()
	-- loop through parts in spawns folder
	-- no failsafe for more players than spawns
	for _, spawnPoint in ipairs(workspace.Spawns:GetChildren()) do
		if not spawnPoint:GetAttribute("Occupied") then
			return spawnPoint
		end
	end
end

PlayerManager.Start()

-- Create new tycoon when player joins
PlayerManager.PlayerAdded:Connect(function(player)
	local tycoon = Tycoon.new(player, FindSpawn())
	tycoon:Init()
end)

-- Object placement
-- Waiting for client to fire RemoteEvent
ReplicatedStorage:WaitForChild('Place').OnServerEvent:Connect(function(player, placePosition, placeObject, placeTarget)
	print(player, placePosition, placeObject, placeTarget)

	local objClone = placeObject:Clone()
	objClone.PrimaryPart.CFrame = CFrame.new(placePosition)

	-- Place inside of template group
	objClone.Parent = placeTarget.Parent
end)