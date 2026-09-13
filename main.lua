local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local MAX_DISTANCE = 100
local TURN_SPEED = 0.18

local lockOn = false
local target = nil

-- Ragdoll state
local wasRagdoll = false
local restoreAfterRagdoll = false
local ragdollTarget = nil

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "WhyyCombat"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local uiScale = Instance.new("UIScale")
uiScale.Scale = 1
uiScale.Parent = gui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(380, 300)
main.Position = UDim2.new(0.5, -190, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
main.BorderSizePixel = 0
main.Parent = gui

local originalSize = main.Size
local originalPosition = main.Position

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(55, 55, 70)
mainStroke.Thickness = 1
mainStroke.Parent = main

--==================================================
-- MENU ANIMATION
--==================================================

local menuOpen = true
local animationRunning = false

local function openMenu()
	if menuOpen or animationRunning then
		return
	end

	animationRunning = true

	main.Visible = true
	main.BackgroundTransparency = 1
	main.Size = UDim2.fromOffset(330, 260)
	main.Position = UDim2.new(0.5, -165, 0.5, -130)

	local tween = TweenService:Create(
		main,
		TweenInfo.new(
			0.32,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Size = originalSize,
			Position = originalPosition,
			BackgroundTransparency = 0
		}
	)

	tween:Play()

	tween.Completed:Once(function()
		menuOpen = true
		animationRunning = false
	end)
end

local function closeMenu()
	if not menuOpen or animationRunning then
		return
	end

	animationRunning = true

	local tween = TweenService:Create(
		main,
		TweenInfo.new(
			0.24,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.In
		),
		{
			Size = UDim2.fromOffset(330, 260),
			Position = UDim2.new(0.5, -165, 0.5, -130),
			BackgroundTransparency = 1
		}
	)

	tween:Play()

	tween.Completed:Once(function()
		main.Visible = false
		main.Size = originalSize
		main.Position = originalPosition
		main.BackgroundTransparency = 0

		menuOpen = false
		animationRunning = false
	end)
end

local function toggleMenu()
	if menuOpen then
		closeMenu()
	else
		openMenu()
	end
end

--==================================================
-- NOTIFICATIONS
--==================================================

local notifications = Instance.new("Frame")
notifications.Name = "Notifications"
notifications.AnchorPoint = Vector2.new(1, 1)
notifications.Position = UDim2.new(1, -20, 1, -20)
notifications.Size = UDim2.fromOffset(300, 250)
notifications.BackgroundTransparency = 1
notifications.Parent = gui

local notificationLayout = Instance.new("UIListLayout")
notificationLayout.FillDirection = Enum.FillDirection.Vertical
notificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
notificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
notificationLayout.Padding = UDim.new(0, 8)
notificationLayout.Parent = notifications

local function notify(titleText, messageText, enabled)

	local notification = Instance.new("Frame")
	notification.Size = UDim2.fromOffset(280, 65)
	notification.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
	notification.BackgroundTransparency = 1
	notification.BorderSizePixel = 0
	notification.Parent = notifications

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = notification

	local stroke = Instance.new("UIStroke")
	stroke.Color = enabled
		and Color3.fromRGB(85, 85, 230)
		or Color3.fromRGB(80, 80, 90)
	stroke.Thickness = 1
	stroke.Transparency = 1
	stroke.Parent = notification

	local indicator = Instance.new("Frame")
	indicator.Size = UDim2.fromOffset(4, 38)
	indicator.Position = UDim2.fromOffset(10, 13)
	indicator.BackgroundColor3 = enabled
		and Color3.fromRGB(85, 85, 230)
		or Color3.fromRGB(100, 100, 110)
	indicator.BackgroundTransparency = 1
	indicator.BorderSizePixel = 0
	indicator.Parent = notification

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator

	local title = Instance.new("TextLabel")
	title.Position = UDim2.fromOffset(25, 10)
	title.Size = UDim2.new(1, -35, 0, 22)
	title.BackgroundTransparency = 1
	title.Text = titleText
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = 1
	title.Parent = notification

	local message = Instance.new("TextLabel")
	message.Position = UDim2.fromOffset(25, 33)
	message.Size = UDim2.new(1, -35, 0, 20)
	message.BackgroundTransparency = 1
	message.Text = messageText
	message.TextColor3 = Color3.fromRGB(145, 145, 160)
	message.TextSize = 11
	message.Font = Enum.Font.Gotham
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextTransparency = 1
	message.Parent = notification

	TweenService:Create(
		notification,
		TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0}
	):Play()

	TweenService:Create(title, TweenInfo.new(0.2), {
		TextTransparency = 0
	}):Play()

	TweenService:Create(message, TweenInfo.new(0.2), {
		TextTransparency = 0
	}):Play()

	TweenService:Create(stroke, TweenInfo.new(0.2), {
		Transparency = 0
	}):Play()

	TweenService:Create(indicator, TweenInfo.new(0.2), {
		BackgroundTransparency = 0
	}):Play()

	-- Важно:
	-- каждое уведомление самостоятельно удаляется,
	-- никаких повторных restore-циклов здесь нет.
	task.delay(1.5, function()

		if not notification.Parent then
			return
		end

		local hideTween = TweenService:Create(
			notification,
			TweenInfo.new(
				0.25,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			),
			{
				Position = UDim2.fromOffset(30, 0),
				BackgroundTransparency = 1
			}
		)

		hideTween:Play()

		TweenService:Create(title, TweenInfo.new(0.2), {
			TextTransparency = 1
		}):Play()

		TweenService:Create(message, TweenInfo.new(0.2), {
			TextTransparency = 1
		}):Play()

		TweenService:Create(stroke, TweenInfo.new(0.2), {
			Transparency = 1
		}):Play()

		TweenService:Create(indicator, TweenInfo.new(0.2), {
			BackgroundTransparency = 1
		}):Play()

		hideTween.Completed:Once(function()

			if notification then
				notification:Destroy()
			end

		end)
	end)
