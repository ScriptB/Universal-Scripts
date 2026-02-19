--[[
	🫧 Phantom Suite - Bubble Dock UI (Pro Layout + Non-Overlap)
	Bottom dock snaps Left/Center/Right, draggable along bottom.
	Tabs spawn “glass bubbles” that auto-layout (no overlap), clamp on-screen,
	and can be sent back to dock. RightControl toggles UI.
	Ref: :contentReference[oaicite:0]{index=0}
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local plr = Players.LocalPlayer

-- Minimal state (wire to your real features)
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
		if ok and type(v) == "string" and v ~= "" then EXECUTOR_NAME = v end
	end
end
detectExecutor()

-- Optional NexacLib notification only
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
	end
end

-- Enhanced Theme (premium glass morphism)
local Theme = {
	BG_Dim = Color3.fromRGB(5,8,20),
	BG_DimAlpha = 0.65,

	-- Glass surfaces with depth
	Glass = Color3.fromRGB(248,252,255),
	Glass2 = Color3.fromRGB(235,243,253),
	Glass3 = Color3.fromRGB(220,235,250),
	
	-- Enhanced strokes with depth
	Stroke = Color3.fromRGB(140,180,255),
	StrokeDark = Color3.fromRGB(100,140,220),
	StrokeLight = Color3.fromRGB(200,220,255),

	-- Text with better hierarchy
	Text = Color3.fromRGB(15,25,55),
	Text2 = Color3.fromRGB(45,65,105),
	Text3 = Color3.fromRGB(80,100,140),

	-- Enhanced accent colors
	Accent = Color3.fromRGB(80,130,255),
	Accent2 = Color3.fromRGB(120,100,255),
	Accent3 = Color3.fromRGB(255,120,180),
	
	-- Status colors with better contrast
	Good = Color3.fromRGB(50,200,100),
	Warn = Color3.fromRGB(255,180,50),
	Bad  = Color3.fromRGB(255,80,80),
	
	-- Shadow colors
	Shadow = Color3.fromRGB(0,10,30),
	ShadowLight = Color3.fromRGB(20,40,80),
}

local function clamp(n,a,b) if n<a then return a elseif n>b then return b end return n end
local function tween(obj, ti, props) local t = TweenService:Create(obj, ti, props); t:Play(); return t end

local function mkCorner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	
	-- Add clipping to prevent content spill over rounded corners
	if parent:IsA("GuiObject") and not parent.ClipsDescendants then
		parent.ClipsDescendants = true
	end
	
	return c
end

-- Enhanced shadow system
local function mkShadow(parent, size, color, transparency)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = transparency or 0.8
	shadow.BackgroundColor3 = color or Theme.Shadow
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.new(1, size*2, 1, size*2)
	shadow.Position = UDim2.new(0, -size, 0, -size)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	mkCorner(shadow, parent:FindFirstChildOfClass("UICorner") and parent.UICorner.CornerRadius.Offset or 12)
	return shadow
end

-- Enhanced glow effect
local function mkGlow(parent, color, intensity)
	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.BackgroundTransparency = 0.9 - (intensity or 0.1)
	glow.BackgroundColor3 = color or Theme.Accent
	glow.BorderSizePixel = 0
	glow.Size = UDim2.new(1, 8, 1, 8)
	glow.Position = UDim2.new(0, -4, 0, -4)
	glow.ZIndex = parent.ZIndex - 2
	glow.Parent = parent
	mkCorner(glow, parent:FindFirstChildOfClass("UICorner") and parent.UICorner.CornerRadius.Offset or 12)
	return glow
end

-- Enhanced gradient with more colors
local function mkGradient(parent, rot, c0, c1, c2)
	local g = Instance.new("UIGradient")
	g.Rotation = rot or 45
	if c2 then
		g.Color = ColorSequence.new({c0, c1, c2})
	else
		g.Color = ColorSequence.new(c0, c1)
	end
	g.Parent = parent
	return g
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

local function mkShadow(parent, alpha)
	local sh = Instance.new("ImageLabel")
	sh.Name = "Shadow"
	sh.BackgroundTransparency = 1
	sh.Image = "rbxassetid://1316045217"
	sh.ImageTransparency = alpha or 0.58
	sh.ScaleType = Enum.ScaleType.Slice
	sh.SliceCenter = Rect.new(10, 10, 118, 118)
	sh.Size = UDim2.new(1, 36, 1, 36)
	sh.Position = UDim2.new(0, -18, 0, -18)
	sh.ZIndex = parent.ZIndex - 1
	sh.Parent = parent
	return sh
end

-- Root
local Root = Instance.new("ScreenGui")
Root.Name = "PhantomBubbleDock"
Root.IgnoreGuiInset = true
Root.ResetOnSpawn = false
Root.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Root.Parent = (gethui and gethui()) or game:GetService("CoreGui")

-- Dim + blur
local Dim = Instance.new("Frame")
Dim.Name = "Dim"
Dim.Size = UDim2.new(1,0,1,0)
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

-- Particles (light)
local ParticleLayer = Instance.new("Frame")
ParticleLayer.Name = "Particles"
ParticleLayer.BackgroundTransparency = 1
ParticleLayer.Size = UDim2.new(1,0,1,0)
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
		p.Image = "rbxassetid://3570695787"
		p.ImageTransparency = 0.78
		local s = math.random(6, 14)
		p.Size = UDim2.new(0, s, 0, s)
		p.Position = UDim2.new(math.random(), 0, 1 + math.random() * 0.4, 0)
		p.ZIndex = 2
		p.Parent = ParticleLayer

		local driftX = (math.random(-20, 20)) / 100
		local dur = math.random(18, 30) / 10
		tween(p, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = UDim2.new(clamp(p.Position.X.Scale + driftX, 0, 1), 0, -0.2, 0),
		})
		tween(p, TweenInfo.new(dur * 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			ImageTransparency = 0.88,
		})
	end
end

-- Enhanced Dock with premium visual effects
local Dock = Instance.new("Frame")
Dock.Name = "Dock"
Dock.AnchorPoint = Vector2.new(0.5, 1)
Dock.Size = UDim2.new(0, 640, 0, 92)
Dock.Position = UDim2.new(0.5, 0, 1, -22)
Dock.BackgroundColor3 = Theme.Glass
Dock.BackgroundTransparency = 0.85
Dock.BorderSizePixel = 0
Dock.ClipsDescendants = true -- Prevent content spill over rounded corners
Dock.ZIndex = 10
Dock.Parent = Root
mkCorner(Dock, 36) -- Increased for smoother edges
mkStroke(Dock, 2, 0.25, Theme.Stroke)
mkGradient(Dock, 90, Theme.Glass, Theme.Glass2, Theme.Glass3)
mkShadow(Dock, 12, Theme.Shadow, 0.6)
mkGlow(Dock, Theme.Accent, 0.05)

local DockInner = Instance.new("Frame")
DockInner.Name = "Inner"
DockInner.BackgroundColor3 = Theme.Glass2
DockInner.BackgroundTransparency = 0.92
DockInner.BorderSizePixel = 0
DockInner.Size = UDim2.new(1, -24, 1, -24)
DockInner.Position = UDim2.new(0, 12, 0, 12)
DockInner.ClipsDescendants = true -- Prevent content spill over rounded corners
DockInner.ZIndex = 11
DockInner.Parent = Dock
mkCorner(DockInner, 28) -- Increased for smoother edges
mkStroke(DockInner, 1, 0.40, Theme.StrokeLight)

-- Left title (fixed width)
local DockTitle = Instance.new("TextLabel")
DockTitle.Name = "Title"
DockTitle.BackgroundTransparency = 1
DockTitle.Size = UDim2.new(0, 130, 1, 0)
DockTitle.Position = UDim2.new(0, 14, 0, 0)
DockTitle.Font = Enum.Font.GothamBold
DockTitle.TextSize = 18
DockTitle.TextXAlignment = Enum.TextXAlignment.Left
DockTitle.TextColor3 = Theme.Text
DockTitle.Text = "🫧 Phantom"
DockTitle.ZIndex = 12
DockTitle.Parent = DockInner

-- Right hint (fixed width) - NO OVERLAP
local DockHint = Instance.new("TextLabel")
DockHint.Name = "Hint"
DockHint.BackgroundTransparency = 1
DockHint.Size = UDim2.new(0, 170, 1, 0)
DockHint.Position = UDim2.new(1, -184, 0, 0)
DockHint.Font = Enum.Font.GothamMedium
DockHint.TextSize = 13
DockHint.TextXAlignment = Enum.TextXAlignment.Right
DockHint.TextColor3 = Theme.Text2
DockHint.Text = "RightCtrl • bubbles"
DockHint.TextTransparency = 0.15
DockHint.ZIndex = 12
DockHint.Parent = DockInner

-- Tabs container fills the remaining center space automatically
local DockTabs = Instance.new("Frame")
DockTabs.Name = "Tabs"
DockTabs.BackgroundTransparency = 1
DockTabs.Position = UDim2.new(0, 0, 0, 0)
DockTabs.Size = UDim2.new(1, 0, 1, 0)
DockTabs.ZIndex = 12
DockTabs.Parent = DockInner

local DockTabsPad = Instance.new("UIPadding")
DockTabsPad.PaddingLeft = UDim.new(0, 150)  -- title space + margin
DockTabsPad.PaddingRight = UDim.new(0, 200) -- hint space + margin
DockTabsPad.Parent = DockTabs

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabsLayout.Padding = UDim.new(0, 8)
tabsLayout.Parent = DockTabs

-- Start hidden + initial positioning
Root.Enabled = false
task.defer(function()
	-- Position dock at center initially
	local vp = workspace.CurrentCamera.ViewportSize
	Dock.Position = UDim2.new(0.5, 0, 1, -22)
end)

-- Drag along bottom (smooth sliding, no snapping)
do
	local dragging = false
	local startX, startPos

	DockInner.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dragging = true
		startX = input.Position.X
		startPos = Dock.Position
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local vp = workspace.CurrentCamera.ViewportSize
		local dx = input.Position.X - startX
		local newX = startPos.X.Offset + dx
		
		-- Edge collision detection - prevent off-screen clipping
		local dockWidth = Dock.AbsoluteSize.X
		local minX = dockWidth/2  -- Left edge collision
		local maxX = vp.X - dockWidth/2  -- Right edge collision
		
		-- Clamp to screen bounds with smooth sliding
		local clampedX = clamp(newX, minX, maxX)
		Dock.Position = UDim2.new(0, clampedX, 1, -22)
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		dragging = false
		-- No snapping - just stop where user placed it
	end)

	-- Keep dock on screen when viewport changes
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not dragging then
			task.defer(function()
				local vp = workspace.CurrentCamera.ViewportSize
				local dockWidth = Dock.AbsoluteSize.X
				local currentX = Dock.Position.X.Offset
				local minX = dockWidth/2
				local maxX = vp.X - dockWidth/2
				local clampedX = clamp(currentX, minX, maxX)
				
				-- Smooth slide back on screen if needed
				if currentX ~= clampedX then
					tween(Dock, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						Position = UDim2.new(0, clampedX, 1, -22)
					})
				end
			end)
		end
	end)
