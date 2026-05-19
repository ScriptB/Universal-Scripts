-- ══════════════════════════════════════════════════════════════
--  Universal Utility — Movement & ESP
--  Toggle menu: RightShift
-- ══════════════════════════════════════════════════════════════

local AxiUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/AxiUI/AxiUI_Framework.lua"
))()

local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/AxiUI/AxiUI_ThemeManager.lua"
))()

local Managers = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/AxiUI/AxiUI_InterfaceManager.lua"
))()

local SaveManager    = Managers.SaveManager
local Watermark      = Managers.Watermark
local KeybindOverlay = Managers.KeybindOverlay

-- ── SERVICES ────────────────────────────────────────────────────
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS        = game:GetService("UserInputService")
local Lighting   = game:GetService("Lighting")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function Char() return LP.Character end
local function HRP()  local c = Char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()  local c = Char(); return c and c:FindFirstChildOfClass("Humanoid") end

-- ── EXECUTOR COMPAT ──────────────────────────────────────────────
local HAS_DRAWING = false
pcall(function()
    local t = Drawing.new("Line"); t:Remove()
    HAS_DRAWING = true
end)

-- ── SPEED STATE ──────────────────────────────────────────────────
local _bvObj, _lvObj, _lvAttach
local _prevSpeedMethod = nil

local function _cleanSpeedObjs()
    if _bvObj    then pcall(function() _bvObj:Destroy()    end); _bvObj    = nil end
    if _lvObj    then pcall(function() _lvObj:Destroy()    end); _lvObj    = nil end
    if _lvAttach then pcall(function() _lvAttach:Destroy() end); _lvAttach = nil end
end

-- ── FLY STATE ────────────────────────────────────────────────────
local _flyConn, _flyBV, _flyGyro

local function _cleanFly()
    if _flyConn  then _flyConn:Disconnect(); _flyConn = nil end
    if _flyBV    then pcall(function() _flyBV:Destroy()   end); _flyBV   = nil end
    if _flyGyro  then pcall(function() _flyGyro:Destroy() end); _flyGyro = nil end
end

-- ── NOCLIP STATE ─────────────────────────────────────────────────
local _noclipConn

-- ── AIRWALK STATE ────────────────────────────────────────────────
local _awPart, _awH = nil, 0

-- ── ESP STATE ────────────────────────────────────────────────────
local ESP_CACHE = {}
local V2        = Vector2.new

-- ══════════════════════════════════════════════════════════════
--  WINDOW
-- ══════════════════════════════════════════════════════════════
local Window = AxiUI:CreateWindow({
    Title     = "Universal",
    Width     = 440,
    Height    = 520,
    ToggleKey = Enum.KeyCode.RightShift,
})

-- ══════════════════════════════════════════════════════════════
--  TAB 1 — MOVEMENT
-- ══════════════════════════════════════════════════════════════
local TabMove = Window:AddTab("Movement")

-- ── Speed ────────────────────────────────────────────────────
local BoxSpeed = TabMove:AddGroupbox("Speed")

BoxSpeed:AddDropdown("SpeedMethod", {
    Text    = "Method",
    Items   = { "WalkSpeed", "CFrame", "BodyVelocity", "LinearVelocity", "TranslateBy" },
    Default = "WalkSpeed",
    Tooltip = "CFrame/BV/LV/TranslateBy bypass server-side WalkSpeed checks",
})

BoxSpeed:AddToggle("SpeedEnabled", {
    Text    = "Speed Hack",
    Default = false,
    Callback = function(on)
        if not on then
            _cleanSpeedObjs()
            _prevSpeedMethod = nil
            local h = Hum(); if h then h.WalkSpeed = 16 end
        end
    end,
})

BoxSpeed:AddSlider("SpeedValue", {
    Text     = "Speed",
    Min      = 16,
    Max      = 500,
    Default  = 60,
    Rounding = false,
    Suffix   = " u/s",
})

BoxSpeed:AddSlider("JumpPower", {
    Text     = "Jump Power",
    Min      = 7,
    Max      = 500,
    Default  = 50,
    Rounding = false,
    Suffix   = " u/s",
    Callback = function(v)
        local h = Hum(); if h then h.UseJumpPower = true; h.JumpPower = v end
    end,
})

