local PlayerManager = require(script.Parent.Parent.PlayerManager)
--local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
--local placeablesFolder = ReplicatedStorage.Placeables
local componentFolder = script.Parent
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
local HttpService = game:GetService("HttpService")

local SettingsButton = {}

SettingsButton.__index = SettingsButton

function SettingsButton.new(tycoon, part)
	local self = setmetatable({}, SettingsButton)
	self.Tycoon = tycoon
	self.Instance = part
	self.ButtonId = self.Instance:GetAttribute("Id")
	print("run")
	print(self)
	print("\n\n")
	return self
end

function SettingsButton:Init()
	print("SettingsButton init")

	local debounce = false
	local lastClick = 0

	local function onClick()
		-- Use debounce AND tick() to prevent autoclicking
		-- Autoclicking at 1ms gets 3-4 clicks past debounce, tick()
		-- can catch this though
		if not debounce then 
			debounce = true

			local thisClick = tick()
			print(thisClick)
			if thisClick - lastClick < 1 then
				warn("Autoclicking")
				lastClick = thisClick
				debounce = false
				return
			end
			lastClick = thisClick

			print("Button press")
			self:Press(self.Tycoon.Owner)
			debounce = false
			return
		end
	end

	self.clickDetect = self.Instance.MouseButton1Click:Connect(onClick)
end

function SettingsButton:Press(player, debounce)
	local debounce = false
	if not debounce then
		debounce = true


		if self.ButtonId == 0 then -- Clear placed objects
			print("Clearing placed objects")
			self:ClearPlacedObjects(player)
		end

		-- if player == self.Tycoon.Owner then
			
		-- end
		debounce = false
	end
end

function SettingsButton:DisableButton()
	print("Disabling button")
	self.Instance.Visible = false
end

function SettingsButton:EnableButton()
	print("Enabling button")
	self.Instance.Visible = true
end

function SettingsButton:ClearPlacedObjects(player)
	local data = PlayerManager.GetPlacedItems(player)
	local placedItemFolder = self.Tycoon.Model.PlacedObjects

	-- Remove physical items
	for _, item in ipairs(placedItemFolder:GetChildren()) do
		item:Destroy()
		print("Destroyed " .. item.Name)
	end

	-- Remove items from placed item data
	for index = 1, #data do
		-- Always use 1 as the index: since we remove the item each iteration
		-- the next item is moved into index 1
		local uuid = data[1][2]

		PlayerManager.RemovePlacedItem(player, uuid)
	end
end

return SettingsButton
