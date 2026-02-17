--[Obfuscated by Hercules v1.6.2 | hercules-obfuscator.xyz/discord | hercules-obfuscator.xyz/source]
do  
    local D,T,P,X,S,E,R,Pa,GM,SM,RG,RS,RE,CG,Sel,C,G=  
        debug,type,pcall,xpcall,tostring,error,rawget,pairs,  
        getmetatable,setmetatable,rawget,rawset,rawequal,collectgarbage,select,coroutine,_G  
  
    local function dbgOK()  
        if T(D)~="table" then return false end  
        for _,k in Pa{"getinfo","getlocal","getupvalue","traceback","sethook","setupvalue","getregistry"} do  
            if T(D[k])~="function" then return false end  
        end  
        return true  
    end  
    if not dbgOK() then E("Tamper Detected! Reason: Debug library incomplete") return end  
  
    local function isNative(f)  
        local i=D.getinfo(f)  
        return i and i.what=="C"  
    end  
  
    local function checkNativeFuncs()  
        local natives={  
            P,X,assert,E,print,RG,RS,RE,tonumber,S,T,  
            Sel,next,ipairs,Pa,CG,GM,SM,  
            load,loadstring,loadfile,dofile,collectgarbage,  
            D.getinfo,D.getlocal,D.getupvalue,D.sethook,D.setupvalue,D.traceback,  
            C.create,C.resume,C.yield,C.status,  
            math.abs,math.acos,math.asin,math.atan,math.ceil,math.cos,math.deg,math.exp,  
            math.floor,math.fmod,math.huge,math.log,math.max,math.min,math.modf,math.pi,  
            math.rad,math.random,math.sin,math.sqrt,math.tan,  
            os.clock,os.date,os.difftime,os.execute,os.exit,os.getenv,os.remove,  
            os.rename,os.setlocale,os.time,os.tmpname,  
            string.byte,string.char,string.dump,string.find,string.format,string.gmatch,  
            string.gsub,string.len,string.lower,string.match,string.rep,string.reverse,  
            string.sub,string.upper,  
            table.insert,table.maxn,table.remove,table.sort  
        }  
        local mts={string,table,math,os,G,package}  
        for _,t in Pa(mts) do  
            local mt=GM(t)  
            if mt then  
                for _,m in Pa{"__index","__newindex","__call","__metatable"} do  
                    local mf=mt[m]  
                    if mf and T(mf)=="function" and not isNative(mf) then  
                        return false,"Metamethod tampered: "..m  
                    end  
                end  
            end  
        end  
        for _,fn in Pa(natives) do  
            if T(fn)=="function" and not isNative(fn) then  
                return false,"Native function replaced or wrapped"  
            end  
        end  
        return true  
    end  
  
    local function isMinified(f)  
        local i=D.getinfo(f,"Sl")  
        return i and i.linedefined==i.lastlinedefined  
    end  
  
    local function scanUp(f)  
        local i=1  
        while true do  
            local n,v=D.getupvalue(f,i)  
            if not n then break end  
            if T(v)=="function" and not isMinified(v) then return false,"Suspicious upvalue: "..n end  
            i=i+1  
        end  
        return true  
    end  
  
    local function scanLocals(l)  
        local i=1  
        while true do  
            local n,v=D.getlocal(l,i)  
            if not n then break end  
            if T(v)=="function" and not isMinified(v) then return false,"Suspicious local: "..n end  
            i=i+1  
        end  
        return true  
    end  
  
    local function checkGlobals()  
        local essentials={"pcall","xpcall","type","tostring","string","table","debug","coroutine","math","os","package"}  
        for _,k in Pa(essentials) do  
            if T(G[k])~=T(_G[k]) then return false,"Global modified: "..k end  
        end  
        if package and package.loaded and T(package.loaded.debug)~="table" then  
            return false,"Package.debug modified"  
        end  
        return true  
    end  
  
    local function run()  
        local ok,r=checkNativeFuncs()  
        if not ok then return false,r end  
        ok,r=checkGlobals()  
        if not ok then return false,r end  
        for l=2,4 do  
            local i=D.getinfo(l,"f")  
            if i and i.func then  
                ok,r=scanUp(i.func)  
                if not ok then return false,r.." @lvl "..l end  
            end  
            ok,r=scanLocals(l)  
            if not ok then return false,r.." @lvl "..l end  
        end  
        return true  
    end  
  
    local ok,r=run()  
    if not ok then  
        E("Tamper Detected! Reason: "..S(r))  
        while true do E("Tamper Detected! Reason: "..S(r)) end  
    end  
