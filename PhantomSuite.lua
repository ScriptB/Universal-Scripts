--[[
	Phantom Suite  v2.0
	by Asuneteric

	Precision aimbot and ESP for competitive advantage.

	Features:
	  - Aimbot with smoothing, prediction, sticky aim, wall/team/health checks
	  - ESP with box, names, health bar, distance, tracers, head dot
	  - Full real-time Bracket UI controls
]]

local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Bracket%20Ui"))()
Bracket:Notification({Title = "Phantom Suite", Description = "Precision aimbot and ESP  —  by Asuneteric", Duration = 5})
Bracket:Notification2({Title = "Phantom Suite"})

local RunService = game:GetService("RunService")
local players    = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local plr        = players.LocalPlayer
local camera     = workspace.CurrentCamera
local mouse      = plr:GetMouse()

--> [< Aimbot Variables >] <--

local hue = 0
local rainbowFov = false
local rainbowSpeed = 0.005

local aimFov = 100
local aiming = false
local predictionStrength = 0.065
local smoothing = 0.05

local aimbotEnabled = false
local wallCheck = true
local stickyAimEnabled = false
local teamCheck = false
local healthCheck = false
local minHealth = 0

local circleColor = Color3.fromRGB(255, 0, 0)
local targetedCircleColor = Color3.fromRGB(0, 255, 0)

--> [< ESP Variables >] <--

local espEnabled   = false
local espBox       = true
local espNames     = true
local espHealth    = true
local espDistance  = true
local espTracers   = false
local espHeadDot   = false
local espTeamCheck = false
local espVisCheck  = false
local espMaxDist   = 1000
local espTextSize  = 13
local espBoxColor    = Color3.fromRGB(255, 0, 0)
local espNameColor   = Color3.fromRGB(255, 255, 255)
local espTracerColor = Color3.fromRGB(255, 255, 0)
local espTeamColor   = Color3.fromRGB(0, 162, 255)

local ESPData = {}
local QUAD_SUPPORTED = pcall(function() Drawing.new("Quad"):Remove() end)

--> [< UI Window >] <--

local Window = Bracket:Window({
    Name = "▶ Universal Aimbot + ESP ◀",
    Enabled = true,
    Color = Color3.fromRGB(100, 150, 255),
    Size = UDim2.new(0, 500, 0, 500),
    Position = UDim2.new(0.5, -250, 0.5, -250)
})

local uiVisible = true
local function setUIVisible(state)
	uiVisible = state
	pcall(function() Window.Enabled = state end)
	local function scan(parent)
		for _, v in ipairs(parent:GetChildren()) do
			if v:IsA("ScreenGui") and v.Name:lower():find("bracket") then
				v.Enabled = state
			end
		end
	end
	pcall(function() scan(game:GetService("CoreGui")) end)
	pcall(function() scan(plr:WaitForChild("PlayerGui")) end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.RightControl then
		setUIVisible(not uiVisible)
	end
end)

local Aimbot = Window:Tab({Name = "Aimbot 🎯"})
local ESP    = Window:Tab({Name = "ESP 👁"})
local Admin  = Window:Tab({Name = "Admin 👑"})

--> [< FOV Circle >] <--

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = aimFov
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255, 0, 0)

--> [< Aimbot Logic >] <--

local currentTarget = nil

local function checkTeam(player)
    if teamCheck and player.Team == plr.Team then
        return true
    end
    return false
end

local function checkWall(targetCharacter)
    if not targetCharacter then return false end
    local targetHead = targetCharacter:FindFirstChild("Head")
    if not targetHead then return false end

    local origin = camera.CFrame.Position
    local direction = targetHead.Position - origin
	if direction.Magnitude <= 0 then return false end

    local ignore = {targetCharacter, workspace.CurrentCamera}
    if plr.Character then table.insert(ignore, plr.Character) end

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = ignore
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    raycastParams.RespectCanCollide = true

	for _ = 1, 2 do
		local raycastResult = workspace:Raycast(origin, direction, raycastParams)
		if not raycastResult then
			return false
		end
		local hit = raycastResult.Instance
		if hit and hit:IsA("BasePart") and (hit.Transparency >= 0.95 or hit.CanCollide == false) then
			table.insert(ignore, hit)
			raycastParams.FilterDescendantsInstances = ignore
		else
			return true
		end
	end

	return true
end

