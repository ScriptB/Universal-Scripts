--// NexacLib Modern (single-file)
--// Unique, modern Roblox UI library with Orion-style API compatibility.
--// Single file. No external dependencies. Optional exploit APIs supported (gethui/syn.protect_gui/writefile/readfile).
--// Elements: Label, Paragraph, Button, Toggle, Slider, Dropdown, MultiDropdown, Bind, Textbox, Colorpicker, Section, SearchBox.
--// Utilities: Notifications, Config Save/Load, Themes + runtime theme switching, RightShift toggle, Draggable window.

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local NexacLib = {
	Version = "1.2.0",
	Elements = {},
	ThemeObjects = {}, -- kept for compatibility (not relied on internally)
	Connections = {},
	Flags = {},
	Windows = {},
	UI = { Enabled = true },

	Themes = {
		Default = {
			-- Surfaces
			Main     = Color3.fromRGB(14, 15, 18),
			Second   = Color3.fromRGB(22, 23, 28),
			Third    = Color3.fromRGB(28, 30, 38),
			Stroke   = Color3.fromRGB(64, 66, 80),
			Divider  = Color3.fromRGB(46, 48, 60),

			-- Text
			Text     = Color3.fromRGB(244, 245, 250),
			TextDark = Color3.fromRGB(170, 172, 186),

			-- Accents
			Accent   = Color3.fromRGB(124, 92, 255),
			Accent2  = Color3.fromRGB(72, 208, 255),
			Good     = Color3.fromRGB(42, 196, 112),
			Warn     = Color3.fromRGB(255, 178, 45),
			Bad      = Color3.fromRGB(255, 92, 92),
		},
		NeonAbyss = {
			Main     = Color3.fromRGB(8, 9, 12),
			Second   = Color3.fromRGB(14, 14, 22),
			Third    = Color3.fromRGB(20, 20, 32),
			Stroke   = Color3.fromRGB(88, 92, 118),
			Divider  = Color3.fromRGB(48, 50, 72),

			Text     = Color3.fromRGB(242, 244, 255),
			TextDark = Color3.fromRGB(168, 174, 200),

			Accent   = Color3.fromRGB(0, 255, 182),
			Accent2  = Color3.fromRGB(255, 76, 208),
			Good     = Color3.fromRGB(0, 255, 182),
			Warn     = Color3.fromRGB(255, 210, 64),
			Bad      = Color3.fromRGB(255, 78, 78),
		},
	},

	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false,

	-- placeholder icon map; user can override NexacLib.Icons["name"]="rbxassetid://..."
	Icons = {},
	-- internal theme bindings: array of {Obj=Instance, Key="Text", Prop="TextColor3"}
	_ThemeBindings = {},
}

local function GetIcon(iconNameOrId)
	return NexacLib.Icons[iconNameOrId]
end

--========================================================
-- ScreenGui mount
--========================================================
local Nexac = Instance.new("ScreenGui")
Nexac.Name = "Nexac"
Nexac.ResetOnSpawn = false
Nexac.IgnoreGuiInset = true

do
	local ok = false
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(Nexac)
			Nexac.Parent = game:GetService("CoreGui")
			ok = true
		end
	end)
	if not ok then
		local parent
		pcall(function()
			parent = (gethui and gethui()) or game:GetService("CoreGui")
		end)
		Nexac.Parent = parent or game:GetService("CoreGui")
	end
end

-- remove duplicates
do
	local parent = Nexac.Parent
	if parent then
		for _, g in ipairs(parent:GetChildren()) do
			if g:IsA("ScreenGui") and g.Name == Nexac.Name and g ~= Nexac then
				pcall(function() g:Destroy() end)
			end
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
	if not NexacLib:IsRunning() then return nil end
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

--========================================================
-- Helpers
--========================================================
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
	-- ZIndex fix: if Parent is assigned and no explicit ZIndex was provided,
	-- place the object above its parent so it renders correctly.
	local parent = props and props.Parent
	local hasExplicitZ = props and props.ZIndex ~= nil
	if parent and not hasExplicitZ and typeof(parent) == "Instance" then
		pcall(function()
			if obj:IsA("GuiObject") and parent:IsA("GuiObject") then
				obj.ZIndex = parent.ZIndex + 1
			end
		end)
	end
	for k, v in next, props do
		obj[k] = v
	end
	return obj
end

local function SetChildren(obj, children)
	for _, ch in next, children do
		ch.Parent = obj
		pcall(function()
			if ch:IsA("GuiObject") and obj:IsA("GuiObject") then
				if ch.ZIndex <= obj.ZIndex then
					ch.ZIndex = obj.ZIndex + 1
				end
			end
		end)
	end
	return obj
end

local function SetZIndexRecursive(root, z)
	local function apply(o)
		if typeof(o) == "Instance" and o:IsA("GuiObject") then
			o.ZIndex = z
		end
		for _, child in ipairs(o:GetChildren()) do
			apply(child)
		end
	end
	apply(root)
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
	return nil
end

