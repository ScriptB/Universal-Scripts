--[[
	ESP Script - by Asuneteric
	Features: Box, Name, Health, Distance, Tracers, Head Dot
]]

assert(Drawing, "ESP: Drawing API not supported by this executor")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local V2 = Vector2.new
local V3 = Vector3.new

--> [< Settings >] <--

local Settings = {
    Enabled      = true,
    Box          = true,
    Names        = true,
    HealthBar    = true,
    Distance     = true,
    Tracers      = false,
    HeadDot      = false,
    TeamCheck    = false,
    VisCheck     = false,
    TextSize     = 13,
    MaxDistance  = 1000,
    BoxThickness = 1,
    TracerThickness = 1,
    BoxColor         = Color3.fromRGB(255, 0, 0),
    NameColor        = Color3.fromRGB(255, 255, 255),
    TracerColor      = Color3.fromRGB(255, 255, 0),
    TeamColor        = Color3.fromRGB(0, 162, 255),
}

--> [< Storage >] <--

local ESPData = {}
local QUAD_SUPPORTED = pcall(function() Drawing.new("Quad"):Remove() end)

--> [< Helpers >] <--

local function WorldToViewport(pos)
    return Camera:WorldToViewportPoint(pos)
end

local function isTeammate(player)
    if not Settings.TeamCheck then return false end
    return player.Team == LocalPlayer.Team
end

local function checkWall(player, character)
    if not Settings.VisCheck then return true end
    local head = character:FindFirstChild("Head")
    if not head then return false end
    local origin = Camera.CFrame.Position
    local dir = (head.Position - origin)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, character}
    params.FilterType = Enum.RaycastFilterType.Blacklist
    local result = workspace:Raycast(origin, dir, params)
    return result == nil
end

local function getHealthColor(h, max)
    local r = math.clamp(h / max, 0, 1)
    return Color3.fromRGB(math.floor((1 - r) * 255), math.floor(r * 255), 0)
end

local function newDrawing(dtype, props)
    local d = Drawing.new(dtype)
    for k, v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

--> [< Per-player ESP object >] <--

local function createESP(player)
    local obj = {}

    -- Box
    if QUAD_SUPPORTED then
        obj.box = newDrawing("Quad", {Visible = false, Color = Settings.BoxColor, Thickness = Settings.BoxThickness, Filled = false, ZIndex = 2})
        obj.boxOutline = newDrawing("Quad", {Visible = false, Color = Color3.fromRGB(0,0,0), Thickness = Settings.BoxThickness + 2, Filled = false, ZIndex = 1})
    else
        obj.boxL = newDrawing("Line", {Visible = false, Color = Settings.BoxColor, Thickness = Settings.BoxThickness, ZIndex = 2})
        obj.boxR = newDrawing("Line", {Visible = false, Color = Settings.BoxColor, Thickness = Settings.BoxThickness, ZIndex = 2})
        obj.boxT = newDrawing("Line", {Visible = false, Color = Settings.BoxColor, Thickness = Settings.BoxThickness, ZIndex = 2})
        obj.boxB = newDrawing("Line", {Visible = false, Color = Settings.BoxColor, Thickness = Settings.BoxThickness, ZIndex = 2})
    end

    -- Name
    obj.name = newDrawing("Text", {
        Visible = false, Text = "", Size = Settings.TextSize,
        Color = Settings.NameColor, Center = true,
        Outline = true, OutlineColor = Color3.fromRGB(0,0,0), ZIndex = 3
    })

    -- Distance (shown below name)
    obj.dist = newDrawing("Text", {
        Visible = false, Text = "", Size = Settings.TextSize - 1,
        Color = Color3.fromRGB(200,200,200), Center = true,
        Outline = true, OutlineColor = Color3.fromRGB(0,0,0), ZIndex = 3
    })

    -- Health bar background + fill
    obj.healthBG = newDrawing("Line", {Visible = false, Color = Color3.fromRGB(0,0,0), Thickness = 4, ZIndex = 2})
    obj.health   = newDrawing("Line", {Visible = false, Color = Color3.fromRGB(0,255,0), Thickness = 2, ZIndex = 3})

    -- Tracer + outline
    obj.tracerOutline = newDrawing("Line", {Visible = false, Color = Color3.fromRGB(0,0,0), Thickness = Settings.TracerThickness + 2, ZIndex = 1})
    obj.tracer        = newDrawing("Line", {Visible = false, Color = Settings.TracerColor, Thickness = Settings.TracerThickness, ZIndex = 2})

    -- Head dot
    obj.headDot = newDrawing("Circle", {Visible = false, Filled = true, NumSides = 20, Radius = 4, Color = Settings.BoxColor, ZIndex = 3})

    ESPData[player] = obj