end

--==================================================
-- HEADER
--==================================================

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 70)
header.BackgroundTransparency = 1
header.Parent = main

local logo = Instance.new("TextLabel")
logo.Size = UDim2.fromOffset(45, 45)
logo.Position = UDim2.fromOffset(15, 12)
logo.BackgroundColor3 = Color3.fromRGB(85, 85, 235)
logo.Text = "W"
logo.TextColor3 = Color3.new(1, 1, 1)
logo.TextSize = 25
logo.Font = Enum.Font.GothamBold
logo.Parent = header

local logoCorner = Instance.new("UICorner")
logoCorner.CornerRadius = UDim.new(0, 10)
logoCorner.Parent = logo

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(72, 10)
title.Size = UDim2.new(1, -125, 0, 28)
title.BackgroundTransparency = 1
title.Text = "WHYY LOCK-ON"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 19
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.fromOffset(72, 38)
subtitle.Size = UDim2.new(1, -125, 0, 18)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Combat assistance"
subtitle.TextColor3 = Color3.fromRGB(140, 140, 155)
subtitle.TextSize = 12
subtitle.Font = Enum.Font.Gotham
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 32)
close.Position = UDim2.new(1, -45, 0, 18)
close.BackgroundColor3 = Color3.fromRGB(35, 35, 43)
close.Text = "×"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 22
close.Font = Enum.Font.GothamBold
close.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = close

close.MouseButton1Click:Connect(closeMenu)

--==================================================
-- DRAG
--==================================================

local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then

		dragging = true
	dragStart = input.Position
	startPosition = main.Position

	end
end)

header.InputEnded:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UserInputService.InputChanged:Connect(function(input)

	if not dragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	local delta = input.Position - dragStart

	main.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end)

--==================================================
-- CARD
--==================================================

local function createCard(y, height)

	local card = Instance.new("Frame")
	card.Position = UDim2.fromOffset(15, y)
	card.Size = UDim2.new(1, -30, 0, height)
	card.BackgroundColor3 = Color3.fromRGB(20, 20, 27)
	card.BorderSizePixel = 0
	card.Parent = main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = card

	return card
end

--==================================================
-- LOCK CARD
--==================================================

local lockCard = createCard(80, 90)

local lockTitle = Instance.new("TextLabel")
lockTitle.Position = UDim2.fromOffset(15, 10)
lockTitle.Size = UDim2.fromOffset(200, 25)
lockTitle.BackgroundTransparency = 1
lockTitle.Text = "Lock-On"
lockTitle.TextColor3 = Color3.new(1, 1, 1)
lockTitle.TextSize = 15
lockTitle.Font = Enum.Font.GothamBold
lockTitle.TextXAlignment = Enum.TextXAlignment.Left
lockTitle.Parent = lockCard

