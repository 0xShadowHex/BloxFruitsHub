-- BloxFruitsHub combined script (no GUIs)
-- All modules merged from: ForceDay, visuals, teleporter, PlayerStatsInspector, esp, autofarm, autobounty

local Config = {
    ForceDay = false,       -- force daytime lighting (ClockTime = 14)
    autofarm = false,       -- auto quest + farm mobs by level stage
    travelToIsland = "Magma Village",   -- auto-travel once on load. Options:
                            --   "Marine Starter", "Pirate Starter", "Jungle", "Pirate Village",
                            --   "Desert", "Frozen Island", "Marine Fortress", "Skylands",
                            --   "Prison", "Colosseum", "Magma Village", "Underwater City",
                            --   "Upper Sky Gods guards", "Upper Sky Island 1",
                            --   "Upper Sky Island 2", "Fountain City"
    SetVisualBeli = nil,    -- number to spoof Beli, or nil for no change
    SetVisualFragments = 100000, -- number to spoof Fragments, or nil
    SetVisualLevel = nil,   -- number to spoof Level, or nil
    SetVisualStats = nil,   -- number to spoof Points, or nil
    enableESP = true,      -- player ESP (name + level + distance + highlight)
    autobounty = false,     -- auto hunt nearest player within 20% level range
}

-- Shared tunables (same defaults each module used originally)
getgenv().TravelSpeed = getgenv().TravelSpeed or 140
getgenv().HoverHeight = getgenv().HoverHeight or 9
getgenv().AttackInterval = getgenv().AttackInterval or 0.28

-- ============================== Re-execution guard ==============================
-- Kills the previous instance (connections, tweens, loops) before this one starts.
do
    local prev = getgenv().BloxFruitsHub
    if prev and prev.Stop then
        pcall(prev.Stop)
    end
end
getgenv().BloxFruitsHubRun = (getgenv().BloxFruitsHubRun or 0) + 1
local HubRun = getgenv().BloxFruitsHubRun
local Hub = { Run = HubRun, Conns = {}, Stops = {} }
function Hub:Bind(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self.Conns, c)
    return c
end
function Hub:OnStop(fn)
    table.insert(self.Stops, fn)
end
function Hub.Stop()
    getgenv().AutoFarm = false
    getgenv().PlayerESP = false
    getgenv().Hunt = false
    for _, c in ipairs(Hub.Conns) do
        pcall(function() c:Disconnect() end)
    end
    for _, f in ipairs(Hub.Stops) do
        pcall(f)
    end
    table.clear(Hub.Conns)
    table.clear(Hub.Stops)
end
getgenv().BloxFruitsHub = Hub
local function HubAlive()
    return getgenv().BloxFruitsHubRun == HubRun
end

-- readPlayerStats(username) -> { beli, exp, fragments, level, points, bounty } (values or nil)
local function readPlayerStats(username)
    local Players = game:GetService("Players")
    local target = nil
    if typeof(username) == "Instance" and username:IsA("Player") then
        target = username
    elseif typeof(username) == "string" then
        target = Players:FindFirstChild(username)
        if not target then
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Name:lower() == username:lower() or p.DisplayName:lower() == username:lower() then
                    target = p
                    break
                end
            end
        end
    end
    if not target then return nil end
    local out = { beli = nil, exp = nil, fragments = nil, level = nil, points = nil, bounty = nil }
    local function get(field)
        local v = nil
        pcall(function()
            local d = target:FindFirstChild("Data")
            if d then
                local o = d:FindFirstChild(field)
                if o then v = o.Value end
            end
            if v == nil then
                local s = target:FindFirstChild("leaderstats")
                if s then
                    local o2 = s:FindFirstChild(field)
                    if o2 then v = o2.Value end
                end
            end
        end)
        return v
    end
    out.beli = get("Beli")
    out.exp = get("Exp")
    out.fragments = get("Fragments")
    out.level = get("Level")
    out.points = get("Points")
    out.bounty = get("Bounty/Honor")
    return out
end
getgenv().readPlayerStats = readPlayerStats

-- ============================== ForceDay ==============================
if Config.ForceDay then
    local Lighting = game:GetService("Lighting")
    local ForceDayConnection = nil

    function ForceDay()
        if ForceDayConnection then
            ForceDayConnection:Disconnect()
        end

        Lighting.ClockTime = 14

        ForceDayConnection = Hub:Bind(Lighting:GetPropertyChangedSignal("ClockTime"), function()
            Lighting.ClockTime = 14
        end)
    end
    Hub:OnStop(function()
        if ForceDayConnection then
            ForceDayConnection:Disconnect()
            ForceDayConnection = nil
        end
    end)
    ForceDay()
end

-- ============================== Visuals (SetVisual*) ==============================
do
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Data = LocalPlayer:WaitForChild("Data")

    if Config.SetVisualBeli ~= nil then
        pcall(function() Data.Beli.Value = math.floor(Config.SetVisualBeli) end)
    end
    if Config.SetVisualFragments ~= nil then
        pcall(function() Data.Fragments.Value = math.floor(Config.SetVisualFragments) end)
    end
    if Config.SetVisualLevel ~= nil then
        pcall(function() Data.Level.Value = math.floor(Config.SetVisualLevel) end)
    end
    if Config.SetVisualStats ~= nil then
        pcall(function() Data.Points.Value = math.floor(Config.SetVisualStats) end)
    end
