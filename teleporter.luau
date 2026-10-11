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
local buttons = {}
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
    for name, btn in pairs(buttons) do
        btn.Text = name .. " [OFF]"
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end
    activeName = nil
end
RunService.Stepped:Connect(function()
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
local function GoTo(entry, btn)
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
    btn.Text = entry.Name .. " [ON]"
    btn.BackgroundColor3 = Color3.fromRGB(30, 140, 60)
    tw.Completed:Connect(function()
        if activeName == entry.Name then
            StopTween(false)
        end
    end)
    tw:Play()
end
local gui = Instance.new("ScreenGui")
gui.Name = "IslandTP"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = Player.PlayerGui end)
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 340)
frame.Position = UDim2.new(1, -230, 0.5, -170)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Island Givers"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -40)
scroll.Position = UDim2.new(0, 5, 0, 35)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, #ISLANDS * 34)
scroll.Parent = frame
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.Parent = scroll
for _, entry in ipairs(ISLANDS) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -4, 0, 30)
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    b.Text = entry.Name .. " [OFF]"
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.Font = Enum.Font.SourceSans
    b.TextSize = 15
    b.Parent = scroll
    buttons[entry.Name] = b
    b.MouseButton1Click:Connect(function()
        if activeName == entry.Name then
            StopTween(true)
        else
            GoTo(entry, b)
        end
    end)
end
print("[IslandTP] Loaded")
