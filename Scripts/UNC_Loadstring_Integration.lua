--[[
    Silent UNC and Executor Detection Loadstrings
    Integrates both UNCTest and Validator scripts into silent loadstrings
    Returns executor info and UNC percentage for GUI display
]]

-- UNCTest Loadstring (Silent Version)
local UNCTest_Loadstring = [[
local passes, fails, undefined = 0, 0, 0
local running = 0
local testResults = {}

local function getGlobal(path)
    local value = getfenv(0)
    while value ~= nil and path ~= "" do
        local name, nextValue = string.match(path, "^([^.]+)%.?(.*)$")
        value = value[name]
        path = nextValue
    end
    return value
end

local function test(name, aliases, callback)
    running += 1
    task.spawn(function()
        if not callback then
            -- No test, just check existence
        elseif not getGlobal(name) then
            fails += 1
        else
            local success, message = pcall(callback)
            if success then
                passes += 1
            else
                fails += 1
            end
        end
        
        local undefinedAliases = {}
        for _, alias in ipairs(aliases) do
            if getGlobal(alias) == nil then
                table.insert(undefinedAliases, alias)
            end
        end
        
        if #undefinedAliases > 0 then
            undefined += 1
        end
        running -= 1
    end)
end

-- Run silent UNC tests
test("cache.invalidate", {})
test("cache.iscached", {})
test("cache.replace", {})
test("cloneref", {})
test("compareinstances", {})
test("checkcaller", {})
test("clonefunction", {})
test("getcallingscript", {})
test("getscriptclosure", {"getscriptfunction"})
test("hookfunction", {"replaceclosure"})
test("iscclosure", {})
test("islclosure", {})
test("isexecutorclosure", {"checkclosure", "isourclosure"})
test("loadstring", {})
test("newcclosure", {})
test("rconsoleclear", {"consoleclear"})
test("rconsolecreate", {"consolecreate"})
test("rconsoledestroy", {"consoledestroy"})
test("rconsoleinput", {"consoleinput"})
test("rconsoleprint", {"consoleprint"})
test("rconsolesettitle", {"rconsolename", "consolesettitle"})
test("crypt.base64encode", {"crypt.base64.encode", "crypt.base64_encode", "base64.encode", "base64_encode"})
test("crypt.base64decode", {"crypt.base64.decode", "crypt.base64_decode", "base64.decode", "base64_decode"})
test("crypt.encrypt", {})
test("crypt.decrypt", {})
test("crypt.generatebytes", {})
test("crypt.generatekey", {})
test("crypt.hash", {})
test("debug.getconstant", {})
test("debug.getconstants", {})
test("debug.getinfo", {})
test("debug.getproto", {})
test("debug.getprotos", {})
test("debug.getstack", {})
test("debug.getupvalue", {})
test("debug.getupvalues", {})
test("debug.setconstant", {})
test("debug.setstack", {})
test("debug.setupvalue", {})
test("readfile", {})
test("listfiles", {})
test("writefile", {})
test("makefolder", {})
test("appendfile", {})
test("isfile", {})
test("isfolder", {})
test("delfolder", {})
test("delfile", {})
test("loadfile", {})
test("dofile", {})
test("isrbxactive", {"isgameactive"})
test("mouse1click", {})
test("mouse1press", {})
test("mouse1release", {})
test("mouse2click", {})
test("mouse2press", {})
test("mouse2release", {})
test("mousemoveabs", {})
test("mousemoverel", {})
test("mousescroll", {})
test("fireclickdetector", {})
test("getcallbackvalue", {})
test("getconnections", {})
test("getcustomasset", {})
test("gethiddenproperty", {})
test("sethiddenproperty", {})
test("gethui", {})
test("getinstances", {})
test("getnilinstances", {})
test("isscriptable", {})
test("setscriptable", {})
test("setrbxclipboard", {})
test("getrawmetatable", {})
test("hookmetamethod", {})
test("getnamecallmethod", {})
test("isreadonly", {})
test("setrawmetatable", {})
test("setreadonly", {})
test("identifyexecutor", {"getexecutorname"})
test("lz4compress", {})
test("lz4decompress", {})
test("messagebox", {})
test("queue_on_teleport", {"queueonteleport"})
test("request", {"http.request", "http_request"})
test("setclipboard", {"toclipboard"})
test("setfpscap", {})
test("getgc", {})
test("getgenv", {})
test("getloadedmodules", {})
test("getrenv", {})
test("getrunningscripts", {})
test("getscriptbytecode", {"dumpstring"})
test("getscripthash", {})
test("getscripts", {})
test("getsenv", {})
test("getthreadidentity", {"getidentity", "getthreadcontext"})
test("setthreadidentity", {"setidentity", "setthreadcontext"})
test("Drawing", {})
test("Drawing.new", {})
test("Drawing.Fonts", {})
test("isrenderobj", {})
test("getrenderproperty", {})
test("setrenderproperty", {})
test("cleardrawcache", {})
test("WebSocket", {})
test("WebSocket.connect", {})

-- Wait for completion
repeat task.wait() until running == 0

-- Calculate UNC percentage
local totalTests = passes + fails
local uncPercentage = totalTests > 0 and math.round((passes / totalTests) * 100) or 0

return {
    UNC = uncPercentage,
    Passes = passes,
    Fails = fails,
    Undefined = undefined,
    Total = totalTests
}
]]

