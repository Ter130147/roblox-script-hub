local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false

local sequenceQueue = {}
local lastHighlightedKey = nil
local lastActionTime = 0
local lastAcceptTime = 0

local Cat1Module = nil
pcall(function()
    local src = game:HttpGet("https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/games/net_a_fish/cat1_fishing_collect.lua?cb=" .. tostring(os.clock()) .. "_" .. tostring(math.random(10000,99999)), true)
    local fn = loadstring(src)
    if fn then
        Cat1Module = fn()
    end
end)

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

local function containsDangerText(container)
    if not container then
        return true
    end
    for _, d in ipairs(container:GetDescendants()) do
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            local t = string.lower(d.Text or "")
            if string.find(t, "robux", 1, true)
                or string.find(t, "r$", 1, true)
                or string.find(t, "ซื้อ", 1, true)
                or string.find(t, "buy", 1, true)
                or string.find(t, "skip", 1, true)
                or string.find(t, "ข้าม", 1, true)
                or string.find(t, "เติม", 1, true)
            then
                return true
            end
        end
    end
    return false
end

local function clickInsideMiniGame(guiObj)
    if not guiObj or not guiObj.Visible then
        return false
    end

    pcall(function()
        if getconnections then
            local btn = guiObj:IsA("GuiButton") and guiObj or guiObj:FindFirstChildWhichIsA("GuiButton", true)
            if btn and btn.Active then
                for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                    conn:Fire()
                end
                for _, conn in ipairs(getconnections(btn.Activated)) do
                    conn:Fire()
                end
            end
        end
    end)

    pcall(function()
        local pos = guiObj.AbsolutePosition
        local sz = guiObj.AbsoluteSize
        if pos and sz and sz.X > 4 and sz.Y > 4 then
            local cx = pos.X + (sz.X * 0.5)
            local cy = pos.Y + (sz.Y * 0.5) + 36
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end
    end)

    return true
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

local function tryClickPlayInMiniGame(mg)
    if tick() - lastAcceptTime < 1.0 then
        return false
    end

    for _, obj in ipairs(mg:GetDescendants()) do
        if obj:IsA("GuiObject") and obj.Visible then
            local txt = ""
            if obj:IsA("TextButton") or obj:IsA("TextLabel") then
                txt = obj.Text or ""
            end
            local low = string.lower(txt)
            if string.find(low, "play", 1, true)
                or string.find(txt, "เล่น", 1, true)
                or string.find(txt, "เข้าร่วม", 1, true)
                or string.find(txt, "ยอมรับ", 1, true)
            then
                local target = obj:IsA("GuiButton") and obj or (obj.Parent and obj.Parent:IsA("GuiButton") and obj.Parent or obj.Parent)
                if target and not containsDangerText(target.Parent) then
                    lastAcceptTime = tick()
                    clickInsideMiniGame(target)
                    return true
                end
            end
        end
    end
    return false
end

local function findReelMiniGame(mg)
    local reelBtn = nil
    local greenZone = nil
    local needle = nil

    for _, obj in ipairs(mg:GetDescendants()) do
        if obj:IsA("GuiObject") and obj.Visible then
            if (obj:IsA("TextButton") or obj:IsA("TextLabel")) and string.find(string.upper(obj.Text or ""), "REEL", 1, true) then
                reelBtn = obj:IsA("GuiButton") and obj or (obj.Parent and obj.Parent:IsA("GuiButton") and obj.Parent or obj)
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
            clickInsideMiniGame(reelBtn)
        end
    elseif not needle then
        lastActionTime = tick()
        clickInsideMiniGame(reelBtn)
    end

    return true
end

local function tryPlayFishChaosGame(mg, Config)
local isChaos = false
for _, obj in ipairs(mg:GetDescendants()) do
if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
local t = obj.Text or ""
if string.find(t, "ความโกลาหลของปลา", 1, true)
or string.find(t, "GOLDEN +30", 1, true)
or string.find(t, "BOOT -15", 1, true)
then
isChaos = true
break
end
end
end

if not isChaos then
return false
end

