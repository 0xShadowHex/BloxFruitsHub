local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local ESP_ENABLED = true
local MAX_DISTANCE = math.huge
local function getChestInfo(objName)
    local lower = string.lower(objName)
    if string.find(lower, "chest3") or string.find(lower, "gold") then
        return "Golden Chest", Color3.fromRGB(255, 215, 0)
    elseif string.find(lower, "chest2") or string.find(lower, "diamond") or string.find(lower, "royal") then
        return "Diamond Chest", Color3.fromRGB(0, 255, 255)
    elseif string.find(lower, "chest1") or string.find(lower, "iron") then
        return "Iron Chest", Color3.fromRGB(255, 255, 255)
    elseif string.find(lower, "chest") then
        return objName, Color3.fromRGB(0, 255, 0)
    end
    return nil, nil
end
local function isChest(obj)
    if not obj:IsA("BasePart") then return false end
    local label, _ = getChestInfo(obj.Name)
    return label ~= nil
end
local function clearESP(obj)
    for _, child in pairs(obj:GetChildren()) do
        if child.Name == "ChestESP_Gui" or child.Name == "ChestESP_Box" then
            child:Destroy()
        end
    end
end
local function createESP(chest)
    clearESP(chest)
    local labelText, color = getChestInfo(chest.Name)
    if not labelText then return end
    local gui = Instance.new("BillboardGui")
    gui.Name = "ChestESP_Gui"
    gui.Adornee = chest
    gui.Size = UDim2.new(0, 200, 0, 50)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Text = labelText
    gui.Parent = chest
    local box = Instance.new("BoxHandleAdornee")
    box.Name = "ChestESP_Box"
    box.Adornee = chest
    box.Size = chest.Size + Vector3.new(0.5, 0.5, 0.5)
    box.Color3 = color
    box.Transparency = 0.4
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Parent = chest
end
local function scanAllChests()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if isChest(obj) then
            if ESP_ENABLED and not obj:FindFirstChild("ChestESP_Gui") then
                createESP(obj)
            elseif not ESP_ENABLED then
                clearESP(obj)
            end
        end
    end
end
Workspace.DescendantAdded:Connect(function(obj)
    task.wait(0.5)
    if ESP_ENABLED and isChest(obj) then
        createESP(obj)
    end
end)
scanAllChests()
task.spawn(function()
    while true do
        task.wait(5)
        scanAllChests()
    end
end)
RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    for _, obj in pairs(Workspace:GetDescendants()) do
        if isChest(obj) then
            local gui = obj:FindFirstChild("ChestESP_Gui")
            if gui then
                local dist = math.floor((hrp.Position - obj.Position).Magnitude)
                local labelText, _ = getChestInfo(obj.Name)
                local textLabel = gui:FindFirstChildOfClass("TextLabel")
                if textLabel then
                    if dist <= MAX_DISTANCE then
                        gui.Enabled = true
                        textLabel.Text = string.format("%s\n[%dm]", labelText, dist)
                    else
                        gui.Enabled = false
                    end
                end
                local box = obj:FindFirstChild("ChestESP_Box")
                if box then
                    box.Visible = (dist <= MAX_DISTANCE)
                end
            end
        end
    end
end)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ChestESP_ToggleGui"
screenGui.ResetOnSpawn = false
pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
if not screenGui.Parent then
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 140, 0, 40)
toggleBtn.Position = UDim2.new(0, 20, 0, 120)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Text = "Chest ESP: ON"
toggleBtn.Parent = screenGui
local corner = Instance.new("UICorner", toggleBtn)
corner.CornerRadius = UDim.new(0, 6)
local function setESP(state)
    ESP_ENABLED = state
    if ESP_ENABLED then
        toggleBtn.Text = "Chest ESP: ON"
        toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 0)
        scanAllChests()
    else
        toggleBtn.Text = "Chest ESP: OFF"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
        for _, obj in pairs(Workspace:GetDescendants()) do
            if isChest(obj) then
                clearESP(obj)
            end
        end
    end
end
toggleBtn.MouseButton1Click:Connect(function()
    setESP(not ESP_ENABLED)
end)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setESP(not ESP_ENABLED)
    end
end)
print("Blox Fruits Chest ESP Loaded - Found chests will show with distance")