local lockInfo = Instance.new("TextLabel")
lockInfo.Position = UDim2.fromOffset(15, 38)
lockInfo.Size = UDim2.fromOffset(300, 20)
lockInfo.BackgroundTransparency = 1
lockInfo.Text = "E = lock  •  MMB = switch"
lockInfo.TextColor3 = Color3.fromRGB(135, 135, 150)
lockInfo.TextSize = 12
lockInfo.Font = Enum.Font.Gotham
lockInfo.TextXAlignment = Enum.TextXAlignment.Left
lockInfo.Parent = lockCard

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.fromOffset(75, 32)
toggle.Position = UDim2.new(1, -90, 0, 28)
toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
toggle.Text = "OFF"
toggle.TextColor3 = Color3.fromRGB(170, 170, 180)
toggle.TextSize = 12
toggle.Font = Enum.Font.GothamBold
toggle.Parent = lockCard

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 8)
toggleCorner.Parent = toggle

local function updateToggle()

	if lockOn then

		toggle.Text = "ON"
		toggle.BackgroundColor3 = Color3.fromRGB(85, 85, 230)
		toggle.TextColor3 = Color3.new(1, 1, 1)

	else

		toggle.Text = "OFF"
		toggle.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		toggle.TextColor3 = Color3.fromRGB(170, 170, 180)

	end
end

--==================================================
-- FIND NEAREST TARGET
--==================================================

local function getNearestTarget()

	local character = player.Character

	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")

	if not root then
		return nil
	end

	local nearest = nil
	local nearestDistance = MAX_DISTANCE

	for _, other in ipairs(Players:GetPlayers()) do

		if other ~= player and other.Character then

			local otherRoot =
				other.Character:FindFirstChild("HumanoidRootPart")

			local humanoid =
				other.Character:FindFirstChildOfClass("Humanoid")

			if otherRoot
				and humanoid
				and humanoid.Health > 0 then

				local distance =
					(root.Position - otherRoot.Position).Magnitude

				if distance < nearestDistance then

					nearest = other
					nearestDistance = distance

				end
			end
		end
	end

	return nearest
end

--==================================================
-- SWITCH TARGET
-- MIDDLE MOUSE BUTTON
--==================================================

local function switchTarget()

	if not lockOn then
		return
	end

	if wasRagdoll then
		return
	end

	local character = player.Character

	if not character then
		return
	end

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local candidates = {}

	for _, other in ipairs(Players:GetPlayers()) do

		if other ~= player and other.Character then

			local otherRoot =
				other.Character:FindFirstChild("HumanoidRootPart")

			local humanoid =
				other.Character:FindFirstChildOfClass("Humanoid")

			if otherRoot
				and humanoid
				and humanoid.Health > 0 then

				local distance =
					(root.Position - otherRoot.Position).Magnitude

				if distance <= MAX_DISTANCE then

					table.insert(
						candidates,
						{
							player = other,
							distance = distance
						}
					)

				end
			end
		end
	end

	table.sort(
		candidates,
		function(a, b)
			return a.distance < b.distance
		end
	)

	if #candidates == 0 then

		target = nil
		return

	end

	if not target then

		target = candidates[1].player
		return

	end

	local currentIndex = nil

	for i, data in ipairs(candidates) do

		if data.player == target then

			currentIndex = i
			break

		end
	end

	if not currentIndex then

		target = candidates[1].player
		return

	end

	local nextIndex = currentIndex + 1

	if nextIndex > #candidates then
		nextIndex = 1
	end

	target = candidates[nextIndex].player
end

--==================================================
-- SET LOCK ON
--==================================================

local function setLockOn(state, showNotification)

	if lockOn == state then
		return
	end

	lockOn = state

	local character = player.Character

	local humanoid =
		character
		and character:FindFirstChildOfClass("Humanoid")

	if lockOn then

		target = getNearestTarget()

		if humanoid then
			humanoid.AutoRotate = false
		end

		if showNotification ~= false then

			notify(
				"Lock-On enabled",
				"Target tracking is now active",
				true
			)

		end

	else

		if humanoid then
			humanoid.AutoRotate = true
		end

		if showNotification ~= false then

			notify(
				"Lock-On disabled",
				"Target tracking is now inactive",
				false
			)

		end
	end

	updateToggle()
end

toggle.MouseButton1Click:Connect(function()

	if wasRagdoll then
		return
	end

	setLockOn(not lockOn)

end)

--==================================================
-- TARGET CARD
--==================================================

local targetCard = createCard(180, 85)

