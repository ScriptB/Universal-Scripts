--[[
	Phantom Suite  Loader  v1.0
	Single entry point for the full Phantom Suite project.

	Load order:
	  1. Key System  — validates the user's key, blocks until done
	  2. Phantom Suite — aimbot + ESP
	  3. Phantom CMD  — command bar

	Usage (paste into executor):
	  loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Core/Loader.lua"))()
]]

local BASE = "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/"

local function load(path)
	local src = game:HttpGet(BASE .. path)
	local fn, err = loadstring(src)
	if not fn then
		error("[Phantom Loader] Syntax error in " .. path .. ": " .. tostring(err), 2)
	end
	local ok, err2 = pcall(fn)
	if not ok then
		error("[Phantom Loader] Runtime error in " .. path .. ": " .. tostring(err2), 2)
	end
end

-- Step 1: Key gate — sets getgenv().SCRIPT_KEY, blocks until validated
load("Tools/KeySystem.lua")

-- Ensure SCRIPT_KEY is set before continuing (handles saved-key fast-return path)
while not getgenv().SCRIPT_KEY do
	task.wait(0.1)
end

-- Step 2: Universal Aimbot — main script
load("Core/Universal_Aimbot.lua")

-- Step 3: Phantom CMD — command bar (optional)
-- load("Examples/PhantomCMD.lua")
