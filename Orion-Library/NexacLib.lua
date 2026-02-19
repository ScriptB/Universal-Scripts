--// NexacLib Modern (single-file) - Rebrand of Orion -> Nexac (same API / behavior)
--// Fully functional build (elements implemented)
--// Enhanced for 100% OrionLib compatibility

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local NexacLib = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Windows = {},
	UI = {
		Enabled = true
	},
	Themes = {
		Default = {
			-- Base
			Main     = Color3.fromRGB(14, 15, 18),
			Second   = Color3.fromRGB(22, 23, 28),
			Stroke   = Color3.fromRGB(64, 66, 80),
			Divider  = Color3.fromRGB(46, 48, 60),
			Text     = Color3.fromRGB(244, 245, 250),
			TextDark = Color3.fromRGB(170, 172, 186),

			-- Added tokens
			Accent   = Color3.fromRGB(124, 92, 255),
			Accent2  = Color3.fromRGB(72, 208, 255),
			Good     = Color3.fromRGB(42, 196, 112),
			Warn     = Color3.fromRGB(255, 178, 45),
			Bad      = Color3.fromRGB(255, 92, 92),
		},
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false
}

-- Placeholder icon mapping
local Icons = {
	["home"] = "",
	["settings"] = "",
	["user"] = "",
	["info"] = "",
	["warning"] = "",
	["check"] = "",
	["x"] = "",
	["chevron-down"] = "",
	["chevron-up"] = "",
	["chevron-left"] = "",
	["chevron-right"] = "",
	["plus"] = "",
	["minus"] = "",
	["search"] = "",
	["download"] = "",
	["upload"] = "",
	["trash"] = "",
	["edit"] = "",
	["copy"] = "",
	["save"] = "",
	["folder"] = "",
	["file"] = "",
	["lock"] = "",
	["unlock"] = "",
	["eye"] = "",
	["eye-off"] = "",
	["play"] = "",
	["pause"] = "",
	["stop"] = "",
	["skip-back"] = "",
	["skip-forward"] = "",
	["volume"] = "",
	["volume-x"] = "",
	["wifi"] = "",
	["wifi-off"] = "",
	["battery"] = "",
	["battery-charging"] = "",
	["moon"] = "",
	["sun"] = "",
	["cloud"] = "",
	["cloud-rain"] = "",
	["umbrella"] = "",
	["star"] = "",
	["heart"] = "",
	["bookmark"] = "",
	["flag"] = "",
	["bell"] = "",
	["mail"] = "",
	["calendar"] = "",
	["clock"] = "",
	["camera"] = "",
	["video"] = "",
	["image"] = "",
	["music"] = "",
	["headphones"] = "",
	["mic"] = "",
	["phone"] = "",
	["monitor"] = "",
	["tablet"] = "",
	["smartphone"] = "",
	["globe"] = "",
	["map"] = "",
	["compass"] = "",
	["zap"] = "",
	["cpu"] = "",
	["hard-drive"] = "",
	["database"] = "",
	["server"] = "",
	["cloud-snow"] = "",
	["thermometer"] = "",
	["wind"] = "",
	["droplet"] = "",
	["flame"] = ""
}

local function GetIcon(IconName)
	if Icons[IconName] ~= nil then
		return Icons[IconName]
	else
		return nil
	end
end

warn("Nexac Library (Modern) - Using placeholder icons. Upload custom icons.json for better icons.")

-- ScreenGui mount (same behavior, rebranded name)
local Nexac = Instance.new("ScreenGui")
Nexac.Name = "Nexac"
Nexac.ResetOnSpawn = false
Nexac.IgnoreGuiInset = true

if syn and syn.protect_gui then
	syn.protect_gui(Nexac)
	Nexac.Parent = game:GetService("CoreGui")
else
	Nexac.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end

-- remove duplicates (OrionLib compatibility)
if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Nexac.Name and Interface ~= Nexac then
			Interface:Destroy()
		end
	end
else
	for _, Interface in ipairs(game:GetService("CoreGui"):GetChildren()) do
		if Interface.Name == Nexac.Name and Interface ~= Nexac then
			Interface:Destroy()
		end
	end
end

function NexacLib:IsRunning()
	local parent = Nexac.Parent
	if gethui then
		return parent == gethui()
	end
	return parent == game:GetService("CoreGui")
end

local function AddConnection(signal, fn)
	if not NexacLib:IsRunning() then return end
	local c = signal:Connect(fn)
	table.insert(NexacLib.Connections, c)
	return c
end

task.spawn(function()
	while NexacLib:IsRunning() do
		task.wait()
	end
	for _, c in next, NexacLib.Connections do
		pcall(function() c:Disconnect() end)
	end
end)

-- Helpers
local function Create(className, props, children)
	local obj = Instance.new(className)
	if props then
		for k, v in next, props do
			obj[k] = v
		end
	end
	if children then
		for _, ch in next, children do
			ch.Parent = obj
		end
	end
	return obj
end

local function CreateElement(name, fn)
	NexacLib.Elements[name] = fn
end

local function MakeElement(name, ...)
	return NexacLib.Elements[name](...)
end

local function SetProps(obj, props)
	for k, v in next, props do
		obj[k] = v
	end
	return obj
end

local function SetChildren(obj, children)
	for _, ch in next, children do
		ch.Parent = obj
	end
	return obj
end

local function Round(num, factor)
	local result = math.floor(num / factor + (math.sign(num) * 0.5)) * factor
	if result < 0 then result = result + factor end
	return result
end

local function ReturnProperty(obj)
	if obj:IsA("Frame") or obj:IsA("TextButton") then return "BackgroundColor3" end
	if obj:IsA("ScrollingFrame") then return "ScrollBarImageColor3" end
	if obj:IsA("UIStroke") then return "Color" end
	if obj:IsA("TextLabel") or obj:IsA("TextBox") then return "TextColor3" end
	if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then return "ImageColor3" end
end

-- PATCHED: safe theming
local function AddThemeObject(obj, typeName)
	NexacLib.ThemeObjects[typeName] = NexacLib.ThemeObjects[typeName] or {}
	table.insert(NexacLib.ThemeObjects[typeName], obj)

	local prop = ReturnProperty(obj)
	if prop and NexacLib.Themes[NexacLib.SelectedTheme] and NexacLib.Themes[NexacLib.SelectedTheme][typeName] then
		pcall(function()
			obj[prop] = NexacLib.Themes[NexacLib.SelectedTheme][typeName]
		end)
	end
	return obj
end

local function SetTheme()
	for typeName, list in pairs(NexacLib.ThemeObjects) do
		for _, obj in pairs(list) do
			pcall(function()
				local prop = ReturnProperty(obj)
				if prop then
					obj[prop] = NexacLib.Themes[NexacLib.SelectedTheme][typeName]
				end
			end)
		end
	end
end

-- Config
local function PackColor(c)
	return {R = c.R * 255, G = c.G * 255, B = c.B * 255}
