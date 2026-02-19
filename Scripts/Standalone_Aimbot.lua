--[[
	Phantom Suite  v2.2
	by Asuneteric

	Precision aimbot and ESP for competitive advantage.

	Features:
	  - Aimbot with smoothing, prediction, sticky aim, wall/team/health checks
	  - ESP with box, names, health bar, distance, tracers, head dot
	  - Full real-time Bracket UI controls
	  - HWID-keyed config auto-save/load (Phantom-Config.txt)
]]

local RunService = game:GetService("RunService")
local players    = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
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

local aimbotIncludeNPCs = false
local espIncludeNPCs = false
local npcScanInterval = 1
local npcMaxTargets = 60
local npcLastScan = 0
local npcTargets = {}

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

--> [< Extras / Commands Variables >] <--

local flyEnabled       = false
local noclipEnabled    = false
local infJumpEnabled   = false
local flySpeed         = 50
local walkSpeed        = 16
local jumpPower        = 50

local extrasConnections = {
    noclip   = nil,
    infJump  = nil,
    fly      = nil,
}

--> [< HWID + Config System >] <--

local CONFIG_FILE = "Phantom-Config.txt"
local HWID_FILE   = "Phantom-HWID.txt"

local function getHWID()
	local id
	if typeof(gethwid) == "function" then
		pcall(function() id = tostring(gethwid()) end)
		if id and #id > 4 then return id end
	end
	if typeof(syn) == "table" and typeof(syn.request) == "function" then
		pcall(function()
			local r = syn.request({Url="https://httpbin.org/get",Method="GET"})
			if r and r.Headers and r.Headers["X-Amzn-Trace-Id"] then
				id = r.Headers["X-Amzn-Trace-Id"]
			end
		end)
		if id and #id > 4 then return id end
	end
	if typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function" then
		if isfile(HWID_FILE) then
			pcall(function() id = readfile(HWID_FILE) end)
			if id and #id > 4 then return id end
		end
		local seed = tostring(os.time()) .. tostring(math.random(100000,999999)) .. tostring(plr.UserId)
		pcall(function() writefile(HWID_FILE, seed) end)
		return seed
	end
	return tostring(plr.UserId)
end

local HWID = getHWID()

local function configToTable()
	return {
		hwid              = HWID,
		aimbotEnabled     = aimbotEnabled,
		wallCheck         = wallCheck,
		stickyAimEnabled  = stickyAimEnabled,
		teamCheck         = teamCheck,
		healthCheck       = healthCheck,
		minHealth         = minHealth,
		aimFov            = aimFov,
		predictionStrength= predictionStrength * 1000,
		smoothing         = math.floor((1 - smoothing) * 100 + 0.5),
		rainbowFov        = rainbowFov,
		rainbowSpeed      = rainbowSpeed,
		aimbotIncludeNPCs = aimbotIncludeNPCs,
		espEnabled        = espEnabled,
		espBox            = espBox,
		espNames          = espNames,
		espHealth         = espHealth,
		espDistance       = espDistance,
		espTracers        = espTracers,
		espHeadDot        = espHeadDot,
		espTeamCheck      = espTeamCheck,
		espVisCheck       = espVisCheck,
		espMaxDist        = espMaxDist,
		espTextSize       = espTextSize,
		espIncludeNPCs    = espIncludeNPCs,
		npcScanInterval   = npcScanInterval,
		npcMaxTargets     = npcMaxTargets,
		espBoxColorR      = math.floor(espBoxColor.R * 255),
		espBoxColorG      = math.floor(espBoxColor.G * 255),
		espBoxColorB      = math.floor(espBoxColor.B * 255),
		espNameColorR     = math.floor(espNameColor.R * 255),
		espNameColorG     = math.floor(espNameColor.G * 255),
		espNameColorB     = math.floor(espNameColor.B * 255),
		espTracerColorR   = math.floor(espTracerColor.R * 255),
		espTracerColorG   = math.floor(espTracerColor.G * 255),
		espTracerColorB   = math.floor(espTracerColor.B * 255),
		circleColorR      = math.floor(circleColor.R * 255),
		circleColorG      = math.floor(circleColor.G * 255),
		circleColorB      = math.floor(circleColor.B * 255),
		flySpeed          = flySpeed,
		walkSpeed         = walkSpeed,
		jumpPower         = jumpPower,
	}
end