local spd = tonumber(Config and Config.MiniGameSpeed) or 0.16
if tick() - lastActionTime < math.clamp(spd, 0.10, 1.0) then
return true
end

local laneKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }
local laneCenters = {}
local laneButtons = {}

for _, obj in ipairs(mg:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local txt = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and (obj.Text or "") or ""
local trimmed = txt:match("^%s*(.-)%s*$")
local laneIdx = tonumber(trimmed)
if laneIdx and laneIdx >= 1 and laneIdx <= 5 then
local centerX = obj.AbsolutePosition.X + (obj.AbsoluteSize.X * 0.5)
laneCenters[laneIdx] = centerX
local btn = obj:IsA("GuiButton") and obj or (obj.Parent and obj.Parent:IsA("GuiButton") and obj.Parent or nil)
if btn and btn.Active then
    laneButtons[laneIdx] = btn
end
end
end
end

local bestLane = nil
local bestTarget = nil
local bestScore = -999

for _, obj in ipairs(mg:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local nLower = string.lower(obj.Name)
local isShoe = string.find(nLower, "boot", 1, true)
or string.find(nLower, "shoe", 1, true)
or string.find(nLower, "รองเท้า", 1, true)
local isLaneOrBg = string.find(nLower, "lane", 1, true)
or string.find(nLower, "bg", 1, true)
or string.find(nLower, "pond", 1, true)
or string.find(nLower, "slot", 1, true)
local isFishLike = string.find(nLower, "fish", 1, true)
or string.find(nLower, "gold", 1, true)
or string.find(nLower, "prey", 1, true)
or string.find(nLower, "target", 1, true)

if not isShoe and not isLaneOrBg and (obj:IsA("ImageButton") or obj:IsA("ImageLabel") or isFishLike) then
if obj.AbsoluteSize.X >= 18 and obj.AbsoluteSize.X <= 150 and obj.AbsoluteSize.Y >= 18 and obj.AbsoluteSize.Y <= 150 then
    local cx = obj.AbsolutePosition.X + (obj.AbsoluteSize.X * 0.5)
    local matchedLane = nil
    local minDist = 70

    for idx = 1, 5 do
        local lx = laneCenters[idx]
        if lx then
            local dist = math.abs(cx - lx)
            if dist < minDist then
                minDist = dist
                matchedLane = idx
            end
        end
    end

    if matchedLane then
        local isGold = string.find(nLower, "gold", 1, true) ~= nil
        local score = (isGold and 25 or 10) - (minDist * 0.15)
        if score > bestScore then
            bestScore = score
            bestLane = matchedLane
            bestTarget = laneButtons[matchedLane] or obj
        end
    end
end
end
end
end

if bestLane then
lastActionTime = tick()
if laneButtons[bestLane] then
clickInsideMiniGame(laneButtons[bestLane])
end
pcall(function()
local kc = laneKeys[bestLane]
if kc then
VirtualInputManager:SendKeyEvent(true, kc, false, game)
task.wait(0.015)
VirtualInputManager:SendKeyEvent(false, kc, false, game)
end
end)
if not laneButtons[bestLane] and bestTarget then
clickInsideMiniGame(bestTarget)
end
end

return true
end

local laneKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }
local laneCenters = {}
local laneButtons = {}

for _, obj in ipairs(mg:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local txt = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and (obj.Text or "") or ""
local trimmed = txt:match("^%s*(.-)%s*$")
local laneIdx = tonumber(trimmed)
if laneIdx and laneIdx >= 1 and laneIdx <= 5 then
local centerX = obj.AbsolutePosition.X + (obj.AbsoluteSize.X * 0.5)
laneCenters[laneIdx] = centerX
local btn = obj:IsA("GuiButton") and obj or (obj.Parent and obj.Parent:IsA("GuiButton") and obj.Parent or nil)
if btn and btn.Active then
laneButtons[laneIdx] = btn
end
end
end
end

local bestLane = nil
local bestTarget = nil
local bestScore = -1

for _, obj in ipairs(mg:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local nLower = string.lower(obj.Name)
local isShoe = string.find(nLower, "boot", 1, true) or string.find(nLower, "shoe", 1, true)
local isLaneOrBg = string.find(nLower, "lane", 1, true) or string.find(nLower, "bg", 1, true) or string.find(nLower, "pond", 1, true)
local isFishLike = string.find(nLower, "fish", 1, true) or string.find(nLower, "gold", 1, true) or string.find(nLower, "prey", 1, true) or string.find(nLower, "target", 1, true)

if not isShoe and not isLaneOrBg and (obj:IsA("ImageButton") or obj:IsA("ImageLabel") or isFishLike) then
if obj.AbsoluteSize.X >= 16 and obj.AbsoluteSize.X <= 160 and obj.AbsoluteSize.Y >= 16 and obj.AbsoluteSize.Y <= 160 then
local cx = obj.AbsolutePosition.X + (obj.AbsoluteSize.X * 0.5)
local matchedLane = nil
local minDist = 75

for idx = 1, 5 do
local lx = laneCenters[idx]
if lx then
local dist = math.abs(cx - lx)
if dist < minDist then
minDist = dist
matchedLane = idx
end
end
end

if matchedLane then
local score = (string.find(nLower, "gold", 1, true) and 20 or 10) - (minDist * 0.1)
if score > bestScore then
bestScore = score
bestLane = matchedLane
bestTarget = laneButtons[matchedLane] or obj
end
end
end
end
end
end

if bestLane then
lastActionTime = tick()
if laneButtons[bestLane] then
clickInsideMiniGame(laneButtons[bestLane])
end
pcall(function()
local kc = laneKeys[bestLane]
if kc then
VirtualInputManager:SendKeyEvent(true, kc, false, game)
task.wait(0.015)
VirtualInputManager:SendKeyEvent(false, kc, false, game)
end
end)
if not laneButtons[bestLane] and bestTarget then
clickInsideMiniGame(bestTarget)
end
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
                txt = obj.Text or ""
            end

            if string.find(txt, "ถึงตาคุณ", 1, true) then
                yourTurn = true
            end

            local upperTxt = string.upper(txt)
            for idx, keyWord in ipairs(orderNames) do
                if upperTxt == string.upper(keyWord) then
                    local card = obj.Parent and obj.Parent:IsA("GuiObject") and obj.Parent or obj
                    local btn = card:IsA("GuiButton") and card or card:FindFirstChildWhichIsA("GuiButton", true)
                    choices[idx] = {
                        index = idx,
                        name = keyWord,
                        target = btn or card,
                    }
                end
            end
        end
    end

    local litIdx = nil
    for idx = 1, 4 do
        local item = choices[idx]
        local t = item and item.target
        if t and t.Visible then
            local bg = t.BackgroundColor3
            if ((bg.R + bg.G + bg.B) / 3) > 0.85 or t.BackgroundTransparency < 0.05 then
                litIdx = idx
                break
            end
            for _, st in ipairs(t:GetDescendants()) do
                if st:IsA("UIStroke") and st.Enabled and st.Thickness >= 2.5 then
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
        if targetItem and targetItem.target then
            lastActionTime = tick()
            clickInsideMiniGame(targetItem.target)
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

    if tryPlayReelGame(mg, Config) then
        return
    end

    if tryPlayFishChaosGame(mg, Config) then
        return
    end

    tryPlayMemoryBaitGame(mg, Config)
    tryClickPlayInMiniGame(mg)
end

function GameModule.init(Config, Utils)`r`n`tif _G.TerNetAFishLoaded then return end`r`n`t_G.TerNetAFishLoaded = true
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

            if Config and Config.AutoFishCollect then
                if Cat1Module and Cat1Module.step then
                    pcall(Cat1Module.step, Config)
                end
            elseif Cat1Module and Cat1Module.reset then
                pcall(Cat1Module.reset)
            end

            if Config and Config.AutoMiniGame then
                pcall(stepMiniGame, Config)
                task.wait(0.05)
            else
                sequenceQueue = {}
                lastHighlightedKey = nil
                task.wait(0.15)
            end
        end
    end)

    print("[Net a Fish] โหลดไฟล์แยกหมวดที่ 1 (cat1_fishing_collect.lua) และระบบมินิเกมเรียบร้อย")
end

return GameModule