end

local function removeESP(player)
    local obj = ESPData[player]
    if not obj then return end
    for _, d in pairs(obj) do
        pcall(function() d.Visible = false d:Remove() end)
    end
    ESPData[player] = nil
end

local function hideAll(obj)
    for _, d in pairs(obj) do
        pcall(function() d.Visible = false end)
    end
end

local function setBoxVisible(obj, vis, color)
    if QUAD_SUPPORTED then
        obj.box.Visible = vis
        obj.boxOutline.Visible = vis
        if color then obj.box.Color = color end
    else
        for _, k in ipairs({"boxL","boxR","boxT","boxB"}) do
            obj[k].Visible = vis
            if color then obj[k].Color = color end
        end
    end
end

local function updateBox(obj, tl, tr, bl, br, color)
    if QUAD_SUPPORTED then
        obj.boxOutline.PointA = tl
        obj.boxOutline.PointB = tr
        obj.boxOutline.PointC = br
        obj.boxOutline.PointD = bl
        obj.boxOutline.Visible = true
        obj.box.PointA = tl
        obj.box.PointB = tr
        obj.box.PointC = br
        obj.box.PointD = bl
        obj.box.Color = color
        obj.box.Visible = true
    else
        -- Top
        obj.boxT.From = tl obj.boxT.To = tr obj.boxT.Color = color obj.boxT.Visible = true
        -- Bottom
        obj.boxB.From = bl obj.boxB.To = br obj.boxB.Color = color obj.boxB.Visible = true
        -- Left
        obj.boxL.From = tl obj.boxL.To = bl obj.boxL.Color = color obj.boxL.Visible = true
        -- Right
        obj.boxR.From = tr obj.boxR.To = br obj.boxR.Color = color obj.boxR.Visible = true
    end
end

--> [< Main Update >] <--