local function saveConfig()
	if typeof(writefile) ~= "function" then return false end
	local data = {}
	if typeof(isfile) == "function" and isfile(CONFIG_FILE) then
		pcall(function()
			data = HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if type(data) ~= "table" then data = {} end
	end
	data[HWID] = configToTable()
	local ok = pcall(function()
		writefile(CONFIG_FILE, HttpService:JSONEncode(data))
	end)
	return ok
end

local loadedConfig = nil
local function loadConfig()
	if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return nil end
	if not isfile(CONFIG_FILE) then return nil end
	local data
	local ok = pcall(function()
		data = HttpService:JSONDecode(readfile(CONFIG_FILE))
	end)
	if not ok or type(data) ~= "table" then return nil end
	local cfg = data[HWID]
	if type(cfg) ~= "table" then return nil end
	return cfg
end

local function applyConfig(cfg)
	if not cfg then return end
	if type(cfg.aimbotEnabled)      == "boolean" then aimbotEnabled     = cfg.aimbotEnabled     end
	if type(cfg.wallCheck)          == "boolean" then wallCheck         = cfg.wallCheck         end
	if type(cfg.stickyAimEnabled)   == "boolean" then stickyAimEnabled  = cfg.stickyAimEnabled  end
	if type(cfg.teamCheck)          == "boolean" then teamCheck         = cfg.teamCheck         end
	if type(cfg.healthCheck)        == "boolean" then healthCheck       = cfg.healthCheck       end
	if type(cfg.minHealth)          == "number"  then minHealth         = cfg.minHealth         end
	if type(cfg.aimFov)             == "number"  then aimFov            = cfg.aimFov            end
	if type(cfg.predictionStrength) == "number"  then predictionStrength= cfg.predictionStrength / 1000 end
	if type(cfg.smoothing)          == "number"  then smoothing         = 1 - (cfg.smoothing / 100) end
	if type(cfg.rainbowFov)         == "boolean" then rainbowFov        = cfg.rainbowFov        end
	if type(cfg.rainbowSpeed)       == "number"  then rainbowSpeed      = cfg.rainbowSpeed      end
	if type(cfg.aimbotIncludeNPCs)  == "boolean" then aimbotIncludeNPCs = cfg.aimbotIncludeNPCs end
	if type(cfg.espEnabled)         == "boolean" then espEnabled        = cfg.espEnabled        end
	if type(cfg.espBox)             == "boolean" then espBox            = cfg.espBox            end
	if type(cfg.espNames)           == "boolean" then espNames          = cfg.espNames          end
	if type(cfg.espHealth)          == "boolean" then espHealth         = cfg.espHealth         end
	if type(cfg.espDistance)        == "boolean" then espDistance       = cfg.espDistance       end
	if type(cfg.espTracers)         == "boolean" then espTracers        = cfg.espTracers        end
	if type(cfg.espHeadDot)         == "boolean" then espHeadDot        = cfg.espHeadDot        end
	if type(cfg.espTeamCheck)       == "boolean" then espTeamCheck      = cfg.espTeamCheck      end
	if type(cfg.espVisCheck)        == "boolean" then espVisCheck       = cfg.espVisCheck       end
	if type(cfg.espMaxDist)         == "number"  then espMaxDist        = cfg.espMaxDist        end
	if type(cfg.espTextSize)        == "number"  then espTextSize       = cfg.espTextSize       end
	if type(cfg.espIncludeNPCs)     == "boolean" then espIncludeNPCs    = cfg.espIncludeNPCs    end
	if type(cfg.npcScanInterval)    == "number"  then npcScanInterval   = cfg.npcScanInterval   end
	if type(cfg.npcMaxTargets)      == "number"  then npcMaxTargets     = cfg.npcMaxTargets     end
	if type(cfg.espBoxColorR)       == "number"  then
		espBoxColor = Color3.fromRGB(cfg.espBoxColorR, cfg.espBoxColorG or 0, cfg.espBoxColorB or 0)
	end
	if type(cfg.espNameColorR)      == "number"  then
		espNameColor = Color3.fromRGB(cfg.espNameColorR, cfg.espNameColorG or 255, cfg.espNameColorB or 255)
	end
	if type(cfg.espTracerColorR)    == "number"  then
		espTracerColor = Color3.fromRGB(cfg.espTracerColorR, cfg.espTracerColorG or 255, cfg.espTracerColorB or 0)
	end
	if type(cfg.circleColorR)       == "number"  then
		circleColor = Color3.fromRGB(cfg.circleColorR, cfg.circleColorG or 0, cfg.circleColorB or 0)
	end
	if type(cfg.flySpeed)           == "number"  then flySpeed   = cfg.flySpeed   end
	if type(cfg.walkSpeed)          == "number"  then walkSpeed  = cfg.walkSpeed  end
	if type(cfg.jumpPower)          == "number"  then jumpPower  = cfg.jumpPower  end
end

loadedConfig = loadConfig()
applyConfig(loadedConfig)

local Bracket = loadstring(game:HttpGet("https://raw.githubusercontent.com/AlexR32/Bracket/main/BracketV32.lua"))()
Bracket:Notification({Title = "Phantom Suite", Description = "Precision aimbot and ESP  —  by Asuneteric", Duration = 5})
Bracket:Notification2({Title = "Phantom Suite"})

local ESPData = {}
local QUAD_SUPPORTED = pcall(function() Drawing.new("Quad"):Remove() end)
local ESPDrawings = {}
local espWasEnabled = false

--> [< UI Window >] <--

local Window = Bracket:Window({
    Name = "▶ Universal Aimbot + ESP ◀",
    Enabled = true,
    Color = Color3.fromRGB(100, 150, 255),
    Size = UDim2.new(0, 500, 0, 500),
    Position = UDim2.new(0.5, -250, 0.5, -250)
})

local uiVisible = true
local uiDestroyed = false
local fovCircle

local function hideAllESPDrawingObjects()
	for d in pairs(ESPDrawings) do
		local ok = pcall(function() d.Visible = false end)
		if not ok then
			ESPDrawings[d] = nil
		end
	end
end

local function destroyUI()
	uiDestroyed = true
	uiVisible = false
	pcall(function() Window.Enabled = false end)
	pcall(function() fovCircle.Visible = false end)
	pcall(function() hideAllESPDrawingObjects() end)
	pcall(function()
		local gui = Bracket and Bracket.ScreenAsset
		if typeof(gui) == "Instance" then
			gui:Destroy()
		end
	end)
	pcall(function()
		for _, parent in ipairs({game:GetService("CoreGui"), plr:FindFirstChildOfClass("PlayerGui")}) do
			if parent then
				for _, v in ipairs(parent:GetDescendants()) do
					if v:IsA("ScreenGui") and v.Name:lower():find("bracket") then
						v:Destroy()
					end
				end
			end
		end
	end)
end

local function setUIVisible(state)
	if uiDestroyed then return end
	uiVisible = state
	pcall(function() Window.Enabled = state end)
	local function scan(parent)
		for _, v in ipairs(parent:GetDescendants()) do
			if v:IsA("ScreenGui") and v.Name:lower():find("bracket") then
				v.Enabled = state
			end
		end
	end
	pcall(function() scan(game:GetService("CoreGui")) end)
	pcall(function() scan(plr:WaitForChild("PlayerGui")) end)
	pcall(function()
		local gui = Bracket and Bracket.ScreenAsset
		if typeof(gui) == "Instance" then
			gui.Enabled = state
		end
	end)
end

local Aimbot   = Window:Tab({Name = "Aimbot 🎯"})
local ESP      = Window:Tab({Name = "ESP 👁"})
local Extras   = Window:Tab({Name = "Extras ⚡"})
local Admin    = Window:Tab({Name = "Admin 👑"})
local Keybinds = Window:Tab({Name = "Keybinds ⌨"})

--> [< FOV Circle >] <--

fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 2
fovCircle.Radius = aimFov
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255, 0, 0)

