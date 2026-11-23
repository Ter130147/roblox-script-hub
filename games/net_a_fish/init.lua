local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false

local lastActionTime = 0
local lastAcceptTime = 0
local lastNeedleX = nil
local lastReelPressTime = 0
local lastChaosLane = nil
local lastChaosLaneTime = 0
local sequenceQueue = {}
local lastHighlightedKey = nil
local lastMemTurnState = false

local lastPadTpTime = 0
local lastCollectMoneyTime = 0
local padCycleIndex = 0

local Cat1Module = nil
pcall(function()
    local src = game:HttpGet("https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/games/net_a_fish/cat1_fishing_collect.lua?cb=" .. tostring(os.clock()) .. "_" .. tostring(math.random(10000,99999)), true)
    local fn = loadstring(src)
    if fn then
        Cat1Module = fn()
    end
end)

local function getRootPart()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then
        return nil
    end
    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local function findCollectPadPart(fromObj)
    local cur = fromObj
    while cur and cur ~= workspace do
        if cur.Name == "Collect" then
            local anchor = cur:FindFirstChild("LabelAnchor")
            if anchor and anchor:IsA("BasePart") then
                return anchor, cur
            end
            local part = cur:FindFirstChildWhichIsA("BasePart", true)
            if part then
                return part, cur
            end
        end
        cur = cur.Parent
    end
    if fromObj and fromObj:IsA("BasePart") then
        return fromObj, fromObj.Parent
    end
    return nil, nil
end

local function getPedestalTargets(rootPos)
    local targets = {}
    local seen = {}

    local mapObj = workspace:FindFirstChild("Map")
    local basesObj = mapObj and mapObj:FindFirstChild("Bases")
    local searchRoot = basesObj or workspace

    for _, d in ipairs(searchRoot:GetDescendants()) do
        if d:IsA("TextLabel") and d.Visible then
            local txt = tostring(d.Text or "")
            if string.find(string.lower(txt), "collect", 1, true) or string.find(txt, "$", 1, true) then
                local part, collectFolder = findCollectPadPart(d)
                if part and not seen[part] then
                    local dist = (part.Position - rootPos).Magnitude
                    if dist <= 260 then
                        seen[part] = true
                        local pedModel = collectFolder and collectFolder.Parent or part.Parent
                        table.insert(targets, {
                            part = part,
                            collectFolder = collectFolder,
                            pedName = pedModel and pedModel.Name or part.Name,
                            pos = part.Position,
                            halfH = part.Size.Y * 0.5,
                            dist = dist,
                        })
                    end
                end
            end
        end
    end

    table.sort(targets, function(a, b)
        if math.abs(a.dist - b.dist) > 25 then
            return a.dist < b.dist
        end
        return tostring(a.pedName) < tostring(b.pedName)
    end)

    return targets
end

