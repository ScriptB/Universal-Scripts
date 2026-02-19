--[[
	🫧 Phantom Suite - Bubble Dock UI (Refined)
	Bottom dock snaps Left/Center/Right, draggable along bottom.
	Tabs spawn “glass bubbles” that float out; bubbles can be sent back to dock.
	RightControl toggles the UI.

	Design choices:
	- Consistent spacing (8px grid) and touch targets for readability. :contentReference[oaicite:0]{index=0}
	- Motion uses standard easing + short durations for “professional” feel. :contentReference[oaicite:1]{index=1}
	- Dock uses edge/corner snapping for fast access. :contentReference[oaicite:2]{index=2}
	- Glass layers preserve contrast/readability (tint + shadow + stroke). :contentReference[oaicite:3]{index=3}
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local plr = Players.LocalPlayer

-- State (kept minimal; wire to your real features)
local aimbotEnabled = false
local espEnabled = false
local aimFov = 100
local EXECUTOR_NAME = "Unknown"

local function detectExecutor()
	if getgenv and getgenv().JJSploit then
		EXECUTOR_NAME = "JJSploit"
	elseif getgenv and getgenv().Solara then
		EXECUTOR_NAME = "Solara"
	elseif identifyexecutor then
		local ok, v = pcall(identifyexecutor)
		if ok and type(v) == "string" and v ~= "" then
			EXECUTOR_NAME = v
		end
	end
end
detectExecutor()

-- Load NexacLib (optional; used only for notification + FX config)
local NexacLib
do
	local ok, lib = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Orion-Library/NexacLib.lua"))()
	end)
	if not ok then
		ok, lib = pcall(function()
			return loadfile("Orion-Library/NexacLib.lua")()
		end)
	end
	if ok and type(lib) == "table" then
		NexacLib = lib
		pcall(function() NexacLib:Init() end)
		pcall(function()
			if NexacLib.SetFX then
				NexacLib:SetFX({
					Blur = false, -- we manage blur here
					DimBackground = false,
					WindowIntro = false,
					TabTransition = false,
					ElementIntro = false,
					Particles = false
				})
			end
		end)
	end
end

-- Theme (glass + accent)
local Theme = {
	BG_Dim = Color3.fromRGB(0, 0, 0),
	BG_DimAlpha = 0.55,

	Glass = Color3.fromRGB(245, 250, 255),
	Glass2 = Color3.fromRGB(225, 235, 250),
	Stroke = Color3.fromRGB(180, 205, 255),

	Text = Color3.fromRGB(20, 30, 60),
	Text2 = Color3.fromRGB(60, 80, 120),

	Accent = Color3.fromRGB(100, 150, 255),
	Accent2 = Color3.fromRGB(150, 205, 255),
	Good = Color3.fromRGB(90, 210, 120),
	Bad = Color3.fromRGB(255, 110, 110),
}

-- Utils
local function tween(obj, ti, props)
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

local function mkCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function mkStroke(parent, thickness, alpha, color)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Thickness = thickness or 1
	s.Transparency = alpha or 0.25
	s.Color = color or Theme.Stroke
	s.Parent = parent
	return s
end

local function mkGradient(parent, rot, c0, c1, c2)
	local g = Instance.new("UIGradient")
	g.Rotation = rot or 45
	if c2 then
		g.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c0),
			ColorSequenceKeypoint.new(0.55, c1),
			ColorSequenceKeypoint.new(1, c2),
		})
	else
		g.Color = ColorSequence.new(c0, c1)
	end
	g.Parent = parent
	return g
end

local function mkShadow(parent, r, alpha)
	local sh = Instance.new("ImageLabel")
	sh.Name = "Shadow"
	sh.BackgroundTransparency = 1
	sh.Image = "rbxassetid://1316045217" -- soft shadow
	sh.ImageTransparency = alpha or 0.55
	sh.ScaleType = Enum.ScaleType.Slice
	sh.SliceCenter = Rect.new(10, 10, 118, 118)
	sh.Size = UDim2.new(1, 36, 1, 36)
	sh.Position = UDim2.new(0, -18, 0, -18)
	sh.ZIndex = parent.ZIndex - 1
	sh.Parent = parent
	return sh
