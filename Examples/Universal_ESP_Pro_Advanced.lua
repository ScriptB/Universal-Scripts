--[[
    Universal ESP Pro Advanced
    Based on the advanced ESP implementation
    
    Features:
    - Box ESP (Corner, Full, 3D styles)
    - Name ESP with distance and health
    - Tracer ESP with multiple origin options
    - Health Bar ESP (bar and text)
    - Skeleton ESP with full joint connections
    - Chams with customizable colors and transparency
    - Rainbow effects with customizable speed
    - Performance optimization with adjustable refresh rate
    - Team check with customizable colors
]]

-- ===================================
-- DEV COPY INTEGRATION (FIRST)
-- ===================================

-- Implement DevCopy functionality directly
print("🔧 Implementing DevCopy functionality directly...")
local success, devCopyLoaded = pcall(function()
    -- Direct implementation of essential DevCopy functionality
    local CoreGui = game:GetService("CoreGui")
    local RunService = game:GetService("RunService")
    
    -- Executor clipboard compatibility
    local function copyToClipboard(text)
        if setclipboard then
            setclipboard(text)
            return true
        elseif toclipboard then
            toclipboard(text)
            return true
        elseif Clipboard and Clipboard.set then
            Clipboard.set(text)
            return true
        else
            warn("[LogCopier] No clipboard function available on this executor.")
            return false
        end
    end
    
    -- Safe instance check
    local function isAlive(instance)
        return instance and instance.Parent ~= nil
    end
    
    -- Get client log
    local function getClientLog()
        local master = CoreGui:FindFirstChild("DevConsoleMaster")
        if not master then return end
        
        -- Find the client log through various paths
        local clientLog
        
        -- Path 1: Standard path
        local window = master:FindFirstChild("DevConsoleWindow")
        if window then
            local ui = window:FindFirstChild("DevConsoleUI")
            if ui then
                local main = ui:FindFirstChild("MainView")
                if main then
                    clientLog = main:FindFirstChild("ClientLog")
                    if clientLog then return clientLog end
                end
            end
        end
        
        -- Path 2: Search all descendants (more reliable)
        for _, descendant in pairs(master:GetDescendants()) do
            if descendant.Name == "ClientLog" then
                return descendant
            end
        end
        
        return nil
    end
    
    -- Hook console
    local function hookConsole()
        local clientLog = getClientLog()
        if not clientLog then
            print("🔧 DevCopy: Waiting for console to load...")
            return
        end
        
        -- Create Copy All button
        if not clientLog:FindFirstChild("CopyAllLogs") then
            local btn = Instance.new("TextButton")
            btn.Name = "CopyAllLogs"
            btn.Size = UDim2.new(0, 120, 0, 22)
            btn.Position = UDim2.new(1, -130, 0, 6)
            btn.BackgroundTransparency = 0.2
            btn.Text = "Copy All"
            btn.Parent = clientLog
            
            btn.MouseButton1Click:Connect(function()
                local buffer = {}
                
                for _, obj in ipairs(clientLog:GetDescendants()) do
                    if obj:IsA("TextLabel") and obj.Text and obj.Text ~= "" then
                        table.insert(buffer, obj.Text)
                    end
                end
                
                if copyToClipboard(table.concat(buffer, "\n")) then
                    btn.Text = "Copied"
                    task.delay(0.6, function()
                        if isAlive(btn) then btn.Text = "Copy All" end
                    end)
                end
            end)
            
            print("🔧 DevCopy: Copy All button created")
        end
    end
    
    -- Initial run + periodic check
    hookConsole()
    
    -- Set up periodic check
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed = elapsed + dt
        if elapsed > 1 then
            elapsed = 0
            hookConsole()
        end
    end)
    
    return true
end)

if success and devCopyLoaded then
    print("📋 DevCopy functionality integrated successfully!")
else
    print("⚠️ DevCopy integration failed!")
    if not success then
        print("❌ HTTP request or loadstring failed:", devCopyLoaded)
    else
        print("❌ DevCopy execution returned:", devCopyLoaded)
    end
    print("🔧 Continuing without DevCopy...")
end

-- ===================================
-- BRACKET LIBRARY INTEGRATION
-- ===================================

-- Load Bracket library for UI
print("🎨 Attempting to load Bracket library...")
local bracketSuccess, Bracket = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Library%20Repos/BracketLib"))()
end)

if bracketSuccess and Bracket then
    print("✅ Bracket library loaded successfully!")
else
    print("⚠️ Bracket library integration failed!")
    if not bracketSuccess then
        print("❌ HTTP request or loadstring failed:", Bracket)
    else
        print("❌ Bracket execution returned:", Bracket)
    end
    print("🔧 Continuing without UI...")
end

print("🚀 Loading Universal ESP Pro Advanced...")

-- ===================================
-- SERVICES AND VARIABLES
-- ===================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Drawing containers
local Drawings = {
    ESP = {},
    Tracers = {},
    Boxes = {},
    Healthbars = {},
    Names = {},
    Distances = {},
    Snaplines = {},
    Skeleton = {}
}

-- Color definitions
local Colors = {
    Enemy = Color3.fromRGB(255, 25, 25),
    Ally = Color3.fromRGB(25, 255, 25),
    Neutral = Color3.fromRGB(255, 255, 255),
    Selected = Color3.fromRGB(255, 210, 0),
    Health = Color3.fromRGB(0, 255, 0),
    Distance = Color3.fromRGB(200, 200, 200),
    Rainbow = nil
}

-- Highlight storage
local Highlights = {}

-- ESP Configuration
local Settings = {
    Enabled = false,
    TeamCheck = false,
    ShowTeam = false,
    VisibilityCheck = true,
    BoxESP = false,
    BoxStyle = "Corner",
    BoxOutline = true,
    BoxFilled = false,
    BoxFillTransparency = 0.5,
    BoxThickness = 1,
    TracerESP = false,
    TracerOrigin = "Bottom",
    TracerStyle = "Line",
    TracerThickness = 1,
    HealthESP = false,
    HealthStyle = "Bar",
    HealthBarSide = "Left",
    HealthTextSuffix = "HP",
    NameESP = false,
    NameMode = "DisplayName",
    ShowDistance = true,
    DistanceUnit = "studs",
    TextSize = 14,
    TextFont = 2,
    RainbowSpeed = 1,
    MaxDistance = 1000,
    RefreshRate = 1/144,
    Snaplines = false,
    SnaplineStyle = "Straight",
    RainbowEnabled = false,
    RainbowBoxes = false,
    RainbowTracers = false,
    RainbowText = false,
    ChamsEnabled = false,
    ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
    ChamsFillColor = Color3.fromRGB(255, 0, 0),
    ChamsOccludedColor = Color3.fromRGB(150, 0, 0),
    ChamsTransparency = 0.5,
    ChamsOutlineTransparency = 0,
    ChamsOutlineThickness = 0.1,
    SkeletonESP = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    SkeletonThickness = 1.5,
    SkeletonTransparency = 1
}

-- ===================================
-- ESP CREATION FUNCTIONS
-- ===================================

