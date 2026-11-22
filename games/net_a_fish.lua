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
        CatchReady = r:FindFirstChild("CatchReady"),
        ResolveCatch = r:FindFirstChild("ResolveCatch"),
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

local function triggerUiMiniGameButtons()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return
    end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name ~= "TerHubProUI" and gui:IsA("ScreenGui") and gui.Enabled then
            local lowerGui = string.lower(gui.Name)
            local isGameGui = string.find(lowerGui, "mini")
                or string.find(lowerGui, "game")
                or string.find(lowerGui, "tap")
                or string.find(lowerGui, "catch")
                or string.find(lowerGui, "reel")
                or string.find(lowerGui, "event")

            for _, btn in ipairs(gui:GetDescendants()) do
                if (btn:IsA("TextButton") or btn:IsA("ImageButton")) and btn.Visible and btn.Active then
                    local n = string.lower(btn.Name)
                    local t = btn:IsA("TextButton") and string.lower(btn.Text) or ""
                    local matchBtn = isGameGui
                        or string.find(n, "tap")
                        or string.find(n, "hit")
                        or string.find(n, "click")
                        or string.find(n, "catch")
                        or string.find(n, "reel")
                        or string.find(n, "claim")
                        or string.find(t, "tap")
                        or string.find(t, "catch")
                        or string.find(t, "reel")
                    if matchBtn then
                        pcall(function()
                            if getconnections then
                                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                                    conn:Fire()
                                end
                                for _, conn in ipairs(getconnections(btn.Activated)) do
                                    conn:Fire()
                                end
                            end
                        end)
                    end
                end
            end
        end
    end
end

local function runMiniGameStep()
    local rem = getRemotes()
    if rem then
        safeFire(rem.MiniGamePing, true)
        safeFire(rem.MiniGamePing, "Complete")
        safeInvoke(rem.MiniGame, "Complete", true)
        safeInvoke(rem.MiniGame, "Hit", true)
        safeFire(rem.PerfectTap, true)
        safeFire(rem.CatchReady)
        safeFire(rem.ResolveCatch, true)
    end
    triggerUiMiniGameButtons()
end

function GameModule.init(Config, Utils)
    if started then
        return
    end
    started = true

    task.spawn(function()
        while started do
            if Config and Config.AutoMiniGame then
                runMiniGameStep()
                local spd = tonumber(Config.MiniGameSpeed) or 0.05
                task.wait(math.clamp(spd, 0.02, 1.0))
            else
                task.wait(0.15)
            end
        end
    end)

    print("[Net a Fish] โหลดโมดูลเฉพาะ Auto MiniGame เรียบร้อย")
end

return GameModule