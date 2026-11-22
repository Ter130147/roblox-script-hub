local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false

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
            task.wait(0.2)
        end
    end)

    print("[Net a Fish] โหลดโหมดปลอดภัย (ปิดการกดและยิง Remote อัตโนมัติทั้งหมด)")
end

return GameModule