end
local function UnpackColor(t)
	return Color3.fromRGB(t.R, t.G, t.B)
end

local function LoadCfg(cfgStr)
	local data = HttpService:JSONDecode(cfgStr)
	for k, v in pairs(data) do
		if NexacLib.Flags[k] then
			task.spawn(function()
				if NexacLib.Flags[k].Type == "Colorpicker" then
					NexacLib.Flags[k]:Set(UnpackColor(v))
				else
					NexacLib.Flags[k]:Set(v)
				end
			end)
		else
			warn("Nexac Config Loader - Missing flag:", k)
		end
	end
end

local function SaveCfg(name)
	local data = {}
	for k, f in pairs(NexacLib.Flags) do
		if f.Save then
			if f.Type == "Colorpicker" then
				data[k] = PackColor(f.Value)
			else
				data[k] = f.Value
			end
		end
	end
	if writefile and NexacLib.Folder then
		writefile(NexacLib.Folder .. "/" .. name .. ".txt", HttpService:JSONEncode(data))
	end
end

-- Draggable
local function MakeDraggable(dragPoint, main)
	pcall(function()
		local dragging, dragInput, mousePos, framePos = false

		AddConnection(dragPoint.InputBegan, function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				mousePos = input.Position
				framePos = main.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		AddConnection(dragPoint.InputChanged, function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				dragInput = input
			end
		end)

		AddConnection(UserInputService.InputChanged, function(input)
			if input == dragInput and dragging then
				local delta = input.Position - mousePos
				main.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
			end
		end)
	end)
end

-- Modern styling system (no external assets)
local UI = {
	Corner = 12,
	StrokeThickness = 1,
	StrokeTransparency = 0.55,
	CardTransparency = 0.08,
	SubCardTransparency = 0.12,
	HoverLift = 2,
	PressDrop = 1,
	ShadowLayers = 3,
	ShadowOffset = 2,
}

local function EnsureCorner(frame, radius)
	local c = frame:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or UI.Corner)
	c.Parent = frame
	return c
end

local function EnsureStroke(frame, color, thickness, transparency)
	local s = frame:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Thickness = thickness or UI.StrokeThickness
	s.Color = color or NexacLib.Themes[NexacLib.SelectedTheme].Stroke
	s.Transparency = transparency == nil and UI.StrokeTransparency or transparency
	s.Parent = frame
	return s
end

local function EnsureGradient(frame, rotation, c0, c1)
	local g = frame:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	g.Rotation = rotation or 90
	g.Color = ColorSequence.new(c0, c1)
	g.Parent = frame
	return g
end

local function AddShadowLayers(frame, layers)
	if frame:FindFirstChild("NexacShadow") then return end
	local shadowFolder = Instance.new("Folder")
	shadowFolder.Name = "NexacShadow"
	shadowFolder.Parent = frame

	for i = 1, (layers or UI.ShadowLayers) do
		local s = Instance.new("Frame")
		s.Name = "L" .. i
		s.BorderSizePixel = 0
		s.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		s.BackgroundTransparency = 0.90 + (i * 0.02)
		s.AnchorPoint = frame.AnchorPoint
		s.Position = frame.Position + UDim2.new(0, i * UI.ShadowOffset, 0, i * UI.ShadowOffset)
		s.Size = frame.Size + UDim2.new(0, i * 2, 0, i * 2)
		s.ZIndex = frame.ZIndex - i
		EnsureCorner(s, (UI.Corner + i))
		s.Parent = shadowFolder
	end

	local function sync()
		for i = 1, (layers or UI.ShadowLayers) do
			local s = shadowFolder:FindFirstChild("L" .. i)
			if s then
				s.AnchorPoint = frame.AnchorPoint
				s.Position = frame.Position + UDim2.new(0, i * UI.ShadowOffset, 0, i * UI.ShadowOffset)
				s.Size = frame.Size + UDim2.new(0, i * 2, 0, i * 2)
				s.ZIndex = frame.ZIndex - i
			end
		end
	end

	AddConnection(frame:GetPropertyChangedSignal("Position"), sync)
	AddConnection(frame:GetPropertyChangedSignal("Size"), sync)
	AddConnection(frame:GetPropertyChangedSignal("ZIndex"), sync)
	AddConnection(frame:GetPropertyChangedSignal("AnchorPoint"), sync)
end

local function ApplyCard(frame, opts)
	opts = opts or {}
	frame.BorderSizePixel = 0
	EnsureCorner(frame, opts.corner or UI.Corner)
	EnsureStroke(frame, opts.strokeColor, opts.strokeThickness, opts.strokeTransparency)
	frame.BackgroundTransparency = opts.transparency == nil and UI.SubCardTransparency or opts.transparency

	if opts.gradient ~= false then
		local t = NexacLib.Themes[NexacLib.SelectedTheme]
		local top = Color3.fromRGB(
			math.clamp(t.Second.R * 255 + 10, 0, 255),
			math.clamp(t.Second.G * 255 + 10, 0, 255),
			math.clamp(t.Second.B * 255 + 14, 0, 255)
		)
		EnsureGradient(frame, 90, top, t.Second)
	end

	if opts.shadow then
		AddShadowLayers(frame, opts.shadowLayers or UI.ShadowLayers)
	end
end

local function ApplyHitEffects(hit, frame, opts)
	opts = opts or {}
	local tweenIn = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	local tweenOut = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

	local basePos = frame.Position
	local hoverPos = basePos + UDim2.new(0, 0, 0, -UI.HoverLift)
	local pressPos = basePos + UDim2.new(0, 0, 0, UI.PressDrop)

	AddConnection(hit.MouseEnter, function()
		TweenService:Create(frame, tweenIn, {Position = hoverPos}):Play()
		if opts.accentStroke then
			local t = NexacLib.Themes[NexacLib.SelectedTheme]
			local s = EnsureStroke(frame, t.Accent, 1.5, 0.20)
			TweenService:Create(s, tweenIn, {Transparency = 0.20}):Play()
		end
	end)

	AddConnection(hit.MouseLeave, function()
		TweenService:Create(frame, tweenOut, {Position = basePos}):Play()
		if opts.accentStroke then
			local s = frame:FindFirstChildOfClass("UIStroke")
			if s then TweenService:Create(s, tweenOut, {Transparency = UI.StrokeTransparency}):Play() end
		end
	end)

	AddConnection(hit.MouseButton1Down, function()
		TweenService:Create(frame, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = pressPos}):Play()
	end)

	AddConnection(hit.MouseButton1Up, function()
		TweenService:Create(frame, tweenIn, {Position = hoverPos}):Play()
	end)
end

-- Key filters
local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3}
local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}
local function CheckKey(tbl, key)
	for _, v in next, tbl do
		if v == key then return true end
	end
	return false
end

-- Elements
CreateElement("Corner", function(scale, offset)
	return Create("UICorner", {CornerRadius = UDim.new(scale or 0, offset or 10)})
end)

