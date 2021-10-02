local CollectionService = game:GetService("CollectionService")
local template = game:GetService("ServerStorage").Template
local componentFolder = script.Parent.Components
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local tycoonStorage = game:GetService("ServerStorage").TycoonStorage
local playerManager = require(script.Parent.PlayerManager)
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
local placeablesFolder = ReplicatedStorage.Placeables

-- print("Hello")

-- clone model to given cframe
local function NewModel(model, cframe)
	local newModel = model:Clone()
	newModel:SetPrimaryPartCFrame(cframe)
	newModel.Parent = workspace
	return newModel
end

local Tycoon = {}
-- Whatever class is created, uses this to index it
Tycoon.__index = Tycoon

-- Only defines properties for tycoon
function Tycoon.new(player, spawnPoint)
	-- Creates new table with metatable set to tycoon
	local self = setmetatable({}, Tycoon)
	self.Owner = player
	
	-- _ indicates private, shouldn't be used outside of tycoon class
	self._topicEvent = Instance.new("BindableEvent")
	self._spawn = spawnPoint
	
	return self
end

-- Called after new()
function Tycoon:Init()
	self.Model = NewModel(template, self._spawn.CFrame)

	-- Disable CharacterAutoLoad in game.Players
	self.Owner.RespawnLocation = self.Model.Spawn
	self.Owner:LoadCharacter()
	self._spawn:SetAttribute("Occupied", true)

	-- Get Guis that were distributed by StarterGui
	self.PlayerGui = game:GetService('Players')[self.Owner.Name]:WaitForChild('PlayerGui')
	self.ShopGui = self.PlayerGui.ShopGui
	self.SettingsGui = self.PlayerGui.SettingsGui

	-- Initializite all GuiButtons in the ShopGui
	for _, descendant in pairs(self.ShopGui:GetDescendants()) do
		if descendant:IsA("TextButton") then
			local compModule = require(componentFolder:FindFirstChild("PlaceableButton"))
			local newComp = compModule.new(self, descendant)
			newComp:Init()
		end
	end

	-- Initializite all GuiButtons in the SettingsGui
	for _, descendant in pairs(self.SettingsGui:GetDescendants()) do
		if descendant:IsA("TextButton") then
			local compModule = require(componentFolder:FindFirstChild("SettingsButton"))
			local newComp = compModule.new(self, descendant)
			newComp:Init()
			print(descendant)
		end
	end
	
	self:LockAll()
	self:LoadUnlocks()
	self:WaitForExit()

	self:BuildPlacedItemsData()
	
	print("Tycoon initialized")
end

-- On join, fetch PlacedItems data and build them
function Tycoon:BuildPlacedItemsData()
	local data = playerManager.GetPlacedItems(self.Owner)
	local placeEvent = ReplicatedStorage:WaitForChild('Place')

	for index = 1, #data do
		print(index)
		-- Always use 1 as the index: since we remove the item each iteration
		-- the next item is moved into index 1
		local itemId = data[1][1]
		local uuid = data[1][2]
		local relX = data[1][3]
		local relZ = data[1][4]
		local rotY = data[1][5]

		-- In case not saved
		if not rotY then rotY = 0 end

		-- Remove this piece of data before placing (placement will re-add it)
		print("Removing " .. uuid)
		playerManager.RemovePlacedItem(self.Owner, uuid)

		-- Build the item again
		-- placeEvent:FireServer(position, self.placeableID, self.Tycoon, self.uuid)
		self:BuildSavedItem(itemId, uuid, relX, relZ, rotY)
	end
end

