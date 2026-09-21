local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local character
local humanoid
local rootPart

local flying = false
local noclip = false
local speed = 60

local flyVelocity
local flyAttachment
local heartbeatConnection

local originalCollision = {}

local keys = {
	W = false,
	A = false,
	S = false,
	D = false,
	Space = false,
	LeftControl = false
}

local function setupCharacter(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	originalCollision = {}

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			originalCollision[object] = object.CanCollide
		end
	end
end

local function setNoclip(enabled)
	noclip = enabled

	if not character then
		return
	end

	for _, object in ipairs(character:GetDescendants()) do
		if object:IsA("BasePart") then
			if enabled then
				object.CanCollide = false
			elseif originalCollision[object] ~= nil then
				object.CanCollide = originalCollision[object]
			end
		end
	end
end

local function stopFlying()
	flying = false

	if heartbeatConnection then
		heartbeatConnection:Disconnect()
		heartbeatConnection = nil
	end

	if flyVelocity then
		flyVelocity:Destroy()
		flyVelocity = nil
	end

	if flyAttachment then
		flyAttachment:Destroy()
		flyAttachment = nil
	end

	if humanoid then
		humanoid.PlatformStand = false
		humanoid.AutoRotate = true
	end
end

local function startFlying()
	if not character or not humanoid or not rootPart then
		return
	end

	flying = true
	humanoid.PlatformStand = true
	humanoid.AutoRotate = false

	flyAttachment = Instance.new("Attachment")
	flyAttachment.Parent = rootPart

	flyVelocity = Instance.new("LinearVelocity")
	flyVelocity.Attachment0 = flyAttachment
	flyVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	flyVelocity.MaxForce = math.huge
	flyVelocity.VectorVelocity = Vector3.zero
	flyVelocity.Parent = rootPart

	heartbeatConnection = RunService.Heartbeat:Connect(function()
		if not character or not rootPart.Parent then
			stopFlying()
			return
		end

		if noclip then
			for _, object in ipairs(character:GetDescendants()) do
				if object:IsA("BasePart") then
					object.CanCollide = false
				end
			end
		end

		local camera = workspace.CurrentCamera
		local direction = Vector3.zero

		if keys.W then
			direction += camera.CFrame.LookVector
		end

		if keys.S then
			direction -= camera.CFrame.LookVector
		end

		if keys.D then
			direction += camera.CFrame.RightVector
		end

		if keys.A then
			direction -= camera.CFrame.RightVector
		end

		if keys.Space then
			direction += Vector3.new(0, 1, 0)
		end

		if keys.LeftControl then
			direction -= Vector3.new(0, 1, 0)
		end

		if direction.Magnitude > 0 then
			direction = direction.Unit * speed
		end

		flyVelocity.VectorVelocity = direction
		rootPart.AssemblyAngularVelocity = Vector3.zero
	end)
end

local function toggleFlying()
	if flying then
		stopFlying()
	else
		startFlying()
	end
end

local function createButton(parent, text, position)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 130, 0, 42)
	button.Position = position
	button.BackgroundColor3 = Color3.fromRGB(10, 35, 90)
	button.BackgroundTransparency = 0.15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 18
	button.Font = Enum.Font.SourceSansBold
	button.Text = text
	button.ZIndex = 3
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button

	return button
end

