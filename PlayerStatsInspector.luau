local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("BF_PlayerViewer")
    if old then old:Destroy() end
end)
local gui = Instance.new("ScreenGui")
gui.Name = "BF_PlayerViewer"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer.PlayerGui
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 440, 0, 300)
main.Position = UDim2.new(0.5, -220, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 32)
header.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
header.BorderSizePixel = 0
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.Text = "Players"
header.Parent = main
local left = Instance.new("ScrollingFrame")
left.Position = UDim2.new(0, 8, 0, 40)
left.Size = UDim2.new(0, 140, 1, -48)
left.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
left.BorderSizePixel = 0
left.ScrollBarThickness = 4
left.AutomaticCanvasSize = Enum.AutomaticSize.Y
left.CanvasSize = UDim2.new(0, 0, 0, 0)
left.Parent = main
local leftList = Instance.new("UIListLayout")
leftList.Padding = UDim.new(0, 4)
leftList.Parent = left
local right = Instance.new("Frame")
right.Position = UDim2.new(0, 156, 0, 40)
right.Size = UDim2.new(0, 276, 1, -48)
right.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
right.BorderSizePixel = 0
right.Parent = main
local rightList = Instance.new("UIListLayout")
rightList.Padding = UDim.new(0, 4)
rightList.Parent = right
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -8, 0, 26)
nameLabel.Position = UDim2.new(0, 4, 0, 4)
nameLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
nameLabel.BorderSizePixel = 0
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 13
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Text = "Select a player"
nameLabel.Parent = right
local fields = {"Beli", "Exp", "Fragments", "Level", "Points", "Bounty/Honor"}
local valueLabels = {}
for i = 1, 6 do
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -8, 0, 24)
    l.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    l.BorderSizePixel = 0
    l.Font = Enum.Font.Gotham
    l.TextSize = 12
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(220, 220, 220)
    l.Text = fields[i] .. ": "
    l.Parent = right
    valueLabels[i] = l
end
local selected = nil
local function getText(plr, field)
    local v = nil
    pcall(function()
        local d = plr:FindFirstChild("Data")
        if d then
            local o = d:FindFirstChild(field)
            if o then v = o.Value end
        end
        if v == nil then
            local s = plr:FindFirstChild("leaderstats")
            if s then
                local o2 = s:FindFirstChild(field)
                if o2 then v = o2.Value end
            end
        end
    end)
    if v == nil then return "N/A" end
    return tostring(v)
end
local function updateDetails()
    if selected == nil or selected.Parent == nil then
        return
    end
    pcall(function()
        nameLabel.Text = selected.DisplayName .. " (@" .. selected.Name .. ")"
    end)
    for i = 1, 6 do
        local f = fields[i]
        local t = getText(selected, f)
        valueLabels[i].Text = " " .. f .. ": " .. t
    end
end
local function refreshList()
    for _, c in pairs(left:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local all = Players:GetPlayers()
    for idx = 1, #all do
        local p = all[idx]
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -8, 0, 26)
        b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        b.BorderSizePixel = 0
        b.Font = Enum.Font.Gotham
        b.TextSize = 12
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextTruncate = Enum.TextTruncate.AtEnd
        b.Text = p.Name
        b.Parent = left
        local target = p
        b.MouseButton1Click:Connect(function()
            selected = target
            updateDetails()
        end)
    end
end
Players.PlayerAdded:Connect(function()
    refreshList()
end)
Players.PlayerRemoving:Connect(function(p)
    if selected == p then
        selected = nil
        nameLabel.Text = "Select a player"
        for i = 1, 6 do
            valueLabels[i].Text = fields[i] .. ": "
        end
    end
    refreshList()
end)
refreshList()
task.spawn(function()
    while gui.Parent do
        pcall(updateDetails)
        task.wait(0.5)
    end
end)