end

-- Bubble config
local BubbleConfig = {
	{Key="Dashboard", Label="Dashboard", Icon="🎯"},
	{Key="Aimbot",    Label="Aimbot",    Icon="🎯"},
	{Key="ESP",       Label="ESP",       Icon="👁️"},
	{Key="Movement",  Label="Move",      Icon="🚀"},
	{Key="Settings",  Label="Settings",  Icon="⚙️"},
}

local Bubbles = {} -- key -> entry
local BubbleButtons = {}

local function mkDockBubbleButton(cfg)
	local btn = Instance.new("TextButton")
	btn.Name = cfg.Key
	btn.AutoButtonColor = false
	btn.BackgroundColor3 = Theme.Glass
	btn.BackgroundTransparency = 0.88
	btn.BorderSizePixel = 0
	btn.Size = UDim2.new(0, 54, 0, 54)
	btn.ClipsDescendants = true -- Prevent icon spill over rounded corners
	btn.Text = ""
	btn.ZIndex = 12
	btn.Parent = DockTabs
	mkCorner(btn, 28) -- Increased for smoother edges
	mkStroke(btn, 1, 0.35, Theme.StrokeLight)
	mkGradient(btn, 55, Theme.Glass, Theme.Glass2, Theme.Glass3)
	mkShadow(btn, 6, Theme.Shadow, 0.4)

	local ico = Instance.new("TextLabel")
	ico.BackgroundTransparency = 1
	ico.Size = UDim2.new(1,0,1,0)
	ico.Font = Enum.Font.GothamBold
	ico.TextSize = 20
	ico.TextColor3 = Theme.Text
	ico.Text = cfg.Icon
	ico.ZIndex = 13
	ico.Parent = btn

	-- Enhanced hover and click animations
	local hoverTween, clickTween
	btn.MouseEnter:Connect(function()
		hoverTween = tween(btn, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.75,
			Size = UDim2.new(0, 58, 0, 58)
		})
		hoverTween = tween(ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0,
			TextSize = 22
		})
		mkGlow(btn, Theme.Accent, 0.08)
	end)

	btn.MouseLeave:Connect(function()
		if hoverTween then hoverTween:Cancel() end
		hoverTween = tween(btn, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.88,
			Size = UDim2.new(0, 54, 0, 54)
		})
		hoverTween = tween(ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			TextTransparency = 0.1,
			TextSize = 20
		})
		local glow = btn:FindFirstChild("Glow")
		if glow then glow:Destroy() end
	end)

	btn.MouseButton1Down:Connect(function()
		tween(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 46, 0, 46)})
	end)
	btn.MouseButton1Up:Connect(function()
		tween(btn, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 50, 0, 50)})
	end)

	return btn
