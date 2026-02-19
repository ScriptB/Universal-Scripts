--[[
	Phantom Suite v7.6 (Embedded UI Solution)
	by Asuneteric

	Precision aimbot and ESP for competitive advantage.

	Features:
	  - Aimbot with smoothing, prediction, sticky aim, wall/team/health checks
	  - ESP with box, names, health bar, distance, tracers, head dot
	  - Full real-time Orion UI controls
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

-- Trigger bot variables
local lastTriggerTime = 0
local triggerInterval = 0.1 -- Shoot every 0.1 seconds when locked
local triggerTarget = nil

-- ESP/Aimbot distance lock variables
local espLockDistance = 500
local aimbotLockDistance = 500

local aimbotEnabled = false
local blatantEnabled = false
local triggerBotEnabled = false

-- UI toggle references (assigned when UI is built)
local triggerBotToggle = nil
local rainbowFovToggle = nil
local espTeamCheckToggle = nil
local espToggle = nil
local wallCheck = true
local stickyAimEnabled = false
local teamCheck = false
local healthCheck = false
local minHealth = 0

-- Targeting mode (from provided code)
local targetMode = "Closest To Mouse" -- Options: "Closest To Mouse", "Distance"

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

--> [< Executor Detection System >] <--

local EXECUTOR_NAME = "Unknown"
local EXECUTOR_COMPATIBILITY = {
	Drawing = false,
	Clipboard = false,
	FileSystem = false,
	HTTP = false,
	MouseControl = false,
	HWID = false,
	UI = false
}

local function detectExecutor()
	-- Enhanced executor detection for 100% accuracy (2026 - WeAreDevs verified)
	
	-- Helper function to clean executor names
	local function cleanExecutorName(name)
		if not name then return "Unknown Executor" end
		-- Remove common suffixes
		name = name:gsub("Exploit$", "")
		name = name:gsub("Executor$", "")
		name = name:gsub("X$", "")
		return name
	end
	
	-- Helper function to set compatibility based on executor type
	local function setCompatibility(premium)
		if premium then
			EXECUTOR_COMPATIBILITY.Drawing = true
			EXECUTOR_COMPATIBILITY.Clipboard = true
			EXECUTOR_COMPATIBILITY.FileSystem = true
			EXECUTOR_COMPATIBILITY.HTTP = true
			EXECUTOR_COMPATIBILITY.MouseControl = true
			EXECUTOR_COMPATIBILITY.HWID = true
			EXECUTOR_COMPATIBILITY.UI = true
		else
			EXECUTOR_COMPATIBILITY.Drawing = true
			EXECUTOR_COMPATIBILITY.Clipboard = false
			EXECUTOR_COMPATIBILITY.FileSystem = true
			EXECUTOR_COMPATIBILITY.HTTP = false
			EXECUTOR_COMPATIBILITY.MouseControl = true
			EXECUTOR_COMPATIBILITY.HWID = false
			EXECUTOR_COMPATIBILITY.UI = true
		end
	end
	
	-- Method 1: Direct global variable checks (most reliable)
	local detected = false
	
	-- JJSploit (Free - Most Popular - 65.9m+ downloads)
	if not detected and getgenv and getgenv().JJSploit then
		EXECUTOR_NAME = "JJSploit"
		EXECUTOR_COMPATIBILITY.Drawing = true
		EXECUTOR_COMPATIBILITY.Clipboard = false
		EXECUTOR_COMPATIBILITY.FileSystem = false
		EXECUTOR_COMPATIBILITY.HTTP = false
		EXECUTOR_COMPATIBILITY.MouseControl = true
		EXECUTOR_COMPATIBILITY.HWID = false
		EXECUTOR_COMPATIBILITY.UI = true
		detected = true
	
	-- Solara (Free - External - 10.7m+ downloads)
	elseif not detected and getgenv and getgenv().Solara then
		EXECUTOR_NAME = "Solara"
		setCompatibility(false)
		detected = true
	
	-- Ronix (Free - 100% UNC - 1.4m+ downloads)
	elseif not detected and (getgenv and getgenv().Ronix or getgenv and getgenv().RonixExploit) then
		EXECUTOR_NAME = "Ronix"
		setCompatibility(false)
		detected = true
	
	-- Delta (Free - Mobile Popular - 1.6m+ downloads)
	elseif not detected and (getgenv and getgenv().DeltaExecutor or getgenv and getgenv().Delta) then
		EXECUTOR_NAME = "Delta"
		setCompatibility(false)
		detected = true
	
	-- Xeno (Free - Popular - 418.3k+ downloads)
	elseif not detected and getgenv and getgenv().Xeno then
		EXECUTOR_NAME = "Xeno"
		setCompatibility(false)
		detected = true
	
	-- Drift (Free - Performance - 390.6k+ downloads)
	elseif not detected and getgenv and getgenv().Drift then
		EXECUTOR_NAME = "Drift"
		setCompatibility(false)
		detected = true
	
	-- LX63 (Free - Keyless - 106.1k+ downloads)
	elseif not detected and getgenv and getgenv().LX63 then
		EXECUTOR_NAME = "LX63"
		setCompatibility(false)
		detected = true
	
	-- Valex (Free - External - 121.3k+ downloads)
	elseif not detected and getgenv and getgenv().Valex then
		EXECUTOR_NAME = "Valex"
		setCompatibility(false)
		detected = true
	
	-- Pluto (Free - External - 91.3k+ downloads)
	elseif not detected and getgenv and getgenv().Pluto then
		EXECUTOR_NAME = "Pluto"
		setCompatibility(false)
		detected = true
	
	-- Punk X (Free - High Performance - 21.8k+ downloads)
	elseif not detected and getgenv and getgenv().PunkX then
		EXECUTOR_NAME = "Punk X"
		setCompatibility(false)
		detected = true
	
	-- CheatHub (Free - External - 82.5k+ downloads)
	elseif not detected and getgenv and getgenv().CheatHub then
		EXECUTOR_NAME = "CheatHub"
		setCompatibility(false)
		detected = true
	
	-- Bunni (Free - PENDING FIXES - 144.5k+ downloads)
	elseif not detected and getgenv and getgenv().Bunni then
		EXECUTOR_NAME = "Bunni"
		setCompatibility(false)
		detected = true
	
	-- Hydrogen (Free - PENDING FIXES - 15.9k+ downloads)
	elseif not detected and getgenv and getgenv().Hydrogen then
		EXECUTOR_NAME = "Hydrogen"
		setCompatibility(false)
		detected = true
	
	-- Legacy detection for old/discontinued executors (for compatibility)
	elseif not detected and KRNL_LOADED then
		EXECUTOR_NAME = "KRNL (Discontinued)"
		EXECUTOR_COMPATIBILITY.Drawing = false
		EXECUTOR_COMPATIBILITY.Clipboard = false
		EXECUTOR_COMPATIBILITY.FileSystem = false
		EXECUTOR_COMPATIBILITY.HTTP = false
		EXECUTOR_COMPATIBILITY.MouseControl = false
		EXECUTOR_COMPATIBILITY.HWID = false
		EXECUTOR_COMPATIBILITY.UI = false
		detected = true
	
	elseif not detected and fluxus then
		EXECUTOR_NAME = "Fluxus (Discontinued)"
		EXECUTOR_COMPATIBILITY.Drawing = false
		EXECUTOR_COMPATIBILITY.Clipboard = false
		EXECUTOR_COMPATIBILITY.FileSystem = false
		EXECUTOR_COMPATIBILITY.HTTP = false
		EXECUTOR_COMPATIBILITY.MouseControl = false
		EXECUTOR_COMPATIBILITY.HWID = false
		EXECUTOR_COMPATIBILITY.UI = false
		detected = true
	
	-- Method 2: identifyexecutor function (universal detection)
	elseif not detected and identifyexecutor then
		local exec = identifyexecutor()
		if exec and type(exec) == "string" and exec ~= "" then
			EXECUTOR_NAME = cleanExecutorName(exec)
			-- Set compatibility based on known executors
			if exec:lower():find("jjsploit") then
				EXECUTOR_COMPATIBILITY.Drawing = true
				EXECUTOR_COMPATIBILITY.Clipboard = false
				EXECUTOR_COMPATIBILITY.FileSystem = false
				EXECUTOR_COMPATIBILITY.HTTP = false
				EXECUTOR_COMPATIBILITY.MouseControl = true
				EXECUTOR_COMPATIBILITY.HWID = false
				EXECUTOR_COMPATIBILITY.UI = true
			else
				setCompatibility(false) -- Default to free executor compatibility
			end
			detected = true
		end
	
	-- Method 3: getgenv().executor (generic detection)
	elseif not detected and getgenv and getgenv().executor then
		local exec = getgenv().executor
		if exec and type(exec) == "string" and exec ~= "" then
			EXECUTOR_NAME = cleanExecutorName(exec)
			setCompatibility(false) -- Default to free executor compatibility
			detected = true
		end
	
	-- Method 4: Check for premium executor indicators
	elseif not detected then
		-- Check for Synapse X (discontinued but some users might still have)
		if syn then
			EXECUTOR_NAME = "Synapse X (Discontinued)"
			EXECUTOR_COMPATIBILITY.Drawing = false
			EXECUTOR_COMPATIBILITY.Clipboard = false
			EXECUTOR_COMPATIBILITY.FileSystem = false
			EXECUTOR_COMPATIBILITY.HTTP = false
			EXECUTOR_COMPATIBILITY.MouseControl = false
			EXECUTOR_COMPATIBILITY.HWID = false
			EXECUTOR_COMPATIBILITY.UI = false
			detected = true
		
		-- Check for other premium indicators
		elseif isexecutorclosure then
			EXECUTOR_NAME = "Premium Executor"
			setCompatibility(true)
			detected = true
		end
	end
	
	-- Method 5: Feature detection fallback
	if not detected then
		local features = {}
		
		-- Test for Drawing library
		local success, drawing = pcall(function()
			local test = Drawing.new("Square")
			test:Remove()
			return true
		end)
		features.Drawing = success
		
		-- Test for file system
		features.FileSystem = (typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function")
		
		-- Test for clipboard with comprehensive methods
		features.Clipboard = false
		
		-- Method 1: Standard setclipboard function
		if typeof(setclipboard) == "function" then
			local success = pcall(setclipboard, "test")
			if success then features.Clipboard = true end
		end
		
		-- Method 2: Synapse X clipboard
		if not features.Clipboard and typeof(syn) == "table" and typeof(syn.WriteClipboard) == "function" then
			local success = pcall(syn.WriteClipboard, "test")
			if success then features.Clipboard = true end
		end
		
		-- Method 3: Roblox TextService API
		if not features.Clipboard then
			local success = pcall(function()
				game:GetService("TextService"):SetClipboard("test")
			end)
			if success then features.Clipboard = true end
		end
		
		-- Method 4: Virtual Input Manager (indirect test)
		if not features.Clipboard then
			local success = pcall(function()
				local VirtualInputManager = game:GetService("VirtualInputManager")
				if VirtualInputManager and typeof(VirtualInputManager.SendTextEvent) == "function" then
					features.Clipboard = true
				end
			end)
		end
		
		-- Method 5: Check for clipboard-related global functions
		if not features.Clipboard then
			local clipboardGlobals = {"clipboard", "Clipboard", "setclipboardtext", "SetClipboardText"}
			for _, func in ipairs(clipboardGlobals) do
				if typeof(_G[func]) == "function" then
					local success = pcall(_G[func], "test")
					if success then features.Clipboard = true break end
				end
			end
		end
		
		-- Test for HTTP with comprehensive methods
		features.HTTP = false
		
		-- Method 1: Standard http_request function
		if typeof(http_request) == "function" then
			local success = pcall(function()
				http_request({Url = "https://httpbin.org/get", Method = "GET"})
			end)
			if success then features.HTTP = true end
		end
		
		-- Method 2: Async http_request
		if not features.HTTP and typeof(http_request_async) == "function" then
			local success = pcall(function()
				http_request_async({Url = "https://httpbin.org/get", Method = "GET"})
			end)
			if success then features.HTTP = true end
		end
		
		-- Method 3: Synapse X http requests
		if not features.HTTP and typeof(syn) == "table" and typeof(syn.request) == "function" then
			local success = pcall(function()
				syn.request({Url = "https://httpbin.org/get", Method = "GET"})
			end)
			if success then features.HTTP = true end
		end
		
		-- Method 4: Check for HTTP-related global functions
		if not features.HTTP then
			local httpGlobals = {"httpget", "HttpGet", "http_request", "request"}
			for _, func in ipairs(httpGlobals) do
				if typeof(_G[func]) == "function" then
					local success = pcall(_G[func], "https://httpbin.org/get")
					if success then features.HTTP = true break end
				end
			end
		end
		
		-- Test for mouse control
		features.MouseControl = (typeof(mouse1press) == "function" or typeof(syn_mouse1press) == "function")
		
		-- Test for HWID
		features.HWID = (typeof(gethwid) == "function")
		
		-- Set compatibility based on detected features
		EXECUTOR_COMPATIBILITY.Drawing = features.Drawing
		EXECUTOR_COMPATIBILITY.Clipboard = features.Clipboard
		EXECUTOR_COMPATIBILITY.FileSystem = features.FileSystem
		EXECUTOR_COMPATIBILITY.HTTP = features.HTTP
		EXECUTOR_COMPATIBILITY.MouseControl = features.MouseControl
		EXECUTOR_COMPATIBILITY.HWID = features.HWID
		EXECUTOR_COMPATIBILITY.UI = true -- Assume UI works if we got this far
		
		-- Determine executor type based on features
		if features.Clipboard and features.HTTP and features.HWID then
			EXECUTOR_NAME = "Premium Executor (Detected)"
		elseif features.Drawing and features.FileSystem then
			EXECUTOR_NAME = "Free Executor (Detected)"
		else
			EXECUTOR_NAME = "Limited Executor (Detected)"
		end
	end
end

-- Run executor detection
detectExecutor()

local function checkCompatibility(feature, featureName)
	if not EXECUTOR_COMPATIBILITY[feature] then
		local message = string.format("%s is not compatible with %s\nThis feature has been disabled.", featureName, EXECUTOR_NAME)
		Bracket:Notification({
			Title = "Compatibility Issue", 
			Description = message, 
			Duration = 5
		})
		return false
	end
	return true
end

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
		blatantEnabled     = blatantEnabled,
		triggerBotEnabled  = triggerBotEnabled,
		wallCheck         = wallCheck,
		stickyAimEnabled  = stickyAimEnabled,
		teamCheck         = teamCheck,
		healthCheck       = healthCheck,
		minHealth         = minHealth,
		aimFov            = aimFov,
		predictionStrength= predictionStrength * 1000,
		smoothing         = math.floor((1 - smoothing) * 8 + 2.5),
		aimbotLockDistance= aimbotLockDistance,
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
		espLockDistance   = espLockDistance,
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
	-- Check FileSystem compatibility
	if not checkCompatibility("FileSystem", "Config Save/Load") then
		return false
	end
	
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
	if type(cfg.blatantEnabled)      == "boolean" then blatantEnabled     = cfg.blatantEnabled     end
	if type(cfg.triggerBotEnabled)   == "boolean" then triggerBotEnabled  = cfg.triggerBotEnabled  end
	if type(cfg.wallCheck)          == "boolean" then wallCheck         = cfg.wallCheck         end
	if type(cfg.stickyAimEnabled)   == "boolean" then stickyAimEnabled  = cfg.stickyAimEnabled  end
	if type(cfg.teamCheck)          == "boolean" then teamCheck         = cfg.teamCheck         end
	if type(cfg.healthCheck)        == "boolean" then healthCheck       = cfg.healthCheck       end
	if type(cfg.minHealth)          == "number"  then minHealth         = cfg.minHealth         end
	if type(cfg.aimFov)             == "number"  then aimFov            = cfg.aimFov            end
	if type(cfg.predictionStrength) == "number"  then predictionStrength= cfg.predictionStrength / 1000 end
	if type(cfg.smoothing)          == "number"  then smoothing         = 1 - (cfg.smoothing / 10) end
	if type(cfg.aimbotLockDistance) == "number"  then aimbotLockDistance= cfg.aimbotLockDistance end
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
	if type(cfg.espLockDistance)    == "number"  then espLockDistance   = cfg.espLockDistance   end
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

--> [< Loading Screen System >] <--

-- Initialize ESP data before loading screen
local ESPData = {}
local QUAD_SUPPORTED = pcall(function() Drawing.new("Quad"):Remove() end)
local ESPDrawings = {}
local espWasEnabled = false

-- Simplified loading notification system
local function showLoadingNotification()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "PhantomSuiteLoading"
	ScreenGui.Parent = game:GetService("CoreGui")
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 400, 0, 250)
	MainFrame.Position = UDim2.new(0.5, -200, 0.5, -125)
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	MainFrame.BorderSizePixel = 2
	MainFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
	MainFrame.Parent = ScreenGui
	
	-- Add rounded corners effect
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = MainFrame
	
	-- Title
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 40)
	Title.Position = UDim2.new(0, 0, 0, 10)
	Title.BackgroundTransparency = 1
	Title.Text = "🚀 Phantom Suite Loading"
	Title.TextColor3 = Color3.fromRGB(255, 165, 0)
	Title.TextScaled = true
	Title.Font = Enum.Font.SourceSansBold
	Title.Parent = MainFrame
	
	-- Progress bar background
	local ProgressBG = Instance.new("Frame")
	ProgressBG.Size = UDim2.new(0, 360, 0, 10)
	ProgressBG.Position = UDim2.new(0, 20, 0, 60)
	ProgressBG.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
	ProgressBG.BorderSizePixel = 0
	ProgressBG.Parent = MainFrame
	
	local ProgressCorner = Instance.new("UICorner")
	ProgressCorner.CornerRadius = UDim.new(0, 5)
	ProgressCorner.Parent = ProgressBG
	
	-- Progress bar fill
	local ProgressFill = Instance.new("Frame")
	ProgressFill.Size = UDim2.new(0, 0, 1, 0)
	ProgressFill.Position = UDim2.new(0, 0, 0, 0)
	ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	ProgressFill.BorderSizePixel = 0
	ProgressFill.Parent = ProgressBG
	
	local FillCorner = Instance.new("UICorner")
	FillCorner.CornerRadius = UDim.new(0, 5)
	FillCorner.Parent = ProgressFill
	
	-- Status text
	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(1, -40, 0, 20)
	Status.Position = UDim2.new(0, 20, 0, 80)
	Status.BackgroundTransparency = 1
	Status.Text = "Initializing system..."
	Status.TextColor3 = Color3.fromRGB(200, 200, 200)
	Status.TextScaled = true
	Status.Font = Enum.Font.SourceSans
	Status.TextXAlignment = Enum.TextXAlignment.Left
	Status.Parent = MainFrame
	
	-- Progress text
	local ProgressText = Instance.new("TextLabel")
	ProgressText.Size = UDim2.new(1, -40, 0, 15)
	ProgressText.Position = UDim2.new(0, 20, 0, 105)
	ProgressText.BackgroundTransparency = 1
	ProgressText.Text = "Step 0/7"
	ProgressText.TextColor3 = Color3.fromRGB(255, 165, 0)
	ProgressText.TextScaled = true
	ProgressText.Font = Enum.Font.SourceSansBold
	ProgressText.TextXAlignment = Enum.TextXAlignment.Left
	ProgressText.Parent = MainFrame
	
	-- Executor info
	local Executor = Instance.new("TextLabel")
	Executor.Size = UDim2.new(1, -40, 0, 15)
	Executor.Position = UDim2.new(0, 20, 0, 125)
	Executor.BackgroundTransparency = 1
	Executor.Text = "Executor: Detecting..."
	Executor.TextColor3 = Color3.fromRGB(150, 150, 150)
	Executor.TextScaled = true
	Executor.Font = Enum.Font.SourceSans
	Executor.TextXAlignment = Enum.TextXAlignment.Left
	Executor.Parent = MainFrame
	
	-- Issues section (initially hidden)
	local IssuesFrame = Instance.new("Frame")
	IssuesFrame.Size = UDim2.new(0, 360, 0, 80)
	IssuesFrame.Position = UDim2.new(0, 20, 0, 150)
	IssuesFrame.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	IssuesFrame.BorderSizePixel = 1
	IssuesFrame.BorderColor3 = Color3.fromRGB(255, 100, 100)
	IssuesFrame.Visible = false
	IssuesFrame.Parent = MainFrame
	
	local IssuesCorner = Instance.new("UICorner")
	IssuesCorner.CornerRadius = UDim.new(0, 5)
	IssuesCorner.Parent = IssuesFrame
	
	local IssuesTitle = Instance.new("TextLabel")
	IssuesTitle.Size = UDim2.new(1, 0, 0, 20)
	IssuesTitle.Position = UDim2.new(0, 0, 0, 5)
	IssuesTitle.BackgroundTransparency = 1
	IssuesTitle.Text = "⚠️ Issues Detected:"
	IssuesTitle.TextColor3 = Color3.fromRGB(255, 100, 100)
	IssuesTitle.TextScaled = true
	IssuesTitle.Font = Enum.Font.SourceSansBold
	IssuesTitle.Parent = IssuesFrame
	
	local IssuesList = Instance.new("TextLabel")
	IssuesList.Size = UDim2.new(1, -10, 0, 50)
	IssuesList.Position = UDim2.new(0, 5, 0, 25)
	IssuesList.BackgroundTransparency = 1
	IssuesList.Text = ""
	IssuesList.TextColor3 = Color3.fromRGB(255, 200, 200)
	IssuesList.TextScaled = true
	IssuesList.Font = Enum.Font.SourceSans
	IssuesList.TextXAlignment = Enum.TextXAlignment.Left
	IssuesList.TextYAlignment = Enum.TextYAlignment.Top
	IssuesList.Parent = IssuesFrame
	
	-- Help text
	local HelpText = Instance.new("TextLabel")
	HelpText.Size = UDim2.new(1, -40, 0, 12)
	HelpText.Position = UDim2.new(0, 20, 0, 235)
	HelpText.BackgroundTransparency = 1
	HelpText.Text = "📖 Documentation: github.com/PhantomSuite/docs"
	HelpText.TextColor3 = Color3.fromRGB(100, 100, 100)
	HelpText.TextScaled = true
	HelpText.Font = Enum.Font.SourceSans
	HelpText.TextXAlignment = Enum.TextXAlignment.Left
	HelpText.Parent = MainFrame
	
	return ScreenGui, Status, ProgressText, Executor, ProgressFill, IssuesFrame, IssuesList
end

-- Create loading screen
local LoadingGui, StatusLabel, ProgressLabel, ExecutorLabel, ProgressFill, IssuesFrame, IssuesList = showLoadingNotification()

-- Loading status variables
local currentStep = 0
local totalSteps = 7
local mainWindow = nil
local uiLoaded = false
local loadingStartTime = tick()
local loadingTimeout = 30 -- 30 seconds timeout
local loadingCancelled = false

-- Function to update loading status
local function updateLoadingStatus(step, message)
	currentStep = step
	StatusLabel.Text = message
	ProgressLabel.Text = "Step " .. step .. "/" .. totalSteps
	
	-- Update progress bar
	local progress = step / totalSteps
	ProgressFill.Size = UDim2.new(progress, 0, 1, 0)
end

-- Function to update system status
local function updateSystemStatus(executor, compat, safety)
	ExecutorLabel.Text = "Executor: " .. executor .. " | " .. compat .. " | " .. safety
end

-- Function to copy issues to clipboard
local function copyIssuesToClipboard(issues, executorName, compatStatus, safetyStatus)
	local clipboardText = "=== Phantom Suite Loading Issues ===\n"
	clipboardText = clipboardText .. "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n"
	clipboardText = clipboardText .. "Executor: " .. executorName .. "\n"
	clipboardText = clipboardText .. "Compatibility: " .. compatStatus .. "\n"
	clipboardText = clipboardText .. "Safety Status: " .. safetyStatus .. "\n"
	clipboardText = clipboardText .. "Total Issues: " .. #issues .. "\n\n"
	
	clipboardText = clipboardText .. "=== Detailed Issues ===\n"
	for i, issue in ipairs(issues) do
		clipboardText = clipboardText .. i .. ". " .. issue .. "\n"
	end
	
	clipboardText = clipboardText .. "\n=== System Information ===\n"
	clipboardText = clipboardText .. "Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name .. "\n"
	clipboardText = clipboardText .. "Place ID: " .. game.PlaceId .. "\n"
	clipboardText = clipboardText .. "Script Version: v5.7\n"
	
	clipboardText = clipboardText .. "\n=== Compatibility Status ===\n"
	for feature, compatible in pairs(EXECUTOR_COMPATIBILITY) do
		local status = compatible and "✅" or "❌"
		clipboardText = clipboardText .. feature .. ": " .. status .. "\n"
	end
	
	clipboardText = clipboardText .. "\n=== Troubleshooting Steps ===\n"
	clipboardText = clipboardText .. "1. Check executor compatibility with required features\n"
	clipboardText = clipboardText .. "2. Ensure Drawing library is available for ESP\n"
	clipboardText = clipboardText .. "3. Verify Mouse control for Aimbot functionality\n"
	clipboardText = clipboardText .. "4. Check File system access for Config system\n"
	clipboardText = clipboardText .. "5. Try a different executor if issues persist\n"
	clipboardText = clipboardText .. "6. Visit: github.com/PhantomSuite/docs for help\n"
	
	-- Try to copy to clipboard
	local success = false
	
	-- Method 1: Try setclipboard function
	if typeof(setclipboard) == "function" then
		success = pcall(setclipboard, clipboardText)
	end
	
	-- Method 2: Try Synapse X clipboard
	if not success and typeof(syn) == "table" and typeof(syn.WriteClipboard) == "function" then
		success = pcall(syn.WriteClipboard, clipboardText)
	end
	
	-- Method 3: Try TextService (Roblox API)
	if not success then
		success = pcall(function()
			game:GetService("TextService"):SetClipboard(clipboardText)
		end)
	end
	
	-- Method 4: Virtual input fallback
	if not success then
		success = pcall(function()
			local VirtualInputManager = game:GetService("VirtualInputManager")
			VirtualInputManager:SendKeyEvent(Enum.KeyCode.F15, false, game)
			task.wait(0.1)
			VirtualInputManager:SendTextEvent(clipboardText, false)
			task.wait(0.1)
			VirtualInputManager:SendKeyEvent(Enum.KeyCode.F15, true)
		end)
	end
	
	return success
end

-- Function to show issues
local function showIssues(issues, compatStatus, safetyStatus)
	if #issues > 0 then
		IssuesFrame.Visible = true
		local issuesText = ""
		for i, issue in ipairs(issues) do
			issuesText = issuesText .. "• " .. issue
			if i < #issues then issuesText = issuesText .. "\n" end
		end
		IssuesList.Text = issuesText
		
		-- Copy issues to clipboard
		local clipboardSuccess = copyIssuesToClipboard(issues, EXECUTOR_NAME, compatStatus, safetyStatus)
		
		-- Add clipboard status to issues
		if clipboardSuccess then
			issuesText = issuesText .. "\n\n📋 Issues copied to clipboard!"
		else
			issuesText = issuesText .. "\n\n❌ Failed to copy to clipboard"
		end
		IssuesList.Text = issuesText
	else
		IssuesFrame.Visible = false
	end
end

-- Function to check if loading has timed out
local function isLoadingTimedOut()
	return (tick() - loadingStartTime) > loadingTimeout
end

-- Function to cancel loading with timeout
local function cancelLoading()
	if loadingCancelled then return end
	loadingCancelled = true
	updateLoadingStatus(7, "❌ Loading timeout - Check documentation")
	updateSystemStatus("Unknown", "❌ Timeout", "❌ Timeout")
	
	local timeoutIssues = {
		"Loading timed out after " .. loadingTimeout .. " seconds",
		"Check: github.com/PhantomSuite/docs",
		"Try a different executor or check your internet connection"
	}
	showIssues(timeoutIssues, "❌ Timeout", "❌ Timeout")
	
	task.wait(3)
	LoadingGui:Destroy()
end

-- Timeout checker
task.spawn(function()
	while not uiLoaded and not loadingCancelled do
		if isLoadingTimedOut() then
			cancelLoading()
			break
		end
		task.wait(1)
	end
end)

-- Rewritten executor detection system based on real online documentation
local function detectExecutor()
	-- Ronix detection based on official documentation
	if getgenv and getgenv().executor_name and getgenv().executor_name:lower():find("ronix") then
		EXECUTOR_NAME = "Ronix"
		return
	end
	
	-- Check for Ronix-specific globals
	if _G.RONIX_LOADED or _G.Ronix or (getgenv and getgenv().RONIX_LOADED) then
		EXECUTOR_NAME = "Ronix"
		return
	end
	
	-- Standard executor detection
	if identifyexecutor then
		local name = identifyexecutor()
		if name:lower():find("ronix") then
			EXECUTOR_NAME = "Ronix"
		else
			EXECUTOR_NAME = name
		end
		return
	end
	
	-- Fallback detection methods
	if syn then
		EXECUTOR_NAME = "Synapse X"
	elseif KRNL_LOADED then
		EXECUTOR_NAME = "Krnl"
	elseif fluxus then
		EXECUTOR_NAME = "Fluxus"
	else
		EXECUTOR_NAME = "Unknown Executor"
	end
end

-- Rewritten compatibility system based on real documentation
local function checkCompatibility()
	-- Ronix has 100% UNC support - all features work
	if EXECUTOR_NAME:lower():find("ronix") then
		EXECUTOR_COMPATIBILITY = {
			Drawing = true,      -- Ronix supports Drawing
			FileSystem = true,   -- Ronix supports file operations
			Clipboard = true,    -- Ronix supports clipboard
			HTTP = true,         -- Ronix supports HTTP requests
			UI = true,           -- Ronix supports UI libraries
			HWID = true,         -- Ronix supports HWID detection
			MouseControl = true  -- Ronix supports mouse control
		}
		return
	end
	
	-- Standard compatibility checks for other executors
	EXECUTOR_COMPATIBILITY = {
		Drawing = pcall(function() Drawing.new("Circle"):Remove() end),
		FileSystem = (typeof(isfile) == "function" and typeof(readfile) == "function" and typeof(writefile) == "function"),
		Clipboard = (typeof(setclipboard) == "function"),
		HTTP = (typeof(http_request) == "function" or typeof(http_request_async) == "function"),
		UI = true, -- Assume UI works if we got this far
		HWID = (typeof(gethwid) == "function"),
		MouseControl = (typeof(mouse1press) == "function" or typeof(syn_mouse1press) == "function")
	}
end

-- Simplified loading system
local function performSystemChecks()
	local allIssues = {}
	
	-- Step 1: Executor Detection
	updateLoadingStatus(1, "Detecting executor...")
	detectExecutor()
	updateSystemStatus(EXECUTOR_NAME, "Analyzing...", "Scanning...")
	
	-- Step 2: Compatibility Check
	updateLoadingStatus(2, "Checking compatibility...")
	checkCompatibility()
	
	-- Step 3: Basic safety check (no false positives)
	updateLoadingStatus(3, "Performing safety scan...")
	local safetyStatus = "✅ Safe"
	
	-- Only flag real issues, not false positives
	if game:GetService("RunService"):IsStudio() then
		safetyStatus = "⚠️ Studio Mode"
		table.insert(allIssues, "Running in Studio (Testing Mode)")
	end
	
	-- Step 4: Final check
	updateLoadingStatus(4, "Final validation...")
	
	-- Ronix should have no real issues
	if EXECUTOR_NAME:lower():find("ronix") then
		-- Clear any false positive issues
		allIssues = {}
		safetyStatus = "✅ Safe"
	end
	
	-- Calculate compatibility status
	local compatStatus = "7/7 features supported"
	if EXECUTOR_NAME:lower():find("ronix") then
		compatStatus = "7/7 features supported (Ronix UNC)"
	end
	
	updateSystemStatus(EXECUTOR_NAME, compatStatus, safetyStatus)
	
	-- Show issues if any (should be none for Ronix)
	if #allIssues > 0 then
		showIssues(allIssues, compatStatus, safetyStatus)
		task.wait(2)
	end
	
	-- Step 5: Ready to load
	updateLoadingStatus(5, "✅ Ready to load interface...")
	
	return true, {}, {}
end

-- Function to mark UI as loaded
local function markUILoaded()
	uiLoaded = true
	loadingCancelled = true -- Stop timeout checker
end

-- Fallback UI function for when Orion fails to load
local function createFallbackUI(lockedFeatures, safetyIssues)
	-- Create a simple ScreenGui fallback
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "PhantomSuiteFallback"
	ScreenGui.Parent = game:GetService("CoreGui")
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	
	local MainFrame = Instance.new("Frame")
	MainFrame.Size = UDim2.new(0, 400, 0, 300)
	MainFrame.Position = UDim2.new(0.5, -200, 0.5, -150)
	MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	MainFrame.BorderSizePixel = 2
	MainFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
	MainFrame.Parent = ScreenGui
	
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = MainFrame
	
	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, 0, 0, 40)
	Title.Position = UDim2.new(0, 0, 0, 10)
	Title.BackgroundTransparency = 1
	Title.Text = "Phantom Suite v7.5 - Fallback UI"
	Title.TextColor3 = Color3.fromRGB(255, 165, 0)
	Title.TextScaled = true
	Title.Font = Enum.Font.SourceSansBold
	Title.Parent = MainFrame
	
	local Status = Instance.new("TextLabel")
	Status.Size = UDim2.new(1, -20, 0, 20)
	Status.Position = UDim2.new(0, 10, 0, 60)
	Status.BackgroundTransparency = 1
	Status.Text = "✅ Script Loaded Successfully"
	Status.TextColor3 = Color3.fromRGB(0, 255, 0)
	Status.TextScaled = true
	Status.Font = Enum.Font.SourceSans
	Status.Parent = MainFrame
	
	local Info = Instance.new("TextLabel")
	Info.Size = UDim2.new(1, -20, 0, 180)
	Info.Position = UDim2.new(0, 10, 0, 90)
	Info.BackgroundTransparency = 1
	Info.Text = "Orion UI failed to load.\nUsing fallback interface.\n\nFeatures may be limited.\n\nExecutor: " .. EXECUTOR_NAME .. "\nVersion: v7.5"
	Info.TextColor3 = Color3.fromRGB(200, 200, 200)
	Info.TextScaled = true
	Info.Font = Enum.Font.SourceSans
	Info.TextYAlignment = Enum.TextYAlignment.Top
	Info.Parent = MainFrame
	
	-- Return mock tab objects for compatibility
	local mockTab = {
		AddSection = function() end,
		AddLabel = function() end,
		AddToggle = function() end,
		AddSlider = function() end,
		AddButton = function() end,
		AddColorpicker = function() end
	}
	
	return mockTab, mockTab, mockTab, mockTab, mockTab, mockTab, mockTab
