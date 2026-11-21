--!strict
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local UI = {}

function UI.init(Config, hubTitle: string?)
    local titleText = hubTitle or "TER HUB"
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("CustomScriptHubUI")
    if existing then
        existing:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomScriptHubUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainWindow"
    mainFrame.Size = UDim2.fromOffset(520, 320)
    mainFrame.Position = UDim2.fromScale(0.5, 0.5)
    mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    local headerLabel = Instance.new("TextLabel")
    headerLabel.Size = UDim2.new(1, -24, 0, 36)
    headerLabel.Position = UDim2.fromOffset(14, 8)
    headerLabel.BackgroundTransparency = 1
    headerLabel.Text = titleText .. "  •  Net a Fish"
    headerLabel.TextColor3 = Color3.fromRGB(245, 245, 250)
    headerLabel.TextXAlignment = Enum.TextXAlignment.Left
    headerLabel.Font = Enum.Font.GothamBold
    headerLabel.TextSize = 15
    headerLabel.Parent = mainFrame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, -28, 0, 44)
    toggleBtn.Position = UDim2.fromOffset(14, 58)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.GothamMedium
    toggleBtn.TextSize = 14
    toggleBtn.Text = "Auto Farm : " .. (Config.AutoFarm and "ON" or "OFF")
    toggleBtn.Parent = mainFrame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleBtn

    toggleBtn.MouseButton1Click:Connect(function()
        Config.AutoFarm = not Config.AutoFarm
        toggleBtn.Text = "Auto Farm : " .. (Config.AutoFarm and "ON" or "OFF")
        toggleBtn.BackgroundColor3 = if Config.AutoFarm
            then Color3.fromRGB(124, 77, 255)
            else Color3.fromRGB(34, 34, 42)
    end)

    print("[UI] โหลดหน้าต่างเรียบร้อย")
end

return UI