end

-- ============================== Teleporter (travelToIsland) ==============================
do
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local RunService = game:GetService("RunService")
    local Player = Players.LocalPlayer
    getgenv().TravelSpeed = getgenv().TravelSpeed or 140
    local ISLANDS = {
        {Name = "Marine Starter", Pos = Vector3.new(-2656.9, 31.7, 2112.7)},
        {Name = "Pirate Starter", Pos = Vector3.new(1052.0, 14.8, 1552.5)},
        {Name = "Jungle", Pos = Vector3.new(-1681.6, 50.1, 174.8)},
        {Name = "Pirate Village", Pos = Vector3.new(-1152.2, 17.3, 3861.1)},
        {Name = "Desert", Pos = Vector3.new(919.5, 5.9, 4203.7)},
        {Name = "Frozen Island", Pos = Vector3.new(1400.8, 78.0, -1307.7)},
        {Name = "Marine Fortress", Pos = Vector3.new(-4695.7, 5.9, 4225.0)},
        {Name = "Skylands", Pos = Vector3.new(-5407.1, 410.7, -695.8)},
        {Name = "Prison", Pos = Vector3.new(5206.4, 19.6, 732.7)},
        {Name = "Colosseum", Pos = Vector3.new(-1343.8, 12.5, -2925.7)},
        {Name = "Magma Village", Pos = Vector3.new(-5312.3, 18.5, 8483.7)},
        {Name = "Underwater City", Pos = Vector3.new(61405.2, 24.9, 1628.8)},
        {Name = "Upper Sky Gods guards", Pos = Vector3.new(-4311.1, 1087.1, -556.9)},
        {Name = "Upper Sky Island 1", Pos = Vector3.new(-5950.7, 5469.2, 2088.6)},
        {Name = "Upper Sky Island 2", Pos = Vector3.new(-7031.9, 5591.9, 1351.0)},
        {Name = "Fountain City", Pos = Vector3.new(5245.5, 76.1, 4093.3)},
    }
    local function GetHrp()
        local c = Player.Character
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local currentTween = nil
    local activeName = nil
    local flying = false
    local function StopTween(drop)
        if currentTween then
            pcall(function() currentTween:Cancel() end)
            currentTween = nil
        end
        flying = false
        if drop then
            pcall(function()
                local hrp = GetHrp()
                if hrp then hrp.AssemblyLinearVelocity = Vector3.zero end
            end)
        end
        activeName = nil
    end
    Hub:OnStop(function()
        StopTween(true)
    end)
    Hub:Bind(RunService.Stepped, function()
        if not flying then return end
        pcall(function()
            local c = Player.Character
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end)
    local function GoTo(entry)
        StopTween(false)
        local hrp = GetHrp()
        if not hrp then return end
        local cf = CFrame.new(entry.Pos + Vector3.new(0, 8, 0))
        local dist = (hrp.Position - cf.Position).Magnitude
        if dist < 10 then return end
        local t = math.clamp(dist / (getgenv().TravelSpeed or 140), 0.5, 120)
        local ok, tw = pcall(function()
            return TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = cf})
        end)
        if not ok or not tw then
            pcall(function() GetHrp().CFrame = cf end)
            return
        end
        currentTween = tw
        flying = true
        activeName = entry.Name
        tw.Completed:Connect(function()
            if activeName == entry.Name then
                StopTween(false)
            end
        end)
        tw:Play()
    end
    getgenv().GoToIsland = function(name)
        local want = string.lower(tostring(name))
        for _, entry in ipairs(ISLANDS) do
            if string.lower(entry.Name) == want then
                GoTo(entry)
                return true
            end
        end
        return false
    end
    if Config.travelToIsland ~= nil then
        local want = string.lower(tostring(Config.travelToIsland))
        for _, entry in ipairs(ISLANDS) do
            if string.lower(entry.Name) == want then
                task.spawn(function()
                    task.wait(3)
                    GoTo(entry)
                end)
                break
            end
        end
    end
end