function Tycoon:BuildSavedItem(itemId, uuid, relX, relZ, rotY)
	-- Check PlacedItems data to ensure id + uuid aren't already placed
	local data = playerManager.GetPlacedItems(self.Owner)

	for _, itemArray in ipairs(data) do
		if table.find(itemArray, uuid) then 
			error("Item " .. uuid .. "already placed")
			return 
		end
	end
	print("UUID unique, placing saved part...")

	print(self.Owner.Name .. " placed Id " .. itemId .. " at ", relX, relZ)

	local Placeable = placeablesFolder:FindFirstChild(itemId)

	-- Get real position to place at
	local basePosition = self.Model.Base.Position
	local baseSize = self.Model.Base.Size
	local baseXMin = basePosition.X - baseSize.X / 2
	local baseZMin = basePosition.Z - baseSize.Z / 2
	local baseY = basePosition.Y + baseSize.Y / 2
	local realPos = CFrame.new(baseXMin + relX, baseY + Placeable.Hitbox.Size.Y / 2, baseZMin + relZ)
	local realPos = realPos * CFrame.Angles(0, math.rad(rotY), 0)

	local PlaceableClone = Placeable:Clone()
	PlaceableClone.PrimaryPart.CFrame = realPos

	-- Place inside of template group
	PlaceableClone.Parent = self.Model.PlacedObjects

	-- Store in PlayerManager data that this has been placed
	-- Since we use this data to place these items on join also, make sure to remove
	-- the item from data before placing it again
	-- Passes relative pos, not real pos
	playerManager.AddPlacedItem(self.Owner, itemId, uuid, relX, relZ, rotY)
end

-- on join, load saved unlocks
function Tycoon:LoadUnlocks()
	for _, id in ipairs(playerManager.GetUnlockIds(self.Owner)) do
		-- simulating button press for the unlock
		self:PublishTopic("Button", id)
	end
end

-- Look through everything in Model, lock those with unlockable tag
function Tycoon:LockAll()
	for _, instance in ipairs(self.Model:GetDescendants()) do
		if CollectionService:HasTag(instance, "Unlockable") then
			self:Lock(instance)
		else
			-- spawn it if not an unlockable
			self:AddComponents(instance)
		end
	end
end

function Tycoon:Lock(instance)
	-- spawn in then move to tycoonStorage to retain position info
	instance.Parent = tycoonStorage
	
	-- listen for unlock
	self:CreateComponent(instance, componentFolder.Unlockable)
end

function Tycoon:Unlock(instance, id)
	-- When unlocking object, add it to to table of unlocked ids
	playerManager.AddUnlockId(self.Owner, id)
	
	CollectionService:RemoveTag(instance, "Unlockable")
	self:AddComponents(instance)
	instance.Parent = self.Model
end

function Tycoon:AddComponents(instance)
	-- Get all of the tags on a component
	for _, tag in ipairs(CollectionService:GetTags(instance)) do
		-- safe approach to check if component exists
		local component = componentFolder:FindFirstChild(tag)
		
		if component then
			self:CreateComponent(instance, component)
		end
	end
end

function Tycoon:CreateComponent(instance, componentScript)
	--print(instance)
	--print(componentScript)
	local compModule = require(componentScript)
	--print(compModule)
	-- module needs tycoon reference, give it 'self'
	local newComp = compModule.new(self, instance)
	
	newComp:Init()
end

-- https://wiki.ros.org/Topics
-- nodes can publish or subscribe to 'topics' to get or send info
-- nodes can not see eachother
function Tycoon:PublishTopic(topicName, ...)
	self._topicEvent:Fire(topicName, ...)
end

-- callback is function
function Tycoon:SubscribeTopic(topicName, callback)
	local connection = self._topicEvent.Event:Connect(function(name, ...)
		if name == topicName then
			callback(...)
		end
	end)
	return connection
end

function Tycoon:WaitForExit()
	playerManager.PlayerRemoving:Connect(function(player)
		if self.Owner == player then
			self:Destroy()
		end
	end)
end

-- Called when player leaves
function Tycoon:Destroy()
	self.Model:Destroy()
	self._spawn:SetAttribute("Occupied", false)
	
	-- destroy bindable events
	self._topicEvent:Destroy()
end








return Tycoon