BoxSpeed:AddToggle("InfiniteJump", {
    Text    = "Infinite Jump",
    Default = false,
    Tooltip = "Jump again mid-air",
})

BoxSpeed:AddButton({ Text = "Reset Speed & Jump", Callback = function()
    _cleanSpeedObjs(); _prevSpeedMethod = nil
    AxiUI.Flags["SpeedEnabled_obj"].Set(false)
    local h = Hum()
    if h then h.WalkSpeed = 16; h.JumpPower = 50 end
    AxiUI.Flags["SpeedValue_obj"].Set(16)
    AxiUI.Flags["JumpPower_obj"].Set(50)
    AxiUI:Notify("Movement", "Speed and jump reset", 2)
end })

-- Unified speed enforcement (runs every heartbeat, method-aware)
RunService.Heartbeat:Connect(function(dt)
    if not AxiUI.Flags["SpeedEnabled"] then return end
    local hrp = HRP(); local h = Hum()
    if not (hrp and h) then return end
    local spd    = AxiUI.Flags["SpeedValue"] or 60
    local method = AxiUI.Flags["SpeedMethod"] or "WalkSpeed"

    -- Reset stale physics objects when method switches
    if method ~= _prevSpeedMethod then
        _cleanSpeedObjs()
        if _prevSpeedMethod == "WalkSpeed" then h.WalkSpeed = 16 end
        _prevSpeedMethod = method
    end

    if method == "WalkSpeed" then
        h.WalkSpeed = spd
    elseif method == "CFrame" then
        if h.MoveDirection.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + h.MoveDirection * spd * dt * 1.5
        end
    elseif method == "BodyVelocity" then
        if not _bvObj or not _bvObj.Parent then
            _bvObj            = Instance.new("BodyVelocity")
            _bvObj.MaxForce   = Vector3.new(1e6, 0, 1e6)
            _bvObj.P          = 1e5
            _bvObj.Velocity   = Vector3.zero
            _bvObj.Parent     = hrp
        end
        _bvObj.Velocity = h.MoveDirection * spd
    elseif method == "LinearVelocity" then
        if not _lvAttach or not _lvAttach.Parent then
            _lvAttach = Instance.new("Attachment"); _lvAttach.Parent = hrp
        end
        if not _lvObj or not _lvObj.Parent then
            _lvObj                 = Instance.new("LinearVelocity")
            _lvObj.MaxForce        = 1e6
            _lvObj.RelativeTo      = Enum.ActuatorRelativeTo.World
            _lvObj.VectorVelocity  = Vector3.zero
            _lvObj.Attachment0     = _lvAttach
            _lvObj.Parent          = hrp
        end
        local dir = h.MoveDirection
        _lvObj.VectorVelocity = Vector3.new(dir.X, 0, dir.Z) * spd
    elseif method == "TranslateBy" then
        local c = Char()
        if c and h.MoveDirection.Magnitude > 0 then
            c:TranslateBy(h.MoveDirection * spd * dt)
        end
    end
end)

-- Infinite jump
UIS.JumpRequest:Connect(function()
    if AxiUI.Flags["AirWalk"] then
        _awH += 2
    elseif AxiUI.Flags["InfiniteJump"] then
        local h = Hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ── Physics ──────────────────────────────────────────────────
local BoxPhys = TabMove:AddGroupbox("Physics")

BoxPhys:AddToggle("NoClip", {
    Text    = "No Clip",
    Default = false,
    Tooltip = "Pass through all parts",
    Callback = function(on)
        if _noclipConn then _noclipConn:Disconnect(); _noclipConn = nil end
        if on then
            _noclipConn = RunService.Stepped:Connect(function()
                local c = Char(); if not c then return end
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end)
        else
            local c = Char(); if not c then return end
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end,
})

BoxPhys:AddToggle("NoFall", {
    Text    = "No Ragdoll",
    Default = false,
    Tooltip = "Disables ragdoll and falling-down states",
    Callback = function(on)
        local h = Hum(); if not h then return end
        pcall(function()
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not on)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     not on)
        end)
    end,
})

