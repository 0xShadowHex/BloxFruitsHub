local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VIM = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
getgenv().Hunt = true
getgenv().HuntSpeed = 140
getgenv().TravelSpeed = 140
getgenv().HoverHeight = 9
getgenv().AttackInterval = 0.28
getgenv().StrictLevel = false
local CurrentTarget = nil
local TargetSpawn = nil
local TravelTween = nil
local HoverTweening = false
local Skipped = {}
local SkipVersion = 0
local RegAtk = nil
local RegHit = nil
pcall(function()
    local net = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Net", 5)
    RegAtk = net:FindFirstChild("RE/RegisterAttack")
    RegHit = net:FindFirstChild("RE/RegisterHit")
end)
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("BF_HuntUI")
    if old then old:Destroy() end
end)
local gui = Instance.new("ScreenGui")
gui.Name = "BF_HuntUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer.PlayerGui
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 200, 0, 130)
main.Position = UDim2.new(0, 20, 0, 120)
main.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 28)
title.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
title.BorderSizePixel = 0
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Hunter"
title.Parent = main
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -16, 0, 44)
status.Position = UDim2.new(0, 8, 0, 34)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextYAlignment = Enum.TextYAlignment.Top
status.Text = "Waiting..."
status.Parent = main
local skipBtn = Instance.new("TextButton")
skipBtn.Size = UDim2.new(1, -16, 0, 32)
skipBtn.Position = UDim2.new(0, 8, 0, 86)
skipBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
skipBtn.BorderSizePixel = 0
skipBtn.Font = Enum.Font.GothamBold
skipBtn.TextSize = 13
skipBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
skipBtn.Text = "Skip Player"
skipBtn.Parent = main
local function SetStatus(t)
    pcall(function() status.Text = t end)
end
skipBtn.MouseButton1Click:Connect(function()
    if CurrentTarget then
        pcall(function() Skipped[CurrentTarget.UserId] = true end)
    end
    CurrentTarget = nil
    TargetSpawn = nil
    SkipVersion = SkipVersion + 1
    pcall(function() if TravelTween then TravelTween:Cancel() end end)
    HoverTweening = false
    SetStatus("Skipped")
end)
local function GetChar()
    return LocalPlayer.Character
end
local function GetHrp()
    local c = GetChar()
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end
local function GetHum()
    local c = GetChar()
    if c then return c:FindFirstChildOfClass("Humanoid") end
    return nil
end
local function GetLevel(plr)
    local lvl = nil
    pcall(function()
        local d = plr:FindFirstChild("Data")
        if d then
            local o = d:FindFirstChild("Level")
            if o then lvl = o.Value end
        end
        if lvl == nil then
            local s = plr:FindFirstChild("leaderstats")
            if s then
                local l2 = s:FindFirstChild("Level") or s:FindFirstChild("Lvl")
                if l2 then lvl = l2.Value end
            end
        end
    end)
    if type(lvl) == "number" then return lvl end
    return nil
end
local function LevelOk(target)
    local mine = GetLevel(LocalPlayer)
    local his = GetLevel(target)
    if mine == nil then return not getgenv().StrictLevel end
    if his == nil then return not getgenv().StrictLevel end
    if mine <= 0 then return false end
    local diff = math.abs(his - mine)
    return diff <= mine * 0.2
end
local function AliveCheck(plr)
    if plr == nil then return false end
    if plr == LocalPlayer then return false end
    local c = plr.Character
    if c == nil then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    if h == nil or r == nil then return false end
    if h.Health <= 0 then return false end
    return true
