local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Data = LocalPlayer:WaitForChild("Data")
local Stats = LocalPlayer:WaitForChild("leaderstats")
pcall(function()
    local old = LocalPlayer.PlayerGui:FindFirstChild("BF_DataEditor")
    if old then old:Destroy() end
end)
local gui = Instance.new("ScreenGui")
gui.Name = "BF_DataEditor"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer.PlayerGui
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 300, 0, 300)
main.Position = UDim2.new(0.5, -150, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = gui
local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
header.BorderSizePixel = 0
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.Text = "Data Editor"
header.Parent = main
local list = Instance.new("UIListLayout", main)
list.Padding = UDim.new(0, 6)
local function row(title, obj)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -16, 0, 32)
    f.Position = UDim2.new(0, 8, 0, 0)
    f.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    f.BorderSizePixel = 0
    f.Parent = main
    local t = Instance.new("TextLabel")
    t.Size = UDim2.new(0.45, 0, 1, 0)
    t.Position = UDim2.new(0, 8, 0, 0)
    t.BackgroundTransparency = 1
    t.Font = Enum.Font.Gotham
    t.TextSize = 13
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.TextColor3 = Color3.fromRGB(220, 220, 220)
    t.Text = title
    t.Parent = f
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.5, -8, 0, 24)
    box.Position = UDim2.new(0.5, 0, 0.5, -12)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    box.BorderSizePixel = 0
    box.Font = Enum.Font.Gotham
    box.TextSize = 13
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.PlaceholderColor3 = Color3.fromRGB(140, 140, 140)
    box.Text = ""
    box.PlaceholderText = tostring(obj.Value)
    box.Parent = f
    obj:GetPropertyChangedSignal("Value"):Connect(function()
        if box:IsFocused() == false then
            box.PlaceholderText = tostring(obj.Value)
        end
    end)
    box.FocusLost:Connect(function(enter)
        if enter then
            local n = tonumber(box.Text)
            if n then
                pcall(function()
                    obj.Value = math.floor(n)
                end)
                box.Text = ""
                box.PlaceholderText = tostring(obj.Value)
            else
                box.Text = ""
            end
        end
    end)
end
task.spawn(function()
    local bounty = Stats:WaitForChild("Bounty/Honor", 10)
    row("Beli", Data:WaitForChild("Beli"))
    row("Exp", Data:WaitForChild("Exp"))
    row("Fragments", Data:WaitForChild("Fragments"))
    row("Level", Data:WaitForChild("Level"))
    row("Points", Data:WaitForChild("Points"))
    if bounty then
        row("Bounty/Honor", bounty)
    end
end)