BoxPhys:AddToggle("AntiVoid", {
    Text    = "Anti-Void",
    Default = true,
    Tooltip = "Teleports you back if you fall below Y=-500",
})

-- Anti-void enforcement
RunService.Heartbeat:Connect(function()
    if not AxiUI.Flags["AntiVoid"] then return end
    local hrp = HRP(); if not hrp then return end
    if hrp.Position.Y < -500 then
        hrp.CFrame = CFrame.new(hrp.Position.X, 100, hrp.Position.Z)
    end
end)

-- ── SpinBot ──────────────────────────────────────────────────
local BoxSpin = TabMove:AddGroupbox("SpinBot")

BoxSpin:AddToggle("SpinBot", {
    Text    = "Spin Bot",
    Default = false,
})

BoxSpin:AddSlider("SpinSpeed", {
    Text     = "Spin Speed",
    Min      = 1,
    Max      = 60,
    Default  = 15,
    Rounding = false,
    Suffix   = " °/f",
})

RunService.Stepped:Connect(function()
    if not AxiUI.Flags["SpinBot"] then return end
    local hrp = HRP(); if not hrp then return end
    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(AxiUI.Flags["SpinSpeed"] or 15), 0)
end)

-- ── Flight ───────────────────────────────────────────────────
local BoxFly = TabMove:AddGroupbox("Flight")

BoxFly:AddToggle("Fly", {
    Text    = "Fly",
    Default = false,
    Tooltip = "WASD + Space (up) / LeftShift (down)",
    Callback = function(on)
        _cleanFly()
        if not on then return end
        local hrp = HRP(); if not hrp then return end
        _flyBV            = Instance.new("BodyVelocity", hrp)
        _flyBV.MaxForce   = Vector3.new(1e9, 1e9, 1e9)
        _flyBV.Velocity   = Vector3.zero
        _flyGyro          = Instance.new("BodyGyro", hrp)
        _flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        _flyGyro.P        = 9e4
        _flyGyro.CFrame   = hrp.CFrame
        _flyConn = RunService.RenderStepped:Connect(function()
            local hrp2 = HRP(); if not hrp2 or not _flyBV then return end
            local spd  = AxiUI.Flags["FlySpeed"] or 80
            local dir  = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W)         then dir += Camera.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)         then dir -= Camera.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)         then dir -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)         then dir += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
            _flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
            _flyGyro.CFrame = Camera.CFrame
        end)
    end,
})

BoxFly:AddSlider("FlySpeed", {
    Text     = "Fly Speed",
    Min      = 10,
    Max      = 500,
    Default  = 80,
    Rounding = false,
    Suffix   = " u/s",
})

-- ── AirWalk ──────────────────────────────────────────────────
local BoxAW = TabMove:AddGroupbox("Air Walk")

BoxAW:AddToggle("AirWalk", {
    Text    = "Air Walk",
    Default = false,
    Tooltip = "Invisible floor — Space to rise, LeftCtrl to lower",
    Callback = function(on)
        if not on then
            if _awPart then pcall(function() _awPart:Destroy() end); _awPart = nil end
            return
        end
        local hrp = HRP(); if not hrp then return end
        _awH  = hrp.Position.Y
        _awPart = Instance.new("Part")
        _awPart.Name        = "AxiAirWalk"
        _awPart.Size        = Vector3.new(50, 1, 50)
        _awPart.Transparency = 1
        _awPart.Anchored    = true
        _awPart.CanCollide  = false
        _awPart.Parent      = workspace
    end,
})

-- AirWalk floor tracking
RunService.RenderStepped:Connect(function()
    if not AxiUI.Flags["AirWalk"] or not _awPart then return end
    local hrp = HRP(); if not hrp then return end
    _awPart.CanCollide = true
    _awPart.CFrame = CFrame.new(hrp.Position.X, _awH - 2.8, hrp.Position.Z)
end)

-- ── Teleport ─────────────────────────────────────────────────
local BoxTele = TabMove:AddGroupbox("Teleport")

