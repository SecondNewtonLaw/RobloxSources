--[[
	This is script is in a Work In Progress state.
	The script aims to provide a movable camera using WASD.
	
	This script has the responsability of detecting the direction of the camera (LookDirection), and creating tweens in the correct directions for movement given the movement keys.
	
	The default movement keys are WASD, this may be changed with a keybinds system, which may or may not be implemented in the future.
	
	TODO:
		- Camera movement 	[COMPLETE]
		- Camera rotation 	[COMPLETE]
		- Camera zoom		[COMPLETE]
]]

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local PlayerService = game:GetService("Players")

local ClientBase = require(game:GetService("ReplicatedStorage").Shared.ClientBase)
local LoggerModule = require(game:GetService("ReplicatedStorage").Shared.LoggerModule)

local Logger = LoggerModule.new("MovableCamera", true)
local LocalPlayer = PlayerService.LocalPlayer
local LocalPlayerMouse = LocalPlayer:GetMouse()
local MovementZone = workspace:WaitForChild("MainMap"):WaitForChild("Baseplate"):WaitForChild("MoveZone")

Logger:PrintInformation("Waiting for Character and Camera to finish loading and to initialise fully...")

game:GetService("Players").LocalPlayer.CharacterAdded:Wait()



--- Verifies if the given CFrame is in the given bounding box.
--- Returns true if the CFrame is within the object's bounding box
local function IsCFrameInBoundingBox(cFrame: CFrame, boundingBox: Part)
	local invisibleTestPart = Instance.new("Part", workspace)
	invisibleTestPart.Transparency = 1
	invisibleTestPart.CFrame = cFrame
	
	local params = OverlapParams.new()

	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {invisibleTestPart}
	
	local parts = workspace:GetPartBoundsInBox(boundingBox.CFrame, boundingBox.Size, params)
	
	invisibleTestPart:Destroy()	-- I hate having to create objects, but this will do, LOL
	return #parts > 0
end

--- Verifies if the given Part is in the given bounding box.
--- Returns true if the CFrame is within the object's bounding box
local function IsPartInBoundingBox(testPart: Part, boundingBox: Part)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {testPart}

	local parts = workspace:GetPartBoundsInBox(boundingBox.CFrame, boundingBox.Size, params)
	
	return #parts > 0
end

-- Camera Movement.
local function MoveCamera(camera: Camera, direction: number, bePerpendicular: boolean)
	local CameraSpeed = 14
	
	local oldCameraCframe = camera.CFrame
	
	local finalVector = (bePerpendicular and oldCameraCframe.LookVector:Cross(Vector3.new(0, 1, 0))) or (oldCameraCframe.LookVector)
	local newPosition = oldCameraCframe.Position + finalVector * direction * CameraSpeed
	
	local diff = math.min(newPosition.Y, oldCameraCframe.Position.Y) - math.max(newPosition.Y, oldCameraCframe.Position.Y)
	local finalY = 
		not bePerpendicular and direction == -1 and (math.max(newPosition.Y, diff) + math.min(newPosition.Y, diff)) or
		not bePerpendicular and direction == 1 and (newPosition.Y - diff) or
		math.max(newPosition.Y, diff) + math.min(newPosition.Y, diff)
	
	newPosition = Vector3.new(newPosition.X, finalY, newPosition.Z)
	
	local targetCframe = CFrame.new(newPosition, newPosition + oldCameraCframe.LookVector)
	
	if IsCFrameInBoundingBox(targetCframe, MovementZone) then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		local tween = TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Circular), { CFrame = targetCframe })
		tween:Play()
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	end
end

-- Camera rotation (Q for Left, E for Right)
local function RotateCamera(camera: Camera, rotationAngleY: number)
	local oldCameraCframe = camera.CFrame
	local position = oldCameraCframe.Position
	local rotationCFrame = CFrame.Angles(0, math.rad(rotationAngleY), 0)

	-- Move the camera to the origin, perform the rotation, and move it back (So it doesn't break everything)
	local targetCframe = CFrame.new(position) * rotationCFrame * CFrame.new(-position) * oldCameraCframe
	
	if IsCFrameInBoundingBox(targetCframe, MovementZone) then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		local tween = TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Circular), { CFrame = targetCframe })
		tween:Play()
		workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	end
end

Logger:PrintInformation("Initialising Camera Movement.")

coroutine.wrap(function()
	while task.wait() do
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then
			MoveCamera(workspace.CurrentCamera, 1)
		end		
		
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then
			MoveCamera(workspace.CurrentCamera, -1)
		end		
		
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then
			MoveCamera(workspace.CurrentCamera, -1, true)
		end		
		
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then
			MoveCamera(workspace.CurrentCamera, 1, true)
		end	
		
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then
			RotateCamera(workspace.CurrentCamera, 10)			
		end
		
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then
			RotateCamera(workspace.CurrentCamera, -10)
		end
	end
end)()

local previousZoomTween: Tween? = nil
UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessedEvent: boolean) 
	if gameProcessedEvent then return end	
	
	local ZoomFactor = 1 * 45
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		
		local newPosition
		
		if input.Position.Z > 0 then
			newPosition = workspace.CurrentCamera.CFrame.Position + workspace.CurrentCamera.CFrame.LookVector * ZoomFactor
		elseif input.Position.Z < 0 then
			newPosition = workspace.CurrentCamera.CFrame.Position - workspace.CurrentCamera.CFrame.LookVector * ZoomFactor
		end
		
		local targetCframe = CFrame.new(newPosition, newPosition + workspace.CurrentCamera.CFrame.LookVector)
		
		if not IsCFrameInBoundingBox(targetCframe, MovementZone) then
			return
		end
		
		
		if previousZoomTween then 
			previousZoomTween:Pause()
		end
		
		previousZoomTween = TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.1, Enum.EasingStyle.Sine), {
			CFrame = targetCframe
		})
		
		previousZoomTween:Play()
	end		
end)

task.wait(1)
Logger:PrintInformation("Pivotting Camera to MainMap MovementZone...")

workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
local newCameraCframe = workspace:WaitForChild("MainMap"):WaitForChild("Baseplate"):WaitForChild("CameraPivotTarget"):GetPivot() * CFrame.Angles(-math.rad(45), 0, 0)
workspace.CurrentCamera.CFrame = newCameraCframe
workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

Logger:PrintInformation("Camera Initiated!")