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
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if getgenv().PlayerESP then MakeESP(p) end
    end)
end)
for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function()
            task.wait(1)
            if getgenv().PlayerESP then MakeESP(p) end
        end)
    end
end
RefreshAll()
RunService.RenderStepped:Connect(function()
    if not getgenv().PlayerESP then return end
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
    while true do
        task.wait(5)
        if getgenv().PlayerESP then RefreshAll() end
    end
end)
