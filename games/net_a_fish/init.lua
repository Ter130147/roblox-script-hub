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
local sequenceQueue = {}
local lastHighlightedKey = nil
local lastMemTurnState = false

local lastPadSweepStartTime = 0
local lastPadStepTime = 0
local sweepActive = false
local sweepTargets = {}
local sweepIndex = 0
local lastCollectMoneyTime = 0

local lastCatchStepTime = 0
local lastReelFullTime = 0
local lastShootMegalodonTime = 0
local lastShootBloopTime = 0
local lastRebirthTime = 0

local Cat1Module = nil
pcall(function()
	local url = "https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/games/net_a_fish/cat1_fishing_collect.lua?cb=" .. tostring(os.clock()) .. "_" .. tostring(math.random(10000, 99999))
	local fn = loadstring(game:HttpGet(url, true))
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

local function naturalPedestalSort(a, b)
	local aNum = tonumber(tostring(a.pedName):match("(%d+)$")) or 999999
	local bNum = tonumber(tostring(b.pedName):match("(%d+)$")) or 999999
	if aNum ~= bNum then
		return aNum < bNum
	end
	return tostring(a.pedName) < tostring(b.pedName)
end

local function isOwnedBase(baseModel)
	if not (baseModel and LocalPlayer) then
		return false
	end
	local myName = string.lower(LocalPlayer.Name)
	local myDisp = string.lower(LocalPlayer.DisplayName or "")
	local myId = tostring(LocalPlayer.UserId)

	for _, attrVal in pairs(baseModel:GetAttributes()) do
		local s = string.lower(tostring(attrVal))
		if s == myName or (myDisp ~= "" and s == myDisp) or s == myId then
			return true
		end
	end

	for _, d in ipairs(baseModel:GetDescendants()) do
		if d:IsA("StringValue") or d:IsA("IntValue") or d:IsA("NumberValue") then
			local v = string.lower(tostring(d.Value))
			if v == myName or (myDisp ~= "" and v == myDisp) or v == myId then
				return true
			end
		elseif d:IsA("ObjectValue") and d.Value == LocalPlayer then
			return true
		elseif d:IsA("TextLabel") and d.Visible then
			local t = string.lower(tostring(d.Text or ""))
			if string.find(t, myName, 1, true) or (myDisp ~= "" and string.find(t, myDisp, 1, true)) then
				return true
			end
		end
	end

	return false
end

local function findMyBaseContainer(rootPos)
	local mapObj = workspace:FindFirstChild("Map")
	local basesObj = mapObj and mapObj:FindFirstChild("Bases")
	if not basesObj then
		return nil
	end

	for _, base in ipairs(basesObj:GetChildren()) do
		if isOwnedBase(base) then
			return base
		end
	end

	local nearestBase = nil
	local nearestDist = math.huge
	for _, base in ipairs(basesObj:GetChildren()) do
		local peds = base:FindFirstChild("Pedestals")
		if peds then
			local ok, pivot = pcall(function()
				return peds:GetPivot()
			end)
			if ok and pivot then
				local d = (pivot.Position - rootPos).Magnitude
				if d < nearestDist then
					nearestDist = d
					nearestBase = base
				end
			end
		end
	end

	return nearestBase
end

local function getPedestalTargets(rootPos)
	local targets = {}
	local seen = {}
	local myBase = findMyBaseContainer(rootPos)
	if not myBase then
		return targets
	end

	local pedsFolder = myBase:FindFirstChild("Pedestals") or myBase
	for _, d in ipairs(pedsFolder:GetDescendants()) do
		if d:IsA("TextLabel") and d.Visible then
			local txt = tostring(d.Text or "")
			if string.find(string.lower(txt), "collect", 1, true) or string.find(txt, "$", 1, true) then
				local part, collectFolder = findCollectPadPart(d)
				if part and not seen[part] then
					seen[part] = true
					local pedModel = collectFolder and collectFolder.Parent or part.Parent
					table.insert(targets, {
						part = part,
						collectFolder = collectFolder,
						pedName = pedModel and pedModel.Name or part.Name,
						pos = part.Position,
						halfH = part.Size.Y * 0.5,
					})
				end
			end
		end
	end

	table.sort(targets, naturalPedestalSort)
	return targets
end

local function stepAutoPadTp(cfg)
	if not (cfg and cfg.AutoPadTp) then
		sweepActive = false
		sweepIndex = 0
		return
	end

	local interval = tonumber(cfg.CollectIntervalSec) or 30
	interval = math.max(1, interval)
	local root = getRootPart()
	if not root then
		return
	end

	if not sweepActive then
		if (tick() - lastPadSweepStartTime) >= interval then
			local list = getPedestalTargets(root.Position)
			if #list > 0 then
				sweepTargets = list
				sweepIndex = 1
				sweepActive = true
				lastPadSweepStartTime = tick()
				lastPadStepTime = 0
			end
		end
	end

	if sweepActive then
		if (tick() - lastPadStepTime) >= 0.18 then
			local item = sweepTargets[sweepIndex]
			if item and item.part and item.part.Parent then
				lastPadStepTime = tick()
				local targetPos = item.pos + Vector3.new(0, (item.halfH or 1) + 3.2, 0)
				pcall(function()
					root.CFrame = CFrame.new(targetPos, targetPos + root.CFrame.LookVector)
				end)
			end
			sweepIndex += 1
			if sweepIndex > #sweepTargets then
				sweepActive = false
				sweepIndex = 0
			end
		end
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
		if (item.pos - root.Position).Magnitude <= 65 then
			if collectRemote and collectRemote:IsA("RemoteEvent") then
				pcall(function() collectRemote:FireServer(item.collectFolder or item.part) end)
				pcall(function() collectRemote:FireServer(item.pedName) end)
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
		pcall(function() collectRemote:FireServer() end)
	end
end

local function containsDangerText(container)
	if not container then
		return true
	end
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local t = string.lower(d.Text or "")
			if string.find(t, "robux", 1, true) or string.find(t, "r$", 1, true) or string.find(t, "buy", 1, true) or string.find(t, "skip", 1, true) then
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
	local btn = guiObj:IsA("GuiButton") and guiObj or guiObj:FindFirstAncestorWhichIsA("GuiButton") or guiObj:FindFirstChildWhichIsA("GuiButton", true) or guiObj
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

local function stepAutoCatch(cfg)
	if not (cfg and cfg.AutoCatch) then
		return
	end
	if tick() - lastCatchStepTime < 0.35 then
		return
	end
	lastCatchStepTime = tick()

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local catchReady = remotes:FindFirstChild("CatchReady")
		local resolveCatch = remotes:FindFirstChild("ResolveCatch")
		if catchReady and catchReady:IsA("RemoteEvent") then
			pcall(function() catchReady:FireServer() end)
		end
		if resolveCatch and resolveCatch:IsA("RemoteEvent") then
			pcall(function() resolveCatch:FireServer() end)
		end
	end

	if Cat1Module and Cat1Module.step then
		pcall(Cat1Module.step, {
			AutoCatch = true,
			AutoFishCollect = true,
			AutoReelFull = false,
		})
	end
end

local function isNetFullInGui()
	local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then
		return false
	end
	for _, obj in ipairs(pg:GetDescendants()) do
		if obj.Name ~= "TerHubProUI" and (obj:IsA("TextLabel") or obj:IsA("TextButton")) and obj.Visible then
			local txt = tostring(obj.Text or "")
			local low = string.lower(txt)
			if string.find(txt, "เต็ม", 1, true) or string.find(low, "full", 1, true) then
				return true
			end
			local curNum, maxNum = txt:match("(%d+)%s*/%s*(%d+)")
			if curNum and maxNum and tonumber(curNum) >= tonumber(maxNum) and tonumber(maxNum) > 0 then
				return true
			end
		end
	end
	return false
end

local function stepAutoReelFull(cfg)
	if not (cfg and cfg.AutoReelFull) then
		return
	end
	if tick() - lastReelFullTime < 0.6 then
		return
	end
	if not isNetFullInGui() then
		return
	end
	lastReelFullTime = tick()

	local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		for _, obj in ipairs(pg:GetDescendants()) do
			if obj.Name ~= "TerHubProUI" and obj:IsA("GuiButton") and obj.Visible and not containsDangerText(obj) then
				local nLow = string.lower(obj.Name)
				local txt = obj:IsA("TextButton") and tostring(obj.Text or "") or ""
				local low = string.lower(txt)
				if string.find(txt, "อวน", 1, true) or string.find(txt, "ดึง", 1, true) or string.find(low, "reel", 1, true) or string.find(nLow, "reel", 1, true) then
					fireGuiButton(obj)
					break
				end
			end
		end
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		local haul = remotes:FindFirstChild("BoatHaul")
		if haul and haul:IsA("RemoteEvent") then
			pcall(function() haul:FireServer() end)
		end
	end
end

local function findBossTargetPos(keyword)
	local root = getRootPart()
	if not root then
		return nil
	end
	local keyLow = string.lower(keyword)
	local bestPos = nil
	local bestDist = math.huge

	for _, obj in ipairs(workspace:GetDescendants()) do
		local nLow = string.lower(obj.Name)
		if string.find(nLow, keyLow, 1, true) then
			local pos = nil
			if obj:IsA("BasePart") then
				pos = obj.Position
			elseif obj:IsA("Model") then
				local ok, pivot = pcall(function() return obj:GetPivot() end)
				if ok and pivot then
					pos = pivot.Position
				end
			end
			if pos then
				local d = (pos - root.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestPos = pos
				end
			end
		end
	end

	return bestPos
end

local function aimAndFireAtTarget(targetPos)
	local root = getRootPart()
	if not (root and targetPos) then
		return
	end
	pcall(function()
		local lookAt = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
		root.CFrame = CFrame.lookAt(root.Position, lookAt)
	end)
	local cam = workspace.CurrentCamera
	if cam then
		pcall(function()
			cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
		end)
		local vpPos, onScreen = cam:WorldToViewportPoint(targetPos)
		if onScreen and vpPos then
			pcall(function()
				VirtualInputManager:SendMouseMoveEvent(vpPos.X, vpPos.Y, game)
				VirtualInputManager:SendMouseButtonEvent(vpPos.X, vpPos.Y, 0, true, game, 0)
				task.wait(0.03)
				VirtualInputManager:SendMouseButtonEvent(vpPos.X, vpPos.Y, 0, false, game, 0)
			end)
		end
	end
	tapKey(Enum.KeyCode.F)
end

local function stepAutoShootMegalodon(cfg)
	if not (cfg and cfg.AutoShootMegalodon) then
		return
	end
	if tick() - lastShootMegalodonTime < 0.22 then
		return
	end
	local targetPos = findBossTargetPos("megalodon")
	if targetPos then
		lastShootMegalodonTime = tick()
		aimAndFireAtTarget(targetPos)
	end
end

local function stepAutoShootBloop(cfg)
	if not (cfg and cfg.AutoShootBloop) then
		return
	end
	if tick() - lastShootBloopTime < 0.22 then
		return
	end
	local targetPos = findBossTargetPos("bloop")
	if targetPos then
		lastShootBloopTime = tick()
		aimAndFireAtTarget(targetPos)
	end
end

local function stepAutoRebirth(cfg)
	if not (cfg and cfg.AutoRebirth) then
		return
	end
	if tick() - lastRebirthTime < 3.0 then
		return
	end
	lastRebirthTime = tick()

	local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		for _, obj in ipairs(pg:GetDescendants()) do
			if obj.Name ~= "TerHubProUI" and obj:IsA("GuiButton") and obj.Visible and not containsDangerText(obj) then
				local nLow = string.lower(obj.Name)
				local txt = obj:IsA("TextButton") and tostring(obj.Text or "") or ""
				local low = string.lower(txt)
				if string.find(txt, "รีเบิร์ธ", 1, true) or string.find(low, "rebirth", 1, true) or string.find(nLow, "rebirth", 1, true) then
					fireGuiButton(obj)
					break
				end
			end
		end
	end

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		for _, r in ipairs(remotes:GetDescendants()) do
			if string.find(string.lower(r.Name), "rebirth", 1, true) then
				if r:IsA("RemoteEvent") then
					pcall(function() r:FireServer() end)
				elseif r:IsA("RemoteFunction") then
					pcall(function() r:InvokeServer() end)
				end
			end
		end
	end
end

local function scanGameStructure()
	print("==========================================================")
	print("[DeepScan] REMOTES & BINDABLES")
	for _, service in ipairs({ ReplicatedStorage, workspace }) do
		for _, obj in ipairs(service:GetDescendants()) do
			if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("BindableEvent") or obj:IsA("BindableFunction") then
				print(string.format("  - [%s] %s", obj.ClassName, obj:GetFullName()))
			end
		end
	end
	print("==========================================================")
end

local function getMiniGameGui()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	local mg = pg and pg:FindFirstChild("MiniGameUI")
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
	local res = mg:FindFirstChild("Window") and mg.Window:FindFirstChild("Body") and mg.Window.Body:FindFirstChild("Result")
	return (res and res:IsA("GuiObject") and res.Visible) == true
end

local function isInActiveGameplay(mg, allText)
	local areas = getActiveMiniGameAreas(mg)
	for _, area in ipairs(areas) do
		for _, d in ipairs(area:GetDescendants()) do
			if d:IsA("GuiObject") and d.Visible then
				local nLow = string.lower(d.Name)
				if string.find(nLow, "bait", 1, true) or string.find(nLow, "spot", 1, true) or string.find(nLow, "lane", 1, true) or string.find(nLow, "needle", 1, true) then
					return true
				end
			end
		end
	end
	return string.find(allText, "YOUR TURN", 1, true) ~= nil or string.find(allText, "SPACE OR CLICK", 1, true) ~= nil or string.find(allText, "CLICK OR KEYS 1-5", 1, true) ~= nil
end

local function tryClickStartButton(mg)
	if isResultScreenVisible(mg) or (tick() - lastAcceptTime < 0.7) then
		return false
	end
	for _, obj in ipairs(mg:GetDescendants()) do
		if obj:IsA("GuiButton") and obj.Visible and obj.Name ~= "Backdrop" then
			local nLow = string.lower(obj.Name)
			local txt = (obj:IsA("TextButton") and obj.Text) or ""
			if txt == "" then
				for _, ch in ipairs(obj:GetDescendants()) do
					if ch:IsA("TextLabel") and ch.Visible and (ch.Text or "") ~= "" then
						txt = ch.Text
						break
					end
				end
			end
			local low = string.lower(txt)
			local isBanner = string.find(low, "play for a medal", 1, true) ~= nil or string.find(low, "the better you do", 1, true) ~= nil
			local isStart = (not isBanner) and (string.find(nLow, "play", 1, true) ~= nil or string.find(nLow, "start", 1, true) ~= nil or (string.find(low, "play", 1, true) ~= nil and #txt <= 48))
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
local isReel = string.find(allText, "REEL", 1, true) ~= nil or string.find(allText, "GOLD IS PERFECT", 1, true) ~= nil
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
if (c.R > 0.85 and c.G > 0.85 and c.B > 0.85 and sz.X >= 3 and sz.X <= 24 and sz.Y >= 20) or string.find(nLow, "needle", 1, true) then
needle = obj
end
if sz.X >= 4 and sz.X <= 180 and sz.Y >= 14 then
if (c.R > 0.72 and c.G > 0.55 and c.B < 0.35) or string.find(nLow, "gold", 1, true) or string.find(nLow, "perfect", 1, true) then
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
if obj:IsA("GuiButton") and obj.Visible and not containsDangerText(obj) and string.find(string.lower(obj.Name), "reel", 1, true) then
reelBtn = obj
break
end
end
if needle and (tick() - lastReelPressTime >= 0.18) then
local nCenter = needle.AbsolutePosition.X + (needle.AbsoluteSize.X * 0.5)
local velX = lastNeedleX and math.clamp(nCenter - lastNeedleX, -40, 40) or 0
lastNeedleX = nCenter
local predCenter = nCenter + (velX * 0.25)
local zMin, zMax
if goldZone then
zMin = goldZone.AbsolutePosition.X + 1
zMax = goldZone.AbsolutePosition.X + goldZone.AbsoluteSize.X - 1
elseif greenZone then
zMin = greenZone.AbsolutePosition.X + (greenZone.AbsoluteSize.X * 0.36)
zMax = greenZone.AbsolutePosition.X + (greenZone.AbsoluteSize.X * 0.64)
end
if zMin and zMax and ((nCenter >= zMin and nCenter <= zMax) or (predCenter >= zMin and predCenter <= zMax)) then
lastReelPressTime = tick()
lastActionTime = tick()
if reelBtn then
fireGuiButton(reelBtn)
else
tapKey(Enum.KeyCode.Space)
end
end
end
return true
end

local function runFishChaosMinigame(mg, allText)
local isChaos = string.find(allText, "FISH CHAOS", 1, true) ~= nil or string.find(allText, "GOLDEN +30", 1, true) ~= nil or string.find(allText, "BOOT -15", 1, true) ~= nil
if not isChaos then
lastChaosLane = nil
return false
end
if tick() - lastActionTime < 0.12 then
return true
end
local areas = getActiveMiniGameAreas(mg)
local laneKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five }
local laneCenters, laneButtons, laneBottomY = {}, {}, nil
for _, area in ipairs(areas) do
for _, obj in ipairs(area:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible then
local txt = (obj:IsA("TextLabel") or obj:IsA("TextButton")) and (obj.Text or "") or ""
local laneIdx = tonumber(txt:match("^%s*(.-)%s*$"))
if laneIdx and laneIdx >= 1 and laneIdx <= 5 then
laneCenters[laneIdx] = obj.AbsolutePosition.X + (obj.AbsoluteSize.X * 0.5)
laneBottomY = obj.AbsolutePosition.Y + (obj.AbsoluteSize.Y * 0.5)
local btn = obj:IsA("GuiButton") and obj or obj:FindFirstAncestorWhichIsA("GuiButton")
if btn and btn.Active then laneButtons[laneIdx] = btn end
end
end
end
end
if #areas > 0 then
local area = areas[1]
local aPos, aSz = area.AbsolutePosition, area.AbsoluteSize
if aSz.X > 100 and aSz.Y > 80 then
laneBottomY = laneBottomY or (aPos.Y + aSz.Y * 0.84)
for idx = 1, 5 do
if not laneCenters[idx] then
laneCenters[idx] = aPos.X + (aSz.X * ((idx - 0.5) / 5))
end
end
end
end
local bestLane, bestTarget, bestScore = nil, nil, -9999
for _, area in ipairs(areas) do
local aPos, aSz = area.AbsolutePosition, area.AbsoluteSize
local playTopY = aPos.Y + 8
local playBotY = (laneBottomY or (aPos.Y + aSz.Y * 0.85)) - 4
for _, obj in ipairs(area:GetDescendants()) do
if obj:IsA("GuiObject") and obj.Visible and not containsDangerText(obj) then
local nLow = string.lower(obj.Name)
local sz = obj.AbsoluteSize
local isBad = string.find(nLow, "boot", 1, true)
or string.find(nLow, "lane", 1, true)
or string.find(nLow, "trash", 1, true)
or string.find(nLow, "bomb", 1, true)
or string.find(nLow, "hazard", 1, true)
or string.find(nLow, "bad", 1, true)
if not isBad and sz.X >= 14 and sz.X <= 180 and sz.Y >= 14 and sz.Y <= 180 then
local cx = obj.AbsolutePosition.X + (sz.X * 0.5)
local cy = obj.AbsolutePosition.Y + (sz.Y * 0.5)
if cy >= playTopY and cy <= playBotY then
local matchedLane, minDist = nil, 56
for idx = 1, 5 do
local lx = laneCenters[idx]
if lx and math.abs(cx - lx) < minDist then
minDist = math.abs(cx - lx)
matchedLane = idx
end
end
if matchedLane then
local progress = math.clamp((cy - playTopY) / math.max(1, (playBotY - playTopY)), 0, 1)
local score = (progress * 45) - (minDist * 0.25)
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
if bestLane then
lastActionTime = tick()
lastChaosLane = bestLane
if laneButtons[bestLane] then
fireGuiButton(laneButtons[bestLane])
elseif bestTarget then
fireGuiButton(bestTarget)
else
tapKey(laneKeys[bestLane])
end
end
return true
end

local function runBaitMemoryMinigame(mg, allText)
local areas = getActiveMiniGameAreas(mg)
local choices = {}
local memKeys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
for _, area in ipairs(areas) do
for idx = 1, 4 do
local baitBtn = area:FindFirstChild("Bait" .. tostring(idx))
if baitBtn and baitBtn:IsA("GuiObject") and baitBtn.Visible then
local face = baitBtn:FindFirstChild("Face")
choices[idx] = { card = (face and face:IsA("GuiObject")) and face or baitBtn, target = baitBtn }
end
end
if next(choices) ~= nil then break end
end
local isMemory = (next(choices) ~= nil) or string.find(allText, "BAIT MEMORY", 1, true) ~= nil
if not isMemory then
lastMemTurnState = false
return false
end
local yourTurn = string.find(allText, "YOUR TURN", 1, true) ~= nil or string.find(allText, "REPEAT THE ORDER", 1, true) ~= nil
if yourTurn and not lastMemTurnState then
lastHighlightedKey = nil
elseif (not yourTurn) and lastMemTurnState and #sequenceQueue == 0 then
sequenceQueue = {}
lastHighlightedKey = nil
end
lastMemTurnState = yourTurn
local litIdx = nil
for idx = 1, 4 do
local item = choices[idx]
local c = item and item.card
if c and c.Visible then
local bg = c.BackgroundColor3
local brightness = (bg.R + bg.G + bg.B) / 3
local isLit = brightness > 0.88 or (c:IsA("ImageLabel") and ((c.ImageColor3.R + c.ImageColor3.G + c.ImageColor3.B) / 3) > 0.92 and c.ImageTransparency < 0.15)
if isLit then
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
if tick() - lastActionTime >= 0.14 and #sequenceQueue > 0 then
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
	if not isInActiveGameplay(mg, allText) and tryClickStartButton(mg) then return end
	if runReelMinigame(mg, allText) then return end
	if runFishChaosMinigame(mg, allText) then return end
	if runBaitMemoryMinigame(mg, allText) then return end
	tryClickStartButton(mg)
end

local lastEquipBestTime = 0
local lastFuseAllTime = 0
local lastSellFishTime = 0
local lastBuyPotionTime = 0
local lastUsePotionTime = 0

local function clickGuiByKeywords(keywords)
local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
if not pg then
return false
end
for _, obj in ipairs(pg:GetDescendants()) do
if obj.Name ~= "TerHubProUI" and obj:IsA("GuiButton") and obj.Visible and not containsDangerText(obj) then
local nLow = string.lower(obj.Name)
local txt = obj:IsA("TextButton") and tostring(obj.Text or "") or ""
if txt == "" then
for _, ch in ipairs(obj:GetDescendants()) do
if ch:IsA("TextLabel") and ch.Visible and (ch.Text or "") ~= "" then
txt = ch.Text
break
end
end
end
local low = string.lower(txt)
for _, kw in ipairs(keywords) do
local kLow = string.lower(kw)
if string.find(txt, kw, 1, true) or string.find(low, kLow, 1, true) or string.find(nLow, kLow, 1, true) then
fireGuiButton(obj)
return true
end
end
end
end
return false
end

local function stepAutoEquipBestFish(cfg)
if not (cfg and cfg.AutoEquipBestFish) then
return
end
if tick() - lastEquipBestTime < 2.0 then
return
end
lastEquipBestTime = tick()

if clickGuiByKeywords({ "Equip Best", "Best Fish", "ใส่ปลาที่ดีที่สุด", "ดีที่สุด" }) then
return
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
for _, r in ipairs(remotes:GetDescendants()) do
local rLow = string.lower(r.Name)
if string.find(rLow, "equipbest", 1, true) or (string.find(rLow, "equip", 1, true) and string.find(rLow, "best", 1, true)) then
if r:IsA("RemoteEvent") then
pcall(function() r:FireServer() end)
elseif r:IsA("RemoteFunction") then
pcall(function() r:InvokeServer() end)
end
end
end
end
end

local function stepAutoFuseAll(cfg)
if not (cfg and cfg.AutoFuseAll) then
return
end
if tick() - lastFuseAllTime < 2.5 then
return
end
lastFuseAllTime = tick()

if clickGuiByKeywords({ "Fuse All", "ฟิวส์ทั้งหมด", "Fuse" }) then
return
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if remotes then
for _, r in ipairs(remotes:GetDescendants()) do
local rLow = string.lower(r.Name)
if string.find(rLow, "fuse", 1, true) then
if r:IsA("RemoteEvent") then
pcall(function() r:FireServer() end)
elseif r:IsA("RemoteFunction") then
pcall(function() r:InvokeServer() end)
end
end
end
end
end

local function stepAutoSellFish(cfg)
if not (cfg and cfg.AutoSellFish) then
return
end
local interval = tonumber(cfg.SellIntervalSec) or 30
interval = math.max(2, interval)
if (tick() - lastSellFishTime) < interval then
return
end
lastSellFishTime = tick()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local sellRemote = remotes and remotes:FindFirstChild("SellFish")
if sellRemote then
if sellRemote:IsA("RemoteEvent") then
pcall(function() sellRemote:FireServer() end)
elseif sellRemote:IsA("RemoteFunction") then
pcall(function() sellRemote:InvokeServer() end)
end
return
end

clickGuiByKeywords({ "Sell All", "ขายทั้งหมด", "ขายปลา", "Sell" })
end

local function stepAutoBuyPotions(cfg)
if not (cfg and cfg.AutoBuyPotions) then
return
end
if tick() - lastBuyPotionTime < 3.0 then
return
end
lastBuyPotionTime = tick()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local potRemote = remotes and remotes:FindFirstChild("Potions")
if potRemote then
if potRemote:IsA("RemoteFunction") then
pcall(function() potRemote:InvokeServer("BuyAll") end)
pcall(function() potRemote:InvokeServer("Buy") end)
elseif potRemote:IsA("RemoteEvent") then
pcall(function() potRemote:FireServer("BuyAll") end)
pcall(function() potRemote:FireServer("Buy") end)
end
end

clickGuiByKeywords({ "Buy Potion", "ซื้อยา" })
end

local function stepAutoUsePotions(cfg)
if not (cfg and cfg.AutoUsePotions) then
return
end
if tick() - lastUsePotionTime < 3.0 then
return
end
lastUsePotionTime = tick()

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local potRemote = remotes and remotes:FindFirstChild("Potions")
if potRemote then
if potRemote:IsA("RemoteFunction") then
pcall(function() potRemote:InvokeServer("UseAll") end)
pcall(function() potRemote:InvokeServer("Use") end)
elseif potRemote:IsA("RemoteEvent") then
pcall(function() potRemote:FireServer("UseAll") end)
pcall(function() potRemote:FireServer("Use") end)
end
end

clickGuiByKeywords({ "Use Potion", "ใช้ยา" })
end

function GameModule.init(Config, Utils)
	if started then return end
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
				if Config.AutoCatch then pcall(stepAutoCatch, Config) end
				if Config.AutoReelFull then pcall(stepAutoReelFull, Config) end
				if Config.AutoPadTp then pcall(stepAutoPadTp, Config) end
				if Config.AutoCollectMoney then pcall(stepAutoCollectMoney, Config) end
				if Config.AutoShootMegalodon then pcall(stepAutoShootMegalodon, Config) end
				if Config.AutoShootBloop then pcall(stepAutoShootBloop, Config) end
				if Config.AutoRebirth then pcall(stepAutoRebirth, Config) end
if Config.AutoEquipBestFish then pcall(stepAutoEquipBestFish, Config) end
if Config.AutoFuseAll then pcall(stepAutoFuseAll, Config) end
if Config.AutoSellFish then pcall(stepAutoSellFish, Config) end
if Config.AutoBuyPotions then pcall(stepAutoBuyPotions, Config) end
if Config.AutoUsePotions then pcall(stepAutoUsePotions, Config) end
			end
			task.wait(0.12)
		end
	end)
	print("[Net a Fish] Ready - All Granular Controls Wired")
end

return GameModule