local function getTarget()
    local nearestPlayer = nil
    local shortestCursorDistance = aimFov
    local shortestPlayerDistance = math.huge
    local cameraPos = camera.CFrame.Position
    for _, player in ipairs(players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("Head") and not checkTeam(player) then
            if player.Character.Humanoid.Health >= minHealth or not healthCheck then
                local head = player.Character.Head
                local headPos = camera:WorldToViewportPoint(head.Position)
                local screenPos = Vector2.new(headPos.X, headPos.Y)
                local mousePos = Vector2.new(mouse.X, mouse.Y)
                local cursorDistance = (screenPos - mousePos).Magnitude
                local playerDistance = (head.Position - cameraPos).Magnitude
                if cursorDistance < shortestCursorDistance and headPos.Z > 0 then
                    if (not wallCheck) or (not checkWall(player.Character)) then
                        if playerDistance < shortestPlayerDistance then
                            shortestPlayerDistance = playerDistance
                            shortestCursorDistance = cursorDistance
                            nearestPlayer = player
                        end
                    end
                end
            end
        end
    end
    return nearestPlayer
end

local function predict(player)
    if player and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
        local head = player.Character.Head
        local hrp = player.Character.HumanoidRootPart
        local velocity = hrp.Velocity
        local predictedPosition = head.Position + (velocity * predictionStrength)
        return predictedPosition
    end
    return nil
end

local function smooth(from, to)
    return from:Lerp(to, smoothing)
end

local function aimAt(player)
    local predictedPosition = predict(player)
    if predictedPosition then
        if player.Character.Humanoid.Health >= minHealth or not healthCheck then
            local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPosition)
            camera.CFrame = smooth(camera.CFrame, targetCFrame)
        end
    end
end

--> [< ESP Logic >] <--

local function newDrawing(dtype, props)
    local d = Drawing.new(dtype)
    for k, v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

local function espIsTeammate(player)
    if not espTeamCheck then return false end
    return player.Team == plr.Team
end

local function espCheckWall(character)
    if not espVisCheck then return true end
    local head = character:FindFirstChild("Head")
    if not head then return false end
    local origin = camera.CFrame.Position
    local dir = head.Position - origin
    local params = RaycastParams.new()
    local ignore = {character, workspace.CurrentCamera}
    if plr.Character then table.insert(ignore, plr.Character) end
    params.FilterDescendantsInstances = ignore
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.IgnoreWater = true
    params.RespectCanCollide = true

	for _ = 1, 2 do
		local result = workspace:Raycast(origin, dir, params)
		if not result then
			return true
		end
		local hit = result.Instance
		if hit and hit:IsA("BasePart") and (hit.Transparency >= 0.95 or hit.CanCollide == false) then
			table.insert(ignore, hit)
			params.FilterDescendantsInstances = ignore
		else
			return false
		end
	end

	return false
end

local function getHealthColor(h, max)
    local r = math.clamp(h / max, 0, 1)
    return Color3.fromRGB(math.floor((1 - r) * 255), math.floor(r * 255), 0)
end