end
local function TweenTo(cf, speed)
    speed = speed or getgenv().TravelSpeed or 140
    local myVer = SkipVersion
    pcall(function() if TravelTween then TravelTween:Cancel() end TravelTween = nil end)
    local hrp = GetHrp()
    if hrp == nil then return false end
    if (hrp.Position - cf.Position).Magnitude < 10 then return true end
    local dist = (hrp.Position - cf.Position).Magnitude
    local t = math.clamp(dist / speed, 0.5, 60)
    local done = false
    local ok = pcall(function()
        local tw = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = cf})
        TravelTween = tw
        tw.Completed:Connect(function() done = true end)
        tw:Play()
    end)
    if not ok then
        pcall(function() GetHrp().CFrame = cf end)
        return true
    end
    local waited = 0
    while not done and waited < t + 3 do
        if getgenv().Hunt == false then pcall(function() if TravelTween then TravelTween:Cancel() end end) return false end
        if myVer ~= SkipVersion then pcall(function() if TravelTween then TravelTween:Cancel() end end) return false end
        if CurrentTarget == nil then pcall(function() if TravelTween then TravelTween:Cancel() end end) return false end
        if AliveCheck(CurrentTarget) == false then pcall(function() if TravelTween then TravelTween:Cancel() end end) return false end
        local cur = GetHrp()
        if cur == nil then return false end
        if (cur.Position - cf.Position).Magnitude < 15 then
            pcall(function() if TravelTween then TravelTween:Cancel() end end)
            return true
        end
        task.wait(0.15)
        waited = waited + 0.15
    end
    local cur2 = GetHrp()
    return cur2 and (cur2.Position - cf.Position).Magnitude < 25 or done
end
local function Press(kc, gap)
    pcall(function()
        VIM:SendKeyEvent(true, kc, false, game)
        task.wait(0.08)
        VIM:SendKeyEvent(false, kc, false, game)
    end)
    task.wait(gap)
end
RunService.Stepped:Connect(function()
    if getgenv().Hunt == false then return end
    pcall(function()
        local c = GetChar()
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end)
task.spawn(function()
    while getgenv().Hunt do
        if CurrentTarget and AliveCheck(CurrentTarget) then
            local ehrp = nil
            pcall(function() ehrp = CurrentTarget.Character:FindFirstChild("HumanoidRootPart") end)
            if ehrp then
                if RegAtk then
                    pcall(function() RegAtk:FireServer(ehrp) end)
                    pcall(function() RegAtk:FireServer({ehrp}) end)
                end
                if RegHit then
                    pcall(function() RegHit:FireServer(ehrp) end)
                    pcall(function() RegHit:FireServer({ehrp}) end)
                end
            end
            task.wait(0.02)
        else
            task.wait(0.5)
        end
    end
end)
task.spawn(function()
    local swings = 0
    while getgenv().Hunt do
        if CurrentTarget and AliveCheck(CurrentTarget) then
            pcall(function()
                local c = GetChar()
                local tool = c and c:FindFirstChildOfClass("Tool")
                if tool then tool:Activate() end
            end)
            swings = swings + 1
            if swings % 4 == 0 then
                pcall(function()
                    local c = GetChar()
                    local hum = c and c:FindFirstChildOfClass("Humanoid")
                    local tool = c and c:FindFirstChildOfClass("Tool")
                    if hum and tool then
                        hum:UnequipTools()
                        task.wait(0.05)
                        hum:EquipTool(tool)
                    end
                end)
            end
        else
            swings = 0
        end
        task.wait(getgenv().AttackInterval)
    end
end)
task.spawn(function()
    while getgenv().Hunt do
        local ok = pcall(function()
            local me = GetHrp()
            local myLvl = GetLevel(LocalPlayer)
            if me == nil then SetStatus("No char") task.wait(0.5) return end
            if CurrentTarget == nil or AliveCheck(CurrentTarget) == false then
                local hrpPos = me.Position
                local best = nil
                local bestD = 1e9
                for _, p in pairs(Players:GetPlayers()) do
                    if Skipped[p.UserId] ~= true and AliveCheck(p) and LevelOk(p) then
                        local r = nil
                        pcall(function() r = p.Character:FindFirstChild("HumanoidRootPart") end)
                        if r then
                            local d = (r.Position - hrpPos).Magnitude
                            if d < bestD then bestD = d best = p end
                        end
                    end
                end
                CurrentTarget = best
                TargetSpawn = nil
                pcall(function() if TravelTween then TravelTween:Cancel() end end)
                HoverTweening = false
                if CurrentTarget then
                    local er = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                    if er then
                        pcall(function() TargetSpawn = er.CFrame end)
                        local hisLvl = GetLevel(CurrentTarget)
                        SetStatus("Lock " .. CurrentTarget.Name .. " Lvl:" .. tostring(hisLvl) .. " D:" .. tostring(math.floor(bestD)))
                        pcall(function()
                            VIM:SendKeyEvent(true, Enum.KeyCode.J, false, game)
                            task.wait(0.1)
                            VIM:SendKeyEvent(false, Enum.KeyCode.J, false, game)
                        end)
                    else
                        CurrentTarget = nil
                    end
                else
                    local total = #Players:GetPlayers() - 1
                    SetStatus("MyLvl:" .. tostring(myLvl) .. " No target 20pct " .. tostring(total))
                    task.wait(0.5)
                end
            elseif CurrentTarget and AliveCheck(CurrentTarget) and TargetSpawn == nil then
                pcall(function()
                    local rer = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                    if rer then TargetSpawn = rer.CFrame end
                end)
            end
        end)
        if ok == false then task.wait(0.5) end
        task.wait(0.25)
    end
end)
task.spawn(function()
    local fightVer = 0
    local lastSkill = 0
    while getgenv().Hunt do
        if CurrentTarget and AliveCheck(CurrentTarget) and LevelOk(CurrentTarget) and fightVer == SkipVersion then
            local waiting = false
            pcall(function()
                if HoverTweening then waiting = true end
                local hrp = GetHrp()
                local er = CurrentTarget.Character:FindFirstChild("HumanoidRootPart")
                if hrp and er then
                    if (hrp.Position - er.Position).Magnitude > 30 then waiting = true end
                else
                    waiting = true
                end
            end)
            if waiting then task.wait(0.4) continue end
            if os.clock() - lastSkill > 5.2 then
                lastSkill = os.clock()
                fightVer = SkipVersion
                Press(Enum.KeyCode.One, 0.35)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.Z, 0.5)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.X, 0.5)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.C, 0.5)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.Two, 0.35)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.Z, 0.5)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.C, 0.5)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.X, 0.5)
                if CurrentTarget == nil or fightVer ~= SkipVersion or AliveCheck(CurrentTarget) == false then task.wait(0.2) continue end
                Press(Enum.KeyCode.V, 0.6)
            else
                task.wait(0.2)
            end
        else
            fightVer = SkipVersion
            task.wait(0.4)
        end
    end