end

local chars = {[128]="\\128",[142]="\\142",[150]="\\150",[151]="\\151",[32]=" ",[40]="(",[41]=")",[46]=".",[47]="/",[175]="\\175",[54]="6",[182]="\\182",[58]=":",[65]="A",[66]="B",[67]="C",[68]="D",[69]="E",[70]="F",[71]="G",[73]="I",[74]="J",[75]="K",[77]="M",[78]="N",[79]="O",[80]="P",[81]="Q",[82]="R",[83]="S",[84]="T",[86]="V",[87]="W",[88]="X",[89]="Y",[90]="Z",[97]="a",[98]="b",[226]="\\226",[100]="d",[101]="e",[102]="f",[103]="g",[104]="h",[105]="i",[106]="j",[107]="k",[108]="l",[109]="m",[110]="n",[111]="o",[112]="p",[240]="\\240",[114]="r",[115]="s",[116]="t",[117]="u",[118]="v",[119]="w",[120]="x",[121]="y",[122]="z",[55]="7",[113]="q",[99]="c",[159]="\\159"}
local function bKkoReptifk(UDRMtiiBXpr)
    return (UDRMtiiBXpr >= 48 and UDRMtiiBXpr <= 57) or (UDRMtiiBXpr >= 65 and UDRMtiiBXpr <= 90) or (UDRMtiiBXpr >= 97 and UDRMtiiBXpr <= 122)
end
	
local function tlmjUJPdvq(wsWLjYZADemA, AokFRBVWRDAZ)
    local GVMoyAVMb = {}
    for i = 1, #wsWLjYZADemA do
        local UDRMtiiBXpr = wsWLjYZADemA:byte(i)
        if bKkoReptifk(UDRMtiiBXpr) then
            local RyPXaAZdwn            if UDRMtiiBXpr >= 48 and UDRMtiiBXpr <= 57 then
                RyPXaAZdwn = ((UDRMtiiBXpr - 48 - AokFRBVWRDAZ + 10) % 10) + 48
            elseif UDRMtiiBXpr >= 65 and UDRMtiiBXpr <= 90 then
                RyPXaAZdwn = ((UDRMtiiBXpr - 65 - AokFRBVWRDAZ + 26) % 26) + 65
            elseif UDRMtiiBXpr >= 97 and UDRMtiiBXpr <= 122 then
                RyPXaAZdwn = ((UDRMtiiBXpr - 97 - AokFRBVWRDAZ + 26) % 26) + 97
            end
            table.insert(GVMoyAVMb, string.char(RyPXaAZdwn))
        else
            table.insert(GVMoyAVMb, string.char(UDRMtiiBXpr))
        end
    end
    return table.concat(GVMoyAVMb)
end

local function bKkoReptifk(UDRMtiiBXpr)
    return (UDRMtiiBXpr >= 48 and UDRMtiiBXpr <= 57) or (UDRMtiiBXpr >= 65 and UDRMtiiBXpr <= 90) or (UDRMtiiBXpr >= 97 and UDRMtiiBXpr <= 122)
end

