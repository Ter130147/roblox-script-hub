local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")
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

print("[DeepScan] 2. PLAYER GUIS & ACTIVE MINIGAMEUI")
local pg = LocalPlayer:FindFirstChild("PlayerGui")
if pg then
for _, gui in ipairs(pg:GetChildren()) do
if gui:IsA("ScreenGui") then
local visButtons = 0
for _, d in ipairs(gui:GetDescendants()) do
if d:IsA("GuiButton") and d.Visible then
visButtons += 1
end
end
print(string.format("  - ScreenGui: %s | Enabled: %s | VisibleButtons: %d", gui.Name, tostring(gui.Enabled), visButtons))
end
end

local mg = pg:FindFirstChild("MiniGameUI")
if mg and mg:IsA("ScreenGui") and mg.Enabled then
print("  --- [MiniGameUI Visible GuiButtons] ---")
for _, d in ipairs(mg:GetDescendants()) do
if d:IsA("GuiButton") and d.Visible then
local txts = {}
if d:IsA("TextButton") and (d.Text or "") ~= "" then
table.insert(txts, d.Text)
end
for _, ch in ipairs(d:GetDescendants()) do
if ch:IsA("TextLabel") and ch.Visible and (ch.Text or "") ~= "" then
table.insert(txts, ch.Text)
end
end
print(string.format("    * BTN: %s (%s) | Act:%s | Pos:(%d,%d) | Sz:(%d,%d) | Txt:[%s]",
d.Name, d.ClassName, tostring(d.Active),
math.floor(d.AbsolutePosition.X), math.floor(d.AbsolutePosition.Y),
math.floor(d.AbsoluteSize.X), math.floor(d.AbsoluteSize.Y),
table.concat(txts, " / ")
))
end
end

print("  --- [MiniGameUI Visible Area / Spot / Game Elements] ---")
local area = mg:FindFirstChild("Window")
and mg.Window:FindFirstChild("Body")
and mg.Window.Body:FindFirstChild("Area")
for _, d in ipairs(mg:GetDescendants()) do
if d:IsA("GuiObject") and d.Visible then
local nLow = string.lower(d.Name)
local pLow = d.Parent and string.lower(d.Parent.Name) or ""
local isInteresting = (area and d:IsDescendantOf(area))
or string.find(nLow, "spot", 1, true)
or string.find(pLow, "spot", 1, true)
or string.find(nLow, "bait", 1, true)
or string.find(nLow, "lane", 1, true)
or string.find(nLow, "needle", 1, true)
or string.find(nLow, "zone", 1, true)
or string.find(nLow, "gold", 1, true)
or string.find(nLow, "reel", 1, true)
if isInteresting then
local c = d.BackgroundColor3
local txt = (d:IsA("TextLabel") or d:IsA("TextButton")) and string.gsub(tostring(d.Text or ""), "[\r\n]+", " ") or ""
print(string.format("    * %s (%s) | T:%.2f | BG:[%d,%d,%d] | Pos:(%d,%d) | Sz:(%d,%d) | Txt:'%s' | %s",
d.Name, d.ClassName, d.BackgroundTransparency,
math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255),
math.floor(d.AbsolutePosition.X), math.floor(d.AbsolutePosition.Y),
math.floor(d.AbsoluteSize.X), math.floor(d.AbsoluteSize.Y),
txt, d:GetFullName()
))
end
end
end
end
end

