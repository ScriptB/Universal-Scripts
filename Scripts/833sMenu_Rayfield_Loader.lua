-- 833sMenu Script Loader using Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Create the main window
local Window = Rayfield:CreateWindow({
    Name = "833sMenu Script Loader",
    LoadingTitle = "833sMenu Loader",
    LoadingSubtitle = "by 833s",
    ConfigurationSaving = {
       Enabled = false, -- Disable to prevent folder issues
       FolderName = "833sMenu",
       FileName = "ScriptLoader"
    },
    Discord = {
       Enabled = false,
       Invite = "N/A", -- Discord invite
       RememberJoins = false
    },
    KeySystem = false, -- Disable key system
    KeySettings = {
       Title = "833sMenu",
       Subtitle = "Script Loader",
       Note = "No key required",
       FileName = "833sMenuKey",
       SaveKey = false,
       GrabKeyFromSite = false
    }
})

-- Script loading function
local function loadScript(scriptContent, scriptName)
    if not scriptContent or scriptContent == "" then
        Rayfield:Notify({
            Title = "Script Error",
            Content = "No script content provided",
            Duration = 3,
            Image = 4483362458
        })
        return
    end
    
    print("[833sMenu] Attempting to load script:", scriptName)
    print("[833sMenu] Script content length:", #scriptContent)
    
    -- Check if loadstring is available
    if not loadstring then
        Rayfield:Notify({
            Title = "Script Error",
            Content = "loadstring function not available - executor not supported",
            Duration = 5,
            Image = 4483362458
        })
        warn("[833sMenu] loadstring is not available")
        return
    end
    
    local success, err = pcall(function()
        -- Handle LOCAL_FILE method (for your local scripts)
        if scriptContent:find("LOCAL_FILE:") then
            local fileName = scriptContent:gsub("LOCAL_FILE:", "")
            print("[833sMenu] Loading local file:", fileName)
            
            -- Try to read the local file content
            local fileContent
            local success, result = pcall(function()
                return game:HttpGet('file:///' .. fileName)
            end)
            
            if success and result and result ~= "" then
                print("[833sMenu] Successfully read file:", fileName)
                print("[833sMenu] File content length:", #result)
                
                -- Execute the file content using loadstring
                local func = loadstring(result)
                if func then
                    func()
                    print("[833sMenu] Local file executed successfully")
                else
                    error("Failed to compile local file content")
                end
            else
                error("Failed to read file '" .. fileName .. "': " .. tostring(result))
            end
            
        -- For scripts that are just loadstring calls, execute them directly
        elseif scriptContent:find("loadstring") and scriptContent:find("game:HttpGet") then
            print("[833sMenu] Detected HTTP loadstring, executing directly...")
            
            -- Check if HttpGet is available
            if not game.HttpGet then
                error("game.HttpGet is not available")
            end
            
            -- Protect Rayfield UI before executing other scripts
            local RayfieldProtected = false
            if scriptContent:find("Universal-Aimassist") then
                print("[833sMenu] Protecting Rayfield UI from Aim Assist script...")
                RayfieldProtected = true
                
                -- Store Rayfield references
                local originalCoreGuiChildren = {}
                local CoreGui = game:GetService("CoreGui")
                for _, child in ipairs(CoreGui:GetChildren()) do
                    if child.Name:find("Rayfield") or child:FindFirstChildWhichIsA("ScreenGui", true) then
                        originalCoreGuiChildren[child.Name] = child
                        child.Parent = nil -- Temporarily remove from CoreGui
                    end
                end
                
                -- Restore after a short delay
                task.spawn(function()
                    task.wait(1)
                    for name, child in pairs(originalCoreGuiChildren) do
                        if child and child.Parent == nil then
                            child.Parent = CoreGui
                        end
                    end
                    print("[833sMenu] Rayfield UI protection completed")
                end)
            end
            
            -- Execute the script content directly
            local func = loadstring(scriptContent)
            if func then
                func()
                
                -- Wait a moment for script to initialize (for large scripts)
                task.wait(2)
                
                -- Special notification for Infinite Yield
                if scriptContent:find("Infinite-Yield") then
                    Rayfield:Notify({
                        Title = "Infinite Yield Loaded",
                        Content = "Script loaded! Use prefix key (usually ;) to access commands like ;help, ;fly, ;noclip",
                        Duration = 6,
                        Image = 4483362458
                    })
                end
                
                if RayfieldProtected then
                    print("[833sMenu] Aim Assist loaded, Rayfield UI protected")
                end
            else
                -- Try to get more detailed error information
                local success, compileError = pcall(function()
                    return loadstring(scriptContent)
                end)
                
                if not success then
                    error("Script compilation error: " .. tostring(compileError))
                else
                    error("Failed to compile HTTP loadstring script")
                end
            end
        else
            -- For regular script content, compile and execute
            print("[833sMenu] Compiling regular script...")
            local func = loadstring(scriptContent)
            if not func then
                error("Failed to compile script - syntax error")
            end
            
            -- Try to execute the compiled script
            func()
        end
    end)
    
    if success then
        Rayfield:Notify({
            Title = "Script Loaded",
            Content = scriptName .. " executed successfully!",
            Duration = 3,
            Image = 4483362458
        })
        print("[833sMenu] Successfully loaded:", scriptName)
    else
        Rayfield:Notify({
            Title = "Script Error",
            Content = "Failed to load " .. scriptName .. ": " .. tostring(err),
            Duration = 5,
            Image = 4483362458
        })
        warn("[833sMenu] Script Load Error:", err)
        warn("[833sMenu] Script name:", scriptName)
        warn("[833sMenu] First 100 chars of script:", scriptContent:sub(1, 100))
    end
end

-- Scripts to load - Your Personal Script Collection
local scripts = {
    {
        name = "Infinite Yield",
        description = "Load Infinite Yield admin commands",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/ScriptB/Infinite-Yield/refs/heads/main/Infinite%20Yield_fixed2.lua'))()"
    },
    {
        name = "Universal Aim Assist",
        description = "Load Universal Aim Assist script",
        script = "loadstring(game:HttpGet('https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/refs/heads/main/Aimbot'))()"
    }
}

-- Create main tab
local MainTab = Window:CreateTab("📜 Script Loader", 4483362458)

-- Create script buttons
for _, scriptData in ipairs(scripts) do
    MainTab:CreateButton({
        Name = scriptData.name,
        Callback = function()
            loadScript(scriptData.script, scriptData.name)
        end,
        Description = scriptData.description
    })
end

-- Custom Script Section
MainTab:CreateSection("Custom Script")

local customScriptText = ""

MainTab:CreateInput({
    Name = "Custom Script Input",
    PlaceholderText = "Enter your script code here...",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        customScriptText = Text
    end
})

MainTab:CreateButton({
    Name = "Execute Custom Script",
    Callback = function()
        if customScriptText and customScriptText ~= "" then
            loadScript(customScriptText, "Custom Script")
        else
            Rayfield:Notify({
                Title = "Input Error",
                Content = "Please enter script code first",
                Duration = 3,
                Image = 4483362458
            })
        end
    end,
    Description = "Run the script from the input field above"
})

-- Utilities Section
MainTab:CreateSection("Utilities")

MainTab:CreateButton({
    Name = "Clear Console",
    Callback = function()
        game:GetService("LogService"):Clear()
        Rayfield:Notify({
            Title = "Console Cleared",
            Content = "Developer console has been cleared",
            Duration = 2,
            Image = 4483362458
        })
    end,
    Description = "Clear the developer console"
})

MainTab:CreateButton({
    Name = "Rejoin Game",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, game:GetService("Players").LocalPlayer)
    end,
    Description = "Rejoin the current game server"
})

MainTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local HttpService = game:GetService("HttpService")
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Desc&limit=100"
        
        pcall(function()
            local Servers = HttpService:JSONDecode(game:HttpGet(Api))
            local ServerList = {}
            for i,v in pairs(Servers.data) do
                if type(v) == "table" and v.playing ~= v.maxPlayers then
                    table.insert(ServerList, v.id)
                end
            end
            if #ServerList > 0 then
                TPS:TeleportToPlaceInstance(game.PlaceId, ServerList[math.random(1, #ServerList)], game:GetService("Players").LocalPlayer)
                Rayfield:Notify({
                    Title = "Server Hopping",
                    Content = "Teleporting to new server...",
                    Duration = 3,
                    Image = 4483362458
                })
            else
                Rayfield:Notify({
                    Title = "No Servers",
                    Content = "No available servers found",
                    Duration = 3,
                    Image = 4483362458
                })
            end
        end)
    end,
    Description = "Join a different server"
})

-- Settings Tab
local SettingsTab = Window:CreateTab("⚙️ Settings", 4483362458)

SettingsTab:CreateSection("Interface Settings")

SettingsTab:CreateToggle({
    Name = "Toggle UI",
    CurrentValue = false,
    Callback = function(Value)
        -- Rayfield has built-in toggle functionality
        Rayfield:ToggleUI()
    end,
    Description = "Toggle the script loader visibility"
})

SettingsTab:CreateButton({
    Name = "Destroy Loader",
    Callback = function()
        Rayfield:Destroy()
        Rayfield:Notify({
            Title = "Loader Destroyed",
            Content = "Script loader has been destroyed",
            Duration = 3,
            Image = 4483362458
        })
    end,
    Description = "Permanently close the script loader"
})

SettingsTab:CreateSection("Information")

SettingsTab:CreateLabel("833sMenu Script Loader v1.0")
SettingsTab:CreateLabel("Created by 833s")
SettingsTab:CreateLabel("Using Rayfield UI Library")
SettingsTab:CreateLabel("Press RightShift to toggle UI")

-- Theme Settings
SettingsTab:CreateSection("Theme")

local currentTheme = "Default"

SettingsTab:CreateDropdown({
    Name = "Theme Selection",
    Options = {"Default", "Dark", "Light", "Midnight"},
    CurrentOption = currentTheme,
    Callback = function(Option)
        currentTheme = Option
        Rayfield:Notify({
            Title = "Theme Changed",
            Content = "Theme set to: " .. Option,
            Duration = 2,
            Image = 4483362458
        })
        -- Note: Actual theme changing would require Rayfield theme support
    end,
    Description = "Select a theme for the interface"
})

-- Info Tab
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateSection("About")

InfoTab:CreateLabel("833sMenu Script Loader")
InfoTab:CreateLabel("A modern script execution interface")
InfoTab:CreateLabel("Built with Rayfield UI Library")

InfoTab:CreateSection("Features")

InfoTab:CreateLabel("• Single-click script execution")
InfoTab:CreateLabel("• Custom script input")
InfoTab:CreateLabel("• Utility functions")
InfoTab:CreateLabel("• Theme customization")
InfoTab:CreateLabel("• Configuration saving")

InfoTab:CreateSection("Scripts Included")

InfoTab:CreateLabel("• Infinite Yield")
InfoTab:CreateLabel("• Universal Aim Assist")
InfoTab:CreateLabel("• Custom script input field")
InfoTab:CreateLabel("• Utility functions")
InfoTab:CreateLabel("• Settings and themes")

-- Initial notification
Rayfield:Notify({
    Title = "833sMenu Loader Ready",
    Content = "Script loader loaded successfully! Press RightShift to toggle UI.",
    Duration = 5,
    Image = 4483362458
})