end

-- Enhanced Bubble card with premium visual effects
local function mkBubbleCard(key, titleText)
	local card = Instance.new("Frame")
	card.Name = "Bubble_"..key
	card.AnchorPoint = Vector2.new(0.5, 0.5) -- easier clamping/rows
	card.Size = UDim2.new(0, 340, 0, 280)
	card.BackgroundColor3 = Theme.Glass
	card.BackgroundTransparency = 0.86
	card.BorderSizePixel = 0
	card.ClipsDescendants = true -- Prevent content spill over rounded corners
	card.ZIndex = 30
	card.Visible = false
	card.Parent = Root
	mkCorner(card, 58) -- Increased for much rounder bubbles
	mkStroke(card, 2, 0.25, Theme.StrokeLight)
	mkGradient(card, 110, Theme.Glass, Theme.Glass2, Theme.Glass3)
	mkShadow(card, 16, Theme.Shadow, 0.5)
	mkGlow(card, Theme.Accent, 0.03)

	-- Enhanced highlight sheen with animated gradient
	local sheen = Instance.new("Frame")
	sheen.Name = "Sheen"
	sheen.BackgroundTransparency = 1
	sheen.Size = UDim2.new(1, -32, 0.45, 0)
	sheen.Position = UDim2.new(0, 16, 0, 12)
	sheen.ZIndex = 31
	sheen.Parent = card
	mkCorner(sheen, 52) -- Increased for smoother edges
	
	local sheenFill = Instance.new("Frame")
	sheenFill.BackgroundColor3 = Color3.fromRGB(255,255,255)
	sheenFill.BackgroundTransparency = 0.94
	sheenFill.BorderSizePixel = 0
	sheenFill.Size = UDim2.new(1,0,1,0)
	sheenFill.Parent = sheen
	mkCorner(sheenFill, 52) -- Increased for smoother edges
	mkGradient(sheenFill, 45, Color3.fromRGB(255,255,255), Color3.fromRGB(240,248,255), Color3.fromRGB(220,235,250))

	local top = Instance.new("Frame")
	top.Name = "Top"
	top.BackgroundTransparency = 1
	top.Size = UDim2.new(1, -24, 0, 58)
	top.Position = UDim2.new(0, 12, 0, 12)
	top.ZIndex = 32
	top.Parent = card

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Position = UDim2.new(0, 14, 0, 0)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 18
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.Text
	title.Text = titleText
	title.ZIndex = 33
	title.Parent = top

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AutoButtonColor = false
	close.BackgroundColor3 = Theme.Glass2
	close.BackgroundTransparency = 0.85
	close.BorderSizePixel = 0
	close.Size = UDim2.new(0, 42, 0, 42)
	close.ClipsDescendants = true -- Prevent text spill over rounded corners
	close.Position = UDim2.new(1, -56, 0, 8)
	close.Text = "↩"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Theme.Text
	close.ZIndex = 33
	close.Parent = top
	mkCorner(close, 24) -- Increased for smoother edges
	mkStroke(close, 1, 0.40, Theme.StrokeLight)
	mkShadow(close, 4, Theme.Shadow, 0.3)

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, -24, 1, -82)
	content.Position = UDim2.new(0, 12, 0, 72)
	content.ZIndex = 32
	content.Parent = card

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = content

	return card, content, close
