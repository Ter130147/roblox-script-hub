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

-- [1] REEL! / ม้วนที่สมบูรณ์แบบ ตอบสนองทันทีเมื่อเข็มเข้าโซนเขียว
local function tryPlayReelGame(mg, allText)
local areas = getActiveMiniGameAreas(mg)
local isReelMode = string.find(allText, "REEL", 1, true) ~= nil
or string.find(allText, "ม้วนที่สมบูรณ์แบบ", 1, true) ~= nil
or string.find(allText, "โซนสีเขียว", 1, true) ~= nil

local reelBtn = nil
local greenZone = nil
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
or string.find(nLower, "stop", 1, true)
) then
if not containsDangerText(obj) then
reelBtn = obj
end
elseif (obj:IsA("TextLabel") or obj:IsA("TextButton")) and (
string.find(txtUpper, "REEL", 1, true)
or string.find(txtUpper, "ม้วน", 1, true)
or string.find(txtUpper, "ดึง", 1, true)
or string.find(txtUpper, "หยุด", 1, true)
) then
local btn = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
if btn and not containsDangerText(btn) then
reelBtn = btn
end
end

if string.find(nLower, "needle", 1, true)
or string.find(nLower, "pointer", 1, true)
or string.find(nLower, "marker", 1, true)
or string.find(nLower, "cursor", 1, true)
or string.find(nLower, "indicator", 1, true)
or string.find(nLower, "bar", 1, true)
then
if obj.AbsoluteSize.X <= 36 and obj.AbsoluteSize.Y >= 10 then
needle = obj
end
end

if obj:IsA("Frame") or obj:IsA("ImageLabel") then
local c = obj.BackgroundColor3
if (c.G > 0.52 and c.R < 0.48)
or string.find(nLower, "green", 1, true)
or string.find(nLower, "zone", 1, true)
or string.find(nLower, "target", 1, true)
or string.find(nLower, "sweet", 1, true)
then
if obj.AbsoluteSize.X >= 10 and obj.AbsoluteSize.X <= 420 then
greenZone = obj
end
end
end
end
end
end

if not isReelMode and not (reelBtn and greenZone) then
return false
end

if tick() - lastActionTime < 0.045 then
return true
end

if needle and greenZone then
local nCenter = needle.AbsolutePosition.X + (needle.AbsoluteSize.X * 0.5)
local zMin = greenZone.AbsolutePosition.X - 3
local zMax = greenZone.AbsolutePosition.X + greenZone.AbsoluteSize.X + 3
if nCenter >= zMin and nCenter <= zMax then
lastActionTime = tick()
if reelBtn then
instantClickMiniGame(reelBtn)
end
instantPressKey(Enum.KeyCode.Space)
end
elseif reelBtn then
lastActionTime = tick()
instantClickMiniGame(reelBtn)
end

return true
end

-- [2] Fish Chaos จับตำแหน่งตามเลน 1-5 และหลีกเลี่ยงสีบูต (น้ำตาล)
local function tryPlayFishChaosGame(mg, allText)
local isChaos = string.find(allText, "FISH CHAOS", 1, true) ~= nil
or string.find(allText, "ความโกลาหลของปลา", 1, true) ~= nil
or string.find(allText, "GOLDEN +30", 1, true) ~= nil
or string.find(allText, "BOOT -15", 1, true) ~= nil

if not isChaos then
return false
end

if tick() - lastActionTime < 0.08 then
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
local playBotY = (laneBottomY or (aPos.Y + aSz.Y * 0.85)) - 10

for _, obj in ipairs(area:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local nLower = string.lower(obj.Name)
local isBootName = string.find(nLower, "boot", 1, true)
or string.find(nLower, "shoe", 1, true)
or string.find(nLower, "รองเท้า", 1, true)
or string.find(nLower, "บูต", 1, true)

local sz = obj.AbsoluteSize
if not isBootName and sz.X >= 18 and sz.X <= 150 and sz.Y >= 18 and sz.Y <= 150 then
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

local isBrownBoot = (col.R > 0.35 and col.G > 0.14 and col.G < 0.52 and col.B < 0.28 and col.R > col.G * 1.25)

if not isBrownBoot then
local matchedLane = nil
local minDist = 48
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
local score = (progress * 40) + (isGold and 25 or 0) - (minDist * 0.35)
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
if laneButtons[bestLane] then
instantClickMiniGame(laneButtons[bestLane])
elseif bestTarget then
instantClickMiniGame(bestTarget)
end
instantPressKey(laneKeys[bestLane])
end

return true
end

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
return false
end

local yourTurn = string.find(allText, "YOUR TURN", 1, true) ~= nil
or string.find(allText, "REPEAT THE ORDER", 1, true) ~= nil
or string.find(allText, "ถึงตาคุณ", 1, true) ~= nil

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
if brightness > 0.88 or c.BackgroundTransparency < 0.05 then
highlighted = true
end
end

if not highlighted then
for _, d in ipairs(c:GetDescendants()) do
if d:IsA("UIStroke") and d.Enabled and d.Thickness >= 2.2 then
highlighted = true
break
elseif d:IsA("UIScale") and d.Scale > 1.04 then
highlighted = true
break
end
end
end

if not highlighted and rootBtn then
for _, d in ipairs(rootBtn:GetDescendants()) do
if d:IsA("UIStroke") and d.Enabled and d.Thickness >= 2.2 then
highlighted = true
break
elseif d:IsA("UIScale") and d.Scale > 1.04 then
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

if tick() - lastActionTime < 0.055 then
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