local function createESP(player)
    local obj = {}
    if QUAD_SUPPORTED then
        obj.box        = newDrawing("Quad", {Visible=false, Color=espBoxColor, Thickness=1, Filled=false})
        obj.boxOutline = newDrawing("Quad", {Visible=false, Color=Color3.fromRGB(0,0,0), Thickness=3, Filled=false})
    else
        obj.boxT = newDrawing("Line", {Visible=false, Color=espBoxColor, Thickness=1})
        obj.boxB = newDrawing("Line", {Visible=false, Color=espBoxColor, Thickness=1})
        obj.boxL = newDrawing("Line", {Visible=false, Color=espBoxColor, Thickness=1})
        obj.boxR = newDrawing("Line", {Visible=false, Color=espBoxColor, Thickness=1})
    end
    obj.name        = newDrawing("Text",   {Visible=false, Text="", Size=espTextSize, Color=espNameColor, Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
    obj.dist        = newDrawing("Text",   {Visible=false, Text="", Size=espTextSize-1, Color=Color3.fromRGB(200,200,200), Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
    obj.healthBG    = newDrawing("Line",   {Visible=false, Color=Color3.fromRGB(0,0,0), Thickness=4})
    obj.health      = newDrawing("Line",   {Visible=false, Color=Color3.fromRGB(0,255,0), Thickness=2})
    obj.tracerOut   = newDrawing("Line",   {Visible=false, Color=Color3.fromRGB(0,0,0), Thickness=3})
    obj.tracer      = newDrawing("Line",   {Visible=false, Color=espTracerColor, Thickness=1})
    obj.headDot     = newDrawing("Circle", {Visible=false, Filled=true, NumSides=20, Radius=4, Color=espBoxColor})
    ESPData[player] = obj
end

local function removeESP(player)
    local obj = ESPData[player]
    if not obj then return end
    for _, d in pairs(obj) do pcall(function() d.Visible=false d:Remove() end) end
    ESPData[player] = nil
end

local function hideESPObj(obj)
    for _, d in pairs(obj) do pcall(function() d.Visible = false end) end
end

local function setBoxVis(obj, vis, color)
    if QUAD_SUPPORTED then
        obj.box.Visible = vis
        obj.boxOutline.Visible = vis
        if color and vis then obj.box.Color = color end
    else
        for _, k in ipairs({"boxT","boxB","boxL","boxR"}) do
            obj[k].Visible = vis
            if color and vis then obj[k].Color = color end
        end
    end
end

local function drawBox(obj, tl, tr, bl, br, color)
    if QUAD_SUPPORTED then
        obj.boxOutline.PointA=tl obj.boxOutline.PointB=tr obj.boxOutline.PointC=br obj.boxOutline.PointD=bl obj.boxOutline.Visible=true
        obj.box.PointA=tl obj.box.PointB=tr obj.box.PointC=br obj.box.PointD=bl obj.box.Color=color obj.box.Visible=true
    else
        obj.boxT.From=tl obj.boxT.To=tr obj.boxT.Color=color obj.boxT.Visible=true
        obj.boxB.From=bl obj.boxB.To=br obj.boxB.Color=color obj.boxB.Visible=true
        obj.boxL.From=tl obj.boxL.To=bl obj.boxL.Color=color obj.boxL.Visible=true
        obj.boxR.From=tr obj.boxR.To=br obj.boxR.Color=color obj.boxR.Visible=true
    end
end

local function updateESP(player, obj)
    local character = player.Character
    if not character then hideESPObj(obj) return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not humanoid or not hrp or not head or humanoid.Health <= 0 then hideESPObj(obj) return end
    local dist = (hrp.Position - camera.CFrame.Position).Magnitude
    if dist > espMaxDist then hideESPObj(obj) return end
    if espVisCheck and not espCheckWall(character) then hideESPObj(obj) return end
    local headScreen = camera:WorldToViewportPoint(head.Position)
    if headScreen.Z < 0 then hideESPObj(obj) return end

    local color = espIsTeammate(player) and espTeamColor or espBoxColor
    local scale = head.Size.Y / 2
    local hrpCF = hrp.CFrame
    pcall(function() hrpCF = hrp:GetRenderCFrame() end)
    local topPos = camera:WorldToViewportPoint((hrpCF * CFrame.new(0, head.Size.Y + hrp.Size.Y + 0.1, 0)).Position)
    local botPos = camera:WorldToViewportPoint((hrpCF * CFrame.new(0, -hrp.Size.Y, 0)).Position)
    local height = math.abs(topPos.Y - botPos.Y)
    local width  = height * 0.55
    local cx     = headScreen.X
    local top    = topPos.Y
    local bot    = botPos.Y
    local left   = cx - width / 2
    local right  = cx + width / 2

    -- Box
    if espBox then
        drawBox(obj, Vector2.new(left,top), Vector2.new(right,top), Vector2.new(left,bot), Vector2.new(right,bot), color)
    else
        setBoxVis(obj, false)
    end

    -- Name
    if espNames then
        obj.name.Text = player.DisplayName
        obj.name.Position = Vector2.new(cx, top - 16)
        obj.name.Color = espNameColor
        obj.name.Size = espTextSize
        obj.name.Visible = true
    else
        obj.name.Visible = false
    end

    -- Distance
    if espDistance then
        obj.dist.Text = string.format("[%dm]", math.floor(dist))
        obj.dist.Position = Vector2.new(cx, top - (espNames and 28 or 16))
        obj.dist.Size = espTextSize - 1
        obj.dist.Visible = true
    else
        obj.dist.Visible = false
    end

    -- Health bar
    if espHealth then
        local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local barX = left - 5
        obj.healthBG.From = Vector2.new(barX, top) obj.healthBG.To = Vector2.new(barX, bot) obj.healthBG.Visible = true
        obj.health.From = Vector2.new(barX, bot) obj.health.To = Vector2.new(barX, bot - (bot - top) * ratio)
        obj.health.Color = getHealthColor(humanoid.Health, humanoid.MaxHealth) obj.health.Visible = true
    else
        obj.healthBG.Visible = false obj.health.Visible = false
    end

    -- Tracers
    if espTracers then
        local origin = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
        local target = Vector2.new(cx, bot)
        obj.tracerOut.From=origin obj.tracerOut.To=target obj.tracerOut.Visible=true
        obj.tracer.From=origin obj.tracer.To=target obj.tracer.Color=espIsTeammate(player) and espTeamColor or espTracerColor obj.tracer.Visible=true
    else
        obj.tracerOut.Visible=false obj.tracer.Visible=false
    end

    -- Head dot
    if espHeadDot then
        local topH = camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, scale, 0)).Position)
        local botH = camera:WorldToViewportPoint((head.CFrame * CFrame.new(0, -scale, 0)).Position)
        obj.headDot.Radius = math.abs((Vector2.new(topH.X,topH.Y) - Vector2.new(botH.X,botH.Y)).Magnitude)
        obj.headDot.Position = Vector2.new(headScreen.X, headScreen.Y)
        obj.headDot.Color = color obj.headDot.Visible = true
    else
        obj.headDot.Visible = false
    end
end

--> [< Player Management >] <--

local function onPlayerAdded(player)
    if player == plr then return end
    createESP(player)
end

local function onPlayerRemoving(player)
    removeESP(player)
end

for _, player in ipairs(players:GetPlayers()) do onPlayerAdded(player) end
players.PlayerAdded:Connect(onPlayerAdded)
players.PlayerRemoving:Connect(onPlayerRemoving)

--> [< Render Loop >] <--

RunService.RenderStepped:Connect(function()
    -- FOV circle
    fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 50)
    if rainbowFov then
        hue = hue + rainbowSpeed
        if hue > 1 then hue = 0 end
        fovCircle.Color = Color3.fromHSV(hue, 1, 1)
    else
        fovCircle.Color = (aiming and currentTarget) and targetedCircleColor or circleColor
    end

    -- Aimbot
    if aimbotEnabled then
        if aiming then
            if stickyAimEnabled and currentTarget then
                local headPos = camera:WorldToViewportPoint(currentTarget.Character.Head.Position)
                local screenPos = Vector2.new(headPos.X, headPos.Y)
                local cursorDistance = (screenPos - Vector2.new(mouse.X, mouse.Y)).Magnitude
                if cursorDistance > aimFov or (wallCheck and checkWall(currentTarget.Character)) or checkTeam(currentTarget) then
                    currentTarget = nil
                end
            end
            if not stickyAimEnabled or not currentTarget then
                currentTarget = getTarget()
            end
            if currentTarget then aimAt(currentTarget) end
        else
            currentTarget = nil
        end
    end

    -- ESP
    if not espEnabled then
        for _, obj in pairs(ESPData) do hideESPObj(obj) end
    else
        for player, obj in pairs(ESPData) do
            pcall(updateESP, player, obj)
        end
    end
end)