end

local function clamp(n, a, b)
	if n < a then return a end
	if n > b then return b end
	return n
end

-- Root UI
local Root = Instance.new("ScreenGui")
Root.Name = "PhantomBubbleDock"
Root.IgnoreGuiInset = true
Root.ResetOnSpawn = false
Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Root.Parent = (gethui and gethui()) or game:GetService("CoreGui")

-- Dim overlay + blur
local Dim = Instance.new("Frame")
Dim.Name = "Dim"
Dim.Size = UDim2.new(1, 0, 1, 0)
Dim.BackgroundColor3 = Theme.BG_Dim
Dim.BackgroundTransparency = 1
Dim.BorderSizePixel = 0
Dim.Visible = false
Dim.ZIndex = 1
Dim.Parent = Root

local Blur = Instance.new("BlurEffect")
Blur.Name = "PhantomBubbleBlur"
Blur.Size = 0
Blur.Enabled = false
Blur.Parent = Lighting

-- Particle layer (simple, lightweight)
local ParticleLayer = Instance.new("Frame")
ParticleLayer.Name = "Particles"
ParticleLayer.BackgroundTransparency = 1
ParticleLayer.Size = UDim2.new(1, 0, 1, 0)
ParticleLayer.ZIndex = 2
ParticleLayer.Visible = false
ParticleLayer.Parent = Root

local function spawnParticles(count)
	for _, c in ipairs(ParticleLayer:GetChildren()) do
		if c:IsA("ImageLabel") then c:Destroy() end
	end
	for i = 1, count do
		local p = Instance.new("ImageLabel")
		p.Name = "P"..i
		p.BackgroundTransparency = 1
		p.Image = "rbxassetid://3570695787" -- circle
		p.ImageTransparency = 0.75
		p.Size = UDim2.new(0, math.random(6, 14), 0, math.random(6, 14))
		p.Position = UDim2.new(math.random(), 0, 1 + math.random() * 0.4, 0)
		p.ZIndex = 2
		p.Parent = ParticleLayer

		local driftX = (math.random(-25, 25)) / 100
		local dur = math.random(18, 30) / 10
		tween(p, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = UDim2.new(clamp(p.Position.X.Scale + driftX, 0, 1), 0, -0.2, 0),
		})
		tween(p, TweenInfo.new(dur * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			ImageTransparency = 0.85,
		})
	end
end

-- Dock (bottom bar)
local Dock = Instance.new("Frame")
Dock.Name = "Dock"
Dock.AnchorPoint = Vector2.new(0.5, 1)
Dock.Size = UDim2.new(0, 520, 0, 72)
Dock.Position = UDim2.new(0.5, 0, 1, -20)
Dock.BackgroundColor3 = Theme.Glass
Dock.BackgroundTransparency = 0.82
Dock.BorderSizePixel = 0
Dock.ZIndex = 10
Dock.Parent = Root
mkCorner(Dock, 22)
mkStroke(Dock, 2, 0.35, Theme.Stroke)
mkGradient(Dock, 90, Theme.Glass, Theme.Glass2, Theme.Glass)
mkShadow(Dock, 22, 0.62)

local DockInner = Instance.new("Frame")
DockInner.Name = "Inner"
DockInner.BackgroundColor3 = Theme.Glass
DockInner.BackgroundTransparency = 0.90
DockInner.BorderSizePixel = 0
DockInner.Size = UDim2.new(1, -16, 1, -16)
DockInner.Position = UDim2.new(0, 8, 0, 8)
DockInner.ZIndex = 11
DockInner.Parent = Dock
mkCorner(DockInner, 18)
mkStroke(DockInner, 1, 0.55, Theme.Stroke)

