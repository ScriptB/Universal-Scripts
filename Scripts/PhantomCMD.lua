--[[
	Phantom Command Bar  v1.3
	Bottom-anchored strip, hover to rise, scroll + click to run commands.
	No external library dependency.
]]

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local plr = Players.LocalPlayer

-- ── Helpers ───────────────────────────────────────────────────
local function getChar()  return plr.Character end
local function getHum()   local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end

-- ── State ─────────────────────────────────────────────────────
local S = { fly=false, noclip=false, infJump=false, invisible=false, speed=16, jump=50 }
local conn = {}

-- ── Fly ───────────────────────────────────────────────────────
local function startFly()
	local c=getChar(); if not c then return end
	local root=c:WaitForChild("HumanoidRootPart",3); if not root then return end
	local hum=c:FindFirstChildOfClass("Humanoid")
	local gyro=Instance.new("BodyGyro")
	gyro.P=9e4; gyro.MaxTorque=Vector3.new(9e9,9e9,9e9)
	gyro.CFrame=workspace.CurrentCamera.CFrame; gyro.Parent=root
	local vel=Instance.new("BodyVelocity")
	vel.Velocity=Vector3.zero; vel.MaxForce=Vector3.new(9e9,9e9,9e9); vel.Parent=root
	local d={w=0,s=0,a=0,d=0,e=0,q=0}
	local ib=UIS.InputBegan:Connect(function(i,p)
		if p then return end local k=i.KeyCode
		if k==Enum.KeyCode.W then d.w=1 elseif k==Enum.KeyCode.S then d.s=-1
		elseif k==Enum.KeyCode.A then d.a=-1 elseif k==Enum.KeyCode.D then d.d=1
		elseif k==Enum.KeyCode.E then d.e=1 elseif k==Enum.KeyCode.Q then d.q=-1 end
	end)
	local ie=UIS.InputEnded:Connect(function(i,p)
		if p then return end local k=i.KeyCode
		if k==Enum.KeyCode.W then d.w=0 elseif k==Enum.KeyCode.S then d.s=0
		elseif k==Enum.KeyCode.A then d.a=0 elseif k==Enum.KeyCode.D then d.d=0
		elseif k==Enum.KeyCode.E then d.e=0 elseif k==Enum.KeyCode.Q then d.q=0 end
	end)
	conn.fly={gyro=gyro,vel=vel,ib=ib,ie=ie}
	task.spawn(function()
		while S.fly do
			task.wait()
			local cam=workspace.CurrentCamera
			local fwd=cam.CFrame.LookVector*(d.w+d.s)
			local right=cam.CFrame.RightVector*(d.d+d.a)
			local up=Vector3.new(0,d.e+d.q,0)
			local mv=(fwd+right+up).Magnitude>0
			vel.Velocity=(fwd+right+up)*(mv and S.speed or 0)
			gyro.CFrame=cam.CFrame
			if hum then hum.PlatformStand=true end
		end
		pcall(function() gyro:Destroy() end)
		pcall(function() vel:Destroy() end)
		pcall(function() ib:Disconnect() end)
		pcall(function() ie:Disconnect() end)
		conn.fly=nil
		local h=getHum(); if h then h.PlatformStand=false end
	end)
end

local function stopFly()
	S.fly=false
	if conn.fly then
		pcall(function() conn.fly.gyro:Destroy() end)
		pcall(function() conn.fly.vel:Destroy() end)
		pcall(function() conn.fly.ib:Disconnect() end)
		pcall(function() conn.fly.ie:Disconnect() end)
		conn.fly=nil
	end
	local h=getHum(); if h then h.PlatformStand=false end
end

