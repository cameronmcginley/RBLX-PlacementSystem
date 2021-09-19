local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService") -- for mouse input
local RunService = game:GetService('RunService') -- for RenderStepped / live input from the user 
local ReplicatedStorage = game:GetService('ReplicatedStorage') -- to define the RemoteEvent
local placeablesFolder = ReplicatedStorage.Placeables

local PlacementSystem = {}

PlacementSystem.__index = PlacementSystem

function PlacementSystem.new(tycoon, id, uuid, cost)
	local self = setmetatable({}, PlacementSystem)
	self.Tycoon = tycoon

	self.uuid = uuid
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
	table.insert(self.IgnoreList, self.Tycoon.Owner)
	return self
end

-- params: X(x position on the screen), Y(y position on the screen), IgnoreList(List of objects to ignore when making raycast)
-- returns: Instance(object that the player's mouse is on), Vector3(position that the player's mouse is on)
function PlacementSystem:getMousePoint(X, Y)
	local camera = workspace.CurrentCamera

	-- Create a new set of Raycast Parameters
	local raycastParams = RaycastParams.new()

	-- Rather than use an ignore list, just whitelist the base
	-- everything else will be ignored
	raycastParams.FilterType = Enum.RaycastFilterType.Whitelist
	raycastParams.FilterDescendantsInstances = {self.Tycoon.Model.Base}
	raycastParams.IgnoreWater = true

	local camray = camera:ScreenPointToRay(X, Y) -- get the position on the world relative to the mouse's screen position(x,y)

	-- Draw the ray in the world, pointing at wherever the mouse is
	local raycastResult = workspace:Raycast(camray.Origin, camray.Direction * 2048, raycastParams)

	-- If the draw failed, or the mouse is pointing at the sky, return nil
	if not raycastResult then return nil end

	-- Round position to nearest 1 stud for grid system
	local rawPosition = raycastResult.Position
	local roundedPosition = Vector3.new(
		math.round(rawPosition.X), 
		math.round(rawPosition.Y), 
		math.round(rawPosition.Z))

	return raycastResult.Instance, roundedPosition, raycastResult.Normal
end

function PlacementSystem:Init()
	local placeEvent = ReplicatedStorage:WaitForChild('Place') -- RemoteEvent to tell server to place object
	local hasPlaced = false
	local Placing
	local Stepped
	local debounce = false

	-- Texture the base
	self:TextureBase()

	-- Place on click
	Placing = UIS.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 and not debounce then
			debounce = true
			hasPlaced = self:PlacePosition(true, placeEvent)

			-- Verify it was actually placed
			if hasPlaced then
				-- Faster we disconnect placing the better, don't want duplicate placements
				Placing:Disconnect()
				Stepped:Disconnect()
				self:Cleanup()
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

function PlacementSystem:PlacePosition(toPlace, placeEvent)
	local mouseLocation = UIS:GetMouseLocation()
	local target, position, normal = self:getMousePoint(mouseLocation.X, mouseLocation.Y)

	if self.placeable.Parent ~= self.Tycoon.Model then
		self.placeable.Parent = self.Tycoon.Model
	end

	-- Move ghost to client target
	if target and normal and target.Name == "Base" and position then
		-- Check if inbounds
		if not self:InBounds(position) then return end

		-- Check if top face
		if PlacementSystem:NormalToFace(normal, self.Tycoon.Model.Base) ~= Enum.NormalId.Top then return end

		-- Check for collision/overlap with other items
		-- Can still move the part, but track this in case user tries to place here
		local isColliding = self:IsColliding()

		-- Position sinks into ground by half of the primary parts height, add to y
		local yOffset = self.placeable.PrimaryPart.Size.Y / 2
		position = CFrame.new(position + Vector3.new(0, yOffset, 0))
		self.placeable.PrimaryPart.CFrame = position
		
		if toPlace then
			if isColliding then
				print("Invalid placement location")
				return false
			end
			-- Pass position relative to base (corner = (0,y,0))
			position = self:GetRelPos(position)
			placeEvent:FireServer(position, self.placeableID, self.Tycoon, self.uuid)
			self.placeable:Destroy() -- Remove placeable ghost on client
			return true
		else
			return false
		end
	end