-- ============================== ESP ==============================
if Config.enableESP then
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    getgenv().PlayerESP = true
    pcall(function()
        for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
            if v.Name == "PESP_Gui" or v.Name == "PESP_HL" then
                pcall(function() v:Destroy() end)
            end
        end
    end)
    local function GetHrp()
        local c = LocalPlayer.Character
        if c then return c:FindFirstChild("HumanoidRootPart") end
        return nil
    end
    local function GetLevel(plr)
        local out = nil
        pcall(function()
            local d = plr:FindFirstChild("Data")
            if d then
                local o = d:FindFirstChild("Level")
                if o then out = o.Value end
            end
        end)
        if out ~= nil then
            return tostring(out)
        end
        return nil
    end
    local function ClearESP(char)
        if char == nil then return end
        pcall(function()
            for _, v in pairs(char:GetDescendants()) do
                if v.Name == "PESP_Gui" or v.Name == "PESP_HL" then
                    v:Destroy()
                end
            end
            local h = char:FindFirstChild("Head")
            if h then
                local g = h:FindFirstChild("PESP_Gui")
                if g then g:Destroy() end
            end
            local r = char:FindFirstChild("HumanoidRootPart")
            if r then
                local g2 = r:FindFirstChild("PESP_Gui")
                if g2 then g2:Destroy() end
            end
        end)
    end
    local function MakeESP(plr)
        if plr == LocalPlayer then return end
        local char = plr.Character
        if char == nil then return end
        ClearESP(char)
        local head = char:WaitForChild("Head", 3)
        if head == nil then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum == nil then return end
        local gui = Instance.new("BillboardGui")
        gui.Name = "PESP_Gui"
        gui.Adornee = head
        gui.Size = UDim2.new(0, 200, 0, 50)
        gui.StudsOffset = Vector3.new(0, 2.5, 0)
        gui.AlwaysOnTop = true
        gui.Parent = head
        local txt = Instance.new("TextLabel")
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 13
        txt.TextColor3 = Color3.fromRGB(255, 255, 255)
        txt.TextStrokeTransparency = 0
        txt.Text = plr.Name
        txt.Parent = gui
        local hl = Instance.new("Highlight")
        hl.Name = "PESP_HL"
        hl.Adornee = char
        hl.FillColor = Color3.fromRGB(255, 0, 0)
        hl.FillTransparency = 0.75
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = char
        pcall(function()
            txt:SetAttribute("P", plr.UserId)
        end)
    end
    local function RefreshAll()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and getgenv().PlayerESP then
                local c = p.Character
                if c then
                    local has = false
                    pcall(function()
                        local h = c:FindFirstChild("Head")
                        has = h and h:FindFirstChild("PESP_Gui") ~= nil
                    end)
                    if not has then
                        task.spawn(function() MakeESP(p) end)
                    end
                end
            end
        end
    end
    Hub:Bind(Players.PlayerAdded, function(p)
        Hub:Bind(p.CharacterAdded, function()
            task.wait(1)
            if getgenv().PlayerESP and HubAlive() then MakeESP(p) end
        end)
    end)
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            Hub:Bind(p.CharacterAdded, function()
                task.wait(1)
                if getgenv().PlayerESP and HubAlive() then MakeESP(p) end
            end)
        end
    end
    RefreshAll()
    Hub:Bind(RunService.RenderStepped, function()
        if not getgenv().PlayerESP or not HubAlive() then return end
        local myHrp = GetHrp()
        local myPos = nil
        if myHrp then myPos = myHrp.Position end
        for _, p in pairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            local c = p.Character
            if c == nil then continue end
            local head = c:FindFirstChild("Head")
            local hum = c:FindFirstChildOfClass("Humanoid")
            local hrp = c:FindFirstChild("HumanoidRootPart")
            if head == nil or hum == nil or hrp == nil then continue end
            local gui = head:FindFirstChild("PESP_Gui")
            if gui == nil then
                task.spawn(function() MakeESP(p) end)
                continue
            end
            local txt = gui:FindFirstChildOfClass("TextLabel")
            if txt then
                local lvl = GetLevel(p)
                local lvlStr = "?"
                if lvl then lvlStr = lvl end
                local dstr = ""
                if myPos then
                    local d = math.floor((myPos - hrp.Position).Magnitude)
                    dstr = " [" .. tostring(d) .. "m]"
                end
                txt.Text = p.Name .. " [lv." .. lvlStr .. "]" .. dstr
                txt.TextColor3 = Color3.fromRGB(255, 255, 255)
            end
            local hl = c:FindFirstChild("PESP_HL")
            if hl == nil then
                task.spawn(function() MakeESP(p) end)
            end
        end
    end)
    task.spawn(function()
        while HubAlive() do
            task.wait(5)
            if getgenv().PlayerESP then RefreshAll() end
        end
    end)
end