local function AddThemeObject(obj, themeKey)
	-- Compatibility: also populate ThemeObjects table like Orion
	NexacLib.ThemeObjects[themeKey] = NexacLib.ThemeObjects[themeKey] or {}
	table.insert(NexacLib.ThemeObjects[themeKey], obj)

	local prop = ReturnProperty(obj)
	if prop then
		table.insert(NexacLib._ThemeBindings, { Obj = obj, Key = themeKey, Prop = prop })
		local t = NexacLib.Themes[NexacLib.SelectedTheme]
		if t and t[themeKey] then
			pcall(function() obj[prop] = t[themeKey] end)
		end
	end
	return obj
end

local function SetTheme()
	local t = NexacLib.Themes[NexacLib.SelectedTheme]
	if not t then return end
	for i = #NexacLib._ThemeBindings, 1, -1 do
		local b = NexacLib._ThemeBindings[i]
		if b.Obj == nil or b.Obj.Parent == nil then
			table.remove(NexacLib._ThemeBindings, i)
		else
			local v = t[b.Key]
			if v ~= nil then
				pcall(function() b.Obj[b.Prop] = v end)
			end
		end
	end
end

function NexacLib:SetTheme(themeName)
	if self.Themes[themeName] then
		self.SelectedTheme = themeName
		SetTheme()
	end
end

--========================================================
-- Config
--========================================================
local function PackColor(c)
	return { R = c.R * 255, G = c.G * 255, B = c.B * 255 }
end

local function UnpackColor(t)
	return Color3.fromRGB(t.R, t.G, t.B)
end

local function LoadCfg(cfgStr)
	local ok, data = pcall(function()
		return HttpService:JSONDecode(cfgStr)
	end)
	if not ok or type(data) ~= "table" then return end

	for k, v in pairs(data) do
		local flag = NexacLib.Flags[k]
		if flag and type(flag) == "table" and flag.Set then
			task.spawn(function()
				if flag.Type == "Colorpicker" then
					flag:Set(UnpackColor(v))
				else
					flag:Set(v)
				end
			end)
		end
	end
end

local function SaveCfg(name)
	local data = {}
	for k, f in pairs(NexacLib.Flags) do
		if type(f) == "table" and f.Save then
			if f.Type == "Colorpicker" then
				data[k] = PackColor(f.Value)
			else
				data[k] = f.Value
			end
		end
	end
	if writefile and NexacLib.Folder then
		pcall(function()
			writefile(NexacLib.Folder .. "/" .. tostring(name) .. ".txt", HttpService:JSONEncode(data))
		end)
	end
end

--========================================================
-- Draggable
--========================================================
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

--========================================================
-- Modern styling
--========================================================
local UI = {
	Corner = 12,
	StrokeThickness = 1,
	StrokeTransparency = 0.55,
	HoverLift = 2,
	PressDrop = 1,
	ShadowLayers = 3,
	ShadowOffset = 2,
}


-- FX / Animation settings
NexacLib.FX = NexacLib.FX or {
    Blur = true,
    BlurSize = 10,
    DimBackground = true,
    DimTransparency = 0.35,
    WindowIntro = true,
    MicroInteractions = true,
    TabTransition = true,
    ElementIntro = true,
    Particles = false,
    ParticleCount = 18,
    ParticleSpeed = 18,
}

local function Tween(obj, info, props)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function EnsureUIScale(guiObj)
    local s = guiObj:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
    s.Scale = s.Scale == 0 and 1 or s.Scale
    s.Parent = guiObj
    return s
end

local function GetOrCreateOverlay()
    local ov = Nexac:FindFirstChild("NexacOverlay")
    if ov then return ov end
    ov = Instance.new("Frame")
    ov.Name = "NexacOverlay"
    ov.BackgroundColor3 = Color3.fromRGB(0,0,0)
    ov.BackgroundTransparency = 1
    ov.BorderSizePixel = 0
    ov.Size = UDim2.fromScale(1,1)
    ov.ZIndex = 1
    ov.Parent = Nexac
    return ov
end

local function GetOrCreateBlur()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local blur = cam:FindFirstChild("NexacBlur")
    if blur and blur:IsA("BlurEffect") then return blur end
    blur = Instance.new("BlurEffect")
    blur.Name = "NexacBlur"
    blur.Size = 0
    blur.Enabled = false
    blur.Parent = cam
    return blur
end