local DockTitle = Instance.new("TextLabel")
DockTitle.Name = "Title"
DockTitle.BackgroundTransparency = 1
DockTitle.Size = UDim2.new(0, 220, 1, 0)
DockTitle.Position = UDim2.new(0, 14, 0, 0)
DockTitle.Font = Enum.Font.GothamBold
DockTitle.TextSize = 16
DockTitle.TextXAlignment = Enum.TextXAlignment.Left
DockTitle.TextColor3 = Theme.Text
DockTitle.Text = "🫧 Phantom Suite"
DockTitle.ZIndex = 12
DockTitle.Parent = DockInner

local DockHint = Instance.new("TextLabel")
DockHint.Name = "Hint"
DockHint.BackgroundTransparency = 1
DockHint.Size = UDim2.new(0, 240, 1, 0)
DockHint.Position = UDim2.new(1, -254, 0, 0)
DockHint.Font = Enum.Font.GothamMedium
DockHint.TextSize = 12
DockHint.TextXAlignment = Enum.TextXAlignment.Right
DockHint.TextColor3 = Theme.Text2
DockHint.Text = "RightCtrl • bubbles"
DockHint.TextTransparency = 0.15
DockHint.ZIndex = 12
DockHint.Parent = DockInner

-- Dock snap logic (left/center/right)
local DockSnap = "Center"
local function snapDock(mode)
	DockSnap = mode
	local vp = workspace.CurrentCamera.ViewportSize
	local y = 1
	local yOff = -20
	local targetX
	if mode == "Left" then
		targetX = UDim2.new(0, 20 + Dock.AbsoluteSize.X/2, y, yOff)
	elseif mode == "Right" then
		targetX = UDim2.new(0, vp.X - 20 - Dock.AbsoluteSize.X/2, y, yOff)
	else
		targetX = UDim2.new(0.5, 0, y, yOff)
	end
	tween(Dock, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = targetX})
end

-- Constrained drag along bottom
do
	local dragging = false
	local startX, startPos
	local handle = DockInner

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			startX = input.Position.X
			startPos = Dock.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					local vp = workspace.CurrentCamera.ViewportSize
					local x = Dock.Position.X.Offset
					local leftX = 20 + Dock.AbsoluteSize.X/2
					local rightX = vp.X - 20 - Dock.AbsoluteSize.X/2
					local centerX = vp.X/2
					local dl = math.abs(x - leftX)
					local dc = math.abs(x - centerX)
					local dr = math.abs(x - rightX)
					if dl < dc and dl < dr then snapDock("Left")
					elseif dr < dc and dr < dl then snapDock("Right")
					else snapDock("Center") end
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local vp = workspace.CurrentCamera.ViewportSize
		local dx = input.Position.X - startX
		local newX = startPos.X.Offset + dx
		local minX = 20 + Dock.AbsoluteSize.X/2
		local maxX = vp.X - 20 - Dock.AbsoluteSize.X/2
		newX = clamp(newX, minX, maxX)
		Dock.Position = UDim2.new(0, newX, 1, -20)
	end)

	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		task.defer(function()
			snapDock(DockSnap)
		end)
	end)
end

-- Bubble system
local Bubbles = {}         -- active bubbles by key
local BubbleButtons = {}   -- dock buttons by key

local BubbleConfig = {
	{Key="Dashboard", Label="Dashboard", Icon="🎯"},
	{Key="Aimbot",    Label="Aimbot",    Icon="🎯"},
	{Key="ESP",       Label="ESP",       Icon="👁️"},
	{Key="Movement",  Label="Move",      Icon="🚀"},
	{Key="Settings",  Label="Settings",  Icon="⚙️"},
}

local DockTabs = Instance.new("Frame")
DockTabs.Name = "Tabs"
DockTabs.BackgroundTransparency = 1
DockTabs.Size = UDim2.new(0, 280, 1, 0)
DockTabs.Position = UDim2.new(0.5, -80, 0, 0)
DockTabs.ZIndex = 12
DockTabs.Parent = DockInner

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabsLayout.Padding = UDim.new(0, 10)
tabsLayout.Parent = DockTabs