-- ============================== AutoFarm ==============================
if Config.autofarm then
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local TweenService = game:GetService("TweenService")
    local Player = Players.LocalPlayer
    getgenv().AutoFarm = true
    getgenv().FarmDebug = true
    getgenv().FarmRunId = (getgenv().FarmRunId or 0) + 1
    local MyRun = getgenv().FarmRunId
    local function Alive() return getgenv().AutoFarm and MyRun == getgenv().FarmRunId end
    local HoverHeight = 9
    getgenv().AttackInterval = 0.28
    getgenv().TravelSpeed = 140
    CurrentTarget = nil
    local TargetSpawn = nil
    local QuestTravel = false
    local TravelTween = nil
    local HoverTweening = false
    Hub:OnStop(function()
        pcall(function() if TravelTween then TravelTween:Cancel() end end)
    end)
    Hub:Bind(Player.Idled, function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
    pcall(function()
        require(ReplicatedStorage.Util.CameraShaker):Stop()
    end)
    local function GetChar() return Player.Character end
    local function GetHrp()
        local c = GetChar()
        return c and c:FindFirstChild("HumanoidRootPart")
    end
    local function GetHum()
        local c = GetChar()
        return c and c:FindFirstChildOfClass("Humanoid")
    end
    local function GetMyLevel()
        if Player:FindFirstChild("Data") and Player.Data:FindFirstChild("Level") then
            return Player.Data.Level.Value
        end
        local ls = Player:FindFirstChild("leaderstats")
        if ls then
            local l = ls:FindFirstChild("Level") or ls:FindFirstChild("Lvl")
            if l then return l.Value end
        end
        return 1
    end
    local function ParseLvl(s)
        if typeof(s) ~= "string" then return nil end
        local n = string.match(s, "Lv%.?%s*(%d+)") or string.match(s, "%[(%d+)%]") or string.match(s, "Level%s*(%d+)")
        return n and tonumber(n) or nil
    end
    local function GetEnemyLevel(e)
        local o = e:FindFirstChild("Level")
        if o and typeof(o.Value) == "number" and o.Value > 0 then return o.Value end
        for _, n in ipairs({"RequiredLevel", "Lvl", "MobLevel"}) do
            local f = e:FindFirstChild(n)
            if f and typeof(f.Value) == "number" and f.Value > 0 then return f.Value end
        end
        local a = ParseLvl(e.Name)
        if a then return a end
        local h = e:FindFirstChildOfClass("Humanoid")
        if h then
            local b = ParseLvl(h.DisplayName)
            if b then return b end
        end
        return 0
    end
    local function IsAlive(e)
        if not e or not e.Parent then return false end
        local h = e:FindFirstChildOfClass("Humanoid")
        local r = e:FindFirstChild("HumanoidRootPart")
        return h ~= nil and r ~= nil and h.Health > 0
    end
    local function TweenTo(cf, speed)
        speed = speed or getgenv().TravelSpeed or 70
        local my = MyRun
        pcall(function() if TravelTween then TravelTween:Cancel() end TravelTween = nil end)
        local hrp = GetHrp()
        if not hrp then return false end
        if (hrp.Position - cf.Position).Magnitude < 10 then return true end
        local dist = (hrp.Position - cf.Position).Magnitude
        print(("[Quest] tween %dst"):format(math.floor(dist)))
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
            if not Alive() or my ~= getgenv().FarmRunId then
                pcall(function() if TravelTween then TravelTween:Cancel() end end)
                return false
            end
            local cur = GetHrp()
            if not cur then return false end
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
    getgenv().QuestMob = nil
    local STAGES = {
        {Min = 0, Mob = "Trainee", Giver = "Marine Leader", Tries = {{"MarineQuest", 1}, {"MarineQuest1", 1}, {"TraineeQuest", 1}}, GiverPos = Vector3.new(-2656.9, 31.7, 2112.7), GrindPos = Vector3.new(-2723.1, 31.7, 2035.1)},
        {Min = 5, Mob = "Bandit", Giver = "Bandit Quest Giver", Tries = {{"BanditQuest1", 1}}, GiverPos = Vector3.new(1052.0, 14.8, 1552.5), GrindPos = Vector3.new(1062.5, 14.5, 1500.5)},
        {Min = 10, Mob = "Monkey", Giver = "Adventurer", Tries = {{"JungleQuest", 1}}, GiverPos = Vector3.new(-1681.6, 50.1, 174.8), GrindPos = Vector3.new(-1657.0, 18.4, 109.3)},
        {Min = 15, Mob = "Gorilla", Giver = "Adventurer", Tries = {{"JungleQuest", 2}}, GiverPos = Vector3.new(-1681.6, 50.1, 174.8), GrindPos = Vector3.new(-1332.0, 13.9, -517.6)},
        {Min = 30, Mob = "Pirate", Giver = "Pirate Adventurer", Tries = {{"BuggyQuest1", 1}, {"PirateQuest", 1}}, GiverPos = Vector3.new(-1152.2, 17.3, 3861.1), GrindPos = Vector3.new(-1222.5, 17.3, 3953.1)},
        {Min = 40, Mob = "Brute", Giver = "Pirate Adventurer", Tries = {{"BuggyQuest1", 2}, {"PirateQuest", 2}}, GiverPos = Vector3.new(-1152.2, 17.3, 3861.1), GrindPos = Vector3.new(-1355.4, 27.1, 4339.0)},
        {Min = 60, Mob = "Desert Bandit", Giver = "Desert Adventurer", Tries = {{"DesertQuest", 1}}, GiverPos = Vector3.new(919.5, 5.9, 4203.7), GrindPos = Vector3.new(926.6, 5.9, 4503.8)},
        {Min = 75, Mob = "Desert Officer", Giver = "Desert Adventurer", Tries = {{"DesertQuest", 2}}, GiverPos = Vector3.new(919.5, 5.9, 4203.7), GrindPos = Vector3.new(1563.4, 13.7, 4165.4)},
        {Min = 90, Mob = "Snow Bandit", Giver = "Villager", Tries = {{"FrozenQuest", 1}, {"SnowQuest", 1}}, GiverPos = Vector3.new(1400.8, 78.0, -1307.7), GrindPos = Vector3.new(1385.4, 78.0, -1392.4)},
        {Min = 100, Mob = "Snowman", Giver = "Villager", Tries = {{"FrozenQuest", 2}, {"SnowQuest", 2}}, GiverPos = Vector3.new(1400.8, 78.0, -1307.7), GrindPos = Vector3.new(1083.8, 97.4, -1605.6)},
        {Min = 120, Mob = "Chief Petty Officer", Giver = "Marine Quest Giver", Tries = {{"MarineQuest", 1}, {"MarineQuest1", 1}}, GiverPos = Vector3.new(-4695.7, 5.9, 4225.0), GrindPos = Vector3.new(-4758.5, 14.2, 4263.9)},
        {Min = 150, Mob = "Sky Bandit", Giver = "Sky Adventurer", Tries = {{"SkyQuest", 1}, {"SkyQuest1", 1}}, GiverPos = Vector3.new(-5407.1, 410.7, -695.8), GrindPos = Vector3.new(-5162.2, 279.4, -1055.4)},
        {Min = 175, Mob = "Dark Master", Giver = "Sky Adventurer", Tries = {{"SkyQuest", 2}, {"SkyQuest1", 2}}, GiverPos = Vector3.new(-5407.1, 410.7, -695.8), GrindPos = Vector3.new(-5315.7, 501.5, -370.5)},
        {Min = 190, Mob = "Prisoner", Giver = "Jail Keeper", Tries = {{"PrisonQuest", 1}, {"PrisonerQuest", 1}}, GiverPos = Vector3.new(5206.4, 19.6, 732.7), GrindPos = Vector3.new(5194.1, 10.3, 466.2)},
        {Min = 210, Mob = "Dangerous Prisoner", Giver = "Jail Keeper", Tries = {{"PrisonQuest", 2}, {"PrisonerQuest", 2}}, GiverPos = Vector3.new(5206.4, 19.6, 732.7), GrindPos = Vector3.new(5158.5, 10.3, 970.3)},
        {Min = 250, Mob = "Toga Warrior", Giver = "Colosseum Quest Giver", Tries = {{"ColosseumQuest", 1}}, GiverPos = Vector3.new(-1343.8, 12.5, -2925.7), GrindPos = Vector3.new(-1708.4, 12.2, -2714.0)},
        {Min = 275, Mob = "Gladiator", Giver = "Colosseum Quest Giver", Tries = {{"ColosseumQuest", 2}}, GiverPos = Vector3.new(-1343.8, 12.5, -2925.7), GrindPos = Vector3.new(-1276.9, 12.2, -3041.6)},
        {Min = 300, Mob = "Military Soldier", Giver = "The Mayor", Tries = {{"MagmaQuest", 1}}, GiverPos = Vector3.new(-5312.3, 18.5, 8483.7), GrindPos = Vector3.new(-5646.2, 18.5, 8381.3)},
        {Min = 325, Mob = "Military Spy", Giver = "The Mayor", Tries = {{"MagmaQuest", 2}}, GiverPos = Vector3.new(-5312.3, 18.5, 8483.7), GrindPos = Vector3.new(-5923.8, 77.3, 8757.8)},
        {Min = 375, Mob = "Fishman Warrior", Giver = "King Neptune", Tries = {{"UnderwaterQuest", 1}}, GiverPos = Vector3.new(61405.2, 24.9, 1628.8), GrindPos = Vector3.new(60803.8, 24.9, 1354.9)},
        {Min = 400, Mob = "Fishman Commando", Giver = "King Neptune", Tries = {{"UnderwaterQuest", 2}}, GiverPos = Vector3.new(61405.2, 24.9, 1628.8), GrindPos = Vector3.new(61932.2, 24.9, 1337.8)},
        {Min = 450, Mob = "God's Guard", Giver = "Mole", Tries = {{"MoleQuest", 1}}, GiverPos = Vector3.new(-4311.1, 1087.1, -556.9), GrindPos = Vector3.new(-4295.6, 1087.6, -412.8)},
        {Min = 475, Mob = "Shanda", Giver = "Mole", Tries = {{"MoleQuest", 2}}, GiverPos = Vector3.new(-5950.7, 5469.2, 2088.6), GrindPos = Vector3.new(-5945.6, 5469.2, 1841.1)},
        {Min = 525, Mob = "Royal Squad", Giver = "Sky Quest Giver 2", Tries = {{"UpperSkyQuest", 1}}, GiverPos = Vector3.new(-7031.9, 5591.9, 1351.0), GrindPos = Vector3.new(-6816.8, 5549.5, 1190.6)},
        {Min = 550, Mob = "Royal Soldier", Giver = "Sky Quest Giver 2", Tries = {{"UpperSkyQuest", 2}}, GiverPos = Vector3.new(-7031.9, 5591.9, 1351.0), GrindPos = Vector3.new(-7071.4, 5540.6, 930.9)},
        {Min = 625, Mob = "Galley Pirate", Giver = "Freezeburg Quest Giver", Tries = {{"FountainQuest", 1}}, GiverPos = Vector3.new(5245.5, 76.1, 4093.3), GrindPos = Vector3.new(5590.4, 76.1, 4042.8)},
        {Min = 650, Mob = "Galley Captain", Giver = "Freezeburg Quest Giver", Tries = {{"FountainQuest", 2}}, GiverPos = Vector3.new(5245.5, 76.1, 4093.3), GrindPos = Vector3.new(5845.0, 76.1, 4673.4)},
    }
    local function BestStage()
        local lvl = GetMyLevel()
        local best = STAGES[1]
        for _, q in ipairs(STAGES) do
            if lvl >= q.Min and q.Min >= best.Min then best = q end
        end
        return best
    end
    local function GetStageForMob(mobName)
        if not mobName then return nil end
        local want = string.lower(mobName)
        for _, q in ipairs(STAGES) do
            if string.lower(q.Mob) == want then return q end
        end
        return nil
    end
    local function GetGrindPosForMob(mobName)
        local st = GetStageForMob(mobName)
        return st and st.GrindPos or nil
    end
    local function HasFrame()
        local has = false
        pcall(function()
            local tq = Player.PlayerGui:FindFirstChild("TrackedQuestFrame")
            has = tq and tq:FindFirstChild("Frame") ~= nil
        end)
        return has == true
    end
    local function FindPromptNear(pos, radius)
        radius = radius or 35
        local best, bestD = nil, radius
        pcall(function()
            local roots = {}
            if Workspace:FindFirstChild("NPCs") then table.insert(roots, Workspace.NPCs) end
            table.insert(roots, Workspace)
            for _, root in ipairs(roots) do
                for _, m in ipairs(root:GetDescendants()) do
                    if m:IsA("ProximityPrompt") then
                        local model = m:FindFirstAncestorOfClass("Model")
                        local hrp = model and model:FindFirstChild("HumanoidRootPart")
                        local pp = m.Parent
                        local part = (pp and pp:IsA("BasePart")) and pp or hrp
                        if part then
                            local d = (part.Position - pos).Magnitude
                            if d < bestD then best, bestD = m, d end
                        end
                    end
                end
            end
        end)
        return best
    end
    local function TakeQuest(entry)
        getgenv().QuestMob = entry.Mob
        QuestTravel = true
        pcall(function() if TravelTween then TravelTween:Cancel() end end)
        HoverTweening = false
        CurrentTarget = nil
        print(("[Quest] taking %s (lvl %d)"):format(entry.Mob, GetMyLevel()))
        if entry.GiverPos then
            TweenTo(CFrame.new(entry.GiverPos + Vector3.new(0, 8, 0)))
            task.wait(0.5)
            if not HasFrame() and typeof(fireproximityprompt) == "function" then
                local pr = FindPromptNear(entry.GiverPos, 35)
                if pr then
                    pcall(function() fireproximityprompt(pr) end)
                    print("[Quest] prompt fired")
                    task.wait(1)
                end
            end
        else
            print(("[Quest] no GiverPos for %s, using remote only"):format(entry.Mob))
        end
        if HasFrame() then
            print(("[Quest] quest active: %s"):format(entry.Mob))
            QuestTravel = false
            return true
        end
        local comm = nil
        pcall(function()
            local r = ReplicatedStorage:FindFirstChild("Remotes")
            comm = r and r:FindFirstChild("CommF_")
        end)
        if comm then
            for _, t in ipairs(entry.Tries) do
                if not Alive() then break end
                if HasFrame() then break end
                print(("[Quest] trying StartQuest %s #%d"):format(t[1], t[2]))
                pcall(function() comm:InvokeServer("StartQuest", t[1], t[2]) end)
                task.wait(1)
            end
        else
            print("[Quest] CommF_ missing")
        end
        QuestTravel = false
        if HasFrame() then
            print(("[Quest] quest active: %s"):format(entry.Mob))
        else
            print(("[Quest] StartQuest tries exhausted for %s, will grind anyway"):format(entry.Mob))
        end
        return HasFrame()
    end
    task.spawn(function()
        local my = MyRun
        task.wait(3)
        if Alive() and my == getgenv().FarmRunId and not HasFrame() then
            local e = BestStage()
            print(("[Quest] first run, taking %s"):format(e.Mob))
            TakeQuest(e)
        end
        while Alive() and my == getgenv().FarmRunId do
            task.wait(5)
            if QuestTravel then
                task.wait(2)
            else
            local want = BestStage()
            if getgenv().QuestMob ~= want.Mob then
                if not HasFrame() then
                    print(("[Quest] switching %s -> %s"):format(tostring(getgenv().QuestMob), want.Mob))
                    TakeQuest(want)
                else
                    local cur = GetStageForMob(getgenv().QuestMob)
                    if cur and want.Min > cur.Min + 30 and not HasFrame() then
                        print(("[Quest] level jumped, re-taking %s"):format(want.Mob))
                        TakeQuest(want)
                    end
                end
            elseif not HasFrame() then
                print(("[Quest] no frame, re-taking %s"):format(want.Mob))
                TakeQuest(want)
            end
            end
        end
    end)
    task.spawn(function()
        local my = MyRun
        local regAtk, regHit = nil, nil
        pcall(function()
            local net = ReplicatedStorage:WaitForChild("Modules", 5):WaitForChild("Net", 5)
            regAtk = net:FindFirstChild("RE/RegisterAttack")
            regHit = net:FindFirstChild("RE/RegisterHit")
            if regAtk or regHit then
                print("[FastAttack] hardwired: " .. tostring(regAtk and regAtk:GetFullName()) .. " + " .. tostring(regHit and regHit:GetFullName()))
            end
        end)
        while Alive() and my == getgenv().FarmRunId do
            if CurrentTarget and IsAlive(CurrentTarget) then
                local ehrp = CurrentTarget:FindFirstChild("HumanoidRootPart")
                if ehrp then
                    if regAtk then
                        pcall(function() regAtk:FireServer(ehrp) end)
                        pcall(function() regAtk:FireServer({ehrp}) end)
                    end
                    if regHit then
                        pcall(function() regHit:FireServer(ehrp) end)
                        pcall(function() regHit:FireServer({ehrp}) end)
                    end
                end
                task.wait(0.02)
            else
                task.wait(0.5)
            end
        end
    end)
    task.spawn(function()
        local my = MyRun
        local lastDbg = 0
        local swings = 0
        while Alive() and my == getgenv().FarmRunId do
            if CurrentTarget and IsAlive(CurrentTarget) then
                local ehrp = CurrentTarget:FindFirstChild("HumanoidRootPart")
                local hrp = GetHrp()
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
                        local bp = Player:FindFirstChild("Backpack")
                        local tool = c and c:FindFirstChildOfClass("Tool")
                        if hum and bp and tool then
                            hum:UnequipTools()
                            task.wait(0.05)
                            hum:EquipTool(tool)
                        end
                    end)
                end
                if getgenv().FarmDebug and os.clock() - lastDbg > 2 then
                    lastDbg = os.clock()
                    local tool = GetChar() and GetChar():FindFirstChildOfClass("Tool")
                    pcall(function()
                        print(("[Dbg] dist=%.1f tool=%s eHP=%.0f"):format(
                            hrp and ehrp and (hrp.Position - ehrp.Position).Magnitude or -1,
                            tool and tool.Name or "NONE",
                            CurrentTarget:FindFirstChildOfClass("Humanoid").Health
                        ))
                    end)
                end
            else
                swings = 0
            end
            task.wait(getgenv().AttackInterval)
        end
    end)
    task.spawn(function()
        local my = MyRun
        while Alive() and my == getgenv().FarmRunId do
            pcall(function()
                local c = GetChar()
                local bp = Player:FindFirstChild("Backpack")
                if c and bp and not c:FindFirstChildOfClass("Tool") then
                    local hum = c:FindFirstChildOfClass("Humanoid")
                    if hum and hum.Health > 0 then
                        local best, fallback = nil, nil
                        for _, t in ipairs(bp:GetChildren()) do
                            if t:IsA("Tool") then
                                fallback = fallback or t
                                local n = string.lower(t.Name)
                                if string.find(n, "combat") or string.find(n, "melee")
                                or string.find(n, "fight") or string.find(n, "sword")
                                or string.find(n, "blade") or string.find(n, "katana") then
                                    best = t break
                                end
                            end
                        end
                        local pick = best or fallback
                        if pick then hum:EquipTool(pick) end
                    end
                end
            end)
            task.wait(0.5)
        end
    end)
    Hub:Bind(RunService.Stepped, function()
        if not Alive() then return end
        pcall(function()
            local c = GetChar()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end)
    end)
    local function PickTarget()
        local folder = Workspace:FindFirstChild("Enemies")
        if not folder then return nil end
        local hrp = GetHrp()
        local myPos = hrp and hrp.Position or Vector3.new(0, 0, 0)
        if getgenv().QuestMob then
            local qm, qd = nil, 1e9
            local skipJacket = string.lower(getgenv().QuestMob) == "prisoner"
            for _, e in ipairs(folder:GetChildren()) do
                if e:IsA("Model") and IsAlive(e) and string.lower(e.Name) == string.lower(getgenv().QuestMob) then
                    if skipJacket and e:FindFirstChild("Accessory (OrangeJacket)") then
                        continue
                    end
                    local er = e:FindFirstChild("HumanoidRootPart")
                    local d = er and (er.Position - myPos).Magnitude or 1e9
                    if d < qd then qm, qd = e, d end
                end
            end
            if qm then return qm, "quest" end
            return nil
        end
        if HasFrame() then return nil end
        local near, nearD = nil, 1e9
        for _, e in ipairs(folder:GetChildren()) do
            if e:IsA("Model") and IsAlive(e) then
                local er = e:FindFirstChild("HumanoidRootPart")
                local d = er and (er.Position - myPos).Magnitude or 1e9
                if d < nearD then near, nearD = e, d end
            end
        end
        if near then return near, "nearest" end
        return nil
    end
    task.spawn(function()
        local lastNoTarget = 0
        local my = MyRun
        while Alive() and my == getgenv().FarmRunId do
            local ok, err = pcall(function()
                if QuestTravel then return end
                if not CurrentTarget or not IsAlive(CurrentTarget) then
                    local pick, mode = PickTarget()
                    CurrentTarget = pick
                    TargetSpawn = nil
                    pcall(function() if TravelTween then TravelTween:Cancel() end end)
                    HoverTweening = false
                    if CurrentTarget then
                        local er = CurrentTarget:FindFirstChild("HumanoidRootPart")
                        if er then
                            local okCap = pcall(function() TargetSpawn = er.CFrame end)
                            if not okCap or not TargetSpawn then
                                warn("[Farm] spawn capture failed, will retry")
                            end
                            pcall(function()
                                local eh = CurrentTarget:FindFirstChildOfClass("Humanoid")
                                eh.WalkSpeed = 0
                                eh.JumpPower = 0
                                er.CanCollide = false
                                if er.Size.X < 6 then
                                    er.Size = Vector3.new(6, 6, 6)
                                    er.Transparency = 1
                                end
                            end)
                            print(("[Farm] Locked %s [Lv %d] (me %d) mode=%s"):format(CurrentTarget.Name, GetEnemyLevel(CurrentTarget), GetMyLevel(), mode or "?"))
                        else
                            warn("[Farm] picked target has no HRP, repicking")
                            CurrentTarget = nil
                        end
                    else
                        local gp = GetGrindPosForMob(getgenv().QuestMob)
                        if gp then
                            local hrpNow = GetHrp()
                            if hrpNow and (hrpNow.Position - gp).Magnitude > 80 then
                                if getgenv().FarmDebug and os.clock() - lastNoTarget > 3 then
                                    lastNoTarget = os.clock()
                                    print(("[Farm] no %s alive, going to grind pos %s"):format(tostring(getgenv().QuestMob), tostring(gp)))
                                end
                                TweenTo(CFrame.new(gp + Vector3.new(0, 8, 0)))
                            else
                                if getgenv().FarmDebug and os.clock() - lastNoTarget > 3 then
                                    lastNoTarget = os.clock()
                                    print(("[Farm] waiting at grind pos for %s (me=%d)"):format(tostring(getgenv().QuestMob), GetMyLevel()))
                                end
                                task.wait(0.5)
                            end
                        else
                            if getgenv().FarmDebug and os.clock() - lastNoTarget > 3 then
                                lastNoTarget = os.clock()
                                print(("[Farm] idle: no enemies (me=%d)"):format(GetMyLevel()))
                            end
                            task.wait(0.5)
                        end
                    end
                elseif CurrentTarget and IsAlive(CurrentTarget) and not TargetSpawn then
                    pcall(function()
                        local rer = CurrentTarget:FindFirstChild("HumanoidRootPart")
                        if rer then TargetSpawn = rer.CFrame end
                    end)
                end
            end)
            if not ok then warn("[Farm selector] " .. tostring(err)) task.wait(1) end
            task.wait(0.25)
        end
    end)
    Hub:Bind(RunService.Heartbeat, function()
        if not Alive() then return end
        if QuestTravel then return end
        if not CurrentTarget or not IsAlive(CurrentTarget) then return end
        local hrp = GetHrp()
        local hum = GetHum()
        local er = CurrentTarget:FindFirstChild("HumanoidRootPart")
        if not hrp or not hum or not er then return end
        if not TargetSpawn then
            pcall(function() TargetSpawn = er.CFrame end)
            if not TargetSpawn then return end
        end
        if (TargetSpawn.Position - er.Position).Magnitude > 40 then
            TargetSpawn = er.CFrame
        end
        pcall(function()
            local hoverCF = TargetSpawn * CFrame.new(0, HoverHeight, 0)
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
        pcall(function()
            er.CanCollide = false
            er.CFrame = TargetSpawn
            pcall(function()
                er.AssemblyLinearVelocity = Vector3.zero
                er.AssemblyAngularVelocity = Vector3.zero
            end)
        end)
    end)
    print(("[AutoFarm v7-stable run %d] Loaded. Stop: getgenv().AutoFarm = false"):format(MyRun))
    local function PressJ()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendKeyEvent(true, Enum.KeyCode.J, false, game)
            task.wait(0.1)
            vim:SendKeyEvent(false, Enum.KeyCode.J, false, game)
        end)
    end
    task.spawn(function()
        task.wait(2)
        if Alive() and MyRun == getgenv().FarmRunId then
            PressJ()
            print("[AutoFarm] aura key (J) pressed")
        end
    end)
    Hub:Bind(Player.CharacterAdded, function()
        task.spawn(function()
            task.wait(2)
            if Alive() and MyRun == getgenv().FarmRunId then
                PressJ()
                print("[AutoFarm] aura key (J) pressed")
            end
        end)
    end)
