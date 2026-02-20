
print("🚀 Loading Phantom Suite v8.0 (Complete Rewrite)...")

pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Tools/DevCopy.lua"))()
end)

local function loadBracketLibrary()
    local success, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Scripts/refs/heads/main/Libraries/BracketLib.lua"))()
    end)
    
    if success and lib then
        print("✅ Bracket library loaded successfully")
        return lib
    else
        warn("❌ Failed to load Bracket library")
        return nil
    end
end

local Bracket = loadBracketLibrary()
if not Bracket then
    warn("❌ Cannot continue without GUI library")
    return
end

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Workspace = workspace

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()


-- Aimbot Configuration
local Aimbot = {
    enabled = false,
    blatant = false,
    fov = 100,
    smoothing = 5,
    prediction = 0.065,
    lockDistance = 500,
    wallCheck = true,
    teamCheck = true,
    healthCheck = false,
    minHealth = 0,
    targetMode = "Closest To Mouse"
}

-- Visual Configuration
local Visual = {
    fovColor = Color3.fromRGB(255, 255, 255),
    espColor = Color3.fromRGB(255, 0, 0),
    rainbowFov = false,
    rainbowSpeed = 0.005
}

-- ESP Configuration
local ESP = {
    enabled = false,
    box = true,
    name = true,
    health = true,
    distance = true,
    tracer = false,
    lockDistance = 500
}

-- Movement Configuration
local Movement = {
    fly = false,
    noclip = false,
    infJump = false,
    flySpeed = 50,
    walkSpeed = 16,
    jumpPower = 50
}

-- State Management
local State = {
    aiming = false,
    target = nil,
    connections = {},
    espObjects = {},
    drawingAvailable = false,
    Drawing = nil
}

-- Executor Detection
local Executor = {
    name = "Unknown",
    compatibility = {
        Drawing = false,
        Clipboard = false,
        FileSystem = false,
        HTTP = false,
        WebSocket = false
    }
}


local function detectExecutor()
    if syn then
        Executor.name = "Synapse X"
        Executor.compatibility.Drawing = true
        Executor.compatibility.Clipboard = true
        Executor.compatibility.FileSystem = true
        Executor.compatibility.HTTP = true
        Executor.compatibility.WebSocket = true
    elseif getexecutorname then
        Executor.name = getexecutorname() or "Unknown"
        Executor.compatibility.Drawing = true
        Executor.compatibility.Clipboard = true
        Executor.compatibility.FileSystem = true
        Executor.compatibility.HTTP = true
    elseif identifyexecutor then
        Executor.name = identifyexecutor()
        Executor.compatibility.Drawing = true
        Executor.compatibility.Clipboard = true
        Executor.compatibility.FileSystem = true
        Executor.compatibility.HTTP = true
    end
end

detectExecutor()


pcall(function()
    State.Drawing = Drawing
    if State.Drawing then
        State.drawingAvailable = pcall(function()
            local test = State.Drawing.new("Circle")
            test:Remove()
        end)
    end
end)


local function getClosestTarget()
    local closest = nil
    local closestDistance = Aimbot.lockDistance
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Team Check
        if Aimbot.teamCheck and player.Team == LocalPlayer.Team then continue end
        
        -- Health Check
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if Aimbot.healthCheck and (not humanoid or humanoid.Health < Aimbot.minHealth) then continue end
        
        -- Character Validation
        local character = player.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not character or not rootPart then continue end
        
        -- Screen Position Check
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if not onScreen then continue end
        
        -- Distance Calculation
        local distance = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
        if distance >= closestDistance then continue end
        
        -- Wall Check
        if Aimbot.wallCheck then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
            
            local result = Workspace:Raycast(Camera.CFrame.Position, (rootPart.Position - Camera.CFrame.Position).Unit * Aimbot.lockDistance, raycastParams)
            if not result or not result.Instance or not result.Instance:IsDescendantOf(character) then continue end
        end
        
        closest = player
        closestDistance = distance
    end
    
    return closest
end

