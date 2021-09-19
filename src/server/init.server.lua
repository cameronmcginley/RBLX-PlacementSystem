local Tycoon = require(script.Tycoon)
local PlayerManager = require(script.PlayerManager)
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local placeablesFolder = ReplicatedStorage.Placeables

local function FindSpawn()
	local debounce = false

	repeat wait() until not debounce
	debounce = true

	-- loop through parts in spawns folder
	-- no failsafe for more players than spawns
	for _, spawnPoint in ipairs(workspace.Spawns:GetChildren()) do
		if not spawnPoint:GetAttribute("Occupied") then
			print(spawnPoint.Name)
			debounce = false
			return spawnPoint
		end
	end

	warn("No unoccupied spawns")
	debounce = false
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
ReplicatedStorage:WaitForChild('Place').OnServerEvent:Connect(function(player, placePosition, placeableId, tycoon, uuid)
	-- Check PlacedItems data to ensure id + uuid aren't already placed
	local data = PlayerManager.GetPlacedItems(player)
	print(data)

	for _, itemArray in ipairs(data) do
		if table.find(itemArray, uuid) then 
			error("Item " .. uuid .. "already placed")
			return 
		end
	end
	print("UUID unique, placing...")

	-- if data and table.find(data.placedItems, uuid) then
	-- 	error("Item " .. uuid .. "already placed")
	-- 	return
	-- end

	print(player.Name .. " placed Id " .. placeableId .. " at ", placePosition, " (relative)")

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

	-- Store in PlayerManager data that this has been placed
	-- Since we use this data to place these items on join also, make sure to remove
	-- the item from data before placing it again
	-- Passes relative pos, not real pos
	PlayerManager.AddPlacedItem(player, placeableId, uuid, placePosition.X, placePosition.Z)
end)