BoxTele:AddInput("TeleX", { Text = "X", Default = "0", Placeholder = "X", Numeric = true })
BoxTele:AddInput("TeleY", { Text = "Y", Default = "0", Placeholder = "Y", Numeric = true })
BoxTele:AddInput("TeleZ", { Text = "Z", Default = "0", Placeholder = "Z", Numeric = true })

BoxTele:AddButton({ Text = "Teleport to Coords", Callback = function()
    local hrp = HRP(); if not hrp then return end
    local x = tonumber(AxiUI.Flags["TeleX"]) or 0
    local y = tonumber(AxiUI.Flags["TeleY"]) or 0
    local z = tonumber(AxiUI.Flags["TeleZ"]) or 0
    hrp.CFrame = CFrame.new(x, y, z)
    AxiUI:Notify("Teleport", string.format("→ (%.0f, %.0f, %.0f)", x, y, z), 2)
end })

BoxTele:AddButton({ Text = "Teleport to Cursor", Callback = function()
    local hrp = HRP(); if not hrp then return end
    local ray = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 2000, RaycastParams.new())
    if ray then
        hrp.CFrame = CFrame.new(ray.Position + Vector3.new(0, 3, 0))
        AxiUI:Notify("Teleport", "Teleported to cursor", 2)
    else
        AxiUI:Notify("Teleport", "No surface found", 2)
    end
end })

BoxTele:AddToggle("ClickTP", {
    Text    = "Click TP  (LeftCtrl + LMB)",
    Default = false,
    Tooltip = "Hold LeftCtrl and click to teleport",
})

-- ── Global InputBegan handler ─────────────────────────────────
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end

    -- AirWalk descent
    if inp.KeyCode == Enum.KeyCode.LeftControl and AxiUI.Flags["AirWalk"] then
        _awH -= 2
        return
    end

    -- Click teleport (LeftCtrl + LMB)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
        and UIS:IsKeyDown(Enum.KeyCode.LeftControl)
        and AxiUI.Flags["ClickTP"] then
        local hrp = HRP(); if not hrp then return end
        local m = LP:GetMouse()
        if m.Hit then hrp.CFrame = CFrame.new(m.Hit.Position + Vector3.new(0, 3, 0)) end
        return
    end

    -- Cursor teleport keybind
    local tk = AxiUI.Flags["TeleportCursorKey"]
    if tk and inp.KeyCode == tk then
        local hrp = HRP(); if not hrp then return end
        local ray = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 2000, RaycastParams.new())
        if ray then hrp.CFrame = CFrame.new(ray.Position + Vector3.new(0, 3, 0)) end
    end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2 — ESP
-- ══════════════════════════════════════════════════════════════
local TabESP = Window:AddTab("ESP")

-- ── Drawing helpers ──────────────────────────────────────────
local _dummy = { Visible = false, Remove = function() end }
local function newLine(thick, col)
    if not HAS_DRAWING then return _dummy end
    local o = Drawing.new("Line"); o.Thickness=thick or 1.5; o.Color=col or Color3.new(1,1,1); o.Visible=false; return o
end
local function newSquare(filled, thick)
    if not HAS_DRAWING then return _dummy end
    local o = Drawing.new("Square"); o.Filled=filled; o.Thickness=thick or 1; o.Visible=false; return o
end
local function newText(sz)
    if not HAS_DRAWING then return _dummy end
    local o = Drawing.new("Text"); o.Size=sz or 13; o.Center=true; o.Outline=true; o.Visible=false; return o
end
local function newCircle(thick)
    if not HAS_DRAWING then return _dummy end
    local o = Drawing.new("Circle"); o.Thickness=thick or 1.5; o.Filled=false; o.Visible=false; return o
end

local CORNER_KEYS = {"TLH","TLV","TRH","TRV","BLH","BLV","BRH","BRV"}
local ALL_DRAW    = {"TLH","TLV","TRH","TRV","BLH","BLV","BRH","BRV","Box","BoxShadow","Name","Dist","HealthBG","HealthFill","HeadDot","Tracer"}