local function stepAutoPadTp(cfg)
    if not (cfg and cfg.AutoPadTp) then
        return
    end
    local interval = tonumber(cfg.CollectIntervalSec) or 5
    local cooldown = math.max(1.0, math.min(interval, 15))
    if tick() - lastPadTpTime < cooldown then
        return
    end

    local root = getRootPart()
    if not root then
        return
    end

    local targets = getPedestalTargets(root.Position)
    if #targets > 0 then
        padCycleIndex = (padCycleIndex % #targets) + 1
        local chosen = targets[padCycleIndex]
        lastPadTpTime = tick()
        local targetPos = chosen.pos + Vector3.new(0, (chosen.halfH or 1) + 3.2, 0)
        pcall(function()
            root.CFrame = CFrame.new(targetPos, targetPos + root.CFrame.LookVector)
        end)
    end
end

local function stepAutoCollectMoney(cfg)
    if not (cfg and cfg.AutoCollectMoney) then
        return
    end
    local interval = tonumber(cfg.CollectIntervalSec) or 5
    local cooldown = math.max(0.8, math.min(interval, 15))
    if tick() - lastCollectMoneyTime < cooldown then
        return
    end
    lastCollectMoneyTime = tick()

    local root = getRootPart()
    if not root then
        return
    end

    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    local collectRemote = remotesFolder and remotesFolder:FindFirstChild("CollectPadReq")
    local targets = getPedestalTargets(root.Position)

    for _, item in ipairs(targets) do
        if item.dist <= 65 then
            if collectRemote and collectRemote:IsA("RemoteEvent") then
                pcall(function()
                    collectRemote:FireServer(item.collectFolder or item.part)
                end)
                pcall(function()
                    collectRemote:FireServer(item.pedName)
                end)
            end
            if firetouchinterest and item.part then
                pcall(function()
                    firetouchinterest(root, item.part, 0)
                    task.wait(0.02)
                    firetouchinterest(root, item.part, 1)
                end)
            end
        end
    end

    if collectRemote and collectRemote:IsA("RemoteEvent") then
        pcall(function()
            collectRemote:FireServer()
        end)
    end
end

local function hasFishingToggleActive(cfg)
    if not cfg then
        return false
    end
    return (cfg.AutoFishCollect == true)
        or (cfg.AutoCatch == true)
        or (cfg.AutoReelFull == true)
end

local function scanGameStructure()
    print("==========================================================")
    print("[DeepScan] 1. REMOTES & BINDABLES")
    local foundRemote = false
    for _, service in ipairs({ ReplicatedStorage, workspace }) do
        for _, obj in ipairs(service:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
                foundRemote = true
                print(string.format("  - [%s] %s", obj.ClassName, obj:GetFullName()))
            end
        end
    end
    if not foundRemote then
        print("  - (ไม่พบ Remote/Bindable)")
    end
    print("==========================================================")
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

local function fireGuiButton(guiObj)
    if not guiObj or not guiObj.Visible then
        return false
    end

    local btn = guiObj:IsA("GuiButton") and guiObj
        or guiObj:FindFirstAncestorWhichIsA("GuiButton")
        or guiObj:FindFirstChildWhichIsA("GuiButton", true)
        or guiObj

    local fired = false
    pcall(function()
        if getconnections and btn and btn:IsA("GuiButton") then
            for _, evName in ipairs({ "MouseButton1Down", "MouseButton1Click", "Activated" }) do
                local sig = btn[evName]
                if sig then
                    for _, conn in ipairs(getconnections(sig)) do
                        conn:Fire()
                        fired = true
                    end
                end
            end
        end
    end)

    pcall(function()
        local targetBox = (guiObj:FindFirstChild("Face", true) or guiObj)
        local pos = targetBox.AbsolutePosition
        local sz = targetBox.AbsoluteSize
        if pos and sz and sz.X > 4 and sz.Y > 4 then
            local inset = GuiService:GetGuiInset()
            local cx = math.floor(pos.X + (sz.X * 0.5) + inset.X)
            local cy = math.floor(pos.Y + (sz.Y * 0.5) + inset.Y)
            VirtualInputManager:SendMouseMoveEvent(cx, cy, game)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.03)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
            fired = true
        end
    end)

    return fired
end

local function tapKey(keyCode)
    if not keyCode then
        return
    end
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
        VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
    end)
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

local function getActiveMiniGameAreas(mg)
    local areas = {}
    for _, d in ipairs(mg:GetDescendants()) do
        if d:IsA("GuiObject") and d.Name == "Area" and d.Visible then
            table.insert(areas, d)
        end
    end
    if #areas == 0 then
        table.insert(areas, mg)
    end
    return areas
end

local function getCombinedVisibleText(mg)
    local list = {}
    for _, obj in ipairs(mg:GetDescendants()) do
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
            local t = string.upper(obj.Text or "")
            if t ~= "" then
                table.insert(list, t)
            end
        end
    end
    return table.concat(list, " | ")
end

local function isResultScreenVisible(mg)
    local res = mg:FindFirstChild("Window")
        and mg.Window:FindFirstChild("Body")
        and mg.Window.Body:FindFirstChild("Result")
    return (res and res:IsA("GuiObject") and res.Visible) == true
end

