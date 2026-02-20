--[[
	Dev Copier - Universal Script & Console Copying Tool
	Designed for easy script distribution and developer console copying
	
	Features:
	- Custom chat command copying
	- Developer console log copying
	- Automatic clipboard copying
	- Loadstring generation
	- Manual copy fallback
	- Error handling
	
	Chat Commands: -datcopy, -copylog
]]

print("🔧 Loading Dev Copier...")

-- ===================================
-- SERVICES
-- ===================================

local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ===================================
-- CONSOLE LOG FUNCTIONS
-- ===================================

-- Utility: safe wait for DevConsole
local function getClientLog()
    local master = CoreGui:FindFirstChild("DevConsoleMaster")
    if not master then return end

    local window = master:FindFirstChild("DevConsoleWindow")
    if not window then return end

    local ui = window:FindFirstChild("DevConsoleUI")
    if not ui then return end

    local main = ui:FindFirstChild("MainView")
    if not main then return end

    return main:FindFirstChild("ClientLog")
end

-- Copy entire console log
local function copyConsoleLog()
    local clientLog = getClientLog()
    if not clientLog then
        warn("⚠️ Developer console not found!")
        return
    end

    local buffer = {}

    -- Collect all text from console
    for _, obj in ipairs(clientLog:GetDescendants()) do
        if obj:IsA("TextLabel") and obj.Text and obj.Text ~= "" then
            table.insert(buffer, obj.Text)
        end
    end

    if #buffer == 0 then
        warn("⚠️ No console log entries found!")
        return
    end

    local logContent = table.concat(buffer, "\n")
    
    -- Copy to clipboard
    if setclipboard then
        setclipboard(logContent)
        print("📋 Developer console log copied to clipboard!")
    else
        warn("⚠️ setclipboard function not available!")
    end
    
    -- Also print to console for manual copying
    print("📄 Console log content ready for manual copying:")
    print(logContent)
    
    print("✅ Copied", #buffer, "console entries!")
end

-- ===================================
-- SCRIPT COPY FUNCTIONS
-- ===================================

local function devCopy()
    -- Get the current script URL
    local scriptUrl = "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Examples/Universal_ESP_Pro.lua"
    
    -- Create the loadstring version for copying
    local scriptContent = string.format([===[
--[[
	Universal ESP Pro Enhanced - Professional ESP System
	Designed from scratch using best practices from multiple ESP libraries
	
	Enhanced Features:
	- Performance optimizations (rendering efficiency, memory management)
	- Advanced ESP features (skeleton, chams, distance-based scaling)
	- Modular architecture for easy integration
	- Advanced features (team colors, rainbow effects, animations)
	- Future-ready structure for script transitions
	
	ESP Types:
	- Box ESP (corner boxes with auto-scaling)
	- Name ESP (distance/health display)
	- Health ESP (dynamic health bars)
	- Tracer ESP (screen edge tracers)
	- Arrow ESP (off-screen indicators)
	- Skeleton ESP (bone structure)
	- Chams ESP (character highlighting)
	- Distance ESP (distance-based scaling)
]]

print("🚀 Loading Universal ESP Pro...")

-- Load the script from GitHub
loadstring(game:HttpGet("%s"))()
]===], scriptUrl)
    
    -- Copy to clipboard
    if setclipboard then
        setclipboard(scriptContent)
        print("📋 Universal ESP Pro Enhanced loadstring copied to clipboard!")
    else
        warn("⚠️ setclipboard function not available!")
    end
    
    -- Also print the script for manual copying
    print("📄 Loadstring content ready for manual copying:")
    print(scriptContent)
    
    -- Also copy the direct URL
    if setclipboard then
        setclipboard(scriptUrl)
        print("🔗 Direct script URL also copied to clipboard!")
    end
    
    print("🌐 Script URL:", scriptUrl)
end

-- ===================================
-- CHAT COMMAND SYSTEM
-- ===================================

-- Chat command handler
local function onChatMessage(message)
	local msg = message:lower()
	if msg == "-datcopy" then
		devCopy()
	elseif msg == "-copylog" then
		copyConsoleLog()
	end
end

-- Connect to chat
local chatConnection
local function setupChatListener()
	if LocalPlayer then
		-- Try to connect to chat service
		local success, result = pcall(function()
			return game:GetService("TextChatService").MessageReceived:Connect(function(message)
				local msg = message.TextInput:lower()
				if msg == "-datcopy" and message.FromUserId == LocalPlayer.UserId then
					devCopy()
				elseif msg == "-copylog" and message.FromUserId == LocalPlayer.UserId then
					copyConsoleLog()
				end
			end)
		end)
		
		if not success then
			-- Fallback to legacy chat
			pcall(function()
				chatConnection = LocalPlayer.Chatted:Connect(onChatMessage)
			end)
		end
		
		-- Additional fallback: Direct chat monitoring
		pcall(function()
			game.Players.LocalPlayer.Chatted:Connect(function(msg)
				local lowerMsg = msg:lower()
				if lowerMsg == "-datcopy" then
					devCopy()
				elseif lowerMsg == "-copylog" then
					copyConsoleLog()
				end
			end)
		end)
	end
end

-- ===================================
-- EXPORT FUNCTIONS
-- ===================================

-- Export dev copier function
getgenv().devCopy = devCopy
print("🔧 Dev copier functions exported to getgenv().devCopy")

-- Export console log copier function
getgenv().copyConsoleLog = copyConsoleLog
print("📋 Console log copier exported to getgenv().copyConsoleLog")

-- Additional utility functions
getgenv().getScriptUrl = function()
    return "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Examples/Universal_ESP_Pro.lua"
end

getgenv().copyScriptUrl = function()
    local url = "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Examples/Universal_ESP_Pro.lua"
    if setclipboard then
        setclipboard(url)
        print("🔗 Script URL copied to clipboard!")
    else
        warn("⚠️ setclipboard function not available!")
    end
    return url
end

-- ===================================
-- INITIALIZE CHAT COMMANDS
-- ===================================

setupChatListener()

print("✅ Dev Copier loaded successfully!")
print("📋 Available commands:")
print("  - Chat: -datcopy (Copy script loadstring)")
print("  - Chat: -copylog (Copy entire developer console)")
print("  - Function: getgenv().devCopy() - Copy script")
print("  - Function: getgenv().copyConsoleLog() - Copy console log")
print("  - Function: getgenv().getScriptUrl() - Get script URL")
print("  - Function: getgenv().copyScriptUrl() - Copy script URL")