end

local function mkPill(parent, text, color)
	local pill = Instance.new("Frame")
	pill.BackgroundColor3 = color or Theme.Glass3
	pill.BackgroundTransparency = 0.85
	pill.BorderSizePixel = 0
	pill.Size = UDim2.new(1, 0, 0, 44)
	pill.ClipsDescendants = true -- Prevent text spill over rounded corners
	pill.ZIndex = 33
	pill.Parent = parent
	mkCorner(pill, 24) -- Increased for smoother edges
	mkStroke(pill, 1, 0.50, Theme.StrokeLight)
	mkGradient(pill, 90, Theme.Glass2, Theme.Glass3, Theme.Glass)
	mkShadow(pill, 4, Theme.Shadow, 0.3)

	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, -20, 1, 0)
	lbl.Position = UDim2.new(0, 12, 0, 0)
	lbl.Font = Enum.Font.GothamMedium
	lbl.TextSize = 15
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
	row.BackgroundColor3 = Theme.Glass3
	row.BackgroundTransparency = 0.86
	row.BorderSizePixel = 0
	row.Size = UDim2.new(1, 0, 0, 48)
	row.ClipsDescendants = true -- Prevent content spill over rounded corners
	row.Text = ""
	row.ZIndex = 33
	row.Parent = parent
	mkCorner(row, 24) -- Increased for smoother edges
	mkStroke(row, 1, 0.50, Theme.StrokeLight)
	mkGradient(row, 90, Theme.Glass2, Theme.Glass3, Theme.Glass)
	mkShadow(row, 3, Theme.Shadow, 0.25)

	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, -110, 1, 0)
	txt.Position = UDim2.new(0, 14, 0, 0)
	txt.Font = Enum.Font.GothamMedium
	txt.TextSize = 15
	txt.TextXAlignment = Enum.TextXAlignment.Left
	txt.TextColor3 = Theme.Text
	txt.Text = name
	txt.ZIndex = 34
	txt.Parent = row

	local chip = Instance.new("Frame")
	chip.Size = UDim2.new(0, 70, 0, 30)
	chip.ClipsDescendants = true -- Prevent text spill over rounded corners
	chip.Position = UDim2.new(1, -90, 0.5, 0)
	chip.AnchorPoint = Vector2.new(0, 0.5)
	chip.BackgroundColor3 = Theme.Accent
	chip.BackgroundTransparency = 0.65
	chip.BorderSizePixel = 0
	chip.ZIndex = 34
	chip.Parent = row
	mkCorner(chip, 20) -- Increased for smoother edges
	mkStroke(chip, 1, 0.40, Theme.StrokeLight)
	mkShadow(chip, 2, Theme.Shadow, 0.2)

	local chipText = Instance.new("TextLabel")
	chipText.BackgroundTransparency = 1
	chipText.Size = UDim2.new(1,0,1,0)
	chipText.Font = Enum.Font.GothamBold
	chipText.TextSize = 14
	chipText.TextColor3 = Color3.fromRGB(255,255,255)
	chipText.ZIndex = 35
	chipText.Parent = chip

	local function refresh()
		local on = get()
		chipText.Text = on and "ON" or "OFF"
		chip.BackgroundColor3 = on and Theme.Good or Theme.Accent
		-- Enhanced visual feedback for state changes
		tween(chip, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, on and 74 or 70, 0, on and 32 or 30)
		})
	end
	refresh()

	-- Enhanced hover effects
	row.MouseEnter:Connect(function()
		tween(row, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.80})
		tween(chip, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.55})
	end)
	row.MouseLeave:Connect(function()
		tween(row, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.86})
		tween(chip, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0.65})
	end)
	row.MouseButton1Click:Connect(function()
		set(not get()); refresh()
	end)

	return row
