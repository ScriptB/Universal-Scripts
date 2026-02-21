-- Universal ESP Pro Enhanced v3.6 (No Silent Aim)
-- UI: LinoriaLib | Full ESP | Config System
-- Loadstring: loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/Examples/Universal_ESP_Pro_Enhanced_v3.6_NoSilent.lua", true))()

repeat task.wait() until game:IsLoaded()

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Camera      = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ══════════════════════════════════════════
-- LOAD LINORIA UI LIBRARY
-- ══════════════════════════════════════════
local repo = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua", true))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua", true))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua", true))()

-- ══════════════════════════════════════════
-- ESP SETTINGS
-- ══════════════════════════════════════════
local Settings = {
    Enabled   = true,
    TeamCheck = false,
    TeamColor = false,
    MaxDist   = 1000,
    Box = {
        Enabled   = true,
        Color     = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
    },
    Tracer = {
        Enabled   = true,
        Color     = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Origin    = "Bottom",
    },
    Name = {
        Enabled      = true,
        Color        = Color3.fromRGB(255, 255, 255),
        Size         = 14,
        ShowDistance = true,
        ShowHealth   = false,
        Outline      = true,
    },
    Health = {
        Enabled   = true,
        ShowBar   = true,
        ShowText  = false,
        Thickness = 3,
    },
    Rainbow = {
        Enabled = false,
        Speed   = 1,
    },
}

-- ══════════════════════════════════════════
-- CONFIG SYSTEM
-- ══════════════════════════════════════════
local CONFIG_FILE = "UniversalESP_Config.json"

local function SerializeColor(c)
    return { R = c.R, G = c.G, B = c.B }
end
local function DeserializeColor(d)
    return Color3.new(d.R, d.G, d.B)
end
local function DeepSerialize(t)
    local o = {}
    for k, v in pairs(t) do
        if typeof(v) == "Color3" then
            o[k] = SerializeColor(v)
        elseif type(v) == "table" then
            o[k] = DeepSerialize(v)
        else
            o[k] = v
        end
    end
    return o
end
local function DeepDeserialize(t)
    local o = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            if v.R ~= nil and v.G ~= nil and v.B ~= nil then
                o[k] = DeserializeColor(v)
            else
                o[k] = DeepDeserialize(v)
            end
        else
            o[k] = v
        end
    end
    return o
end

local function Notify(title, content, duration)
    Library:Notify(title .. "\n" .. content, duration or 4)
end

local function SaveConfig()
    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(DeepSerialize(Settings)))
    end)
    if ok then
        print("[ESP] Config saved.")
        Notify("Config Saved", "Written to " .. CONFIG_FILE, 3)
    else
        warn("[ESP] Save failed: " .. tostring(err))
        Notify("Save Failed", tostring(err), 5)
    end
end

local function LoadConfig()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if ok and data then
        local loaded = DeepDeserialize(data)
        for k, v in pairs(loaded) do
            if Settings[k] ~= nil then
                if type(v) == "table" and type(Settings[k]) == "table" then
                    for sk, sv in pairs(v) do
                        Settings[k][sk] = sv
                    end
                else
                    Settings[k] = v
                end
            end
        end
        print("[ESP] Config loaded.")
        Notify("Config Loaded", "Restored from " .. CONFIG_FILE, 3)
    else
        Notify("No Config Found", "Save a config first.", 4)
    end
end

-- ══════════════════════════════════════════
-- SILENT AIM SETTINGS
-- ══════════════════════════════════════════
local SilentAimSettings = {
    Enabled = false,
    HitPart = "Head",
    TeamCheck = false,
    ShowTargetLine = true,
    TargetLineColor = Color3.fromRGB(0, 255, 0),
    Method = "All",
    HitChance = 100
}

-- Silent Aim State
local SilentAimState = {
    Target = nil,
    TargetPart = nil,
}

-- Hit Chance Calculation
local function CalculateChance(Percentage)
    -- Floor the percentage
    Percentage = math.floor(Percentage)
    
    -- Get the chance
    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
    
    -- Return
    return chance <= Percentage / 100
end

-- Expected Arguments for validation
local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

-- Validate Arguments Function
local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

-- Get Direction Function
local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

-- ══════════════════════════════════════════
-- AIMBOT SETTINGS
-- ══════════════════════════════════════════
local AimbotSettings = {
    Enabled      = false,
    Mode         = "Mouse (1st Person)", -- "Camera (3rd Person)" or "Mouse (1st Person)"
    FOV          = 150,
    Smoothness   = 10,
    Sensitivity  = 0.5,
    HitPart      = "Head",
    TeamCheck    = true,
    ShowFOV      = true,
    FOVColor     = Color3.fromRGB(255, 255, 255),
    Keybind      = "RightMouseButton",
}

-- ══════════════════════════════════════════
-- SERVICES
-- ══════════════════════════════════════════
local UserInputService = game:GetService("UserInputService")

-- ══════════════════════════════════════════
-- ESP CORE
-- ══════════════════════════════════════════
local ESPObjects = {}

local function GetColor(player, default)
    if Settings.Rainbow.Enabled then
        return Color3.fromHSV((tick() * Settings.Rainbow.Speed) % 1, 1, 1)
    end
    if Settings.TeamColor and player.Team then
        return player.TeamColor.Color
    end
    return default
end

local function NewDrawing(class, props)
    local ok, obj = pcall(Drawing.new, class)
    if not ok then
        return { Visible = false, Remove = function() end }
    end
    for k, v in pairs(props) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

local function HideESP(e)
    for _, l in ipairs(e.Boxes) do l.Visible = false end
    e.Tracer.Visible  = false
    e.Name.Visible    = false
    e.HpBg.Visible    = false
    e.HpBar.Visible   = false
    e.HpText.Visible  = false