local targetTitle = Instance.new("TextLabel")
targetTitle.Position = UDim2.fromOffset(15, 10)
targetTitle.Size = UDim2.fromOffset(150, 20)
targetTitle.BackgroundTransparency = 1
targetTitle.Text = "Current target"
targetTitle.TextColor3 = Color3.fromRGB(150, 150, 165)
targetTitle.TextSize = 12
targetTitle.Font = Enum.Font.Gotham
targetTitle.TextXAlignment = Enum.TextXAlignment.Left
targetTitle.Parent = targetCard

local targetText = Instance.new("TextLabel")
targetText.Position = UDim2.fromOffset(15, 32)
targetText.Size = UDim2.new(1, -30, 0, 30)
targetText.BackgroundTransparency = 1
targetText.Text = "No target"
targetText.TextColor3 = Color3.new(1, 1, 1)
targetText.TextSize = 15
targetText.Font = Enum.Font.GothamBold
targetText.TextXAlignment = Enum.TextXAlignment.Left
targetText.Parent = targetCard

--==================================================
-- RAGDOLL DETECTION
--==================================================

local function isRagdoll(humanoid)

	if not humanoid then
		return false
	end

	local state = humanoid:GetState()

	return (
		state == Enum.HumanoidStateType.Ragdoll
		or state == Enum.HumanoidStateType.FallingDown
	)

end

--==================================================
-- RAGDOLL START
--==================================================

local function beginRagdoll(humanoid)

	-- Уже обрабатываем ragdoll
	if wasRagdoll then
		return
	end

	wasRagdoll = true

	-- Сохраняем только если Lock-On реально был включен
	restoreAfterRagdoll = lockOn

	-- Сохраняем именно текущую цель
	if restoreAfterRagdoll then
		ragdollTarget = target
	else
		ragdollTarget = nil
	end

	-- Полностью выключаем Lock-On
	lockOn = false

	-- Не удаляем target.
	-- Он хранится в ragdollTarget.
	target = nil

	humanoid.AutoRotate = true

	updateToggle()

	-- Только ОДНО уведомление на начало ragdoll
	if restoreAfterRagdoll then

		notify(
			"Lock-On paused",
			"Waiting for ragdoll to end",
			false
		)

	end
end

--==================================================
-- RAGDOLL END
--==================================================

local function endRagdoll(character, humanoid)

	-- Защита от повторного вызова
	if not wasRagdoll then
		return
	end

	wasRagdoll = false

	-- Если Lock-On не был включен до ragdoll,
	-- ничего не восстанавливаем.
	if not restoreAfterRagdoll then

		ragdollTarget = nil
		return

	end

	restoreAfterRagdoll = false

	local savedTarget = ragdollTarget
	ragdollTarget = nil

	if not character
		or character ~= player.Character
		or not humanoid then

		return
	end

	-- Проверяем, что персонаж действительно вышел
	-- из ragdoll.
	if isRagdoll(humanoid) then
		return
	end

	if not savedTarget then

		humanoid.AutoRotate = true
		updateToggle()

		return

	end

	if not savedTarget.Parent then

		humanoid.AutoRotate = true
		updateToggle()

		return

	end

	local targetCharacter =
		savedTarget.Character

	if not targetCharacter then

		humanoid.AutoRotate = true
		updateToggle()

		return

	end

	local targetRoot =
		targetCharacter:FindFirstChild("HumanoidRootPart")

	local targetHumanoid =
		targetCharacter:FindFirstChildOfClass("Humanoid")

	local root =
		character:FindFirstChild("HumanoidRootPart")

	if not targetRoot
		or not targetHumanoid
		or not root
		or targetHumanoid.Health <= 0 then

		humanoid.AutoRotate = true
		updateToggle()

		return

	end

	local distance =
		(root.Position - targetRoot.Position).Magnitude

	-- Если цель слишком далеко,
	-- не включаем Lock-On.
	if distance > MAX_DISTANCE then

		humanoid.AutoRotate = true
		updateToggle()

		return

	end

	--==================================================
	-- ВОССТАНОВЛЕНИЕ
	--==================================================

	target = savedTarget
	lockOn = true

	humanoid.AutoRotate = false

	updateToggle()

	-- ВАЖНО:
	-- это единственное место, где создаётся
	-- уведомление о восстановлении.
	notify(
		"Lock-On restored",
		"Target tracking resumed",
		true
	)