local function FX_ShowBackdrop(show, zIndex)
    local ov = GetOrCreateOverlay()
    ov.ZIndex = zIndex or 1

    if NexacLib.FX.DimBackground then
        ov.Visible = true
        if show then
            ov.BackgroundTransparency = 1
            Tween(ov, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundTransparency = NexacLib.FX.DimTransparency
            })
        else
            Tween(ov, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
            task.delay(0.21, function()
                if ov and ov.Parent and ov.BackgroundTransparency >= 0.99 then ov.Visible = false end
            end)
        end
    end

    if NexacLib.FX.Blur then
        local blur = GetOrCreateBlur()
        if blur then
            blur.Enabled = true
            if show then
                blur.Size = 0
                Tween(blur, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = NexacLib.FX.BlurSize})
            else
                Tween(blur, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
                task.delay(0.21, function()
                    if blur and blur.Parent and blur.Size <= 0.05 then blur.Enabled = false end
                end)
            end
        end
    end
end


local function CaptureAndSetTransparent(root)
    local list = {}
    for _, obj in ipairs(root:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            table.insert(list, {obj=obj, prop="TextTransparency", val=obj.TextTransparency})
            obj.TextTransparency = 1
        elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            table.insert(list, {obj=obj, prop="ImageTransparency", val=obj.ImageTransparency})
            obj.ImageTransparency = 1
        elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
            table.insert(list, {obj=obj, prop="BackgroundTransparency", val=obj.BackgroundTransparency})
            obj.BackgroundTransparency = 1
        elseif obj:IsA("UIStroke") then
            table.insert(list, {obj=obj, prop="Transparency", val=obj.Transparency})
            obj.Transparency = 1
        end
    end
    return list
end

local function TweenRestore(list, duration)
    local info = TweenInfo.new(duration or 0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    for _, item in ipairs(list) do
        local o, p, v = item.obj, item.prop, item.val
        if o and o.Parent then
            pcall(function()
                Tween(o, info, {[p]=v})
            end)
        end
    end

local function SpawnParticles(parent, z)
    if not (NexacLib.FX and NexacLib.FX.Particles) then return nil end
    local holder = Instance.new("Frame")
    holder.Name = "NexacParticles"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromScale(1,1)
    holder.ZIndex = z or (parent.ZIndex + 1)
    holder.ClipsDescendants = true
    holder.Parent = parent

    local rng = Random.new()
    local count = math.clamp(tonumber(NexacLib.FX.ParticleCount) or 18, 6, 60)
    local speed = math.clamp(tonumber(NexacLib.FX.ParticleSpeed) or 18, 6, 80)

    local parts = {}
    for i=1,count do
        local p = Instance.new("Frame")
        p.Name = "P"..i
        p.BorderSizePixel = 0
        p.BackgroundTransparency = 0.92
        p.BackgroundColor3 = Color3.fromRGB(255,255,255)
        p.Size = UDim2.new(0, rng:NextInteger(2,4), 0, rng:NextInteger(2,4))
        p.Position = UDim2.fromScale(rng:NextNumber(0,1), rng:NextNumber(0,1))
        p.ZIndex = holder.ZIndex
        EnsureCorner(p, 99)
        local g = Instance.new("UIGradient")
        g.Rotation = rng:NextInteger(0,360)
        g.Transparency = NumberSequence.new{
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 0.6),
        }
        g.Parent = p
        p.Parent = holder
        parts[i] = {obj=p, vx=rng:NextNumber(-1,1), vy=rng:NextNumber(-1,1)}
    end

    local con
    con = AddConnection(RunService.RenderStepped, function(dt)
        if not holder or not holder.Parent then
            if con then con:Disconnect() end
            return
        end
        for _, it in ipairs(parts) do
            local o = it.obj
            if o and o.Parent then
                local pos = o.Position
                local nx = pos.X.Scale + (it.vx * dt * speed / 100)
                local ny = pos.Y.Scale + (it.vy * dt * speed / 100)
                if nx < -0.05 then nx = 1.05 elseif nx > 1.05 then nx = -0.05 end
                if ny < -0.05 then ny = 1.05 elseif ny > 1.05 then ny = -0.05 end
                o.Position = UDim2.fromScale(nx, ny)
            end
        end
    end)

    return holder
end

end

function NexacLib:SetFX(cfg)
    if type(cfg) ~= "table" then return end
    for k, v in pairs(cfg) do
        if NexacLib.FX[k] ~= nil then
            NexacLib.FX[k] = v
        end
    end
end


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

	local count = layers or UI.ShadowLayers
	for i = 1, count do
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
		for i = 1, count do
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

	if opts.transparency ~= nil then
		frame.BackgroundTransparency = opts.transparency
	end

	if opts.gradient ~= false then
		local t = NexacLib.Themes[NexacLib.SelectedTheme]
		local top = Color3.fromRGB(
			math.clamp(t.Second.R * 255 + 10, 0, 255),
			math.clamp(t.Second.G * 255 + 10, 0, 255),
			math.clamp(t.Second.B * 255 + 14, 0, 255)
		)
		EnsureGradient(frame, 90, top, frame.BackgroundColor3)
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
		TweenService:Create(frame, tweenIn, { Position = hoverPos }):Play()
		if opts.accentStroke then
			local t = NexacLib.Themes[NexacLib.SelectedTheme]
			local s = EnsureStroke(frame, t.Accent, 1.5, 0.20)
			TweenService:Create(s, tweenIn, { Transparency = 0.20 }):Play()
		end
	end)

	AddConnection(hit.MouseLeave, function()
		TweenService:Create(frame, tweenOut, { Position = basePos }):Play()
		if opts.accentStroke then
			local s = frame:FindFirstChildOfClass("UIStroke")
			if s then TweenService:Create(s, tweenOut, { Transparency = UI.StrokeTransparency }):Play() end
		end
	end)

	AddConnection(hit.MouseButton1Down, function()
		TweenService:Create(frame, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = pressPos }):Play()
	end)

	AddConnection(hit.MouseButton1Up, function()
		TweenService:Create(frame, tweenIn, { Position = hoverPos }):Play()
	end)