mouse.Button2Down:Connect(function()
    if aimbotEnabled then aiming = true end
end)
mouse.Button2Up:Connect(function()
    if aimbotEnabled then aiming = false end
end)

--> [< Aimbot UI >] <--

Aimbot:Divider({Text = "Main", Side = "Left"})

Aimbot:Toggle({
    Name = "Aimbot", Side = "Left", Value = false,
    Callback = function(Value)
        aimbotEnabled = Value
        fovCircle.Visible = Value
    end
})

Aimbot:Divider({Text = "Settings", Side = "Left"})

Aimbot:Slider({
    Name = "Smoothing", Side = "Left", Min = 0, Max = 100, Value = 5, Precise = 0, Unit = "",
    Callback = function(Value) smoothing = 1 - (Value / 100) end
})

Aimbot:Slider({
    Name = "Prediction Strength", Side = "Left", Min = 0, Max = 200, Value = 65, Precise = 0, Unit = "",
    Callback = function(Value) predictionStrength = Value / 1000 end
})

Aimbot:Slider({
    Name = "Aimbot Fov", Side = "Left", Min = 0, Max = 1000, Value = 100, Precise = 0, Unit = "",
    Callback = function(Value)
        aimFov = Value
        fovCircle.Radius = aimFov
    end
})