print("[DeepScan] 3. WORKSPACE TOP-LEVEL & CHILD COUNTS")
for _, obj in ipairs(workspace:GetChildren()) do
if obj:IsA("Folder") or obj:IsA("Model") then
print(string.format("  - %s (%s) | Descendants: %d", obj.Name, obj.ClassName, #obj:GetDescendants()))
end
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

local function instantClickMiniGame(guiObj)
if not guiObj or not guiObj.Visible then
return false
end

local fired = false
pcall(function()
if getconnections then
local btn = guiObj:IsA("GuiButton") and guiObj
or guiObj:FindFirstAncestorWhichIsA("GuiButton")
or guiObj:FindFirstChildWhichIsA("GuiButton", true)
if btn then
for _, conn in ipairs(getconnections(btn.MouseButton1Down)) do
conn:Fire()
fired = true
end
for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
conn:Fire()
fired = true
end
for _, conn in ipairs(getconnections(btn.Activated)) do
conn:Fire()
fired = true
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
VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
fired = true
end
end)

return fired
end

local function instantPressKey(keyCode)
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

local function getHeaderTitle(mg)
local titles = {}
for _, obj in ipairs(mg:GetDescendants()) do
if (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
local t = string.upper(obj.Text or "")
if t ~= "" then
table.insert(titles, t)
end
end
end
return table.concat(titles, " | ")
end

local function tryClickPlayInMiniGame(mg)
if tick() - lastAcceptTime < 0.6 then
return false
end

local resultFrame = mg:FindFirstChild("Window")
and mg.Window:FindFirstChild("Body")
and mg.Window.Body:FindFirstChild("Result")
if resultFrame and resultFrame:IsA("GuiObject") and resultFrame.Visible then
return false
end

for _, obj in ipairs(mg:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local nLower = string.lower(obj.Name)
local txt = ""
if obj:IsA("TextButton") or obj:IsA("TextLabel") then
txt = obj.Text or ""
end
local low = string.lower(txt)
local isBannerText = string.find(low, "play for a medal", 1, true) ~= nil
or string.find(low, "the better you do", 1, true) ~= nil

local isPlayBtn = (not isBannerText) and (
string.find(nLower, "playbutton", 1, true) ~= nil
or (string.find(low, "play", 1, true) ~= nil and #txt <= 32)
or (string.find(txt, "เล่น", 1, true) ~= nil and #txt <= 32)
or (string.find(txt, "เริ่ม", 1, true) ~= nil and #txt <= 32)
)

if isPlayBtn then
local target = obj:IsA("GuiButton") and obj
or obj:FindFirstAncestorWhichIsA("GuiButton")
if target and target:IsA("GuiButton") and target.Name ~= "Backdrop" and not containsDangerText(target.Parent) then
lastAcceptTime = tick()
print("[MiniGame] กดปุ่มเริ่มรอบ:", target.Name, "|", txt)
instantClickMiniGame(target)
return true
end
end
end
end
return false
end

-- [1] REEL! / ม้วนที่สมบูรณ์แบบ เล็งเฉพาะโซนสีทอง (PERFECT) พร้อมชดเชยความเร็วเข็ม
local lastNeedleX = nil

local function tryPlayReelGame(mg, allText)
local areas = getActiveMiniGameAreas(mg)
local isReelMode = string.find(allText, "REEL", 1, true) ~= nil
or string.find(allText, "ม้วนที่สมบูรณ์แบบ", 1, true) ~= nil
or string.find(allText, "GOLD IS PERFECT", 1, true) ~= nil

local reelBtn = nil
local greenZone = nil
local goldZone = nil
local needle = nil

for _, area in ipairs(areas) do
for _, obj in ipairs(area:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local nLower = string.lower(obj.Name)
local txtUpper = string.upper((obj:IsA("TextLabel") or obj:IsA("TextButton")) and (obj.Text or "") or "")

if obj:IsA("GuiButton") and (
string.find(nLower, "reel", 1, true)
or string.find(nLower, "tap", 1, true)
or string.find(nLower, "btn", 1, true)
or string.find(nLower, "action", 1, true)
) then
if not containsDangerText(obj) then
reelBtn = obj
end
elseif (obj:IsA("TextLabel") or obj:IsA("TextButton")) and string.find(txtUpper, "REEL", 1, true) then
local btn = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
if btn and not containsDangerText(btn) then
reelBtn = btn
end
end

-- เข็มสีขาวแนวตั้ง (กว้างแคบ สูงกว่าความกว้าง)
if obj:IsA("Frame") or obj:IsA("ImageLabel") then
local c = obj.BackgroundColor3
local sz = obj.AbsoluteSize
local isWhiteNeedle = (c.R > 0.85 and c.G > 0.85 and c.B > 0.85 and obj.BackgroundTransparency < 0.3 and sz.X >= 3 and sz.X <= 22 and sz.Y >= 24)
local isNamedNeedle = (
string.find(nLower, "needle", 1, true)
or string.find(nLower, "pointer", 1, true)
or string.find(nLower, "marker", 1, true)
or string.find(nLower, "cursor", 1, true)
or string.find(nLower, "indicator", 1, true)
) and (sz.X <= 28 and sz.Y >= 16)

if isWhiteNeedle or isNamedNeedle then
needle = obj
end

-- แถบสีทอง (PERFECT) อยู่ด้านในโซนเขียว
if sz.X >= 4 and sz.X <= 180 and sz.Y >= 14 and obj.BackgroundTransparency < 0.4 then
local isGoldColor = (c.R > 0.72 and c.G > 0.55 and c.B < 0.35)
local isGoldName = string.find(nLower, "gold", 1, true) ~= nil
or string.find(nLower, "perfect", 1, true) ~= nil
or string.find(nLower, "sweet", 1, true) ~= nil
or string.find(nLower, "center", 1, true) ~= nil

if isGoldColor or isGoldName then
goldZone = obj
elseif (c.G > 0.52 and c.R < 0.48) or string.find(nLower, "green", 1, true) or string.find(nLower, "zone", 1, true) then
if sz.X <= 360 then
greenZone = obj
end
end
end
end
end
end
end

-- ค้นหาปุ่ม REEL! สีเขียวด้านล่าง Body ด้วย (เผื่ออยู่นอก Area)
if not reelBtn then
for _, obj in ipairs(mg:GetDescendants()) do
if obj:IsA("GuiButton") and obj.Visible and not containsDangerText(obj) then
local nLower = string.lower(obj.Name)
if string.find(nLower, "reel", 1, true) then
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
end

if not isReelMode and not (needle and (goldZone or greenZone)) then
lastNeedleX = nil
return false
end

if needle then
local nCenter = needle.AbsolutePosition.X + (needle.AbsoluteSize.X * 0.5)
local velX = lastNeedleX and (nCenter - lastNeedleX) or 0
lastNeedleX = nCenter

-- คาดการณ์ตำแหน่งเข็มล่วงหน้า ~0.6 เฟรม เพื่อชดเชยจังหวะส่งคำสั่งคลิก
local predictedCenter = nCenter + (velX * 0.6)

local targetMin, targetMax
if goldZone then
targetMin = goldZone.AbsolutePosition.X + 1
targetMax = goldZone.AbsolutePosition.X + goldZone.AbsoluteSize.X - 1
elseif greenZone then
-- ถ้าหาแถบสีทองไม่เจอ ให้บีบเป้าเหลือเฉพาะ 28% ตรงกลางของแถบเขียว
local gLeft = greenZone.AbsolutePosition.X
local gWidth = greenZone.AbsoluteSize.X
targetMin = gLeft + (gWidth * 0.36)
targetMax = gLeft + (gWidth * 0.64)
end

if targetMin and targetMax and (tick() - lastActionTime >= 0.16) then
if (nCenter >= targetMin and nCenter <= targetMax) or (predictedCenter >= targetMin and predictedCenter <= targetMax) then
lastActionTime = tick()
if reelBtn then
instantClickMiniGame(reelBtn)
end
instantPressKey(Enum.KeyCode.Space)
end
end
end

return true
end

local lastChaosLane = nil
local lastChaosLaneTime = 0
local lastMemTurnState = false

-- [2] Fish Chaos ปรับกันกดย้ำเลนเดิมซ้ำ และเน้นเป้าที่ใกล้โซนรับด้านล่าง
local function tryPlayFishChaosGame(mg, allText)
local isChaos = string.find(allText, "FISH CHAOS", 1, true) ~= nil
or string.find(allText, "ความโกลาหลของปลา", 1, true) ~= nil
or string.find(allText, "GOLDEN +30", 1, true) ~= nil
or string.find(allText, "BOOT -15", 1, true) ~= nil

if not isChaos then
lastChaosLane = nil
return false
end

if tick() - lastActionTime < 0.065 then
return true
end

local areas = getActiveMiniGameAreas(mg)
local laneKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }
local laneCenters = {}
local laneButtons = {}
local laneBottomY = nil

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

local laneCount = 0
for idx = 1, 5 do
if laneCenters[idx] then
laneCount += 1
end
end

if laneCount < 3 and #areas > 0 then
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

local bestLane = nil
local bestTarget = nil
local bestScore = -9999

for _, area in ipairs(areas) do
local aPos = area.AbsolutePosition
local aSz = area.AbsoluteSize
local playTopY = aPos.Y + 12
local playBotY = (laneBottomY or (aPos.Y + aSz.Y * 0.85)) - 8

for _, obj in ipairs(area:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local nLower = string.lower(obj.Name)
local isBootName = string.find(nLower, "boot", 1, true)
or string.find(nLower, "shoe", 1, true)
or string.find(nLower, "รองเท้า", 1, true)
or string.find(nLower, "บูต", 1, true)
local isUiChrome = string.find(nLower, "lane", 1, true)
or string.find(nLower, "slot", 1, true)
or string.find(nLower, "bg", 1, true)
or string.find(nLower, "pond", 1, true)

local sz = obj.AbsoluteSize
if not isBootName and not isUiChrome and sz.X >= 18 and sz.X <= 150 and sz.Y >= 18 and sz.Y <= 150 then
local pos = obj.AbsolutePosition
local cx = pos.X + (sz.X * 0.5)
local cy = pos.Y + (sz.Y * 0.5)

if cy >= playTopY and cy <= playBotY then
local col = obj.BackgroundColor3
if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
if obj.ImageTransparency < 0.85 then
col = obj.ImageColor3
end
end

local isBrownBoot = (col.R > 0.34 and col.G > 0.13 and col.G < 0.54 and col.B < 0.30 and col.R > col.G * 1.22)

if not isBrownBoot then
local matchedLane = nil
local minDist = 44
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
local isGold = (col.R > 0.78 and col.G > 0.65 and col.B < 0.35)
or (string.find(nLower, "gold", 1, true) ~= nil)
local progress = math.clamp((cy - playTopY) / math.max(1, (playBotY - playTopY)), 0, 1)
local repeatPenalty = (matchedLane == lastChaosLane and (tick() - lastChaosLaneTime) < 0.22) and 35 or 0
local score = (progress * 50) + (isGold and 25 or 0) - (minDist * 0.35) - repeatPenalty
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
instantClickMiniGame(laneButtons[bestLane])
elseif bestTarget then
instantClickMiniGame(bestTarget)
end
instantPressKey(laneKeys[bestLane])
end

return true
end

-- [3] Bait Memory จับไฮไลต์ให้ครอบคลุมขึ้นและล้างคิวเมื่อเริ่มรอบใหม่
local function tryPlayMemoryBaitGame(mg, allText)
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

local isMemoryMode = (next(choices) ~= nil)
or string.find(allText, "BAIT MEMORY", 1, true) ~= nil
or string.find(allText, "ความจำเหยื่อ", 1, true) ~= nil

if not isMemoryMode then
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
local brightness = (bg.R + bg.G + bg.B) / 3
if brightness > 0.85 or c.BackgroundTransparency < 0.05 then
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
elseif d:IsA("GuiObject") and d.Visible and string.find(string.lower(d.Name), "glow", 1, true) then
highlighted = true
break
end
end
end

if not highlighted and rootBtn then
for _, d in ipairs(rootBtn:GetDescendants()) do
if d:IsA("UIStroke") and d.Enabled and d.Thickness >= 2.0 then
highlighted = true
break
elseif d:IsA("UIScale") and d.Scale > 1.03 then
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
print("[MemoryBait] จำลำดับ:", litIdx, "(" .. orderNames[litIdx] .. ") | คิวรวม:", #sequenceQueue)
elseif not litIdx then
lastHighlightedKey = nil
end
return true
end

if tick() - lastActionTime < 0.06 then
return true
end

if #sequenceQueue > 0 then
local nextIdx = table.remove(sequenceQueue, 1)
local targetItem = choices[nextIdx]
if targetItem and targetItem.target then
lastActionTime = tick()
print("[MemoryBait] ถึงตาคุณ -> กดทันที:", nextIdx, "(" .. orderNames[nextIdx] .. ")")
instantClickMiniGame(targetItem.target)
instantPressKey(memKeys[nextIdx])
end
end

return true
end

local function stepMiniGame()
local mg = getMiniGameGui()
if not mg then
sequenceQueue = {}
lastHighlightedKey = nil
return
end

-- กดปุ่ม PlayButton / เริ่มเล่น ก่อนเสมอสำหรับทุกมินิเกม
if tryClickPlayInMiniGame(mg) then
return
end

local allText = getHeaderTitle(mg)

if tryPlayReelGame(mg, allText) then
return
end

if tryPlayFishChaosGame(mg, allText) then
return
end

if tryPlayMemoryBaitGame(mg, allText) then
return
end
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
if Config and Config.AutoFishCollect then
if Cat1Module and Cat1Module.step then
pcall(Cat1Module.step, Config)
end
elseif Cat1Module and Cat1Module.reset then
pcall(Cat1Module.reset)
end
task.wait(0.1)
end
end)

print("[Net a Fish] โหลดระบบมินิเกมโหมดตอบสนองทันที (Zero-Delay Heartbeat + Thai/EN) เรียบร้อย")
end

return GameModule