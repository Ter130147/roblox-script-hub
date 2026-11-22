local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false

local function getRemotes()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if not r then
        return nil
    end
    return {
        MiniGame = r:FindFirstChild("MiniGame"),
        MiniGamePing = r:FindFirstChild("MiniGamePing"),
        PerfectTap = r:FindFirstChild("PerfectTap"),
    }
end

local function safeFire(rem, ...)
    if rem and rem:IsA("RemoteEvent") then
        local args = { ... }
        pcall(function()
            rem:FireServer(unpack(args))
        end)
    end
end

local function safeInvoke(rem, ...)
    if rem and rem:IsA("RemoteFunction") then
        local args = { ... }
        pcall(function()
            rem:InvokeServer(unpack(args))
        end)
    end
end

local function hasActiveMiniGameGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return false
    end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name ~= "TerHubProUI" and gui:IsA("ScreenGui") and gui.Enabled then
            local n = string.lower(gui.Name)
            if string.find(n, "minigame") or string.find(n, "mini_game") or string.find(n, "skillcheck") then
                return true
            end
        end
    end
    return false
end

local function runMiniGameStep(rem)
    if not rem then
        return
    end
    safeFire(rem.MiniGamePing, "Complete")
    safeInvoke(rem.MiniGame, "Complete")
    safeFire(rem.PerfectTap, true)
end

local function scanGameStructure()
    print("=== 1. REMOTES IN REPLICATEDSTORAGE ===")
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if r then
        for _, obj in ipairs(r:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                print(obj.ClassName, "|", obj:GetFullName())
            end
        end
    end

    print("=== 2. ACTIVE PLAYER GUIS ===")
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _, gui in ipairs(pg:GetChildren()) do
            if gui:IsA("ScreenGui") then
                print("ScreenGui:", gui.Name, "| Enabled:", tostring(gui.Enabled))
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

function GameModule.init(Config, Utils)
    if started then
        return
    end
    started = true

    task.spawn(function()
        while started do
            if Config and Config.ScanNow then
                Config.ScanNow = false
                scanGameStructure()
            end

            if Config and Config.AutoMiniGame then
                local rem = getRemotes()
                if rem and (hasActiveMiniGameGui() or rem.MiniGamePing or rem.MiniGame) then
                    runMiniGameStep(rem)
                end
                local spd = tonumber(Config.MiniGameSpeed) or 0.15
                task.wait(math.clamp(spd, 0.10, 1.50))
            else
                task.wait(0.2)
            end
        end
    end)

    print("[Net a Fish] โหลดโมดูลพร้อมปุ่มสแกนเรียบร้อย")
end

return GameModule