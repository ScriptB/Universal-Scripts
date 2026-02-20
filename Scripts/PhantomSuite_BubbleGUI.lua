--[[
	🫧 Phantom Suite - Bubble GUI Edition
	Animated glass bubble interface with blur effects
	Right Control to toggle bubbles
]]

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local plr = Players.LocalPlayer
local camera = workspace.CurrentCamera

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

-- Load NexacLib Modern
local success, NexacLib = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/NexacLib.lua"))()
end)

if not success then
	local success, NexacLib = pcall(function()
		return loadfile("Orion-Library/NexacLib.lua")()
	end)
	if not success then return end
end

NexacLib:Init()

-- Configure advanced FX for glass bubble effects
NexacLib:SetFX({
    Blur = true,
    BlurSize = 15,
    DimBackground = true,
    DimTransparency = 0.4,
    WindowIntro = true,
    TabTransition = true,
    ElementIntro = true,
    Particles = true,
    ParticleCount = 25,
    ParticleSpeed = 20
})

-- Create glass theme for bubbles
local GlassTheme = {
    Main = Color3.fromRGB(255, 255, 255),
    Second = Color3.fromRGB(240, 248, 255),
    Third = Color3.fromRGB(230, 240, 250),
    Stroke = Color3.fromRGB(200, 220, 255),
    Divider = Color3.fromRGB(180, 200, 240),
    Text = Color3.fromRGB(20, 30, 60),
    TextDark = Color3.fromRGB(60, 80, 120),
    Accent = Color3.fromRGB(100, 150, 255),
    Accent2 = Color3.fromRGB(150, 200, 255),
    Good = Color3.fromRGB(100, 200, 100),
    Warn = Color3.fromRGB(255, 200, 100),
    Bad = Color3.fromRGB(255, 100, 100)
}

NexacLib.Themes.Glass = GlassTheme
NexacLib.SelectedTheme = "Glass"

-- Bubble GUI System
local BubbleGUI = {
    Visible = false,
    Bubbles = {},
    Connections = {},
    BlurEffect = nil,
    BackgroundOverlay = nil
}

-- Create background overlay with blur
local function createBackgroundOverlay()
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "BubbleOverlay"
    overlay.Parent = game:GetService("CoreGui")
    overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Background dimming
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.Position = UDim2.new(0, 0, 0, 0)
    background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    background.BackgroundTransparency = 1
    background.BorderSizePixel = 0
    background.Parent = overlay
    
    -- Blur effect
    local blur = Instance.new("BlurEffect")
    blur.Name = "BubbleBlur"
    blur.Size = 0
    blur.Enabled = false
    blur.Parent = Lighting
    
    BubbleGUI.BlurEffect = blur
    BubbleGUI.BackgroundOverlay = overlay
    BubbleGUI.BackgroundFrame = background
    
    return overlay
end

-- Create glass bubble effect
local function createGlassBubble(size, position, zIndex)
    local bubble = Instance.new("Frame")
    bubble.Name = "GlassBubble"
    bubble.Size = size
    bubble.Position = position
    bubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bubble.BackgroundTransparency = 0.85
    bubble.BorderSizePixel = 0
    bubble.ZIndex = zIndex
    
    -- Glass gradient effect
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 248, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 235, 255))
    }
    gradient.Rotation = 45
    gradient.Parent = bubble
    
    -- Glass border
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 220, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    stroke.Parent = bubble
    
    -- Corner rounding for bubble shape
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = bubble
    
    -- Inner glow effect
    local innerGlow = Instance.new("Frame")
    innerGlow.Name = "InnerGlow"
    innerGlow.Size = UDim2.new(0.9, 0, 0.9, 0)
    innerGlow.Position = UDim2.new(0.05, 0, 0.05, 0)
    innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    innerGlow.BackgroundTransparency = 0.9
    innerGlow.BorderSizePixel = 0
    innerGlow.ZIndex = bubble.ZIndex + 1
    innerGlow.Parent = bubble
    
    local innerCorner = Instance.new("UICorner")
    innerCorner.CornerRadius = UDim.new(0, 18)
    innerCorner.Parent = innerGlow
    
    local innerGradient = Instance.new("UIGradient")
    innerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 220, 255))
    }
    innerGradient.Rotation = -45
    innerGradient.Parent = innerGlow
    
    return bubble
end