local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local box = {
        TopLeft = Drawing.new("Line"),
        TopRight = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"),
        BottomRight = Drawing.new("Line"),
        Left = Drawing.new("Line"),
        Right = Drawing.new("Line"),
        Top = Drawing.new("Line"),
        Bottom = Drawing.new("Line")
    }
    
    for _, line in pairs(box) do
        line.Visible = false
        line.Color = Colors.Enemy
        line.Thickness = Settings.BoxThickness
        if line == box.Fill then
            line.Filled = true
            line.Transparency = Settings.BoxFillTransparency
        end
    end
    
    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Colors.Enemy
    tracer.Thickness = Settings.TracerThickness
    
    local healthBar = {
        Outline = Drawing.new("Square"),
        Fill = Drawing.new("Square"),
        Text = Drawing.new("Text")
    }
    
    for _, obj in pairs(healthBar) do
        obj.Visible = false
        if obj == healthBar.Fill then
            obj.Color = Colors.Health
            obj.Filled = true
        elseif obj == healthBar.Text then
            obj.Center = true
            obj.Size = Settings.TextSize
            obj.Color = Colors.Health
            obj.Font = Settings.TextFont
        end
    end
    
    local info = {
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    for _, text in pairs(info) do
        text.Visible = false
        text.Center = true
        text.Size = Settings.TextSize
        text.Color = Colors.Enemy
        text.Font = Settings.TextFont
        text.Outline = true
    end
    
    local snapline = Drawing.new("Line")
    snapline.Visible = false
    snapline.Color = Colors.Enemy
    snapline.Thickness = 1
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Settings.ChamsFillColor
    highlight.OutlineColor = Settings.ChamsOutlineColor
    highlight.FillTransparency = Settings.ChamsTransparency
    highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = Settings.ChamsEnabled
    
    Highlights[player] = highlight
    
    local skeleton = {
        -- Spine & Head
        Head = Drawing.new("Line"),
        Neck = Drawing.new("Line"),
        UpperSpine = Drawing.new("Line"),
        LowerSpine = Drawing.new("Line"),
        
        -- Left Arm
        LeftShoulder = Drawing.new("Line"),
        LeftUpperArm = Drawing.new("Line"),
        LeftLowerArm = Drawing.new("Line"),
        LeftHand = Drawing.new("Line"),
        
        -- Right Arm
        RightShoulder = Drawing.new("Line"),
        RightUpperArm = Drawing.new("Line"),
        RightLowerArm = Drawing.new("Line"),
        RightHand = Drawing.new("Line"),
        
        -- Left Leg
        LeftHip = Drawing.new("Line"),
        LeftUpperLeg = Drawing.new("Line"),
        LeftLowerLeg = Drawing.new("Line"),
        LeftFoot = Drawing.new("Line"),
        
        -- Right Leg
        RightHip = Drawing.new("Line"),
        RightUpperLeg = Drawing.new("Line"),
        RightLowerLeg = Drawing.new("Line"),
        RightFoot = Drawing.new("Line")
    }
    
    for _, line in pairs(skeleton) do
        line.Visible = false
        line.Color = Settings.SkeletonColor
        line.Thickness = Settings.SkeletonThickness
        line.Transparency = Settings.SkeletonTransparency
    end
    
    Drawings.Skeleton[player] = skeleton
    
    Drawings.ESP[player] = {
        Box = box,
        Tracer = tracer,
        HealthBar = healthBar,
        Info = info,
        Snapline = snapline
    }
end

-- ===================================
-- ESP CLEANUP FUNCTIONS
-- ===================================

local function RemoveESP(player)
    local esp = Drawings.ESP[player]
    if esp then
        for _, obj in pairs(esp.Box) do obj:Remove() end
        esp.Tracer:Remove()
        for _, obj in pairs(esp.HealthBar) do obj:Remove() end
        for _, obj in pairs(esp.Info) do obj:Remove() end
        esp.Snapline:Remove()
        Drawings.ESP[player] = nil
    end
    
    local highlight = Highlights[player]
    if highlight then
        highlight:Destroy()
        Highlights[player] = nil
    end
    
    local skeleton = Drawings.Skeleton[player]
    if skeleton then
        for _, line in pairs(skeleton) do
            line:Remove()
        end
        Drawings.Skeleton[player] = nil
    end
end

local function DisableESP()
    for _, player in ipairs(Players:GetPlayers()) do
        local esp = Drawings.ESP[player]
        if esp then
            for _, obj in pairs(esp.Box) do obj.Visible = false end
            esp.Tracer.Visible = false
            for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
            for _, obj in pairs(esp.Info) do obj.Visible = false end
            esp.Snapline.Visible = false
        end
        
        -- Also hide skeleton
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
    end
end

local function CleanupESP()
    for _, player in ipairs(Players:GetPlayers()) do
        RemoveESP(player)
    end
    Drawings.ESP = {}
    Drawings.Skeleton = {}
    Highlights = {}
end

-- ===================================
-- ESP UTILITY FUNCTIONS
-- ===================================

local function GetPlayerColor(player)
    if Settings.RainbowEnabled then
        if Settings.RainbowBoxes and Settings.BoxESP then return Colors.Rainbow end
        if Settings.RainbowTracers and Settings.TracerESP then return Colors.Rainbow end
        if Settings.RainbowText and (Settings.NameESP or Settings.HealthESP) then return Colors.Rainbow end
    end
    return player.Team == LocalPlayer.Team and Colors.Ally or Colors.Enemy
end

local function GetBoxCorners(cf, size)
    local corners = {
        Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
        Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
        Vector3.new(-size.X/2, size.Y/2, size.Z/2),
        Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
        Vector3.new(size.X/2, -size.Y/2, size.Z/2),
        Vector3.new(size.X/2, size.Y/2, -size.Z/2),
        Vector3.new(size.X/2, size.Y/2, size.Z/2)
    }
    
    for i, corner in ipairs(corners) do
        corners[i] = cf:PointToWorldSpace(corner)
    end
    
    return corners
end

local function GetTracerOrigin()
    local origin = Settings.TracerOrigin
    if origin == "Bottom" then
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    elseif origin == "Top" then
        return Vector2.new(Camera.ViewportSize.X/2, 0)
    elseif origin == "Mouse" then
        return UserInputService:GetMouseLocation()
    else
        return Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end
end

-- ===================================
-- ESP UPDATE FUNCTIONS
-- ===================================

-- ===================================
-- MAIN EXECUTION FUNCTIONS
-- ===================================

-- Generate rainbow color
task.spawn(function()
    while task.wait(0.1) do
        Colors.Rainbow = Color3.fromHSV(tick() * Settings.RainbowSpeed % 1, 1, 1)
    end
end)

local function UpdateESP(player)
    if not Settings.Enabled then return end
    
    local esp = Drawings.ESP[player]
    if not esp then return end
    
    local character = player.Character
    if not character then 
        -- Hide all drawings if character doesn't exist
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return 
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then 
        -- Hide all drawings if rootPart doesn't exist
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return 
    end
    
    -- Early screen check to hide all drawings if player is off screen
    local _, isOnScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not isOnScreen then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
        return
    end
    
    local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    local distance = (rootPart.Position - Camera.CFrame.Position).Magnitude
    
    if not onScreen or distance > Settings.MaxDistance then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end
    
    if Settings.TeamCheck and player.Team == LocalPlayer.Team and not Settings.ShowTeam then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        esp.Tracer.Visible = false
        for _, obj in pairs(esp.HealthBar) do obj.Visible = false end
        for _, obj in pairs(esp.Info) do obj.Visible = false end
        esp.Snapline.Visible = false
        return
    end
    
    local color = GetPlayerColor(player)
    local size = character:GetExtentsSize()
    local cf = rootPart.CFrame
    
    local top, top_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, size.Y/2, 0).Position)
    local bottom, bottom_onscreen = Camera:WorldToViewportPoint(cf * CFrame.new(0, -size.Y/2, 0).Position)
    
    if not top_onscreen or not bottom_onscreen then
        for _, obj in pairs(esp.Box) do obj.Visible = false end
        return
    end
    
    local screenSize = bottom.Y - top.Y
    local boxWidth = screenSize * 0.65
    local boxPosition = Vector2.new(top.X - boxWidth/2, top.Y)
    local boxSize = Vector2.new(boxWidth, screenSize)
    
    -- Hide all box parts by default
    for _, obj in pairs(esp.Box) do
        obj.Visible = false
    end
    
    if Settings.BoxESP then
        if Settings.BoxStyle == "ThreeD" then
            local front = {
                TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, -size.Z/2)).Position),
                TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, -size.Z/2)).Position),
                BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2)).Position),
                BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, -size.Z/2)).Position)
            }
            
            local back = {
                TL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, size.Y/2, size.Z/2)).Position),
                TR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, size.Y/2, size.Z/2)).Position),
                BL = Camera:WorldToViewportPoint((cf * CFrame.new(-size.X/2, -size.Y/2, size.Z/2)).Position),
                BR = Camera:WorldToViewportPoint((cf * CFrame.new(size.X/2, -size.Y/2, size.Z/2)).Position)
            }
            
            if not (front.TL.Z > 0 and front.TR.Z > 0 and front.BL.Z > 0 and front.BR.Z > 0 and
                   back.TL.Z > 0 and back.TR.Z > 0 and back.BL.Z > 0 and back.BR.Z > 0) then
                for _, obj in pairs(esp.Box) do obj.Visible = false end
                return
            end
            
            -- Convert to Vector2
            local function toVector2(v3) return Vector2.new(v3.X, v3.Y) end
            front.TL, front.TR = toVector2(front.TL), toVector2(front.TR)
            front.BL, front.BR = toVector2(front.BL), toVector2(front.BR)
            back.TL, back.TR = toVector2(back.TL), toVector2(back.TR)
            back.BL, back.BR = toVector2(back.BL), toVector2(back.BR)
            
            -- Front face
            esp.Box.TopLeft.From = front.TL
            esp.Box.TopLeft.To = front.TR
            esp.Box.TopLeft.Visible = true
            
            esp.Box.TopRight.From = front.TR
            esp.Box.TopRight.To = front.BR
            esp.Box.TopRight.Visible = true
            
            esp.Box.BottomLeft.From = front.BL
            esp.Box.BottomLeft.To = front.BR
            esp.Box.BottomLeft.Visible = true
            
            esp.Box.BottomRight.From = front.TL
            esp.Box.BottomRight.To = front.BL
            esp.Box.BottomRight.Visible = true
            
            -- Back face
            esp.Box.Left.From = back.TL
            esp.Box.Left.To = back.TR
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = back.TR
            esp.Box.Right.To = back.BR
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = back.BL
            esp.Box.Top.To = back.BR
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = back.TL
            esp.Box.Bottom.To = back.BL
            esp.Box.Bottom.Visible = true
            
            -- Connect front to back
            local function drawConnectingLine(from, to, visible)
                local line = Drawing.new("Line")
                line.Visible = visible
                line.Color = color
                line.Thickness = Settings.BoxThickness
                line.From = from
                line.To = to
                return line
            end
            
            -- Connect front to back
            local connectors = {
                drawConnectingLine(front.TL, back.TL, true),
                drawConnectingLine(front.TR, back.TR, true),
                drawConnectingLine(front.BL, back.BL, true),
                drawConnectingLine(front.BR, back.BR, true)
            }
            
            -- Clean up connecting lines after frame
            task.spawn(function()
                task.wait()
                for _, line in ipairs(connectors) do
                    line:Remove()
                end
            end)
            
        elseif Settings.BoxStyle == "Corner" then
            local cornerSize = boxWidth * 0.2
            
            esp.Box.TopLeft.From = boxPosition
            esp.Box.TopLeft.To = boxPosition + Vector2.new(cornerSize, 0)
            esp.Box.TopLeft.Visible = true
            
            esp.Box.TopRight.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.TopRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, 0)
            esp.Box.TopRight.Visible = true
            
            esp.Box.BottomLeft.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.BottomLeft.To = boxPosition + Vector2.new(cornerSize, boxSize.Y)
            esp.Box.BottomLeft.Visible = true
            
            esp.Box.BottomRight.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.BottomRight.To = boxPosition + Vector2.new(boxSize.X - cornerSize, boxSize.Y)
            esp.Box.BottomRight.Visible = true
            
            esp.Box.Left.From = boxPosition
            esp.Box.Left.To = boxPosition + Vector2.new(0, cornerSize)
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, cornerSize)
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Top.To = boxPosition + Vector2.new(0, boxSize.Y - cornerSize)
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y - cornerSize)
            esp.Box.Bottom.Visible = true
            
        else -- Full box
            esp.Box.Left.From = boxPosition
            esp.Box.Left.To = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Left.Visible = true
            
            esp.Box.Right.From = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Right.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Right.Visible = true
            
            esp.Box.Top.From = boxPosition
            esp.Box.Top.To = boxPosition + Vector2.new(boxSize.X, 0)
            esp.Box.Top.Visible = true
            
            esp.Box.Bottom.From = boxPosition + Vector2.new(0, boxSize.Y)
            esp.Box.Bottom.To = boxPosition + Vector2.new(boxSize.X, boxSize.Y)
            esp.Box.Bottom.Visible = true
            
            esp.Box.TopLeft.Visible = false
            esp.Box.TopRight.Visible = false
            esp.Box.BottomLeft.Visible = false
            esp.Box.BottomRight.Visible = false
        end
        
        for _, obj in pairs(esp.Box) do
            if obj.Visible then
                obj.Color = color
                obj.Thickness = Settings.BoxThickness
            end
        end
    end
    
    if Settings.TracerESP then
        esp.Tracer.From = GetTracerOrigin()
        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Visible = true
    else
        esp.Tracer.Visible = false
    end
    
    if Settings.HealthESP then
        local health = humanoid.Health
        local maxHealth = humanoid.MaxHealth
        local healthPercent = health/maxHealth
        
        local barHeight = screenSize * 0.8
        local barWidth = 4
        local barPos = Vector2.new(
            boxPosition.X - barWidth - 2,
            boxPosition.Y + (screenSize - barHeight)/2
        )
        
        esp.HealthBar.Outline.Size = Vector2.new(barWidth, barHeight)
        esp.HealthBar.Outline.Position = barPos
        esp.HealthBar.Outline.Visible = true
        
        esp.HealthBar.Fill.Size = Vector2.new(barWidth - 2, barHeight * healthPercent)
        esp.HealthBar.Fill.Position = Vector2.new(barPos.X + 1, barPos.Y + barHeight * (1-healthPercent))
        esp.HealthBar.Fill.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
        esp.HealthBar.Fill.Visible = true
        
        if Settings.HealthStyle == "Both" or Settings.HealthStyle == "Text" then
            esp.HealthBar.Text.Text = math.floor(health) .. Settings.HealthTextSuffix
            esp.HealthBar.Text.Position = Vector2.new(barPos.X + barWidth + 2, barPos.Y + barHeight/2)
            esp.HealthBar.Text.Visible = true
        else
            esp.HealthBar.Text.Visible = false
        end
    else
        for _, obj in pairs(esp.HealthBar) do
            obj.Visible = false
        end
    end
    
    if Settings.NameESP then
        esp.Info.Name.Text = player.DisplayName
        esp.Info.Name.Position = Vector2.new(
            boxPosition.X + boxWidth/2,
            boxPosition.Y - 20
        )
        esp.Info.Name.Color = color
        esp.Info.Name.Visible = true
    else
        esp.Info.Name.Visible = false
    end
    
    if Settings.Snaplines then
        esp.Snapline.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        esp.Snapline.To = Vector2.new(pos.X, pos.Y)
        esp.Snapline.Color = color
        esp.Snapline.Visible = true
    else
        esp.Snapline.Visible = false
    end
    
    local highlight = Highlights[player]
    if highlight then
        if Settings.ChamsEnabled and character then
            highlight.Parent = character
            highlight.FillColor = Settings.ChamsFillColor
            highlight.OutlineColor = Settings.ChamsOutlineColor
            highlight.FillTransparency = Settings.ChamsTransparency
            highlight.OutlineTransparency = Settings.ChamsOutlineTransparency
            highlight.Enabled = true
        else
            highlight.Enabled = false
        end
    end
    
    if Settings.SkeletonESP then
        local function getBonePositions(character)
            if not character then return nil end
            
            local bones = {
                Head = character:FindFirstChild("Head"),
                UpperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"),
                LowerTorso = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso"),
                RootPart = character:FindFirstChild("HumanoidRootPart"),
                
                -- Left Arm
                LeftUpperArm = character:FindFirstChild("LeftUpperArm") or character:FindFirstChild("Left Arm"),
                LeftLowerArm = character:FindFirstChild("LeftLowerArm") or character:FindFirstChild("Left Arm"),
                LeftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"),
                
                -- Right Arm
                RightUpperArm = character:FindFirstChild("RightUpperArm") or character:FindFirstChild("Right Arm"),
                RightLowerArm = character:FindFirstChild("RightLowerArm") or character:FindFirstChild("Right Arm"),
                RightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"),
                
                -- Left Leg
                LeftUpperLeg = character:FindFirstChild("LeftUpperLeg") or character:FindFirstChild("Left Leg"),
                LeftLowerLeg = character:FindFirstChild("LeftLowerLeg") or character:FindFirstChild("Left Leg"),
                LeftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("Left Leg"),
                
                -- Right Leg
                RightUpperLeg = character:FindFirstChild("RightUpperLeg") or character:FindFirstChild("Right Leg"),
                RightLowerLeg = character:FindFirstChild("RightLowerLeg") or character:FindFirstChild("Right Leg"),
                RightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("Right Leg")
            }
            
            -- Verify we have the minimum required bones
            if not (bones.Head and bones.UpperTorso) then return nil end
            
            return bones
        end
        
        local function drawBone(from, to, line)
            if not from or not to then 
                line.Visible = false
                return 
            end
            
            -- Get center positions of the parts
            local fromPos = (from.CFrame * CFrame.new(0, 0, 0)).Position
            local toPos = (to.CFrame * CFrame.new(0, 0, 0)).Position
            
            -- Convert to screen positions with proper depth check
            local fromScreen, fromVisible = Camera:WorldToViewportPoint(fromPos)
            local toScreen, toVisible = Camera:WorldToViewportPoint(toPos)
            
            -- Only show if both points are visible and in front of camera
            if not (fromVisible and toVisible) or fromScreen.Z < 0 or toScreen.Z < 0 then
                line.Visible = false
                return
            end
            
            -- Check if points are within screen bounds
            local screenBounds = Camera.ViewportSize
            if fromScreen.X < 0 or fromScreen.X > screenBounds.X or
               fromScreen.Y < 0 or fromScreen.Y > screenBounds.Y or
               toScreen.X < 0 or toScreen.X > screenBounds.X or
               toScreen.Y < 0 or toScreen.Y > screenBounds.Y then
                line.Visible = false
                return
            end
            
            -- Update line with screen positions
            line.From = Vector2.new(fromScreen.X, fromScreen.Y)
            line.To = Vector2.new(toScreen.X, toScreen.Y)
            line.Color = Settings.SkeletonColor
            line.Thickness = Settings.SkeletonThickness
            line.Transparency = Settings.SkeletonTransparency
            line.Visible = true
        end
        
        local bones = getBonePositions(character)
        if bones then
            local skeleton = Drawings.Skeleton[player]
            if skeleton then
                -- Spine & Head
                drawBone(bones.Head, bones.UpperTorso, skeleton.Head)
                drawBone(bones.UpperTorso, bones.LowerTorso, skeleton.UpperSpine)
                
                -- Left Arm Chain
                drawBone(bones.UpperTorso, bones.LeftUpperArm, skeleton.LeftShoulder)
                drawBone(bones.LeftUpperArm, bones.LeftLowerArm, skeleton.LeftUpperArm)
                drawBone(bones.LeftLowerArm, bones.LeftHand, skeleton.LeftLowerArm)
                
                -- Right Arm Chain
                drawBone(bones.UpperTorso, bones.RightUpperArm, skeleton.RightShoulder)
                drawBone(bones.RightUpperArm, bones.RightLowerArm, skeleton.RightUpperArm)
                drawBone(bones.RightLowerArm, bones.RightHand, skeleton.RightLowerArm)
                
                -- Left Leg Chain
                drawBone(bones.LowerTorso, bones.LeftUpperLeg, skeleton.LeftHip)
                drawBone(bones.LeftUpperLeg, bones.LeftLowerLeg, skeleton.LeftUpperLeg)
                drawBone(bones.LeftLowerLeg, bones.LeftFoot, skeleton.LeftLowerLeg)
                
                -- Right Leg Chain
                drawBone(bones.LowerTorso, bones.RightUpperLeg, skeleton.RightHip)
                drawBone(bones.RightUpperLeg, bones.RightLowerLeg, skeleton.RightUpperLeg)
                drawBone(bones.RightLowerLeg, bones.RightFoot, skeleton.RightLowerLeg)
            end
        end
    else
        local skeleton = Drawings.Skeleton[player]
        if skeleton then
            for _, line in pairs(skeleton) do
                line.Visible = false
            end
        end
    end
