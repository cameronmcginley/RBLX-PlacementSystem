local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local PlayerData = DataStoreService:GetDataStore("PlayerData")

local function LeaderboardSetup(value)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = value
	money.Parent = leaderstats
	
	return leaderstats
end

local function LoadData(player)
	local success, result = pcall(function()
		return PlayerData:GetAsync(player.UserId)
	end)
	
	if not success then
		warn(result)
	end
	
	return success, result
end

local function SaveData(player, data)
	local success, result = pcall(function()
		PlayerData:SetAsync(player.UserId, data)
	end)
	
	if not success then
		warn(result)
	end

	return success
end

-- key: player use id, value: data in table
local sessionData = {}

-- call this after onplayeradded
-- cant put in PlayerManager module, so other modules dont need to say .event
-- also they cant fire it, want to keep it so only playermanager can fire it
local playerAdded = Instance.new("BindableEvent")
local playerRemoving = Instance.new("BindableEvent")

local PlayerManager = {}

PlayerManager.PlayerAdded = playerAdded.Event
PlayerManager.PlayerRemoving = playerRemoving.Event

-- hook events to proper functions
function PlayerManager.Start()
	for _, player in ipairs(Players:GetPlayers()) do
		-- coroutune allows multiple tasks to run at same time within same script
		coroutine.wrap(PlayerManager.OnPlayerAdded)(player)
	end
	
	print("PlayerManager started")
	Players.PlayerAdded:Connect(PlayerManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerManager.OnPlayerRemoving)
	
	-- runs OnClose function when game is closed
	game:BindToClose(PlayerManager.OnClose)
end

function PlayerManager.OnPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		PlayerManager.OnCharacterAdded(player, character)
	end)
	
	local success, data = LoadData(player)
	-- if success, then return data (or new table for default data)
	sessionData[player.UserId] = success and data or {
		Money = 0,
		UnlockIds = {},
		placedItems = {}
	}

	-- Do this for each in case successful load, but mising new data piece
	if not sessionData[player.UserId].placedItems then 
		sessionData[player.UserId].placedItems = {}
	end
	-- TESTING TESTING TESTING TESTING TESTING
	sessionData[player.UserId].placedItems = {}
	
	local leaderstats = LeaderboardSetup(PlayerManager.GetMoney(player))
	leaderstats.Parent = player
	
	playerAdded:Fire(player)
end

function PlayerManager.OnCharacterAdded(player, character)
	local humanoid = character:FindFirstChild("Humanoid")
	
	if humanoid then
		-- check when dies
		humanoid.Died:Connect(function()
			wait(3)
			player:LoadCharacter()
		end)
	end
end

-- leaderstats is responive to our session data, it doesnt define the session data
function PlayerManager.GetMoney(player)
	--local leaderstats = player:FindFirstChild("leaderstats")
	
	--if leaderstats then
	--	local money = leaderstats:FindFirstChild("Money")
		
	--	if money then
	--		return money.Value
	--	end
	--end
	
	--return 0
	
	return sessionData[player.UserId].Money
end

function PlayerManager.SetMoney(player, value)
	if value then
		sessionData[player.UserId].Money = value
		
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local money = leaderstats:FindFirstChild("Money")

			if money then
				money.Value = value
			end
		end
	end
end

function PlayerManager.AddUnlockId(player, id)
	local data = sessionData[player.UserId]
	
	-- checks for repeats
	if not table.find(data.UnlockIds, id) then
		table.insert(data.UnlockIds, id)
	end
end

function PlayerManager.GetUnlockIds(player)
	return sessionData[player.UserId].UnlockIds
end

function PlayerManager.OnPlayerRemoving(player)
	SaveData(player, sessionData[player.UserId])
	playerRemoving:Fire(player)
end

-- run when game is closing
function PlayerManager.OnClose()
	-- this line could cause trouble with saving in studio, comment it if needed
	-- will certainly work in the normal game though
	if game:GetService("RunService"):IsStudio() then return end
	
	for _, player in ipairs(Players:GetPlayers()) do
		coroutine.wrap(PlayerManager.OnPlayerRemoving(player))()
	end
end




-- TODO: Add rotation
-- When an item is placed down, store it in sessionData with the id and relative coords
function PlayerManager.AddPlacedItem(player, itemId, uuid, relX, relZ)
	local data = sessionData[player.UserId]
	
	-- checks for repeats
	if not table.find(data.placedItems, {itemId, uuid, relX, relZ}) then
		table.insert(data.placedItems, {itemId, uuid, relX, relZ})
	end
end

function PlayerManager.GetPlacedItems(player)
	return sessionData[player.UserId].placedItems
end

function PlayerManager.RemovePlacedItem(player, uuid)
	print(sessionData[player.UserId].placedItems)
	for index, itemArray in ipairs(sessionData[player.UserId].placedItems) do
		if table.find(itemArray, uuid) then 
			print("Removing " .. uuid .. " from PlacedItems")
			table.remove(sessionData[player.UserId].placedItems, index)
			print(sessionData[player.UserId].placedItems)
			print("\n\n\n")
			return
		end
	end
	print("UUID NOT FOUND")
end









return PlayerManager
