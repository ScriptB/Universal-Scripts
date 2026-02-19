--[[
	◈ NEXUS HUB - Revolutionary Circular Interface
	Completely different GUI architecture - no traditional tabs
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local plr = Players.LocalPlayer

-- Variables
local aimbotEnabled = false
local espEnabled = false
local aimFov = 100
local EXECUTOR_NAME = "Unknown"

-- Executor detection
local function detectExecutor()
	if getgenv and getgenv().JJSploit then
		EXECUTOR_NAME = "JJSploit"
	elseif getgenv and getgenv().Solara then
		EXECUTOR_NAME = "Solara"
	elseif identifyexecutor then
		EXECUTOR_NAME = identifyexecutor()
	else
		EXECUTOR_NAME = "Unknown"
	end
end
detectExecutor()

-- Load NexacLib
local success, NexacLib = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Orion-Library/NexacLib.lua"))()
end)

if not success then
	local success, NexacLib = pcall(function()
		return loadfile("Orion-Library/NexacLib.lua")()
	end)
	if not success then return end
end

NexacLib:Init()

-- Create revolutionary theme
local HubTheme = {
	Main = Color3.fromRGB(10, 10, 20),
	Second = Color3.fromRGB(20, 15, 30),
	Third = Color3.fromRGB(30, 20, 40),
	Stroke = Color3.fromRGB(255, 0, 128),
	Divider = Color3.fromRGB(128, 0, 255),
	Text = Color3.fromRGB(0, 255, 255),
	TextDark = Color3.fromRGB(128, 128, 255),
	Accent = Color3.fromRGB(255, 0, 128),
	Accent2 = Color3.fromRGB(0, 255, 255),
	Good = Color3.fromRGB(0, 255, 128),
	Warn = Color3.fromRGB(255, 255, 0),
	Bad = Color3.fromRGB(255, 0, 0)
}

NexacLib.Themes.Hub = HubTheme
NexacLib.SelectedTheme = "Hub"

-- Create revolutionary circular hub window
local HubWindow = NexacLib:MakeWindow({
	Name = "◈ NEXUS HUB",
	HidePremium = false,
	SaveConfig = true,
	ConfigFolder = "NexusHub",
	IntroEnabled = false,
	ShowIcon = false
})

-- Create floating panels instead of traditional tabs
local CenterHub = HubWindow:MakeTab({Name = "◈", Icon = ""})
local AimPanel = HubWindow:MakeTab({Name = "🎯", Icon = ""})
local EspPanel = HubWindow:MakeTab({Name = "👁️", Icon = ""})
local MovePanel = HubWindow:MakeTab({Name = "🚀", Icon = ""})
local ToolPanel = HubWindow:MakeTab({Name = "⚡", Icon = ""})

-- Revolutionary interface - no sections, just direct controls
CenterHub:AddLabel("◈ " .. plr.DisplayName)
CenterHub:AddLabel("⚡ " .. EXECUTOR_NAME)
CenterHub:AddLabel("🌍 " .. game.PlaceId)

-- Central control toggle
CenterHub:AddToggle({
	Name = "◈",
	Default = aimbotEnabled,
	Callback = function(value)
		aimbotEnabled = value
		NexacLib:MakeNotification({
			Name = "Target",
			Content = value and "◈ Locked" or "◈ Released",
			Time = 1
		})
	end
})

-- Floating panels with minimal controls
AimPanel:AddToggle({
	Name = "🎯",
	Default = aimbotEnabled,
	Callback = function(value)
		aimbotEnabled = value
	end
})

AimPanel:AddSlider({
	Name = "◯",
	Min = 10,
	Max = 180,
	Default = aimFov,
	Callback = function(value)
		aimFov = value
	end
})

EspPanel:AddToggle({
	Name = "👁️",
	Default = espEnabled,
	Callback = function(value)
		espEnabled = value
	end
})

MovePanel:AddToggle({
	Name = "🚀",
	Default = false,
	Callback = function(value)
		-- Speed functionality
	end
})

ToolPanel:AddButton({
	Name = "⚡",
	Callback = function()
		NexacLib:MakeNotification({
			Name = "Tool",
			Content = "⚡ Activated",
			Time = 1
		})
	end
})

-- Dynamic status display
local statusLabel = CenterHub:AddLabel("◈ STANDBY")

game:GetService("RunService").Heartbeat:Connect(function()
	if statusLabel then
		statusLabel:Set("◈ " .. (aimbotEnabled and "ACTIVE" or "STANDBY"))
	end
end)

NexacLib:MakeNotification({
	Name = "Hub Online",
	Content = "◈ Revolutionary interface activated",
	Time = 2
})