local function mkDockBubbleButton(cfg)
	local btn = Instance.new("TextButton")
	btn.Name = cfg.Key
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Theme.Glass
	btn.BackgroundTransparency = 0.86
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(0, 44, 0, 44)
	btn.Text = ""
	btn.ZIndex = 12
	btn.Parent = DockTabs
	mkCorner(btn, 16)
	mkStroke(btn, 1, 0.55, Theme.Stroke)
	mkGradient(btn, 55, Theme.Glass, Theme.Glass2, Theme.Glass)

	local ico = Instance.new("TextLabel")
	ico.BackgroundTransparency = 1
	ico.Size = UDim2.new(1, 0, 1, 0)
	ico.Font = Enum.Font.GothamBold
	ico.TextSize = 16
	ico.TextColor3 = Theme.Text
	ico.Text = cfg.Icon
	ico.ZIndex = 13
	ico.Parent = btn

	-- hover/press micro-motion
	btn.MouseEnter:Connect(function()
		tween(btn, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.80
		})
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.86
		})
	end)
	btn.MouseButton1Down:Connect(function()
		tween(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 42, 0, 42)
		})
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 44, 0, 44)
		})
	end)

	return btn
end

-- Bubble card creation
local function mkBubbleCard(key, titleText)
	local card = Instance.new("Frame")
	card.Name = "Bubble_"..key
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Size = UDim2.new(0, 280, 0, 220)
	card.BackgroundColor3 = Theme.Glass
	card.BackgroundTransparency = 0.84
	card.BorderSizePixel = 0
	card.ZIndex = 30
	card.Visible = false
	card.Parent = Root
	mkCorner(card, 26)
	mkStroke(card, 2, 0.30, Theme.Stroke)
	mkGradient(card, 90, Theme.Glass, Theme.Glass2, Theme.Glass)
	mkShadow(card, 26, 0.58)

	local top = Instance.new("Frame")
	top.Name = "Top"
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, -18, 0, 44)
	top.Position = UDim2.new(0, 9, 0, 8)
	top.ZIndex = 31
	top.Parent = card

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -84, 1, 0)
	title.Position = UDim2.new(0, 8, 0, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Text
	title.Text = titleText
	title.ZIndex = 32
	title.Parent = top

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AutoButtonColor = false
	close.BackgroundColor3 = Theme.Glass
	close.BackgroundTransparency = 0.88
	close.BorderSizePixel = 0
	close.Size = UDim2.new(0, 34, 0, 34)
	close.Position = UDim2.new(1, -42, 0, 5)
	close.Text = "↩"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 14
	close.TextColor3 = Theme.Text
	close.ZIndex = 32
	close.Parent = top
	mkCorner(close, 14)
	mkStroke(close, 1, 0.55, Theme.Stroke)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, -18, 1, -62)
	content.Position = UDim2.new(0, 9, 0, 52)
	content.ZIndex = 31
	content.Parent = card

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = content

	return card, content, close
end

local function mkPill(parent, text, color)
	local pill = Instance.new("Frame")
	pill.BackgroundColor3 = color or Theme.Glass2
	pill.BackgroundTransparency = 0.82
	pill.BorderSizePixel = 0
	pill.Size = UDim2.new(1, 0, 0, 36)
	pill.ZIndex = 33
	pill.Parent = parent
	mkCorner(pill, 16)
	mkStroke(pill, 1, 0.60, Theme.Stroke)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -16, 1, 0)
	lbl.Position = UDim2.new(0, 10, 0, 0)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 13
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextColor3 = Theme.Text
	lbl.Text = text
	lbl.ZIndex = 34
	lbl.Parent = pill
	return pill, lbl
end

