local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false

local sequenceQueue = {}
local lastHighlightedKey = nil
local lastActionTime = 0

local function scanGameStructure()
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local function getMiniGameGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return nil
    end
    local mg = pg:FindFirstChild("MiniGameUI")
    if mg and mg:IsA("ScreenGui") and mg.Enabled then
        return mg
    end
    return nil
end

local function fireGuiBtn(btn)
    if not btn or not btn.Visible or not btn.Active then
        return
    end
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

local function findReelMiniGame(mg)
    local reelBtn = nil
    local greenZone = nil
    local needle = nil

    for _, obj in ipairs(mg:GetDescendants()) do
        if obj:IsA("GuiObject") and obj.Visible then
            if obj:IsA("TextButton") and string.find(string.upper(obj.Text), "REEL", 1, true) then
                reelBtn = obj
            elseif obj:IsA("ImageButton") and string.find(string.lower(obj.Name), "reel", 1, true) then
                reelBtn = obj
            end

            local nLower = string.lower(obj.Name)
            if string.find(nLower, "needle", 1, true) or string.find(nLower, "pointer", 1, true) or string.find(nLower, "marker", 1, true) then
                if obj.AbsoluteSize.X <= 24 and obj.AbsoluteSize.Y >= 16 then
                    needle = obj
                end
            end

            if obj:IsA("Frame") or obj:IsA("ImageLabel") then
                local c = obj.BackgroundColor3
                if (c.G > 0.55 and c.R < 0.45) or string.find(nLower, "green", 1, true) or string.find(nLower, "zone", 1, true) or string.find(nLower, "target", 1, true) then
                    if obj.AbsoluteSize.X > 12 and obj.AbsoluteSize.X < 400 then
                        greenZone = obj
                    end
                end
            end
        end
    end

    return reelBtn, needle, greenZone
end

local function tryPlayReelGame(mg, Config)
    local reelBtn, needle, greenZone = findReelMiniGame(mg)
    if not reelBtn then
        return false
    end

    local spd = tonumber(Config and Config.MiniGameSpeed) or 0.15
    if tick() - lastActionTime < math.clamp(spd, 0.08, 1.0) then
        return true
    end

    if needle and greenZone then
        local nCenter = needle.AbsolutePosition.X + (needle.AbsoluteSize.X * 0.5)
        local zMin = greenZone.AbsolutePosition.X - 4
        local zMax = greenZone.AbsolutePosition.X + greenZone.AbsoluteSize.X + 4
        if nCenter >= zMin and nCenter <= zMax then
            lastActionTime = tick()
            fireGuiBtn(reelBtn)
        end
    elseif not needle then
        lastActionTime = tick()
        fireGuiBtn(reelBtn)
    end

    return true
end

local function tryPlayMemoryBaitGame(mg, Config)
    local yourTurn = false
    local choices = {}
    local orderNames = { "worm", "shrimp", "cricket", "minnow" }

    for _, obj in ipairs(mg:GetDescendants()) do
        if obj:IsA("GuiObject") and obj.Visible then
            local txt = ""
            if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                txt = obj.Text
            end
            if string.find(txt, "ถึงตาคุณ", 1, true) then
                yourTurn = true
            end
            local lowerTxt = string.lower(txt)
            for idx, keyWord in ipairs(orderNames) do
                if lowerTxt == keyWord then
                    local btn = obj:IsA("GuiButton") and obj or obj:FindFirstChildWhichIsA("GuiButton", true)
                    if not btn and obj.Parent then
                        btn = obj.Parent:IsA("GuiButton") and obj.Parent or obj.Parent:FindFirstChildWhichIsA("GuiButton", true)
                    end
                    if btn and btn.Visible and btn.Active then
                        choices[idx] = { index = idx, name = keyWord, button = btn }
                    end
                end
            end
        end
    end

    local litIdx = nil
    for idx = 1, 4 do
        local item = choices[idx]
        local btn = item and item.button
        if btn and btn.Visible then
            local bg = btn.BackgroundColor3
            if ((bg.R + bg.G + bg.B) / 3) > 0.85 or btn.BackgroundTransparency < 0.05 then
                litIdx = idx
                break
            end
            for _, st in ipairs(btn:GetDescendants()) do
                if st:IsA("UIStroke") and st.Enabled and st.Thickness >= 3 then
                    litIdx = idx
                    break
                end
            end
            if litIdx then
                break
            end
        end
    end

    if not yourTurn then
        if litIdx and litIdx ~= lastHighlightedKey then
            lastHighlightedKey = litIdx
            table.insert(sequenceQueue, litIdx)
        elseif not litIdx then
            lastHighlightedKey = nil
        end
        return
    end

    local spd = tonumber(Config and Config.MiniGameSpeed) or 0.20
    if tick() - lastActionTime < math.clamp(spd, 0.15, 1.50) then
        return
    end

    if #sequenceQueue > 0 then
        local nextIdx = table.remove(sequenceQueue, 1)
        local targetItem = choices[nextIdx]
        if targetItem and targetItem.button then
            lastActionTime = tick()
            fireGuiBtn(targetItem.button)
        end
    end
end

local function stepMiniGame(Config)
    local mg = getMiniGameGui()
    if not mg then
        sequenceQueue = {}
        lastHighlightedKey = nil
        return
    end

    local handledReel = tryPlayReelGame(mg, Config)
    if not handledReel then
        tryPlayMemoryBaitGame(mg, Config)
    end
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
                pcall(stepMiniGame, Config)
                task.wait(0.03)
            else
                sequenceQueue = {}
                lastHighlightedKey = nil
                task.wait(0.25)
            end
        end
    end)

    print("[Net a Fish] โหลดโหมด MiniGameUI รองรับ REEL! และช่วยความจำเหยื่อเรียบร้อย")
end

return GameModule