end

-- Position helpers
local function dockCenterPx()
	local vp = workspace.CurrentCamera.ViewportSize
	local p = Dock.Position
	local x = (p.X.Scale == 0.5) and (vp.X/2 + p.X.Offset) or p.X.Offset
	local y = vp.Y + p.Y.Offset
	return x, y
end

local function clampBubbleCenter(cx, cy, w, h)
	local vp = workspace.CurrentCamera.ViewportSize
	local margin = 16
	local dockTop = vp.Y + Dock.Position.Y.Offset - Dock.AbsoluteSize.Y
	local minX = margin + w/2
	local maxX = vp.X - margin - w/2
	local minY = margin + h/2
	local maxY = dockTop - margin - h/2
	return clamp(cx, minX, maxX), clamp(cy, minY, maxY)
end

-- Layout manager: when multiple bubbles open, slide into rows (no overlap)
local function layoutOpenBubbles()
	local vp = workspace.CurrentCamera.ViewportSize
	local open = {}
	for _, e in pairs(Bubbles) do
		if e.Open and e.Card.Visible then
			table.insert(open, e)
		end
	end
	table.sort(open, function(a,b) return (a.OpenTick or 0) < (b.OpenTick or 0) end)
	if #open == 0 then return end

	local spacing = 20 -- Increased spacing for better separation
	local marginTop = 60 -- Increased margin from top
	local marginLeft = 40 -- Increased margin from sides
	local dockTop = vp.Y + Dock.Position.Y.Offset - Dock.AbsoluteSize.Y
	local availableH = dockTop - marginTop - 20

	-- Try 1 row, else 2 rows
	local function totalW(list)
		local w = 0
		for i,e in ipairs(list) do
			w += e.TargetSize.X.Offset
			if i > 1 then w += spacing end
		end
		return w
	end

	local maxRowW = vp.X - (marginLeft * 2) -- Account for side margins
	local rows = {}
	if totalW(open) <= maxRowW or availableH < 520 then
		rows[1] = open
	else
		rows[1], rows[2] = {}, {}
		local w1 = 0
		for _, e in ipairs(open) do
			local ew = e.TargetSize.X.Offset
			local nextW = (#rows[1] == 0) and ew or (w1 + spacing + ew)
			if nextW <= maxRowW or #rows[2] > 0 then
				table.insert(rows[1], e)
				w1 = nextW
			else
				table.insert(rows[2], e)
			end
		end
	end

	local rowCount = #rows
	local rowGap = 20 -- Increased gap between rows
	for r = 1, rowCount do
		local row = rows[r]
		local tw = totalW(row)
		-- Center the row with proper margins
		local startX = marginLeft + ((vp.X - (marginLeft * 2) - tw) / 2)
		local y = marginTop + ((r-1) * (300 + rowGap)) -- Increased bubble height
		
		for i, e in ipairs(row) do
			local w = e.TargetSize.X.Offset
			local h = e.TargetSize.Y.Offset
			local cx = startX + (w/2)
			local cy = y + (h/2)
			
			-- Ensure bubbles stay on screen
			cx = math.max(marginLeft + w/2, math.min(cx, vp.X - marginLeft - w/2))
			cy = math.max(marginTop + h/2, math.min(cy, dockTop - marginTop - h/2))
			
			startX = startX + w + spacing

			e.TargetCenter = Vector2.new(cx, cy)
			tween(e.Card, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, cx, 0, cy),
				Size = e.TargetSize,
				BackgroundTransparency = 0.86,
			})
		end
	end