-- Create individual bubble content
local function createBubbleContent(bubble, bubbleType, size)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(0.9, 0, 0.8, 0)
    content.Position = UDim2.new(0.05, 0, 0.1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Color3.fromRGB(200, 220, 255)
    content.ZIndex = bubble.ZIndex + 2
    content.Parent = bubble
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.Parent = content
    
    -- Bubble title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundTransparency = 1
    title.Text = bubbleType
    title.TextColor3 = Color3.fromRGB(20, 30, 60)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.ZIndex = bubble.ZIndex + 3
    title.Parent = content
    
    return content
end

-- Create all bubbles
local function createBubbles()
    local overlay = BubbleGUI.BackgroundOverlay
    
    -- Dashboard Bubble (Top Left - Largest)
    local dashboardBubble = createGlassBubble(
        UDim2.new(0, 280, 0, 350),
        UDim2.new(0, 30, 0, 30),
        10
    )
    dashboardBubble.Parent = overlay
    local dashboardContent = createBubbleContent(dashboardBubble, "🎯 Dashboard", UDim2.new(0, 280, 0, 350))
    
    -- Aimbot Bubble (Left Middle)
    local aimbotBubble = createGlassBubble(
        UDim2.new(0, 200, 0, 200),
        UDim2.new(0, 50, 0, 400),
        11
    )
    aimbotBubble.Parent = overlay
    local aimbotContent = createBubbleContent(aimbotBubble, "🎯 Aimbot", UDim2.new(0, 200, 0, 200))
    
    -- ESP Bubble (Left Middle-Bottom)
    local espBubble = createGlassBubble(
        UDim2.new(0, 200, 0, 200),
        UDim2.new(0, 50, 0, 620),
        12
    )
    espBubble.Parent = overlay
    local espContent = createBubbleContent(espBubble, "👁️ ESP", UDim2.new(0, 200, 0, 200))
    
    -- Movement Bubble (Left Bottom)
    local movementBubble = createGlassBubble(
        UDim2.new(0, 200, 0, 200),
        UDim2.new(0, 50, 0, 840),
        13
    )
    movementBubble.Parent = overlay
    local movementContent = createBubbleContent(movementBubble, "🚀 Movement", UDim2.new(0, 200, 0, 200))
    
    -- Settings Bubble (Left Bottom-Right)
    local settingsBubble = createGlassBubble(
        UDim2.new(0, 200, 0, 200),
        UDim2.new(0, 270, 0, 840),
        14
    )
    settingsBubble.Parent = overlay
    local settingsContent = createBubbleContent(settingsBubble, "⚙️ Settings", UDim2.new(0, 200, 0, 200))
    
    -- Store bubbles
    BubbleGUI.Bubbles = {
        Dashboard = {Frame = dashboardBubble, Content = dashboardContent},
        Aimbot = {Frame = aimbotBubble, Content = aimbotContent},
        ESP = {Frame = espBubble, Content = espContent},
        Movement = {Frame = movementBubble, Content = movementContent},
        Settings = {Frame = settingsBubble, Content = settingsContent}
    }
end

-- Add content to bubbles
local function populateBubbles()
    -- Dashboard content
    local dashboard = BubbleGUI.Bubbles.Dashboard.Content
    
    local userLabel = Instance.new("TextLabel")
    userLabel.Size = UDim2.new(1, 0, 0, 20)
    userLabel.BackgroundTransparency = 1
    userLabel.Text = "👤 User: " .. plr.DisplayName
    userLabel.TextColor3 = Color3.fromRGB(20, 30, 60)
    userLabel.TextScaled = true
    userLabel.Font = Enum.Font.Gotham
    userLabel.LayoutOrder = 1
    userLabel.Parent = dashboard
    
    local executorLabel = Instance.new("TextLabel")
    executorLabel.Size = UDim2.new(1, 0, 0, 20)
    executorLabel.BackgroundTransparency = 1
    executorLabel.Text = "⚡ Executor: " .. EXECUTOR_NAME
    executorLabel.TextColor3 = Color3.fromRGB(20, 30, 60)
    executorLabel.TextScaled = true
    executorLabel.Font = Enum.Font.Gotham
    executorLabel.LayoutOrder = 2
    executorLabel.Parent = dashboard
    
    local gameLabel = Instance.new("TextLabel")
    gameLabel.Size = UDim2.new(1, 0, 0, 20)
    gameLabel.BackgroundTransparency = 1
    gameLabel.Text = "🎮 Game: " .. game.PlaceId
    gameLabel.TextColor3 = Color3.fromRGB(20, 30, 60)
    gameLabel.TextScaled = true
    gameLabel.Font = Enum.Font.Gotham
    gameLabel.LayoutOrder = 3
    gameLabel.Parent = dashboard
    
    -- Aimbot content
    local aimbot = BubbleGUI.Bubbles.Aimbot.Content
    
    local aimbotToggle = Instance.new("TextButton")
    aimbotToggle.Size = UDim2.new(1, 0, 0, 30)
    aimbotToggle.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    aimbotToggle.BackgroundTransparency = 0.7
    aimbotToggle.BorderSizePixel = 0
    aimbotToggle.Text = "🎯 Aimbot: OFF"
    aimbotToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    aimbotToggle.TextScaled = true
    aimbotToggle.Font = Enum.Font.GothamBold
    aimbotToggle.LayoutOrder = 1
    aimbotToggle.Parent = aimbot
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = aimbotToggle
    
    aimbotToggle.MouseButton1Click:Connect(function()
        aimbotEnabled = not aimbotEnabled
        aimbotToggle.Text = "🎯 Aimbot: " .. (aimbotEnabled and "ON" or "OFF")
        aimbotToggle.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 150, 255)
    end)
    
    -- ESP content
    local esp = BubbleGUI.Bubbles.ESP.Content
    
    local espToggle = Instance.new("TextButton")
    espToggle.Size = UDim2.new(1, 0, 0, 30)
    espToggle.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    espToggle.BackgroundTransparency = 0.7
    espToggle.BorderSizePixel = 0
    espToggle.Text = "👁️ ESP: OFF"
    espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    espToggle.TextScaled = true
    espToggle.Font = Enum.Font.GothamBold
    espToggle.LayoutOrder = 1
    espToggle.Parent = esp
    
    local espCorner = Instance.new("UICorner")
    espCorner.CornerRadius = UDim.new(0, 10)
    espCorner.Parent = espToggle
    
    espToggle.MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        espToggle.Text = "👁️ ESP: " .. (espEnabled and "ON" or "OFF")
        espToggle.BackgroundColor3 = espEnabled and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 150, 255)
    end)