-- ── Noclip ────────────────────────────────────────────────────
local function startNoclip()
	conn.noclip=RunService.Stepped:Connect(function()
		pcall(function()
			local c=getChar(); if not c then return end
			for _,p in ipairs(c:GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide=false end
			end
		end)
	end)
end

local function stopNoclip()
	if conn.noclip then conn.noclip:Disconnect(); conn.noclip=nil end
	pcall(function()
		local c=getChar(); if not c then return end
		for _,p in ipairs(c:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide=true end
		end
	end)
end

-- ── Inf Jump ──────────────────────────────────────────────────
local function startInfJump()
	conn.infJump=UIS.JumpRequest:Connect(function()
		local h=getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
	end)
end
local function stopInfJump()
	if conn.infJump then conn.infJump:Disconnect(); conn.infJump=nil end
end

-- ── Speed / Jump ──────────────────────────────────────────────
local function applySpeed(v) S.speed=v; local h=getHum(); if h then h.WalkSpeed=v end end
local function applyJump(v)  S.jump=v;  local h=getHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end

-- ── Invisible ─────────────────────────────────────────────────
local function setInvisible(on)
	local c=getChar(); if not c then return end
	for _,p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") or p:IsA("Decal") then
			p.LocalTransparencyModifier=on and 1 or 0
		end
	end
end

-- ── TP / Bring / Player utils ───────────────────────────────
local function findPlayer(name)
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=plr and p.Name:lower():find(name:lower(),1,true) then return p end
	end
end

local function trim(s)
	return (s:match("^%s*(.-)%s*$") or s)
end

local function isAll(name)
	return trim(name):lower() == "all"
end

local function getOthers()
	local t={}
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=plr then t[#t+1]=p end
	end
	return t
end

local function tpToPlayer(name)
	if isAll(name) then
		-- TP self to each player in sequence (last one sticks)
		local r=getRoot(); if not r then return "No character" end
		local count=0
		for _,p in ipairs(getOthers()) do
			local tc=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if tc then r.CFrame=tc.CFrame+Vector3.new(0,4,0); count+=1; task.wait(0.1) end
		end
		return "TP'd through "..count.." players"
	end
	local p=findPlayer(name); if not p then return "Player not found" end
	local r=getRoot(); local tc=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if r and tc then r.CFrame=tc.CFrame+Vector3.new(0,4,0); return "TP'd → "..p.Name end
	return "Character not loaded"
end

local function bringPlayer(name)
	if isAll(name) then
		local r=getRoot(); if not r then return "No character" end
		local count=0
		for i,p in ipairs(getOthers()) do
			local tc=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if tc then
				local offset=Vector3.new((i-1)*4,0,0)
				tc.CFrame=r.CFrame+offset; count+=1
			end
		end
		return "Brought "..count.." players"
	end
	local p=findPlayer(name); if not p then return "Player not found" end
	local r=getRoot(); local tc=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	if r and tc then tc.CFrame=r.CFrame+Vector3.new(3,0,0); return "Brought "..p.Name end
	return "Character not loaded"
end

local function tpToCoords(input)
	local x,y,z=input:match("([%-%.%d]+)[,%s]+([%-%.%d]+)[,%s]+([%-%.%d]+)")
	if not x then return "Format: x,y,z" end
	local r=getRoot(); if not r then return "No character" end
	r.CFrame=CFrame.new(tonumber(x),tonumber(y),tonumber(z))
	return string.format("TP'd to %.0f,%.0f,%.0f",tonumber(x),tonumber(y),tonumber(z))
end

local function kickPlayer(name)
	if isAll(name) then
		local count=0
		for _,p in ipairs(getOthers()) do
			pcall(function() p:Kick("Kicked by Phantom CMD") end)
			count+=1
		end
		return "Kicked "..count.." players"
	end
	local p=findPlayer(name); if not p then return "Player not found" end
	pcall(function() p:Kick("Kicked by Phantom CMD") end)
	return "Kicked "..p.Name
end

local function chatMsg(msg)
	local ok=pcall(function()
		local rs=game:GetService("ReplicatedStorage")
		local ev=rs:FindFirstChild("DefaultChatSystemChatEvents") and
				 rs.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
		if ev then ev:FireServer(msg,"All") end
	end)
	return ok and "Said: "..msg or "Chat unavailable"
end

local flingActive=false
local function toggleFling()
	flingActive=not flingActive
	if flingActive then
		task.spawn(function()
			local movel=0.1
			while flingActive do
				local r=getRoot()
				if r and r.Parent then
					local vel=r.Velocity
					r.Velocity=vel*1000000+Vector3.new(0,1000000,0)
					RunService.RenderStepped:Wait()
					if r and r.Parent then r.Velocity=vel end
					RunService.Stepped:Wait()
					if r and r.Parent then
						r.Velocity=vel+Vector3.new(0,movel,0)
						movel=movel*-1
					end
				else
					RunService.Heartbeat:Wait()
				end
			end
		end)
		return "Fling ON"
	end
	return "Fling OFF"
end

local loopKillConn=nil
local loopKillTarget="" -- "all" or player name
local function startLoopKill(name)
	if loopKillConn then loopKillConn:Disconnect() end
	loopKillTarget=name
	loopKillConn=RunService.Heartbeat:Connect(function()
		if isAll(loopKillTarget) then
			for _,p in ipairs(getOthers()) do
				local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if h then h.Health=0 end
			end
		else
			local p=findPlayer(loopKillTarget); if not p then return end
			local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if h then h.Health=0 end
		end
	end)
	return "Loop killing "..(isAll(name) and "everyone" or name)
end
local function stopLoopKill()
	if loopKillConn then loopKillConn:Disconnect(); loopKillConn=nil end
	loopKillTarget=""
	return "Loop kill stopped"
end

local loopBringConn=nil
local loopBringTarget=""
local function startLoopBring(name)
	if loopBringConn then loopBringConn:Disconnect() end
	loopBringTarget=name
	loopBringConn=RunService.Heartbeat:Connect(function()
		local r=getRoot(); if not r then return end
		if isAll(loopBringTarget) then
			for i,p in ipairs(getOthers()) do
				local tc=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if tc then tc.CFrame=r.CFrame+Vector3.new((i-1)*4,0,0) end
			end
		else
			local p=findPlayer(loopBringTarget); if not p then return end
			local tc=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
			if tc then tc.CFrame=r.CFrame+Vector3.new(3,0,0) end
		end
	end)
	return "Loop bringing "..(isAll(name) and "everyone" or name)
end
local function stopLoopBring()
	if loopBringConn then loopBringConn:Disconnect(); loopBringConn=nil end
	loopBringTarget=""
	return "Loop bring stopped"
end


local loopTpConn=nil
local loopTpTarget=""
local function startLoopTp(name)
	if loopTpConn then loopTpConn:Disconnect() end
	loopTpTarget=name
	loopTpConn=RunService.Heartbeat:Connect(function()
		local r=getRoot(); if not r then return end
		local p=findPlayer(loopTpTarget); if not p then return end
		local tc=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if tc then r.CFrame=tc.CFrame+Vector3.new(0,4,0) end
	end)
	return "Loop TP → "..name
end
local function stopLoopTp()
	if loopTpConn then loopTpConn:Disconnect(); loopTpConn=nil end
	loopTpTarget=""
	return "Loop TP stopped"
end

local antiAfkConn=nil
local function startAntiAfk()
	if antiAfkConn then return "Already active" end
	local VirtualUser=game:GetService("VirtualUser")
	antiAfkConn=game:GetService("Players").LocalPlayer.Idled:Connect(function()
		VirtualUser:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
	end)
	return "Anti-AFK ON"
end
local function stopAntiAfk()
	if antiAfkConn then antiAfkConn:Disconnect(); antiAfkConn=nil end
	return "Anti-AFK OFF"
end

local function setTimeOfDay(input)
	local h=tonumber(input)
	if not h then return "Enter hour 0-24" end
	local lighting=game:GetService("Lighting")
	lighting.TimeOfDay=string.format("%02d:00:00",math.clamp(math.floor(h),0,23))
	return "Time set to "..h..":00"
end

local function setFog(input)
	local v=tonumber(input)
	if not v then return "Enter number" end
	game:GetService("Lighting").FogEnd=v
	return "Fog end → "..v
end

local function setGravity(input)
	local v=tonumber(input)
	if not v then return "Enter number" end
	workspace.Gravity=v
	return "Gravity → "..v
end

local function printPos()
	local r=getRoot(); if not r then return "No character" end
	local p=r.Position
	return string.format("%.1f, %.1f, %.1f",p.X,p.Y,p.Z)
end

local function copyPos()
	local r=getRoot(); if not r then return "No character" end
	local p=r.Position
	return string.format("%.1f,%.1f,%.1f",p.X,p.Y,p.Z)
end

local function tpToSpawn()
	local r=getRoot(); if not r then return "No character" end
	local sp=workspace:FindFirstChildOfClass("SpawnLocation")
	if sp then r.CFrame=sp.CFrame+Vector3.new(0,5,0); return "TP'd to spawn"
	else r.CFrame=CFrame.new(0,10,0); return "TP'd to 0,10,0" end
end

local function deleteTerrainDecals()
	for _,v in ipairs(workspace.Terrain:GetChildren()) do
		if v:IsA("Decal") then v:Destroy() end
	end
	return "Terrain decals removed"
end

local function unlockAllParts()
	for _,v in ipairs(workspace:GetDescendants()) do
		if v:IsA("BasePart") then v.Locked=false end
	end
	return "All parts unlocked"
end

local function printPlayers()
	local names={}
	for _,p in ipairs(Players:GetPlayers()) do names[#names+1]=p.Name end
	return table.concat(names,", ")
end

-- ── Re-apply on respawn ───────────────────────────────────────
plr.CharacterAdded:Connect(function()
	task.wait(0.5)
	if S.speed~=16  then applySpeed(S.speed) end
	if S.jump~=50   then applyJump(S.jump)   end
	if S.noclip     then stopNoclip(); startNoclip() end
	if S.fly        then stopFly(); S.fly=true; startFly() end
	if S.invisible  then setInvisible(true) end
end)

-- ── Tabbed Command Table ──────────────────────────────────────
-- Each tab: { name, icon, cmds={...} }
-- cmd kinds: "toggle"|"action"|"input"|"slider"
local TABS = {
	{
		name="Movement", icon="🏃",
		cmds={
			{name="Fly",         icon="✈",  kind="toggle",
				get=function() return S.fly end,
				run=function() S.fly=not S.fly; if S.fly then startFly() else stopFly() end; return S.fly end},
			{name="Noclip",      icon="👻", kind="toggle",
				get=function() return S.noclip end,
				run=function() S.noclip=not S.noclip; if S.noclip then startNoclip() else stopNoclip() end; return S.noclip end},
			{name="Inf Jump",    icon="⬆",  kind="toggle",
				get=function() return S.infJump end,
				run=function() S.infJump=not S.infJump; if S.infJump then startInfJump() else stopInfJump() end; return S.infJump end},
			{name="Walk Speed",  icon="⚡", kind="slider", min=8,   max=500, val=16,
				run=function(v) applySpeed(v) end},
			{name="Jump Power",  icon="🦘", kind="slider", min=7,   max=500, val=50,
				run=function(v) applyJump(v) end},
			{name="Fly Speed",   icon="💨", kind="slider", min=10,  max=500, val=50,
				run=function(v) S.speed=v end},
			{name="Gravity",     icon="🌍", kind="input",  hint="e.g. 50 (default 196.2)",
				run=setGravity},
			{name="Respawn",     icon="🔄", kind="action",
				run=function() local h=getHum(); if h then h.Health=0 end; return "Respawned" end},
		},
	},
	{
		name="Player", icon="👤",
		cmds={
			{name="Invisible",   icon="👁",  kind="toggle",
				get=function() return S.invisible end,
				run=function() S.invisible=not S.invisible; setInvisible(S.invisible); return S.invisible end},
			{name="Anti-AFK",    icon="💤", kind="toggle",
				get=function() return antiAfkConn~=nil end,
				run=function()
					if antiAfkConn then stopAntiAfk(); return false
					else startAntiAfk(); return true end
				end},
			{name="Print Pos",   icon="📍", kind="action",  run=printPos},
			{name="TP to Spawn", icon="🏠", kind="action",  run=tpToSpawn},
			{name="TP to Coords",icon="🗺",  kind="input",  hint="x, y, z",
				run=tpToCoords},
			{name="Chat...",     icon="💬", kind="input",  hint="Message to send",
				run=chatMsg},
			{name="Phantom Suite",icon="👑", kind="action",
				run=function()
					task.spawn(function()
						loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Phantom%20Suite"))()
					end)
					return "Loading Phantom Suite..."
				end},
		},
	},
	{
		name="Others", icon="👥",
		cmds={
			{name="TP to...",    icon="🎯", kind="input",  hint="Player name or 'all'",
				run=tpToPlayer},
			{name="Bring...",    icon="📌", kind="input",  hint="Player name or 'all'",
				run=bringPlayer},
			{name="Fling",       icon="💥", kind="toggle", state=function() return flingActive end,
				run=toggleFling},
			{name="Loop Kill...",icon="☠",  kind="input",  hint="Player name or 'all'",
				run=startLoopKill},
			{name="Stop LK",     icon="🛑", kind="action",
				run=stopLoopKill},
			{name="Loop Bring...",icon="🔁", kind="input",  hint="Player name or 'all'",
				run=startLoopBring},
			{name="Stop LB",     icon="⏹",  kind="action",
				run=stopLoopBring},
			{name="Loop TP...",  icon="📡", kind="input",  hint="Player name",
				run=startLoopTp},
			{name="Stop LT",     icon="⛔", kind="action",
				run=stopLoopTp},
			{name="Kick...",     icon="🥾", kind="input",  hint="Player name or 'all'",
				run=kickPlayer},
			{name="List Players",icon="📋", kind="action",
				run=printPlayers},
		},
	},
	{
		name="World", icon="🌐",
		cmds={
			{name="Time of Day", icon="🕐", kind="input",  hint="Hour 0-23",
				run=setTimeOfDay},
			{name="Fog",         icon="🌫", kind="input",  hint="Fog end distance",
				run=setFog},
			{name="Unlock Parts",icon="🔓", kind="action",
				run=unlockAllParts},
			{name="Del Decals",  icon="🗑",  kind="action",
				run=deleteTerrainDecals},
			{name="Fullbright",  icon="☀",  kind="action",
				run=function()
					local l=game:GetService("Lighting")
					l.Brightness=2; l.ClockTime=14; l.FogEnd=1e6
					l.GlobalShadows=false; l.Ambient=Color3.fromRGB(178,178,178)
					return "Fullbright ON"
				end},
			{name="Reset Lighting",icon="🌙",kind="action",
				run=function()
					local l=game:GetService("Lighting")
					l.Brightness=1; l.ClockTime=14; l.FogEnd=1e6
					l.GlobalShadows=true; l.Ambient=Color3.fromRGB(70,70,70)
					return "Lighting reset"
				end},
		},
	},
}

-- ── Theme ─────────────────────────────────────────────────────
local BG    = Color3.fromRGB(14,12,22)
local BG2   = Color3.fromRGB(24,20,38)
local BG3   = Color3.fromRGB(34,28,54)
local ACC   = Color3.fromRGB(120,80,220)
local ACON  = Color3.fromRGB(60,200,110)
local TXT   = Color3.fromRGB(235,228,255)
local SUB   = Color3.fromRGB(150,138,195)
local BRD   = Color3.fromRGB(65,50,105)
local STRIP_COL = Color3.fromRGB(18,14,30)

local PANEL_W = 430
local STRIP_H = 46
local PANEL_H = 260

-- ── Destroy old instance ──────────────────────────────────────
pcall(function()
	local old=game:GetService("CoreGui"):FindFirstChild("PhantomCMD")
	if old then old:Destroy() end
end)

-- ── ScreenGui ─────────────────────────────────────────────────
local gui=Instance.new("ScreenGui")
gui.Name="PhantomCMD"; gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.DisplayOrder=998; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
pcall(function() gui.Parent=game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent=plr:WaitForChild("PlayerGui") end

-- ── Strip (always-visible bottom bar) ────────────────────────
local strip=Instance.new("Frame")
strip.Name="Strip"; strip.AnchorPoint=Vector2.new(0.5,1)
strip.Position=UDim2.new(0.5,0,1,0)
strip.Size=UDim2.new(0,PANEL_W,0,STRIP_H)
strip.BackgroundColor3=STRIP_COL; strip.BorderSizePixel=0; strip.ZIndex=10; strip.Parent=gui
Instance.new("UICorner",strip).CornerRadius=UDim.new(0,10)
local ss=Instance.new("UIStroke",strip); ss.Color=BRD; ss.Thickness=1.5

local stripLbl=Instance.new("TextLabel",strip)
stripLbl.Size=UDim2.new(1,-20,1,0); stripLbl.Position=UDim2.new(0,14,0,0)
stripLbl.BackgroundTransparency=1; stripLbl.Text="⚡  Phantom CMD  —  hover to open"
stripLbl.Font=Enum.Font.GothamBold; stripLbl.TextSize=12
stripLbl.TextColor3=SUB; stripLbl.TextXAlignment=Enum.TextXAlignment.Left; stripLbl.ZIndex=11

-- drag handle pill
local pill=Instance.new("Frame",strip)
pill.Size=UDim2.new(0,32,0,4); pill.AnchorPoint=Vector2.new(0.5,0)
pill.Position=UDim2.new(0.5,0,0,6); pill.BackgroundColor3=BRD; pill.BorderSizePixel=0; pill.ZIndex=11
Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)

-- ── Panel (slides up on hover) ────────────────────────────────
local panel=Instance.new("Frame")
panel.Name="Panel"; panel.AnchorPoint=Vector2.new(0.5,1)
panel.Position=UDim2.new(0.5,0,1,-STRIP_H)
panel.Size=UDim2.new(0,PANEL_W,0,0)
panel.BackgroundColor3=BG; panel.BorderSizePixel=0
panel.ClipsDescendants=true; panel.ZIndex=9; panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,12)
local ps=Instance.new("UIStroke",panel); ps.Color=BRD; ps.Thickness=1.5

-- title bar
local tbar=Instance.new("Frame",panel)
tbar.Size=UDim2.new(1,0,0,36); tbar.BackgroundColor3=BG2; tbar.BorderSizePixel=0; tbar.ZIndex=10
Instance.new("UICorner",tbar).CornerRadius=UDim.new(0,12)
-- cover bottom corners of title bar
local tcov=Instance.new("Frame",tbar)
tcov.Size=UDim2.new(1,0,0,14); tcov.Position=UDim2.new(0,0,1,-14)
tcov.BackgroundColor3=BG2; tcov.BorderSizePixel=0; tcov.ZIndex=10

local tlbl=Instance.new("TextLabel",tbar)
tlbl.Size=UDim2.new(1,-50,1,0); tlbl.Position=UDim2.new(0,14,0,0)
tlbl.BackgroundTransparency=1; tlbl.Text="⚡  Phantom Command Bar"
tlbl.Font=Enum.Font.GothamBold; tlbl.TextSize=13; tlbl.TextColor3=TXT
tlbl.TextXAlignment=Enum.TextXAlignment.Left; tlbl.ZIndex=11

local cBtn=Instance.new("TextButton",tbar)
cBtn.Size=UDim2.new(0,26,0,20); cBtn.Position=UDim2.new(1,-32,0.5,-10)
cBtn.BackgroundColor3=Color3.fromRGB(180,55,55); cBtn.BorderSizePixel=0
cBtn.Text="✕"; cBtn.Font=Enum.Font.GothamBold; cBtn.TextSize=11
cBtn.TextColor3=Color3.fromRGB(255,255,255); cBtn.ZIndex=12
Instance.new("UICorner",cBtn).CornerRadius=UDim.new(0,5)

-- scroll area
local scroll=Instance.new("ScrollingFrame",panel)
scroll.Position=UDim2.new(0,0,0,36); scroll.Size=UDim2.new(1,0,1,-52)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.ScrollBarThickness=4; scroll.ScrollBarImageColor3=ACC
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.ScrollingDirection=Enum.ScrollingDirection.Y; scroll.ZIndex=10

local ll=Instance.new("UIListLayout",scroll)
ll.Padding=UDim.new(0,6); ll.SortOrder=Enum.SortOrder.LayoutOrder
local lp=Instance.new("UIPadding",scroll)
lp.PaddingTop=UDim.new(0,8); lp.PaddingBottom=UDim.new(0,8)
lp.PaddingLeft=UDim.new(0,10); lp.PaddingRight=UDim.new(0,10)

-- feedback label
local feedLbl=Instance.new("TextLabel",panel)
feedLbl.Size=UDim2.new(1,-20,0,18); feedLbl.Position=UDim2.new(0,10,1,-22)
feedLbl.BackgroundTransparency=1; feedLbl.Text=""
feedLbl.Font=Enum.Font.Gotham; feedLbl.TextSize=11
feedLbl.TextColor3=Color3.fromRGB(255,210,80)
feedLbl.TextXAlignment=Enum.TextXAlignment.Left; feedLbl.ZIndex=11

local function showFeedback(msg)
	feedLbl.Text=msg
	task.delay(3,function() if feedLbl.Text==msg then feedLbl.Text="" end end)
end

-- ── Input Overlay ─────────────────────────────────────────────
local ov=Instance.new("Frame",gui)
ov.Size=UDim2.new(1,0,1,0); ov.BackgroundColor3=Color3.fromRGB(0,0,0)
ov.BackgroundTransparency=0.5; ov.BorderSizePixel=0; ov.ZIndex=50; ov.Visible=false

local ob=Instance.new("Frame",ov)
ob.AnchorPoint=Vector2.new(0.5,0.5); ob.Position=UDim2.new(0.5,0,0.5,0)
ob.Size=UDim2.new(0,340,0,120); ob.BackgroundColor3=BG2; ob.BorderSizePixel=0; ob.ZIndex=51
Instance.new("UICorner",ob).CornerRadius=UDim.new(0,12)
local ovs=Instance.new("UIStroke",ob); ovs.Color=ACC; ovs.Thickness=1.5

local ovT=Instance.new("TextLabel",ob)
ovT.Size=UDim2.new(1,-20,0,30); ovT.Position=UDim2.new(0,10,0,8)
ovT.BackgroundTransparency=1; ovT.Text="Enter value"
ovT.Font=Enum.Font.GothamBold; ovT.TextSize=14; ovT.TextColor3=TXT
ovT.TextXAlignment=Enum.TextXAlignment.Left; ovT.ZIndex=52

local ovI=Instance.new("TextBox",ob)
ovI.Size=UDim2.new(1,-20,0,34); ovI.Position=UDim2.new(0,10,0,42)
ovI.BackgroundColor3=BG3; ovI.BorderSizePixel=0; ovI.Text=""
ovI.PlaceholderText="Type here..."; ovI.Font=Enum.Font.Gotham; ovI.TextSize=13
ovI.TextColor3=TXT; ovI.PlaceholderColor3=SUB; ovI.ClearTextOnFocus=false; ovI.ZIndex=52
Instance.new("UICorner",ovI).CornerRadius=UDim.new(0,7)
Instance.new("UIPadding",ovI).PaddingLeft=UDim.new(0,8)

local ovOk=Instance.new("TextButton",ob)
ovOk.Size=UDim2.new(0,90,0,28); ovOk.Position=UDim2.new(1,-100,1,-38)
ovOk.BackgroundColor3=ACC; ovOk.BorderSizePixel=0; ovOk.Text="Run"
ovOk.Font=Enum.Font.GothamBold; ovOk.TextSize=13; ovOk.TextColor3=Color3.fromRGB(255,255,255); ovOk.ZIndex=52
Instance.new("UICorner",ovOk).CornerRadius=UDim.new(0,7)

local ovCx=Instance.new("TextButton",ob)
ovCx.Size=UDim2.new(0,70,0,28); ovCx.Position=UDim2.new(0,10,1,-38)
ovCx.BackgroundColor3=BG3; ovCx.BorderSizePixel=0; ovCx.Text="Cancel"
ovCx.Font=Enum.Font.Gotham; ovCx.TextSize=12; ovCx.TextColor3=SUB; ovCx.ZIndex=52
Instance.new("UICorner",ovCx).CornerRadius=UDim.new(0,7)

-- ── Slider Overlay ────────────────────────────────────────────
local slov=Instance.new("Frame",gui)
slov.Size=UDim2.new(1,0,1,0); slov.BackgroundColor3=Color3.fromRGB(0,0,0)
slov.BackgroundTransparency=0.5; slov.BorderSizePixel=0; slov.ZIndex=50; slov.Visible=false

local slb=Instance.new("Frame",slov)
slb.AnchorPoint=Vector2.new(0.5,0.5); slb.Position=UDim2.new(0.5,0,0.5,0)
slb.Size=UDim2.new(0,340,0,130); slb.BackgroundColor3=BG2; slb.BorderSizePixel=0; slb.ZIndex=51
Instance.new("UICorner",slb).CornerRadius=UDim.new(0,12)
local slbs=Instance.new("UIStroke",slb); slbs.Color=ACC; slbs.Thickness=1.5

local slT=Instance.new("TextLabel",slb)
slT.Size=UDim2.new(1,-90,0,28); slT.Position=UDim2.new(0,10,0,8)
slT.BackgroundTransparency=1; slT.Text="Value"
slT.Font=Enum.Font.GothamBold; slT.TextSize=14; slT.TextColor3=TXT
slT.TextXAlignment=Enum.TextXAlignment.Left; slT.ZIndex=52

local slV=Instance.new("TextLabel",slb)
slV.Size=UDim2.new(0,80,0,28); slV.Position=UDim2.new(1,-90,0,8)
slV.BackgroundTransparency=1; slV.Text="16"
slV.Font=Enum.Font.GothamBold; slV.TextSize=14; slV.TextColor3=ACC
slV.TextXAlignment=Enum.TextXAlignment.Right; slV.ZIndex=52

local slTrk=Instance.new("Frame",slb)
slTrk.Size=UDim2.new(1,-20,0,10); slTrk.Position=UDim2.new(0,10,0,50)
slTrk.BackgroundColor3=BG3; slTrk.BorderSizePixel=0; slTrk.ZIndex=52
Instance.new("UICorner",slTrk).CornerRadius=UDim.new(1,0)

local slFill=Instance.new("Frame",slTrk)
slFill.Size=UDim2.new(0,0,1,0); slFill.BackgroundColor3=ACC
slFill.BorderSizePixel=0; slFill.ZIndex=53
Instance.new("UICorner",slFill).CornerRadius=UDim.new(1,0)

local slKnob=Instance.new("Frame",slTrk)
slKnob.Size=UDim2.new(0,18,0,18); slKnob.AnchorPoint=Vector2.new(0.5,0.5)
slKnob.Position=UDim2.new(0,0,0.5,0); slKnob.BackgroundColor3=Color3.fromRGB(255,255,255)
slKnob.BorderSizePixel=0; slKnob.ZIndex=54
Instance.new("UICorner",slKnob).CornerRadius=UDim.new(1,0)

local slOk=Instance.new("TextButton",slb)
slOk.Size=UDim2.new(0,90,0,28); slOk.Position=UDim2.new(1,-100,1,-38)
slOk.BackgroundColor3=ACC; slOk.BorderSizePixel=0; slOk.Text="Apply"
slOk.Font=Enum.Font.GothamBold; slOk.TextSize=13; slOk.TextColor3=Color3.fromRGB(255,255,255); slOk.ZIndex=52
Instance.new("UICorner",slOk).CornerRadius=UDim.new(0,7)

local slCx=Instance.new("TextButton",slb)
slCx.Size=UDim2.new(0,70,0,28); slCx.Position=UDim2.new(0,10,1,-38)
slCx.BackgroundColor3=BG3; slCx.BorderSizePixel=0; slCx.Text="Cancel"
slCx.Font=Enum.Font.Gotham; slCx.TextSize=12; slCx.TextColor3=SUB; slCx.ZIndex=52
Instance.new("UICorner",slCx).CornerRadius=UDim.new(0,7)

-- ── Slider Overlay Logic ──────────────────────────────────────
local sliderDragging = false
local sliderCurrentCmd = nil
local sliderCurrentVal = 16

local function updateSliderVisual(pct)
	slFill.Size=UDim2.new(pct,0,1,0)
	slKnob.Position=UDim2.new(pct,0,0.5,0)
end

local function openSlider(cmd)
	sliderCurrentCmd=cmd
	sliderCurrentVal=cmd.val
	slT.Text=cmd.name
	local pct=(cmd.val-cmd.min)/(cmd.max-cmd.min)
	slV.Text=tostring(cmd.val)
	updateSliderVisual(pct)
	slov.Visible=true
end

slTrk.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
		sliderDragging=true
	end
end)
UIS.InputEnded:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
		sliderDragging=false
	end
end)
UIS.InputChanged:Connect(function(inp)
	if not sliderDragging or not sliderCurrentCmd then return end
	if inp.UserInputType~=Enum.UserInputType.MouseMovement and inp.UserInputType~=Enum.UserInputType.Touch then return end
	local abs=slTrk.AbsolutePosition; local sz=slTrk.AbsoluteSize
	local pct=math.clamp((inp.Position.X-abs.X)/sz.X,0,1)
	local cmd=sliderCurrentCmd
	local val=math.floor(cmd.min+(cmd.max-cmd.min)*pct+0.5)
	sliderCurrentVal=val; slV.Text=tostring(val)
	updateSliderVisual(pct)
end)

slOk.MouseButton1Click:Connect(function()
	if sliderCurrentCmd then
		sliderCurrentCmd.val=sliderCurrentVal
		sliderCurrentCmd.run(sliderCurrentVal)
		showFeedback(sliderCurrentCmd.name.." → "..sliderCurrentVal)
	end
	slov.Visible=false
end)
slCx.MouseButton1Click:Connect(function() slov.Visible=false end)

-- ── Input Overlay Logic ───────────────────────────────────────
local inputCurrentCmd=nil

local function openInput(cmd)
	inputCurrentCmd=cmd
	ovT.Text=cmd.name
	ovI.Text=""
	ovI.PlaceholderText=cmd.hint or "Enter value..."
	ov.Visible=true
	task.delay(0.05,function() ovI:CaptureFocus() end)
end

local function runInputCmd()
	if not inputCurrentCmd then return end
	local text = trim(ovI.Text)
	if text == "" then return end
	local cmd = inputCurrentCmd
	inputCurrentCmd = nil
	ov.Visible = false
	task.spawn(function()
		local result = cmd.run(text)
		if result then showFeedback(tostring(result)) end
	end)
end

ovOk.MouseButton1Click:Connect(runInputCmd)
ovCx.MouseButton1Click:Connect(function() inputCurrentCmd=nil; ov.Visible=false end)
ovI.FocusLost:Connect(function(enter)
	if enter then runInputCmd() end
end)

-- ── Tab Bar + Command Rows ────────────────────────────────────

-- Resize panel title bar to make room for tab bar below it
-- Layout: titleBar(36) + tabBar(30) + scroll(rest) + feedLbl(18)
local TAB_BAR_H = 30

-- Tab bar frame (sits below title bar)
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, 0, 0, TAB_BAR_H)
tabBar.Position = UDim2.new(0, 0, 0, 36)
tabBar.BackgroundColor3 = BG2
tabBar.BorderSizePixel = 0
tabBar.ZIndex = 10
tabBar.Parent = panel

