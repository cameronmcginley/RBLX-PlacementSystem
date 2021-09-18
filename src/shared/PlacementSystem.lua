local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService") -- for mouse input
local RunService = game:GetService('RunService') -- for RenderStepped / live input from the user 
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
local placeablesFolder = ReplicatedStorage.Placeables

local Placeable = {}

Placeable.__index = Placeable

function Placeable.new(tycoon, id, cost)
	local self = setmetatable({}, Placeable)
	self.Tycoon = tycoon

	self.placeableID = id
	local placeableOriginal = placeablesFolder:FindFirstChild(id)

	-- Cloned via client, CAN NOT PASS THIS TO SERVER
	-- Pass its id instead, then clone new one from serverstorage
	self.placeable = placeablesFolder:WaitForChild(placeableOriginal.Name):clone()

	-- Ignore list
	-- Everything inside tycoon model + user
	self.IgnoreList = self.Tycoon.Model:GetDescendants()
	table.insert(self.IgnoreList, self.placeable)
	table.remove(self.IgnoreList, table.find(self.IgnoreList, self.Tycoon.Model.Base))

	return self
end

-- params: X(x position on the screen), Y(y position on the screen), IgnoreList(List of objects to ignore when making raycast)
-- returns: Instance(object that the player's mouse is on), Vector3(position that the player's mouse is on)
function Placeable:getMousePoint(X, Y)
	local camera = workspace.CurrentCamera

	-- Create a new set of Raycast Parameters
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Blacklist -- have the mouse ignore objects
	raycastParams.FilterDescendantsInstances = self.IgnoreList -- have the mouse ignore the bed
	raycastParams.IgnoreWater = true

	local camray = camera:ScreenPointToRay(X, Y) -- get the position on the world relative to the mouse's screen position(x,y)

	-- Draw the ray in the world, pointing at wherever the mouse is
	local raycastResult = workspace:Raycast(camray.Origin, camray.Direction * 2048, raycastParams)

	-- If the draw failed, or the mouse is pointing at the sky, return nil
	if not raycastResult then return nil end

	-- Otherwise, return the part and position the mouse is over
	return raycastResult.Instance, raycastResult.Position
end

function Placeable:Init()
	local placeEvent = ReplicatedStorage:WaitForChild('Place') -- RemoteEvent to tell server to place object
	local hasPlaced = false
	local Placing
	local Stepped
	local debounce = false

	-- Place on click
	Placing = UIS.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 and not debounce then
			debounce = true
			hasPlaced = self:PlacePosition(true, placeEvent)

			-- Verify it was actually placed, above fires on invalid positions still
			if hasPlaced then
				-- Faster we disconnect placing the better, don't want duplicate placements
				Placing:Disconnect()
				Stepped:Disconnect()
			end

			debounce = false
		end
	end)

	-- Move ghost with mouse
	-- RenderStepped will run every frame for the client (60ish times a second)
	Stepped = RunService.RenderStepped:Connect(function()
		self:PlacePosition(false, placeEvent)
	end)
end

function Placeable:PlacePosition(toPlace, placeEvent)
	local mouseLocation = UIS:GetMouseLocation()
	local target, position = self:getMousePoint(mouseLocation.X, mouseLocation.Y, self.IgnoreList)

	if self.placeable.Parent ~= self.Tycoon.Model then
		self.placeable.Parent = self.Tycoon.Model
	end

	-- Move ghost to client target
	if target and target.Name == "Base" and position then
		-- Position sinks into ground by half of the primary parts height, add to y
		local yOffset = self.placeable.PrimaryPart.Size.Y / 2
		position = CFrame.new(position + Vector3.new(0, yOffset, 0))
		self.placeable.PrimaryPart.CFrame = position
		
		if toPlace then
			-- Pass desired position and id of desired placeable
			placeEvent:FireServer(position, self.placeableID, self.Tycoon.Model)
			self.placeable:Destroy() -- Remove placeable ghost on client
			return true
		else
			return false
		end
	end
end

return Placeable