end

-- Verify the hitbox of the placeable is within base
function PlacementSystem:InBounds(placePosition)
	local hitboxSize = self.placeable.Hitbox.Size
	local basePosition = self.Tycoon.Model.Base.Position
	local baseSize = self.Tycoon.Model.Base.Size

	-- position +- half of size to get max/min coord
	local xMax = placePosition.X + hitboxSize.X / 2 <= basePosition.X + baseSize.X / 2
	local xMin = placePosition.X - hitboxSize.X / 2 >= basePosition.X - baseSize.X / 2

	local zMax = placePosition.Z + hitboxSize.Z / 2 <= basePosition.Z + baseSize.Z / 2
	local zMin = placePosition.Z - hitboxSize.Z / 2 >= basePosition.Z - baseSize.Z / 2

	return xMax and xMin and zMax and zMin
end

-- Take in actual position, return position relative to (minx, minz)
function PlacementSystem:GetRelPos(placePosition)
	local basePosition = self.Tycoon.Model.Base.Position
	local baseSize = self.Tycoon.Model.Base.Size

	local baseXMin = basePosition.X - baseSize.X / 2
	local baseZMin = basePosition.Z - baseSize.Z / 2

	return CFrame.new(placePosition.X - baseXMin, placePosition.Y, placePosition.Z - baseZMin)
end

function PlacementSystem:IsColliding()
	-- This is an extra hitbox for the object, but .2 smaller on each side
	-- since GetTouchingParts will get side-by-side parts so hitbox won't work
	local collisionDetector = self.placeable.CollisionDetector

	-- https://devforum.roblox.com/t/simple-trick-to-make-gettouchingparts-work-with-non-cancollide-parts/177450
	-- GetTouchingParts only works with cancollide, this connection bypasses that
	local connection = collisionDetector.Touched:Connect(function() end)
	local results = collisionDetector:GetTouchingParts()
	connection:Disconnect()

	for _, obj in ipairs(results) do
		if obj.Name == "CollisionDetector" then
			self.placeable.Hitbox.Color = Color3.new(255,0,0)
			return true
		end
	end
	self.placeable.Hitbox.Color = Color3.new(0, 255,0)
	return false
end

--[[**
	https://devforum.roblox.com/t/how-do-you-find-the-side-of-a-part-using-raycasting/655452
   This function returns the face that we hit on the given part based on
   an input normal. If the normal vector is not within a certain tolerance of
   any face normal on the part, we return nil.

    @param normalVector (Vector3) The normal vector we are comparing to the normals of the faces of the given part.
    @param part (BasePart) The part in question.

    @return (Enum.NormalId) The face we hit.
**--]]
function PlacementSystem:NormalToFace(normalVector, part)

    local TOLERANCE_VALUE = 1 - 0.001
    local allFaceNormalIds = {
        Enum.NormalId.Front,
        Enum.NormalId.Back,
        Enum.NormalId.Bottom,
        Enum.NormalId.Top,
        Enum.NormalId.Left,
        Enum.NormalId.Right
    }    

    for _, normalId in pairs( allFaceNormalIds ) do
        -- If the two vectors are almost parallel,
        if self:GetNormalFromFace(part, normalId):Dot(normalVector) > TOLERANCE_VALUE then
            return normalId -- We found it!
        end
    end
    
    return nil -- None found within tolerance.

end

--[[**
    This function returns a vector representing the normal for the given
    face of the given part.

    @param part (BasePart) The part for which to find the normal of the given face.
    @param normalId (Enum.NormalId) The face to find the normal of.

    @returns (Vector3) The normal for the given face.
**--]]
function PlacementSystem:GetNormalFromFace(part, normalId)
    return part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(normalId))
end

function PlacementSystem:TextureBase()
	local base = self.Tycoon.Model.Base

	base.Texture.Transparency = 0.8
	base.Material = Enum.Material.SmoothPlastic
end

function PlacementSystem:Cleanup()
	local base = self.Tycoon.Model.Base

	base.Texture.Transparency = 1
	base.Material = Enum.Material.Slate
end

return PlacementSystem
