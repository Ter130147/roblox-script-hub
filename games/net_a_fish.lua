local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false

local sequenceQueue = {}
local lastHighlightedKey = nil
local lastReplayTime = 0
local lastAcceptTime = 0

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

local function clickGuiButton(btn)
    if not btn or not btn.Visible then
        return false
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

    pcall(function()
        if btn.AbsolutePosition and btn.AbsoluteSize then
            local cx = btn.AbsolutePosition.X + (btn.AbsoluteSize.X * 0.5)
            local cy = btn.AbsolutePosition.Y + (btn.AbsoluteSize.Y * 0.5) + 36
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        end
    end)

    return true
end

local function autoAcceptMiniGame(rem)
    if tick() - lastAcceptTime < 0.6 then
        return
    end

    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return
    end

    local acceptKeywords = {
        "accept", "play", "start", "join", "ready", "enter", "confirm", "yes",
        "ยอมรับ", "เริ่ม", "เล่น", "ตกลง", "เข้าร่วม", "พร้อม"
    }

    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name ~= "TerHubProUI" and gui:IsA("ScreenGui") and gui.Enabled then
            for _, obj in ipairs(gui:GetDescendants()) do
                if (obj:IsA("TextButton") or obj:IsA("ImageButton")) and obj.Visible and obj.Active then
                    local nameLower = string.lower(obj.Name)
                    local textLower = obj:IsA("TextButton") and string.lower(obj.Text) or ""
                    local blob = nameLower .. " " .. textLower

                    -- ข้ามปุ่มปิด/กากบาท
                    if string.find(blob, "close") or string.find(blob, "decline") or string.find(blob, "cancel") or textLower == "x" then
                        continue
                    end

                    for _, kw in ipairs(acceptKeywords) do
                        if string.find(blob, kw) then
                            lastAcceptTime = tick()
                            clickGuiButton(obj)
                            if rem then
                                safeFire(rem.MiniGamePing, "Accept")
                                safeInvoke(rem.MiniGame, "Accept")
                                safeInvoke(rem.MiniGame, "Start")
                            end
                            return
                        end
                    end
                end
            end
        end
    end
end

local function getBaitChoices()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return {}
    end
    local choices = {}
    local orderNames = { "worm", "shrimp", "cricket", "minnow" }

    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name ~= "TerHubProUI" and gui:IsA("ScreenGui") and gui.Enabled then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("GuiObject") and obj.Visible then
                    local blob = string.lower(obj.Name .. " " .. (obj:IsA("TextLabel") or obj:IsA("TextButton") and obj.Text or ""))
                    for idx, keyWord in ipairs(orderNames) do
                        if string.find(blob, keyWord) then
                            local btn = obj:IsA("GuiButton") and obj or obj:FindFirstChildWhichIsA("GuiButton", true)
                            if btn and btn.Visible then
                                choices[idx] = {
                                    index = idx,
                                    name = keyWord,
                                    button = btn,
                                    card = obj,
                                }
                            end
                        end
                    end
                end
            end
        end
    end
    return choices
end

local function isYourTurnTextActive()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return false
    end
    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name ~= "TerHubProUI" and gui:IsA("ScreenGui") and gui.Enabled then
            for _, lbl in ipairs(gui:GetDescendants()) do
                if lbl:IsA("TextLabel") and lbl.Visible then
                    local txt = string.lower(lbl.Text)
                    if string.find(txt, "ถึงตาคุณ") or string.find(txt, "repeat") or string.find(txt, "your turn") then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function detectHighlightedBait(choices)
    for idx = 1, 4 do
        local item = choices[idx]
        if item and item.card then
            local c = item.card
            local isLit = false
            if c:IsA("Frame") or c:IsA("TextButton") or c:IsA("ImageButton") then
                local bg = c.BackgroundColor3
                local brightness = (bg.R + bg.G + bg.B) / 3
                if brightness > 0.78 or c.BackgroundTransparency < 0.12 then
                    isLit = true
                end
            end
            for _, st in ipairs(c:GetDescendants()) do
                if st:IsA("UIStroke") and st.Enabled and st.Thickness >= 2.5 then
                    isLit = true
                    break
                end
            end
            if isLit then
                return idx
            end
        end
    end
    return nil
end

local function pressChoice(item, rem)
    if not item then
        return
    end
    local idx = item.index
    local keyMap = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }

    clickGuiButton(item.button)

    pcall(function()
        if keyMap[idx] then
            VirtualInputManager:SendKeyEvent(true, keyMap[idx], false, game)
            task.wait(0.02)
            VirtualInputManager:SendKeyEvent(false, keyMap[idx], false, game)
        end
    end)

    if rem then
        safeFire(rem.MiniGamePing, "Select", idx, item.name)
        safeInvoke(rem.MiniGame, "Select", idx, item.name)
    end
end

local function runMemoryBaitStep()
    local rem = getRemotes()
    autoAcceptMiniGame(rem)

    local choices = getBaitChoices()
    local yourTurn = isYourTurnTextActive()
    local litIdx = detectHighlightedBait(choices)

    if not yourTurn then
        if litIdx and litIdx ~= lastHighlightedKey then
            lastHighlightedKey = litIdx
            table.insert(sequenceQueue, litIdx)
        elseif not litIdx then
            lastHighlightedKey = nil
        end
        return
    end

    local spd = tonumber(Config and Config.MiniGameSpeed) or 0.15
    if tick() - lastReplayTime < math.clamp(spd, 0.05, 1.0) then
        return
    end

    if #sequenceQueue > 0 then
        local nextIdx = table.remove(sequenceQueue, 1)
        local targetItem = choices[nextIdx]
        if targetItem then
            lastReplayTime = tick()
            pressChoice(targetItem, rem)
        end
    else
        lastHighlightedKey = nil
    end
end

function GameModule.init(Config, Utils)
    if started then
        return
    end
    started = true

    task.spawn(function()
        while started do
            if Config and Config.AutoMiniGame then
                pcall(runMemoryBaitStep)
                task.wait(0.03)
            else
                sequenceQueue = {}
                lastHighlightedKey = nil
                task.wait(0.2)
            end
        end
    end)

    print("[Net a Fish] โหลดระบบกดรับมินิเกมอัตโนมัติ + จำลำดับเหยื่อเรียบร้อย")
end

return GameModule