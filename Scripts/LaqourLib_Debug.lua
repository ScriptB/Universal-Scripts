-- LaqourLib Debug Script
-- Test if LaqourLib can load and identify the exact issue

print("🔍 Starting LaqourLib Debug Test...")

-- Test 1: Basic HTTP Request
print("📡 Test 1: Testing HTTP Request...")
local httpSuccess, httpResult = pcall(function()
    return game:HttpGet("https://raw.githubusercontent.com/ScriptB/Universal-Aimassist/main/Libraries/LaqourLib_BracketRebranded.lua")
end)

if httpSuccess then
    print("✅ HTTP Request successful")
    print("📄 Response length:", #httpResult)
    print("📝 First 100 chars:", httpResult:sub(1, 100))
else
    print("❌ HTTP Request failed:", tostring(httpResult))
    return
end

-- Test 2: Loadstring Execution
print("\n🔧 Test 2: Testing Loadstring...")
local loadSuccess, loadResult = pcall(function()
    return loadstring(httpResult)
end)

if loadSuccess then
    print("✅ Loadstring successful")
    print("📝 Function type:", type(loadResult))
else
    print("❌ Loadstring failed:", tostring(loadResult))
    return
end

-- Test 3: Function Execution
print("\n🚀 Test 3: Testing Function Execution...")
local execSuccess, execResult = pcall(function()
    return loadResult()
end)

if execSuccess then
    print("✅ Function execution successful")
    print("📦 Result type:", type(execResult))
    
    if type(execResult) == "table" then
        print("📋 Table keys:")
        for key, value in pairs(execResult) do
            print("  -", key, ":", type(value))
        end
        
        -- Test 4: GUI Creation
        print("\n🎨 Test 4: Testing GUI Creation...")
        if execResult.CreateWindow then
            print("✅ CreateWindow function exists")
            
            local guiSuccess, guiResult = pcall(function()
                return execResult:CreateWindow({
                    WindowName = "Test Window",
                    Size = UDim2.new(0, 400, 0, 300)
                }, game:GetService("CoreGui"))
            end)
            
            if guiSuccess then
                print("✅ GUI Creation successful")
                print("🖼️ GUI type:", type(guiResult))
                
                -- Clean up
                if guiResult and guiResult.Destroy then
                    guiResult:Destroy()
                end
            else
                print("❌ GUI Creation failed:", tostring(guiResult))
            end
        else
            print("❌ CreateWindow function missing")
        end
    else
        print("❌ Function did not return a table")
    end
else
    print("❌ Function execution failed:", tostring(execResult))
    print("🔍 This is likely the main issue!")
end

print("\n🏁 Debug Test Complete")