local showFovCircle = true
local aimFovStep = 10

--> [< Aimbot Logic >] <--

local currentTarget = nil

local function getRootPart(character)
	return character and (character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("LowerTorso"))
end

local function getAimPart(character)
	return character and (character:FindFirstChild("Head") or getRootPart(character))
end

local function resolveCharacter(target)
	if typeof(target) == "Instance" then
		if target:IsA("Player") then
			return target.Character, target
		end
		if target:IsA("Model") then
			return target, players:GetPlayerFromCharacter(target)
		end
	end
	if type(target) == "table" then
		local char = target.Character
		if typeof(char) == "Instance" and char:IsA("Model") then
			return char, players:GetPlayerFromCharacter(char)
		end
	end
	return nil, nil
end

local function checkTeam(target)
	if not teamCheck then return false end
	local _, p = resolveCharacter(target)
	return p ~= nil and p.Team == plr.Team
end

local function checkWall(targetCharacter)
    if not targetCharacter then return false end
    local targetPart = getAimPart(targetCharacter)
    if not targetPart then return false end

    local origin = camera.CFrame.Position
	local direction = targetPart.Position - origin
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

	return false
end

local createESP, removeESP

local function ensureNPCScan()
	if not (aimbotIncludeNPCs or espIncludeNPCs) then
		if next(npcTargets) then
			for model in pairs(npcTargets) do
				npcTargets[model] = nil
				removeESP(model)
			end
		end
		return
	end
	local now = os.clock()
	if now - npcLastScan < npcScanInterval then return end
	npcLastScan = now

	local found = {}
	local count = 0
	local inspected = 0
	local maxInspect = 6000
	local roots = {}
	for _, name in ipairs({"NPCs","Bots","Mobs","Enemies","Enemy","AI"}) do
		local inst = workspace:FindFirstChild(name)
		if inst then
			roots[#roots + 1] = inst
		end
	end
	if #roots == 0 then
		roots[1] = workspace
	end

	for _, root in ipairs(roots) do
		for _, hum in ipairs(root:GetDescendants()) do
			inspected += 1
			if inspected >= maxInspect then break end
			if hum:IsA("Humanoid") and hum.Health > 0 then
				local model = hum.Parent
				while model and not model:IsA("Model") do
					model = model.Parent
				end
				if model and model:IsA("Model") and model ~= plr.Character and players:GetPlayerFromCharacter(model) == nil then
					local part = getAimPart(model)
					local rootPart = getRootPart(model)
					if part and rootPart then
						found[model] = true
						count += 1
						if count >= npcMaxTargets then
							break
						end
					end
				end
			end
		end
		if count >= npcMaxTargets or inspected >= maxInspect then
			break
		end
	end

	for model in pairs(npcTargets) do
		if not found[model] then
			npcTargets[model] = nil
			removeESP(model)
		end
	end
	for model in pairs(found) do
		npcTargets[model] = true
		if espIncludeNPCs and ESPData[model] == nil then
			createESP(model)
		end
	end
end

local function getTarget()
	ensureNPCScan()
    local nearestPlayer = nil
    local shortestCursorDistance = aimFov
    local shortestPlayerDistance = math.huge
    local cameraPos = camera.CFrame.Position
    for _, player in ipairs(players:GetPlayers()) do
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local aimPart = getAimPart(character)
        if player ~= plr and character and humanoid and humanoid.Health > 0 and aimPart and not checkTeam(character) then
            if humanoid.Health >= minHealth or not healthCheck then
                local headPos = camera:WorldToViewportPoint(aimPart.Position)
                local screenPos = Vector2.new(headPos.X, headPos.Y)
                local mousePos = Vector2.new(mouse.X, mouse.Y)
                local cursorDistance = (screenPos - mousePos).Magnitude
                local playerDistance = (aimPart.Position - cameraPos).Magnitude
                if cursorDistance < shortestCursorDistance and headPos.Z > 0 then
                    if (not wallCheck) or (not checkWall(character)) then
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

	if aimbotIncludeNPCs then
		for model in pairs(npcTargets) do
			local character = model
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local aimPart = getAimPart(character)
			if humanoid and humanoid.Health > 0 and aimPart then
				if humanoid.Health >= minHealth or not healthCheck then
					local headPos = camera:WorldToViewportPoint(aimPart.Position)
					local screenPos = Vector2.new(headPos.X, headPos.Y)
					local mousePos = Vector2.new(mouse.X, mouse.Y)
					local cursorDistance = (screenPos - mousePos).Magnitude
					local playerDistance = (aimPart.Position - cameraPos).Magnitude
					if cursorDistance < shortestCursorDistance and headPos.Z > 0 then
						if (not wallCheck) or (not checkWall(character)) then
							if playerDistance < shortestPlayerDistance then
								shortestPlayerDistance = playerDistance
								shortestCursorDistance = cursorDistance
								nearestPlayer = {Character = character}
							end
						end
					end
				end
			end
		end
	end
    return nearestPlayer
end

local function predict(player)
    if player and player.Character then
        local aimPart = getAimPart(player.Character)
        local hrp = getRootPart(player.Character)
        if not aimPart or not hrp then return nil end
        local velocity = hrp.Velocity
        local predictedPosition = aimPart.Position + (velocity * predictionStrength)
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
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health > 0 and (humanoid.Health >= minHealth or not healthCheck) then
            local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPosition)
            camera.CFrame = smooth(camera.CFrame, targetCFrame)
        end
    end