local function mkToggleRow(parent, name, get, set)
	local row = Instance.new("TextButton")
	row.AutoButtonColor = false
	row.BackgroundColor3 = Theme.Glass2
	row.BackgroundTransparency = 0.84
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 40)
	row.Text = ""
	row.ZIndex = 33
	row.Parent = parent
	mkCorner(row, 16)
	mkStroke(row, 1, 0.60, Theme.Stroke)

	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, -86, 1, 0)
	txt.Position = UDim2.new(0, 12, 0, 0)
	txt.Font = Enum.Font.GothamMedium
	txt.TextSize = 13
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextColor3 = Theme.Text
	txt.Text = name
	txt.ZIndex = 34
	txt.Parent = row

	local chip = Instance.new("Frame")
	chip.Size = UDim2.new(0, 60, 0, 26)
	chip.Position = UDim2.new(1, -72, 0.5, 0)
	chip.AnchorPoint = Vector2.new(0, 0.5)
	chip.BackgroundColor3 = Theme.Accent
	chip.BackgroundTransparency = 0.70
	chip.BorderSizePixel = 0
	chip.ZIndex = 34
	chip.Parent = row
	mkCorner(chip, 12)
	mkStroke(chip, 1, 0.55, Theme.Stroke)

	local chipText = Instance.new("TextLabel")
	chipText.BackgroundTransparency = 1
	chipText.Size = UDim2.new(1, 0, 1, 0)
	chipText.Font = Enum.Font.GothamBold
	chipText.TextSize = 12
	chipText.TextColor3 = Color3.fromRGB(255, 255, 255)
	chipText.ZIndex = 35
	chipText.Parent = chip

	local function refresh()
		local on = get()
		chipText.Text = on and "ON" or "OFF"
		chip.BackgroundColor3 = on and Theme.Good or Theme.Accent
	end
	refresh()

	row.MouseEnter:Connect(function()
		tween(row, TweenInfo.new(0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.78})
	end)
	row.MouseLeave:Connect(function()
		tween(row, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.84})
	end)
	row.MouseButton1Click:Connect(function()
		set(not get())
		refresh()
	end)

	return row
end

-- Bubble open/close animations (dock -> bubble and back)
local function bubbleOriginPosition()
	local vp = workspace.CurrentCamera.ViewportSize
	local base = Dock.Position
	-- convert dock position to pixels for bubble anchoring using offsets
	return UDim2.new(0, base.X.Offset, 1, base.Y.Offset)
end

local function openBubble(key)
	if Bubbles[key] and Bubbles[key].Open then return end
	local entry = Bubbles[key]
	if not entry then return end

	local card = entry.Card
	card.Visible = true
	card.Rotation = 0
	card.BackgroundTransparency = 1

	local origin = bubbleOriginPosition()
	card.Position = origin
	card.Size = UDim2.new(0, 0, 0, 0)

	-- “pop” + float
	local targetPos = UDim2.new(0, origin.X.Offset, 1, origin.Y.Offset - 120)
	local targetSize = entry.TargetSize

	tween(card, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize,
		Position = targetPos,
		BackgroundTransparency = 0.84
	})

	-- subtle breathing
	if entry.FloatConn then entry.FloatConn:Disconnect() end
	local t0 = os.clock()
	entry.FloatConn = RunService.RenderStepped:Connect(function()
		if not card.Visible then return end
		local wob = math.sin((os.clock() - t0) * 1.2) * 2
		card.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset + wob)
	end)

	entry.Open = true
end

local function closeBubble(key)
	local entry = Bubbles[key]
	if not entry or not entry.Open then return end
	local card = entry.Card

	if entry.FloatConn then entry.FloatConn:Disconnect(); entry.FloatConn = nil end

	local origin = bubbleOriginPosition()
	tween(card, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = origin,
		BackgroundTransparency = 1
	})
	task.delay(0.28, function()
		if entry.Open then
			card.Visible = false
			entry.Open = false
		end
	end)
end

