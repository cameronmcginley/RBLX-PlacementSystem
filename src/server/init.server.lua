local Tycoon = require(script.Tycoon)
local PlayerManager = require(script.PlayerManager)
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local placeablesFolder = ReplicatedStorage.Placeables

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

-- placePosition is position relative to min x and min z of the base
ReplicatedStorage:WaitForChild('Place').OnServerEvent:Connect(function(player, placePosition, placeableId, tycoon)
	print(player.Name .. " placed Id " .. placeableId .. " at ", placePosition)

	-- Get real position to place at
	local basePosition = tycoon.Model.Base.Position
	local baseSize = tycoon.Model.Base.Size
	local baseXMin = basePosition.X - baseSize.X / 2
	local baseZMin = basePosition.Z - baseSize.Z / 2
	local realPos = CFrame.new(baseXMin + placePosition.X, placePosition.Y, baseZMin + placePosition.Z)

	local Placeable = placeablesFolder:FindFirstChild(placeableId)
	local PlaceableClone = Placeable:Clone()
	PlaceableClone.PrimaryPart.CFrame = realPos

	-- Place inside of template group
	PlaceableClone.Parent = tycoon.Model
end)