Aimbot:Divider({Text = "Filters", Side = "Left"})

Aimbot:Toggle({
    Name = "Wall Check", Side = "Left", Value = true,
    Callback = function(Value) wallCheck = Value end
})

Aimbot:Toggle({
    Name = "Sticky Aim", Side = "Left", Value = false,
    Callback = function(Value) stickyAimEnabled = Value end
})

Aimbot:Toggle({
    Name = "Team Check (Experimental)", Side = "Left", Value = false,
    Callback = function(Value) teamCheck = Value end
})

Aimbot:Toggle({
    Name = "Health Check (Experimental)", Side = "Left", Value = false,
    Callback = function(Value) healthCheck = Value end
})

Aimbot:Slider({
    Name = "Min Health", Side = "Left", Min = 0, Max = 100, Value = 0, Precise = 0, Unit = "",
    Callback = function(Value) minHealth = Value end
})

Aimbot:Divider({Text = "Visual", Side = "Left"})

Aimbot:Colorpicker({
    Name = "Fov Color", Color = circleColor,
    Callback = function(Table, Color)
        circleColor = Color
        if not rainbowFov then fovCircle.Color = Color end
    end
})

Aimbot:Colorpicker({
    Name = "Targeted Fov Color", Color = targetedCircleColor,
    Callback = function(Table, Color)
        targetedCircleColor = Color
    end
})

Aimbot:Toggle({
    Name = "Rainbow Fov", Side = "Left", Value = false,
    Callback = function(Value) rainbowFov = Value end
})

--> [< ESP UI >] <--

ESP:Divider({Text = "Main", Side = "Left"})

ESP:Toggle({
    Name = "ESP", Side = "Left", Value = false,
    Callback = function(Value) espEnabled = Value end
})

ESP:Divider({Text = "Features", Side = "Left"})

ESP:Toggle({
    Name = "Box", Side = "Left", Value = true,
    Callback = function(Value) espBox = Value end
})

ESP:Toggle({
    Name = "Names", Side = "Left", Value = true,
    Callback = function(Value) espNames = Value end
})

ESP:Toggle({
    Name = "Health Bar", Side = "Left", Value = true,
    Callback = function(Value) espHealth = Value end
})

ESP:Toggle({
    Name = "Distance", Side = "Left", Value = true,
    Callback = function(Value) espDistance = Value end
})

ESP:Toggle({
    Name = "Tracers", Side = "Left", Value = false,
    Callback = function(Value) espTracers = Value end
})

ESP:Toggle({
    Name = "Head Dot", Side = "Left", Value = false,
    Callback = function(Value) espHeadDot = Value end
})

ESP:Divider({Text = "Filters", Side = "Left"})

ESP:Toggle({
    Name = "Team Check", Side = "Left", Value = false,
    Callback = function(Value) espTeamCheck = Value end
})

ESP:Toggle({
    Name = "Visibility Check", Side = "Left", Value = false,
    Callback = function(Value) espVisCheck = Value end
})

ESP:Slider({
    Name = "Max Distance", Side = "Left", Min = 100, Max = 5000, Value = 1000, Precise = 0, Unit = "",
    Callback = function(Value) espMaxDist = Value end
})

ESP:Slider({
    Name = "Text Size", Side = "Left", Min = 8, Max = 24, Value = 13, Precise = 0, Unit = "",
    Callback = function(Value) espTextSize = Value end
})

ESP:Divider({Text = "Colors", Side = "Left"})

ESP:Colorpicker({
    Name = "Box Color", Color = espBoxColor,
    Callback = function(Table, Color)
        espBoxColor = Color
    end
})

ESP:Colorpicker({
    Name = "Name Color", Color = espNameColor,
    Callback = function(Table, Color)
        espNameColor = Color
    end
})

ESP:Colorpicker({
    Name = "Tracer Color", Color = espTracerColor,
    Callback = function(Table, Color)
        espTracerColor = Color
    end
})

ESP:Colorpicker({
    Name = "Team Color", Color = espTeamColor,
    Callback = function(Table, Color)
        espTeamColor = Color
    end
})

--> [< Admin Tab >] <--

Admin:Divider({Text = "Admin Tools", Side = "Left"})

Admin:Button({
    Name = "Load Infinite Yield", Side = "Left",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Infinite-Yield/refs/heads/main/Infinite%20Yield_fixed2.lua"))()
    end
})
