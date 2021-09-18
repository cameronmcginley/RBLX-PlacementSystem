local CollectionService = game:GetService("CollectionService")
local template = game:GetService("ServerStorage").Template
local componentFolder = script.Parent.Components
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local tycoonStorage = game:GetService("ServerStorage").TycoonStorage
local playerManager = require(script.Parent.PlayerManager)

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



	-- Get Gui that was distributed by StarterGui
	self.PlayerGui = game:GetService('Players')[self.Owner.Name]:WaitForChild('PlayerGui')
	self.ShopGui = self.PlayerGui.ShopGui
	print(self.ShopGui)
	-- Initializite all GuiButtons in the ShopGui
	for _, descendant in pairs(self.ShopGui:GetDescendants()) do
		if descendant:IsA("TextButton") then
			print(descendant)
			local compModule = require(componentFolder:FindFirstChild("GuiButton"))
			local newComp = compModule.new(self, descendant)
			newComp:Init()
		end
	end
	

	
	self:LockAll()
	self:LoadUnlocks()
	self:WaitForExit()
	
	print("Tycoon initialized")
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