end

--========================================================
-- Key filters (Orion-compatible)
--========================================================
local WhitelistedMouse = { Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3 }
local BlacklistedKeys = {
	Enum.KeyCode.Unknown, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D,
	Enum.KeyCode.Up, Enum.KeyCode.Left, Enum.KeyCode.Down, Enum.KeyCode.Right,
	Enum.KeyCode.Slash, Enum.KeyCode.Tab, Enum.KeyCode.Backspace, Enum.KeyCode.Escape
}

local function CheckKey(tbl, key)
	for _, v in next, tbl do
		if v == key then return true end
	end
	return false
end

--========================================================
-- Base element constructors (kept close to Orion style)
--========================================================
CreateElement("Corner", function(scale, offset)
	return Create("UICorner", { CornerRadius = UDim.new(scale or 0, offset or UI.Corner) })
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
		PaddingBottom = UDim.new(0, bottom or 6),
		PaddingLeft = UDim.new(0, left or 10),
		PaddingRight = UDim.new(0, right or 10),
		PaddingTop = UDim.new(0, top or 6)
	})
end)

CreateElement("TFrame", function()
	return Create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0 })
end)

CreateElement("Frame", function(color)
	return Create("Frame", { BackgroundColor3 = color or Color3.new(1, 1, 1), BorderSizePixel = 0 })
end)

CreateElement("RoundFrame", function(color, scale, offset)
	return Create("Frame", { BackgroundColor3 = color or Color3.new(1, 1, 1), BorderSizePixel = 0 }, {
		Create("UICorner", { CornerRadius = UDim.new(scale or 0, offset or UI.Corner) })
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
		MidImage = "rbxassetid://7445543667",
		BottomImage = "rbxassetid://7445543667",
		TopImage = "rbxassetid://7445543667",
	})
end)

CreateElement("Image", function(imageId)
	local img = Create("ImageLabel", { Image = imageId, BackgroundTransparency = 1, BorderSizePixel = 0 })
	local icon = GetIcon(imageId)
	if icon then img.Image = icon end
	return img
end)

CreateElement("ImageButton", function(imageId)
	return Create("ImageButton", { Image = imageId, BackgroundTransparency = 1, AutoButtonColor = false, BorderSizePixel = 0 })
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

--========================================================
-- Notifications
--========================================================
local NotificationHolder

function NexacLib:MakeNotification(cfg)
	task.spawn(function()
		cfg = cfg or {}
		cfg.Name = cfg.Name or "Notification"
		cfg.Content = cfg.Content or "Test"
		cfg.Image = cfg.Image or "rbxassetid://4384403532"
		cfg.Time = cfg.Time or 6

		if not NotificationHolder then
			NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
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
		end

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

		ApplyCard(frame, { shadow = true, transparency = 0.02, gradient = true })
		EnsureStroke(frame, t.Stroke, 1, 0.40)

		TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), { Position = UDim2.new(0, 0, 0, 0) }):Play()

		task.wait(math.max(0.1, cfg.Time - 0.88))
		TweenService:Create(frame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), { ImageTransparency = 1 }):Play()
		TweenService:Create(frame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.6 }):Play()
		task.wait(0.3)

		local s = frame:FindFirstChildOfClass("UIStroke")
		if s then TweenService:Create(s, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { Transparency = 0.9 }):Play() end
		TweenService:Create(frame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { TextTransparency = 0.4 }):Play()
		TweenService:Create(frame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), { TextTransparency = 0.5 }):Play()
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
				local path = NexacLib.Folder .. "/" .. tostring(game.GameId) .. ".txt"
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

--========================================================
-- Window / Tabs / Elements (Orion-style API)
--========================================================
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

	-- Main window
	local MainWindow = AddThemeObject(SetProps(MakeElement("RoundFrame", t.Main, 0, UI.Corner), {
		Parent = Nexac,
		Position = UDim2.new(0.5, -360, 0.5, -210),
		Size = UDim2.new(0, 720, 0, 420),
		ClipsDescendants = true,
		ZIndex = 10,
		Name = "NexacWindow"
	}), "Main")
	MainWindow.BackgroundTransparency = 0
	ApplyCard(MainWindow, { shadow = true, transparency = 0.0, gradient = true })

	table.insert(NexacLib.Windows, MainWindow)
	SetZIndexRecursive(MainWindow, 10)


-- FX: intro animation + backdrop
local _introVisuals
local _basePos = MainWindow.Position
if NexacLib.FX and NexacLib.FX.WindowIntro then
	FX_ShowBackdrop(true, 2)
	local sc = EnsureUIScale(MainWindow)
	sc.Scale = 0.965
	MainWindow.Position = _basePos + UDim2.new(0, 0, 0, 14)
	_introVisuals = CaptureAndSetTransparent(MainWindow)
	MainWindow.BackgroundTransparency = 1
	Tween(MainWindow, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = _basePos,
		BackgroundTransparency = 0
	})
	task.delay(0.02, function()
		if sc and sc.Parent then
			Tween(sc, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1})
		end
		if _introVisuals then TweenRestore(_introVisuals, 0.30) end
	end)