end

-- ============================== AutoBounty ==============================
if Config.autobounty then
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
    local function SetStatus(t)
        print("[Hunter] " .. tostring(t))
    end
    getgenv().SkipHuntTarget = function()
        if CurrentTarget then
            pcall(function() Skipped[CurrentTarget.UserId] = true end)
        end
        CurrentTarget = nil
        TargetSpawn = nil
        SkipVersion = SkipVersion + 1
        pcall(function() if TravelTween then TravelTween:Cancel() end end)
        HoverTweening = false
        SetStatus("Skipped")
    end
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
    Hub:OnStop(function()
        pcall(function() if TravelTween then TravelTween:Cancel() end end)
    end)
    Hub:Bind(RunService.Stepped, function()
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
        while getgenv().Hunt and HubAlive() do
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
        while getgenv().Hunt and HubAlive() do
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
        while getgenv().Hunt and HubAlive() do
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
        while getgenv().Hunt and HubAlive() do
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
    Hub:Bind(Players.PlayerRemoving, function(p)
        pcall(function() Skipped[p.UserId] = nil end)
        if CurrentTarget == p then
            CurrentTarget = nil
            TargetSpawn = nil
            SkipVersion = SkipVersion + 1
        end
    end)
    Hub:Bind(RunService.Heartbeat, function()
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
end

print("[BloxFruitsHub] Loaded. APIs: getgenv().readPlayerStats(name), getgenv().GoToIsland(name), getgenv().SkipHuntTarget()")