end

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

	local character = player.Character

	if not character then
		return
	end

	local root =
		character:FindFirstChild("HumanoidRootPart")

	local humanoid =
		character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid then
		return
	end

	--================================================
	-- RAGDOLL
	--================================================

	local currentlyRagdoll =
		isRagdoll(humanoid)

	-- Начало ragdoll
	if currentlyRagdoll and not wasRagdoll then

		beginRagdoll(humanoid)

	end

	--================================================
	-- ПОКА RAGDOLL
	--================================================

	if currentlyRagdoll then

		humanoid.AutoRotate = true

		if ragdollTarget
			and ragdollTarget.Character then

			local savedHumanoid =
				ragdollTarget.Character:FindFirstChildOfClass(
					"Humanoid"
				)

			if savedHumanoid
				and savedHumanoid.Health > 0 then

				targetText.Text =
					ragdollTarget.DisplayName
					.. "  •  Ragdoll"

			else

				ragdollTarget = nil
				restoreAfterRagdoll = false

				targetText.Text = "No target"

			end

		else

			if restoreAfterRagdoll then
				restoreAfterRagdoll = false
			end

			ragdollTarget = nil
			targetText.Text = "No target"

		end

		return
	end

	--================================================
	-- RAGDOLL JUST ENDED
	--================================================

	if wasRagdoll then

		endRagdoll(
			character,
			humanoid
		)

	end

	--================================================
	-- LOCK OFF
	--================================================

	if not lockOn then

		targetText.Text = "No target"

		humanoid.AutoRotate = true

		return

	end

	--================================================
	-- LOCK ON
	--================================================

	humanoid.AutoRotate = false

	if not target then

		lockOn = false
		humanoid.AutoRotate = true

		updateToggle()

		targetText.Text = "No target"

		return
	end

	if not target.Character then

		target = nil
		lockOn = false
		humanoid.AutoRotate = true

		updateToggle()

		targetText.Text = "No target"

		return
	end

	local targetRoot =
		target.Character:FindFirstChild("HumanoidRootPart")

	local targetHumanoid =
		target.Character:FindFirstChildOfClass("Humanoid")

	if not targetRoot
		or not targetHumanoid
		or targetHumanoid.Health <= 0 then

		target = nil
		lockOn = false
		humanoid.AutoRotate = true

		updateToggle()

		targetText.Text = "No target"

		return
	end

	--================================================
	-- DISTANCE
	--================================================

	local distance =
		(root.Position - targetRoot.Position).Magnitude

	if distance > MAX_DISTANCE then

		target = nil
		lockOn = false
		humanoid.AutoRotate = true

		updateToggle()

		targetText.Text = "No target"

		return
	end

	--================================================
	-- FACE TARGET
	--================================================

	local direction =
		targetRoot.Position - root.Position

	direction = Vector3.new(
		direction.X,
		0,
		direction.Z
	)

	if direction.Magnitude > 0.01 then

		local desired =
			CFrame.lookAt(
				root.Position,
				root.Position + direction
			)

		root.CFrame =
			root.CFrame:Lerp(
				desired,
				TURN_SPEED
			)

	end

	--================================================
	-- TARGET INFO
	--================================================

	targetText.Text =
		target.DisplayName
		.. "  •  "
		.. math.floor(distance)
		.. " studs"

end)

--==================================================
-- KEYBOARD
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)

	if processed then
		return
	end

	-- E = Lock-On
	if input.KeyCode == Enum.KeyCode.E then

		if wasRagdoll then
			return
		end

		setLockOn(not lockOn)
		return

	end

	-- K = Menu
	if input.KeyCode == Enum.KeyCode.K then

		toggleMenu()
		return

	end

end)

--==================================================
-- MIDDLE MOUSE BUTTON
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)

	if processed then
		return
	end

	-- Нажатие колёсика мыши
	if input.UserInputType == Enum.UserInputType.MouseButton3 then

		if wasRagdoll then
			return
		end

		if not lockOn then
			return
		end

		switchTarget()

	end

end)

--==================================================
-- RESPAWN
--==================================================

player.CharacterAdded:Connect(function(character)

	-- Полностью сбрасываем состояние
	lockOn = false
	target = nil

	wasRagdoll = false
	restoreAfterRagdoll = false
	ragdollTarget = nil

	local humanoid =
		character:WaitForChild("Humanoid")

	humanoid.AutoRotate = true

	updateToggle()

	targetText.Text = "No target"

end)

--==================================================
-- INITIALIZE
--==================================================

updateToggle()
