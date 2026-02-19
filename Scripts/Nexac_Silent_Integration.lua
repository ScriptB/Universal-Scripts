--[[
    Silent UNC and Executor Detection Integration for Nexac
    Uses GitHub raw URLs for loadstrings
    Replaces the prior custom UNC and Executor check
]]

-- Silent UNC and Executor Detection Loadstrings
local function runSilentChecks()
    local results = {
        Executor = "Unknown",
        UNC = 0,
        SecurityScore = 0,
        Status = "Running"
    }
    
    -- Get executor name first
    results.Executor = identifyexecutor and identifyexecutor() or "Unknown"
    
    -- Run UNCTest silently via GitHub raw URL
    task.spawn(function()
        local success, uncResults = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Scripts/UNCTest"))()
        end)
        
        if success and uncResults then
            results.UNC = uncResults.UNC or 0
            results.UNCDetails = uncResults
        else
            results.UNC = 0
        end
    end)
    
    -- Run Validator silently via GitHub raw URL  
    task.spawn(function()
        local success, validatorResults = pcall(function()
            return loadstring(game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Scripts/Validator%20and%20Executor%20Check"))()
        end)
        
        if success and validatorResults then
            -- Extract security score from validator results
            local total = validatorResults.Results and (validatorResults.Results.Pass + validatorResults.Results.Fail + validatorResults.Results.Unknown) or 0
            results.SecurityScore = total > 0 and math.round((validatorResults.Results.Pass / total) * 100) or 0
            results.ValidatorDetails = validatorResults
        else
            results.SecurityScore = 0
        end
    end)
    
    -- Wait for both to complete
    task.wait(5)
    results.Status = "Complete"
    
    return results
end

-- GUI Update Function
local function updateGUIWithResults(window, results)
    -- Update executor name label
    if window.ExecutorLabel then
        window.ExecutorLabel.Text = "Executor: " .. results.Executor
    end
    
    -- Update UNC percentage label
    if window.UNCLabel then
        window.UNCLabel.Text = "UNC: " .. results.UNC .. "%"
    end
    
    -- Update security score label
    if window.SecurityLabel then
        window.SecurityLabel.Text = "Security: " .. results.SecurityScore .. "%"
    end
    
    -- Update status label
    if window.StatusLabel then
        if results.Status == "Complete" then
            window.StatusLabel.Text = "✅ Detection Complete"
            window.StatusLabel.Color = Color3.new(0, 1, 0)
        else
            window.StatusLabel.Text = "🔄 Running Detection..."
            window.StatusLabel.Color = Color3.new(1, 1, 0)
        end
    end
end

-- Integration function to call from main Nexac script
return {
    RunChecks = runSilentChecks,
    UpdateGUI = updateGUIWithResults
}
