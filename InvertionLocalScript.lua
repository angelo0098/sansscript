-- Place this LocalScript inside game.StarterPlayer.StarterPlayerScripts

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for the server to create the RemoteEvent
local invertEvent = ReplicatedStorage:WaitForChild("SansInvertionEvent", 9999)

local camera = workspace.CurrentCamera
local currentRoll = 0
local targetRoll = 0
local invertConnection

-- Use BindToRenderStep to run AFTER the default camera script updates (priority 201)
local function UpdateCameraRoll(dt)
	-- Check if duration is over (handled by the event connection below)
	
	-- Smoothly interpolate the screen roll
	currentRoll = currentRoll + (targetRoll - currentRoll) * math.clamp(dt * 12, 0, 1)
	
	-- Stop connection once screen returns to normal
	if targetRoll == 0 and math.abs(currentRoll) < 0.5 then
		currentRoll = 0
		RunService:UnbindFromRenderStep("SansInvertionCameraRoll")
		return
	end
	
	-- Apply the roll to the camera
	if math.abs(currentRoll) > 0.1 then
		camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(currentRoll))
	end
end

invertEvent.OnClientEvent:Connect(function(direction, duration)
	if direction == "North" then
		targetRoll = 179.9 -- Upside down
	elseif direction == "Left" then
		targetRoll = 89.9  -- 90 deg counter-clockwise
	elseif direction == "Right" then
		targetRoll = -89.9 -- 90 deg clockwise
	else
		targetRoll = 0
	end
	
	local startTime = tick()
	
	-- Unbind any existing connection first to reset it
	pcall(function() RunService:UnbindFromRenderStep("SansInvertionCameraRoll") end)
	
	RunService:BindToRenderStep("SansInvertionCameraRoll", Enum.RenderPriority.Camera.Value + 1, function(dt)
		if tick() - startTime > duration then
			targetRoll = 0
		end
		UpdateCameraRoll(dt)
	end)
end)

-- Mobile Teleport Button Logic
local mobileEvent = ReplicatedStorage:WaitForChild("SansMobileButtonEvent", 9999)
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

mobileEvent.OnClientEvent:Connect(function(show)
	local existing = playerGui:FindFirstChild("MobileTeleportButton")
	if existing then
		existing:Destroy()
	end
	
	if not show then return end
	
	local UIS = game:GetService("UserInputService")
	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "MobileTeleportButton"
	screenGui.ResetOnSpawn = false
	
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 100, 0, 100)
	frame.Position = UDim2.new(0.80, -50, 0.45, -50)
	frame.BackgroundTransparency = 1
	frame.Parent = screenGui
	
	local button = Instance.new("ImageButton")
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 0.3
	button.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
	button.Image = "rbxassetid://338425795"
	button.ImageColor3 = Color3.new(1, 1, 1)
	button.Parent = frame
	
	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	uiCorner.Parent = button
	
	local uiStroke = Instance.new("UIStroke")
	uiStroke.Color = Color3.fromRGB(255, 255, 255)
	uiStroke.Thickness = 3
	uiStroke.Parent = button
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0.35, 0)
	label.Position = UDim2.new(0, 0, 1.05, 0)
	label.BackgroundTransparency = 1
	label.Text = "TELEPORT"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.Arcade
	label.TextScaled = true
	label.Parent = button
	
	-- Only show on mobile / touch devices
	if not UIS.TouchEnabled then
		frame.Visible = false
	end
	
	local debounce = false
	button.MouseButton1Click:Connect(function()
		if debounce then return end
		debounce = true
		
		local event = nil
		for _, p in ipairs(game.Players:GetPlayers()) do
			if p.Character and p.Character:FindFirstChild("UserInput_Event") then
				event = p.Character.UserInput_Event
				break
			end
		end
		
		if event then
			event:FireServer({
				KeyCode = Enum.KeyCode.P,
				UserInputState = Enum.UserInputState.Begin
			})
		end
		
		task.wait(0.3)
		debounce = false
	end)
	
	screenGui.Parent = playerGui
end)