local function updateESP(player, obj)
    local character = player.Character
    if not character then hideAll(obj) return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    if not humanoid or not hrp or not head or humanoid.Health <= 0 then
        hideAll(obj) return
    end

    local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
    if dist > Settings.MaxDistance then hideAll(obj) return end

    if Settings.VisCheck and not checkWall(player, character) then
        hideAll(obj) return
    end

    local headScreen, headVis = WorldToViewport(head.Position)
    if headScreen.Z < 0 then hideAll(obj) return end

    local color = isTeammate(player) and Settings.TeamColor or Settings.BoxColor

    -- Calculate bounding box from character parts
    local scale = head.Size.Y / 2
    local topPos, _ = WorldToViewport((hrp:GetRenderCFrame() * CFrame.new(0, head.Size.Y + hrp.Size.Y + 0.1, 0)).Position)
    local botPos, _ = WorldToViewport((hrp:GetRenderCFrame() * CFrame.new(0, -hrp.Size.Y, 0)).Position)

    local height = math.abs(topPos.Y - botPos.Y)
    local width  = height * 0.55
    local cx     = headScreen.X
    local top    = topPos.Y
    local bot    = botPos.Y
    local left   = cx - width / 2
    local right  = cx + width / 2

    -- Box
    if Settings.Box then
        local tl = V2(left, top)
        local tr = V2(right, top)
        local bl = V2(left, bot)
        local br = V2(right, bot)
        updateBox(obj, tl, tr, bl, br, color)
    else
        setBoxVisible(obj, false)
    end

    -- Name
    if Settings.Names then
        obj.name.Text     = player.DisplayName
        obj.name.Position = V2(cx, top - 16)
        obj.name.Color    = Settings.NameColor
        obj.name.Size     = Settings.TextSize
        obj.name.Visible  = true
    else
        obj.name.Visible = false
    end

    -- Distance
    if Settings.Distance then
        obj.dist.Text     = string.format("[%dm]", math.floor(dist))
        obj.dist.Position = V2(cx, top - (Settings.Names and 28 or 16))
        obj.dist.Size     = Settings.TextSize - 1
        obj.dist.Visible  = true
    else
        obj.dist.Visible = false
    end

    -- Health bar
    if Settings.HealthBar then
        local ratio     = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local barX      = left - 5
        local barHeight = (bot - top) * ratio

        obj.healthBG.From    = V2(barX, top)
        obj.healthBG.To      = V2(barX, bot)
        obj.healthBG.Visible = true

        obj.health.From    = V2(barX, bot)
        obj.health.To      = V2(barX, bot + barHeight * -1)
        obj.health.Color   = getHealthColor(humanoid.Health, humanoid.MaxHealth)
        obj.health.Visible = true
    else
        obj.healthBG.Visible = false
        obj.health.Visible   = false
    end

    -- Tracers
    if Settings.Tracers then
        local origin = V2(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        local target = V2(cx, bot)

        obj.tracerOutline.From    = origin
        obj.tracerOutline.To      = target
        obj.tracerOutline.Visible = true

        obj.tracer.From    = origin
        obj.tracer.To      = target
        obj.tracer.Color   = isTeammate(player) and Settings.TeamColor or Settings.TracerColor
        obj.tracer.Visible = true
    else
        obj.tracerOutline.Visible = false
        obj.tracer.Visible        = false
    end

    -- Head dot
    if Settings.HeadDot then
        local topH, _ = WorldToViewport((head.CFrame * CFrame.new(0, scale, 0)).Position)
        local botH, _ = WorldToViewport((head.CFrame * CFrame.new(0, -scale, 0)).Position)
        obj.headDot.Radius   = math.abs((topH - botH).Y)
        obj.headDot.Position = V2(headScreen.X, headScreen.Y)
        obj.headDot.Color    = color
        obj.headDot.Visible  = true
    else
        obj.headDot.Visible = false
    end
end

--> [< Keybind Toggle (standalone) >] <--

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.F5 then
        Settings.Enabled = not Settings.Enabled
    end
end)

--> [< Player Management >] <--

local function onPlayerAdded(player)
    if player == LocalPlayer then return end
    createESP(player)
end

local function onPlayerRemoving(player)
    removeESP(player)
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

--> [< Render Loop >] <--

local lastUpdate = 0
local REFRESH = 1 / 60

RunService.RenderStepped:Connect(function()
    local now = tick()
    if now - lastUpdate < REFRESH then return end
    lastUpdate = now

    if not Settings.Enabled then
        for _, obj in pairs(ESPData) do hideAll(obj) end
        return
    end

    for player, obj in pairs(ESPData) do
        local ok, err = pcall(updateESP, player, obj)
        if not ok then hideAll(obj) end
    end
end)

--> [< Public API >] <--

return {
    Settings = Settings,
    setEnabled      = function(v) Settings.Enabled = v end,
    setBox          = function(v) Settings.Box = v end,
    setNames        = function(v) Settings.Names = v end,
    setHealthBar    = function(v) Settings.HealthBar = v end,
    setDistance     = function(v) Settings.Distance = v end,
    setTracers      = function(v) Settings.Tracers = v end,
    setHeadDot      = function(v) Settings.HeadDot = v end,
    setTeamCheck    = function(v) Settings.TeamCheck = v end,
    setVisCheck     = function(v) Settings.VisCheck = v end,
    setBoxColor     = function(v) Settings.BoxColor = v end,
    setNameColor    = function(v) Settings.NameColor = v end,
    setTracerColor  = function(v) Settings.TracerColor = v end,
    setMaxDistance  = function(v) Settings.MaxDistance = v end,
    setTextSize     = function(v) Settings.TextSize = v end,
}