-- Validator Loadstring (Silent Version)
local Validator_Loadstring = [[
local ExecutorTest = {
    Results = { Pass = 0, Fail = 0, Unknown = 0, Details = {} },
    StartTime = tick()
}

local function recordResult(testName, status, details)
    ExecutorTest.Results.Details[testName] = {
        Status = status,
        Details = details or ""
    }
    
    if status == "Pass" then
        ExecutorTest.Results.Pass = ExecutorTest.Results.Pass + 1
    elseif status == "Fail" then
        ExecutorTest.Results.Fail = ExecutorTest.Results.Fail + 1
    else
        ExecutorTest.Results.Unknown = ExecutorTest.Results.Unknown + 1
    end
end

local function testServiceFunction(serviceName, functionName, expectedError)
    local testName = serviceName .. ":" .. functionName
    
    local success, result = pcall(function()
        return game:GetService(serviceName)[functionName]()
    end)
    
    if not success and result == expectedError then
        recordResult(testName, "Pass")
    elseif success then
        recordResult(testName, "Fail", "Unexpected success")
    else
        recordResult(testName, "Pass", "Function blocked")
    end
end

-- Run silent validator tests
task.spawn(function() testServiceFunction("HttpRbxApiService", "PostAsync", "Argument 1 missing or nil") end)
task.spawn(function() testServiceFunction("HttpRbxApiService", "GetAsync", "Argument 1 missing or nil") end)
task.spawn(function() testServiceFunction("ScriptContext", "AddCoreScriptLocal", "Argument 1 missing or nil") end)
task.spawn(function() testServiceFunction("BrowserService", "ExecuteJavaScript", "Argument 1 missing or nil") end)
task.spawn(function() testServiceFunction("MarketplaceService", "PerformPurchase", "Argument 1 missing or nil") end)
task.spawn(function() testServiceFunction("HttpService", "RequestInternal", "Argument 1 missing or nil") end)
task.spawn(function() testServiceFunction("GuiService", "OpenBrowserWindow", "Argument 1 missing or nil") end)
task.spawn(function() testServiceFunction("OpenCloudService", "HttpRequestAsync", "Argument 1 missing or nil") end)

-- Test HTTP functions
task.spawn(function()
    local success, result = pcall(function()
        return request({ Url = "https://httpbin.org/user-agent", Method = "GET" })
    end)
    if success and result.StatusCode == 200 then
        recordResult("CustomHTTP", "Pass", "HTTP requests work")
    else
        recordResult("CustomHTTP", "Fail", "HTTP requests blocked")
    end
end)

-- Wait for completion
task.wait(3)

-- Calculate security score
local total = ExecutorTest.Results.Pass + ExecutorTest.Results.Fail + ExecutorTest.Results.Unknown
local securityScore = total > 0 and math.round((ExecutorTest.Results.Pass / total) * 100) or 0

return {
    SecurityScore = securityScore,
    Pass = ExecutorTest.Results.Pass,
    Fail = ExecutorTest.Results.Fail,
    Unknown = ExecutorTest.Results.Unknown,
    Total = total,
    Executor = identifyexecutor and identifyexecutor() or "Unknown"
}
]]

-- Main integration function
local function runSilentChecks()
    local results = {
        Executor = "Unknown",
        UNC = 0,
        SecurityScore = 0,
        Status = "Running"
    }
    
    -- Get executor name first
    results.Executor = identifyexecutor and identifyexecutor() or "Unknown"
    
    -- Run UNCTest
    task.spawn(function()
        local success, uncResults = pcall(function()
            return loadstring(UNC_Test_Loadstring)()
        end)
        
        if success and uncResults then
            results.UNC = uncResults.UNC
            results.UNCDetails = uncResults
        else
            results.UNC = 0
        end
    end)
    
    -- Run Validator
    task.spawn(function()
        local success, validatorResults = pcall(function()
            return loadstring(Validator_Loadstring)()
        end)
        
        if success and validatorResults then
            results.SecurityScore = validatorResults.SecurityScore
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

-- Export the integration function
return {
    RunChecks = runSilentChecks,
    UNCTest_Loadstring = UNCTest_Loadstring,
    Validator_Loadstring = Validator_Loadstring
}