end

local function openBubble(key)
	if Bubbles[key] and Bubbles[key].Open then return end
	local entry = Bubbles[key]
	if not entry then return end

	local card = entry.Card
	card.Visible = true
	card.Rotation = 0
	card.BackgroundTransparency = 1

	local origin = dockCenterPx()
	card.Position = origin
	card.Size = UDim2.new(0, 0, 0, 0)

	-- Don't set initial position here - let layoutOpenBubbles handle it
	-- Just animate to the target size and transparency
	tween(card, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = entry.TargetSize,
		BackgroundTransparency = 0.86,
		Rotation = 0
	})

	-- Staggered content appearance
	task.delay(0.15, function()
		local sheen = card:FindFirstChild("Sheen")
		if sheen then
			sheen.BackgroundTransparency = 0
			tween(sheen, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.94
			})
		end
	end)

	task.delay(0.25, function()
		local top = card:FindFirstChild("Top")
		if top then
			for _, child in ipairs(top:GetChildren()) do
				if child:IsA("GuiObject") then
					child.BackgroundTransparency = 1
					child.TextTransparency = 1
					tween(child, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
						BackgroundTransparency = child.BackgroundTransparency == 1 and 0 or child.BackgroundTransparency,
						TextTransparency = child.TextTransparency == 1 and 0 or child.TextTransparency
					})
				end
			end
		end
	end)

	entry.Open = true
	entry.OpenTick = tick()
	-- Call layoutOpenBubbles to position the bubble correctly
	layoutOpenBubbles()
end