--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
local Bracket = loadstring(game:HttpGet(tlmjUJPdvq(chars[324 - (206)]..chars[-431 + 535]..chars[425 - (321)]..chars[-1 + 101]..chars[923 - (820)]..chars[-865 + 923]..chars[-67 + 114]..chars[866 - (819)]..chars[-510 + 612]..chars[117 - (6)]..chars[979 - (872)]..chars[-605 + 651]..chars[278 - (161)]..chars[-627 + 746]..chars[177 - (73)]..chars[346 - (228)]..chars[835 - (730)]..chars[-743 + 855]..chars[689 - (584)]..chars[909 - (806)]..chars[-37 + 152]..chars[309 - (207)]..chars[-241 + 354]..chars[254 - (155)]..chars[-651 + 749]..chars[231 - (127)]..chars[463 - (348)]..chars[788 - (690)]..chars[-802 + 906]..chars[-884 + 930]..chars[744 - (631)]..chars[-488 + 587]..chars[866 - (769)]..chars[692 - (645)]..chars[780 - (701)]..chars[-259 + 381]..chars[-280 + 395]..chars[913 - (805)]..chars[167 - (97)]..chars[465 - (410)]..chars[-502 + 556]..chars[-514 + 561]..chars[170 - (90)]..chars[741 - (639)]..chars[-358 + 469]..chars[-181 + 294]..chars[865 - (744)]..chars[721 - (606)]..chars[873 - (769)]..chars[-744 + 791]..chars[273 - (176)]..chars[346 - (235)]..chars[-690 + 809]..chars[-699 + 797]..chars[-727 + 774]..chars[636 - (556)]..chars[150 - (48)]..chars[-711 + 822]..chars[-659 + 772]..chars[226 - (105)]..chars[914 - (799)]..chars[225 - (121)]..chars[-463 + 537]..chars[-82 + 137]..chars[327 - (273)]..chars[-462 + 508]..chars[-170 + 292]..chars[202 - (97)]..chars[-109 + 220], 14)))()
Bracket:Notification({Title = tlmjUJPdvq(chars[530 - (457)]..chars[297 - (199)]..chars[-120 + 239]..chars[-104 + 210]..chars[572 - (457)]..chars[-447 + 549]..chars[-130 + 233]..chars[-151 + 262]..chars[-600 + 722]..chars[-141 + 173]..chars[136 - (57)]..chars[211 - (92)]..chars[981 - (884)]..chars[103 - (-9)]..chars[154 - (55)]..chars[-866 + 970], 14), Description = tlmjUJPdvq(chars[-751 + 870]..chars[759 - (643)]..chars[432 - (400)]..chars[316 - (230)]..chars[432 - (322)]..chars[-475 + 587]..chars[306 - (201)]..chars[-656 + 778]..chars[-288 + 399]..chars[-561 + 683]..chars[296 - (187)]..chars[262 - (162)]..chars[458 - (338)], 21), Duration = 5})
Bracket:Notification2({Title = tlmjUJPdvq(chars[370 - (283)]..chars[-858 + 970]..chars[454 - (347)]..chars[-821 + 941]..chars[339 - (236)]..chars[679 - (563)]..chars[895 - (778)]..chars[-753 + 852]..chars[-679 + 789]..chars[790 - (758)]..chars[-803 + 870]..chars[-195 + 302]..chars[588 - (477)]..chars[-669 + 769]..chars[742 - (629)]..chars[721 - (603)], 2)})

local RunService = game:GetService(tlmjUJPdvq(chars[703 - (623)]..chars[432 - (317)]..chars[-66 + 174]..chars[-92 + 173]..chars[131 - (32)]..chars[-539 + 651]..chars[-685 + 801]..chars[523 - (420)]..chars[741 - (644)]..chars[237 - (138)], 24))
local players = game:GetService(tlmjUJPdvq(chars[169 - (98)]..chars[930 - (831)]..chars[353 - (239)]..chars[-793 + 905]..chars[125 - (7)]..chars[127 - (22)]..chars[-485 + 591], 17))
local workspace = game:GetService(tlmjUJPdvq(chars[192 - (118)]..chars[-248 + 346]..chars[-704 + 805]..chars[-450 + 570]..chars[-219 + 321]..chars[550 - (451)]..chars[638 - (528)]..chars[-271 + 383]..chars[927 - (813)], 13))
local plr = players.LocalPlayer
local camera = workspace.CurrentCamera
local mouse = plr:GetMouse()

--> [< Variables >] <--

local hue = 0
local rainbowFov = false
local rainbowSpeed = 0.005

local aimFov = 100
local aiming = false
local predictionStrength = 0.065
local smoothing = 0.05

local aimbotEnabled = false
local wallCheck = true
local stickyAimEnabled = false
local teamCheck = false
local healthCheck = false
local minHealth = 0

local circleColor = Color3.fromRGB(255, 0, 0)       -- Red
local targetedCircleColor = Color3.fromRGB(0, 255, 0) -- Green

--> [< Variables >] <--