end

local function CreateESP(player)
    if ESPObjects[player] then return end
    local e = {
        Player = player,
        Boxes = {
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
            NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
        },
        Tracer = NewDrawing("Line", { Thickness = 1, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
        Name   = NewDrawing("Text", { Text = player.Name, Size = 14, Center = true, Outline = true, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
        HpBg   = NewDrawing("Line", { Thickness = 4, Color = Color3.new(0,0,0), Transparency = 0.5, Visible = false }),
        HpBar  = NewDrawing("Line", { Thickness = 3, Color = Color3.new(0,1,0), Transparency = 1, Visible = false }),
        HpText = NewDrawing("Text", { Text = "100hp", Size = 11, Center = true, Outline = true, Color = Color3.new(1,1,1), Transparency = 1, Visible = false }),
    }
    ESPObjects[player] = e
end

local function RemoveESP(player)
    local e = ESPObjects[player]
    if not e then return end
    for _, l in ipairs(e.Boxes) do pcall(function() l:Remove() end) end
    pcall(function() e.Tracer:Remove() end)
    pcall(function() e.Name:Remove() end)
    pcall(function() e.HpBg:Remove() end)
    pcall(function() e.HpBar:Remove() end)
    pcall(function() e.HpText:Remove() end)
    ESPObjects[player] = nil
end

local function UpdateESP(e)
    local player = e.Player
    local char   = player.Character
    if not char then HideESP(e); return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp then HideESP(e); return end

    local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
    if dist > Settings.MaxDist then HideESP(e); return end
    if Settings.TeamCheck and player.Team == LocalPlayer.Team then HideESP(e); return end

    local rv, onScreen = Camera:WorldToViewportPoint(hrp.Position)
    if not onScreen then HideESP(e); return end

    local sf = 1 / rv.Z
    local w  = math.clamp(35 * sf * 100, 20, 200)
    local h  = math.clamp(55 * sf * 100, 30, 300)
    local cx, cy = rv.X, rv.Y

    local tl = Vector2.new(cx - w/2, cy - h/2)
    local tr = Vector2.new(cx + w/2, cy - h/2)
    local bl = Vector2.new(cx - w/2, cy + h/2)
    local br = Vector2.new(cx + w/2, cy + h/2)

    local bc = GetColor(player, Settings.Box.Color)
    local bv = Settings.Enabled and Settings.Box.Enabled
    local bt = Settings.Box.Thickness
    e.Boxes[1].From = tl; e.Boxes[1].To = tr; e.Boxes[1].Color = bc; e.Boxes[1].Thickness = bt; e.Boxes[1].Visible = bv
    e.Boxes[2].From = tr; e.Boxes[2].To = br; e.Boxes[2].Color = bc; e.Boxes[2].Thickness = bt; e.Boxes[2].Visible = bv
    e.Boxes[3].From = br; e.Boxes[3].To = bl; e.Boxes[3].Color = bc; e.Boxes[3].Thickness = bt; e.Boxes[3].Visible = bv
    e.Boxes[4].From = bl; e.Boxes[4].To = tl; e.Boxes[4].Color = bc; e.Boxes[4].Thickness = bt; e.Boxes[4].Visible = bv

    local tOrigin
    if Settings.Tracer.Origin == "Top" then
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, 0)
    elseif Settings.Tracer.Origin == "Center" then
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        tOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    end
    e.Tracer.From      = tOrigin
    e.Tracer.To        = Vector2.new(cx, cy + h/2)
    e.Tracer.Color     = GetColor(player, Settings.Tracer.Color)
    e.Tracer.Thickness = Settings.Tracer.Thickness
    e.Tracer.Visible   = Settings.Enabled and Settings.Tracer.Enabled

    local nameStr = player.Name
    if Settings.Name.ShowDistance then nameStr = nameStr .. " [" .. math.floor(dist) .. "m]" end
    if Settings.Name.ShowHealth and hum then nameStr = nameStr .. " [" .. math.floor(hum.Health) .. "hp]" end
    e.Name.Text     = nameStr
    e.Name.Size     = Settings.Name.Size
    e.Name.Color    = GetColor(player, Settings.Name.Color)
    e.Name.Outline  = Settings.Name.Outline
    e.Name.Position = Vector2.new(cx, tl.Y - Settings.Name.Size - 2)
    e.Name.Visible  = Settings.Enabled and Settings.Name.Enabled

    if hum and Settings.Health.Enabled and Settings.Health.ShowBar then
        local ratio  = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
        local bx     = tl.X - 6
        local hColor = Color3.fromRGB(math.floor(255 * (1 - ratio)), math.floor(255 * ratio), 0)
        e.HpBg.From       = Vector2.new(bx, tl.Y)
        e.HpBg.To         = Vector2.new(bx, bl.Y)
        e.HpBg.Thickness  = Settings.Health.Thickness + 1
        e.HpBg.Visible    = Settings.Enabled
        e.HpBar.From      = Vector2.new(bx, bl.Y - (bl.Y - tl.Y) * ratio)
        e.HpBar.To        = Vector2.new(bx, bl.Y)
        e.HpBar.Color     = hColor
        e.HpBar.Thickness = Settings.Health.Thickness
        e.HpBar.Visible   = Settings.Enabled
        if Settings.Health.ShowText then
            e.HpText.Text     = math.floor(hum.Health) .. "hp"
            e.HpText.Position = Vector2.new(bx, tl.Y - 12)
            e.HpText.Visible  = Settings.Enabled
        else
            e.HpText.Visible = false
        end
    else
        e.HpBg.Visible   = false
        e.HpBar.Visible  = false
        e.HpText.Visible = false
    end
end

-- ══════════════════════════════════════════
-- SILENT AIM FUNCTIONS
-- ══════════════════════════════════════════

-- Get closest player to cursor within Silent Aim FOV
local function GetClosestSilentTarget()
    local mouseLoc = UserInputService:GetMouseLocation()
    local bestDist = AimbotSettings.FOV
    local bestChar = nil
    local bestPart = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if SilentAimSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        local char = player.Character
        if not char then continue end

        local part = char:FindFirstChild(SilentAimSettings.HitPart)
            or char:FindFirstChild("HumanoidRootPart")
            or char:FindFirstChild("Torso")
            or char:FindFirstChild("UpperTorso")
            or char:FindFirstChild("Head")
        if not part then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local sv, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local screenPos = Vector2.new(sv.X, sv.Y)
        local dist = (screenPos - mouseLoc).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestChar = char
            bestPart = part
        end
    end
    return bestPart, bestChar
end

-- Check if Silent Aim should be active
local function canUseSilentAim()
    return SilentAimSettings.Enabled and SilentAimState.Target and SilentAimState.TargetPart
end

-- ══════════════════════════════════════════
-- SILENT AIM HOOKS
-- ══════════════════════════════════════════

local oldNamecall
local oldIndex

-- Hook __namecall for RCL and Modern gun systems
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    local chance = CalculateChance(SilentAimSettings.HitChance)
    
    -- Only intercept calls from the game when we have a valid target and hit chance succeeds
    if not checkcaller() and SilentAimSettings.Enabled and SilentAimState.TargetPart and chance then
        local methodEnabled = SilentAimSettings.Method == "All"
        
        -- Hook FindPartOnRayWithIgnoreList (RCL guns)
        if method == "FindPartOnRayWithIgnoreList" and self == workspace and (methodEnabled or SilentAimSettings.Method == "RCL") then
            if ValidateArguments(args, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local ray = args[1] -- Ray is first argument after self
                if ray and typeof(ray) == "Ray" then
                    -- Redirect ray to target
                    local origin = ray.Origin
                    local direction = getDirection(origin, SilentAimState.TargetPart.Position)
                    args[1] = Ray.new(origin, direction)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        
        -- Hook FindPartOnRayWithWhitelist (RCL guns)
        if method == "FindPartOnRayWithWhitelist" and self == workspace and (methodEnabled or SilentAimSettings.Method == "RCL") then
            if ValidateArguments(args, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local ray = args[1]
                if ray and typeof(ray) == "Ray" then
                    -- Redirect ray to target
                    local origin = ray.Origin
                    local direction = getDirection(origin, SilentAimState.TargetPart.Position)
                    args[1] = Ray.new(origin, direction)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        
        -- Hook FindPartOnRay (RCL guns)  
        if (method == "FindPartOnRay" or method == "findPartOnRay") and self == workspace and (methodEnabled or SilentAimSettings.Method == "RCL") then
            if ValidateArguments(args, ExpectedArguments.FindPartOnRay) then
                local ray = args[1]
                if ray and typeof(ray) == "Ray" then
                    -- Redirect ray to target
                    local origin = ray.Origin
                    local direction = getDirection(origin, SilentAimState.TargetPart.Position)
                    args[1] = Ray.new(origin, direction)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        
        -- Hook Raycast (Modern guns)
        if method == "Raycast" and self == workspace and (methodEnabled or SilentAimSettings.Method == "Modern") then
            if ValidateArguments(args, ExpectedArguments.Raycast) then
                local origin = args[1]
                if origin and typeof(origin) == "Vector3" then
                    -- Redirect direction to target
                    args[2] = getDirection(origin, SilentAimState.TargetPart.Position)
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        
        -- Hook RemoteEvent FireServer (RemoteEvent guns)
        if method == "FireServer" and self:IsA("RemoteEvent") and (methodEnabled or SilentAimSettings.Method == "RemoteEvent") then
            -- Check if any argument looks like shooting direction or position
            for i, arg in ipairs(args) do
                if typeof(arg) == "Vector3" then
                    -- Replace Vector3 arguments with target position or direction
                    args[i] = SilentAimState.TargetPart.Position
                elseif typeof(arg) == "Instance" and arg:IsA("BasePart") then
                    -- Replace BasePart arguments with target part
                    args[i] = SilentAimState.TargetPart
                elseif typeof(arg) == "table" then
                    -- Handle table arguments (common in modern games)
                    for j, tableArg in ipairs(arg) do
                        if typeof(tableArg) == "Vector3" then
                            arg[j] = SilentAimState.TargetPart.Position
                            break
                        elseif typeof(tableArg) == "Instance" and tableArg:IsA("BasePart") then
                            arg[j] = SilentAimState.TargetPart
                            break
                        end
                    end
                end
            end
        end
    end
    
    return oldNamecall(self, unpack(args))
end))

-- Hook __index for Mouse.Hit/Target (Old guns)
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, key)
    -- Only intercept Mouse calls when we have a valid target and hit chance succeeds
    if not checkcaller() and self:IsA("Mouse") and SilentAimSettings.Enabled and SilentAimState.TargetPart and CalculateChance(SilentAimSettings.HitChance) then
        local methodEnabled = SilentAimSettings.Method == "All" or SilentAimSettings.Method == "Old"
        
        if methodEnabled then
            if key == "Hit" or key == "hit" then
                -- Use prediction if enabled (future enhancement)
                return SilentAimState.TargetPart.CFrame
            elseif key == "Target" or key == "target" then
                return SilentAimState.TargetPart
            elseif key == "X" or key == "x" then
                local targetPos = Camera:WorldToViewportPoint(SilentAimState.TargetPart.Position)
                return targetPos.X
            elseif key == "Y" or key == "y" then
                local targetPos = Camera:WorldToViewportPoint(SilentAimState.TargetPart.Position)
                return targetPos.Y
            elseif key == "UnitRay" then
                -- Support for Mouse.UnitRay (common in old gun systems)
                local targetPos = SilentAimState.TargetPart.Position
                local origin = Camera.CFrame.Position
                return Ray.new(origin, (targetPos - origin).Unit)
            end
        end
    end
    return oldIndex(self, key)
end))