end

--> [< ESP Logic >] <--

local function newDrawing(dtype, props)
    local d = Drawing.new(dtype)
	ESPDrawings[d] = true
    for k, v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

local function espIsTeammate(target)
    if not espTeamCheck then return false end
	local _, p = resolveCharacter(target)
	return p ~= nil and p.Team == plr.Team
end

local function espCheckWall(character)
    if not espVisCheck then return true end
    local part = getAimPart(character)
    if not part then return false end
    local origin = camera.CFrame.Position
    local dir = part.Position - origin
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

	return true
end

local function getHealthColor(h, max)
    local r = math.clamp(h / max, 0, 1)
    return Color3.fromRGB(math.floor((1 - r) * 255), math.floor(r * 255), 0)
end

createESP = function(target)
	if ESPData[target] then
		removeESP(target)
	end
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
    ESPData[target] = obj
end

removeESP = function(target)
    local obj = ESPData[target]
    if not obj then return end
    for _, d in pairs(obj) do
		pcall(function() d.Visible=false d:Remove() end)
		ESPDrawings[d] = nil
	end
    ESPData[target] = nil
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
    local character, p = resolveCharacter(player)
    if not character then hideESPObj(obj) return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = getRootPart(character)
    local head = character:FindFirstChild("Head")
    local aimPart = getAimPart(character)
    if not humanoid or not hrp or not aimPart or humanoid.Health <= 0 then hideESPObj(obj) return end
    local dist = (hrp.Position - camera.CFrame.Position).Magnitude
    if dist > espMaxDist then hideESPObj(obj) return end
    if espVisCheck and not espCheckWall(character) then hideESPObj(obj) return end
    local headScreen = camera:WorldToViewportPoint(aimPart.Position)
    if headScreen.Z < 0 then hideESPObj(obj) return end

    local color = espIsTeammate(player) and espTeamColor or espBoxColor
    local scale = (head and head.Size.Y or 2) / 2
    local hrpCF = hrp.CFrame
    pcall(function() hrpCF = hrp:GetRenderCFrame() end)
    local headSizeY = head and head.Size.Y or 2
    local topPos = camera:WorldToViewportPoint((hrpCF * CFrame.new(0, headSizeY + hrp.Size.Y + 0.1, 0)).Position)
    local botPos = camera:WorldToViewportPoint((hrpCF * CFrame.new(0, -hrp.Size.Y, 0)).Position)
    if topPos.Z <= 0 or botPos.Z <= 0 then hideESPObj(obj) return end
    local height = math.abs(topPos.Y - botPos.Y)
    if height ~= height or height <= 1 or height > (camera.ViewportSize.Y * 5) then hideESPObj(obj) return end
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
        local name = character.Name
        if p then
            name = p.DisplayName
        end
        obj.name.Text = name
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
        local dotPart = head or aimPart
        local topH = camera:WorldToViewportPoint((dotPart.CFrame * CFrame.new(0, scale, 0)).Position)
        local botH = camera:WorldToViewportPoint((dotPart.CFrame * CFrame.new(0, -scale, 0)).Position)
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