local function ESP_create(p)
    local d = {
        TLH=newLine(1.5), TLV=newLine(1.5), TRH=newLine(1.5), TRV=newLine(1.5),
        BLH=newLine(1.5), BLV=newLine(1.5), BRH=newLine(1.5), BRV=newLine(1.5),
        Box=newSquare(false,1), BoxShadow=newSquare(false,3),
        Name=newText(13), Dist=newText(11),
        HealthBG=newSquare(true,1), HealthFill=newSquare(true,1),
        HeadDot=newCircle(1.5), Tracer=newLine(1),
        Highlight=Instance.new("Highlight"),
    }
    d.BoxShadow.Color        = Color3.fromRGB(0,0,0)
    d.BoxShadow.Transparency = 0.55
    d.HealthBG.Color         = Color3.fromRGB(15,15,15)
    d.Dist.Color             = Color3.fromRGB(200,200,200)
    d.Highlight.Name         = "AxiESP_Cham"
    ESP_CACHE[p] = d
    return d
end

local function ESP_remove(p)
    local d = ESP_CACHE[p]; if not d then return end
    for _, k in ipairs(ALL_DRAW) do pcall(function() d[k]:Remove() end) end
    pcall(function() d.Highlight:Destroy() end)
    ESP_CACHE[p] = nil
end

local function ESP_hide(d)
    for _, k in ipairs(ALL_DRAW) do d[k].Visible = false end
    d.Highlight.Parent = nil
end

local function drawCorners(d, x, y, w, h, col, vis)
    local cl = math.max(5, math.floor(math.min(w,h)*0.22))
    local x2,y2 = x+w, y+h
    d.TLH.From=V2(x,y);   d.TLH.To=V2(x+cl,y)
    d.TLV.From=V2(x,y);   d.TLV.To=V2(x,y+cl)
    d.TRH.From=V2(x2,y);  d.TRH.To=V2(x2-cl,y)
    d.TRV.From=V2(x2,y);  d.TRV.To=V2(x2,y+cl)
    d.BLH.From=V2(x,y2);  d.BLH.To=V2(x+cl,y2)
    d.BLV.From=V2(x,y2);  d.BLV.To=V2(x,y2-cl)
    d.BRH.From=V2(x2,y2); d.BRH.To=V2(x2-cl,y2)
    d.BRV.From=V2(x2,y2); d.BRV.To=V2(x2,y2-cl)
    for _, k in ipairs(CORNER_KEYS) do d[k].Color=col; d[k].Visible=vis end
end

-- ── ESP controls ─────────────────────────────────────────────
local BoxESPMain = TabESP:AddGroupbox("Player ESP")

BoxESPMain:AddToggle("ESPEnabled", {
    Text    = "Enable ESP",
    Default = false,
    Callback = function(on)
        if not on then for p in pairs(ESP_CACHE) do ESP_remove(p) end end
    end,
})

BoxESPMain:AddToggle("TeamCheck", {
    Text    = "Team Check",
    Default = true,
    Tooltip = "Skip players on your team",
})

BoxESPMain:AddColorPicker("ESPColor", {
    Text    = "ESP Color",
    Default = Color3.fromRGB(255, 60, 60),
})

local BoxESPFeat = TabESP:AddGroupbox("Features")

BoxESPFeat:AddToggle("ESP_Box",     { Text = "Bounding Box",  Default = true  })
BoxESPFeat:AddDropdown("ESP_BoxStyle", {
    Text    = "Box Style",
    Items   = { "Corner", "Full" },
    Default = "Corner",
})
BoxESPFeat:AddToggle("ESP_Name",    { Text = "Names",         Default = true  })
BoxESPFeat:AddToggle("ESP_Health",  { Text = "Health Bar",    Default = true  })
BoxESPFeat:AddToggle("ESP_Dist",    { Text = "Distance",      Default = true  })
BoxESPFeat:AddToggle("ESP_HeadDot", { Text = "Head Dot",      Default = false })
BoxESPFeat:AddToggle("ESP_Tracer",  { Text = "Tracers",       Default = false })
BoxESPFeat:AddToggle("ESP_Cham",    { Text = "Chams",         Default = true  })

