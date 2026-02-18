--[[
	Phantom Suite  Loader  v1.0
	Single entry point for the full Phantom Suite project.

	Load order:
	  1. Key System  — validates the user's key, blocks until done
	  2. Phantom Suite — aimbot + ESP
	  3. Phantom CMD  — command bar

	Usage (paste into executor):
	  loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Loader"))()
]]

local BASE = "https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/"

local function load(path)
	local ok, err = pcall(function()
		loadstring(game:HttpGet(BASE .. path))()
	end)
	if not ok then
		warn("[Phantom Loader] Failed to load: " .. path .. "\n" .. tostring(err))
	end
end

-- Step 1: Key gate (blocks via while-loop until SCRIPT_KEY is set)
load("KeySystem.lua")

-- Step 2: Phantom Suite (aimbot + ESP)
load("PhantomSuite.lua")

-- Step 3: Phantom CMD (command bar)
load("PhantomCMD.lua")