end

-- ===================================
-- BRACKET UI INTEGRATION
-- ===================================

if bracketSuccess and Bracket then
    -- Create notification system with custom styling
    local Notify = Bracket:Notification({
        Title = "Universal ESP Pro Advanced",
        Description = "ESP system loaded successfully!",
        Duration = 5,
        TitleColor = Color3.fromRGB(255, 255, 255),
        DescriptionColor = Color3.fromRGB(200, 200, 255),
        TitleTextSize = 17,
        DescriptionTextSize = 14,
        TitleFont = Enum.Font.SourceSansBold,
        DescriptionFont = Enum.Font.SourceSans
    })
    
    -- Create main window with improved styling
    local Window = Bracket:Window({
        Title = "Universal ESP Pro Advanced",
        Subtitle = "by ScriptB",
        Position = UDim2.new(0.05, 0, 0.5, 0),
        Size = UDim2.new(0, 580, 0, 480),
        Transparency = 0.92,
        TitleColor = Color3.fromRGB(255, 255, 255),
        TitleTextSize = 18,
        TitleFont = Enum.Font.GothamBold,
        BackgroundColor = Color3.fromRGB(30, 30, 35),
        BorderColor = Color3.fromRGB(60, 60, 80),
        BorderThickness = 1
    })
    
    -- Create tabs with icons for better visual identification
    local MainTab = Window:Tab({ Title = "Main", Icon = "home" })
    local BoxESPTab = Window:Tab({ Title = "Box ESP", Icon = "square" })
    local TracerTab = Window:Tab({ Title = "Tracers", Icon = "trending-up" })
    local SkeletonTab = Window:Tab({ Title = "Skeleton", Icon = "activity" })
    local ChamsTab = Window:Tab({ Title = "Chams", Icon = "layers" })
    local SettingsTab = Window:Tab({ Title = "Settings", Icon = "settings" })
    
    -- Main Tab with master controls and status display
    local MainSection = MainTab:Section({
        Title = "ESP Master Controls",
        Icon = "power",
        Side = "Left"
    })
    
    MainSection:Toggle({
        Title = "Enable ESP",
        Description = "Master switch for all ESP features",
        Default = Settings.Enabled,
        Icon = "eye",
        Callback = function(state)
            Settings.Enabled = state
            if not state then
                DisableESP()
            end
        end
    })
    
    MainSection:Toggle({
        Title = "Team Check",
        Description = "Use different colors for teammates",
        Default = Settings.TeamCheck,
        Icon = "users",
        Callback = function(state)
            Settings.TeamCheck = state
        end
    })
    
    MainSection:Toggle({
        Title = "Show Teammates",
        Description = "Display ESP for players on your team",
        Default = Settings.ShowTeam,
        Icon = "user-check",
        Callback = function(state)
            Settings.ShowTeam = state
        end
    })
    
    local DistanceSection = MainTab:Section({
        Title = "Distance & Performance",
        Icon = "sliders",
        Side = "Left"
    })
    
    DistanceSection:Slider({
        Title = "Max Distance",
        Description = "Maximum render distance for ESP",
        Default = Settings.MaxDistance,
        Min = 100,
        Max = 5000,
        Increment = 100,
        ValueFormat = "%d studs",
        Callback = function(value)
            Settings.MaxDistance = value
        end
    })
    
    DistanceSection:Toggle({
        Title = "Distance Culling",
        Description = "Hide ESP for distant players",
        Default = Settings.Performance.DistanceCulling,
        Callback = function(state)
            Settings.Performance.DistanceCulling = state
        end
    })
    
    DistanceSection:Toggle({
        Title = "Occlusion Culling",
        Description = "Hide ESP for players behind walls",
        Default = Settings.Performance.OcclusionCulling,
        Callback = function(state)
            Settings.Performance.OcclusionCulling = state
        end
    })
    
    local FeaturesSection = MainTab:Section({
        Title = "ESP Features",
        Icon = "list",
        Side = "Right"
    })
    
    FeaturesSection:Toggle({
        Title = "Box ESP",
        Description = "Show boxes around players",
        Default = Settings.BoxESP,
        Icon = "square",
        Callback = function(state)
            Settings.BoxESP = state
        end
    })
    
    FeaturesSection:Toggle({
        Title = "Name ESP",
        Description = "Show player names",
        Default = Settings.NameESP,
        Icon = "type",
        Callback = function(state)
            Settings.NameESP = state
        end
    })
    
    FeaturesSection:Toggle({
        Title = "Tracer ESP",
        Description = "Show lines pointing to players",
        Default = Settings.TracerESP,
        Icon = "trending-up",
        Callback = function(state)
            Settings.TracerESP = state
        end
    })
    
    FeaturesSection:Toggle({
        Title = "Health ESP",
        Description = "Show health bars",
        Default = Settings.HealthESP,
        Icon = "heart",
        Callback = function(state)
            Settings.HealthESP = state
        end
    })
    
    FeaturesSection:Toggle({
        Title = "Skeleton ESP",
        Description = "Show player bone structure",
        Default = Settings.SkeletonESP,
        Icon = "activity",
        Callback = function(state)
            Settings.SkeletonESP = state
        end
    })
    
    FeaturesSection:Toggle({
        Title = "Chams",
        Description = "Show player highlights",
        Default = Settings.ChamsEnabled,
        Icon = "layers",
        Callback = function(state)
            Settings.ChamsEnabled = state
        end
    })
    
    local EffectsSection = MainTab:Section({
        Title = "Visual Effects",
        Icon = "droplet",
        Side = "Right"
    })
    
    EffectsSection:Toggle({
        Title = "Rainbow Effect",
        Description = "Apply rainbow color cycling",
        Default = Settings.RainbowEnabled,
        Icon = "rainbow",
        Callback = function(state)
            Settings.RainbowEnabled = state
        end
    })
    
    EffectsSection:Slider({
        Title = "Rainbow Speed",
        Description = "Speed of color cycling",
        Default = Settings.RainbowSpeed,
        Min = 0.1,
        Max = 5,
        Decimals = 1,
        ValueFormat = "%.1fx",
        Callback = function(value)
            Settings.RainbowSpeed = value
        end
    })
    
    -- Box ESP Tab with detailed box customization
    local BoxEnableSection = BoxESPTab:Section({
        Title = "Box ESP Settings",
        Icon = "square",
        Side = "Left"
    })
    
    BoxEnableSection:Toggle({
        Title = "Enable Box ESP",
        Description = "Show boxes around players",
        Default = Settings.BoxESP,
        Icon = "check-square",
        Callback = function(state)
            Settings.BoxESP = state
        end
    })
    
    BoxEnableSection:Dropdown({
        Title = "Box Style",
        Description = "Choose box visualization style",
        Default = "Corner",
        Icon = "layout",
        List = {"Corner", "Full", "ThreeD"},
        Multi = false,
        Callback = function(option)
            if type(option) == "string" then
                Settings.BoxStyle = option
            end
        end
    })
    
    BoxEnableSection:Toggle({
        Title = "Box Outline",
        Description = "Add outline to boxes for better visibility",
        Default = Settings.BoxOutline,
        Icon = "square",
        Callback = function(state)
            Settings.BoxOutline = state
        end
    })
    
    BoxEnableSection:Toggle({
        Title = "Filled Boxes",
        Description = "Fill boxes with transparent color",
        Default = Settings.BoxFilled,
        Icon = "square",
        Callback = function(state)
            Settings.BoxFilled = state
        end
    })
    
    local BoxStyleSection = BoxESPTab:Section({
        Title = "Box Appearance",
        Icon = "edit",
        Side = "Left"
    })
    
    BoxStyleSection:Slider({
        Title = "Box Thickness",
        Description = "Line thickness for boxes",
        Default = Settings.BoxThickness,
        Min = 0.5,
        Max = 5,
        Decimals = 1,
        ValueFormat = "%.1fpx",
        Callback = function(value)
            Settings.BoxThickness = value
        end
    })
    
    BoxStyleSection:Slider({
        Title = "Corner Length",
        Description = "Length of corner segments (Corner style)",
        Default = Settings.Box.CornerLength or 8,
        Min = 4,
        Max = 20,
        ValueFormat = "%dpx",
        Callback = function(value)
            if not Settings.Box then Settings.Box = {} end
            Settings.Box.CornerLength = value
        end
    })
    
    BoxStyleSection:Slider({
        Title = "Fill Transparency",
        Description = "Transparency for filled boxes",
        Default = Settings.BoxFillTransparency,
        Min = 0,
        Max = 1,
        Decimals = 2,
        ValueFormat = "%.2f",
        Callback = function(value)
            Settings.BoxFillTransparency = value
        end
    })
    
    local BoxColorSection = BoxESPTab:Section({
        Title = "Box Colors",
        Icon = "droplet",
        Side = "Right"
    })
    
    BoxColorSection:ColorPicker({
        Title = "Enemy Box Color",
        Description = "Color for enemy player boxes",
        Default = Colors.Enemy,
        Callback = function(color)
            Colors.Enemy = color
        end
    })
    
    BoxColorSection:ColorPicker({
        Title = "Ally Box Color",
        Description = "Color for teammate boxes",
        Default = Colors.Ally,
        Callback = function(color)
            Colors.Ally = color
        end
    })
    
    BoxColorSection:Toggle({
        Title = "Rainbow Boxes",
        Description = "Apply rainbow effect to boxes",
        Default = Settings.RainbowBoxes,
        Icon = "rainbow",
        Callback = function(state)
            Settings.RainbowBoxes = state
        end
    })
    
    local BoxAdvancedSection = BoxESPTab:Section({
        Title = "Advanced Options",
        Icon = "settings",
        Side = "Right"
    })
    
    BoxAdvancedSection:Toggle({
        Title = "Auto-Scale",
        Description = "Automatically scale box thickness with distance",
        Default = Settings.Box.AutoScale or true,
        Callback = function(state)
            if not Settings.Box then Settings.Box = {} end
            Settings.Box.AutoScale = state
        end
    })
    
    BoxAdvancedSection:Toggle({
        Title = "Show Distance",
        Description = "Show distance to player on box",
        Default = Settings.ShowDistance,
        Callback = function(state)
            Settings.ShowDistance = state
        end
    })
    
    -- Tracer Tab with comprehensive tracer customization
    local TracerEnableSection = TracerTab:Section({
        Title = "Tracer Settings",
        Icon = "trending-up",
        Side = "Left"
    })
    
    TracerEnableSection:Toggle({
        Title = "Enable Tracers",
        Description = "Show lines pointing to players",
        Default = Settings.TracerESP,
        Icon = "target",
        Callback = function(state)
            Settings.TracerESP = state
        end
    })
    
    TracerEnableSection:Dropdown({
        Title = "Tracer Origin",
        Description = "Where tracers start from",
        Default = "Bottom",
        Icon = "navigation",
        List = {"Bottom", "Top", "Mouse", "Center"},
        Multi = false,
        Callback = function(option)
            if type(option) == "string" then
                Settings.TracerOrigin = option
            end
        end
    })
    
    TracerEnableSection:Dropdown({
        Title = "Tracer Style",
        Description = "Visual style of tracer lines",
        Default = "Line",
        Icon = "minus",
        List = {"Line", "Dashed", "Dotted"},
        Multi = false,
        Callback = function(option)
            if type(option) == "string" then
                Settings.TracerStyle = option
            end
        end
    })
    
    local TracerAppearanceSection = TracerTab:Section({
        Title = "Tracer Appearance",
        Icon = "edit-2",
        Side = "Left"
    })
    
    TracerAppearanceSection:Slider({
        Title = "Tracer Thickness",
        Description = "Line thickness for tracers",
        Default = Settings.TracerThickness,
        Min = 0.5,
        Max = 5,
        Decimals = 1,
        ValueFormat = "%.1fpx",
        Callback = function(value)
            Settings.TracerThickness = value
        end
    })
    
    TracerAppearanceSection:Toggle({
        Title = "Auto-Scale",
        Description = "Automatically scale tracer thickness with distance",
        Default = Settings.Tracer.AutoScale or true,
        Icon = "zoom-in",
        Callback = function(state)
            if not Settings.Tracer then Settings.Tracer = {} end
            Settings.Tracer.AutoScale = state
        end
    })
    
    TracerAppearanceSection:Slider({
        Title = "Tracer Transparency",
        Description = "Transparency of tracer lines",
        Default = Settings.Tracer.Transparency or 1,
        Min = 0,
        Max = 1,
        Decimals = 2,
        ValueFormat = "%.2f",
        Callback = function(value)
            if not Settings.Tracer then Settings.Tracer = {} end
            Settings.Tracer.Transparency = value
        end
    })
    
    local TracerColorSection = TracerTab:Section({
        Title = "Tracer Colors",
        Icon = "droplet",
        Side = "Right"
    })
    
    TracerColorSection:ColorPicker({
        Title = "Enemy Tracer Color",
        Description = "Color for enemy player tracers",
        Default = Colors.Enemy,
        Callback = function(color)
            Colors.Enemy = color
        end
    })
    
    TracerColorSection:ColorPicker({
        Title = "Ally Tracer Color",
        Description = "Color for teammate tracers",
        Default = Colors.Ally,
        Callback = function(color)
            Colors.Ally = color
        end
    })
    
    TracerColorSection:Toggle({
        Title = "Rainbow Tracers",
        Description = "Apply rainbow effect to tracers",
        Default = Settings.RainbowTracers,
        Icon = "rainbow",
        Callback = function(state)
            Settings.RainbowTracers = state
        end
    })
    
    local SnaplineSection = TracerTab:Section({
        Title = "Snaplines",
        Icon = "git-commit",
        Side = "Right"
    })
    
    SnaplineSection:Toggle({
        Title = "Enable Snaplines",
        Description = "Show direct lines from screen bottom to players",
        Default = Settings.Snaplines,
        Icon = "arrow-up",
        Callback = function(state)
            Settings.Snaplines = state
        end
    })
    
    SnaplineSection:Dropdown({
        Title = "Snapline Style",
        Description = "Visual style of snaplines",
        Default = "Straight",
        Icon = "minus",
        List = {"Straight", "Dashed", "Dotted"},
        Multi = false,
        Callback = function(option)
            if type(option) == "string" then
                Settings.SnaplineStyle = option
            end
        end
    })
    
    SnaplineSection:Slider({
        Title = "Snapline Thickness",
        Description = "Line thickness for snaplines",
        Default = Settings.Snapline.Thickness or 1,
        Min = 0.5,
        Max = 5,
        Decimals = 1,
        ValueFormat = "%.1fpx",
        Callback = function(value)
            if not Settings.Snapline then Settings.Snapline = {} end
            Settings.Snapline.Thickness = value
        end
    })
    
    -- Skeleton Tab with bone visualization settings
    local SkeletonEnableSection = SkeletonTab:Section({
        Title = "Skeleton Settings",
        Icon = "activity",
        Side = "Left"
    })
    
    SkeletonEnableSection:Toggle({
        Title = "Enable Skeleton ESP",
        Description = "Show player bone structure",
        Default = Settings.SkeletonESP,
        Icon = "activity",
        Callback = function(state)
            Settings.SkeletonESP = state
        end
    })
    
    local SkeletonAppearanceSection = SkeletonTab:Section({
        Title = "Bone Appearance",
        Icon = "edit-2",
        Side = "Left"
    })
    
    SkeletonAppearanceSection:ColorPicker({
        Title = "Skeleton Color",
        Description = "Color for skeleton lines",
        Default = Settings.SkeletonColor,
        Callback = function(color)
            Settings.SkeletonColor = color
            for _, player in ipairs(Players:GetPlayers()) do
                local skeleton = Drawings.Skeleton[player]
                if skeleton then
                    for _, line in pairs(skeleton) do
                        line.Color = color
                    end
                end
            end
        end
    })
    
    SkeletonAppearanceSection:Slider({
        Title = "Line Thickness",
        Description = "Thickness of skeleton lines",
        Default = Settings.SkeletonThickness,
        Min = 0.5,
        Max = 3,
        Decimals = 1,
        ValueFormat = "%.1fpx",
        Callback = function(value)
            Settings.SkeletonThickness = value
            for _, player in ipairs(Players:GetPlayers()) do
                local skeleton = Drawings.Skeleton[player]
                if skeleton then
                    for _, line in pairs(skeleton) do
                        line.Thickness = value
                    end
                end
            end
        end
    })
    
    SkeletonAppearanceSection:Slider({
        Title = "Transparency",
        Description = "Transparency of skeleton lines",
        Default = Settings.SkeletonTransparency,
        Min = 0,
        Max = 1,
        Decimals = 2,
        ValueFormat = "%.2f",
        Callback = function(value)
            Settings.SkeletonTransparency = value
            for _, player in ipairs(Players:GetPlayers()) do
                local skeleton = Drawings.Skeleton[player]
                if skeleton then
                    for _, line in pairs(skeleton) do
                        line.Transparency = value
                    end
                end
            end
        end
    })
    
    local SkeletonOptionsSection = SkeletonTab:Section({
        Title = "Bone Options",
        Icon = "sliders",
        Side = "Right"
    })
    
    SkeletonOptionsSection:Toggle({
        Title = "Show Head Connection",
        Description = "Display line connecting head to torso",
        Default = Settings.Skeleton.ShowHead or true,
        Icon = "user",
        Callback = function(state)
            if not Settings.Skeleton then Settings.Skeleton = {} end
            Settings.Skeleton.ShowHead = state
        end
    })
    
    SkeletonOptionsSection:Toggle({
        Title = "Show Arms",
        Description = "Display arm bones",
        Default = Settings.Skeleton.ShowArms or true,
        Icon = "thumbs-up",
        Callback = function(state)
            if not Settings.Skeleton then Settings.Skeleton = {} end
            Settings.Skeleton.ShowArms = state
        end
    })
    
    SkeletonOptionsSection:Toggle({
        Title = "Show Legs",
        Description = "Display leg bones",
        Default = Settings.Skeleton.ShowLegs or true,
        Icon = "activity",
        Callback = function(state)
            if not Settings.Skeleton then Settings.Skeleton = {} end
            Settings.Skeleton.ShowLegs = state
        end
    })
    
    SkeletonOptionsSection:Toggle({
        Title = "Rainbow Skeleton",
        Description = "Apply rainbow effect to skeleton",
        Default = Settings.Skeleton.Rainbow or false,
        Icon = "rainbow",
        Callback = function(state)
            if not Settings.Skeleton then Settings.Skeleton = {} end
            Settings.Skeleton.Rainbow = state
        end
    })
    
    -- Chams Tab with highlight customization
    local ChamsEnableSection = ChamsTab:Section({
        Title = "Chams Settings",
        Icon = "layers",
        Side = "Left"
    })
    
    ChamsEnableSection:Toggle({
        Title = "Enable Chams",
        Description = "Show player highlights through walls",
        Default = Settings.ChamsEnabled,
        Icon = "eye",
        Callback = function(state)
            Settings.ChamsEnabled = state
        end
    })
    
    ChamsEnableSection:Toggle({
        Title = "Show Through Walls",
        Description = "Make players visible through walls",
        Default = Settings.Chams.ShowThroughWalls or true,
        Icon = "eye",
        Callback = function(state)
            if not Settings.Chams then Settings.Chams = {} end
            Settings.Chams.ShowThroughWalls = state
        end
    })
    
    ChamsEnableSection:Toggle({
        Title = "Use Team Colors",
        Description = "Apply team colors to chams",
        Default = Settings.Chams.UseTeamColors or true,
        Icon = "users",
        Callback = function(state)
            if not Settings.Chams then Settings.Chams = {} end
            Settings.Chams.UseTeamColors = state
        end
    })
    
    local ChamsColorSection = ChamsTab:Section({
        Title = "Chams Colors",
        Icon = "droplet",
        Side = "Left"
    })
    
    ChamsColorSection:ColorPicker({
        Title = "Fill Color",
        Description = "Color for visible parts",
        Default = Settings.ChamsFillColor,
        Callback = function(color)
            Settings.ChamsFillColor = color
        end
    })
    
    ChamsColorSection:ColorPicker({
        Title = "Outline Color",
        Description = "Color for character outline",
        Default = Settings.ChamsOutlineColor,
        Callback = function(color)
            Settings.ChamsOutlineColor = color
        end
    })
    
    ChamsColorSection:ColorPicker({
        Title = "Occluded Color",
        Description = "Color for parts behind walls",
        Default = Settings.ChamsOccludedColor,
        Callback = function(color)
            Settings.ChamsOccludedColor = color
        end
    })
    
    local ChamsAppearanceSection = ChamsTab:Section({
        Title = "Chams Appearance",
        Icon = "sliders",
        Side = "Right"
    })
    
    ChamsAppearanceSection:Slider({
        Title = "Fill Transparency",
        Description = "Transparency of the fill color",
        Default = Settings.ChamsTransparency,
        Min = 0,
        Max = 1,
        Decimals = 2,
        ValueFormat = "%.2f",
        Callback = function(value)
            Settings.ChamsTransparency = value
        end
    })
    
    ChamsAppearanceSection:Slider({
        Title = "Outline Transparency",
        Description = "Transparency of the outline",
        Default = Settings.ChamsOutlineTransparency,
        Min = 0,
        Max = 1,
        Decimals = 2,
        ValueFormat = "%.2f",
        Callback = function(value)
            Settings.ChamsOutlineTransparency = value
        end
    })
    
    ChamsAppearanceSection:Slider({
        Title = "Outline Thickness",
        Description = "Thickness of the outline",
        Default = Settings.ChamsOutlineThickness,
        Min = 0,
        Max = 1,
        Decimals = 2,
        ValueFormat = "%.2f",
        Callback = function(value)
            Settings.ChamsOutlineThickness = value
        end
    })
    
    ChamsAppearanceSection:Dropdown({
        Title = "Chams Mode",
        Description = "Visual style for chams",
        Default = "AlwaysOnTop",
        Icon = "layers",
        List = {"AlwaysOnTop", "Occluded", "Both"},
        Multi = false,
        Callback = function(option)
            if not Settings.Chams then Settings.Chams = {} end
            if type(option) == "string" then
                Settings.Chams.Mode = option
            end
        end
    })
    
    -- Settings Tab with comprehensive configuration options
    local PerformanceSection = SettingsTab:Section({
        Title = "Performance Settings",
        Icon = "cpu",
        Side = "Left"
    })
    
    PerformanceSection:Slider({
        Title = "Refresh Rate",
        Description = "ESP update frequency",
        Default = 1/Settings.RefreshRate,
        Min = 15,
        Max = 144,
        ValueFormat = "%d FPS",
        Icon = "refresh-cw",
        Callback = function(value)
            Settings.RefreshRate = 1/value
        end
    })
    
    PerformanceSection:Toggle({
        Title = "Visibility Check",
        Description = "Check if players are visible",
        Default = Settings.VisibilityCheck,
        Icon = "eye",
        Callback = function(state)
            Settings.VisibilityCheck = state
        end
    })
    
    PerformanceSection:Toggle({
        Title = "Batch Rendering",
        Description = "Optimize ESP updates for better performance",
        Default = Settings.Performance.BatchRendering or true,
        Icon = "layers",
        Callback = function(state)
            if not Settings.Performance then Settings.Performance = {} end
            Settings.Performance.BatchRendering = state
        end
    })
    
    PerformanceSection:Slider({
        Title = "Batch Size",
        Description = "Number of players to update per frame",
        Default = Settings.Performance.BatchSize or 5,
        Min = 1,
        Max = 10,
        ValueFormat = "%d players",
        Icon = "users",
        Callback = function(value)
            if not Settings.Performance then Settings.Performance = {} end
            Settings.Performance.BatchSize = value
        end
    })
    
    local TextSection = SettingsTab:Section({
        Title = "Text Settings",
        Icon = "type",
        Side = "Left"
    })
    
    TextSection:Slider({
        Title = "Text Size",
        Description = "Size of ESP text elements",
        Default = Settings.TextSize,
        Min = 10,
        Max = 24,
        ValueFormat = "%dpx",
        Icon = "type",
        Callback = function(value)
            Settings.TextSize = value
        end
    })
    
    TextSection:Dropdown({
        Title = "Text Font",
        Description = "Font for ESP text elements",
        Default = "SourceSans",
        Icon = "type",
        List = {"SourceSans", "SourceSansBold", "Gotham", "GothamBold", "Arial", "ArialBold"},
        Multi = false,
        Callback = function(option)
            if type(option) == "string" then
                if option == "SourceSans" then
                    Settings.TextFont = 0
                elseif option == "SourceSansBold" then
                    Settings.TextFont = 1
                elseif option == "Gotham" then
                    Settings.TextFont = 2
                elseif option == "GothamBold" then
                    Settings.TextFont = 3
                elseif option == "Arial" then
                    Settings.TextFont = 4
                elseif option == "ArialBold" then
                    Settings.TextFont = 5
                end
            end
        end
    })
    
    TextSection:Dropdown({
        Title = "Health Text Format",
        Description = "Format of health display",
        Default = "Number",
        Icon = "heart",
        List = {"Number", "Percentage", "Both"},
        Multi = false,
        Callback = function(option)
            if type(option) == "string" then
                Settings.HealthTextFormat = option
            end
        end
    })
    
    TextSection:Input({
        Title = "Health Text Suffix",
        Description = "Text to display after health value",
        Default = Settings.HealthTextSuffix or "HP",
        Placeholder = "HP",
        Icon = "edit-3",
        Callback = function(text)
            Settings.HealthTextSuffix = text
        end
    })
    
    local DistanceSection = SettingsTab:Section({
        Title = "Distance Settings",
        Icon = "map-pin",
        Side = "Right"
    })
    
    DistanceSection:Toggle({
        Title = "Show Distance",
        Description = "Display distance to players",
        Default = Settings.ShowDistance,
        Icon = "ruler",
        Callback = function(state)
            Settings.ShowDistance = state
        end
    })
    
    DistanceSection:Dropdown({
        Title = "Distance Unit",
        Description = "Unit for distance measurements",
        Default = "studs",
        Icon = "ruler",
        List = {"studs", "m", "ft"},
        Multi = false,
        Callback = function(option)
            if type(option) == "string" then
                Settings.DistanceUnit = option
            end
        end
    })
    
    DistanceSection:Slider({
        Title = "Distance Precision",
        Description = "Number of decimal places for distance",
        Default = Settings.DistancePrecision or 0,
        Min = 0,
        Max = 2,
        ValueFormat = "%d decimals",
        Icon = "edit-2",
        Callback = function(value)
            Settings.DistancePrecision = value
        end
    })
    
    local ControlsSection = SettingsTab:Section({
        Title = "Controls",
        Icon = "settings",
        Side = "Right"
    })
    
    ControlsSection:Button({
        Title = "Reset Settings",
        Description = "Reset all ESP settings to default",
        Icon = "refresh-cw",
        Callback = function()
            CleanupESP()
            
            Settings = {
                Enabled = false,
                TeamCheck = false,
                ShowTeam = false,
                VisibilityCheck = true,
                BoxESP = false,
                BoxStyle = "Corner",
                BoxOutline = true,
                BoxFilled = false,
                BoxFillTransparency = 0.5,
                BoxThickness = 1,
                TracerESP = false,
                TracerOrigin = "Bottom",
                TracerStyle = "Line",
                TracerThickness = 1,
                HealthESP = false,
                HealthStyle = "Bar",
                HealthBarSide = "Left",
                HealthTextSuffix = "HP",
                NameESP = false,
                NameMode = "DisplayName",
                ShowDistance = true,
                DistanceUnit = "studs",
                TextSize = 14,
                TextFont = 2,
                RainbowSpeed = 1,
                MaxDistance = 1000,
                RefreshRate = 1/144,
                Snaplines = false,
                SnaplineStyle = "Straight",
                RainbowEnabled = false,
                RainbowBoxes = false,
                RainbowTracers = false,
                RainbowText = false,
                ChamsEnabled = false,
                ChamsOutlineColor = Color3.fromRGB(255, 255, 255),
                ChamsFillColor = Color3.fromRGB(255, 0, 0),
                ChamsOccludedColor = Color3.fromRGB(150, 0, 0),
                ChamsTransparency = 0.5,
                ChamsOutlineTransparency = 0,
                ChamsOutlineThickness = 0.1,
                SkeletonESP = false,
                SkeletonColor = Color3.fromRGB(255, 255, 255),
                SkeletonThickness = 1.5,
                SkeletonTransparency = 1,
                Performance = {
                    BatchRendering = true,
                    BatchSize = 5,
                    DistanceCulling = true,
                    OcclusionCulling = true
                },
                Box = {},
                Tracer = {},
                Skeleton = {},
                Chams = {},
                Snapline = {}
            }
            
            Notify:Update({
                Title = "Settings Reset",
                Description = "All ESP settings have been reset to default"
            })
        end
    })
    
    ControlsSection:Button({
        Title = "Unload ESP",
        Description = "Completely unload ESP and UI",
        Icon = "x-circle",
        Callback = function()
            -- Clean up all ESP objects
            CleanupESP()
            
            -- Destroy UI
            Window:Destroy()
            
            Notify:Update({
                Title = "ESP Unloaded",
                Description = "Universal ESP Pro Advanced has been unloaded"
            })
        end
    })
    
    -- DevCopy Tools Section
    local DevToolsSection = SettingsTab:Section({
        Title = "Developer Tools",
        Icon = "code",
        Side = "Left"
    })
    
    DevToolsSection:Button({
        Title = "Copy Console Log",
        Description = "Copy developer console logs to clipboard",
        Icon = "clipboard",
        Callback = function()
            -- Try to refresh DevCopy
            local refreshSuccess, refreshResult = pcall(function()
                -- Attempt to reload DevCopy to refresh console content
                local response = game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Useful/DevCopy")
                return loadstring(response)()
            end)
            
            if refreshSuccess then
                Notify:Update({
                    Title = "DevCopy",
                    Description = "Console logs copied to clipboard!"
                })
            else
                Notify:Update({
                    Title = "DevCopy Error",
                    Description = "Failed to copy console logs: " .. tostring(refreshResult)
                })
            end
        end
    })
    
    DevToolsSection:Button({
        Title = "Copy Script Loadstring",
        Description = "Copy loadstring for this ESP script",
        Icon = "code",
        Callback = function()
            local loadstringText = 'loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Examples/Universal_ESP_Pro_Advanced.lua"))()'
            
            local copySuccess = pcall(function()
                if setclipboard then
                    setclipboard(loadstringText)
                elseif toclipboard then
                    toclipboard(loadstringText)
                elseif Clipboard and Clipboard.set then
                    Clipboard.set(loadstringText)
                else
                    error("No clipboard function found")
                end
            end)
            
            if copySuccess then
                Notify:Update({
                    Title = "Loadstring Copied",
                    Description = "ESP script loadstring copied to clipboard!"
                })
            else
                Notify:Update({
                    Title = "Copy Error",
                    Description = "Failed to copy loadstring to clipboard"
                })
            end
        end
    })
    
    DevToolsSection:Button({
        Title = "Print Settings to Console",
        Description = "Output current settings to developer console",
        Icon = "terminal",
        Callback = function()
            print("\n=== UNIVERSAL ESP PRO ADVANCED SETTINGS ===")
            for setting, value in pairs(Settings) do
                if type(value) ~= "table" then
                    print(setting .. ": " .. tostring(value))
                else
                    print(setting .. ": [Table]")
                    for subSetting, subValue in pairs(value) do
                        print("  " .. subSetting .. ": " .. tostring(subValue))
                    end
                end
            end
            print("=== END OF SETTINGS ===\n")
            
            Notify:Update({
                Title = "Settings Printed",
                Description = "Current settings output to developer console"
            })
        end
    })
    
    -- UI Keybinds
    local function toggleUI()
        Window.Enabled = not Window.Enabled
    end
    
    -- Keybind configuration
    local KeybindSection = SettingsTab:Section({
        Title = "Keybinds",
        Icon = "key",
        Side = "Right"
    })
    
    KeybindSection:Label({
        Title = "Toggle UI",
        Description = "Press Left Ctrl to show/hide the UI",
        Icon = "eye"
    })
    
    KeybindSection:Label({
        Title = "Hide UI",
        Description = "Press Delete to hide the UI",
        Icon = "eye-off"
    })
    
    -- Left Ctrl to toggle UI
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed then
            if input.KeyCode == Enum.KeyCode.LeftControl then
                toggleUI()
            elseif input.KeyCode == Enum.KeyCode.Delete then
                Window.Enabled = false
            end
        end
    end)
    
    -- Final notifications with styled console output
    print("\n" .. string.rep("=", 40))
    print("✅ Universal ESP Pro Advanced v2.0")
    print("📊 Features: Box ESP, Tracers, Skeleton, Chams & more")
    print("⌨️ Press Left Ctrl to toggle UI | Delete to hide UI")
    print(string.rep("=", 40) .. "\n")
    
    -- Initial UI setup
    Window:SelectTab(1) -- Select Main tab by default
