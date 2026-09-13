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
	stroke.Thic