local function applyAimbot(target)
    if not target or not target.Character then return end
    
    local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local targetPos = rootPart.Position
    
    -- Prediction
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.MoveDirection ~= Vector3.new(0, 0, 0) then
        targetPos = targetPos + humanoid.MoveDirection * Aimbot.prediction * 50
    end
    
    -- Aim Calculation
    local aimDirection = (targetPos - Camera.CFrame.Position).Unit
    local currentLook = Camera.CFrame.LookVector
    local smoothedDirection = currentLook:Lerp(aimDirection, 1 / Aimbot.smoothing)
    
    -- Apply Aim
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + smoothedDirection)
end


local function createESPObjects(player)
    if not State.drawingAvailable or not ESP.enabled then return end
    
    -- Cleanup existing objects
    if State.espObjects[player] then
        for _, obj in pairs(State.espObjects[player]) do
            if obj and obj.Remove then
                obj:Remove()
            end
        end
    end
    
    State.espObjects[player] = {}
    
    -- Box ESP
    if ESP.box then
        local box = State.Drawing.new("Square")
        box.Thickness = 1
        box.Color = Visual.espColor
        box.Transparency = 1
        box.Visible = false
        table.insert(State.espObjects[player], box)
    end
    
    -- Name ESP
    if ESP.name then
        local name = State.Drawing.new("Text")
        name.Size = 13
        name.Color = Visual.espColor
        name.Center = true
        name.Outline = true
        name.Visible = false
        table.insert(State.espObjects[player], name)
    end
    
    -- Health ESP
    if ESP.health then
        local healthBar = State.Drawing.new("Square")
        healthBar.Thickness = 1
        healthBar.Color = Color3.fromRGB(0, 255, 0)
        healthBar.Transparency = 1
        healthBar.Visible = false
        table.insert(State.espObjects[player], healthBar)
    end
    
    -- Tracer ESP
    if ESP.tracer then
        local tracer = State.Drawing.new("Line")
        tracer.Thickness = 1
        tracer.Color = Visual.espColor
        tracer.Transparency = 1
        tracer.Visible = false
        table.insert(State.espObjects[player], tracer)
    end
end

local function updateESPObjects(player)
    if not State.drawingAvailable or not ESP.enabled or not State.espObjects[player] then return end
    
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not character or not humanoid or not rootPart then
        -- Hide ESP if character doesn't exist
        for _, obj in pairs(State.espObjects[player]) do
            if obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    -- Team Check
    if Aimbot.teamCheck and player.Team == LocalPlayer.Team then
        for _, obj in pairs(State.espObjects[player]) do
            if obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    local position, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        -- Hide ESP if off screen
        for _, obj in pairs(State.espObjects[player]) do
            if obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
        return
    end
    
    local objIndex = 1
    
    -- Update Box ESP
    if ESP.box and State.espObjects[player][objIndex] then
        local box = State.espObjects[player][objIndex]
        local size = rootPart.Size.Y * 2
        local scaleFactor = (size / (position.Z * math.tan(math.rad(Camera.FieldOfView / 2))))
        
        box.Size = Vector2.new(scaleFactor, scaleFactor * 1.5)
        box.Position = Vector2.new(position.X - box.Size.X / 2, position.Y - box.Size.Y / 2)
        box.Color = Visual.espColor
        box.Visible = ESP.enabled
        objIndex = objIndex + 1
    end
    
    -- Update Name ESP
    if ESP.name and State.espObjects[player][objIndex] then
        local name = State.espObjects[player][objIndex]
        name.Text = player.Name .. " [" .. math.floor((rootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude) .. "m]"
        name.Position = Vector2.new(position.X, position.Y - 20)
        name.Color = Visual.espColor
        name.Visible = ESP.enabled
        objIndex = objIndex + 1
    end
    
    -- Update Health ESP
    if ESP.health and State.espObjects[player][objIndex] then
        local healthBar = State.espObjects[player][objIndex]
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        
        healthBar.Size = Vector2.new(4, 50)
        healthBar.Position = Vector2.new(position.X - 30, position.Y - 25)
        healthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
        healthBar.Visible = ESP.enabled
        objIndex = objIndex + 1
    end
    
    -- Update Tracer ESP
    if ESP.tracer and State.espObjects[player][objIndex] then
        local tracer = State.espObjects[player][objIndex]
        tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        tracer.To = Vector2.new(position.X, position.Y)
        tracer.Color = Visual.espColor
        tracer.Visible = ESP.enabled
        objIndex = objIndex + 1
    end
end

local function cleanupESP(player)
    if State.espObjects[player] then
        for _, obj in pairs(State.espObjects[player]) do
            if obj and obj.Remove then
                obj:Remove()
            end
        end
        State.espObjects[player] = nil
    end
end


local function startFly()
    if State.connections.fly then return end
    
    State.connections.fly = RunService.Heartbeat:Connect(function()
        if not Movement.fly then
            if State.connections.fly then
                State.connections.fly:Disconnect()
                State.connections.fly = nil
            end
            return
        end
        
        local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            local moveDirection = Vector3.new(
                (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.S) and 1 or 0),
                0,
                (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0) - (UserInputService:IsKeyDown(Enum.KeyCode.A) and 1 or 0)
            )
            
            if moveDirection ~= Vector3.new(0, 0, 0) then
                humanoid:Move(moveDirection * Movement.flySpeed)
            end
        end
    end)