local function closeBubble(key)
	local entry = Bubbles[key]
	if not entry or not entry.Open then return end

	local card = entry.Card
	local origin = dockCenterPx()

	-- Enhanced closing animation with spin effect
	tween(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Position = origin,
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Rotation = 180
	})

	task.delay(0.35, function()
		card.Visible = false
		card.Rotation = 0
	end)

	entry.Open = false
	layoutOpenBubbles()
end

-- Initialize bubbles
for _, cfg in ipairs(BubbleConfig) do
	local btn = mkDockBubbleButton(cfg)
	BubbleButtons[cfg.Key] = btn

	local card, content, closeBtn = mkBubbleCard(cfg.Key, cfg.Icon.."  "..cfg.Label)

	local s = (cfg.Key == "Dashboard") and UDim2.new(0, 380, 0, 290)
		or (cfg.Key == "Settings") and UDim2.new(0, 320, 0, 250)
		or UDim2.new(0, 320, 0, 260)

	Bubbles[cfg.Key] = {
		Key = cfg.Key,
		Card = card,
		Content = content,
		TargetSize = s,
		Open = false,
		OpenTick = 0,
		TargetCenter = nil,
		FloatConn = nil,
	}

	btn.MouseButton1Click:Connect(function()
		if Bubbles[cfg.Key].Open then closeBubble(cfg.Key) else openBubble(cfg.Key) end
	end)
	closeBtn.MouseButton1Click:Connect(function() closeBubble(cfg.Key) end)
end

-- Populate content
do
	local c = Bubbles.Dashboard.Content
	mkPill(c, "👤 "..plr.DisplayName, Theme.Glass2)
	mkPill(c, "⚡ Executor: "..EXECUTOR_NAME, Theme.Glass2)
	mkPill(c, "🎮 PlaceId: "..tostring(game.PlaceId), Theme.Glass2)
	mkPill(c, "🎯 Aim FOV: "..tostring(aimFov), Theme.Glass2)

	local a = Bubbles.Aimbot.Content
	mkToggleRow(a, "🎯 Aimbot Enabled", function() return aimbotEnabled end, function(v) aimbotEnabled = v end)
	mkPill(a, "Hook to your aimbot logic", Theme.Glass2)

	local e = Bubbles.ESP.Content
	mkToggleRow(e, "👁️ ESP Enabled", function() return espEnabled end, function(v) espEnabled = v end)
	mkPill(e, "Hook to your ESP logic", Theme.Glass2)

	local m = Bubbles.Movement.Content
	mkPill(m, "🚀 Movement modules here", Theme.Glass2)
	mkPill(m, "Add sliders/toggles as needed", Theme.Glass2)

	local s = Bubbles.Settings.Content
	mkPill(s, "⚙️ UI Preferences", Theme.Glass2)
	mkPill(s, "Dock: drag along bottom", Theme.Glass2)
	mkPill(s, "Snaps: left/center/right", Theme.Glass2)
	mkPill(s, "Auto-layout: no overlap", Theme.Glass2)
end

-- Toggle UI
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

		tween(Dim, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1 - Theme.BG_DimAlpha
		})
		tween(Blur, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 14})

		-- Don't touch dock position - preserve user's placement
		-- Just animate the dock appearance if needed
		if not UIVisible then
			-- Only animate if UI was previously hidden
			tween(Dock, TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.82
			})
		end
	else
		for k, b in pairs(Bubbles) do if b.Open then closeBubble(k) end end

		tween(Dim, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		tween(Blur, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
		-- Don't move dock - just fade out
		tween(Dock, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
			BackgroundTransparency = 1
		})

		task.delay(0.22, function()
			Blur.Enabled = false
			Dim.Visible = false
			ParticleLayer.Visible = false
			Root.Enabled = false
		end)
	end
end

-- Keep layout valid on viewport changes + dock moves
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	task.defer(function() layoutOpenBubbles() end)
end)
Dock:GetPropertyChangedSignal("Position"):Connect(function()
	task.defer(function() layoutOpenBubbles() end)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		setUI(not UIVisible)
	end
end)

if NexacLib and NexacLib.MakeNotification then
	pcall(function()
		NexacLib:MakeNotification({
			Name = "Bubble Dock Ready",
			Content = "🫧 RightControl toggles • Drag dock • Bubbles auto-layout",
			Time = 5,
			Image = ""
		})
	end)
end

print("🫧 Phantom Bubble Dock UI loaded. RightControl to toggle.")
