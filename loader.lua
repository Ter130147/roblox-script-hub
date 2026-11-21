local BASE_URL = "https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/"
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local SupportedGames = {
    [93898234979111] = "games/net_a_fish.lua",
}

local function fetchRemote(relativePath)
    local ok, result = pcall(function()
        return game:HttpGet(BASE_URL .. relativePath .. "?t=" .. tostring(os.clock()))
    end)
    if not ok or type(result) ~= "string" then
        warn("[Hub] Failed to fetch:", relativePath, result)
        return nil
    end
    if string.sub(result, 1, 3) == "\239\187\191" then
        result = string.sub(result, 4)
    end
    return result
end

local function loadLuaSource(src, label)
    local fn, compileErr = loadstring(src)
    if not fn then
        warn("[Hub] Compile Error in " .. label .. ":", compileErr)
        return nil
    end
    local ok, modOrErr = pcall(fn)
    if not ok then
        warn("[Hub] Runtime Error in " .. label .. ":", modOrErr)
        return nil
    end
    return modOrErr
end

local function runGameScanner()
    print("=== 1. REMOTES IN REPLICATEDSTORAGE ===")
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") then
            print(obj.ClassName, "|", obj:GetFullName())
        end
    end

    print("=== 2. TOOLS (BACKPACK & CHARACTER) ===")
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                print("Backpack Tool:", t.Name)
            end
        end
    end
    if LocalPlayer.Character then
        for _, t in ipairs(LocalPlayer.Character:GetChildren()) do
            if t:IsA("Tool") then
                print("Equipped Tool:", t.Name)
            end
        end
    end

    print("=== 3. WORKSPACE FOLDERS / MODELS ===")
    for _, obj in ipairs(workspace:GetChildren()) do
        if obj:IsA("Folder") or obj:IsA("Model") then
            print("Workspace:", obj.ClassName, "|", obj.Name)
        end
    end
    print("=== SCAN COMPLETE ===")
end

local function mountUI(Config, hubTitle)
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
    headerLabel.Text = titleText .. " - Net a Fish"
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
        if Config.AutoFarm then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(124, 77, 255)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
        end
    end)

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.new(1, -28, 0, 44)
    scanBtn.Position = UDim2.fromOffset(14, 114)
    scanBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 56)
    scanBtn.TextColor3 = Color3.fromRGB(230, 230, 240)
    scanBtn.Font = Enum.Font.GothamMedium
    scanBtn.TextSize = 14
    scanBtn.Text = "Scan Game Remotes & Tools (Check Console)"
    scanBtn.Parent = mainFrame

    local scanCorner = Instance.new("UICorner")
    scanCorner.CornerRadius = UDim.new(0, 8)
    scanCorner.Parent = scanBtn

    scanBtn.MouseButton1Click:Connect(function()
        scanBtn.Text = "Scanning... Check Console!"
        runGameScanner()
        task.delay(1.5, function()
            if scanBtn and scanBtn.Parent then
                scanBtn.Text = "Scan Game Remotes & Tools (Check Console)"
            end
        end)
    end)

    print("[UI] Mounted with Scanner")
end

local function bootstrap()
    local placeId = game.PlaceId
    local gameScriptPath = SupportedGames[placeId]

    if not gameScriptPath then
        warn("[Hub] Unsupported PlaceId:", placeId)
        return
    end

    local configSrc = fetchRemote("config.lua")
    local utilsSrc = fetchRemote("core/utils.lua")
    local gameSrc = fetchRemote(gameScriptPath)

    if not (configSrc and utilsSrc and gameSrc) then
        return
    end

    local Config = loadLuaSource(configSrc, "config.lua")
    local Utils = loadLuaSource(utilsSrc, "core/utils.lua")
    local GameModule = loadLuaSource(gameSrc, gameScriptPath)

    if not (Config and Utils and GameModule) then
        return
    end

    mountUI(Config, "TER HUB")

    if type(GameModule) == "table" and type(GameModule.init) == "function" then
        GameModule.init(Config, Utils)
    else
        warn("[Hub] Missing init in:", gameScriptPath)
    end
end

bootstrap()