RunService.RenderStepped:Connect(function()
	local ok = pcall(function()
		ensureNPCScan()
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
					local character = currentTarget.Character
					local aimPart = character and getAimPart(character)
					if not character or not aimPart then
						currentTarget = nil
					else
						local headPos = camera:WorldToViewportPoint(aimPart.Position)
						local screenPos = Vector2.new(headPos.X, headPos.Y)
						local cursorDistance = (screenPos - Vector2.new(mouse.X, mouse.Y)).Magnitude
						if cursorDistance > aimFov or (wallCheck and checkWall(character)) or checkTeam(currentTarget) then
							currentTarget = nil
						end
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
			if espWasEnabled then
				hideAllESPDrawingObjects()
			end
			for _, obj in pairs(ESPData) do hideESPObj(obj) end
		else
			for target, obj in pairs(ESPData) do
				local ok2 = pcall(updateESP, target, obj)
				if not ok2 then
					hideESPObj(obj)
				end
			end
		end
		espWasEnabled = espEnabled
	end)
	if not ok then
		pcall(function() hideAllESPDrawingObjects() end)
		pcall(function() fovCircle.Visible = false end)
	end
end)

--> [< Aimbot UI >] <--

Aimbot:Divider({Text = "Main", Side = "Left"})

local aimbotToggle = Aimbot:Toggle({
    Name = "Aimbot", Side = "Left", Value = aimbotEnabled,
    Callback = function(Value)
        aimbotEnabled = Value
        fovCircle.Visible = Value and showFovCircle
		if not Value then
			aiming = false
			currentTarget = nil
		end
    end
})

Aimbot:Divider({Text = "Settings", Side = "Left"})

Aimbot:Slider({
    Name = "Smoothing", Side = "Left", Min = 0, Max = 100, Value = math.floor((1 - smoothing) * 100 + 0.5), Precise = 0, Unit = "",
    Callback = function(Value) smoothing = 1 - (Value / 100) end
})

Aimbot:Slider({
    Name = "Prediction Strength", Side = "Left", Min = 0, Max = 200, Value = math.floor(predictionStrength * 1000 + 0.5), Precise = 0, Unit = "",
    Callback = function(Value) predictionStrength = Value / 1000 end
})

local aimFovSlider = Aimbot:Slider({
    Name = "Aimbot Fov", Side = "Left", Min = 0, Max = 1000, Value = aimFov, Precise = 0, Unit = "",
    Callback = function(Value)
        aimFov = Value
        fovCircle.Radius = aimFov
    end
})

Aimbot:Divider({Text = "Filters", Side = "Left"})

local wallCheckToggle = Aimbot:Toggle({
    Name = "Wall Check", Side = "Left", Value = wallCheck,
    Callback = function(Value) wallCheck = Value end
})

Aimbot:Toggle({
	Name = "Include NPCs/Bots", Side = "Left", Value = aimbotIncludeNPCs,
	Callback = function(Value) aimbotIncludeNPCs = Value end
})

Aimbot:Toggle({
    Name = "Sticky Aim", Side = "Left", Value = stickyAimEnabled,
    Callback = function(Value) stickyAimEnabled = Value end
})

Aimbot:Toggle({
    Name = "Team Check (Experimental)", Side = "Left", Value = teamCheck,
    Callback = function(Value) teamCheck = Value end
})

Aimbot:Toggle({
    Name = "Health Check (Experimental)", Side = "Left", Value = healthCheck,
    Callback = function(Value) healthCheck = Value end
})

Aimbot:Slider({
    Name = "Min Health", Side = "Left", Min = 0, Max = 100, Value = minHealth, Precise = 0, Unit = "",
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
    Name = "Rainbow Fov", Side = "Left", Value = rainbowFov,
    Callback = function(Value) rainbowFov = Value end
})

--> [< ESP UI >] <--

ESP:Divider({Text = "Main", Side = "Left"})

local espToggle = ESP:Toggle({
    Name = "ESP", Side = "Left", Value = espEnabled,
	Callback = function(Value)
		espEnabled = Value
		if not Value then
			espWasEnabled = false
			hideAllESPDrawingObjects()
			for _, obj in pairs(ESPData) do hideESPObj(obj) end
		end
	end
})