-- ══════════════════════════════════════════
-- AIMBOT CORE
-- ══════════════════════════════════════════

local FovCircle = NewDrawing("Circle", {
    Thickness    = 1,
    Color        = Color3.fromRGB(255, 255, 255),
    Transparency = 1,
    Filled       = false,
    Visible      = false,
})

local TargetLine = NewDrawing("Line", {
    Thickness    = 2,
    Color        = Color3.fromRGB(0, 255, 0),
    Transparency = 1,
    Visible      = false,
})

local function getBestBodyPart(char)
    return char:FindFirstChild(AimbotSettings.HitPart)
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Head")
end

-- Function to get camera-compensated crosshair position
-- Based on forum research: https://devforum.roblox.com/t/unusual-worldtoviewportpoint-behavior/3309800
local function getCameraCompensatedCenter()
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local guiInset = game:GetService("GuiService"):GetGuiInset()
    screenCenter = screenCenter - (guiInset / 2)
    
    -- For third person, create a virtual raycast point that compensates for camera displacement
    if AimbotSettings.Mode ~= "Mouse (1st Person)" then
        -- Get mouse ray from camera (forum solution: use camera origin with mouse direction)
        local mouse = game.Players.LocalPlayer:GetMouse()
        local unitRay = Camera:ScreenPointToRay(mouse.X, mouse.Y)
        
        -- Cast ray to find where camera would actually hit
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
        
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
        if result then
            -- Convert hit point back to screen coordinates
            local hitScreenPos, onScreen = Camera:WorldToViewportPoint(result.Position)
            if onScreen then
                return Vector2.new(hitScreenPos.X, hitScreenPos.Y)
            end
        end
        
        -- Fallback: use mouse position directly (most reliable for third person)
        return Vector2.new(mouse.X, mouse.Y)
    end
    
    -- For first person, use screen center
    return screenCenter