end)
Players.PlayerRemoving:Connect(function(p)
    pcall(function() Skipped[p.UserId] = nil end)
    if CurrentTarget == p then
        CurrentTarget = nil
        TargetSpawn = nil
        SkipVersion = SkipVersion + 1
    end
end)
RunService.Heartbeat:Connect(function()
    if getgenv().Hunt == false then return end
    if CurrentTarget == nil then return end
    if AliveCheck(CurrentTarget) == false then return end
    local hrp = GetHrp()
    local hum = GetHum()
    local er = nil
    pcall(function() er = CurrentTarget.Character:FindFirstChild("HumanoidRootPart") end)
    if hrp == nil or hum == nil or er == nil then return end
    if TargetSpawn == nil then
        pcall(function() TargetSpawn = er.CFrame end)
        if TargetSpawn == nil then return end
    end
    if (TargetSpawn.Position - er.Position).Magnitude > 40 then
        TargetSpawn = er.CFrame
    end
    pcall(function()
        local hoverPos = TargetSpawn.Position + Vector3.new(0, getgenv().HoverHeight, 0)
        local hoverCF = CFrame.new(hoverPos, er.Position)
        if (hrp.Position - hoverCF.Position).Magnitude > 200 then
            if not HoverTweening then
                HoverTweening = true
                task.spawn(function()
                    TweenTo(hoverCF)
                    HoverTweening = false
                end)
            end
        else
            hrp.CFrame = hoverCF
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end)
end)