else
	FX_ShowBackdrop(true, 2)
end

	local _particles = SpawnParticles(MainWindow, 9)

	-- TopBar / drag point
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
		Name = "WindowName",
		Parent = TopBar
	}), "Text")

	local SubLine = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.new(0, 0, 1, -1),
		BackgroundTransparency = 0.15,
		Parent = TopBar
	}), "Stroke")

	-- buttons
	local BtnWrap = SetProps(MakeElement("RoundFrame", t.Second, 0, 10), {
		Size = UDim2.new(0, 92, 0, 34),
		Position = UDim2.new(1, -20, 0, 11),
		AnchorPoint = Vector2.new(1, 0),
		Parent = TopBar,
		ZIndex = 11
	})
	ApplyCard(BtnWrap, { shadow = false, transparency = 0.05, gradient = true })
	EnsureStroke(BtnWrap, t.Stroke, 1, 0.55)

	local Divider = AddThemeObject(SetProps(MakeElement("Frame"), {
		Size = UDim2.new(0, 1, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 0.2,
		Parent = BtnWrap
	}), "Stroke")

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
		TextTransparency = 0.05,
		Parent = CloseBtn
	}), "Text")

	local MinIco = AddThemeObject(SetProps(MakeElement("Label", "—", 16), {
		Size = UDim2.new(1, 0, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Center,
		Font = Enum.Font.GothamBold,
		TextTransparency = 0.10,
		Name = "Ico",
		Parent = MinBtn
	}), "Text")

	-- Sidebar
	local Sidebar = AddThemeObject(SetProps(MakeElement("RoundFrame", t.Second, 0, UI.Corner), {
		Size = UDim2.new(0, 190, 1, -56),
		Position = UDim2.new(0, 0, 0, 56),
		Parent = MainWindow,
		Name = "Sidebar",
		ZIndex = 10
	}), "Second")
	ApplyCard(Sidebar, { shadow = false, transparency = 0.02, gradient = true })
	EnsureStroke(Sidebar, t.Stroke, 1, 0.50)

	-- Profile footer
	local Profile = AddThemeObject(SetProps(MakeElement("RoundFrame", t.Main, 0, 10), {
		Size = UDim2.new(1, -16, 0, 54),
		Position = UDim2.new(0, 8, 1, -62),
		Parent = Sidebar,
		ZIndex = 11
	}), "Main")
	ApplyCard(Profile, { shadow = false, transparency = 0.15, gradient = true })
	EnsureStroke(Profile, t.Stroke, 1, 0.65)

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

	-- Right side content host
	local ContentHost = AddThemeObject(SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, -190, 1, -56),
		Position = UDim2.new(0, 190, 0, 56),
		Parent = MainWindow,
		Name = "ContentHost"
	}), "Main")

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
		if UIHidden then return end
		UIHidden = true
		NexacLib.UI.Enabled = false
		pcall(function()
			local sc = EnsureUIScale(MainWindow)
			Tween(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.985})
			Tween(MainWindow, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
		end)
		task.delay(0.19, function()
			if MainWindow and MainWindow.Parent then
				MainWindow.Visible = false
			end
			FX_ShowBackdrop(false, 2)
		end)
		NexacLib:MakeNotification({
			Name = "Interface Hidden",
			Content = "Press RightShift to reopen the interface",
			Time = 4
		})
		cfg.CloseCallback()
	end)

	AddConnection(UserInputService.InputBegan, function(input)
		if input.KeyCode == Enum.KeyCode.RightShift and UIHidden then
			UIHidden = false
			NexacLib.UI.Enabled = true
			if MainWindow and MainWindow.Parent then
				MainWindow.Visible = true
				FX_ShowBackdrop(true, 2)
				pcall(function()
					local sc = EnsureUIScale(MainWindow)
					sc.Scale = 0.985
					MainWindow.BackgroundTransparency = 1
					Tween(sc, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1})
					Tween(MainWindow, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
				end)
			end
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

	-- Tab factory
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
		SetZIndexRecursive(TabHit, 11)

		local TabCard = AddThemeObject(SetProps(MakeElement("RoundFrame", t.Second, 0, 10), {
			Size = UDim2.new(1, 0, 1, 0),
			Parent = TabHit,
			BackgroundTransparency = 0.10
		}), "Second")
		ApplyCard(TabCard, { shadow = false, transparency = 0.10, gradient = true })

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

		ApplyHitEffects(TabHit, TabCard, { accentStroke = true })

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
			if NexacLib.FX and NexacLib.FX.TabTransition then
				Container.Position = UDim2.new(0, 18, 0, 0)
				Container.Visible = true
				Tween(Container, TweenInfo.new(0.20, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)})
			else
				Container.Visible = true
			end
			EnsureStroke(TabCard, t.Accent, 1.6, 0.15)
		end

		AddConnection(TabHit.MouseButton1Click, function()
			-- reset all tab styles
			for _, btn in next, TabHolder:GetChildren() do
				if btn:IsA("TextButton") then
					local card = btn:FindFirstChildOfClass("Frame")
					if card then
						local ico2 = card:FindFirstChild("Ico")
						local title2 = card:FindFirstChild("Title")
						if ico2 then TweenService:Create(ico2, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0.35 }):Play() end
						if title2 then
							title2.Font = Enum.Font.GothamSemibold
							TweenService:Create(title2, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.30 }):Play()
						end
						local s = card:FindFirstChildOfClass("UIStroke")
						if s then TweenService:Create(s, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Transparency = 0.65, Color = t.Stroke }):Play() end
					end
				end
			end

			for _, c in next, ContentHost:GetChildren() do
				if c.Name == "ItemContainer" then
					if NexacLib.FX and NexacLib.FX.TabTransition and c.Visible then
						local base = c.Position
						Tween(c, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = base + UDim2.new(0, -18, 0, 0)})
						task.delay(0.17, function()
							if c and c.Parent then
								c.Visible = false
								c.Position = base
							end
						end)
					else
						c.Visible = false
					end
				end
			end

			TweenService:Create(Ico, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0.0 }):Play()
			TweenService:Create(Txt, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.0 }):Play()
			Txt.Font = Enum.Font.GothamBold
			local s = EnsureStroke(TabCard, t.Accent, 1.6, 0.15)
			s.Transparency = 0.15
			Container.Visible = true
		end)

		--========================================================
		-- Elements Implementation
		--========================================================
		local function GetElements(ItemParent)
			local ElementFunction = {}
			local t2 = NexacLib.Themes[NexacLib.SelectedTheme]

			local function NewElementFrame(height)
				local f = AddThemeObject(SetProps(MakeElement("RoundFrame", t2.Second, 0, 10), {
					Size = UDim2.new(1, 0, 0, height),
					Parent = ItemParent,
					ClipsDescendants = true
				}), "Second")
				f.BackgroundTransparency = 0.10
				ApplyCard(f, { shadow = false, transparency = 0.10, gradient = true })
				EnsureStroke(f, t2.Stroke, 1, 0.55)
				if NexacLib.FX and NexacLib.FX.ElementIntro then
					local sc = EnsureUIScale(f)
					local bt = f.BackgroundTransparency
					sc.Scale = 0.985
					f.BackgroundTransparency = 1
					Tween(sc, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Scale = 1})
					Tween(f, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = bt})
					local stroke = f:FindFirstChildOfClass("UIStroke")
					if stroke then
						local st = stroke.Transparency
						stroke.Transparency = 1
						Tween(stroke, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = st})
					end
				end
				return f
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
				ApplyHitEffects(click, f, { accentStroke = true })

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

				local Toggle = { Value = cfg3.Default, Save = cfg3.Save, Type = "Toggle" }

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
				ApplyCard(box, { shadow = false, transparency = 0.08, gradient = true })
				EnsureStroke(box, t2.Stroke, 1, 0.55)

				local knob = SetProps(MakeElement("RoundFrame", t2.Stroke, 0, 10), {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 3, 0.5, 0),
					AnchorPoint = Vector2.new(0, 0.5),
					Parent = box
				})
				ApplyCard(knob, { shadow = false, transparency = 0.0, gradient = false })
				EnsureStroke(knob, t2.Stroke, 1, 0.65)

				local click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), Parent = f })
				ApplyHitEffects(click, f, { accentStroke = true })

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

				local Slider = { Value = cfg3.Default, Save = cfg3.Save, Type = "Slider" }
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
				ApplyCard(bar, { shadow = false, transparency = 0.10, gradient = true })
				EnsureStroke(bar, t2.Stroke, 1, 0.55)

				local fill = SetProps(MakeElement("RoundFrame", cfg3.Color, 0, 8), {
					Size = UDim2.new(0, 0, 1, 0),
					Parent = bar
				})
				ApplyCard(fill, { shadow = false, transparency = 0.25, gradient = false })
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
					local pct = (cfg3.Max == cfg3.Min) and 0 or ((v - cfg3.Min) / (cfg3.Max - cfg3.Min))
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

			-- Dropdown (single)
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
					Size = UDim2.new(0, 170, 1, 0),
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

				local click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), Parent = header })
				ApplyHitEffects(click, f, { accentStroke = true })

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
						ApplyCard(optCard, { shadow = false, transparency = 0.10, gradient = true })
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

						Dropdown.Buttons[opt] = { Btn = optBtn, Card = optCard, Label = optLbl }
					end
				end

				function Dropdown:Refresh(opts, deleteOld)
					if deleteOld then
						for _, v in pairs(Dropdown.Buttons) do
							pcall(function() v.Btn:Destroy() end)
						end
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

				Dropdown:Refresh(Dropdown.Options, true)
				Dropdown:Set(Dropdown.Value)

				if cfg3.Flag then NexacLib.Flags[cfg3.Flag] = Dropdown end
				return Dropdown
			end

			-- MultiDropdown (Orion-style extension)
			function ElementFunction:AddMultiDropdown(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "MultiDropdown"
				cfg3.Options = cfg3.Options or {}
				cfg3.Default = cfg3.Default or {}
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.Flag = cfg3.Flag or nil
				cfg3.Save = cfg3.Save or false

				local Multi = {
					Value = {},
					Options = cfg3.Options,
					Buttons = {},
					Toggled = false,
					Type = "Dropdown",
					Save = cfg3.Save,
					Multi = true
				}

				-- initialize set
				local function setInit(def)
					Multi.Value = {}
					if type(def) == "table" then
						for _, v in ipairs(def) do
							if table.find(Multi.Options, v) then
								Multi.Value[v] = true
							end
						end
					end
				end
				setInit(cfg3.Default)

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
					Size = UDim2.new(0, 170, 1, 0),
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

				local click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), Parent = header })
				ApplyHitEffects(click, f, { accentStroke = true })

				local function formatSelected()
					local out = {}
					for opt, on in pairs(Multi.Value) do
						if on then table.insert(out, tostring(opt)) end
					end
					table.sort(out)
					if #out == 0 then
						return "..."
					end
					-- show first few
					local show = {}
					for i = 1, math.min(3, #out) do
						table.insert(show, out[i])
					end
					local s = table.concat(show, ", ")
					if #out > 3 then s = s .. (" +" .. tostring(#out - 3)) end
					return s
				end

				local function updateSelectedLabel()
					selected.Text = formatSelected()
				end

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
						ApplyCard(optCard, { shadow = false, transparency = 0.10, gradient = true })
						EnsureStroke(optCard, t2.Stroke, 1, 0.65)

						local optLbl = AddThemeObject(SetProps(MakeElement("Label", tostring(opt), 13), {
							Size = UDim2.new(1, -16, 1, 0),
							Position = UDim2.new(0, 10, 0, 0),
							Font = Enum.Font.GothamMedium,
							Name = "Title",
							TextTransparency = 0.25,
							Parent = optCard
						}), "TextDark")

						local function repaint()
							local active = Multi.Value[opt] == true
							optLbl.TextTransparency = active and 0.0 or 0.25
							EnsureStroke(optCard, active and t2.Accent2 or t2.Stroke, 1, active and 0.25 or 0.65)
						end
						repaint()

						AddConnection(optBtn.MouseButton1Click, function()
							Multi.Value[opt] = not Multi.Value[opt]
							repaint()
							updateSelectedLabel()
							cfg3.Callback(Multi:Get())
							SaveCfg(game.GameId)
						end)

						Multi.Buttons[opt] = { Btn = optBtn, Card = optCard, Label = optLbl, Repaint = repaint }
					end
				end

				function Multi:Get()
					local out = {}
					for opt, on in pairs(Multi.Value) do
						if on then table.insert(out, opt) end
					end
					table.sort(out, function(a,b) return tostring(a) < tostring(b) end)
					return out
				end

				function Multi:Set(list)
					setInit(list)
					for _, o in pairs(Multi.Buttons) do
						pcall(function() o.Repaint() end)
					end
					updateSelectedLabel()
					cfg3.Callback(Multi:Get())
				end

				addOptions(Multi.Options)
				updateSelectedLabel()

				AddConnection(click.MouseButton1Click, function()
					Multi.Toggled = not Multi.Toggled
					line.Visible = Multi.Toggled
					container.Visible = Multi.Toggled
					arrow.Text = Multi.Toggled and "▴" or "▾"

					local maxH = 6 * 36
					local full = listLayout.AbsoluteContentSize.Y + 20
					local targetH = Multi.Toggled and math.min(maxH, full) or 0

					TweenService:Create(f, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, 42 + targetH)
					}):Play()
					TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(1, 0, 0, targetH)
					}):Play()
				end)

				if cfg3.Flag then NexacLib.Flags[cfg3.Flag] = Multi end
				return Multi
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

				local Bind = { Value = nil, Binding = false, Type = "Bind", Save = cfg3.Save }
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
				ApplyCard(box, { shadow = false, transparency = 0.10, gradient = true })
				EnsureStroke(box, t2.Stroke, 1, 0.55)

				local valLbl = AddThemeObject(SetProps(MakeElement("Label", "", 13), {
					Size = UDim2.new(1, 0, 1, 0),
					TextXAlignment = Enum.TextXAlignment.Center,
					Font = Enum.Font.GothamBold,
					Name = "Value",
					Parent = box
				}), "Text")

				local click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), Parent = f })
				ApplyHitEffects(click, f, { accentStroke = true })

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
					Size = UDim2.new(0, 160, 0, 26),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = f
				})
				ApplyCard(box, { shadow = false, transparency = 0.10, gradient = true })
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

				local click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), Parent = f })
				ApplyHitEffects(click, f, { accentStroke = true })

				AddConnection(click.MouseButton1Up, function()
					tb:CaptureFocus()
				end)

				AddConnection(tb.FocusLost, function()
					cfg3.Callback(tb.Text)
					if cfg3.TextDisappear then tb.Text = "" end
				end)

				local api = {}
				function api:Set(v)
					tb.Text = tostring(v)
					cfg3.Callback(tb.Text)
				end
				return api
			end

			-- Colorpicker
			function ElementFunction:AddColorpicker(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Colorpicker"
				cfg3.Default = cfg3.Default or Color3.fromRGB(255, 255, 255)
				cfg3.Callback = cfg3.Callback or function() end
				cfg3.Flag = cfg3.Flag or nil
				cfg3.Save = cfg3.Save or false

				local Colorpicker = { Value = cfg3.Default, Toggled = false, Type = "Colorpicker", Save = cfg3.Save }
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
				ApplyCard(preview, { shadow = false, transparency = 0.0, gradient = false })
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
				sel.Image = "rbxassetid://4805639000"
				sel.Size = UDim2.new(0, 16, 0, 16)
				sel.AnchorPoint = Vector2.new(0.5, 0.5)
				sel.Parent = colorSquare

				local hueSel = Instance.new("ImageLabel")
				hueSel.BackgroundTransparency = 1
				hueSel.Image = "rbxassetid://4805639000"
				hueSel.Size = UDim2.new(0, 16, 0, 16)
				hueSel.AnchorPoint = Vector2.new(0.5, 0.5)
				hueSel.Parent = hueBar

				local colorInputConn, hueInputConn

				local function syncSelectors()
					sel.Position = UDim2.new(ColorS, 0, 1 - ColorV, 0)
					hueSel.Position = UDim2.new(0.5, 0, 1 - ColorH, 0)
				end

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
					syncSelectors()
					updateUI()
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

				local click = SetProps(MakeElement("Button"), { Size = UDim2.new(1, 0, 1, 0), Parent = f })
				ApplyHitEffects(click, f, { accentStroke = true })

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

				-- returns a fresh element table bound to the section holder
				return GetElements(holder)
			end

			-- SearchBox (filters siblings under ItemParent / Section holder)
			function ElementFunction:AddSearchBox(cfg3)
				cfg3 = cfg3 or {}
				cfg3.Name = cfg3.Name or "Search"
				cfg3.Placeholder = cfg3.Placeholder or "Search..."
				cfg3.Callback = cfg3.Callback or function(_) end

				local f = NewElementFrame(42)

				AddThemeObject(SetProps(MakeElement("Label", cfg3.Name, 14), {
					Size = UDim2.new(0, 120, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content",
					Parent = f
				}), "Text")

				local box = SetProps(MakeElement("RoundFrame", t2.Main, 0, 8), {
					Size = UDim2.new(1, -150, 0, 26),
					Position = UDim2.new(1, -12, 0.5, 0),
					AnchorPoint = Vector2.new(1, 0.5),
					Parent = f
				})
				ApplyCard(box, { shadow = false, transparency = 0.10, gradient = true })
				EnsureStroke(box, t2.Stroke, 1, 0.55)

				local tb = AddThemeObject(Instance.new("TextBox"), "Text")
				tb.Size = UDim2.new(1, -10, 1, 0)
				tb.Position = UDim2.new(0, 5, 0, 0)
				tb.BackgroundTransparency = 1
				tb.ClearTextOnFocus = false
				tb.PlaceholderText = cfg3.Placeholder
				tb.Text = ""
				tb.Font = Enum.Font.GothamMedium
				tb.TextSize = 13
				tb.TextXAlignment = Enum.TextXAlignment.Left
				tb.Parent = box

				local function applyFilter(q)
					q = tostring(q or ""):lower()
					for _, child in ipairs(ItemParent:GetChildren()) do
						if child:IsA("Frame") or child:IsA("TextButton") then
							local ok = true
							if q ~= "" then
								ok = false
								local label = child:FindFirstChild("Content", true) or child:FindFirstChild("Title", true)
								if label and label:IsA("TextLabel") then
									ok = tostring(label.Text):lower():find(q, 1, true) ~= nil
								end
							end
							if child ~= f then
								child.Visible = ok
							end
						end
					end
				end

				AddConnection(tb:GetPropertyChangedSignal("Text"), function()
					applyFilter(tb.Text)
					cfg3.Callback(tb.Text)
				end)

				local api = {}
				function api:Set(v)
					tb.Text = tostring(v or "")
					applyFilter(tb.Text)
				end
				return api
			end

			return ElementFunction
		end

		local ElementFunction = {}
		for k, v in next, GetElements(Container) do
			ElementFunction[k] = v
		end

		-- Premium-only behavior: no-op creators
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

	-- optional window methods
	TabFunction.SetTheme = function(_, themeName)
		NexacLib:SetTheme(themeName)
	end

	TabFunction.Toggle = function()
		MainWindow.Visible = not MainWindow.Visible
		NexacLib.UI.Enabled = MainWindow.Visible
	end

	return TabFunction
end

function NexacLib:Destroy()
	pcall(function() Nexac:Destroy() end)
end

return NexacLib