local BoxESPStyle = TabESP:AddGroupbox("Cham Style")
BoxESPStyle:AddSlider("ESP_ChamFill", {
    Text     = "Fill Transparency",
    Min      = 0, Max = 100, Default = 50,
    Rounding = false, Suffix = "%",
})
BoxESPStyle:AddSlider("ESP_ChamOutline", {
    Text     = "Outline Transparency",
    Min      = 0, Max = 100, Default = 0,
    Rounding = false, Suffix = "%",
})

-- ── ESP render loop ───────────────────────────────────────────
local function isTeammate(p)
    if not AxiUI.Flags["TeamCheck"] then return false end
    -- Only flag as teammate when both players have a real Team object assigned
    -- Falling back to TeamColor would match everyone in games without a team system
    local mt, pt = LP.Team, p.Team
    if mt ~= nil and pt ~= nil then return mt == pt end
    -- If LP is assigned to a team but target isn't (or vice versa), they're enemies
    return false
end

RunService.RenderStepped:Connect(function()
    if not AxiUI.Flags["ESPEnabled"] then return end
    local camPos   = Camera.CFrame.Position
    local vp       = Camera.ViewportSize
    local snapPt   = V2(vp.X * 0.5, vp.Y)
    local col      = AxiUI.Flags["ESPColor"] or Color3.fromRGB(255,60,60)
    local isCorner = AxiUI.Flags["ESP_BoxStyle"] ~= "Full"

    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        if isTeammate(p) then ESP_remove(p); continue end

        local char = p.Character
        local head  = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
        local hrp2  = char and char:FindFirstChild("HumanoidRootPart")
        local hum2  = char and char:FindFirstChildOfClass("Humanoid")
        if not (head and hum2 and hum2.Health > 0) then ESP_remove(p); continue end

        local headVP, onScreen = Camera:WorldToViewportPoint(head.Position)
        local d = ESP_CACHE[p] or ESP_create(p)
        if not onScreen then ESP_hide(d); continue end

        local hrpPos = hrp2 and hrp2.Position or head.Position
        local topVP  = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.75, 0))
        local botVP  = Camera:WorldToViewportPoint(hrpPos - Vector3.new(0, hum2.HipHeight + 0.1, 0))
        local bTop   = math.min(topVP.Y, botVP.Y)
        local bBot   = math.max(topVP.Y, botVP.Y)
        local bH     = math.max(bBot - bTop, 10)
        local bW     = bH / 1.75
        local bX     = headVP.X - bW * 0.5
        local dist3D = (head.Position - camPos).Magnitude

        -- Box
        local boxOn = AxiUI.Flags["ESP_Box"] == true
        drawCorners(d, bX, bTop, bW, bH, col, boxOn and isCorner)
        d.BoxShadow.Position = V2(bX-1, bTop-1); d.BoxShadow.Size = V2(bW+2, bH+2)
        d.BoxShadow.Visible  = boxOn and not isCorner
        d.Box.Position = V2(bX, bTop); d.Box.Size = V2(bW, bH)
        d.Box.Color = col; d.Box.Visible = boxOn and not isCorner

        -- Head dot
        d.HeadDot.Visible = AxiUI.Flags["ESP_HeadDot"] == true
        if d.HeadDot.Visible then
            d.HeadDot.Position = V2(headVP.X, headVP.Y)
            d.HeadDot.Radius   = math.max(math.floor(bW * 0.13), 3)
            d.HeadDot.Color    = col
        end

        -- Name
        d.Name.Visible = AxiUI.Flags["ESP_Name"] == true
        if d.Name.Visible then
            d.Name.Text     = p.DisplayName ~= p.Name
                and (p.DisplayName.." ["..p.Name.."]") or p.Name
            d.Name.Position = V2(headVP.X, bTop - 15)
            d.Name.Color    = col
        end

        -- Distance
        d.Dist.Visible = AxiUI.Flags["ESP_Dist"] == true
        if d.Dist.Visible then
            d.Dist.Text     = string.format("%d m", math.floor(dist3D))
            d.Dist.Position = V2(headVP.X, bBot + 3)
        end

        -- Health bar
        d.HealthBG.Visible   = AxiUI.Flags["ESP_Health"] == true
        d.HealthFill.Visible = AxiUI.Flags["ESP_Health"] == true
        if d.HealthBG.Visible then
            local frac  = math.clamp(hum2.Health / math.max(hum2.MaxHealth, 1), 0, 1)
            local fillH = math.max(math.floor(bH * frac), 1)
            local bX2   = bX - 5
            d.HealthBG.Position   = V2(bX2, bTop)
            d.HealthBG.Size       = V2(3, bH)
            d.HealthFill.Position = V2(bX2, bTop + bH - fillH)
            d.HealthFill.Size     = V2(3, fillH)
            d.HealthFill.Color    = Color3.fromRGB(
                math.floor((1-frac)*255), math.floor(frac*200+30), 30)
        end

        -- Tracer
        d.Tracer.Visible = AxiUI.Flags["ESP_Tracer"] == true
        if d.Tracer.Visible then
            d.Tracer.From  = snapPt
            d.Tracer.To    = V2(headVP.X, bBot)
            d.Tracer.Color = col
        end

        -- Chams
        if AxiUI.Flags["ESP_Cham"] then
            d.Highlight.FillColor           = col
            d.Highlight.OutlineColor        = Color3.fromRGB(0,0,0)
            d.Highlight.FillTransparency    = (AxiUI.Flags["ESP_ChamFill"] or 50) / 100
            d.Highlight.OutlineTransparency = (AxiUI.Flags["ESP_ChamOutline"] or 0) / 100
            d.Highlight.Parent              = char
        else
            d.Highlight.Parent = nil
        end
    end