-- Build bubbles + dock buttons
do
	for _, cfg in ipairs(BubbleConfig) do
		local btn = mkDockBubbleButton(cfg)
		BubbleButtons[cfg.Key] = btn

		local card, content, closeBtn = mkBubbleCard(cfg.Key, cfg.Icon.."  "..cfg.Label)

		-- size per type
		local s = (cfg.Key == "Dashboard") and UDim2.new(0, 320, 0, 240)
			or (cfg.Key == "Settings") and UDim2.new(0, 260, 0, 210)
			or UDim2.new(0, 280, 0, 220)

		Bubbles[cfg.Key] = {
			Key = cfg.Key,
			Card = card,
			Content = content,
			TargetSize = s,
			Open = false,
			FloatConn = nil,
		}

		btn.MouseButton1Click:Connect(function()
			if Bubbles[cfg.Key].Open then
				closeBubble(cfg.Key)
			else
				openBubble(cfg.Key)
			end
		end)

		closeBtn.MouseButton1Click:Connect(function()
			closeBubble(cfg.Key)
		end)
	end

	-- Populate content
	do
		-- Dashboard
		local c = Bubbles.Dashboard.Content
		mkPill(c, "👤 "..plr.DisplayName, Theme.Glass2)
		mkPill(c, "⚡ Executor: "..EXECUTOR_NAME, Theme.Glass2)
		mkPill(c, "🎮 PlaceId: "..tostring(game.PlaceId), Theme.Glass2)
		mkPill(c, "🎯 Aim FOV: "..tostring(aimFov), Theme.Glass2)

		-- Aimbot
		local a = Bubbles.Aimbot.Content
		mkToggleRow(a, "🎯 Aimbot Enabled", function() return aimbotEnabled end, function(v) aimbotEnabled = v end)
		mkPill(a, "Hold RMB to aim (if wired)", Theme.Glass2)

		-- ESP
		local e = Bubbles.ESP.Content
		mkToggleRow(e, "👁️ ESP Enabled", function() return espEnabled end, function(v) espEnabled = v end)
		mkPill(e, "Distance/box/etc (if wired)", Theme.Glass2)

		-- Movement
		local m = Bubbles.Movement.Content
		mkPill(m, "🚀 Movement modules here", Theme.Glass2)
		mkPill(m, "Add sliders/toggles as needed", Theme.Glass2)

		-- Settings
		local s = Bubbles.Settings.Content
		mkPill(s, "⚙️ UI Preferences", Theme.Glass2)
		mkPill(s, "Dock: drag along bottom", Theme.Glass2)
		mkPill(s, "Snaps: left/center/right", Theme.Glass2)
	end
end

-- UI Toggle (blur + dim + particles + bubble close)
local UIVisible = false

local function setUI(on)
	UIVisible = on
	Dim.Visible = true
	ParticleLayer.Visible = true

	if on then
		Root.Enabled = true
		Dim.BackgroundTransparency = 1
		Blur.Enabled = true
		Blur.Size = 0
		spawnParticles(18)

		tween(Dim, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1 - Theme.BG_DimAlpha
		})
		tween(Blur, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = 14
		})

		-- dock intro
		Dock.Position = UDim2.new(Dock.Position.X.Scale, Dock.Position.X.Offset, 1, 20)
		tween(Dock, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(Dock.Position.X.Scale, Dock.Position.X.Offset, 1, -20)
		})
	else
		-- close any open bubble
		for k, b in pairs(Bubbles) do
			if b.Open then closeBubble(k) end
		end

		tween(Dim, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		})
		tween(Blur, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = 0
		})
		tween(Dock, TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			Position = UDim2.new(Dock.Position.X.Scale, Dock.Position.X.Offset, 1, 20)
		})

		task.delay(0.24, function()
			Blur.Enabled = false
			Dim.Visible = false
			ParticleLayer.Visible = false
			Root.Enabled = false
		end)
	end
end

-- Start hidden
Root.Enabled = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		setUI(not UIVisible)
	end
end)

-- Initial snap
task.defer(function()
	snapDock("Center")
end)

-- Optional notification
if NexacLib and NexacLib.MakeNotification then
	pcall(function()
		NexacLib:MakeNotification({
			Name = "Bubble Dock Ready",
			Content = "🫧 RightControl toggles • Drag dock • Tap bubbles",
			Time = 5,
			Image = ""
		})
	end)
end

print("🫧 Phantom Bubble Dock UI loaded. RightControl to toggle.")