ESP:Divider({Text = "Features", Side = "Left"})

ESP:Toggle({
    Name = "Box", Side = "Left", Value = espBox,
    Callback = function(Value) espBox = Value end
})

ESP:Toggle({
    Name = "Names", Side = "Left", Value = espNames,
    Callback = function(Value) espNames = Value end
})

ESP:Toggle({
    Name = "Health Bar", Side = "Left", Value = espHealth,
    Callback = function(Value) espHealth = Value end
})

ESP:Toggle({
    Name = "Distance", Side = "Left", Value = espDistance,
    Callback = function(Value) espDistance = Value end
})

ESP:Toggle({
    Name = "Tracers", Side = "Left", Value = espTracers,
    Callback = function(Value) espTracers = Value end
})

ESP:Toggle({
    Name = "Head Dot", Side = "Left", Value = espHeadDot,
    Callback = function(Value) espHeadDot = Value end
})

ESP:Divider({Text = "Filters", Side = "Left"})

ESP:Toggle({
    Name = "Team Check", Side = "Left", Value = espTeamCheck,
    Callback = function(Value) espTeamCheck = Value end
})

ESP:Toggle({
    Name = "Visibility Check", Side = "Left", Value = espVisCheck,
    Callback = function(Value) espVisCheck = Value end
})

ESP:Divider({Text = "Targets", Side = "Left"})

ESP:Toggle({
	Name = "Include NPCs/Bots", Side = "Left", Value = espIncludeNPCs,
	Callback = function(Value) espIncludeNPCs = Value end
})

ESP:Slider({
	Name = "NPC Scan Interval", Side = "Left", Min = 0.2, Max = 5, Value = npcScanInterval, Precise = 1, Unit = "s",
	Callback = function(Value) npcScanInterval = Value end
})

ESP:Slider({
	Name = "Max NPC Targets", Side = "Left", Min = 1, Max = 200, Value = npcMaxTargets, Precise = 0, Unit = "",
	Callback = function(Value) npcMaxTargets = Value end
})

ESP:Slider({
    Name = "Max Distance", Side = "Left", Min = 100, Max = 5000, Value = espMaxDist, Precise = 0, Unit = "",
    Callback = function(Value) espMaxDist = Value end
})