CreateElement("Stroke", function(color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or Color3.fromRGB(255, 255, 255),
		Thickness = thickness or 1,
		Transparency = transparency == nil and 0 or transparency,
		LineJoinMode = Enum.LineJoinMode.Round,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	})
end)

CreateElement("List", function(scale, offset)
	return Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(scale or 0, offset or 0)
	})
end)

CreateElement("Padding", function(bottom, left, right, top)
	return Create("UIPadding", {
		PaddingBottom = UDim.new(0, bottom or 4),
		PaddingLeft = UDim.new(0, left or 4),
		PaddingRight = UDim.new(0, right or 4),
		PaddingTop = UDim.new(0, top or 4)
	})
end)

CreateElement("TFrame", function()
	return Create("Frame", {BackgroundTransparency = 1, BorderSizePixel = 0})
end)

CreateElement("Frame", function(color)
	return Create("Frame", {BackgroundColor3 = color or Color3.new(1, 1, 1), BorderSizePixel = 0})
end)

CreateElement("RoundFrame", function(color, scale, offset)
	return Create("Frame", {BackgroundColor3 = color or Color3.new(1, 1, 1), BorderSizePixel = 0}, {
		Create("UICorner", {CornerRadius = UDim.new(scale or 0, offset or UI.Corner)})
	})
end)

CreateElement("Button", function()
	return Create("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		BorderSizePixel = 0
	})
end)

CreateElement("ScrollFrame", function(color, width)
	return Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		ScrollBarImageColor3 = color,
		BorderSizePixel = 0,
		ScrollBarThickness = width,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		MidImage = "rbxassetid://7445543667"
	})
end)

CreateElement("Image", function(imageId)
	local img = Create("ImageLabel", {Image = imageId, BackgroundTransparency = 1})
	local icon = GetIcon(imageId)
	if icon then img.Image = icon end
	return img
end)

CreateElement("ImageButton", function(imageId)
	return Create("ImageButton", {Image = imageId, BackgroundTransparency = 1, AutoButtonColor = false})
end)

CreateElement("Label", function(text, textSize, transparency)
	return Create("TextLabel", {
		Text = text or "",
		TextColor3 = Color3.fromRGB(244, 245, 250),
		TextTransparency = transparency or 0,
		TextSize = textSize or 14,
		Font = Enum.Font.GothamMedium,
		RichText = true,
		BackgroundTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		BorderSizePixel = 0
	})
end)

-- Notifications
local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8)
	})
}), {
	Position = UDim2.new(1, -24, 1, -24),
	Size = UDim2.new(0, 320, 1, -24),
	AnchorPoint = Vector2.new(1, 1),
	Parent = Nexac
})