end

local function GetClosestTarget()
    -- Use camera-compensated center for both FOV and targeting consistency
    local center = getCameraCompensatedCenter()
    
    local bestDist = AimbotSettings.FOV
    local bestChar = nil
    local bestPart = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if AimbotSettings.TeamCheck and player.Team == LocalPlayer.Team then continue end
        local char = player.Character
        if not char then continue end
        
        local part = getBestBodyPart(char)
        if not part then continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        
        local sv, onScreen = Camera:WorldToViewportPoint(part.Position)
        if not onScreen then continue end
        
        local screenPos = Vector2.new(sv.X, sv.Y)
        local dist = (screenPos - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestChar = char
            bestPart = part
        end
    end
    return bestPart, bestChar, center
end

-- ══════════════════════════════════════════
-- BUILD LINORIA UI
-- ══════════════════════════════════════════
local Window = Library:CreateWindow({
    Title        = "Universal ESP Pro Enhanced",
    Center       = true,
    AutoShow     = true,
    TabPadding   = 10,
    MenuFadeTime = 0.35,
})

local Tabs = {
    ESP     = Window:AddTab("ESP"),
    Aimbot  = Window:AddTab("Aimbot"),
    Visuals = Window:AddTab("Visuals"),
    Config  = Window:AddTab("Config"),
    UI      = Window:AddTab("UI Settings"),
}

-- ══════════════════════════════════════════
-- TAB: ESP
-- ══════════════════════════════════════════

-- LEFT: General + Box + Health
local GbMaster = Tabs.ESP:AddLeftGroupbox("General")
GbMaster:AddToggle("ESPEnabled", {
    Text    = "ESP Enabled",
    Default = Settings.Enabled,
    Tooltip = "Master switch — turns off all ESP rendering",
})
GbMaster:AddLabel("Toggle Keybind"):AddKeyPicker("ESPKeybind", {
    Default         = "RightShift",
    SyncToggleState = true,
    Mode            = "Toggle",
    Text            = "ESP On/Off",
    Tooltip         = "Keybind synced to the ESP Enabled toggle",
})
GbMaster:AddDivider()
GbMaster:AddToggle("TeamCheck", {
    Text    = "Team Check",
    Default = Settings.TeamCheck,
    Tooltip = "Skip ESP for players on your team",
})
GbMaster:AddToggle("TeamColor", {
    Text    = "Team Color",
    Default = Settings.TeamColor,
    Tooltip = "Use each player's team color instead of custom colors",
})
GbMaster:AddDivider()
GbMaster:AddSlider("MaxDist", {
    Text     = "Max Distance",
    Default  = Settings.MaxDist,
    Min      = 100,
    Max      = 5000,
    Rounding = 0,
    Suffix   = " st",
    Compact  = false,
    Tooltip  = "ESP hidden beyond this distance",
})

local GbBox = Tabs.ESP:AddLeftGroupbox("Box")
GbBox:AddToggle("BoxEnabled", {
    Text    = "Enabled",
    Default = Settings.Box.Enabled,
    Tooltip = "Bounding box around each player",
})
local DepBox = GbBox:AddDependencyBox()
DepBox:AddSlider("BoxThickness", {
    Text     = "Thickness",
    Default  = Settings.Box.Thickness,
    Min      = 1,
    Max      = 5,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Box line thickness",
})
DepBox:AddLabel("Color"):AddColorPicker("BoxColor", {
    Default = Settings.Box.Color,
    Title   = "Box Color",
})
DepBox:SetupDependencies({ { Toggles.BoxEnabled, true } })

local GbHealth = Tabs.ESP:AddLeftGroupbox("Health Bar")
GbHealth:AddToggle("HealthEnabled", {
    Text    = "Enabled",
    Default = Settings.Health.Enabled,
    Tooltip = "Side health bar for each player",
})
local DepHealth = GbHealth:AddDependencyBox()
DepHealth:AddToggle("HealthText", {
    Text    = "Show HP Number",
    Default = Settings.Health.ShowText,
    Tooltip = "Show numeric HP above the bar",
})
DepHealth:AddSlider("HealthThickness", {
    Text     = "Thickness",
    Default  = Settings.Health.Thickness,
    Min      = 1,
    Max      = 6,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Health bar line thickness",
})
DepHealth:SetupDependencies({ { Toggles.HealthEnabled, true } })

-- RIGHT: Tracer + Name
local GbTracer = Tabs.ESP:AddRightGroupbox("Tracer")
GbTracer:AddToggle("TracerEnabled", {
    Text    = "Enabled",
    Default = Settings.Tracer.Enabled,
    Tooltip = "Line from screen edge to each player",
})
local DepTracer = GbTracer:AddDependencyBox()
DepTracer:AddDropdown("TracerOrigin", {
    Values  = { "Bottom", "Center", "Top" },
    Default = 1,
    Text    = "Origin Point",
    Tooltip = "Where the tracer starts on screen",
})
DepTracer:AddSlider("TracerThickness", {
    Text     = "Thickness",
    Default  = Settings.Tracer.Thickness,
    Min      = 1,
    Max      = 5,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Tracer line thickness",
})
DepTracer:AddLabel("Color"):AddColorPicker("TracerColor", {
    Default = Settings.Tracer.Color,
    Title   = "Tracer Color",
})
DepTracer:SetupDependencies({ { Toggles.TracerEnabled, true } })

local GbName = Tabs.ESP:AddRightGroupbox("Name Label")
GbName:AddToggle("NameEnabled", {
    Text    = "Enabled",
    Default = Settings.Name.Enabled,
    Tooltip = "Player name above their character",
})
local DepName = GbName:AddDependencyBox()
DepName:AddToggle("ShowDistance", {
    Text    = "Distance",
    Default = Settings.Name.ShowDistance,
    Tooltip = "Append [Xm] to the name",
})
DepName:AddToggle("ShowHealthName", {
    Text    = "Health",
    Default = Settings.Name.ShowHealth,
    Tooltip = "Append [Xhp] to the name",
})
DepName:AddToggle("NameOutline", {
    Text    = "Outline",
    Default = Settings.Name.Outline,
    Tooltip = "Dark outline behind text",
})
DepName:AddSlider("NameSize", {
    Text     = "Size",
    Default  = Settings.Name.Size,
    Min      = 10,
    Max      = 24,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Name text size",
})
DepName:AddLabel("Color"):AddColorPicker("NameColor", {
    Default = Settings.Name.Color,
    Title   = "Name Color",
})
DepName:SetupDependencies({ { Toggles.NameEnabled, true } })

-- ══════════════════════════════════════════
-- TAB: AIMBOT
-- ══════════════════════════════════════════

-- LEFT: Main aimbot controls
local GbAim = Tabs.Aimbot:AddLeftGroupbox("Aimbot")
GbAim:AddToggle("AimbotEnabled", {
    Text    = "Enabled",
    Default = AimbotSettings.Enabled,
    Tooltip = "Rotate camera toward nearest target within FOV",
})
GbAim:AddLabel("Hold Key"):AddKeyPicker("AimbotKey", {
    Default = "MB2",
    Mode    = "Hold",
    Text    = "Aim",
    Tooltip = "Hold this key to activate aimbot",
})
GbAim:AddDivider()
local DepAim = GbAim:AddDependencyBox()
DepAim:AddDropdown("AimbotMode", {
    Values  = { "Mouse (1st Person)", "Camera (3rd Person)" },
    Default = 1,
    Text    = "Aimbot Mode",
    Tooltip = "1st Person = Fixed Screen Center\n3rd Person = Follows Mouse Cursor",
}):OnChanged(function(val)
    AimbotSettings.Mode = val
end)
DepAim:AddSlider("AimbotFOV", {
    Text     = "FOV",
    Default  = AimbotSettings.FOV,
    Min      = 10,
    Max      = 500,
    Rounding = 0,
    Compact  = true,
    Suffix   = "px",
    Tooltip  = "Screen-space radius in pixels to search for targets",
})
DepAim:AddSlider("AimbotSmooth", {
    Text     = "Smoothness (Camera)",
    Default  = AimbotSettings.Smoothness,
    Min      = 1,
    Max      = 50,
    Rounding = 0,
    Compact  = true,
    Tooltip  = "Higher = slower/smoother camera movement (3rd Person mode)",
})
DepAim:AddSlider("AimbotSens", {
    Text     = "Sensitivity (Mouse)",
    Default  = AimbotSettings.Sensitivity,
    Min      = 0.1,
    Max      = 5.0,
    Rounding = 1,
    Compact  = true,
    Tooltip  = "Higher = faster mouse movement (1st Person mode)",
})
DepAim:AddDropdown("AimbotHitPart", {
    Values  = { "Head", "HumanoidRootPart", "Torso", "UpperTorso" },
    Default = 1,
    Text    = "Hit Part",
    Tooltip = "Which body part the aimbot should target",
}):OnChanged(function(val)
    AimbotSettings.HitPart = val
end)
DepAim:AddToggle("AimbotTeamCheck", {
    Text    = "Team Check",
    Default = AimbotSettings.TeamCheck,
    Tooltip = "Skip teammates when finding targets",
})
DepAim:SetupDependencies({ { Toggles.AimbotEnabled, true } })

-- LEFT: FOV circle
local GbFOV = Tabs.Aimbot:AddLeftGroupbox("FOV Circle")
GbFOV:AddToggle("ShowFOV", {
    Text    = "Show FOV Circle",
    Default = AimbotSettings.ShowFOV,
    Tooltip = "Draw a circle showing the aimbot FOV radius",
})
local DepFOV = GbFOV:AddDependencyBox()
DepFOV:AddLabel("Color"):AddColorPicker("FOVColor", {
    Default = AimbotSettings.FOVColor,
    Title   = "FOV Circle Color",
})
DepFOV:SetupDependencies({ { Toggles.ShowFOV, true } })

-- RIGHT: Silent Aim
local GbSilent = Tabs.Aimbot:AddRightGroupbox("Silent Aim")
GbSilent:AddToggle("SilentAimEnabled", {
    Text    = "Silent Aim Enabled",
    Default = SilentAimSettings.Enabled,
    Tooltip = "Silently redirects bullets to target without moving cursor",
})
local DepSilent = GbSilent:AddDependencyBox()
DepSilent:AddDropdown("SilentMethod", {
    Values  = { "All", "RCL", "Modern", "Old", "RemoteEvent" },
    Default = 1,
    Text    = "Gun System",
    Tooltip = "All: Hook all methods, RCL: FindPartOnRay, Modern: Raycast, Old: Mouse.Hit/Target, RemoteEvent: FireServer hooks",
}):OnChanged(function(val)
    SilentAimSettings.Method = val
end)
DepSilent:AddSlider('SilentHitChance', {
    Text = 'Hit Chance %',
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Compact = false,
}):OnChanged(function(val)
    SilentAimSettings.HitChance = val
end)
DepSilent:AddDropdown("SilentHitPart", {
    Values  = { "Head", "HumanoidRootPart", "Torso", "UpperTorso" },
    Default = 1,
    Text    = "Hit Part",
    Tooltip = "Which body part silent aim should target",
}):OnChanged(function(val)
    SilentAimSettings.HitPart = val
end)
DepSilent:AddToggle("SilentTeamCheck", {
    Text    = "Team Check",
    Default = SilentAimSettings.TeamCheck,
    Tooltip = "Skip teammates for silent aim targeting",
})
DepSilent:AddToggle("SilentShowLine", {
    Text    = "Show Target Line",
    Default = SilentAimSettings.ShowTargetLine,
    Tooltip = "Draw green line from cursor to target",
})
DepSilent:AddLabel("Line Color"):AddColorPicker("SilentLineColor", {
    Default = SilentAimSettings.TargetLineColor,
    Title   = "Target Line Color",
})
DepSilent:SetupDependencies({ { Toggles.SilentAimEnabled, true } })

local GbAimInfo = Tabs.Aimbot:AddRightGroupbox("Info")
GbAimInfo:AddLabel("Aimbot: Hold key to lock camera\nSilent Aim: Redirects bullets silently", true)

-- ══════════════════════════════════════════
-- TAB: VISUALS
-- ══════════════════════════════════════════
local GbRainbow = Tabs.Visuals:AddLeftGroupbox("Rainbow")
GbRainbow:AddToggle("RainbowEnabled", {
    Text    = "Rainbow Mode",
    Default = Settings.Rainbow.Enabled,
    Tooltip = "Cycle all ESP colors through the spectrum",
})
local DepRainbow = GbRainbow:AddDependencyBox()
DepRainbow:AddSlider("RainbowSpeed", {
    Text     = "Speed",
    Default  = Settings.Rainbow.Speed,
    Min      = 1,
    Max      = 20,
    Rounding = 0,
    Compact  = true,
    Suffix   = "x",
    Tooltip  = "Rainbow cycle speed",
})
DepRainbow:SetupDependencies({ { Toggles.RainbowEnabled, true } })

local GbColorNote = Tabs.Visuals:AddRightGroupbox("Color Priority")
GbColorNote:AddLabel("1. Rainbow (overrides all)", true)
GbColorNote:AddLabel("2. Team Color (per player)", true)
GbColorNote:AddLabel("3. Custom colors (default)", true)
GbColorNote:AddDivider()
GbColorNote:AddLabel("Set colors in the ESP tab\nunder each feature.", true)

-- ══════════════════════════════════════════
-- TAB: CONFIG
-- ══════════════════════════════════════════
local GbConfig = Tabs.Config:AddLeftGroupbox("ESP Config")
GbConfig:AddButton({
    Text    = "Save Config",
    Func    = SaveConfig,
    Tooltip = "Save current settings to " .. CONFIG_FILE,
})
GbConfig:AddButton({
    Text    = "Load Config",
    Func    = LoadConfig,
    Tooltip = "Load settings from " .. CONFIG_FILE,
})
GbConfig:AddDivider()
GbConfig:AddLabel("File: " .. CONFIG_FILE, true)

local GbScriptInfo = Tabs.Config:AddRightGroupbox("About")
GbScriptInfo:AddLabel("Universal ESP Pro Enhanced", true)
GbScriptInfo:AddLabel("v3.6  |  LinoriaLib", true)
GbScriptInfo:AddDivider()
GbScriptInfo:AddLabel("Loadstring in script header.", true)
GbScriptInfo:AddDivider()
GbScriptInfo:AddButton({
    Text    = "Copy Loadstring",
    Func    = function()
        if setclipboard then
            setclipboard('loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/main/Examples/Universal_ESP_Pro_Enhanced_v3.6_NoSilent.lua",true))()')
            Notify("Copied!", "Loadstring copied to clipboard.", 3)
        else
            Notify("Unavailable", "setclipboard not supported.", 3)
        end
    end,
    Tooltip = "Copy the loadstring to clipboard",
})

-- ══════════════════════════════════════════
-- TAB: UI SETTINGS
-- ══════════════════════════════════════════
local GbMenu = Tabs.UI:AddLeftGroupbox("Menu")
GbMenu:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "End",
    NoUI    = true,
    Text    = "Toggle Menu",
    Tooltip = "Show/hide the menu",
})
GbMenu:AddDivider()
GbMenu:AddButton({
    Text    = "Unload Script",
    Func    = function()
        Notify("Unloading", "Removing all ESP...", 2)
        task.wait(0.6)
        Library:Unload()
    end,
    Tooltip = "Remove all ESP and destroy the UI",
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("UniversalESP")
SaveManager:SetFolder("UniversalESP")
ThemeManager:ApplyToTab(Tabs.UI)
SaveManager:BuildConfigSection(Tabs.UI)

-- ══════════════════════════════════════════
-- ONCHANGED CALLBACKS (decoupled from UI)
-- ══════════════════════════════════════════
Toggles.ESPEnabled:OnChanged(function()    Settings.Enabled          = Toggles.ESPEnabled.Value    end)
Toggles.TeamCheck:OnChanged(function()     Settings.TeamCheck         = Toggles.TeamCheck.Value     end)
Toggles.TeamColor:OnChanged(function()     Settings.TeamColor         = Toggles.TeamColor.Value     end)
Options.MaxDist:OnChanged(function()       Settings.MaxDist           = Options.MaxDist.Value       end)

Toggles.BoxEnabled:OnChanged(function()    Settings.Box.Enabled       = Toggles.BoxEnabled.Value    end)
Options.BoxThickness:OnChanged(function()  Settings.Box.Thickness      = Options.BoxThickness.Value  end)
Options.BoxColor:OnChanged(function()      Settings.Box.Color          = Options.BoxColor.Value      end)

Toggles.TracerEnabled:OnChanged(function()   Settings.Tracer.Enabled   = Toggles.TracerEnabled.Value   end)
Options.TracerThickness:OnChanged(function() Settings.Tracer.Thickness  = Options.TracerThickness.Value end)
Options.TracerOrigin:OnChanged(function()    Settings.Tracer.Origin     = Options.TracerOrigin.Value    end)
Options.TracerColor:OnChanged(function()     Settings.Tracer.Color      = Options.TracerColor.Value     end)

Toggles.NameEnabled:OnChanged(function()    Settings.Name.Enabled      = Toggles.NameEnabled.Value    end)
Toggles.ShowDistance:OnChanged(function()   Settings.Name.ShowDistance  = Toggles.ShowDistance.Value   end)
Toggles.ShowHealthName:OnChanged(function() Settings.Name.ShowHealth    = Toggles.ShowHealthName.Value  end)
Toggles.NameOutline:OnChanged(function()    Settings.Name.Outline       = Toggles.NameOutline.Value     end)
Options.NameSize:OnChanged(function()       Settings.Name.Size          = Options.NameSize.Value        end)
Options.NameColor:OnChanged(function()      Settings.Name.Color         = Options.NameColor.Value       end)

Toggles.HealthEnabled:OnChanged(function()   Settings.Health.Enabled    = Toggles.HealthEnabled.Value   end)
Toggles.HealthText:OnChanged(function()      Settings.Health.ShowText    = Toggles.HealthText.Value      end)
Options.HealthThickness:OnChanged(function() Settings.Health.Thickness   = Options.HealthThickness.Value end)

Toggles.RainbowEnabled:OnChanged(function() Settings.Rainbow.Enabled    = Toggles.RainbowEnabled.Value  end)
Options.RainbowSpeed:OnChanged(function()   Settings.Rainbow.Speed       = Options.RainbowSpeed.Value    end)

-- Silent Aim event handlers
Toggles.SilentAimEnabled:OnChanged(function() SilentAimSettings.Enabled = Toggles.SilentAimEnabled.Value end)
Toggles.SilentTeamCheck:OnChanged(function() SilentAimSettings.TeamCheck = Toggles.SilentTeamCheck.Value end)
Toggles.SilentShowLine:OnChanged(function() SilentAimSettings.ShowTargetLine = Toggles.SilentShowLine.Value end)
Options.SilentLineColor:OnChanged(function() SilentAimSettings.TargetLineColor = Options.SilentLineColor.Value end)

Options.ESPKeybind:OnClick(function()
    Settings.Enabled = Toggles.ESPEnabled.Value
end)

-- Aimbot OnChanged
Toggles.AimbotEnabled:OnChanged(function()  AimbotSettings.Enabled    = Toggles.AimbotEnabled.Value  end)
Toggles.AimbotTeamCheck:OnChanged(function() AimbotSettings.TeamCheck  = Toggles.AimbotTeamCheck.Value end)
Toggles.ShowFOV:OnChanged(function()        AimbotSettings.ShowFOV    = Toggles.ShowFOV.Value         end)
Options.AimbotMode:OnChanged(function()     AimbotSettings.Mode       = Options.AimbotMode.Value      end)
Options.AimbotFOV:OnChanged(function()      AimbotSettings.FOV        = Options.AimbotFOV.Value       end)
Options.AimbotSmooth:OnChanged(function()   AimbotSettings.Smoothness  = Options.AimbotSmooth.Value    end)
Options.AimbotSens:OnChanged(function()     AimbotSettings.Sensitivity = Options.AimbotSens.Value      end)
Options.AimbotHitPart:OnChanged(function()  AimbotSettings.HitPart    = Options.AimbotHitPart.Value   end)
Options.FOVColor:OnChanged(function()       AimbotSettings.FOVColor   = Options.FOVColor.Value        end)

-- ══════════════════════════════════════════
-- WATERMARK
-- ══════════════════════════════════════════
-- Watermark: bottom-left
Library:SetWatermarkVisibility(true)
Library.Watermark.Position = UDim2.new(0, 10, 1, -30)

-- KeybindFrame: bottom-left above watermark, auto-hide after 10s
Library.KeybindFrame.Position = UDim2.new(0, 10, 1, -55)
Library.KeybindFrame.Visible = true
task.delay(10, function()
    if Library.KeybindFrame then
        Library.KeybindFrame.Visible = false
    end
end)

-- NotificationArea: bottom-right corner flush with screen edge
Library.NotificationArea.AnchorPoint = Vector2.new(1, 1)
Library.NotificationArea.Position    = UDim2.new(1, 0, 1, 0)
Library.NotificationArea.Size        = UDim2.new(0, 300, 0, 600)
-- Make the list layout stack from the bottom upward
local _notifLayout = Library.NotificationArea:FindFirstChildOfClass("UIListLayout")
if _notifLayout then
    _notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
end

local _frameTimer   = tick()
local _frameCounter = 0
local _fps          = 60
local _ping         = 0

-- ══════════════════════════════════════════
-- ESP RUNTIME
-- ══════════════════════════════════════════
Players.PlayerAdded:Connect(function(player)
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

local _wmConn = RunService.RenderStepped:Connect(function()
    _frameCounter += 1
    if (tick() - _frameTimer) >= 1 then
        _fps          = _frameCounter
        _frameTimer   = tick()
        _frameCounter = 0
    end
    local ok, p = pcall(function()
        return math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    end)
    _ping = ok and p or _ping
    Library:SetWatermark(("Universal ESP v3.6  |  %d fps  |  %dms  |  %d players"):format(
        math.floor(_fps), _ping,
        math.max(0, #Players:GetPlayers() - 1)
    ))
    for _, e in pairs(ESPObjects) do
        pcall(UpdateESP, e)
    end

    -- Unified FOV circle - shows for both aimbot and silent aim
    local mouseLoc = UserInputService:GetMouseLocation()
    local fovCenter = mouseLoc

    if AimbotSettings.ShowFOV and (AimbotSettings.Enabled or SilentAimSettings.Enabled) then
        FovCircle.Position    = fovCenter
        FovCircle.Radius      = AimbotSettings.FOV
        FovCircle.Color       = AimbotSettings.FOVColor
        FovCircle.Visible     = true
    else
        FovCircle.Visible = false
    end
    
    -- Silent Aim is always active when enabled (no keybind required)
    local silentAimActive = SilentAimSettings.Enabled
    
    -- Update Silent Aim target when enabled
    if silentAimActive then
        local silentTarget, silentChar = GetClosestSilentTarget()
        SilentAimState.Target = silentChar
        SilentAimState.TargetPart = silentTarget
    else
        -- Clear target when disabled
        SilentAimState.Target = nil
        SilentAimState.TargetPart = nil
    end
    
    -- Draw target line when Silent Aim is enabled and has target
    if silentAimActive and SilentAimSettings.ShowTargetLine and SilentAimState.TargetPart then
        local targetScreenPos = Camera:WorldToViewportPoint(SilentAimState.TargetPart.Position)
        TargetLine.From = mouseLoc
        TargetLine.To = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
        TargetLine.Color = SilentAimSettings.TargetLineColor
        TargetLine.Thickness = 2
        TargetLine.Transparency = 1
        TargetLine.Visible = true
        -- Debug output
        print("Target Line Should Be Visible:", TargetLine.Visible, "From:", TargetLine.From, "To:", TargetLine.To)
    else
        TargetLine.Visible = false
    end

    -- Aimbot (camera-based / mouse-based)
    local aimbotHeld = false
    if Options.AimbotKey then
        aimbotHeld = Options.AimbotKey:GetState()
        
        -- Fallback for RightMouseButton if LinoriaLib isn't picking it up via GetState
        if not aimbotHeld and Options.AimbotKey.Value == "MB2" then
            aimbotHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end
    end

    if AimbotSettings.Enabled and aimbotHeld then
        local target, _, center = GetClosestTarget()
        if target and center then
            local sv = Camera:WorldToViewportPoint(target.Position)
            local delta = Vector2.new(sv.X, sv.Y) - center
            
            -- Simple smoothing
            if AimbotSettings.Smoothness > 1 then
                delta = delta / AimbotSettings.Smoothness
            end
            
            -- Use mousemoverel if supported by the executor, otherwise fallback
            if mousemoverel then
                mousemoverel(delta.X * AimbotSettings.Sensitivity, delta.Y * AimbotSettings.Sensitivity)
            end
        end
    end
end)

Library:OnUnload(function()
    _wmConn:Disconnect()
    for player in pairs(ESPObjects) do
        RemoveESP(player)
    end
    pcall(function() FovCircle:Remove() end)
    print("[Universal ESP] Unloaded.")
end)

-- ══════════════════════════════════════════
-- GLOBAL API
-- ══════════════════════════════════════════
getgenv().UniversalESP = {
    Settings   = Settings,
    SaveConfig = SaveConfig,
    LoadConfig = LoadConfig,
    Destroy    = function() Library:Unload() end,
}

SaveManager:LoadAutoloadConfig()
Notify("Universal ESP Pro Enhanced", "Loaded! Press End to toggle menu.", 5)
print("[Universal ESP Pro Enhanced v3.6] Loaded successfully.")
