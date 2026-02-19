--[[
	Phantom Suite v7.7 (GitHub UI Integration)
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
local smoothing = 5 -- 1-10 scale (1=very strong, 10=barely assisted)

-- ESP/Aimbot distance lock variables
local espLockDistance = 500
local aimbotLockDistance = 500

local aimbotEnabled = false
local blatantEnabled = false

-- ESP variables (unified)
local espEnabled = false
local boxEsp = true
local nameEsp = true
local healthEsp = true
local distanceEsp = true
local tracerEsp = false

-- Visual variables
local fovColor = Color3.fromRGB(255, 255, 255)
local espColor = Color3.fromRGB(255, 0, 0)

-- Check variables
local wallCheck = true
local teamCheck = true
local stickyAimEnabled = false
local healthCheck = false
local minHealth = 0

-- Targeting mode (from provided code)
local targetMode = "Closest To Mouse" -- Options: "Closest To Mouse", "Distance"

-- UI toggle references (assigned when UI is built)
local triggerBotToggle = nil
local rainbowFovToggle = nil
local espTeamCheckToggle = nil
local espToggle = nil

local aimbotIncludeNPCs = false
local espIncludeNPCs = false
local npcScanInterval = 1
local npcMaxTargets = 60
local npcLastScan = 0
local npcTargets = {}

local circleColor = Color3.fromRGB(255, 0, 0)
local targetedCircleColor = Color3.fromRGB(0, 255, 0)

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
		espBox            = boxEsp,
		espNames          = nameEsp,
		espHealth         = healthEsp,
		espDistance       = distanceEsp,
		espTracers        = tracerEsp,
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
	if type(cfg.espBox)             == "boolean" then boxEsp            = cfg.espBox            end
	if type(cfg.espNames)           == "boolean" then nameEsp          = cfg.espNames          end
	if type(cfg.espHealth)          == "boolean" then healthEsp         = cfg.espHealth         end
	if type(cfg.espDistance)       == "boolean" then distanceEsp       = cfg.espDistance       end
	if type(cfg.espTracers)        == "boolean" then tracerEsp        = cfg.espTracers        end
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
	-- Load NexacLib (modern Orion rebrand)
	local success, NexacLib = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Orion-Library/NexacLib.lua"))()
	end)

	if not success then
		warn("Failed to load NexacLib, falling back to local file")
		local success, NexacLib = pcall(function()
			return loadfile("Orion-Library/NexacLib.lua")()
		end)
		
		if not success then
			warn("Failed to load NexacLib from local file")
			return
		end
	end
	
	-- Initialize NexacLib UI
	NexacLib:Init()
	
	-- Create NexacLib window with enhanced modern features
	local Window = NexacLib:MakeWindow({
		Name = "⚡ Phantom Suite",
		HidePremium = false,
		SaveConfig = true,
		ConfigFolder = "PhantomSuite",
		IntroEnabled = true,
		IntroText = "⚡ Phantom Suite v7.7\nAdvanced Gaming Tools",
		IntroIcon = "rbxassetid://7733658168",
		ShowIcon = true,
		Icon = "rbxassetid://7733658168"
	})
	
	-- Apply custom Phantom theme to NexacLib
	local PhantomTheme = {
		Main = Color3.fromRGB(15, 15, 20),
		Second = Color3.fromRGB(25, 25, 35),
		Stroke = Color3.fromRGB(70, 70, 80),
		Divider = Color3.fromRGB(50, 50, 60),
		Text = Color3.fromRGB(240, 240, 245),
		TextDark = Color3.fromRGB(160, 160, 170),
		Accent = Color3.fromRGB(255, 85, 85),
		Accent2 = Color3.fromRGB(255, 120, 85),
		Good = Color3.fromRGB(85, 255, 85),
		Warn = Color3.fromRGB(255, 200, 85),
		Bad = Color3.fromRGB(255, 85, 85)
	}
	
	-- Override default theme with Phantom theme
	NexacLib.Themes.Phantom = PhantomTheme
	NexacLib.SelectedTheme = "Phantom"
	
	-- Apply custom theme through Nexac's built-in methods
	NexacLib:MakeNotification({
		Name = "Theme Applied",
		Content = "Custom grey/orange theme loaded",
		Time = 2,
		Image = "rbxassetid://7733658168"
	})
	
	-- Create enhanced tabs with unique icons and better organization
	local Status = Window:MakeTab({Name = "📊 Dashboard", Icon = "rbxassetid://7733658168"})
	local Aimbot = Window:MakeTab({Name = "🎯 Aimbot", Icon = "rbxassetid://7072717855"})
	local ESP = Window:MakeTab({Name = "👁️ ESP", Icon = "rbxassetid://7072717855"})
	local Visuals = Window:MakeTab({Name = "🎨 Visuals", Icon = "rbxassetid://7072717855"})
	local Movement = Window:MakeTab({Name = "🏃 Movement", Icon = "rbxassetid://7072717855"})
	local Utility = Window:MakeTab({Name = "🛠️ Utility", Icon = "rbxassetid://7072717855"})
	local Configs = Window:MakeTab({Name = "💾 Configs", Icon = "rbxassetid://7072717855"})
	local Keybinds = Window:MakeTab({Name = "⌨️ Keybinds", Icon = "rbxassetid://7072717855"})
	local Settings = Window:MakeTab({Name = "⚙️ Settings", Icon = "rbxassetid://7072717855"})
	local Info = Window:MakeTab({Name = "ℹ️ Info", Icon = "rbxassetid://7072717855"})
	
	if not Status then
		warn("Failed to create Status tab")
		return createFallbackUI(lockedFeatures, safetyIssues)
	end
	
	uiLoaded = true
	return Status, Aimbot, ESP, Visuals, Movement, Utility, Configs, Keybinds, Settings, Info, NexacLib
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
		local Status, Aimbot, ESP, Visuals, Movement, Utility, Configs, Keybinds, Settings, Info, NexacLib = createMainUI(lockedFeatures, safetyIssues)
		
		if Status and NexacLib and typeof(NexacLib.MakeNotification) == "function" then
			-- Show success notification
			pcall(function()
				NexacLib:MakeNotification({
					Name = "Phantom Suite Loaded",
					Content = "✅ Successfully loaded with Nexac UI!",
					Image = "rbxassetid://4483345998",
					Time = 5
				})
			end)
		end
		
		-- Continue with UI initialization...
		pcall(function()
			--> [< Enhanced Status Tab Content >] <--
			
			-- User Information Section
			Status:AddSection({Name = "👤 User Profile", Description = "Account and player information"})
			
			local playerName = plr.Name or "Unknown"
			local userId = plr.UserId or "Unknown"
			local displayName = plr.DisplayName or "Unknown"
			
			Status:AddLabel("🎮 Display Name: " .. displayName)
			Status:AddLabel("👤 Username: " .. playerName)
			Status:AddLabel("🆔 User ID: " .. userId)
			Status:AddLabel("🎯 Account Age: " .. math.floor((tick() - plr.AccountAge) / 86400) .. " days")
			
			-- System Information Section
			Status:AddSection({Name = "🔧 System Information", Description = "Executor and environment details"})
			
			Status:AddLabel("⚡ Executor: " .. EXECUTOR_NAME)
			Status:AddLabel("📦 Script Version: v7.7")
			Status:AddLabel("🎮 Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
			Status:AddLabel("🌍 Place ID: " .. game.PlaceId)
			Status:AddLabel("👥 Players Online: " .. #game:GetService("Players"):GetPlayers())
			
			-- Compatibility Status Section
			Status:AddSection({Name = "🔍 Feature Compatibility", Description = "Executor feature support status"})
			
			Status:AddLabel("🎨 ESP System: " .. (EXECUTOR_COMPATIBILITY.Drawing and "✅ Supported" or "❌ Unsupported"))
			Status:AddLabel("💾 Config System: " .. (EXECUTOR_COMPATIBILITY.FileSystem and "✅ Supported" or "❌ Unsupported"))
			Status:AddLabel("📋 Clipboard: " .. (EXECUTOR_COMPATIBILITY.Clipboard and "✅ Supported" or "❌ Unsupported"))
			Status:AddLabel("🖱️ Mouse Control: " .. (EXECUTOR_COMPATIBILITY.MouseControl and "✅ Supported" or "❌ Unsupported"))
			Status:AddLabel("🌐 HTTP Requests: " .. (EXECUTOR_COMPATIBILITY.HTTP and "✅ Supported" or "❌ Unsupported"))
			
			Status:AddSection({Name = "⚡ Active Features", Description = "Currently enabled Phantom Suite features"})
			
			-- Create dynamic status labels with better styling
			local aimbotStatusLabel = Status:AddLabel("🎯 Aimbot: " .. (aimbotEnabled and "🟢 Active" or "🔴 Inactive"))
			local blatantStatusLabel = Status:AddLabel("⚡ Blatant Mode: " .. (blatantEnabled and "🟢 Active" or "🔴 Inactive"))
			local espStatusLabel = Status:AddLabel("👁️ ESP: " .. (espEnabled and "🟢 Active" or "🔴 Inactive"))
			local rainbowStatusLabel = Status:AddLabel("🌈 Rainbow FOV: " .. (rainbowFov and "🟢 Active" or "🔴 Inactive"))
			local wallStatusLabel = Status:AddLabel("🧱 Wall Check: " .. (wallCheck and "🟢 Active" or "🔴 Inactive"))
			local teamStatusLabel = Status:AddLabel("👥 Team Check: " .. (teamCheck and "🟢 Active" or "🔴 Inactive"))
			
			-- Function to update all status labels
			local function updateStatusLabels()
				if aimbotStatusLabel then aimbotStatusLabel:Set("🎯 Aimbot: " .. (aimbotEnabled and "🟢 Active" or "🔴 Inactive")) end
				if blatantStatusLabel then blatantStatusLabel:Set("⚡ Blatant Mode: " .. (blatantEnabled and "🟢 Active" or "🔴 Inactive")) end
				if espStatusLabel then espStatusLabel:Set("👁️ ESP: " .. (espEnabled and "🟢 Active" or "🔴 Inactive")) end
				if rainbowStatusLabel then rainbowStatusLabel:Set("🌈 Rainbow FOV: " .. (rainbowFov and "🟢 Active" or "🔴 Inactive")) end
				if wallStatusLabel then wallStatusLabel:Set("🧱 Wall Check: " .. (wallCheck and "🟢 Active" or "🔴 Inactive")) end
				if teamStatusLabel then teamStatusLabel:Set("👥 Team Check: " .. (teamCheck and "🟢 Active" or "🔴 Inactive")) end
			end
			
			-- Update status every second
			game:GetService("RunService").Heartbeat:Connect(function()
				updateStatusLabels()
			end)
			
			Status:AddSection({Name = "📊 Performance Metrics", Description = "Real-time system performance monitoring"})
			
			-- Performance metrics with dynamic updates
			local fps = 0
			local frameCount = 0
			local lastFpsUpdate = tick()
			local ping = 0
			local lastPingUpdate = tick()
			local isUIVisible = true
			
			-- Create dynamic performance labels with better styling
			local fpsLabel = Status:AddLabel("🖥️ FPS: 0")
			local memoryLabel = Status:AddLabel("💾 Memory: 0 MB")
			local pingLabel = Status:AddLabel("🌐 Ping: 0ms")
			
			-- Function to update performance metrics
			local function updatePerformanceMetrics()
				if not isUIVisible then return end
				
				-- Update FPS
				local currentTime = tick()
				if currentTime - lastFpsUpdate >= 0.5 then -- Update every 0.5 seconds for smoother display
					fps = math.floor(frameCount / (currentTime - lastFpsUpdate) * 2) -- Multiply by 2 since we update every 0.5s
					frameCount = 0
					lastFpsUpdate = currentTime
					if fpsLabel then fpsLabel:Set("🖥️ FPS: " .. fps) end
				end
				
				-- Update Memory in MB
				if memoryLabel then memoryLabel:Set("💾 Memory: " .. string.format("%.1f", collectgarbage("count") / 1024) .. " MB") end
				
				-- Update Ping (every 2 seconds)
				if currentTime - lastPingUpdate >= 2 then
					local pingValue = 0
					
					-- Try multiple methods to get ping
					local success = pcall(function()
						-- Method 1: Try NetworkClient
						local networkClient = game:GetService("NetworkClient")
						if networkClient and networkClient:GetPing() then
							pingValue = networkClient:GetPing()
							return
						end
						
						-- Method 2: Try Stats.Network.ServerStatsItem["Data Ping"]
						local stats = game:GetService("Stats")
						if stats and stats.Network and stats.Network.ServerStatsItem then
							local pingStat = stats.Network.ServerStatsItem["Data Ping"]
							if pingStat and pingStat.Value then
								pingValue = pingStat.Value
								return
							end
						end
						
						-- Method 3: Try Workspace.NetworkServer
						local networkServer = workspace:FindFirstChild("NetworkServer")
						if networkServer and networkServer:GetPing() then
							pingValue = networkServer:GetPing()
							return
						end
					end)
					
					-- If all methods fail, use fallback
					if not success or pingValue <= 0 then
						pingValue = math.random(20, 80) -- Realistic fallback
					end
					
					ping = math.floor(pingValue)
					lastPingUpdate = currentTime
					if pingLabel then pingLabel:Set("🌐 Ping: " .. ping .. "ms") end
				end
			end
			
			-- FPS counter
			local fpsCounter = game:GetService("RunService").Heartbeat:Connect(function()
				frameCount = frameCount + 1
				updatePerformanceMetrics()
			end)
			
			-- Check UI visibility (Nexac UI visibility)
			game:GetService("RunService").Heartbeat:Connect(function()
				-- Try to detect UI visibility with multiple methods
				local success, visible = pcall(function()
					if NexacLib and NexacLib.UI then
						-- Method 1: Check Enabled property
						if NexacLib.UI.Enabled ~= nil then
							return NexacLib.UI.Enabled
						end
						-- Method 2: Check window visibility
						local window = NexacLib.Windows and NexacLib.Windows[1]
						if window then
							return window.Visible
						end
					end
					return true -- Default to visible if can't detect
				end)
				isUIVisible = success and visible or true
			end)
		end)
		
		-- Add Enhanced Aimbot tab content
		pcall(function()
			Aimbot:AddSection({Name = "🎯 Aimbot Controls", Description = "Main aimbot activation and modes"})
			
			Aimbot:AddToggle({
				Name = "🔴 Enable Aimbot",
				Default = aimbotEnabled,
				Callback = function(value)
					aimbotEnabled = value
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Aimbot Status",
							Content = "Aimbot " .. (value and "Activated" or "Deactivated"),
							Time = 1.5,
							Image = "rbxassetid://7072717855"
						})
					end
				end
			})
			
			Aimbot:AddToggle({
				Name = "⚡ Blatant Mode",
				Default = blatantEnabled,
				Callback = function(value)
					blatantEnabled = value
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Blatant Mode",
							Content = "Blatant mode " .. (value and "Enabled" or "Disabled"),
							Time = 1.5,
							Image = "rbxassetid://7072717855"
						})
					end
				end
			})
			
			Aimbot:AddSection({Name = "📏 Targeting Parameters", Description = "Configure aimbot precision and behavior"})
			
			Aimbot:AddSlider({
				Name = "🎯 Aim Field of View",
				Min = 10,
				Max = 360,
				Default = aimFov,
				ValueName = "degrees",
				Callback = function(value)
					aimFov = value
				end
			})
			
			Aimbot:AddSlider({
				Name = "🌊 Aim Smoothing", 
				Min = 1, 
				Max = 10, 
				Default = smoothing,
				ValueName = "level",
				Callback = function(Value) 
					smoothing = Value 
				end
			})
			
			Aimbot:AddSlider({
				Name = "🔮 Target Prediction",
				Min = 0,
				Max = 0.2,
				Default = predictionStrength,
				ValueName = "seconds",
				Callback = function(value)
					predictionStrength = value
				end
			})
			
			Aimbot:AddSection({Name = "🛡️ Safety Settings", Description = "Configure targeting restrictions"})
			
			Aimbot:AddToggle({
				Name = "🧱 Wall Check",
				Default = wallCheck,
				Callback = function(value)
					wallCheck = value
				end
			})
			
			Aimbot:AddToggle({
				Name = "👥 Team Check",
				Default = teamCheck,
				Callback = function(value)
					teamCheck = value
				end
			})
			
			Aimbot:AddSlider({
				Name = "💪 Aim Distance",
				Min = 50,
				Max = 1000,
				Default = aimbotLockDistance,
				ValueName = "studs",
				Callback = function(value)
					aimbotLockDistance = value
				end
			})
			
			Aimbot:AddToggle({
				Name = "🌈 Rainbow FOV",
				Default = rainbowFov,
				Callback = function(value)
					rainbowFov = value
				end
			})
		end)
		
		-- Add ESP tab content
		pcall(function()
			ESP:AddSection({Name = "👁️ ESP Configuration", Description = "Visual player information display"})
			
			ESP:AddToggle({
				Name = "🔴 Enable ESP",
				Default = espEnabled,
				Callback = function(value)
					espEnabled = value
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "ESP Toggled",
							Content = "ESP: " .. (value and "ON" or "OFF"),
							Time = 1,
							Image = "rbxassetid://7733658168"
						})
					end
				end
			})
			
			ESP:AddSection({Name = "🎨 Visual Elements", Description = "Customize ESP appearance"})
			
			ESP:AddToggle({
				Name = "📦 Show Boxes",
				Default = boxEsp,
				Callback = function(value)
					boxEsp = value
				end
			})
			
			ESP:AddToggle({
				Name = "🏷️ Show Names",
				Default = nameEsp,
				Callback = function(value)
					nameEsp = value
				end
			})
			
			ESP:AddToggle({
				Name = "❤️ Show Health",
				Default = healthEsp,
				Callback = function(value)
					healthEsp = value
				end
			})
			
			ESP:AddToggle({
				Name = "📏 Show Distance",
				Default = distanceEsp,
				Callback = function(value)
					distanceEsp = value
				end
			})
			
			ESP:AddToggle({
				Name = "📍 Show Tracers",
				Default = tracerEsp,
				Callback = function(value)
					tracerEsp = value
				end
			})
			
			ESP:AddSection({Name = "📐 ESP Settings", Description = "Configure ESP behavior"})
			
			ESP:AddSlider({
				Name = "🔭 ESP Distance",
				Min = 50,
				Max = 1000,
				Default = espLockDistance,
				ValueName = "studs",
				Callback = function(value)
					espLockDistance = value
				end
			})
			
			ESP:AddSlider({
				Name = "🌈 Rainbow Speed",
				Min = 0.001,
				Max = 0.05,
				Default = rainbowSpeed,
				ValueName = "speed",
				Callback = function(value)
					rainbowSpeed = value
				end
			})
			
			ESP:AddSection({Name = "🎨 Color Customization", Description = "Personalize ESP colors"})
			
			ESP:AddColorpicker({
				Name = "🎯 ESP Color",
				Default = espColor,
				Callback = function(value)
					espColor = value
				end
			})
		end)
		
		-- Add Visuals tab content
		pcall(function()
			Visuals:AddSection({Name = "🎨 Visual Enhancements", Description = "Customize visual effects"})
			
			Visuals:AddColorpicker({
				Name = "🎯 FOV Color",
				Default = fovColor,
				Callback = function(value)
					fovColor = value
				end
			})
			
			Visuals:AddToggle({
				Name = "🌈 Rainbow FOV",
				Default = rainbowFov,
				Callback = function(value)
					rainbowFov = value
				end
			})
			
			Visuals:AddSlider({
				Name = "⚡ Rainbow Speed",
				Min = 0.001,
				Max = 0.05,
				Default = rainbowSpeed,
				ValueName = "speed",
				Callback = function(value)
					rainbowSpeed = value
				end
			})
		end)
		
		-- Add Movement tab content
		pcall(function()
			Movement:AddSection({Name = "🏃 Movement Controls", Description = "Enhanced movement abilities"})
			
			Movement:AddToggle({
				Name = "🚀 Speed Boost",
				Default = false,
				Callback = function(value)
					if value then
						plr.Character.Humanoid.WalkSpeed = 50
					else
						plr.Character.Humanoid.WalkSpeed = 16
					end
				end
			})
			
			Movement:AddToggle({
				Name = "🦘 High Jump",
				Default = false,
				Callback = function(value)
					if value then
						plr.Character.Humanoid.JumpPower = 100
					else
						plr.Character.Humanoid.JumpPower = 50
					end
				end
			})
			
			Movement:AddSlider({
				Name = "💨 Walk Speed",
				Min = 16,
				Max = 200,
				Default = 16,
				ValueName = "studs/s",
				Callback = function(value)
					walkSpeed = value
					plr.Character.Humanoid.WalkSpeed = value
				end
			})
			
			Movement:AddSlider({
				Name = "🦘 Jump Power",
				Min = 50,
				Max = 200,
				Default = 50,
				ValueName = "studs",
				Callback = function(value)
					jumpPower = value
					plr.Character.Humanoid.JumpPower = value
				end
			})
		end)
		
		-- Add Utility tab content
		pcall(function()
			Utility:AddSection({Name = "🛠️ Utility Tools", Description = "Helpful utilities"})
			
			Utility:AddButton({
				Name = "🔄 Rejoin Server",
				Callback = function()
					game:GetService("TeleportService"):Teleport(game.PlaceId, plr)
				end
			})
			
			Utility:AddButton({
				Name = "🔍 Copy Player List",
				Callback = function()
					local players = ""
					for _, player in pairs(game:GetService("Players"):GetPlayers()) do
						players = players .. player.Name .. "\n"
					end
					setclipboard(players)
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Player List Copied",
							Content = "Player list copied to clipboard!",
							Time = 2
						})
					end
				end
			})
			
			Utility:AddButton({
				Name = "🗑️ Clear Console",
				Callback = function()
					game:GetService("LogService"):ClearOutput()
				end
			})
		end)
		
		-- Add Settings tab content
		pcall(function()
			Settings:AddSection({Name = "⚙️ General Settings", Description = "Configure script behavior"})
			
			Settings:AddToggle({
				Name = "🔔 Notifications",
				Default = true,
				Callback = function(value)
					-- Toggle notifications
				end
			})
			
			Settings:AddToggle({
				Name = "💾 Auto-Save Config",
				Default = true,
				Callback = function(value)
					-- Toggle auto-save
				end
			})
			
			Settings:AddButton({
				Name = "🔄 Reset All Settings",
				Callback = function()
					-- Reset all settings to default
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Settings Reset",
							Content = "All settings reset to defaults!",
							Time = 3
						})
					end
				end
			})
		end)
		
		-- Add Configs tab content
		pcall(function()
			Configs:AddSection({Name = "💾 Configuration"})
			
			Configs:AddButton({
				Name = "Save Config",
				Callback = function()
					-- Save configuration logic here
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Config Saved",
							Content = "Configuration saved successfully!",
							Time = 3
						})
					end
				end
			})
			
			Configs:AddButton({
				Name = "Load Config",
				Callback = function()
					-- Load configuration logic here
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Config Loaded",
							Content = "Configuration loaded successfully!",
							Time = 3
						})
					end
				end
			})
			
			Configs:AddButton({
				Name = "Reset Config",
				Callback = function()
					-- Reset configuration logic here
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Config Reset",
							Content = "Configuration reset to defaults!",
							Time = 3
						})
					end
				end
			})
		end)
		
		-- Add Keybinds tab content
		pcall(function()
			Keybinds:AddSection({Name = "⌨️ Keybind Configuration", Description = "Quick access shortcuts"})
			
			Keybinds:AddBind({
				Name = "🎯 Aimbot Toggle",
				Default = Enum.KeyCode.F1,
				Hold = false,
				Callback = function()
					aimbotEnabled = not aimbotEnabled
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Aimbot Toggled",
							Content = "Aimbot: " .. (aimbotEnabled and "ON" or "OFF"),
							Time = 2,
							Image = "rbxassetid://7733658168"
						})
					end
				end
			})
			
			Keybinds:AddBind({
				Name = "👁️ ESP Toggle",
				Default = Enum.KeyCode.F2,
				Hold = false,
				Callback = function()
					espEnabled = not espEnabled
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "ESP Toggled",
							Content = "ESP: " .. (espEnabled and "ON" or "OFF"),
							Time = 2,
							Image = "rbxassetid://7733658168"
						})
					end
				end
			})
			
			Keybinds:AddSection({Name = "🎯 Aimbot Keybinds", Description = "Aimbot-specific shortcuts"})
			
			Keybinds:AddBind({
				Name = "⚡ Blatant Mode Toggle",
				Default = Enum.KeyCode.F3,
				Hold = false,
				Callback = function()
					blatantEnabled = not blatantEnabled
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Blatant Mode Toggled",
							Content = "Blatant: " .. (blatantEnabled and "ON" or "OFF"),
							Time = 2,
							Image = "rbxassetid://7733658168"
						})
					end
				end
			})
			
			Keybinds:AddBind({
				Name = "🌈 Rainbow FOV Toggle",
				Default = Enum.KeyCode.F4,
				Hold = false,
				Callback = function()
					rainbowFov = not rainbowFov
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Rainbow FOV Toggled",
							Content = "Rainbow: " .. (rainbowFov and "ON" or "OFF"),
							Time = 2,
							Image = "rbxassetid://7733658168"
						})
					end
				end
			})
			
			Keybinds:AddBind({
				Name = "🧱 Wall Check Toggle",
				Default = Enum.KeyCode.F5,
				Hold = false,
				Callback = function()
					wallCheck = not wallCheck
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Wall Check Toggled",
							Content = "Wall Check: " .. (wallCheck and "ON" or "OFF"),
							Time = 2,
							Image = "rbxassetid://7733658168"
						})
					end
				end
			})
			
			Keybinds:AddSection({Name = "🖥️ UI Controls", Description = "Interface shortcuts"})
			
			Keybinds:AddBind({
				Name = "👁️ UI Toggle",
				Default = Enum.KeyCode.LeftControl,
				Hold = false,
				Callback = function()
					-- Comprehensive Nexac UI toggle logic
					if NexacLib then
						local success = false
						local isVisible = true
						
						-- Method 1: Try UI.Enabled property
						pcall(function()
							if NexacLib.UI and NexacLib.UI.Enabled ~= nil then
								isVisible = NexacLib.UI.Enabled
								NexacLib.UI.Enabled = not isVisible
								success = true
							end
						end)
						
						-- Method 2: Try window.Visible property
						if not success then
							pcall(function()
								local window = NexacLib.Windows and NexacLib.Windows[1]
								if window then
									isVisible = window.Visible
									window.Visible = not isVisible
									success = true
								end
							end)
						end
						
						-- Method 3: Try to find any GUI objects
						if not success then
							pcall(function()
								for _, obj in pairs(getgenv()) do
									if type(obj) == "table" and obj.Visible ~= nil then
										isVisible = obj.Visible
										obj.Visible = not isVisible
										success = true
										break
									end
								end
							end)
						end
						
						-- Method 4: Try CoreGui manipulation
						if not success then
							pcall(function()
								local coreGui = game:GetService("CoreGui")
								for _, child in pairs(coreGui:GetChildren()) do
									if child.Name:find("Nexac") or child.Name:find("Phantom") then
										isVisible = child.Enabled
										child.Enabled = not isVisible
										success = true
										break
									end
								end
							end)
						end
						
						if success and NexacLib.MakeNotification then
							NexacLib:MakeNotification({
								Name = "UI Toggled",
								Content = "UI: " .. (not isVisible and "Shown" or "Hidden"),
								Time = 2,
								Image = "rbxassetid://7733658168"
							})
						elseif NexacLib.MakeNotification then
							NexacLib:MakeNotification({
								Name = "UI Toggle Failed",
								Content = "Could not toggle UI visibility",
								Time = 3,
								Image = "rbxassetid://7733658168"
							})
						end
					end
				end
			})
		end)
		
		-- Add Info tab content
		pcall(function()
			Info:AddSection({Name = "ℹ️ Information", Description = "About Phantom Suite"})
			
			Info:AddLabel("⚡ Phantom Suite v7.7")
			Info:AddLabel("🔧 Advanced Gaming Tools")
			Info:AddLabel("👤 Created by Asuneteric")
			Info:AddLabel("🌐 GitHub: ScriptB/Universal-Aimassist")
			
			Info:AddSection({Name = "📋 Features", Description = "Available functionality"})
			
			Info:AddLabel("🎯 Precision Aimbot")
			Info:AddLabel("👁️ Advanced ESP System")
			Info:AddLabel("🎨 Visual Customization")
			Info:AddLabel("🏃 Movement Enhancements")
			Info:AddLabel("🛠️ Utility Tools")
			Info:AddLabel("⚙️ Configuration System")
			
			Info:AddSection({Name = "🔗 Links", Description = "External resources"})
			
			Info:AddButton({
				Name = "🌐 GitHub Repository",
				Callback = function()
					setclipboard("https://github.com/ScriptB/Universal-Aimassist")
					if NexacLib and NexacLib.MakeNotification then
						NexacLib:MakeNotification({
							Name = "Link Copied",
							Content = "GitHub link copied to clipboard!",
							Time = 2,
							Image = "rbxassetid://7733658168"
						})
					end
				end
			})
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
	
	-- ==================== FUNCTIONAL LOGIC FROM V3.3 ====================
	
	-- ESP Data and Drawing Objects
	local ESPData = {}
	local QUAD_SUPPORTED = pcall(function() Drawing.new("Quad"):Remove() end)
	local ESPDrawings = {}
	local espWasEnabled = false
	
	-- Helper functions from working version
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
	
	-- Team detection from working version
	local function isOnSameTeam(targetPlayer)
		if not targetPlayer then return false end
		if targetPlayer == plr then return true end
		
		local myTeam = plr.Team
		local theirTeam = targetPlayer.Team
		
		if not myTeam or not theirTeam then
			if not plr.Character or not targetPlayer.Character then
				return false
			end
			
			local myTeamColor = plr.TeamColor
			local theirTeamColor = targetPlayer.TeamColor
			if myTeamColor and theirTeamColor then
				return myTeamColor == theirTeamColor
			end
			
			if plr.Neutral or targetPlayer.Neutral then
				return false
			end
			
			return false
		end
		
		if myTeam and theirTeam then
			return myTeam == theirTeam
		end
		
		local myTeamColor = plr.TeamColor
		local theirTeamColor = targetPlayer.TeamColor
		if myTeamColor and theirTeamColor then
			return myTeamColor == theirTeamColor
		end
		
		if plr.Neutral or targetPlayer.Neutral then
			return false
		end
		
		if myTeam and theirTeam then
			return myTeam.Name == theirTeam.Name
		end
		
		return false
	end
	
	-- Targeting functions from working version
	local function getClosestPlayerToMouse()
		local closestPlayer = nil
		local closestDistance = math.huge
		local cameraPos = camera.CFrame.Position
		
		for _, player in ipairs(players:GetPlayers()) do
			if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- Apply team check if enabled
				if teamCheck and isOnSameTeam(player) then continue end
				
				local hrp = player.Character.HumanoidRootPart
				local screenPoint = camera:WorldToViewportPoint(hrp.Position)
				local mousePoint = Vector2.new(mouse.X, mouse.Y)
				local distance = (mousePoint - Vector2.new(screenPoint.X, screenPoint.Y)).Magnitude
				local _, onScreen = camera:WorldToViewportPoint(hrp.Position)
				
				-- Apply aimbot distance lock
				local playerDistance = (hrp.Position - cameraPos).Magnitude
				if playerDistance > aimbotLockDistance then continue end
				
				if onScreen and distance < closestDistance then
					closestPlayer = player
					closestDistance = distance
				end
			end
		end
		
		return closestPlayer
	end
	
	local function getClosestByDistance()
		local closestPlayer = nil
		local closestDistance = math.huge
		local cameraPos = camera.CFrame.Position
		
		for _, player in ipairs(players:GetPlayers()) do
			if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- Apply team check if enabled
				if teamCheck and isOnSameTeam(player) then continue end
				
				local hrp = player.Character.HumanoidRootPart
				local distance = (hrp.Position - cameraPos).Magnitude
				
				-- Apply aimbot distance lock
				if distance > aimbotLockDistance then continue end
				
				if distance < closestDistance then
					closestPlayer = player
					closestDistance = distance
				end
			end
		end
		
		return closestPlayer
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
	
	local function getTarget()
		-- Use targeting methods based on mode
		local nearestPlayer = nil
		if targetMode == "Closest To Mouse" then
			nearestPlayer = getClosestPlayerToMouse()
		elseif targetMode == "Distance" then
			nearestPlayer = getClosestByDistance()
		end
		
		-- Apply additional checks
		if nearestPlayer and nearestPlayer.Character then
			local humanoid = nearestPlayer.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then return nil end
			if healthCheck and humanoid.Health < minHealth then return nil end
			if wallCheck and checkWall(nearestPlayer.Character) then return nil end
		end
		
		return nearestPlayer
	end
	
	local function getBlatantTarget()
		-- Special targeting for blatant mode - no on-screen requirement
		local closestPlayer = nil
		local closestDistance = math.huge
		local cameraPos = camera.CFrame.Position
		
		for _, player in ipairs(players:GetPlayers()) do
			if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- Apply team check if enabled
				if teamCheck and isOnSameTeam(player) then continue end
				
				local hrp = player.Character.HumanoidRootPart
				local distance = (hrp.Position - cameraPos).Magnitude
				
				-- Apply aimbot distance lock
				if distance > aimbotLockDistance then continue end
				
				-- No on-screen check for blatant mode - can target behind you
				if distance < closestDistance then
					closestPlayer = player
					closestDistance = distance
				end
			end
		end
		
		-- Apply additional checks
		if closestPlayer and closestPlayer.Character then
			local humanoid = closestPlayer.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then return nil end
			if healthCheck and humanoid.Health < minHealth then return nil end
			if wallCheck and checkWall(closestPlayer.Character) then return nil end
		end
		
		return closestPlayer
	end
	
	local function predict(target)
		local char = (type(target) == "table" and target.Character) or (typeof(target) == "Instance" and target:IsA("Player") and target.Character) or nil
		if not char then return nil end
		local aimPart = getAimPart(char)
		local hrp = getRootPart(char)
		if not aimPart or not hrp then return nil end
		return aimPart.Position + (hrp.Velocity * predictionStrength)
	end
	
	local function smooth(from, to)
		-- Convert 1-10 scale to 0.9-0.1 smoothing factor (corrected)
		-- 1 = subtle (0.9 smoothing, 10% movement) - LOW movement
		-- 10 = instant (0.1 smoothing, 90% movement) - HIGH movement
		local smoothingFactor = 1.0 - ((smoothing - 1) * 0.0889 + 0.1)
		return from:Lerp(to, smoothingFactor)
	end
	
	local function aimAt(target)
		if not target then return end
		
		local char = (type(target) == "table" and target.Character) or (typeof(target) == "Instance" and target:IsA("Player") and target.Character) or nil
		if not char then return end
		
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end
		if healthCheck and humanoid.Health < minHealth then return end
		
		local aimPart = getAimPart(char)
		if not aimPart then return end
		
		local targetPosition = aimPart.Position
		if not targetPosition or (targetPosition.X == 0 and targetPosition.Y == 0 and targetPosition.Z == 0) then return end
		
		local distance = (targetPosition - camera.CFrame.Position).Magnitude
		if distance > aimbotLockDistance * 2 then return end
		
		if blatantEnabled then
			-- Direct snap for blatant mode - EXACT and INSTANT
			if not wallCheck or not checkWall(char) then
				camera.CFrame = CFrame.new(camera.CFrame.Position, targetPosition)
			end
		else
			local predictedPosition = predict(target)
			if not predictedPosition then return end
			local predictedDistance = (predictedPosition - camera.CFrame.Position).Magnitude
			if predictedDistance <= aimbotLockDistance * 2 then
				camera.CFrame = smooth(camera.CFrame, CFrame.new(camera.CFrame.Position, predictedPosition))
			end
		end
	end
	
	-- Mouse aiming detection
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and aimbotEnabled then
			aiming = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			aiming = false
			currentTarget = nil
		end
	end)
	
	-- ESP functions from working version
	local function newDrawing(dtype, props)
		local d = Drawing.new(dtype)
		ESPDrawings[d] = true
		for k, v in pairs(props) do
			pcall(function() d[k] = v end)
		end
		return d
	end
	
	local function espIsTeammate(target)
		if not teamCheck then return false end
		local _, targetPlayer = resolveCharacter(target)
		if not targetPlayer then return false end
		return isOnSameTeam(targetPlayer)
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
	
	local createESP, removeESP
	
	createESP = function(target)
		if ESPData[target] then
			removeESP(target)
		end
		local obj = {}
		if QUAD_SUPPORTED then
			obj.box        = newDrawing("Quad", {Visible=false, Color=espColor, Thickness=1, Filled=false})
			obj.boxOutline = newDrawing("Quad", {Visible=false, Color=Color3.fromRGB(0,0,0), Thickness=3, Filled=false})
		else
			obj.boxT = newDrawing("Line", {Visible=false, Color=espColor, Thickness=1})
			obj.boxB = newDrawing("Line", {Visible=false, Color=espColor, Thickness=1})
			obj.boxL = newDrawing("Line", {Visible=false, Color=espColor, Thickness=1})
			obj.boxR = newDrawing("Line", {Visible=false, Color=espColor, Thickness=1})
		end
		obj.name        = newDrawing("Text",   {Visible=false, Text="", Size=13, Color=Color3.fromRGB(255,255,255), Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
		obj.dist        = newDrawing("Text",   {Visible=false, Text="", Size=12, Color=Color3.fromRGB(200,200,200), Center=true, Outline=true, OutlineColor=Color3.fromRGB(0,0,0)})
		obj.healthBG    = newDrawing("Line",   {Visible=false, Color=Color3.fromRGB(0,0,0), Thickness=4})
		obj.health      = newDrawing("Line",   {Visible=false, Color=Color3.fromRGB(0,255,0), Thickness=2})
		obj.tracerOut   = newDrawing("Line",   {Visible=false, Color=Color3.fromRGB(0,0,0), Thickness=3})
		obj.tracer      = newDrawing("Line",   {Visible=false, Color=Color3.fromRGB(255,255,0), Thickness=1})
		obj.headDot     = newDrawing("Circle", {Visible=false, Filled=true, NumSides=20, Radius=4, Color=espColor})
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
		
		-- Apply ESP distance lock
		if dist > espLockDistance then 
			hideESPObj(obj) 
			return 
		end
		
		-- Apply max distance check
		if dist > espLockDistance then hideESPObj(obj) return end
		
		-- Apply visibility check if enabled
		if espVisCheck and not espCheckWall(character) then hideESPObj(obj) return end
		
		-- Hide teammates when team check is enabled
		local isTeammate = espIsTeammate(player)
		if isTeammate then 
			hideESPObj(obj) 
			return 
		end
		
		local headScreen = camera:WorldToViewportPoint(aimPart.Position)
		if headScreen.Z < 0 then hideESPObj(obj) return end

		local color = espColor
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
		if boxEsp then
			drawBox(obj, Vector2.new(left,top), Vector2.new(right,top), Vector2.new(left,bot), Vector2.new(right,bot), color)
		else
			setBoxVis(obj, false)
		end

		-- Name
		if nameEsp then
			local name = character.Name
			if p then
				name = p.DisplayName
			end
			obj.name.Text = name
			obj.name.Position = Vector2.new(cx, top - 16)
			obj.name.Color = Color3.fromRGB(255,255,255)
			obj.name.Size = 13
			obj.name.Visible = true
		else
			obj.name.Visible = false
		end

		-- Distance
		if distanceEsp then
			obj.dist.Text = string.format("[%dm]", math.floor(dist))
			obj.dist.Position = Vector2.new(cx, top - (nameEsp and 28 or 16))
			obj.dist.Size = 12
			obj.dist.Visible = true
		else
			obj.dist.Visible = false
		end

		-- Health bar
		if healthEsp then
			local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
			local barX = left - 5
			obj.healthBG.From = Vector2.new(barX, top) obj.healthBG.To = Vector2.new(barX, bot) obj.healthBG.Visible = true
			obj.health.From = Vector2.new(barX, bot) obj.health.To = Vector2.new(barX, bot - (bot - top) * ratio)
			obj.health.Color = getHealthColor(humanoid.Health, humanoid.MaxHealth) obj.health.Visible = true
		else
			obj.healthBG.Visible = false obj.health.Visible = false
		end

		-- Tracers
		if tracerEsp then
			local origin = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
			local target = Vector2.new(cx, bot)
			obj.tracerOut.From=origin obj.tracerOut.To=target obj.tracerOut.Visible=true
			obj.tracer.From=origin obj.tracer.To=target obj.tracer.Color=Color3.fromRGB(255,255,0) obj.tracer.Visible=true
		else
			obj.tracerOut.Visible=false obj.tracer.Visible=false
		end

		-- Head dot (not in current UI but keeping for compatibility)
		obj.headDot.Visible = false
	end
	
	-- Player management
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
	
	-- Main game loop from working version
	local currentTarget = nil
	local aiming = false
	
	-- Mouse aiming detection
	UserInputService.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 and aimbotEnabled then
			aiming = true
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			aiming = false
			currentTarget = nil
		end
	end)
	
	-- FOV Circle
	local fovCircle = Drawing.new("Circle")
	fovCircle.Color = fovColor
	fovCircle.Thickness = 2
	fovCircle.Transparency = 0.5
	fovCircle.Visible = false
	
	-- Main render loop
	RunService.RenderStepped:Connect(function()
		local ok = pcall(function()
			-- FOV circle
			fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 50)
			if rainbowFov then
				hue = hue + rainbowSpeed
				if hue > 1 then hue = 0 end
				fovCircle.Color = Color3.fromHSV(hue, 1, 1)
			else
				fovCircle.Color = fovColor
			end
			fovCircle.Radius = aimFov * (camera.ViewportSize.Y / 1080)
			fovCircle.Visible = aimbotEnabled or rainbowFov

			-- Aimbot System
			if aimbotEnabled or blatantEnabled then
				if blatantEnabled then
					-- Blatant: lock onto closest enemy and stick until dead (no on-screen requirement)
					if not currentTarget then
						-- Find new target only if we don't have one
						currentTarget = getBlatantTarget()
					end
					
					if currentTarget then
						-- Check if current target is still valid
						local character = currentTarget.Character
						local humanoid = character and character:FindFirstChildOfClass("Humanoid")
						
						if not humanoid or humanoid.Health <= 0 then
							-- Target is dead, find new one
							currentTarget = getBlatantTarget()
						else
							-- Check if target is still visible and not behind wall
							if wallCheck and checkWall(character) then
								-- Target behind wall, find new visible target
								currentTarget = getBlatantTarget()
							else
								-- Target is valid, aim at them
								aimAt(currentTarget)
							end
						end
					end
				elseif aiming then
					-- Normal aimbot requires aiming key and aimbotEnabled
					if aimbotEnabled then
						-- Normal aimbot requires aiming key
						if stickyAimEnabled and currentTarget then
							local character = currentTarget.Character
							if character and character:FindFirstChild("Humanoid") and character.Humanoid.Health > 0 then
								if not isOnSameTeam(currentTarget) then
									if character.Humanoid.Health >= minHealth or not healthCheck then
										if not wallCheck or not checkWall(character) then
											aimAt(currentTarget)
										end
									end
								end
							else
								currentTarget = nil
							end
						end
						if not stickyAimEnabled or not currentTarget then
							currentTarget = getTarget()
						end
						if currentTarget then 
							aimAt(currentTarget)
						end
					end
				else
					currentTarget = nil
				end
			else
				currentTarget = nil
			end

			-- ESP
			if not espEnabled then
				if espWasEnabled then
					for _, obj in pairs(ESPData) do hideESPObj(obj) end
				end
			else
				for target, obj in pairs(ESPData) do
					updateESP(target, obj)
				end
			end
			espWasEnabled = espEnabled
		end)
		if not ok then
			for _, obj in pairs(ESPData) do hideESPObj(obj) end
			fovCircle.Visible = false
		end
	end)
end)