function NexacLib:MakeNotification(cfg)
	task.spawn(function()
		cfg = cfg or {}
		cfg.Name = cfg.Name or "Notification"
		cfg.Content = cfg.Content or "Test"
		cfg.Image = cfg.Image or "rbxassetid://4384403532"
		cfg.Time = cfg.Time or 6

		local t = NexacLib.Themes[NexacLib.SelectedTheme]

		local parent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		local frame = SetChildren(SetProps(MakeElement("RoundFrame", t.Second, 0, UI.Corner), {
			Parent = parent,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, 40, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 50
		}), {
			MakeElement("Padding", 12, 12, 12, 12),
			AddThemeObject(SetProps(MakeElement("Image", cfg.Image), {
				Size = UDim2.new(0, 20, 0, 20),
				Name = "Icon"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", cfg.Name, 15), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", cfg.Content, 13), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 24),
				Font = Enum.Font.GothamMedium,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = t.TextDark,
				TextWrapped = true
			}), "TextDark")
		})

		ApplyCard(frame, {shadow = true, transparency = 0.02})
		EnsureStroke(frame, t.Stroke, 1, 0.40)

		TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

		task.wait(cfg.Time - 0.88)
		TweenService:Create(frame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
		task.wait(0.3)
		TweenService:Create(frame:FindFirstChildOfClass("UIStroke"), TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
		TweenService:Create(frame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
		TweenService:Create(frame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
		task.wait(0.05)

		frame:TweenPosition(UDim2.new(1, 20, 0, 0), "In", "Quint", 0.8, true)
		task.wait(1.35)
		parent:Destroy()
	end)
end

function NexacLib:Init()
	if NexacLib.SaveCfg then
		pcall(function()
			if isfile and readfile and NexacLib.Folder then
				local path = NexacLib.Folder .. "/" .. game.GameId .. ".txt"
				if isfile(path) then
					LoadCfg(readfile(path))
					NexacLib:MakeNotification({
						Name = "Configuration",
						Content = "Auto-loaded configuration for gameId " .. tostring(game.GameId) .. ".",
						Time = 4
					})
				end
			end
		end)
	end
end

-- Window
function NexacLib:MakeWindow(cfg)
	cfg = cfg or {}
	cfg.Name = cfg.Name or "Nexac Library"
	cfg.ConfigFolder = cfg.ConfigFolder or cfg.Name
	cfg.SaveConfig = cfg.SaveConfig or false
	cfg.IntroEnabled = (cfg.IntroEnabled == nil) and true or cfg.IntroEnabled
	cfg.IntroText = cfg.IntroText or cfg.Name
	cfg.CloseCallback = cfg.CloseCallback or function() end
	cfg.ShowIcon = cfg.ShowIcon or false
	cfg.Icon = cfg.Icon or "rbxassetid://8834748103"
	cfg.IntroIcon = cfg.IntroIcon or cfg.Icon
	cfg.HidePremium = cfg.HidePremium or false

	NexacLib.Folder = cfg.ConfigFolder
	NexacLib.SaveCfg = cfg.SaveConfig

	if cfg.SaveConfig and makefolder and isfolder and NexacLib.Folder then
		if not isfolder(NexacLib.Folder) then
			makefolder(NexacLib.Folder)
		end
	end

	local t = NexacLib.Themes[NexacLib.SelectedTheme]

	local FirstTab = true
	local Minimized = false
	local UIHidden = false

	-- Main window base
	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", t.Main, 0, UI.Corner), {
		Parent = Nexac,
		Position = UDim2.new(0.5, -360, 0.5, -210),
		Size = UDim2.new(0, 720, 0, 420),
		ClipsDescendants = true,
		ZIndex = 10
	}), {
	}), "Main")
	
	-- Add to Windows table for UI visibility tracking
	table.insert(NexacLib.Windows, MainWindow)

	ApplyCard(MainWindow, {shadow = true, transparency = 0.00, gradient = true})

	-- TopBar
	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 56),
		Name = "DragPoint",
		Parent = MainWindow
	})

	local TopBar = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 56),
		Name = "TopBar",
		Parent = MainWindow
	})

	local Title = AddThemeObject(SetProps(MakeElement("Label", cfg.Name, 18), {
		Font = Enum.Font.GothamBold,
		Position = UDim2.new(0, 20, 0, 0),
		Size = UDim2.new(1, -220, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Name = "WindowName"
	}), "Text")

	Title.Parent = TopBar

	local SubLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundTransparency = 0.15
	}), "Stroke")
	SubLine.Parent = TopBar

	-- Buttons container
	local BtnWrap = SetProps(MakeElement("RoundFrame", t.Second, 0, 10), {
		Size = UDim2.new(0, 92, 0, 34),
		Position = UDim2.new(1, -20, 0, 11),
		AnchorPoint = Vector2.new(1, 0),
		Parent = TopBar,
		ZIndex = 11
	})
	ApplyCard(BtnWrap, {shadow = false, transparency = 0.05, gradient = true})
	EnsureStroke(BtnWrap, t.Stroke, 1, 0.55)

	local Divider = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 0.2
	}), "Stroke")
	Divider.Parent = BtnWrap

	local CloseBtn = SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Parent = BtnWrap
	})
	local MinBtn = SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Parent = BtnWrap
	})

	local CloseIco = AddThemeObject(SetProps(MakeElement("Label", "✕", 16), {
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextTransparency = 0.05
	}), "Text")
	CloseIco.Parent = CloseBtn

	local MinIco = AddThemeObject(SetProps(MakeElement("Label", "—", 16), {
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextTransparency = 0.10,
		Name = "Ico"
	}), "Text")
	MinIco.Parent = MinBtn

	-- Sidebar
	local Sidebar = AddThemeObject(SetProps(MakeElement("RoundFrame", t.Second, 0, UI.Corner), {
		Size = UDim2.new(0, 190, 1, -56),
		Position = UDim2.new(0, 0, 0, 56),
		Parent = MainWindow,
		Name = "Sidebar",
		ZIndex = 10
	}), "Second")
	ApplyCard(Sidebar, {shadow = false, transparency = 0.02, gradient = true})
	EnsureStroke(Sidebar, t.Stroke, 1, 0.50)

	-- Sidebar: profile footer
	local Profile = AddThemeObject(SetProps(MakeElement("RoundFrame", t.Main, 0, 10), {
		Size = UDim2.new(1, -16, 0, 54),
		Position = UDim2.new(0, 8, 1, -62),
		Parent = Sidebar,
		ZIndex = 11
	}), "Main")
	ApplyCard(Profile, {shadow = false, transparency = 0.15, gradient = true})
	EnsureStroke(Profile, t.Stroke, 1, 0.65)

	-- PATCHED: use rbxthumb (not https)
	local Avatar = SetProps(MakeElement("Image", ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(LocalPlayer.UserId)), {
		Size = UDim2.new(0, 34, 0, 34),
		Position = UDim2.new(0, 10, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Parent = Profile
	})
	EnsureCorner(Avatar, 10)

	AddThemeObject(SetProps(MakeElement("Label", LocalPlayer.DisplayName, 14), {
		Font = Enum.Font.GothamBold,
		Position = UDim2.new(0, 52, 0, 10),
		Size = UDim2.new(1, -60, 0, 16),
		Parent = Profile,
		TextTransparency = 0.0,
		ClipsDescendants = true
	}), "Text")

	AddThemeObject(SetProps(MakeElement("Label", "@" .. LocalPlayer.Name, 12), {
		Font = Enum.Font.GothamMedium,
		Position = UDim2.new(0, 52, 0, 28),
		Size = UDim2.new(1, -60, 0, 14),
		Parent = Profile,
		TextTransparency = 0.25
	}), "TextDark")

	-- Tabs holder
	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", t.Divider, 5), {
		Size = UDim2.new(1, 0, 1, -132),
		Position = UDim2.new(0, 0, 0, 8),
		Parent = Sidebar,
		Name = "TabHolder",
		ScrollBarThickness = 4
	}), {
		MakeElement("List", 0, 6),
		MakeElement("Padding", 10, 10, 10, 8)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 12)
	end)

	-- Content container (right)
	local ContentHost = AddThemeObject(SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, -190, 1, -56),
		Position = UDim2.new(0, 190, 0, 56),
		Parent = MainWindow,
		Name = "ContentHost"
	}), "Main")

	-- Icon on title
	if cfg.ShowIcon then
		SetProps(MakeElement("Image", cfg.Icon), {
			Size = UDim2.new(0, 20, 0, 20),
			Position = UDim2.new(0, 20, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			Parent = TopBar
		})
		Title.Position = UDim2.new(0, 48, 0, 0)
	end

	MakeDraggable(DragPoint, MainWindow)

	-- Hide/Show
	AddConnection(CloseBtn.MouseButton1Up, function()
		MainWindow.Visible = false
		UIHidden = true
		NexacLib.UI.Enabled = false
		NexacLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Press RightShift to reopen the interface",
			Time = 4
		})
		cfg.CloseCallback()
	end)

	AddConnection(UserInputService.InputBegan, function(input)
		if input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
			MainWindow.Visible = true
			UIHidden = false
			NexacLib.UI.Enabled = true
		end
	end)

	-- Minimize
	AddConnection(MinBtn.MouseButton1Up, function()
		if Minimized then
			MinIco.Text = "—"
			TweenService:Create(MainWindow, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 720, 0, 420)
			}):Play()
			task.wait(0.05)
			Sidebar.Visible = true
			ContentHost.Visible = true
		else
			MinIco.Text = "▢"
			Sidebar.Visible = false
			ContentHost.Visible = false
			TweenService:Create(MainWindow, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, math.clamp(Title.TextBounds.X + 160, 320, 520), 0, 56)
			}):Play()
		end
		Minimized = not Minimized
	end)

	-- Intro
	local function LoadSequence()
		MainWindow.Visible = false

		local Logo = SetProps(MakeElement("Image", cfg.IntroIcon), {
			Parent = Nexac,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.46, 0),
			Size = UDim2.new(0, 32, 0, 32),
			ImageTransparency = 1,
			ImageColor3 = t.Text
		})

		local Text = SetProps(MakeElement("Label", cfg.IntroText, 16), {
			Parent = Nexac,
			Size = UDim2.new(1, 0, 0, 24),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.52, 0),
			TextXAlignment = Enum.TextXAlignment.Center,
			Font = Enum.Font.GothamBold,
			TextTransparency = 1
		})

		TweenService:Create(Logo, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 0
		}):Play()
		task.wait(0.12)
		TweenService:Create(Text, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0
		}):Play()
		task.wait(0.9)

		TweenService:Create(Logo, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageTransparency = 1
		}):Play()
		TweenService:Create(Text, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 1
		}):Play()

		task.wait(0.25)
		Logo:Destroy()
		Text:Destroy()
		MainWindow.Visible = true
	end

	if cfg.IntroEnabled then
		LoadSequence()
	end

	-- Tab factory (same API)
	local TabFunction = {}
	function TabFunction:MakeTab(tabCfg)
		tabCfg = tabCfg or {}
		tabCfg.Name = tabCfg.Name or "Tab"
		tabCfg.Icon = tabCfg.Icon or ""
		tabCfg.PremiumOnly = tabCfg.PremiumOnly or false

		local TabHit = SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 40),
			Parent = TabHolder
		})

		local TabCard = AddThemeObject(SetProps(MakeElement("RoundFrame", t.Second, 0, 10), {
			Size = UDim2.new(1, 0, 1, 0),
			Parent = TabHit,
			BackgroundTransparency = 0.10
		}), "Second")
		ApplyCard(TabCard, {shadow = false, transparency = 0.10, gradient = true})

		local Ico = AddThemeObject(SetProps(MakeElement("Image", tabCfg.Icon), {
			Size = UDim2.new(0, 18, 0, 18),
			Position = UDim2.new(0, 12, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			ImageTransparency = 0.35,
			Name = "Ico",
			Parent = TabCard
		}), "Text")

		local icon = GetIcon(tabCfg.Icon)
		if icon then Ico.Image = icon end

		local Txt = AddThemeObject(SetProps(MakeElement("Label", tabCfg.Name, 14), {
			Size = UDim2.new(1, -44, 1, 0),
			Position = UDim2.new(0, 40, 0, 0),
			Font = Enum.Font.GothamSemibold,
			TextTransparency = 0.30,
			Name = "Title",
			Parent = TabCard
		}), "Text")

		ApplyHitEffects(TabHit, TabCard, {accentStroke = true})

		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", t.Divider, 6), {
			Size = UDim2.new(1, 0, 1, 0),
			Parent = ContentHost,
			Visible = false,
			Name = "ItemContainer",
			ScrollBarThickness = 5
		}), {
			MakeElement("List", 0, 10),
			MakeElement("Padding", 14, 14, 14, 14)
		}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 18)
		end)

		if FirstTab then
			FirstTab = false
			Ico.ImageTransparency = 0
			Txt.TextTransparency = 0
			Txt.Font = Enum.Font.GothamBold
			Container.Visible = true
			EnsureStroke(TabCard, t.Accent, 1.6, 0.15)
		end

		AddConnection(TabHit.MouseButton1Click, function()
			for _, btn in next, TabHolder:GetChildren() do
				if btn:IsA("TextButton") then
					local card = btn:FindFirstChildOfClass("Frame")
					if card then
						local ico2 = card:FindFirstChild("Ico")
						local title2 = card:FindFirstChild("Title")
						if ico2 then TweenService:Create(ico2, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.35}):Play() end
						if title2 then
							title2.Font = Enum.Font.GothamSemibold
							TweenService:Create(title2, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.30}):Play()
						end
						local s = card:FindFirstChildOfClass("UIStroke")
						if s then TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0.65, Color = t.Stroke}):Play() end
					end
				end
			end

			for _, c in next, ContentHost:GetChildren() do
				if c.Name == "ItemContainer" then
					c.Visible = false
				end
			end

			TweenService:Create(Ico, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.0}):Play()
			TweenService:Create(Txt, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.0}):Play()
			Txt.Font = Enum.Font.GothamBold
			local s = EnsureStroke(TabCard, t.Accent, 1.6, 0.15)
			s.Transparency = 0.15
			Container.Visible = true
		end)

		-- FULL ELEMENT IMPLEMENTATION (restored)
		local function GetElements(ItemParent)
			local ElementFunction = {}
			local t2 = NexacLib.Themes[NexacLib.SelectedTheme]

			local function NewElementFrame(height)
				local frame = AddThemeObject(SetProps(MakeElement("RoundFrame", t2.Second, 0, 10), {
					Size = UDim2.new(1, 0, 0, height),
					Parent = ItemParent,
					ClipsDescendants = true
				}), "Second")
				ApplyCard(frame, {shadow = false, transparency = 0.10, gradient = true})
				EnsureStroke(frame, t2.Stroke, 1, 0.55)
				return frame
			end

			-- Label
			function ElementFunction:AddLabel(text)
				local f = NewElementFrame(34)
				local lbl = AddThemeObject(SetProps(MakeElement("Label", text or "", 14), {
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				local api = {}
				function api:Set(v) lbl.Text = tostring(v) end
				return api
			end

			-- Paragraph
			function ElementFunction:AddParagraph(title, content)
				title = title or "Text"
				content = content or "Content"

				local f = NewElementFrame(44)

				AddThemeObject(SetProps(MakeElement("Label", title, 14), {
					Size = UDim2.new(1, -20, 0, 18),
					Position = UDim2.new(0, 12, 0, 10),
					Font = Enum.Font.GothamBold,
					Name = "Title",
					Parent = f
				}), "Text")

				local contentLbl = AddThemeObject(SetProps(MakeElement("Label", "", 13), {
					Size = UDim2.new(1, -24, 0, 0),
					Position = UDim2.new(0, 12, 0, 30),
					Font = Enum.Font.GothamMedium,
					Name = "Content",
					TextWrapped = true,
					AutomaticSize = Enum.AutomaticSize.Y,
					TextColor3 = t2.TextDark,
					Parent = f
				}), "TextDark")

				AddConnection(contentLbl:GetPropertyChangedSignal("Text"), function()
					f.Size = UDim2.new(1, 0, 0, math.max(44, contentLbl.TextBounds.Y + 40))
				end)

				contentLbl.Text = content

				local api = {}
				function api:Set(v) contentLbl.Text = tostring(v) end
				return api
			end

			-- Button
			function ElementFunction:AddButton(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Button"
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.Icon = cfg3.Icon or "rbxassetid://3944703587"

				local f = NewElementFrame(38)

				local lbl = AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(1, -44, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				AddThemeObject(SetProps(MakeElement("Image", cfg3.Icon), {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(1, -30, 0, 10),
					Name = "Icon",
					ImageTransparency = 0.35,
					Parent = f
				}), "TextDark")

				local click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0),
					Parent = f
				})

				ApplyHitEffects(click, f, {accentStroke = true})

				AddConnection(click.MouseButton1Up, function()
					task.spawn(cfg3.Callback)
				end)

				local api = {}
				function api:Set(v) lbl.Text = tostring(v) end
				return api
			end

			-- Toggle
			function ElementFunction:AddToggle(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Toggle"
				cfg3.Default = cfg3.Default or false
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.Color = cfg3.Color or t2.Accent
				cfg3.Flag = cfg3.Flag or nil
				cfg3.Save = cfg3.Save or false

				local Toggle = {Value = cfg3.Default, Save = cfg3.Save, Type = "Toggle"}

				local f = NewElementFrame(42)

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				local box = SetProps(MakeElement("RoundFrame", t2.Main, 0, 8), {
					Size = UDim2.new(0, 42, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = f
				})
				ApplyCard(box, {shadow = false, transparency = 0.08, gradient = true})
				EnsureStroke(box, t2.Stroke, 1, 0.55)

				local knob = SetProps(MakeElement("RoundFrame", t2.Stroke, 0, 10), {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 3, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Parent = box
				})
				ApplyCard(knob, {shadow = false, transparency = 0.0, gradient = false})
				EnsureStroke(knob, t2.Stroke, 1, 0.65)

				local click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0),
					Parent = f
				})
				ApplyHitEffects(click, f, {accentStroke = true})

				function Toggle:Set(v)
					Toggle.Value = not not v
					local on = Toggle.Value

					local goalPos = on and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
					local goalColor = on and cfg3.Color or t2.Stroke

					TweenService:Create(knob, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Position = goalPos,
						BackgroundColor3 = goalColor
					}):Play()
					TweenService:Create(box, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundColor3 = on and t2.Second or t2.Main
					}):Play()

					cfg3.Callback(Toggle.Value)
				end

				Toggle:Set(Toggle.Value)

				AddConnection(click.MouseButton1Up, function()
					SaveCfg(game.GameId)
					Toggle:Set(not Toggle.Value)
				end)

				if cfg3.Flag then NexacLib.Flags[cfg3.Flag] = Toggle end
				return Toggle
			end

			-- Slider
			function ElementFunction:AddSlider(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Slider"
				cfg3.Min = cfg3.Min or 0
				cfg3.Max = cfg3.Max or 100
				cfg3.Increment = cfg3.Increment or 1
				cfg3.Default = cfg3.Default or cfg3.Min
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.ValueName = cfg3.ValueName or ""
				cfg3.Color = cfg3.Color or t2.Accent2
				cfg3.Flag = cfg3.Flag or nil
				cfg3.Save = cfg3.Save or false

				local Slider = {Value = cfg3.Default, Save = cfg3.Save, Type = "Slider"}
				local dragging = false

				local f = NewElementFrame(68)

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(1, -20, 0, 18),
					Position = UDim2.new(0, 12, 0, 10),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				local bar = SetProps(MakeElement("RoundFrame", t2.Main, 0, 8), {
					Size = UDim2.new(1, -24, 0, 26),
					Position = UDim2.new(0, 12, 0, 34),
					Parent = f
				})
				ApplyCard(bar, {shadow = false, transparency = 0.10, gradient = true})
				EnsureStroke(bar, t2.Stroke, 1, 0.55)

				local fill = SetProps(MakeElement("RoundFrame", cfg3.Color, 0, 8), {
					Size = UDim2.new(0, 0, 1, 0),
					Parent = bar
				})
				ApplyCard(fill, {shadow = false, transparency = 0.25, gradient = false})
				EnsureStroke(fill, cfg3.Color, 1, 0.65)

				local valueLbl = AddThemeObject(SetProps(MakeElement("Label", "", 13), {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					Font = Enum.Font.GothamBold,
					TextXAlignment = Enum.TextXAlignment.Right,
					Name = "Value",
					TextTransparency = 0.2,
					Parent = bar
				}), "Text")

				local function setFromX(x)
					local pct = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
					local raw = cfg3.Min + ((cfg3.Max - cfg3.Min) * pct)
					Slider:Set(raw)
					SaveCfg(game.GameId)
				end

				function Slider:Set(v)
					v = math.clamp(Round(v, cfg3.Increment), cfg3.Min, cfg3.Max)
					Slider.Value = v
					local pct = (v - cfg3.Min) / (cfg3.Max - cfg3.Min)
					TweenService:Create(fill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.fromScale(pct, 1)
					}):Play()
					valueLbl.Text = tostring(v) .. (cfg3.ValueName ~= "" and (" " .. cfg3.ValueName) or "")
					cfg3.Callback(v)
				end

				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true
						setFromX(input.Position.X)
					end
				end)
				bar.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
					end
				end)
				UserInputService.InputChanged:Connect(function(input)
					if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
						setFromX(input.Position.X)
					end
				end)

				Slider:Set(Slider.Value)
				if cfg3.Flag then NexacLib.Flags[cfg3.Flag] = Slider end
				return Slider
			end

			-- Dropdown
			function ElementFunction:AddDropdown(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Dropdown"
				cfg3.Options = cfg3.Options or {}
				cfg3.Default = cfg3.Default or ""
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.Flag = cfg3.Flag or nil
				cfg3.Save = cfg3.Save or false

				local Dropdown = {
					Value = cfg3.Default,
					Options = cfg3.Options,
					Buttons = {},
					Toggled = false,
					Type = "Dropdown",
					Save = cfg3.Save
				}
				local MaxElements = 6

				if not table.find(Dropdown.Options, Dropdown.Value) then
					Dropdown.Value = "..."
				end

				local f = NewElementFrame(42)

				local header = SetProps(MakeElement("TFrame"), {
					Size = UDim2.new(1, 0, 0, 42),
					Parent = f,
					Name = "Header"
				})

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(1, -90, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = header
				}), "Text")

				local selected = AddThemeObject(SetProps(MakeElement("Label", "", 13), {
					Size = UDim2.new(0, 120, 1, 0),
					Position = UDim2.new(1, -42, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					Font = Enum.Font.GothamMedium,
					TextXAlignment = Enum.TextXAlignment.Right,
					Name = "Selected",
					TextTransparency = 0.25,
					Parent = header
				}), "TextDark")

				local arrow = AddThemeObject(SetProps(MakeElement("Label", "▾", 16), {
					Size = UDim2.new(0, 24, 1, 0),
					Position = UDim2.new(1, -12, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					Font = Enum.Font.GothamBold,
					Name = "Arrow",
					TextTransparency = 0.15,
					Parent = header
				}), "Text")

				local line = AddThemeObject(SetProps(MakeElement("Frame"), {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 1, -1),
					Name = "Line",
					Visible = false,
					BackgroundTransparency = 0.2,
					Parent = header
				}), "Stroke")

				local listLayout = MakeElement("List", 0, 6)

				local container = SetChildren(SetProps(MakeElement("ScrollFrame", t2.Divider, 5), {
					Parent = f,
					Position = UDim2.new(0, 0, 0, 42),
					Size = UDim2.new(1, 0, 0, 0),
					ClipsDescendants = true,
					Visible = false,
					ScrollBarThickness = 4,
					Name = "DropdownContainer"
				}), {
					listLayout,
					MakeElement("Padding", 10, 12, 12, 10)
				})

				AddConnection(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					container.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
				end)

				local click = SetProps(MakeElement("Button"), {
					Size = UDim2.new(1, 0, 1, 0),
					Parent = header
				})
				ApplyHitEffects(click, f, {accentStroke = true})

				local function addOptions(opts)
					for _, opt in ipairs(opts) do
						local optBtn = SetProps(MakeElement("Button"), {
							Size = UDim2.new(1, 0, 0, 30),
							Parent = container
						})

						local optCard = SetProps(MakeElement("RoundFrame", t2.Main, 0, 8), {
							Size = UDim2.new(1, 0, 1, 0),
							Parent = optBtn,
							BackgroundTransparency = 0.10
						})
						ApplyCard(optCard, {shadow = false, transparency = 0.10, gradient = true})
						EnsureStroke(optCard, t2.Stroke, 1, 0.65)

						local optLbl = AddThemeObject(SetProps(MakeElement("Label", tostring(opt), 13), {
							Size = UDim2.new(1, -16, 1, 0),
							Position = UDim2.new(0, 10, 0, 0),
							Font = Enum.Font.GothamMedium,
							Name = "Title",
							TextTransparency = 0.25,
							Parent = optCard
						}), "TextDark")

						AddConnection(optBtn.MouseButton1Click, function()
							Dropdown:Set(opt)
							SaveCfg(game.GameId)
						end)

						Dropdown.Buttons[opt] = {Btn = optBtn, Card = optCard, Label = optLbl}
					end
				end

				function Dropdown:Refresh(opts, deleteOld)
					if deleteOld then
						for _, v in pairs(Dropdown.Buttons) do
							pcall(function() v.Btn:Destroy() end)
						end
						table.clear(Dropdown.Options)
						table.clear(Dropdown.Buttons)
					end
					Dropdown.Options = opts or {}
					addOptions(Dropdown.Options)
				end

				function Dropdown:Set(v)
					if not table.find(Dropdown.Options, v) then
						Dropdown.Value = "..."
						selected.Text = Dropdown.Value
						return
					end
					Dropdown.Value = v
					selected.Text = tostring(v)

					for opt, o in pairs(Dropdown.Buttons) do
						local active = (opt == v)
						o.Label.TextTransparency = active and 0.0 or 0.25
						EnsureStroke(o.Card, active and t2.Accent or t2.Stroke, 1, active and 0.25 or 0.65)
					end

					cfg3.Callback(Dropdown.Value)
				end

				AddConnection(click.MouseButton1Click, function()
					Dropdown.Toggled = not Dropdown.Toggled
					line.Visible = Dropdown.Toggled
					container.Visible = Dropdown.Toggled
					arrow.Text = Dropdown.Toggled and "▴" or "▾"

					local targetH
					if Dropdown.Toggled then
						local full = listLayout.AbsoluteContentSize.Y + 20
						targetH = (#Dropdown.Options > MaxElements) and (MaxElements * 36) or full
					else
						targetH = 0
					end

					TweenService:Create(f, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 42 + targetH)
					}):Play()
					TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, targetH)
					}):Play()
				end)

				Dropdown:Refresh(Dropdown.Options, false)
				Dropdown:Set(Dropdown.Value)

				if cfg3.Flag then NexacLib.Flags[cfg3.Flag] = Dropdown end
				return Dropdown
			end

			-- Bind
			function ElementFunction:AddBind(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Bind"
				cfg3.Default = cfg3.Default or Enum.KeyCode.Unknown
				cfg3.Hold = cfg3.Hold or false
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.Flag = cfg3.Flag or nil
				cfg3.Save = cfg3.Save or false

				local Bind = {Value = nil, Binding = false, Type = "Bind", Save = cfg3.Save}
				local holding = false

				local f = NewElementFrame(42)

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(1, -80, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				local box = SetProps(MakeElement("RoundFrame", t2.Main, 0, 8), {
					Size = UDim2.new(0, 70, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = f
				})
				ApplyCard(box, {shadow = false, transparency = 0.10, gradient = true})
				EnsureStroke(box, t2.Stroke, 1, 0.55)

				local valLbl = AddThemeObject(SetProps(MakeElement("Label", "", 13), {
					Size = UDim2.new(1, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					Font = Enum.Font.GothamBold,
					Name = "Value",
					Parent = box
				}), "Text")

				local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0), Parent = f})
				ApplyHitEffects(click, f, {accentStroke = true})

				function Bind:Set(key)
					Bind.Binding = false
					Bind.Value = key or Bind.Value
					local display = Bind.Value
					display = (typeof(display) == "EnumItem") and display.Name or tostring(display)
					valLbl.Text = display
				end

				AddConnection(click.InputEnded, function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						if Bind.Binding then return end
						Bind.Binding = true
						valLbl.Text = "..."
					end
				end)

				AddConnection(UserInputService.InputBegan, function(input)
					if UserInputService:GetFocusedTextBox() then return end

					local current = Bind.Value
					local currentName = (typeof(current) == "EnumItem") and current.Name or tostring(current)

					if not Bind.Binding then
						if (input.KeyCode.Name == currentName) or (input.UserInputType.Name == currentName) then
							if cfg3.Hold then
								holding = true
								cfg3.Callback(holding)
							else
								cfg3.Callback()
							end
						end
						return
					end

					local key
					if not CheckKey(BlacklistedKeys, input.KeyCode) then
						key = input.KeyCode
					end
					if (not key) and CheckKey(WhitelistedMouse, input.UserInputType) then
						key = input.UserInputType
					end
					key = key or Bind.Value
					Bind:Set(key)
					SaveCfg(game.GameId)
				end)

				AddConnection(UserInputService.InputEnded, function(input)
					local current = Bind.Value
					local currentName = (typeof(current) == "EnumItem") and current.Name or tostring(current)
					if cfg3.Hold and holding then
						if (input.KeyCode.Name == currentName) or (input.UserInputType.Name == currentName) then
							holding = false
							cfg3.Callback(holding)
						end
					end
				end)

				Bind:Set(cfg3.Default)
				if cfg3.Flag then NexacLib.Flags[cfg3.Flag] = Bind end
				return Bind
			end

			-- Textbox
			function ElementFunction:AddTextbox(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Textbox"
				cfg3.Default = cfg3.Default or ""
				cfg3.TextDisappear = cfg3.TextDisappear or false
				cfg3.Callback = cfg3.Callback or function() end

				local f = NewElementFrame(42)

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(1, -140, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				local box = SetProps(MakeElement("RoundFrame", t2.Main, 0, 8), {
					Size = UDim2.new(0, 120, 0, 26),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = f
				})
				ApplyCard(box, {shadow = false, transparency = 0.10, gradient = true})
				EnsureStroke(box, t2.Stroke, 1, 0.55)

				local tb = AddThemeObject(Instance.new("TextBox"), "Text")
				tb.Size = UDim2.new(1, -10, 1, 0)
				tb.Position = UDim2.new(0, 5, 0, 0)
				tb.BackgroundTransparency = 1
				tb.ClearTextOnFocus = false
				tb.PlaceholderText = "Input"
				tb.Text = cfg3.Default
				tb.Font = Enum.Font.GothamMedium
				tb.TextSize = 13
				tb.TextXAlignment = Enum.TextXAlignment.Center
				tb.Parent = box

				local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0), Parent = f})
				ApplyHitEffects(click, f, {accentStroke = true})

				AddConnection(click.MouseButton1Up, function()
					tb:CaptureFocus()
				end)

				AddConnection(tb.FocusLost, function()
					cfg3.Callback(tb.Text)
					if cfg3.TextDisappear then tb.Text = "" end
				end)
			end

			-- Colorpicker
			function ElementFunction:AddColorpicker(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Colorpicker"
				cfg3.Default = cfg3.Default or Color3.fromRGB(255, 255, 255)
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.Flag = cfg3.Flag or nil
				cfg3.Save = cfg3.Save or false

				local Colorpicker = {Value = cfg3.Default, Toggled = false, Type = "Colorpicker", Save = cfg3.Save}
				local ColorH, ColorS, ColorV = Color3.toHSV(Colorpicker.Value)

				local f = NewElementFrame(42)

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(1, -120, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				local preview = SetProps(MakeElement("RoundFrame", Colorpicker.Value, 0, 8), {
					Size = UDim2.new(0, 34, 0, 24),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = f
				})
				ApplyCard(preview, {shadow = false, transparency = 0.0, gradient = false})
				EnsureStroke(preview, t2.Stroke, 1, 0.55)

				local line = AddThemeObject(SetProps(MakeElement("Frame"), {
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 0, 42),
					Visible = false,
					BackgroundTransparency = 0.2,
					Parent = f
				}), "Stroke")

				local panel = SetProps(MakeElement("TFrame"), {
					Position = UDim2.new(0, 0, 0, 43),
					Size = UDim2.new(1, 0, 0, 0),
					ClipsDescendants = true,
					Visible = false,
					Parent = f
				})

				local colorSquare = Instance.new("ImageLabel")
				colorSquare.BackgroundTransparency = 1
				colorSquare.Size = UDim2.new(1, -56, 0, 90)
				colorSquare.Position = UDim2.new(0, 12, 0, 10)
				colorSquare.Image = "rbxassetid://4155801252"
				colorSquare.Parent = panel
				EnsureCorner(colorSquare, 10)

				local hueBar = Instance.new("Frame")
				hueBar.Size = UDim2.new(0, 18, 0, 90)
				hueBar.Position = UDim2.new(1, -30, 0, 10)
				hueBar.Parent = panel
				EnsureCorner(hueBar, 10)

				local hueGrad = Instance.new("UIGradient")
				hueGrad.Rotation = 270
				hueGrad.Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0))
				}
				hueGrad.Parent = hueBar
				hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				hueBar.BackgroundTransparency = 0.0
				EnsureStroke(hueBar, t2.Stroke, 1, 0.55)

				local sel = Instance.new("ImageLabel")
				sel.BackgroundTransparency = 1
				sel.Image = "http://www.roblox.com/asset/?id=4805639000"
				sel.Size = UDim2.new(0, 16, 0, 16)
				sel.AnchorPoint = Vector2.new(0.5, 0.5)
				sel.Parent = colorSquare

				local hueSel = Instance.new("ImageLabel")
				hueSel.BackgroundTransparency = 1
				hueSel.Image = "http://www.roblox.com/asset/?id=4805639000"
				hueSel.Size = UDim2.new(0, 16, 0, 16)
				hueSel.AnchorPoint = Vector2.new(0.5, 0.5)
				hueSel.Parent = hueBar

				local colorInputConn, hueInputConn

				local function updateUI()
					local c = Color3.fromHSV(ColorH, ColorS, ColorV)
					Colorpicker.Value = c
					preview.BackgroundColor3 = c
					colorSquare.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
					cfg3.Callback(c)
					SaveCfg(game.GameId)
				end

				function Colorpicker:Set(v)
					Colorpicker.Value = v
					ColorH, ColorS, ColorV = Color3.toHSV(v)
					sel.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
					hueSel.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
					updateUI()
				end

				local function syncSelectors()
					sel.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
					hueSel.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
				end

				syncSelectors()
				updateUI()

				AddConnection(colorSquare.InputBegan, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					if colorInputConn then colorInputConn:Disconnect() end
					colorInputConn = AddConnection(RunService.RenderStepped, function()
						local x = math.clamp((Mouse.X - colorSquare.AbsolutePosition.X) / colorSquare.AbsoluteSize.X, 0, 1)
						local y = math.clamp((Mouse.Y - colorSquare.AbsolutePosition.Y) / colorSquare.AbsoluteSize.Y, 0, 1)
						ColorS = x
						ColorV = 1 - y
						syncSelectors()
						updateUI()
					end)
				end)

				AddConnection(colorSquare.InputEnded, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					if colorInputConn then colorInputConn:Disconnect(); colorInputConn = nil end
				end)

				AddConnection(hueBar.InputBegan, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					if hueInputConn then hueInputConn:Disconnect() end
					hueInputConn = AddConnection(RunService.RenderStepped, function()
						local y = math.clamp((Mouse.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
						ColorH = 1 - y
						syncSelectors()
						updateUI()
					end)
				end)

				AddConnection(hueBar.InputEnded, function(input)
					if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
					if hueInputConn then hueInputConn:Disconnect(); hueInputConn = nil end
				end)

				local click = SetProps(MakeElement("Button"), {Size = UDim2.new(1, 0, 1, 0), Parent = f})
				ApplyHitEffects(click, f, {accentStroke = true})

				AddConnection(click.MouseButton1Up, function()
					Colorpicker.Toggled = not Colorpicker.Toggled
					line.Visible = Colorpicker.Toggled
					panel.Visible = Colorpicker.Toggled

					local targetH = Colorpicker.Toggled and 112 or 0
					TweenService:Create(f, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 42 + targetH)
					}):Play()
					TweenService:Create(panel, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, targetH)
					}):Play()
				end)

				if cfg3.Flag then NexacLib.Flags[cfg3.Flag] = Colorpicker end
				return Colorpicker
			end

			-- Section
			function ElementFunction:AddSection(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Section"

				local wrap = SetProps(MakeElement("TFrame"), {
					Size = UDim2.new(1, 0, 0, 28),
					Parent = ItemParent
				})

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 13), {
					Size = UDim2.new(1, -12, 0, 18),
					Position = UDim2.new(0, 2, 0, 4),
					Font = Enum.Font.GothamSemibold,
					TextTransparency = 0.25,
					Parent = wrap
				}), "TextDark")

				local holder = SetChildren(SetProps(MakeElement("TFrame"), {
					Size = UDim2.new(1, 0, 0, 0),
					Position = UDim2.new(0, 0, 0, 26),
					Name = "Holder",
					Parent = wrap
				}), {
					MakeElement("List", 0, 10)
				})

				AddConnection(holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
					holder.Size = UDim2.new(1, 0, 0, holder.UIListLayout.AbsoluteContentSize.Y)
					wrap.Size = UDim2.new(1, 0, 0, holder.UIListLayout.AbsoluteContentSize.Y + 28)
				end)

				return GetElements(holder)
			end

			return ElementFunction
		end

		local ElementFunction = {}
		for k, v in next, GetElements(Container) do
			ElementFunction[k] = v
		end

		-- Premium-only lockout behavior kept (no-op creators)
		if tabCfg.PremiumOnly then
			for k in pairs(ElementFunction) do
				ElementFunction[k] = function() end
			end
			pcall(function()
				Container:FindFirstChildOfClass("UIListLayout"):Destroy()
				Container:FindFirstChildOfClass("UIPadding"):Destroy()
			end)
		end

		return ElementFunction
	end

	return TabFunction
end

function NexacLib:Destroy()
	Nexac:Destroy()
end

return NexacLib