else
    -- Headless mode (no UI)
    print("\n" .. string.rep("=", 40))
    print("⚠️ Bracket UI not available, running in headless mode")
    print("📊 ESP features will still work without UI")
    print("💻 Use _G.UniversalESP API to control ESP programmatically")
    print(string.rep("=", 40) .. "\n")
end

-- ===================================
-- MAIN EXECUTION
-- ===================================

-- Initialize ESP for existing players
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

-- Connect player events
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

-- Main update loop
local lastUpdate = 0
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then 
        DisableESP()
        return 
    end
    
    local currentTime = tick()
    if currentTime - lastUpdate >= Settings.RefreshRate then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not Drawings.ESP[player] then
                    CreateESP(player)
                end
                UpdateESP(player)
            end
        end
        lastUpdate = currentTime
    end
end)

-- Export API to global environment
if getgenv then
    getgenv().UniversalESP = {
        Settings = Settings,
        Colors = Colors,
        Toggle = function(state) Settings.Enabled = state end,
        ToggleBox = function(state) Settings.BoxESP = state end,
        ToggleName = function(state) Settings.NameESP = state end,
        ToggleTracer = function(state) Settings.TracerESP = state end,
        ToggleHealth = function(state) Settings.HealthESP = state end,
        ToggleSkeleton = function(state) Settings.SkeletonESP = state end,
        ToggleChams = function(state) Settings.ChamsEnabled = state end,
        SetMaxDistance = function(distance) Settings.MaxDistance = distance end,
        SetRefreshRate = function(fps) Settings.RefreshRate = 1/fps end,
        SetBoxStyle = function(style) Settings.BoxStyle = style end,
        SetTracerOrigin = function(origin) Settings.TracerOrigin = origin end,
        Cleanup = CleanupESP
    }
    print("🏁 Universal ESP Pro Advanced functions exported to getgenv().UniversalESP")
else
    _G.UniversalESP = {
        Settings = Settings,
        Colors = Colors,
        Toggle = function(state) Settings.Enabled = state end,
        ToggleBox = function(state) Settings.BoxESP = state end,
        ToggleName = function(state) Settings.NameESP = state end,
        ToggleTracer = function(state) Settings.TracerESP = state end,
        ToggleHealth = function(state) Settings.HealthESP = state end,
        ToggleSkeleton = function(state) Settings.SkeletonESP = state end,
        ToggleChams = function(state) Settings.ChamsEnabled = state end,
        SetMaxDistance = function(distance) Settings.MaxDistance = distance end,
        SetRefreshRate = function(fps) Settings.RefreshRate = 1/fps end,
        SetBoxStyle = function(style) Settings.BoxStyle = style end,
        SetTracerOrigin = function(origin) Settings.TracerOrigin = origin end,
        Cleanup = CleanupESP
    }
    print("🏁 Universal ESP Pro Advanced functions exported to _G.UniversalESP")
end

print("✅ Universal ESP Pro Advanced loaded successfully!")
print("🎮 Use Left Ctrl to toggle UI visibility")