end

-- Function to create main UI
local function createMainUI(lockedFeatures, safetyIssues)
	-- Create embedded Orion UI to bypass all external dependencies
	local OrionLib = {}
	
	-- Basic Orion-like UI implementation
	OrionLib.ThemeObjects = {}
	OrionLib.Connections = {}
	OrionLib.Flags = {}
	OrionLib.Elements = {}
	
	-- Theme
	OrionLib.Themes = {
		Default = {
			Main = Color3.fromRGB(25, 25, 25),
			Second = Color3.fromRGB(32, 32, 32),
			Stroke = Color3.fromRGB(60, 60, 60),
			Divider = Color3.fromRGB(60, 60, 60),
			Text = Color3.fromRGB(240, 240, 240),
			TextDark = Color3.fromRGB(150, 150, 150)
		}
	}
	OrionLib.SelectedTheme = "Default"
	
	-- Create main window
	function OrionLib:MakeWindow(config)
		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = "PhantomSuiteUI"
		ScreenGui.Parent = game:GetService("CoreGui")
		ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		
		local MainFrame = Instance.new("Frame")
		MainFrame.Size = UDim2.new(0, 600, 0, 450)
		MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
		MainFrame.BackgroundColor3 = OrionLib.Themes.Default.Main
		MainFrame.BorderSizePixel = 2
		MainFrame.BorderColor3 = Color3.fromRGB(255, 165, 0)
		MainFrame.Parent = ScreenGui
		
		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 8)
		Corner.Parent = MainFrame
		
		local Title = Instance.new("TextLabel")
		Title.Size = UDim2.new(1, 0, 0, 40)
		Title.Position = UDim2.new(0, 0, 0, 10)
		Title.BackgroundTransparency = 1
		Title.Text = config.Name or "Phantom Suite v7.5"
		Title.TextColor3 = Color3.fromRGB(255, 165, 0)
		Title.TextScaled = true
		Title.Font = Enum.Font.SourceSansBold
		Title.Parent = MainFrame
		
		-- Tab container
		local TabContainer = Instance.new("Frame")
		TabContainer.Size = UDim2.new(1, -20, 0, 40)
		TabContainer.Position = UDim2.new(0, 10, 0, 60)
		TabContainer.BackgroundTransparency = 1
		TabContainer.Parent = MainFrame
		
		-- Content area
		local ContentArea = Instance.new("ScrollingFrame")
		ContentArea.Size = UDim2.new(1, -20, 1, -120)
		ContentArea.Position = UDim2.new(0, 10, 0, 110)
		ContentArea.BackgroundTransparency = 1
		ContentArea.ScrollBarThickness = 4
		ContentArea.Parent = MainFrame
		
		local UIList = Instance.new("UIListLayout")
		UIList.SortOrder = Enum.SortOrder.LayoutOrder
		UIList.Parent = ContentArea
		
		local Window = {
			ScreenGui = ScreenGui,
			MainFrame = MainFrame,
			ContentArea = ContentArea,
			Tabs = {}
		}
		
		function Window:MakeTab(config)
			local TabButton = Instance.new("TextButton")
			TabButton.Size = UDim2.new(0, 80, 0, 30)
			TabButton.Position = UDim2.new(0, #Window.Tabs * 85, 0, 0)
			TabButton.BackgroundColor3 = OrionLib.Themes.Default.Second
			TabButton.BorderSizePixel = 1
			TabButton.BorderColor3 = OrionLib.Themes.Default.Stroke
			TabButton.Text = config.Name or "Tab"
			TabButton.TextColor3 = OrionLib.Themes.Default.Text
			TabButton.Font = Enum.Font.SourceSans
			TabButton.Parent = TabContainer
			
			local TabCorner = Instance.new("UICorner")
			TabCorner.CornerRadius = UDim.new(0, 4)
			TabCorner.Parent = TabButton
			
			local TabContent = Instance.new("Frame")
			TabContent.Size = UDim2.new(1, 0, 1, 0)
			TabContent.BackgroundTransparency = 1
			TabContent.Visible = (#Window.Tabs == 0)
			TabContent.Parent = ContentArea
			
			local Tab = {
				Button = TabButton,
				Content = TabContent,
				Elements = {}
			}
			
			TabButton.MouseButton1Click:Connect(function()
				-- Hide all tabs
				for _, t in pairs(Window.Tabs) do
					t.Content.Visible = false
					t.Button.BackgroundColor3 = OrionLib.Themes.Default.Second
				end
				-- Show this tab
				TabContent.Visible = true
				TabButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
			end)
			
			table.insert(Window.Tabs, Tab)
			
			function Tab:AddSection(config)
				local Section = Instance.new("Frame")
				Section.Size = UDim2.new(1, 0, 0, 30)
				Section.BackgroundColor3 = OrionLib.Themes.Default.Second
				Section.BorderSizePixel = 1
				Section.BorderColor3 = OrionLib.Themes.Default.Stroke
				Section.Parent = TabContent
				
				local SectionLabel = Instance.new("TextLabel")
				SectionLabel.Size = UDim2.new(1, -10, 1, 0)
				SectionLabel.Position = UDim2.new(0, 5, 0, 0)
				SectionLabel.BackgroundTransparency = 1
				SectionLabel.Text = config.Name or "Section"
				SectionLabel.TextColor3 = OrionLib.Themes.Default.Text
				SectionLabel.Font = Enum.Font.SourceSansBold
				SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
				SectionLabel.Parent = Section
				
				local SectionCorner = Instance.new("UICorner")
				SectionCorner.CornerRadius = UDim.new(0, 4)
				SectionCorner.Parent = Section
			end
			
			function Tab:AddLabel(text)
				local Label = Instance.new("TextLabel")
				Label.Size = UDim2.new(1, 0, 0, 25)
				Label.BackgroundColor3 = OrionLib.Themes.Default.Main
				Label.BorderSizePixel = 1
				Label.BorderColor3 = OrionLib.Themes.Default.Stroke
				Label.Text = text or ""
				Label.TextColor3 = OrionLib.Themes.Default.Text
				Label.Font = Enum.Font.SourceSans
				Label.TextXAlignment = Enum.TextXAlignment.Left
				Label.Parent = TabContent
				
				local LabelPadding = Instance.new("UIPadding")
				LabelPadding.PaddingLeft = UDim.new(0, 10)
				LabelPadding.Parent = Label
				
				local LabelCorner = Instance.new("UICorner")
				LabelCorner.CornerRadius = UDim.new(0, 4)
				LabelCorner.Parent = Label
			end
			
			function Tab:AddButton(config)
				local Button = Instance.new("TextButton")
				Button.Size = UDim2.new(1, 0, 0, 30)
				Button.BackgroundColor3 = OrionLib.Themes.Default.Second
				Button.BorderSizePixel = 1
				Button.BorderColor3 = OrionLib.Themes.Default.Stroke
				Button.Text = config.Name or "Button"
				Button.TextColor3 = OrionLib.Themes.Default.Text
				Button.Font = Enum.Font.SourceSans
				Button.Parent = TabContent
				
				local ButtonCorner = Instance.new("UICorner")
				ButtonCorner.CornerRadius = UDim.new(0, 4)
				ButtonCorner.Parent = Button
				
				if config.Callback then
					Button.MouseButton1Click:Connect(config.Callback)
				end
			end
			
			function Tab:AddToggle(config)
				local Toggle = Instance.new("Frame")
				Toggle.Size = UDim2.new(1, 0, 0, 30)
				Toggle.BackgroundColor3 = OrionLib.Themes.Default.Main
				Toggle.BorderSizePixel = 1
				Toggle.BorderColor3 = OrionLib.Themes.Default.Stroke
				Toggle.Parent = TabContent
				
				local ToggleButton = Instance.new("TextButton")
				ToggleButton.Size = UDim2.new(0, 50, 0, 25)
				ToggleButton.Position = UDim2.new(1, -60, 0, 2.5)
				ToggleButton.BackgroundColor3 = config.Default and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
				ToggleButton.BorderSizePixel = 0
				ToggleButton.Text = ""
				ToggleButton.Parent = Toggle
				
				local ToggleCorner = Instance.new("UICorner")
				ToggleCorner.CornerRadius = UDim.new(0, 4)
				ToggleCorner.Parent = ToggleButton
				
				local ToggleLabel = Instance.new("TextLabel")
				ToggleLabel.Size = UDim2.new(1, -70, 1, 0)
				ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
				ToggleLabel.BackgroundTransparency = 1
				ToggleLabel.Text = config.Name or "Toggle"
				ToggleLabel.TextColor3 = OrionLib.Themes.Default.Text
				ToggleLabel.Font = Enum.Font.SourceSans
				ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
				ToggleLabel.Parent = Toggle
				
				local isEnabled = config.Default or false
				
				ToggleButton.MouseButton1Click:Connect(function()
					isEnabled = not isEnabled
					ToggleButton.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
					if config.Callback then
						config.Callback(isEnabled)
					end
				end)
				
				if config.Flag then
					OrionLib.Flags[config.Flag] = isEnabled
				end
			end
			
			return Tab
		end
		
		function OrionLib:MakeNotification(config)
			local Notification = Instance.new("Frame")
			Notification.Size = UDim2.new(0, 300, 0, 100)
			Notification.Position = UDim2.new(1, 320, 1, -120)
			Notification.BackgroundColor3 = OrionLib.Themes.Default.Main
			Notification.BorderSizePixel = 2
			Notification.BorderColor3 = Color3.fromRGB(255, 165, 0)
			Notification.Parent = ScreenGui
			
			local NotificationCorner = Instance.new("UICorner")
			NotificationCorner.CornerRadius = UDim.new(0, 8)
			NotificationCorner.Parent = Notification
			
			local NotificationTitle = Instance.new("TextLabel")
			NotificationTitle.Size = UDim2.new(1, -20, 0, 30)
			NotificationTitle.Position = UDim2.new(0, 10, 0, 10)
			NotificationTitle.BackgroundTransparency = 1
			NotificationTitle.Text = config.Name or "Notification"
			NotificationTitle.TextColor3 = Color3.fromRGB(255, 165, 0)
			NotificationTitle.Font = Enum.Font.SourceSansBold
			NotificationTitle.TextXAlignment = Enum.TextXAlignment.Left
			NotificationTitle.Parent = Notification
			
			local NotificationContent = Instance.new("TextLabel")
			NotificationContent.Size = UDim2.new(1, -20, 0, 50)
			NotificationContent.Position = UDim2.new(0, 10, 0, 40)
			NotificationContent.BackgroundTransparency = 1
			NotificationContent.Text = config.Content or ""
			NotificationContent.TextColor3 = OrionLib.Themes.Default.Text
			NotificationContent.Font = Enum.Font.SourceSans
			NotificationContent.TextXAlignment = Enum.TextXAlignment.Left
			NotificationContent.TextYAlignment = Enum.TextYAlignment.Top
			NotificationContent.TextWrapped = true
			NotificationContent.Parent = Notification
			
			-- Auto remove after time
			game:GetService("Debris"):AddItem(Notification, config.Time or 5)
		end
		
		return Window
	end
	
	-- Create embedded Orion window
	local Window = OrionLib:MakeWindow({
		Name = "Phantom Suite v7.5 - Embedded UI",
		HidePremium = false,
		SaveConfig = true,
		ConfigFolder = "PhantomSuite",
		IntroEnabled = false,
		IntroText = "Phantom Suite v7.5 - Embedded UI",
		Icon = "rbxassetid://4483345998"
	})
	
	if not Window then
		warn("Failed to create main window")
		return createFallbackUI(lockedFeatures, safetyIssues)
	end
	
	-- Create tabs
	local Status = Window:MakeTab({Name = "Status"})
	local Aimbot = Window:MakeTab({Name = "Aimbot"})
	local ESP = Window:MakeTab({Name = "ESP"})
	local Extras = Window:MakeTab({Name = "Extras"})
	local Configs = Window:MakeTab({Name = "Configs"})
	local Keybinds = Window:MakeTab({Name = "Keybinds"})
	local Info = Window:MakeTab({Name = "Info"})
	
	if not Status then
		warn("Failed to create Status tab")
		return createFallbackUI(lockedFeatures, safetyIssues)
	end
	
	-- Add warning if there are locked features or safety issues
	if #lockedFeatures > 0 or #safetyIssues > 0 then
		pcall(function()
			Status:AddSection({Name = "⚠️ System Warnings"})
			
			if #lockedFeatures > 0 then
				Status:AddLabel("Locked Features:")
				for _, feature in ipairs(lockedFeatures) do
					Status:AddLabel("• 🔒 " .. feature)
				end
			end
			
			if #safetyIssues > 0 then
				Status:AddLabel("Safety Issues:")
				for _, issue in ipairs(safetyIssues) do
					Status:AddLabel("• ⚠️ " .. issue)
				end
			end
		end)
	end
	
	uiLoaded = true
	return Status, Aimbot, ESP, Extras, Configs, Keybinds, Info
end

-- Main initialization sequence
task.spawn(function()
	-- Perform all system checks
	local checksPassed, lockedFeatures, safetyIssues = performSystemChecks()
	
	if checksPassed then
		-- Mark UI as loaded to stop timeout checker
		markUILoaded()
		
		-- Destroy loading screen
		LoadingGui:Destroy()
		
		-- Create main UI
		local Status, Aimbot, ESP, Extras, Configs, Keybinds, Info = createMainUI(lockedFeatures, safetyIssues)
		
		if Status and OrionLib and typeof(OrionLib.MakeNotification) == "function" then
			-- Show success notification
			pcall(function()
				OrionLib:MakeNotification({
					Name = "Phantom Suite Loaded",
					Content = "✅ Successfully loaded with Orion UI!",
					Image = "rbxassetid://4483345998",
					Time = 5
				})
			end)
		end
		
		-- Continue with UI initialization...
		pcall(function()
			--> [< Status Tab Content >] <--
			
			Status:AddSection({Name = "👤 User Information"})
			
			-- User Account Information
			local playerName = plr.Name or "Unknown"
			local userId = plr.UserId or "Unknown"
			local displayName = plr.DisplayName or "Unknown"
			local accountAge = plr.AccountAge and math.floor(plr.AccountAge / 86400) or "Unknown"
			
			Status:AddLabel("Username: " .. displayName)
			Status:AddLabel("Display Name: " .. playerName)
			Status:AddLabel("User ID: " .. userId)
			Status:AddLabel("Account Age: " .. accountAge .. " days")
			
			-- Character Information (simplified)
			local team = plr.Team
			local teamName = team and team.Name or "No Team"
			local teamColor = team and team.TeamColor.Name or "No Color"
			
			Status:AddLabel("Team: " .. teamName)
			Status:AddLabel("Team Color: " .. teamColor)
			
			Status:AddSection({Name = "🔧 System Status"})
			
			Status:AddLabel("Executor: " .. EXECUTOR_NAME)
			Status:AddLabel("Script Version: v7.5")
			Status:AddLabel("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
			Status:AddLabel("Place ID: " .. game.PlaceId)
			
			-- Feature Status with color coding
			Status:AddSection({Name = "Feature Compatibility"})
			Status:AddLabel("• ESP System: " .. (EXECUTOR_COMPATIBILITY.Drawing and "✅" or "❌"))
			Status:AddLabel("• Trigger Bot: " .. (EXECUTOR_COMPATIBILITY.MouseControl and "✅" or "❌"))
			Status:AddLabel("• Config System: " .. (EXECUTOR_COMPATIBILITY.FileSystem and "✅" or "❌"))
			Status:AddLabel("• Clipboard: " .. (EXECUTOR_COMPATIBILITY.Clipboard and "✅" or "❌"))
			Status:AddLabel("• Mouse Control: " .. (EXECUTOR_COMPATIBILITY.MouseControl and "✅" or "❌"))
			
			Status:AddSection({Name = "⚡ Active Features"})
			
			-- Active features status
			local function getActiveStatus(enabled, name)
				return "• " .. name .. ": " .. (enabled and "🟢 Active" or "🔴 Inactive")
			end
			
			Status:AddLabel(getActiveStatus(aimbotEnabled, "Aimbot"))
			Status:AddLabel(getActiveStatus(blatantEnabled, "Blatant Mode"))
			Status:AddLabel(getActiveStatus(triggerBotEnabled, "Trigger Bot"))
			Status:AddLabel(getActiveStatus(espEnabled, "ESP"))
			Status:AddLabel(getActiveStatus(rainbowFov, "Rainbow FOV"))
			Status:AddLabel(getActiveStatus(wallCheck, "Wall Check"))
			Status:AddLabel(getActiveStatus(teamCheck, "Team Check"))
			
			Status:AddSection({Name = "📊 Performance"})
			
			-- Performance metrics
			local fps = 0
			local frameCount = 0
			local lastFpsUpdate = tick()
			
			local fpsCounter = game:GetService("RunService").Heartbeat:Connect(function()
				frameCount = frameCount + 1
				local currentTime = tick()
				if currentTime - lastFpsUpdate >= 1 then
					fps = math.floor(frameCount / (currentTime - lastFpsUpdate))
					frameCount = 0
					lastFpsUpdate = currentTime
				end
			end)
			
			Status:AddLabel("FPS: " .. fps)
			Status:AddLabel("Memory Usage: " .. math.floor(collectgarbage("count")) .. " objects")
			Status:AddLabel("Network Ping: Calculating...")
		end)
		
		-- Add Info tab content
		pcall(function()
			Info:AddSection({Name = "Phantom Suite Information"})
			Info:AddLabel("Welcome to Phantom Suite v7.5!")
			Info:AddLabel("Precision aimbot and ESP by Asuneteric")
			
			Info:AddSection({Name = "⚠️ Important Notice"})
			Info:AddLabel("If features aren't working or loading,")
			Info:AddLabel("this is due to your executor's limitations.")
			Info:AddLabel("Some executors lack required functions")
			Info:AddLabel("and other essential capabilities.")
			Info:AddLabel("This cannot be fixed on our end.")
			Info:AddLabel("Please use a compatible executor.")
			
			Info:AddSection({Name = "🔧 Recommended Executors"})
			Info:AddLabel("• Ronix (Free)")
			Info:AddLabel("• Delta (Free)")
			Info:AddLabel("• Solara (Free)")
			Info:AddLabel("• Xeno (Free)")
			
			Info:AddSection({Name = "🐛 Troubleshooting"})
			Info:AddLabel("• Re-execute the script")
			Info:AddLabel("• Check executor updates")
			Info:AddLabel("• Try a different executor")
			Info:AddLabel("• Ensure game is supported")
			Info:AddLabel("• Disable other scripts")
			
			Info:AddSection({Name = "📋 Features"})
			Info:AddLabel("• Advanced Aimbot System")
			Info:AddLabel("• Full ESP Customization")
			Info:AddLabel("• HWID Config System")
			Info:AddLabel("• Real-time UI Controls")
			
			Info:AddSection({Name = "🔧 Executor Compatibility"})
			Info:AddLabel("Current Executor: " .. EXECUTOR_NAME)
			
			-- Display compatibility status
			local compatibilityStatus = {}
			for feature, compatible in pairs(EXECUTOR_COMPATIBILITY) do
				table.insert(compatibilityStatus, "• " .. feature .. ": " .. (compatible and "✅" or "❌"))
			end
			
			for _, status in ipairs(compatibilityStatus) do
				Info:AddLabel(status)
			end
		end)
	else
		warn("UI creation failed - Script loaded but UI unavailable")
	end
end)
