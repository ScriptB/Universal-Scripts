--[[
	Dev Copier - Universal Script Copying Tool
	Designed for easy script distribution and sharing
	
	Features:
	- Custom chat command copying
	- Automatic clipboard copying
	- Loadstring generation
	- Manual copy fallback
	- Error handling
	
	Chat Command: -datcopy
]]

print("🔧 Loading Dev Copier...")

-- ===================================
-- DEV COPIER FUNCTIONS
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

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Chat command handler
local function onChatMessage(message)
	if message == "-datcopy" then
		devCopy()
	end
end

-- Connect to chat
local chatConnection
local function setupChatListener()
	if LocalPlayer then
		-- Try to connect to chat service
		local success, result = pcall(function()
			return game:GetService("TextChatService").MessageReceived:Connect(function(message)
				if message.TextInput == "-datcopy" and message.FromUserId == LocalPlayer.UserId then
					devCopy()
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
				if msg:lower() == "-datcopy" then
					devCopy()
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
print("  - Chat: -datcopy (Copy loadstring version)")
print("  - Function: getgenv().devCopy() - Copy loadstring version")
print("  - Function: getgenv().getScriptUrl() - Get script URL")
print("  - Function: getgenv().copyScriptUrl() - Copy script URL")