local tabBarLayout = Instance.new("UIListLayout", tabBar)
tabBarLayout.FillDirection = Enum.FillDirection.Horizontal
tabBarLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabBarLayout.Padding = UDim.new(0, 2)

local tabBarPad = Instance.new("UIPadding", tabBar)
tabBarPad.PaddingLeft = UDim.new(0, 6)
tabBarPad.PaddingRight = UDim.new(0, 6)
tabBarPad.PaddingTop = UDim.new(0, 4)
tabBarPad.PaddingBottom = UDim.new(0, 4)

-- Reposition scroll and feedLbl to account for tab bar
scroll.Position = UDim2.new(0, 0, 0, 36 + TAB_BAR_H)
scroll.Size = UDim2.new(1, 0, 1, -(36 + TAB_BAR_H + 22))
feedLbl.Position = UDim2.new(0, 10, 1, -20)

-- Helper: build one command row into a parent ScrollingFrame
local function refreshToggleVisual(row, active)
	local ind = row:FindFirstChild("Indicator")
	local nl  = row:FindFirstChild("NameLbl")
	if ind then ind.BackgroundColor3 = active and ACON or BG3 end
	if nl  then nl.TextColor3 = active and ACON or TXT end
	row.BackgroundColor3 = active and Color3.fromRGB(28,48,36) or BG2