local function makeDraggable(frame, dragHandle)
	local dragging = false
	local dragStart
	local startPosition
	local dragInput

	dragHandle.Active = true

	local function update(input)
		local delta = input.Position - dragStart

		frame.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPosition = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragHandle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local function createAnimatedBackground(frame)
	frame.BackgroundColor3 = Color3.fromRGB(3, 15, 50)
	frame.BackgroundTransparency = 0

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 25, 90)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 130, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 20, 100))
	})
	gradient.Rotation = 25
	gradient.Parent = frame

	local spikes = {}

	for i = 1, 20 do
		local spike = Instance.new("TextLabel")
		spike.Name = "BackgroundSpike"
		spike.Size = UDim2.new(0, 45, 0, 45)
		spike.Position = UDim2.new(0, (i - 1) * 18 - 30, 0, 75)
		spike.BackgroundTransparency = 1
		spike.Text = "▲"
		spike.TextColor3 = Color3.fromRGB(0, 80, 210)
		spike.TextTransparency = 0.2
		spike.TextSize = 42
		spike.Font = Enum.Font.SourceSansBold
		spike.Rotation = 180
		spike.ZIndex = 2
		spike.Parent = frame

		table.insert(spikes, spike)
	end

	local animationTime = 0

	RunService.RenderStepped:Connect(function(deltaTime)
		if not frame.Parent then
			return
		end

		animationTime += deltaTime

		gradient.Offset = Vector2.new(
			math.sin(animationTime * 0.7) * 0.35,
			math.cos(animationTime * 0.5) * 0.15
		)

		for i, spike in ipairs(spikes) do
			local baseX = (i - 1) * 18 - 30
			local movement = math.sin(animationTime * 1.5 + i * 0.4) * 12
			local verticalMovement = math.sin(animationTime * 2 + i) * 8

			spike.Position = UDim2.new(
				0,
				baseX + movement,
				0,
				75 + verticalMovement
			)
		end
	end)
end

local function createGui()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FlightControls"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 280, 0, 145)
	frame.Position = UDim2.new(0, 20, 0.5, -70)
	frame.ClipsDescendants = true
	frame.ZIndex = 1
	frame.Parent = gui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	createAnimatedBackground(frame)

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Text = "Dank's Fly"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 20
	title.Font = Enum.Font.SourceSansBold
	title.ZIndex = 3
	title.Parent = frame

	makeDraggable(frame, title)

	local flyButton = createButton(
		frame,
		"Fly: OFF",
		UDim2.new(0, 10, 0, 45)
	)

	local noclipButton = createButton(
		frame,
		"Noclip: OFF",
		UDim2.new(0, 140, 0, 45)
	)

	local instructions = Instance.new("TextLabel")
	instructions.Size = UDim2.new(1, -20, 0, 35)
	instructions.Position = UDim2.new(0, 10, 0, 100)
	instructions.BackgroundTransparency = 1
	instructions.Text = "Q = Fly    Z = Noclip"
	instructions.TextColor3 = Color3.fromRGB(210, 230, 255)
	instructions.TextSize = 16
	instructions.Font = Enum.Font.SourceSans
	instructions.ZIndex = 3
	instructions.Parent = frame

	flyButton.MouseButton1Click:Connect(function()
		toggleFlying()
		flyButton.Text = flying and "Fly: ON" or "Fly: OFF"
	end)

	noclipButton.MouseButton1Click:Connect(function()
		setNoclip(not noclip)
		noclipButton.Text = noclip and "Noclip: ON" or "Noclip: OFF"
	end)

	return flyButton, noclipButton
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		toggleFlying()
	elseif input.KeyCode == Enum.KeyCode.Z then
		setNoclip(not noclip)
	elseif input.KeyCode == Enum.KeyCode.W then
		keys.W = true
	elseif input.KeyCode == Enum.KeyCode.A then
		keys.A = true
	elseif input.KeyCode == Enum.KeyCode.S then
		keys.S = true
	elseif input.KeyCode == Enum.KeyCode.D then
		keys.D = true
	elseif input.KeyCode == Enum.KeyCode.Space then
		keys.Space = true
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		keys.LeftControl = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then
		keys.W = false
	elseif input.KeyCode == Enum.KeyCode.A then
		keys.A = false
	elseif input.KeyCode == Enum.KeyCode.S then
		keys.S = false
	elseif input.KeyCode == Enum.KeyCode.D then
		keys.D = false
	elseif input.KeyCode == Enum.KeyCode.Space then
		keys.Space = false
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		keys.LeftControl = false
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	stopFlying()
	setNoclip(false)
	setupCharacter(newCharacter)
end)

if player.Character then
	setupCharacter(player.Character)
else
	setupCharacter(player.CharacterAdded:Wait())
end

local flyButton, noclipButton = createGui()

RunService.Heartbeat:Connect(function()
	flyButton.Text = flying and "Fly: ON" or "Fly: OFF"
	noclipButton.Text = noclip and "Noclip: ON" or "Noclip: OFF"
end)