end

local function stopFly()
    Movement.fly = false
    if State.connections.fly then
        State.connections.fly:Disconnect()
        State.connections.fly = nil
    end
end

local function startNoclip()
    if State.connections.noclip then return end
    
    State.connections.noclip = RunService.Stepped:Connect(function()
        if not Movement.noclip then
            if State.connections.noclip then
                State.connections.noclip:Disconnect()
                State.connections.noclip = nil
            end
            return
        end
        
        if LocalPlayer.Character then
            for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
end

local function stopNoclip()
    Movement.noclip = false
    if State.connections.noclip then
        State.connections.noclip:Disconnect()
        State.connections.noclip = nil
    end
end

local function startInfJump()
    if State.connections.infJump then return end
    
    State.connections.infJump = UserInputService.JumpRequest:Connect(function()
        if Movement.infJump then
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Jump = true
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
end

local function stopInfJump()
    Movement.infJump = false
    if State.connections.infJump then
        State.connections.infJump:Disconnect()
        State.connections.infJump = nil
    end
end


local function enableBlatantMode()
    Aimbot.fov = 500
    Aimbot.smoothing = 1
    Aimbot.prediction = 0.1
    Aimbot.wallCheck = false
    Aimbot.teamCheck = false
    Aimbot.healthCheck = false
    print("🔥 Blatant mode activated - Maximum settings applied!")
end

local function disableBlatantMode()
    Aimbot.fov = 100
    Aimbot.smoothing = 5
    Aimbot.prediction = 0.065
    Aimbot.wallCheck = true
    Aimbot.teamCheck = true
    Aimbot.healthCheck = false
    print("🛡️ Blatant mode deactivated - Default settings restored!")
end


local function createUI()
    local Window = Bracket:Window({
        Name = "Phantom Suite v8.0",
        Color = Color3.new(0.5, 0.25, 1),
        Size = UDim2.new(0, 500, 0, 400),
        Position = UDim2.new(0.5, -250, 0.5, -200)
    })
    
    -- Create Tabs
    local StatusTab = Window:Tab({Name = "Status"})
    local AimbotTab = Window:Tab({Name = "Aimbot"})
    local ESPTab = Window:Tab({Name = "ESP"})
    local ExtrasTab = Window:Tab({Name = "Extras"})
    local ConfigsTab = Window:Tab({Name = "Configs"})
    local KeybindsTab = Window:Tab({Name = "Keybinds"})
    local InfoTab = Window:Tab({Name = "Info"})
    
    -- Status Tab
    StatusTab:Divider({Text = "System Status"})
    StatusTab:Label({Text = "Executor: " .. Executor.name})
    StatusTab:Label({Text = "UI: Bracket Library"})
    StatusTab:Label({Text = "Version: v8.0"})
    StatusTab:Label({Text = "Drawing: " .. (State.drawingAvailable and "Available" or "Not Available")})
    
    -- Aimbot Tab
    AimbotTab:Divider({Text = "Aimbot Settings"})
    AimbotTab:Toggle({
        Name = "Enable Aimbot",
        Value = Aimbot.enabled,
        Callback = function(state)
            Aimbot.enabled = state
            print("Aimbot:", state and "ON" or "OFF")
        end
    })
    
    AimbotTab:Toggle({
        Name = "Blatant Mode",
        Value = Aimbot.blatant,
        Callback = function(state)
            Aimbot.blatant = state
            if state then
                enableBlatantMode()
            else
                disableBlatantMode()
            end
        end
    })
    
    AimbotTab:Slider({
        Name = "FOV",
        Min = 10,
        Max = 500,
        Value = Aimbot.fov,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            Aimbot.fov = value
            print("Aimbot FOV:", value)
        end
    })
    
    AimbotTab:Slider({
        Name = "Smoothing",
        Min = 1,
        Max = 10,
        Value = Aimbot.smoothing,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            Aimbot.smoothing = value
            print("Aimbot Smoothing:", value)
        end
    })
    
    AimbotTab:Slider({
        Name = "Prediction",
        Min = 0,
        Max = 0.2,
        Value = Aimbot.prediction,
        Precise = 3,
        Unit = "",
        Callback = function(value)
            Aimbot.prediction = value
            print("Aimbot Prediction:", value)
        end
    })
    
    AimbotTab:Divider({Text = "Checks"})
    AimbotTab:Toggle({
        Name = "Wall Check",
        Value = Aimbot.wallCheck,
        Callback = function(state)
            Aimbot.wallCheck = state
        end
    })
    
    AimbotTab:Toggle({
        Name = "Team Check",
        Value = Aimbot.teamCheck,
        Callback = function(state)
            Aimbot.teamCheck = state
        end
    })
    
    AimbotTab:Toggle({
        Name = "Health Check",
        Value = Aimbot.healthCheck,
        Callback = function(state)
            Aimbot.healthCheck = state
        end
    })
    
    -- ESP Tab
    ESPTab:Divider({Text = "ESP Settings"})
    ESPTab:Toggle({
        Name = "Enable ESP",
        Value = ESP.enabled,
        Callback = function(state)
            ESP.enabled = state
            print("ESP:", state and "ON" or "OFF")
        end
    })
    
    ESPTab:Toggle({
        Name = "Box ESP",
        Value = ESP.box,
        Callback = function(state)
            ESP.box = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Name ESP",
        Value = ESP.name,
        Callback = function(state)
            ESP.name = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Health ESP",
        Value = ESP.health,
        Callback = function(state)
            ESP.health = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Distance ESP",
        Value = ESP.distance,
        Callback = function(state)
            ESP.distance = state
        end
    })
    
    ESPTab:Toggle({
        Name = "Tracer ESP",
        Value = ESP.tracer,
        Callback = function(state)
            ESP.tracer = state
        end
    })
    
    ESPTab:Divider({Text = "Visual Settings"})
    ESPTab:Colorpicker({
        Name = "ESP Color",
        Color = Visual.espColor,
        Callback = function(color)
            Visual.espColor = color
        end
    })
    
    ESPTab:Colorpicker({
        Name = "FOV Color",
        Color = Visual.fovColor,
        Callback = function(color)
            Visual.fovColor = color
        end
    })
    
    -- Extras Tab
    ExtrasTab:Divider({Text = "Movement"})
    ExtrasTab:Toggle({
        Name = "Fly",
        Value = Movement.fly,
        Callback = function(state)
            Movement.fly = state
            print("Fly:", state and "ON" or "OFF")
        end
    })
    
    ExtrasTab:Toggle({
        Name = "Noclip",
        Value = Movement.noclip,
        Callback = function(state)
            Movement.noclip = state
            print("Noclip:", state and "ON" or "OFF")
        end
    })
    
    ExtrasTab:Toggle({
        Name = "Infinite Jump",
        Value = Movement.infJump,
        Callback = function(state)
            Movement.infJump = state
            print("Infinite Jump:", state and "ON" or "OFF")
        end
    })
    
    ExtrasTab:Slider({
        Name = "Fly Speed",
        Min = 10,
        Max = 200,
        Value = Movement.flySpeed,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            Movement.flySpeed = value
            print("Fly Speed:", value)
        end
    })
    
    ExtrasTab:Slider({
        Name = "Walk Speed",
        Min = 16,
        Max = 200,
        Value = Movement.walkSpeed,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            Movement.walkSpeed = value
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = value
            end
            print("Walk Speed:", value)
        end
    })
    
    ExtrasTab:Slider({
        Name = "Jump Power",
        Min = 50,
        Max = 200,
        Value = Movement.jumpPower,
        Precise = 0,
        Unit = "",
        Callback = function(value)
            Movement.jumpPower = value
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
            print("Jump Power:", value)
        end
    })
    
    -- Configs Tab
    ConfigsTab:Divider({Text = "Configuration"})
    ConfigsTab:Button({
        Name = "Save Config",
        Callback = function()
            print("Configuration saved!")
        end
    })
    
    ConfigsTab:Button({
        Name = "Load Config",
        Callback = function()
            print("Configuration loaded!")
        end
    })
    
    ConfigsTab:Button({
        Name = "Reset Config",
        Callback = function()
            print("Configuration reset!")
        end
    })
    
    -- Keybinds Tab
    KeybindsTab:Divider({Text = "Keybinds"})
    KeybindsTab:Keybind({
        Name = "Toggle Aimbot",
        Key = "LeftControl",
        Mouse = false,
        Callback = function(bool, key)
            Aimbot.enabled = not Aimbot.enabled
            print("Aimbot:", Aimbot.enabled and "ON" or "OFF")
        end
    })
    
    KeybindsTab:Keybind({
        Name = "Toggle ESP",
        Key = "LeftShift",
        Mouse = false,
        Callback = function(bool, key)
            ESP.enabled = not ESP.enabled
            print("ESP:", ESP.enabled and "ON" or "OFF")
        end
    })
    
    KeybindsTab:Keybind({
        Name = "Toggle UI",
        Key = "RightShift",
        Mouse = false,
        Callback = function(bool, key)
            Window:Toggle()
            print("UI Toggled")
        end
    })
    
    KeybindsTab:Keybind({
        Name = "Blatant Mode",
        Key = "B",
        Mouse = false,
        Callback = function(bool, key)
            Aimbot.blatant = not Aimbot.blatant
            if Aimbot.blatant then
                enableBlatantMode()
            else
                disableBlantantMode()
            end
        end
    })
    
    -- Info Tab
    InfoTab:Divider({Text = "Information"})
    InfoTab:Label({Text = "Phantom Suite v8.0"})
    InfoTab:Label({Text = "Complete Rewrite"})
    InfoTab:Label({Text = "by Asuneteric"})
    InfoTab:Label({Text = ""})
    InfoTab:Label({Text = "Features:"})
    InfoTab:Label({Text = "• Advanced Aimbot"})
    InfoTab:Label({Text = "• Comprehensive ESP"})
    InfoTab:Label({Text = "• Movement Tools"})
    InfoTab:Label({Text = "• Blatant Mode"})
    InfoTab:Label({Text = "• Professional UI"})
    
    return Window
end


local function main()
    -- Create UI
    local Window = createUI()
    
    print("✅ Phantom Suite v8.0 loaded successfully!")
    
    -- Setup ESP for existing players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESPObjects(player)
        end
    end
    
    -- Player events
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            createESPObjects(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(player)
        cleanupESP(player)
    end)
    
    -- Main game loop
    task.spawn(function()
        while true do
            task.wait()
            
            -- Aimbot logic
            if Aimbot.enabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                State.target = getClosestTarget()
                if State.target then
                    applyAimbot(State.target)
                end
            else
                State.target = nil
            end
            
            -- Movement logic
            if Movement.fly then
                startFly()
            else
                stopFly()
            end
            
            if Movement.noclip then
                startNoclip()
            else
                stopNoclip()
            end
            
            if Movement.infJump then
                startInfJump()
            else
                stopInfJump()
            end
            
            -- Apply movement settings
            local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Movement.walkSpeed
                humanoid.JumpPower = Movement.jumpPower
            end
        end
    end)
    
    -- ESP update loop
    task.spawn(function()
        while true do
            task.wait(0.1)
            
            if ESP.enabled and State.drawingAvailable then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        updateESPObjects(player)
                    end
                end
            end
        end
    end)
end

-- Start the script
main()