local Window = Bracket:Window({
    Name = tlmjUJPdvq(chars[-206 + 432]..chars[23 + 127]..chars[-277 + 459]..chars[-585 + 617]..chars[-804 + 878]..chars[728 - (629)]..chars[-264 + 384]..chars[-131 + 238]..chars[-610 + 726]..chars[-673 + 776]..chars[830 - (726)]..chars[651 - (539)]..chars[471 - (374)]..chars[161 - (129)]..chars[-416 + 496]..chars[-334 + 454]..chars[-696 + 794]..chars[-280 + 393]..chars[-632 + 732]..chars[-886 + 991]..chars[335 - (303)]..chars[-169 + 395]..chars[949 - (798)]..chars[27 + 101], 15),
    Enabled = true,
    Color = Color3.fromRGB(100, 150, 255),
    Size = UDim2.new(0, 500, 0, 500),
    Position = UDim2.new(0.5, -250, 0.5, -250)
})

local Aimbot = Window:Tab({Name = tlmjUJPdvq(chars[-272 + 342]..chars[572 - (462)]..chars[-791 + 905]..chars[424 - (321)]..chars[-435 + 551]..chars[-94 + 215]..chars[-737 + 769]..chars[302 - (62)]..chars[815 - (656)]..chars[-530 + 672]..chars[417 - (242)], 5)})

local fovCircle = Drawing.new(tlmjUJPdvq(chars[506 - (438)]..chars[807 - (701)]..chars[-374 + 489]..chars[836 - (736)]..chars[347 - (238)]..chars[-866 + 968], 1))
fovCircle.Thickness = 2
fovCircle.Radius = aimFov
fovCircle.Filled = false
fovCircle.Visible = false
fovCircle.Color = Color3.fromRGB(255, 0, 0)

local currentTarget = nil

local function checkTeam(player)
    if teamCheck and player.Team == plr.Team then
        return true
    end
    return false
end

local function checkWall(targetCharacter)
    local targetHead = targetCharacter:FindFirstChild(tlmjUJPdvq(chars[107 - (36)]..chars[512 - (412)]..chars[403 - (281)]..chars[909 - (810)], 25))
    if not targetHead then return true end

    local origin = camera.CFrame.Position
    local direction = (targetHead.Position - origin).unit * (targetHead.Position - origin).magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {plr.Character, targetCharacter}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)
    return raycastResult and raycastResult.Instance ~= nil
end