end

local function buildRow(cmd, idx, parent)
	local row = Instance.new("Frame")
	row.Name = "Row_"..idx
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = BG2
	row.BorderSizePixel = 0
	row.LayoutOrder = idx
	row.ZIndex = 11
	row.Parent = parent
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

	local iconLbl = Instance.new("TextLabel", row)
	iconLbl.Size = UDim2.new(0, 36, 1, 0)
	iconLbl.Position = UDim2.new(0, 4, 0, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Text = cmd.icon or "•"
	iconLbl.Font = Enum.Font.GothamBold
	iconLbl.TextSize = 18
	iconLbl.TextColor3 = ACC
	iconLbl.ZIndex = 12

	local nameLbl = Instance.new("TextLabel", row)
	nameLbl.Name = "NameLbl"
	nameLbl.Size = UDim2.new(1, -120, 1, 0)
	nameLbl.Position = UDim2.new(0, 42, 0, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Text = cmd.name
	nameLbl.Font = Enum.Font.GothamBold
	nameLbl.TextSize = 13
	nameLbl.TextColor3 = TXT
	nameLbl.TextXAlignment = Enum.TextXAlignment.Left
	nameLbl.ZIndex = 12

	local badge = Instance.new("TextLabel", row)
	badge.Size = UDim2.new(0, 54, 0, 20)
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -8, 0.5, 0)
	badge.BackgroundColor3 = BG3
	badge.BorderSizePixel = 0
	badge.Text = cmd.kind:upper()
	badge.Font = Enum.Font.Gotham
	badge.TextSize = 10
	badge.TextColor3 = SUB
	badge.ZIndex = 12
	Instance.new("UICorner", badge).CornerRadius = UDim.new(0, 5)

	if cmd.kind == "toggle" then
		local ind = Instance.new("Frame", row)
		ind.Name = "Indicator"
		ind.Size = UDim2.new(0, 10, 0, 10)
		ind.AnchorPoint = Vector2.new(0, 0.5)
		ind.Position = UDim2.new(1, -70, 0.5, 0)
		ind.BackgroundColor3 = BG3
		ind.BorderSizePixel = 0
		ind.ZIndex = 13
		Instance.new("UICorner", ind).CornerRadius = UDim.new(1, 0)
		-- show initial state
		if cmd.get and cmd.get() then refreshToggleVisual(row, true) end
	end

	local btn = Instance.new("TextButton", row)
	btn.Size = UDim2.new(1, 0, 1, 0)
	btn.BackgroundTransparency = 1
	btn.Text = ""
	btn.ZIndex = 14

	btn.MouseEnter:Connect(function()
		local active = (cmd.kind=="toggle" and cmd.get and cmd.get()) or false
		TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3=active and Color3.fromRGB(32,58,42) or BG3}):Play()
	end)
	btn.MouseLeave:Connect(function()
		local active = (cmd.kind=="toggle" and cmd.get and cmd.get()) or false
		TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3=active and Color3.fromRGB(28,48,36) or BG2}):Play()
	end)
	btn.MouseButton1Click:Connect(function()
		if cmd.kind == "toggle" then
			local newState = cmd.run()
			refreshToggleVisual(row, newState)
			showFeedback(cmd.name .. (newState and "  ON" or "  OFF"))
		elseif cmd.kind == "action" then
			local result = cmd.run()
			if result then showFeedback(tostring(result)) end
		elseif cmd.kind == "input" then
			openInput(cmd)
		elseif cmd.kind == "slider" then
			openSlider(cmd)
		end
	end)
