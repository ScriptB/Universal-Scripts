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
    -- Create notification system
    local Notify = Bracket:Notification({
        Title = "Universal ESP Pro Advanced",
        Description = "ESP system loaded successfully!",
        Duration = 5
    })
    
    -- Create main window
    local Window = Bracket:Window({
        Title = "Universal ESP Pro Advanced",
        Position = UDim2.new(0.05, 0, 0.5, 0),
        Size = UDim2.new(0, 550, 0, 450),
        Transparency = 0.8
    })
    
    -- Create tabs
    local ESPTab = Window:Tab({ Title = "ESP" })
    local VisualsTab = Window:Tab({ Title = "Visuals" })
    local SkeletonTab = Window:Tab({ Title = "Skeleton" })
    local ChamsTab = Window:Tab({ Title = "Chams" })
    local SettingsTab = Window:Tab({ Title = "Settings" })
    
    -- ESP Tab
    ESPTab:Toggle({
        Title = "Enable ESP",
        Description = "Toggle all ESP features",
        Default = Settings.Enabled,
        Callback = function(state)
            Settings.Enabled = state
            if not state then
                DisableESP()
            end
        end
    })
    
    ESPTab:Toggle({
        Title = "Team Check",
        Description = "Use team colors for ESP",
        Default = Settings.TeamCheck,
        Callback = function(state)
            Settings.TeamCheck = state
        end
    })
    
    ESPTab:Toggle({
        Title = "Show Team",
        Description = "Show ESP for teammates",
        Default = Settings.ShowTeam,
        Callback = function(state)
            Settings.ShowTeam = state
        end
    })
    
    ESPTab:Slider({
        Title = "Max Distance",
        Description = "Maximum distance for ESP visibility",
        Default = Settings.MaxDistance,
        Min = 100,
        Max = 5000,
        Callback = function(value)
            Settings.MaxDistance = value
        end
    })
    
    ESPTab:Divider({ Text = "ESP Types", Side = "Left" })
    
    ESPTab:Toggle({
        Title = "Box ESP",
        Description = "Show boxes around players",
        Default = Settings.BoxESP,
        Side = "Left",
        Callback = function(state)
            Settings.BoxESP = state
        end
    })
    
    ESPTab:Dropdown({
        Title = "Box Style",
        Description = "Style of the ESP box",
        Default = Settings.BoxStyle,
        Side = "Left",
        List = {"Corner", "Full", "ThreeD"},
        Callback = function(option)
            Settings.BoxStyle = option
        end
    })
    
    ESPTab:Toggle({
        Title = "Name ESP",
        Description = "Show player names",
        Default = Settings.NameESP,
        Side = "Left",
        Callback = function(state)
            Settings.NameESP = state
        end
    })
    
    ESPTab:Toggle({
        Title = "Tracer ESP",
        Description = "Show lines pointing to players",
        Default = Settings.TracerESP,
        Side = "Left",
        Callback = function(state)
            Settings.TracerESP = state
        end
    })
    
    ESPTab:Dropdown({
        Title = "Tracer Origin",
        Description = "Where tracers start from",
        Default = Settings.TracerOrigin,
        Side = "Left",
        List = {"Bottom", "Top", "Mouse", "Center"},
        Callback = function(option)
            Settings.TracerOrigin = option
        end
    })
    
    ESPTab:Toggle({
        Title = "Health ESP",
        Description = "Show health bars",
        Default = Settings.HealthESP,
        Side = "Right",
        Callback = function(state)
            Settings.HealthESP = state
        end
    })
    
    ESPTab:Dropdown({
        Title = "Health Style",
        Description = "Style of health display",
        Default = Settings.HealthStyle,
        Side = "Right",
        List = {"Bar", "Text", "Both"},
        Callback = function(option)
            Settings.HealthStyle = option
        end
    })
    
    ESPTab:Toggle({
        Title = "Snaplines",
        Description = "Show lines from screen bottom to players",
        Default = Settings.Snaplines,
        Side = "Right",
        Callback = function(state)
            Settings.Snaplines = state
        end
    })
    
    -- Visuals Tab
    VisualsTab:Divider({ Text = "Colors", Side = "Left" })
    
    VisualsTab:ColorPicker({
        Title = "Enemy Color",
        Description = "Color for enemy players",
        Default = Colors.Enemy,
        Side = "Left",
        Callback = function(color)
            Colors.Enemy = color
        end
    })
    
    VisualsTab:ColorPicker({
        Title = "Ally Color",
        Description = "Color for team members",
        Default = Colors.Ally,
        Side = "Left",
        Callback = function(color)
            Colors.Ally = color
        end
    })
    
    VisualsTab:ColorPicker({
        Title = "Health Color",
        Description = "Color for full health",
        Default = Colors.Health,
        Side = "Left",
        Callback = function(color)
            Colors.Health = color
        end
    })
    
    VisualsTab:Divider({ Text = "Effects", Side = "Right" })
    
    VisualsTab:Toggle({
        Title = "Rainbow Effect",
        Description = "Apply rainbow color effect to ESP",
        Default = Settings.RainbowEnabled,
        Side = "Right",
        Callback = function(state)
            Settings.RainbowEnabled = state
        end
    })
    
    VisualsTab:Slider({
        Title = "Rainbow Speed",
        Description = "Speed of rainbow color cycling",
        Default = Settings.RainbowSpeed,
        Min = 0.1,
        Max = 5,
        Decimals = 1,
        Side = "Right",
        Callback = function(value)
            Settings.RainbowSpeed = value
        end
    })
    
    VisualsTab:Toggle({
        Title = "Rainbow Boxes",
        Description = "Apply rainbow effect to boxes",
        Default = Settings.RainbowBoxes,
        Side = "Right",
        Callback = function(state)
            Settings.RainbowBoxes = state
        end
    })
    
    VisualsTab:Toggle({
        Title = "Rainbow Tracers",
        Description = "Apply rainbow effect to tracers",
        Default = Settings.RainbowTracers,
        Side = "Right",
        Callback = function(state)
            Settings.RainbowTracers = state
        end
    })
    
    VisualsTab:Toggle({
        Title = "Rainbow Text",
        Description = "Apply rainbow effect to text",
        Default = Settings.RainbowText,
        Side = "Right",
        Callback = function(state)
            Settings.RainbowText = state
        end
    })
    
    -- Skeleton Tab
    SkeletonTab:Toggle({
        Title = "Skeleton ESP",
        Description = "Show player skeleton",
        Default = Settings.SkeletonESP,
        Callback = function(state)
            Settings.SkeletonESP = state
        end
    })
    
    SkeletonTab:ColorPicker({
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
    
    SkeletonTab:Slider({
        Title = "Line Thickness",
        Description = "Thickness of skeleton lines",
        Default = Settings.SkeletonThickness,
        Min = 0.5,
        Max = 3,
        Decimals = 1,
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
    
    SkeletonTab:Slider({
        Title = "Transparency",
        Description = "Transparency of skeleton lines",
        Default = Settings.SkeletonTransparency,
        Min = 0,
        Max = 1,
        Decimals = 2,
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
    
    -- Chams Tab
    ChamsTab:Toggle({
        Title = "Enable Chams",
        Description = "Show player highlights through walls",
        Default = Settings.ChamsEnabled,
        Callback = function(state)
            Settings.ChamsEnabled = state
        end
    })
    
    ChamsTab:ColorPicker({
        Title = "Fill Color",
        Description = "Color for visible parts",
        Default = Settings.ChamsFillColor,
        Callback = function(color)
            Settings.ChamsFillColor = color
        end
    })
    
    ChamsTab:ColorPicker({
        Title = "Outline Color",
        Description = "Color for character outline",
        Default = Settings.ChamsOutlineColor,
        Callback = function(color)
            Settings.ChamsOutlineColor = color
        end
    })
    
    ChamsTab:ColorPicker({
        Title = "Occluded Color",
        Description = "Color for parts behind walls",
        Default = Settings.ChamsOccludedColor,
        Callback = function(color)
            Settings.ChamsOccludedColor = color
        end
    })
    
    ChamsTab:Slider({
        Title = "Fill Transparency",
        Description = "Transparency of the fill color",
        Default = Settings.ChamsTransparency,
        Min = 0,
        Max = 1,
        Decimals = 2,
        Callback = function(value)
            Settings.ChamsTransparency = value
        end
    })
    
    ChamsTab:Slider({
        Title = "Outline Transparency",
        Description = "Transparency of the outline",
        Default = Settings.ChamsOutlineTransparency,
        Min = 0,
        Max = 1,
        Decimals = 2,
        Callback = function(value)
            Settings.ChamsOutlineTransparency = value
        end
    })
    
    ChamsTab:Slider({
        Title = "Outline Thickness",
        Description = "Thickness of the outline",
        Default = Settings.ChamsOutlineThickness,
        Min = 0,
        Max = 1,
        Decimals = 2,
        Callback = function(value)
            Settings.ChamsOutlineThickness = value
        end
    })
    
    -- Settings Tab
    SettingsTab:Divider({ Text = "Performance", Side = "Left" })
    
    SettingsTab:Slider({
        Title = "Refresh Rate",
        Description = "ESP update frequency (FPS)",
        Default = 1/Settings.RefreshRate,
        Min = 15,
        Max = 144,
        Callback = function(value)
            Settings.RefreshRate = 1/value
        end
    })
    
    SettingsTab:Toggle({
        Title = "Visibility Check",
        Description = "Check if players are visible",
        Default = Settings.VisibilityCheck,
        Side = "Left",
        Callback = function(state)
            Settings.VisibilityCheck = state
        end
    })
    
    SettingsTab:Divider({ Text = "Text Settings", Side = "Right" })
    
    SettingsTab:Slider({
        Title = "Text Size",
        Description = "Size of ESP text",
        Default = Settings.TextSize,
        Min = 10,
        Max = 24,
        Side = "Right",
        Callback = function(value)
            Settings.TextSize = value
        end
    })
    
    SettingsTab:Dropdown({
        Title = "Health Text Format",
        Description = "Format of health display",
        Default = "Number",
        Side = "Right",
        List = {"Number", "Percentage", "Both"},
        Callback = function(option)
            Settings.HealthTextFormat = option
        end
    })
    
    SettingsTab:Divider({ Text = "Controls", Side = "Left" })
    
    SettingsTab:Button({
        Title = "Reset Settings",
        Description = "Reset all ESP settings to default",
        Side = "Left",
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
                SkeletonTransparency = 1
            }
            
            Notify:Update({
                Title = "Settings Reset",
                Description = "All ESP settings have been reset to default"
            })
        end
    })
    
    SettingsTab:Button({
        Title = "Unload ESP",
        Description = "Completely unload ESP and UI",
        Side = "Left",
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
    
    -- DevCopy buttons
    SettingsTab:Divider({ Text = "DevCopy Tools", Side = "Right" })
    
    SettingsTab:Button({
        Title = "Copy Console Log",
        Description = "Copy developer console logs to clipboard",
        Side = "Right",
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
    
    SettingsTab:Button({
        Title = "Copy Script Loadstring",
        Description = "Copy loadstring for this ESP script",
        Side = "Right",
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
    
    -- UI Keybinds
    local function toggleUI()
        Window.Enabled = not Window.Enabled
    end
    
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
    
    -- Final notifications
    print("✅ Universal ESP Pro Advanced UI loaded successfully!")
    print("⌨️ Press Left Ctrl to toggle UI")
else
    print("⚠️ Bracket UI not available, running in headless mode")
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