ESP:Slider({
    Name = "Text Size", Side = "Left", Min = 8, Max = 24, Value = espTextSize, Precise = 0, Unit = "",
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

Keybinds:Divider({Text = "Menu", Side = "Left"})

Keybinds:Keybind({
	Name = "Toggle GUI", Side = "Left", Value = "RightControl", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if pressed then
			if UserInputService:GetFocusedTextBox() then return end
			setUIVisible(not uiVisible)
		end
	end
})

Keybinds:Divider({Text = "Aimbot Activation", Side = "Left"})

Keybinds:Keybind({
	Name = "Aimbot Hold", Side = "Left", Value = "MouseButton2", Mouse = true,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if UserInputService:GetFocusedTextBox() then return end
		if not aimbotEnabled then
			aiming = false
			return
		end
		aiming = pressed and true or false
	end
})

Keybinds:Divider({Text = "Toggles", Side = "Left"})

Keybinds:Keybind({
	Name = "Toggle Aimbot", Side = "Left", Value = "NONE", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if pressed and aimbotToggle then
			if UserInputService:GetFocusedTextBox() then return end
			aimbotToggle:SetValue(not aimbotEnabled)
		end
	end
})

Keybinds:Keybind({
	Name = "Toggle ESP", Side = "Left", Value = "NONE", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if pressed and espToggle then
			if UserInputService:GetFocusedTextBox() then return end
			espToggle:SetValue(not espEnabled)
		end
	end
})

Keybinds:Keybind({
	Name = "Toggle Wall Check", Side = "Left", Value = "NONE", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if pressed and wallCheckToggle then
			if UserInputService:GetFocusedTextBox() then return end
			wallCheckToggle:SetValue(not wallCheck)
		end
	end
})

Keybinds:Keybind({
	Name = "Toggle FOV Circle", Side = "Left", Value = "NONE", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if pressed then
			if UserInputService:GetFocusedTextBox() then return end
			showFovCircle = not showFovCircle
			fovCircle.Visible = aimbotEnabled and showFovCircle
		end
	end
})

Keybinds:Divider({Text = "FOV", Side = "Left"})

Keybinds:Slider({
	Name = "FOV Step", Side = "Left", Min = 1, Max = 100, Value = 10, Precise = 0, Unit = "",
	Callback = function(Value) aimFovStep = Value end
})

Keybinds:Keybind({
	Name = "FOV +", Side = "Left", Value = "NONE", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if not pressed then return end
		if UserInputService:GetFocusedTextBox() then return end
		local newValue = math.clamp(aimFov + aimFovStep, 0, 1000)
		if aimFovSlider then
			aimFovSlider:SetValue(newValue)
		else
			aimFov = newValue
			fovCircle.Radius = aimFov
		end
	end
})

Keybinds:Keybind({
	Name = "FOV -", Side = "Left", Value = "NONE", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if not pressed then return end
		if UserInputService:GetFocusedTextBox() then return end
		local newValue = math.clamp(aimFov - aimFovStep, 0, 1000)
		if aimFovSlider then
			aimFovSlider:SetValue(newValue)
		else
			aimFov = newValue
			fovCircle.Radius = aimFov
		end
	end
})

Keybinds:Divider({Text = "Safety", Side = "Left"})

Keybinds:Keybind({
	Name = "Panic (Disable All + Hide GUI)", Side = "Left", Value = "NONE", Mouse = false,
	Blacklist = {"W","A","S","D","Slash","Tab","Backspace","Escape","Space","Delete","Unknown","Backquote"},
	Callback = function(_, pressed)
		if not pressed then return end
		if UserInputService:GetFocusedTextBox() then return end
		aiming = false
		currentTarget = nil
		if aimbotToggle then aimbotToggle:SetValue(false) end
		if espToggle then espToggle:SetValue(false) end
		showFovCircle = false
		fovCircle.Visible = false
		setUIVisible(false)
	end
})

--> [< Extras Command Logic >] <--

local function getChar()
	return plr.Character
end

local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function startFly()
	local c = getChar()
	if not c then return end
	local root = c:WaitForChild("HumanoidRootPart", 3)
	if not root then return end
	local hum = c:FindFirstChildOfClass("Humanoid")

	local gyro = Instance.new("BodyGyro")
	gyro.P = 9e4
	gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
	gyro.CFrame = workspace.CurrentCamera.CFrame
	gyro.Parent = root

	local velo = Instance.new("BodyVelocity")
	velo.Velocity = Vector3.zero
	velo.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	velo.Parent = root

	local flyDirs = {fwd=0, bwd=0, left=0, right=0, up=0, down=0}

	local ib = UserInputService.InputBegan:Connect(function(inp, proc)
		if proc then return end
		local k = inp.KeyCode
		if k == Enum.KeyCode.W then flyDirs.fwd = 1
		elseif k == Enum.KeyCode.S then flyDirs.bwd = -1
		elseif k == Enum.KeyCode.A then flyDirs.left = -1
		elseif k == Enum.KeyCode.D then flyDirs.right = 1
		elseif k == Enum.KeyCode.E then flyDirs.up = 1
		elseif k == Enum.KeyCode.Q then flyDirs.down = -1
		end
	end)
	local ie = UserInputService.InputEnded:Connect(function(inp, proc)
		if proc then return end
		local k = inp.KeyCode
		if k == Enum.KeyCode.W then flyDirs.fwd = 0
		elseif k == Enum.KeyCode.S then flyDirs.bwd = 0
		elseif k == Enum.KeyCode.A then flyDirs.left = 0
		elseif k == Enum.KeyCode.D then flyDirs.right = 0
		elseif k == Enum.KeyCode.E then flyDirs.up = 0
		elseif k == Enum.KeyCode.Q then flyDirs.down = 0
		end
	end)

	extrasConnections.fly = {gyro=gyro, velo=velo, ib=ib, ie=ie}

	task.spawn(function()
		while flyEnabled do
			task.wait()
			if not flyEnabled then break end
			local cam = workspace.CurrentCamera
			local fwd   = cam.CFrame.LookVector  * (flyDirs.fwd  + flyDirs.bwd)
			local right = cam.CFrame.RightVector  * (flyDirs.right + flyDirs.left)
			local up    = Vector3.new(0, flyDirs.up + flyDirs.down, 0)
			local moving = (fwd + right + up).Magnitude > 0
			velo.Velocity = (fwd + right + up) * (moving and flySpeed or 0)
			gyro.CFrame = cam.CFrame
			if hum then hum.PlatformStand = true end
		end
		pcall(function() gyro:Destroy() end)
		pcall(function() velo:Destroy() end)
		pcall(function() ib:Disconnect() end)
		pcall(function() ie:Disconnect() end)
		extrasConnections.fly = nil
		local h = getHum()
		if h then h.PlatformStand = false end
	end)
end

local function stopFly()
	flyEnabled = false
	if extrasConnections.fly then
		pcall(function() extrasConnections.fly.gyro:Destroy() end)
		pcall(function() extrasConnections.fly.velo:Destroy() end)
		pcall(function() extrasConnections.fly.ib:Disconnect() end)
		pcall(function() extrasConnections.fly.ie:Disconnect() end)
		extrasConnections.fly = nil
	end
	local h = getHum()
	if h then h.PlatformStand = false end
end

local function startNoclip()
	extrasConnections.noclip = RunService.Stepped:Connect(function()
		pcall(function()
			local c = getChar()
			if not c then return end
			for _, p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end)
	end)
end

local function stopNoclip()
	if extrasConnections.noclip then
		extrasConnections.noclip:Disconnect()
		extrasConnections.noclip = nil
	end
	pcall(function()
		local c = getChar()
		if not c then return end
		for _, p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = true end
		end
	end)
end

local function applyWalkSpeed()
	local h = getHum()
	if h then h.WalkSpeed = walkSpeed end
end

local function applyJumpPower()
	local h = getHum()
	if h then
		h.JumpPower = jumpPower
		h.UseJumpPower = true
	end
end

local function startInfJump()
	extrasConnections.infJump = UserInputService.JumpRequest:Connect(function()
		local h = getHum()
		if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
end

local function stopInfJump()
	if extrasConnections.infJump then
		extrasConnections.infJump:Disconnect()
		extrasConnections.infJump = nil
	end
end


plr.CharacterAdded:Connect(function()
	task.wait(0.5)
	if walkSpeed ~= 16 then applyWalkSpeed() end
	if jumpPower ~= 50 then applyJumpPower() end
	if noclipEnabled then
		stopNoclip()
		startNoclip()
	end
	if flyEnabled then
		stopFly()
		flyEnabled = true
		startFly()
	end
end)

--> [< Extras Tab UI >] <--

local flyToggle, noclipToggle, infJumpToggle
local walkSpeedSlider, jumpPowerSlider, flySpeedSlider

Extras:Divider({Text = "Movement", Side = "Left"})

flyToggle = Extras:Toggle({
	Name = "Fly", Side = "Left", Value = flyEnabled,
	Callback = function(Value)
		flyEnabled = Value
		if Value then
			startFly()
		else
			stopFly()
		end
	end
})

noclipToggle = Extras:Toggle({
	Name = "Noclip", Side = "Left", Value = noclipEnabled,
	Callback = function(Value)
		noclipEnabled = Value
		if Value then startNoclip() else stopNoclip() end
	end
})

flySpeedSlider = Extras:Slider({
	Name = "Fly Speed", Side = "Left", Min = 10, Max = 500, Value = flySpeed, Precise = 0, Unit = "",
	Callback = function(Value) flySpeed = Value end
})

walkSpeedSlider = Extras:Slider({
	Name = "Walk Speed", Side = "Left", Min = 8, Max = 500, Value = walkSpeed, Precise = 0, Unit = "",
	Callback = function(Value)
		walkSpeed = Value
		applyWalkSpeed()
	end
})

jumpPowerSlider = Extras:Slider({
	Name = "Jump Power", Side = "Left", Min = 7, Max = 500, Value = jumpPower, Precise = 0, Unit = "",
	Callback = function(Value)
		jumpPower = Value
		applyJumpPower()
	end
})

Extras:Divider({Text = "Character", Side = "Left"})

infJumpToggle = Extras:Toggle({
	Name = "Infinite Jump", Side = "Left", Value = infJumpEnabled,
	Callback = function(Value)
		infJumpEnabled = Value
		if Value then startInfJump() else stopInfJump() end
	end
})

Extras:Divider({Text = "Tools", Side = "Left"})

Extras:Button({
	Name = "Load Phantom CMD", Side = "Left",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/CMD%20Suite"))()
	end
})

--> [< Admin Tab >] <--

Admin:Divider({Text = "Config", Side = "Left"})

Admin:Label({Text = "HWID: " .. tostring(HWID):sub(1, 24) .. "...", Side = "Left"})

Admin:Button({
	Name = "Save Config", Side = "Left",
	Callback = function()
		local ok = saveConfig()
		Bracket:Notification({Title = "Phantom Suite", Description = ok and "Config saved!" or "Save failed (no file access)", Duration = 3})
	end
})

Admin:Button({
	Name = "Load Config", Side = "Left",
	Callback = function()
		local cfg = loadConfig()
		if not cfg then
			Bracket:Notification({Title = "Phantom Suite", Description = "No config found for this HWID.", Duration = 3})
			return
		end
		applyConfig(cfg)
		-- Aimbot
		if aimbotToggle    then aimbotToggle:SetValue(aimbotEnabled) end
		if wallCheckToggle then wallCheckToggle:SetValue(wallCheck) end
		-- ESP
		if espToggle       then espToggle:SetValue(espEnabled) end
		-- Extras
		if flyToggle       then flyToggle:SetValue(false) end
		if noclipToggle    then noclipToggle:SetValue(false) end
		if infJumpToggle   then infJumpToggle:SetValue(false) end
		if flySpeedSlider  then flySpeedSlider:SetValue(flySpeed) end
		if walkSpeedSlider then walkSpeedSlider:SetValue(walkSpeed) end
		if jumpPowerSlider then jumpPowerSlider:SetValue(jumpPower) end
		-- Apply speed/jump immediately
		applyWalkSpeed()
		applyJumpPower()
		Bracket:Notification({Title = "Phantom Suite", Description = "Config loaded!", Duration = 3})
	end
})

Admin:Divider({Text = "Admin Tools", Side = "Left"})

Admin:Button({
	Name = "Destroy UI (Stealth)", Side = "Left",
	Callback = function()
		destroyUI()
	end
})