end

-- Build one ScrollingFrame per tab, stacked in the same area
local tabScrolls = {}
local tabBtns    = {}
local activeTab  = 1

local function switchTab(idx)
	activeTab = idx
	for i, sf in ipairs(tabScrolls) do
		sf.Visible = (i == idx)
	end
	for i, tb in ipairs(tabBtns) do
		if i == idx then
			tb.BackgroundColor3 = ACC
			tb.TextColor3 = Color3.fromRGB(255,255,255)
		else
			tb.BackgroundColor3 = BG3
			tb.TextColor3 = SUB
		end
	end
end

for ti, tab in ipairs(TABS) do
	-- Tab button
	local tbtn = Instance.new("TextButton", tabBar)
	tbtn.Size = UDim2.new(0, 90, 1, 0)
	tbtn.BackgroundColor3 = BG3
	tbtn.BorderSizePixel = 0
	tbtn.Text = tab.icon .. " " .. tab.name
	tbtn.Font = Enum.Font.GothamBold
	tbtn.TextSize = 11
	tbtn.TextColor3 = SUB
	tbtn.LayoutOrder = ti
	tbtn.ZIndex = 11
	Instance.new("UICorner", tbtn).CornerRadius = UDim.new(0, 6)
	tabBtns[ti] = tbtn

	-- Per-tab scroll
	local sf = Instance.new("ScrollingFrame", panel)
	sf.Position = UDim2.new(0, 0, 0, 36 + TAB_BAR_H)
	sf.Size = UDim2.new(1, 0, 1, -(36 + TAB_BAR_H + 22))
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 4
	sf.ScrollBarImageColor3 = ACC
	sf.CanvasSize = UDim2.new(0, 0, 0, 0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.ScrollingDirection = Enum.ScrollingDirection.Y
	sf.ZIndex = 10
	sf.Visible = (ti == 1)
	sf.Parent = panel
	tabScrolls[ti] = sf

	local sfl = Instance.new("UIListLayout", sf)
	sfl.Padding = UDim.new(0, 6)
	sfl.SortOrder = Enum.SortOrder.LayoutOrder
	local sfp = Instance.new("UIPadding", sf)
	sfp.PaddingTop = UDim.new(0, 8)
	sfp.PaddingBottom = UDim.new(0, 8)
	sfp.PaddingLeft = UDim.new(0, 10)
	sfp.PaddingRight = UDim.new(0, 10)

	-- Build rows for this tab
	for ci, cmd in ipairs(tab.cmds) do
		buildRow(cmd, ci, sf)
	end

	tbtn.MouseButton1Click:Connect(function() switchTab(ti) end)
end

-- Hide the old shared scroll (replaced by per-tab scrolls above)
scroll.Visible = false

-- Activate first tab visually
switchTab(1)

-- ── Panel Open / Close Animation ─────────────────────────────
local panelOpen = false
local TINFO = TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function openPanel()
	if panelOpen then return end
	panelOpen = true
	stripLbl.Text = "⚡  Phantom CMD"
	TweenService:Create(panel, TINFO, {Size=UDim2.new(0,PANEL_W,0,PANEL_H)}):Play()
end

local function closePanel()
	if not panelOpen then return end
	panelOpen = false
	stripLbl.Text = "⚡  Phantom CMD  —  hover to open"
	TweenService:Create(panel, TINFO, {Size=UDim2.new(0,PANEL_W,0,0)}):Play()
end

cBtn.MouseButton1Click:Connect(closePanel)

-- ── Hover Detection (event-based) ────────────────────────────
-- A small delay before closing prevents flicker when moving between strip and panel.
local closeThread = nil

local function scheduleClose()
	if closeThread then task.cancel(closeThread) end
	closeThread = task.delay(0.08, function()
		if ov.Visible or slov.Visible then return end
		closePanel()
		closeThread = nil
	end)
end

local function cancelClose()
	if closeThread then task.cancel(closeThread); closeThread = nil end
	if ov.Visible or slov.Visible then return end
	openPanel()
end

-- Strip events
strip.MouseEnter:Connect(cancelClose)
strip.MouseLeave:Connect(scheduleClose)

-- Panel events — use a transparent overlay button so ClipsDescendants doesn't block events
local panelHover = Instance.new("TextButton")
panelHover.Name = "HoverCatcher"
panelHover.Size = UDim2.new(1,0,1,0)
panelHover.BackgroundTransparency = 1
panelHover.Text = ""
panelHover.ZIndex = 8
panelHover.Parent = panel
panelHover.MouseEnter:Connect(cancelClose)
panelHover.MouseLeave:Connect(scheduleClose)

-- ── Horizontal Drag ───────────────────────────────────────────
local dragging=false
local dragStartX=0
local dragStartPanelX=0

strip.InputBegan:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=true
		dragStartX=inp.Position.X
		dragStartPanelX=strip.Position.X.Scale
	end
end)
UIS.InputEnded:Connect(function(inp)
	if inp.UserInputType==Enum.UserInputType.MouseButton1 then
		dragging=false
	end
end)
UIS.InputChanged:Connect(function(inp)
	if not dragging then return end
	if inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
	local vp=workspace.CurrentCamera.ViewportSize
	local delta=inp.Position.X-dragStartX
	local newScale=math.clamp(dragStartPanelX+delta/vp.X, 0.1, 0.9)
	strip.Position=UDim2.new(newScale,0,1,0)
	panel.Position=UDim2.new(newScale,0,1,-STRIP_H)
end)

-- ── Done ──────────────────────────────────────────────────────
-- PhantomCMD loaded. Strip sits at bottom-centre. Hover to open.