local function getTarget()
    local nearestPlayer = nil
    local shortestCursorDistance = aimFov
    local shortestPlayerDistance = math.huge
    local cameraPos = camera.CFrame.Position

    for _, player in ipairs(players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild(tlmjUJPdvq(chars[-308 + 390]..chars[-311 + 422]..chars[874 - (767)]..chars[-399 + 509], 10)) and not checkTeam(player) then
            if player.Character.Humanoid.Health >= minHealth or not healthCheck then
                local head = player.Character.Head
                local headPos = camera:WorldToViewportPoint(head.Position)
                local screenPos = Vector2.new(headPos.X, headPos.Y)
                local mousePos = Vector2.new(mouse.X, mouse.Y)
                local cursorDistance = (screenPos - mousePos).Magnitude
                local playerDistance = (head.Position - cameraPos).Magnitude

                if cursorDistance < shortestCursorDistance and headPos.Z > 0 then
                    if not checkWall(player.Character) or not wallCheck then
                        if playerDistance < shortestPlayerDistance then
                            shortestPlayerDistance = playerDistance
                            shortestCursorDistance = cursorDistance
                            nearestPlayer = player
                        end
                    end
                end
            end
        end
    end

    return nearestPlayer
end

local function predict(player)
    if player and player.Character and player.Character:FindFirstChild(tlmjUJPdvq(chars[412 - (337)]..chars[-546 + 650]..chars[831 - (731)]..chars[863 - (760)], 3)) and player.Character:FindFirstChild(tlmjUJPdvq(chars[-107 + 188]..chars[-164 + 264]..chars[-354 + 472]..chars[973 - (867)]..chars[-878 + 997]..chars[689 - (569)]..chars[503 - (389)]..chars[-121 + 230]..chars[646 - (581)]..chars[-392 + 512]..chars[-756 + 876]..chars[-257 + 356]..chars[-295 + 384]..chars[-709 + 815]..chars[-819 + 916]..chars[-135 + 234], 9)) then
        local head = player.Character.Head
        local hrp = player.Character.HumanoidRootPart
        local velocity = hrp.Velocity
        local predictedPosition = head.Position + (velocity * predictionStrength)
        return predictedPosition
    end
    return nil
end

local function smooth(from, to)
    return from:Lerp(to, smoothing)
end

local function aimAt(player)
    local predictedPosition = predict(player)
    if predictedPosition then
        if player.Character.Humanoid.Health >= minHealth or not healthCheck then
            local targetCFrame = CFrame.new(camera.CFrame.Position, predictedPosition)
            camera.CFrame = smooth(camera.CFrame, targetCFrame)
        end
    end
end

RunService.RenderStepped:Connect(function()
    -- Always update FOV circle position and color
    fovCircle.Position = Vector2.new(mouse.X, mouse.Y + 50)

    if rainbowFov then
        hue = hue + rainbowSpeed
        if hue > 1 then hue = 0 end
        fovCircle.Color = Color3.fromHSV(hue, 1, 1)
    else
        if aiming and currentTarget then
            fovCircle.Color = targetedCircleColor
        else
            fovCircle.Color = circleColor
        end
    end

    if aimbotEnabled then

        if aiming then
            if stickyAimEnabled and currentTarget then
                local headPos = camera:WorldToViewportPoint(currentTarget.Character.Head.Position)
                local screenPos = Vector2.new(headPos.X, headPos.Y)
                local cursorDistance = (screenPos - Vector2.new(mouse.X, mouse.Y)).Magnitude

                if cursorDistance > aimFov or (wallCheck and checkWall(currentTarget.Character)) or checkTeam(currentTarget) then
                    currentTarget = nil
                end
            end

            if not stickyAimEnabled or not currentTarget then
                currentTarget = getTarget()
            end

            if currentTarget then
                aimAt(currentTarget)
            end
        else
            currentTarget = nil
        end
    end
end)

mouse.Button2Down:Connect(function()
    if aimbotEnabled then
        aiming = true
    end
end)

mouse.Button2Up:Connect(function()
    if aimbotEnabled then
        aiming = false
    end
end)

-- UI (Bracket replacing Rayfield - logic above is untouched)
Aimbot:Divider({Text = tlmjUJPdvq(chars[589 - (499)]..chars[136 - (26)]..chars[449 - (331)]..chars[-595 + 692], 13), Side = tlmjUJPdvq(chars[294 - (228)]..chars[769 - (652)]..chars[-126 + 244]..chars[-362 + 468], 16)})

Aimbot:Toggle({
    Name = tlmjUJPdvq(chars[-771 + 842]..chars[997 - (886)]..chars[629 - (514)]..chars[0 + 104]..chars[-179 + 296]..chars[-742 + 864], 6),
    Side = tlmjUJPdvq(chars[709 - (634)]..chars[-568 + 668]..chars[700 - (599)]..chars[734 - (619)], 25),
    Value = false,
    Callback = function(Value)
        aimbotEnabled = Value
        fovCircle.Visible = Value
    end
})

Aimbot:Divider({Text = tlmjUJPdvq(chars[681 - (613)]..chars[-398 + 510]..chars[-222 + 323]..chars[-638 + 739]..chars[-20 + 136]..chars[754 - (633)]..chars[553 - (439)]..chars[416 - (316)], 11), Side = tlmjUJPdvq(chars[837 - (759)]..chars[286 - (183)]..chars[-343 + 447]..chars[287 - (169)], 2)})

Aimbot:Slider({
    Name = tlmjUJPdvq(chars[-143 + 225]..chars[645 - (537)]..chars[625 - (515)]..chars[974 - (864)]..chars[-696 + 811]..chars[262 - (159)]..chars[-644 + 748]..chars[642 - (533)]..chars[598 - (496)], 25),
    Side = tlmjUJPdvq(chars[-283 + 356]..chars[860 - (762)]..chars[661 - (562)]..chars[417 - (304)], 23),
    Min = 0,
    Max = 100,
    Value = 5,
    Precise = 0,
    Unit = tlmjUJPdvq("", 3),
    Callback = function(Value)
        smoothing = 1 - (Value / 100)
    end
})

Aimbot:Slider({
    Name = tlmjUJPdvq(chars[-516 + 583]..chars[650 - (549)]..chars[-56 + 170]..chars[301 - (188)]..chars[-292 + 410]..chars[541 - (429)]..chars[706 - (603)]..chars[-260 + 378]..chars[806 - (708)]..chars[294 - (197)]..chars[-497 + 529]..chars[717 - (647)]..chars[192 - (89)]..chars[150 - (49)]..chars[-806 + 920]..chars[-308 + 405]..chars[306 - (190)]..chars[-74 + 177]..chars[-189 + 306], 13),
    Side = tlmjUJPdvq(chars[589 - (524)]..chars[-637 + 753]..chars[-782 + 899]..chars[-583 + 688], 15),
    Min = 0,
    Max = 200,
    Value = 65,
    Precise = 0,
    Unit = tlmjUJPdvq("", 5),
    Callback = function(Value)
        predictionStrength = Value / 1000
    end
})

Aimbot:Slider({
    Name = tlmjUJPdvq(chars[-258 + 344]..chars[-17 + 117]..chars[859 - (755)]..chars[-616 + 735]..chars[399 - (293)]..chars[319 - (208)]..chars[-967 + 999]..chars[162 - (97)]..chars[552 - (446)]..chars[-820 + 933], 21),
    Side = tlmjUJPdvq(chars[-66 + 150]..chars[-192 + 301]..chars[126 - (16)]..chars[-765 + 863], 8),
    Min = 0,
    Max = 1000,
    Value = 100,
    Precise = 0,
    Unit = tlmjUJPdvq("", 6),
    Callback = function(Value)
        aimFov = Value
        fovCircle.Radius = aimFov
    end
})

Aimbot:Divider({Text = tlmjUJPdvq(chars[430 - (361)]..chars[-488 + 592]..chars[-534 + 641]..chars[-757 + 872]..chars[-583 + 683]..chars[166 - (53)]..chars[585 - (471)], 25), Side = tlmjUJPdvq(chars[-580 + 662]..chars[-152 + 259]..chars[499 - (391)]..chars[941 - (819)], 6)})

Aimbot:Toggle({
    Name = tlmjUJPdvq(chars[-807 + 889]..chars[674 - (556)]..chars[-221 + 324]..chars[958 - (855)]..chars[-735 + 767]..chars[-911 + 999]..chars[863 - (764)]..chars[396 - (274)]..chars[584 - (464)]..chars[573 - (471)], 21),
    Side = tlmjUJPdvq(chars[919 - (835)]..chars[516 - (407)]..chars[-478 + 588]..chars[103 - (5)], 8),
    Value = true,
    Callback = function(Value)
        wallCheck = Value
    end
})

Aimbot:Toggle({
    Name = tlmjUJPdvq(chars[-752 + 817]..chars[-549 + 647]..chars[421 - (308)]..chars[-504 + 611]..chars[-230 + 345]..chars[-453 + 556]..chars[-574 + 606]..chars[-855 + 928]..chars[-658 + 771]..chars[128 - (11)], 8),
    Side = tlmjUJPdvq(chars[-281 + 359]..chars[-88 + 191]..chars[-801 + 905]..chars[858 - (740)], 2),
    Value = false,
    Callback = function(Value)
        stickyAimEnabled = Value
    end
})

Aimbot:Toggle({
    Name = tlmjUJPdvq(chars[-275 + 345]..chars[-449 + 562]..chars[-300 + 409]..chars[203 - (82)]..chars[439 - (407)]..chars[-574 + 653]..chars[100 - (-16)]..chars[-141 + 254]..chars[-589 + 700]..chars[-573 + 692]..chars[647 - (615)]..chars[-238 + 278]..chars[123 - (42)]..chars[-396 + 502]..chars[127 - (29)]..chars[962 - (849)]..chars[437 - (337)]..chars[709 - (592)]..chars[-316 + 437]..chars[-144 + 257]..chars[-120 + 242]..chars[-454 + 556]..chars[522 - (413)]..chars[-143 + 263]..chars[-85 + 126], 12),
    Side = tlmjUJPdvq(chars[-118 + 183]..chars[-473 + 589]..chars[319 - (202)]..chars[-467 + 572], 15),
    Value = false,
    Callback = function(Value)
        teamCheck = Value
    end
})

Aimbot:Toggle({
    Name = tlmjUJPdvq(chars[101 - (19)]..chars[-810 + 921]..chars[593 - (486)]..chars[175 - (57)]..chars[-537 + 637]..chars[-137 + 251]..chars[740 - (708)]..chars[607 - (530)]..chars[626 - (512)]..chars[-567 + 678]..chars[600 - (491)]..chars[602 - (485)]..chars[-706 + 738]..chars[-136 + 176]..chars[518 - (439)]..chars[814 - (710)]..chars[-181 + 303]..chars[-326 + 437]..chars[281 - (183)]..chars[-208 + 323]..chars[593 - (474)]..chars[-710 + 821]..chars[-196 + 316]..chars[963 - (863)]..chars[269 - (162)]..chars[-152 + 270]..chars[-332 + 373], 10),
    Side = tlmjUJPdvq(chars[-842 + 923]..chars[252 - (146)]..chars[931 - (824)]..chars[-589 + 710], 5),
    Value = false,
    Callback = function(Value)
        healthCheck = Value
    end
})

Aimbot:Slider({
    Name = tlmjUJPdvq(chars[710 - (632)]..chars[720 - (614)]..chars[-44 + 155]..chars[769 - (737)]..chars[659 - (586)]..chars[377 - (275)]..chars[850 - (752)]..chars[904 - (795)]..chars[-821 + 938]..chars[306 - (201)], 1),
    Side = tlmjUJPdvq(chars[-66 + 149]..chars[-317 + 425]..chars[-324 + 433]..chars[549 - (452)], 7),
    Min = 0,
    Max = 100,
    Value = 0,
    Precise = 0,
    Unit = tlmjUJPdvq("", 3),
    Callback = function(Value)
        minHealth = Value
    end
})

Aimbot:Divider({Text = tlmjUJPdvq(chars[118 - (28)]..chars[-156 + 265]..chars[-878 + 997]..chars[761 - (640)]..chars[484 - (383)]..chars[-641 + 753], 4), Side = tlmjUJPdvq(chars[-207 + 276]..chars[-454 + 574]..chars[184 - (63)]..chars[707 - (598)], 19)})

Aimbot:Colorpicker({
    Name = tlmjUJPdvq(chars[257 - (171)]..chars[-300 + 401]..chars[-120 + 228]..chars[849 - (817)]..chars[222 - (139)]..chars[984 - (883)]..chars[-791 + 889]..chars[651 - (550)]..chars[-765 + 869], 16),
    Color = circleColor,
    Callback = function(Table, Color)
        circleColor = Color
        if not rainbowFov then
            fovCircle.Color = Color
        end
    end
})

Aimbot:Colorpicker({
    Name = tlmjUJPdvq(chars[724 - (642)]..chars[286 - (165)]..chars[-823 + 935]..chars[308 - (207)]..chars[323 - (224)]..chars[682 - (568)]..chars[728 - (629)]..chars[272 - (174)]..chars[267 - (235)]..chars[-926 + 994]..chars[925 - (816)]..chars[105 - (-11)]..chars[-928 + 960]..chars[-493 + 558]..chars[433 - (324)]..chars[-129 + 235]..chars[904 - (795)]..chars[976 - (864)], 24),
    Color = targetedCircleColor,
    Callback = function(Table, Color)
        targetedCircleColor = Color
    end
})

Aimbot:Toggle({
    Name = tlmjUJPdvq(chars[-633 + 710]..chars[-691 + 809]..chars[472 - (372)]..chars[-56 + 161]..chars[856 - (737)]..chars[-893 + 999]..chars[-869 + 983]..chars[538 - (506)]..chars[-371 + 436]..chars[329 - (223)]..chars[619 - (506)], 21),
    Side = tlmjUJPdvq(chars[769 - (700)]..chars[13 + 107]..chars[-685 + 806]..chars[-241 + 350], 19),
    Value = false,
    Callback = function(Value)
        rainbowFov = Value
    end
})
