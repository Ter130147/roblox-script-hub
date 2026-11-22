local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false

local sequenceQueue = {}
local lastHighlightedKey = nil
local lastReplayTime = 0

local function getRemotes()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if not r then
        return nil
    end
    return {
        MiniGame = r:FindFirstChild("MiniGame"),
        MiniGamePing = r:FindFirstChild("MiniGamePing"),
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

local function getMemoryMiniGameContext()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        return false, false, {}
    end

    local hasMiniGame = false
    local yourTurn = false
    local choices = {}
    local orderNames = { "worm", "shrimp", "cricket", "minnow" }

    for _, gui in ipairs(pg:GetChildren()) do
        if gui.Name ~= "TerHubProUI" and gui:IsA("ScreenGui") and gui.Enabled then
            for _, obj in ipairs(gui:GetDescendants()) do
                if obj:IsA("GuiObject") and obj.Visible then
                    local txt = ""
                    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        txt = string.lower(obj.Text)
                    end
                    local blob = string.lower(obj.Name) .. " " .. txt

                    if string.find(blob, "ช่วยความจำเหยื่อ") or string.find(blob, "repeat the order") then
                        hasMiniGame = true
                    end

                    if string.find(txt, "ถึงตาคุณ") or string.find(txt, "repeat the order") then
                        hasMiniGame = true
                        yourTurn = true
                    end

                    for idx, keyWord in ipairs(orderNames) do
                        if string.find(blob, keyWord) then
                            hasMiniGame = true
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

    return hasMiniGame, yourTurn, choices
end

local function detectHighlightedBait(choices)
    for idx = 1, 4 do
        local item = choices[idx]
        if item and item.card then
            local c = item.card
            if c:IsA("GuiObject") then
                local bg = c.BackgroundColor3
                local brightness = (bg.R + bg.G + bg.B) / 3
                if brightness > 0.82 or c.BackgroundTransparency < 0.08 then
                    return idx
                end
            end
            for _, st in ipairs(c:GetDescendants()) do
                if st:IsA("UIStroke") and st.Enabled and st.Thickness >= 3 then
                    return idx
                end
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

    pcall(function()
        if item.button and item.button.AbsolutePosition and item.button.AbsoluteSize then
            local cx = item.button.AbsolutePosition.X + (item.button.AbsoluteSize.X * 0.5)
            local cy = item.button.AbsolutePosition.Y + (item.button.AbsoluteSize.Y * 0.5) + 36
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
            task.wait(0.02)
            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
        elseif keyMap[idx] then
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
    local hasMiniGame, yourTurn, choices = getMemoryMiniGameContext()
    if not hasMiniGame then
        sequenceQueue = {}
        lastHighlightedKey = nil
        return
    end

    local rem = getRemotes()
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
    if tick() - lastReplayTime < math.clamp(spd, 0.08, 1.0) then
        return
    end

    if #sequenceQueue > 0 then
        local nextIdx = table.remove(sequenceQueue, 1)
        local targetItem = choices[nextIdx]
        if targetItem then
            lastReplayTime = tick()
            pressChoice(targetItem, rem)
        end
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
                task.wait(0.04)
            else
                sequenceQueue = {}
                lastHighlightedKey = nil
                task.wait(0.2)
            end
        end
    end)

    print("[Net a Fish] โหลดโหมดจำเหยื่อแบบไม่กดมั่วเรียบร้อย")
end

return GameModule