end)

Players.PlayerRemoving:Connect(ESP_remove)

-- ══════════════════════════════════════════════════════════════
--  TAB 3 — WORLD
-- ══════════════════════════════════════════════════════════════
local TabWorld = Window:AddTab("World")

local BoxWorld = TabWorld:AddGroupbox("Workspace")

BoxWorld:AddSlider("Gravity", {
    Text = "Gravity", Min = 0, Max = 300, Default = 196,
    Rounding = false, Suffix = " u/s²",
    Callback = function(v) workspace.Gravity = v end,
})

BoxWorld:AddSlider("FogEnd", {
    Text = "Fog Distance", Min = 100, Max = 10000, Default = 10000,
    Rounding = false, Suffix = " st",
    Callback = function(v) Lighting.FogEnd = v end,
})

BoxWorld:AddToggle("Fullbright", {
    Text    = "Fullbright",
    Default = false,
    Callback = function(on)
        Lighting.Ambient        = on and Color3.new(1,1,1) or Color3.new(0,0,0)
        Lighting.OutdoorAmbient = on and Color3.new(1,1,1) or Color3.fromRGB(127,127,127)
        Lighting.Brightness     = on and 10 or 2
        Lighting.GlobalShadows  = not on
    end,
})

BoxWorld:AddToggle("NoFog", {
    Text    = "No Fog",
    Default = false,
    Callback = function(on)
        Lighting.FogEnd = on and 1e6 or (AxiUI.Flags["FogEnd"] or 10000)
    end,
})

BoxWorld:AddDivider()

BoxWorld:AddButton({ Text = "Reset Workspace", Callback = function()
    workspace.Gravity = 196
    Lighting.Ambient = Color3.new(0,0,0)
    Lighting.OutdoorAmbient = Color3.fromRGB(127,127,127)
    Lighting.Brightness = 2; Lighting.GlobalShadows = true; Lighting.FogEnd = 10000
    AxiUI.Flags["Gravity_obj"].Set(196)
    AxiUI.Flags["FogEnd_obj"].Set(10000)
    AxiUI.Flags["Fullbright_obj"].Set(false)
    AxiUI.Flags["NoFog_obj"].Set(false)
    AxiUI:Notify("World", "Workspace reset", 2)
end })

local BoxTime = TabWorld:AddGroupbox("Time of Day")

BoxTime:AddSlider("TimeOfDay", {
    Text = "Hour", Min = 0, Max = 24, Default = 14,
    Rounding = false, Suffix = "h",
    Callback = function(v) Lighting:SetMinutesAfterMidnight(v * 60) end,
})