end

-- Animate bubbles appearing
local function animateBubblesIn()
    local blur = BubbleGUI.BlurEffect
    local background = BubbleGUI.BackgroundFrame
    
    -- Fade in background
    background:TweenPosition(UDim2.new(0, 0, 0, 0), "Out", "Quad", 0.3, true)
    background:TweenBackgroundTransparency(0.4, "Out", "Quad", 0.3, true)
    
    -- Fade in blur
    if blur then
        blur.Enabled = true
        local blurTween = TweenService:Create(blur, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 15})
        blurTween:Play()
    end
    
    -- Animate each bubble with staggered timing
    local bubbleOrder = {
        "Dashboard", "Aimbot", "ESP", "Movement", "Settings"
    }
    
    for i, bubbleName in ipairs(bubbleOrder) do
        local bubble = BubbleGUI.Bubbles[bubbleName].Frame
        local delay = (i - 1) * 0.1
        
        -- Start with bubbles scaled down and transparent
        bubble.Size = UDim2.new(0, 0, 0, 0)
        bubble.BackgroundTransparency = 1
        
        task.wait(delay)
        
        -- Scale and fade in
        local targetSize = bubbleName == "Dashboard" and UDim2.new(0, 280, 0, 350) or UDim2.new(0, 200, 0, 200)
        
        local scaleTween = TweenService:Create(bubble, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = targetSize,
            BackgroundTransparency = 0.85
        })
        scaleTween:Play()
        
        -- Add floating animation
        local floatTween = TweenService:Create(bubble, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Position = bubble.Position + UDim2.new(0, 0, 0, -5)
        })
        task.wait(0.4)
        floatTween:Play()
    end
end

-- Animate bubbles disappearing
local function animateBubblesOut()
    local blur = BubbleGUI.BlurEffect
    local background = BubbleGUI.BackgroundFrame
    
    -- Animate bubbles out in reverse order
    local bubbleOrder = {"Settings", "Movement", "ESP", "Aimbot", "Dashboard"}
    
    for i, bubbleName in ipairs(bubbleOrder) do
        local bubble = BubbleGUI.Bubbles[bubbleName].Frame
        local delay = (i - 1) * 0.05
        
        task.wait(delay)
        
        -- Scale down and fade out
        local scaleTween = TweenService:Create(bubble, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        })
        scaleTween:Play()
    end
    
    -- Fade out background and blur
    task.wait(0.5)
    background:TweenBackgroundTransparency(1, "Out", "Quad", 0.3, true)
    
    if blur then
        local blurTween = TweenService:Create(blur, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = 0})
        blurTween:Play()
        task.delay(0.31, function()
            blur.Enabled = false
        end)
    end
end

-- Toggle bubble GUI
local function toggleBubbleGUI()
    if not BubbleGUI.BackgroundOverlay then
        createBackgroundOverlay()
        createBubbles()
        populateBubbles()
    end
    
    BubbleGUI.Visible = not BubbleGUI.Visible
    
    if BubbleGUI.Visible then
        BubbleGUI.BackgroundOverlay.Enabled = true
        animateBubblesIn()
    else
        animateBubblesOut()
        task.delay(1, function()
            if BubbleGUI.BackgroundOverlay then
                BubbleGUI.BackgroundOverlay.Enabled = false
            end
        end)
    end
end

-- Right Control keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.RightControl then
        toggleBubbleGUI()
    end
end)

-- Notification
NexacLib:MakeNotification({
    Name = "Bubble GUI Ready",
    Content = "🫧 Press Right Control to toggle bubble interface",
    Time = 5,
    Image = ""
})

print("🫧 Phantom Suite Bubble GUI Loaded - Press Right Control to toggle")