local function isInActiveGameplay(mg, allText)
    local areas = getActiveMiniGameAreas(mg)
    for _, area in ipairs(areas) do
        for _, d in ipairs(area:GetDescendants()) do
            if d:IsA("GuiObject") and d.Visible then
                local nLow = string.lower(d.Name)
                if string.find(nLow, "bait", 1, true)
                    or string.find(nLow, "spot", 1, true)
                    or string.find(nLow, "lane", 1, true)
                    or string.find(nLow, "needle", 1, true)
                then
                    return true
                end
            end
        end
    end
    if string.find(allText, "YOUR TURN", 1, true)
        or string.find(allText, "ถึงตาคุณ", 1, true)
        or string.find(allText, "SPACE OR CLICK", 1, true)
        or string.find(allText, "CLICK OR KEYS 1-5", 1, true)
    then
        return true
    end
    return false
end

local function tryClickStartButton(mg)
    if isResultScreenVisible(mg) then
        return false
    end
    if tick() - lastAcceptTime < 0.7 then
        return false
    end

    for _, obj in ipairs(mg:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and obj.Name ~= "Backdrop" then
            local nLow = string.lower(obj.Name)
            local txt = ""
            if obj:IsA("TextButton") and (obj.Text or "") ~= "" then
                txt = obj.Text
            else
                for _, ch in ipairs(obj:GetDescendants()) do
                    if ch:IsA("TextLabel") and ch.Visible and (ch.Text or "") ~= "" then
                        txt = ch.Text
                        break
                    end
                end
            end
            local low = string.lower(txt)
            local isBanner = string.find(low, "play for a medal", 1, true) ~= nil
                or string.find(low, "the better you do", 1, true) ~= nil

            local isStart = (not isBanner) and (
                string.find(nLow, "play", 1, true) ~= nil
                or string.find(nLow, "start", 1, true) ~= nil
                or (string.find(low, "play", 1, true) ~= nil and #txt <= 48)
                or (string.find(txt, "เล่น", 1, true) ~= nil and #txt <= 48)
                or (string.find(txt, "เริ่ม", 1, true) ~= nil and #txt <= 48)
            )

            if isStart and not containsDangerText(obj.Parent) then
                lastAcceptTime = tick()
                fireGuiButton(obj)
                return true
            end
        end
    end

    return false
end

local function runReelMinigame(mg, allText)
    local isReel = string.find(allText, "REEL", 1, true) ~= nil
        or string.find(allText, "ม้วนที่สมบูรณ์แบบ", 1, true) ~= nil
        or string.find(allText, "GOLD IS PERFECT", 1, true) ~= nil

    if not isReel then
        lastNeedleX = nil
        return false
    end

    local areas = getActiveMiniGameAreas(mg)
    local reelBtn, greenZone, goldZone, needle = nil, nil, nil, nil

    for _, area in ipairs(areas) do
        for _, obj in ipairs(area:GetDescendants()) do
            if obj:IsA("GuiObject") and obj.Visible then
                local nLow = string.lower(obj.Name)
                local sz = obj.AbsoluteSize
                local c = obj.BackgroundColor3

                if (obj:IsA("Frame") or obj:IsA("ImageLabel")) and obj.BackgroundTransparency < 0.35 then
                    local isWhiteNeedle = (c.R > 0.85 and c.G > 0.85 and c.B > 0.85 and sz.X >= 3 and sz.X <= 24 and sz.Y >= 20)
                    local isNamedNeedle = (
                        string.find(nLow, "needle", 1, true)
                        or string.find(nLow, "pointer", 1, true)
                        or string.find(nLow, "marker", 1, true)
                        or string.find(nLow, "cursor", 1, true)
                        or string.find(nLow, "indicator", 1, true)
                    ) and (sz.X <= 30 and sz.Y >= 14)

                    if isWhiteNeedle or isNamedNeedle then
                        needle = obj
                    end

                    if sz.X >= 4 and sz.X <= 180 and sz.Y >= 14 then
                        local isGold = (c.R > 0.72 and c.G > 0.55 and c.B < 0.35)
                            or string.find(nLow, "gold", 1, true) ~= nil
                            or string.find(nLow, "perfect", 1, true) ~= nil
                            or string.find(nLow, "sweet", 1, true) ~= nil
                        if isGold then
                            goldZone = obj
                        elseif (c.G > 0.52 and c.R < 0.48) or string.find(nLow, "green", 1, true) or string.find(nLow, "zone", 1, true) then
                            if sz.X <= 360 then
                                greenZone = obj
                            end
                        end
                    end
                end
            end
        end
    end

    for _, obj in ipairs(mg:GetDescendants()) do
        if obj:IsA("GuiButton") and obj.Visible and not containsDangerText(obj) then
            local nLow = string.lower(obj.Name)
            if string.find(nLow, "reel", 1, true) then
                reelBtn = obj
                break
            end
            for _, ch in ipairs(obj:GetDescendants()) do
                if ch:IsA("TextLabel") and string.find(string.upper(ch.Text or ""), "REEL", 1, true) then
                    reelBtn = obj
                    break
                end
            end
            if reelBtn then break end
        end
    end

    if needle and (tick() - lastReelPressTime >= 0.16) then
        local nCenter = needle.AbsolutePosition.X + (needle.AbsoluteSize.X * 0.5)
        local velX = lastNeedleX and (nCenter - lastNeedleX) or 0
        lastNeedleX = nCenter
        local predCenter = nCenter + (velX * 0.55)

        local zMin, zMax
        if goldZone then
            zMin = goldZone.AbsolutePosition.X + 1
            zMax = goldZone.AbsolutePosition.X + goldZone.AbsoluteSize.X - 1
        elseif greenZone then
            local gLeft = greenZone.AbsolutePosition.X
            local gWidth = greenZone.AbsoluteSize.X
            zMin = gLeft + (gWidth * 0.36)
            zMax = gLeft + (gWidth * 0.64)
        end

        if zMin and zMax then
            if (nCenter >= zMin and nCenter <= zMax) or (predCenter >= zMin and predCenter <= zMax) then
                lastReelPressTime = tick()
                lastActionTime = tick()
                if reelBtn then
                    fireGuiButton(reelBtn)
                end
                tapKey(Enum.KeyCode.Space)
            end
        end
    end

    return true
end

local function runFishChaosMinigame(mg, allText)
    local isChaos = string.find(allText, "FISH CHAOS", 1, true) ~= nil
        or string.find(allText, "ความโกลาหลของปลา", 1, true) ~= nil
        or string.find(allText, "GOLDEN +30", 1, true) ~= nil
        or string.find(allText, "BOOT -15", 1, true) ~= nil

    if not isChaos then
        lastChaosLane = nil
        return false
    end

    if tick() - lastActionTime < 0.05 then
        return true
    end

    local areas = getActiveMiniGameAreas(mg)
    local laneKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }
    local laneCenters, laneButtons, laneBottomY = {}, {}, nil

    for _, area in ipairs(areas) do
        for _, obj in ipairs(area:GetDescendants()) do
            if obj:IsA("GuiObject") and obj.Visible then
                local txt = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and (obj.Text or "") or ""
                local trimmed = txt:match("^%s*(.-)%s*$")
                local laneIdx = tonumber(trimmed)
                if laneIdx and laneIdx >= 1 and laneIdx <= 5 then
                    laneCenters[laneIdx] = obj.AbsolutePosition.X + (obj.AbsoluteSize.X * 0.5)
                    laneBottomY = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y * 0.5)
                    local btn = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
                    if btn and btn.Active then
                        laneButtons[laneIdx] = btn
                    end
                end
            end
        end
    end

    local foundLanes = 0
    for idx = 1, 5 do
        if laneCenters[idx] then
            foundLanes += 1
        end
    end

    if foundLanes < 3 and #areas > 0 then
        local area = areas[1]
        local aPos = area.AbsolutePosition
        local aSz = area.AbsoluteSize
        if aSz.X > 100 and aSz.Y > 80 then
            laneBottomY = laneBottomY or (aPos.Y + aSz.Y * 0.84)
            for idx = 1, 5 do
                laneCenters[idx] = aPos.X + (aSz.X * ((idx - 0.5) / 5))
            end
        end
    end

    local bestLane, bestTarget, bestScore = nil, nil, -9999

    for _, area in ipairs(areas) do
        local aPos = area.AbsolutePosition
        local aSz = area.AbsoluteSize
        local playTopY = aPos.Y + 8
        local playBotY = (laneBottomY or (aPos.Y + aSz.Y * 0.85)) - 4

        for _, obj in ipairs(area:GetDescendants()) do
            if obj:IsA("GuiObject") and obj.Visible then
                local nLow = string.lower(obj.Name)
                local isBootName = string.find(nLow, "boot", 1, true)
                    or string.find(nLow, "shoe", 1, true)
                    or string.find(nLow, "รองเท้า", 1, true)
                    or string.find(nLow, "บูต", 1, true)
                local isUiChrome = string.find(nLow, "lane", 1, true)
                    or string.find(nLow, "slot", 1, true)
                    or string.find(nLow, "bg", 1, true)
                    or string.find(nLow, "pond", 1, true)

                local sz = obj.AbsoluteSize
                if not isBootName and not isUiChrome and sz.X >= 14 and sz.X <= 180 and sz.Y >= 14 and sz.Y <= 180 then
                    local pos = obj.AbsolutePosition
                    local cx = pos.X + (sz.X * 0.5)
                    local cy = pos.Y + (sz.Y * 0.5)

                    if cy >= playTopY and cy <= playBotY then
                        local col = obj.BackgroundColor3
                        if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.ImageTransparency < 0.85 then
                            col = obj.ImageColor3
                        end

                        local isDarkBrownBoot = (col.R > 0.42 and col.G < 0.34 and col.B < 0.18 and col.R > col.G * 1.45)

                        if not isDarkBrownBoot then
                            local matchedLane = nil
                            local minDist = 56
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
                                local progress = math.clamp((cy - playTopY) / math.max(1, (playBotY - playTopY)), 0, 1)
                                local repeatPenalty = (matchedLane == lastChaosLane and (tick() - lastChaosLaneTime) < 0.16) and 25 or 0
                                local score = (progress * 45) - (minDist * 0.25) - repeatPenalty
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
        end
    end

    if bestLane then
        lastActionTime = tick()
        lastChaosLane = bestLane
        lastChaosLaneTime = tick()
        if laneButtons[bestLane] then
            fireGuiButton(laneButtons[bestLane])
        elseif bestTarget then
            fireGuiButton(bestTarget)
        end
        tapKey(laneKeys[bestLane])
    end

    return true
end

local function runBaitMemoryMinigame(mg, allText)
    local areas = getActiveMiniGameAreas(mg)
    local choices = {}
    local orderNames = { "WORM", "SHRIMP", "CRICKET", "MINNOW" }
    local memKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }

    for _, area in ipairs(areas) do
        for idx = 1, 4 do
            local baitBtn = area:FindFirstChild("Bait" .. tostring(idx))
            if baitBtn and baitBtn:IsA("GuiObject") and baitBtn.Visible then
                local face = baitBtn:FindFirstChild("Face")
                local shine = face and face:FindFirstChild("Shine")
                choices[idx] = {
                    index = idx,
                    name = orderNames[idx],
                    card = (face and face:IsA("GuiObject")) and face or baitBtn,
                    shine = shine,
                    target = baitBtn,
                }
            end
        end
        if next(choices) ~= nil then
            break
        end
    end

    local isMemory = (next(choices) ~= nil)
        or string.find(allText, "BAIT MEMORY", 1, true) ~= nil
        or string.find(allText, "ความจำเหยื่อ", 1, true) ~= nil
        or string.find(allText, "หน่วยความจำเหยื่อ", 1, true) ~= nil

    if not isMemory then
        lastMemTurnState = false
        return false
    end

    local yourTurn = string.find(allText, "YOUR TURN", 1, true) ~= nil
        or string.find(allText, "REPEAT THE ORDER", 1, true) ~= nil
        or string.find(allText, "ถึงตาคุณ", 1, true) ~= nil

    if yourTurn and not lastMemTurnState then
        lastHighlightedKey = nil
    elseif (not yourTurn) and lastMemTurnState then
        sequenceQueue = {}
        lastHighlightedKey = nil
    end
    lastMemTurnState = yourTurn

    local litIdx = nil
    for idx = 1, 4 do
        local item = choices[idx]
        local c = item and item.card
        local rootBtn = item and item.target
        local sh = item and item.shine
        if c and c.Visible then
            local highlighted = false
            if sh and sh:IsA("GuiObject") and sh.Visible then
                highlighted = true
            end
            if not highlighted then
                local bg = c.BackgroundColor3
                if ((bg.R + bg.G + bg.B) / 3) > 0.85 or c.BackgroundTransparency < 0.05 then
                    highlighted = true
                end
            end
            if not highlighted and (c:IsA("ImageLabel") or c:IsA("ImageButton")) then
                local ic = c.ImageColor3
                if ((ic.R + ic.G + ic.B) / 3) > 0.90 and c.ImageTransparency < 0.15 then
                    highlighted = true
                end
            end
            if not highlighted then
                for _, d in ipairs(c:GetDescendants()) do
                    if d:IsA("UIStroke") and d.Enabled and d.Thickness >= 2.0 then
                        highlighted = true
                        break
                    elseif d:IsA("UIScale") and d.Scale > 1.03 then
                        highlighted = true
                        break
                    elseif d:IsA("GuiObject") and d.Visible and (
                        string.find(string.lower(d.Name), "glow", 1, true)
                        or string.find(string.lower(d.Name), "flash", 1, true)
                        or string.find(string.lower(d.Name), "highlight", 1, true)
                    ) then
                        highlighted = true
                        break
                    end
                end
            end
            if highlighted then
                litIdx = idx
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
        return true
    end

    if tick() - lastActionTime < 0.08 then
        return true
    end

    if #sequenceQueue > 0 then
        local nextIdx = table.remove(sequenceQueue, 1)
        local targetItem = choices[nextIdx]
        if targetItem and targetItem.target then
            lastActionTime = tick()
            fireGuiButton(targetItem.target)
            tapKey(memKeys[nextIdx])
        end
    end

    return true
end

local function stepMiniGame()
    local mg = getMiniGameGui()
    if not mg then
        sequenceQueue = {}
        lastHighlightedKey = nil
        lastNeedleX = nil
        lastChaosLane = nil
        lastMemTurnState = false
        return
    end

    local allText = getCombinedVisibleText(mg)

    if not isInActiveGameplay(mg, allText) then
        if tryClickStartButton(mg) then
            return
        end
    end

    if runReelMinigame(mg, allText) then
        return
    end

    if runFishChaosMinigame(mg, allText) then
        return
    end

    if runBaitMemoryMinigame(mg, allText) then
        return
    end

    tryClickStartButton(mg)
end

function GameModule.init(Config, Utils)
    if started then
        return
    end
    started = true

    RunService.Heartbeat:Connect(function()
        if Config and Config.ScanNow then
            Config.ScanNow = false
            task.spawn(scanGameStructure)
        end

        if Config and Config.AutoMiniGame then
            pcall(stepMiniGame)
        else
            sequenceQueue = {}
            lastHighlightedKey = nil
        end
    end)

    task.spawn(function()
        while started do
            if Config then
                if hasFishingToggleActive(Config) then
                    if Cat1Module and Cat1Module.step then
                        pcall(Cat1Module.step, Config)
                    end
                elseif Cat1Module and Cat1Module.reset then
                    pcall(Cat1Module.reset)
                end

                if Config.AutoPadTp then
                    pcall(stepAutoPadTp, Config)
                end

                if Config.AutoCollectMoney then
                    pcall(stepAutoCollectMoney, Config)
                end
            end
            task.wait(0.15)
        end
    end)

    print("[Net a Fish] โหลดระบบ Pedestal TP + CollectPadReq + 3 Minigames เรียบร้อย")
end

return GameModule