BoxTime:AddButton({ Text = "Day",    Callback = function() AxiUI.Flags["TimeOfDay_obj"].Set(14) end })
BoxTime:AddButton({ Text = "Sunset", Callback = function() AxiUI.Flags["TimeOfDay_obj"].Set(18) end })
BoxTime:AddButton({ Text = "Night",  Callback = function() AxiUI.Flags["TimeOfDay_obj"].Set(0)  end })

-- ══════════════════════════════════════════════════════════════
--  TAB 4 — SETTINGS
-- ══════════════════════════════════════════════════════════════
local TabSettings = Window:AddTab("Settings")

ThemeManager:ApplyToTab(TabSettings)

local BoxWM = TabSettings:AddGroupbox("Watermark")
BoxWM:AddToggle("WatermarkEnabled", {
    Text    = "Show Watermark",
    Default = true,
    Callback = function(on) Watermark:SetVisible(on) end,
})
BoxWM:AddInput("WatermarkText", {
    Text = "Watermark Text", Default = "Universal", Placeholder = "text",
    Callback = function(v) Watermark:Set(v) end,
})

local BoxKB = TabSettings:AddGroupbox("Keybinds")
BoxKB:AddKeybind("TeleportCursorKey", {
    Text    = "Teleport to Cursor",
    Default = Enum.KeyCode.T,
})

local BoxCfg = TabSettings:AddGroupbox("Config")
BoxCfg:AddInput("CfgName", {
    Text = "Profile Name", Default = "default", Placeholder = "config name",
})
BoxCfg:AddButton({ Text = "Save Config", Callback = function()
    SaveManager:SetFolder("AxiUI_Universal")
    local name = AxiUI.Flags["CfgName"] or "default"
    local ok = SaveManager:Save(name)
    AxiUI:Notify("Config", ok and ("Saved: "..name) or "Save failed", 3)
end })
BoxCfg:AddButton({ Text = "Load Config", Callback = function()
    SaveManager:SetFolder("AxiUI_Universal")
    local name = AxiUI.Flags["CfgName"] or "default"
    local ok = SaveManager:Load(name)
    AxiUI:Notify("Config", ok and ("Loaded: "..name) or "Not found", 3)
end })

-- ══════════════════════════════════════════════════════════════
--  WATERMARK + KEYBIND OVERLAY
-- ══════════════════════════════════════════════════════════════
Watermark:Set("Universal")
Watermark:SetVisible(true)
KeybindOverlay:Register("Toggle Menu",  Enum.KeyCode.RightShift)
KeybindOverlay:Register("Tele Cursor",  Enum.KeyCode.T)
KeybindOverlay:SetVisible(true)

-- ══════════════════════════════════════════════════════════════
--  CHARACTER LIFECYCLE — restore states on respawn
-- ══════════════════════════════════════════════════════════════
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    Camera = workspace.CurrentCamera

    -- NoFall
    if AxiUI.Flags["NoFall"] then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then pcall(function()
            h:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            h:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     false)
        end) end
    end

    -- Fly (re-attach physics to new HRP)
    if AxiUI.Flags["Fly"] then
        local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
        _cleanFly()
        _flyBV            = Instance.new("BodyVelocity", hrp)
        _flyBV.MaxForce   = Vector3.new(1e9, 1e9, 1e9)
        _flyBV.Velocity   = Vector3.zero
        _flyGyro          = Instance.new("BodyGyro", hrp)
        _flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        _flyGyro.P        = 9e4
        _flyGyro.CFrame   = hrp.CFrame
        _flyConn = RunService.RenderStepped:Connect(function()
            local hrp2 = HRP(); if not hrp2 or not _flyBV then return end
            local spd  = AxiUI.Flags["FlySpeed"] or 80
            local dir  = Vector3.zero
            if UIS:IsKeyDown(Enum.KeyCode.W)         then dir += Camera.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.S)         then dir -= Camera.CFrame.LookVector  end
            if UIS:IsKeyDown(Enum.KeyCode.A)         then dir -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D)         then dir += Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end
            _flyBV.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
            _flyGyro.CFrame = Camera.CFrame
        end)
    end
end)

-- ══════════════════════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════════════════════
task.delay(0.5, function()
    AxiUI:Notify("Universal", "Loaded — RightShift to toggle", 4)
end)
