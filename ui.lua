local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local UI = {}
local PALETTE = {
	WindowBase = Color3.fromRGB(13, 12, 15),
	WindowTop = Color3.fromRGB(22, 16, 20),
	SidebarBg = Color3.fromRGB(16, 13, 17),
	CardBase = Color3.fromRGB(17, 15, 19),
	RowBase = Color3.fromRGB(26, 21, 25),
	RowHighlight = Color3.fromRGB(44, 22, 29),
	Red = Color3.fromRGB(225, 45, 68),
	RedBright = Color3.fromRGB(255, 92, 112),
	RedDark = Color3.fromRGB(115, 18, 30),
	CrimsonDeep = Color3.fromRGB(72, 10, 18),
	OffTrack = Color3.fromRGB(48, 42, 46),
	TextSecondary = Color3.fromRGB(172, 158, 164),
	TextMuted = Color3.fromRGB(122, 110, 116),
	Success = Color3.fromRGB(74, 222, 128),
}

local function round(i, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = i
	return c
end

local function stroke(i, col, th, tr)
	local s = Instance.new("UIStroke")
	s.Color = col or PALETTE.Red
	s.Thickness = th or 1
	s.Transparency = tr or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = i
	return s
end

local function tween(i, t, p)
	local tw = TweenService:Create(i, TweenInfo.new(t or 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p)
	tw:Play()
	return tw
end

local function grad3(p, c1, c2, c3)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(0.5, c2),
		ColorSequenceKeypoint.new(1, c3),
	})
	g.Parent = p
	return g
end

local function draggable(h, f)
	local drag, orig, sp, moved = false, nil, nil, false
	h.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = true
			moved = false
			orig = inp.Position
			sp = f.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if drag and inp.UserInputType == Enum.UserInputType.MouseMovement then
			local d = inp.Position - orig
			if d.Magnitude > 4 then
				moved = true
			end
			f.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			drag = false
		end
	end)
	return function()
		return moved
	end
end

function UI.init(Config, hubTitle)
	Config.AutoFishCollect = Config.AutoFishCollect or false
	Config.AutoCatch = Config.AutoCatch or false
	Config.AutoReelFull = Config.AutoReelFull or false
	Config.CollectIntervalSec = Config.CollectIntervalSec or 44
	Config.AutoPadTp = Config.AutoPadTp or false
	Config.AutoCollectMoney = Config.AutoCollectMoney or false
	Config.AutoShootMegalodon = Config.AutoShootMegalodon or false
	Config.AutoShootBloop = Config.AutoShootBloop or false
	Config.AutoRebirth = Config.AutoRebirth or false

	Config.AutoEquipBestFish = Config.AutoEquipBestFish or false
	Config.AutoFuseAll = Config.AutoFuseAll or false
	Config.KeepRarity = Config.KeepRarity or "None"
	Config.SellIntervalSec = Config.SellIntervalSec or 30
	Config.AutoSellFish = Config.AutoSellFish or false
	Config.AutoBuyPotions = Config.AutoBuyPotions or false
	Config.AutoUsePotions = Config.AutoUsePotions or false

	Config.AutoMiniGame = Config.AutoMiniGame or false
	Config.MiniGameInstant = true

	local pg = LocalPlayer:WaitForChild("PlayerGui")
	if pg:FindFirstChild("TerHubProUI") then
		pg.TerHubProUI:Destroy()
	end

	local sg = Instance.new("ScreenGui")
	sg.Name = "TerHubProUI"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999
	sg.Parent = pg

	local miniHolder = Instance.new("Frame")
	miniHolder.Size = UDim2.fromOffset(48, 52)
	miniHolder.Position = UDim2.new(0, 18, 0.25, 0)
	miniHolder.BackgroundTransparency = 1
	miniHolder.Visible = false
	miniHolder.Parent = sg

	local miniIcon = Instance.new("TextButton")
	miniIcon.Size = UDim2.fromOffset(44, 44)
	miniIcon.Position = UDim2.fromOffset(2, 1)
	miniIcon.BackgroundColor3 = PALETTE.Red
	miniIcon.Text = "Ter"
	miniIcon.Font = Enum.Font.GothamBlack
	miniIcon.TextSize = 11
	miniIcon.TextColor3 = Color3.new(1, 1, 1)
	miniIcon.AutoButtonColor = false
	miniIcon.Parent = miniHolder
	round(miniIcon, 11)
	stroke(miniIcon, PALETTE.RedBright, 1.5, 0)

	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.fromOffset(632, 382)
	wrap.Position = UDim2.fromScale(0.5, 0.5)
	wrap.AnchorPoint = Vector2.new(0.5, 0.5)
	wrap.BackgroundTransparency = 1
	wrap.Parent = sg

	local main = Instance.new("Frame")
	main.Size = UDim2.fromOffset(620, 368)
	main.Position = UDim2.fromOffset(6, 2)
	main.BackgroundColor3 = PALETTE.WindowBase
	main.ClipsDescendants = true
	main.Parent = wrap
	round(main, 14)

	local mStroke = stroke(main, PALETTE.Red, 1.6, 0)
	local mGrad = grad3(mStroke, PALETTE.RedDark, PALETTE.RedBright, PALETTE.CrimsonDeep)
	grad3(main, Color3.fromRGB(48, 12, 20), Color3.fromRGB(14, 12, 16), Color3.fromRGB(38, 10, 16)).Rotation = 32

	local top = Instance.new("Frame")
	top.Size = UDim2.new(1, 0, 0, 54)
	top.BackgroundColor3 = PALETTE.WindowTop
	top.BackgroundTransparency = 0.24
	top.ZIndex = 3
	top.Parent = main

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromOffset(420, 20)
	title.Position = UDim2.fromOffset(16, 9)
	title.BackgroundTransparency = 1
	title.Text = (hubTitle or "TER HUB") .. "  •  NET A FISH"
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 14
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 4
	title.Parent = top

	local rgb = Instance.new("UIGradient")
	rgb.Parent = title

	local subT = Instance.new("TextLabel")
	subT.Size = UDim2.fromOffset(420, 16)
	subT.Position = UDim2.fromOffset(16, 29)
	subT.BackgroundTransparency = 1
	subT.Text = "3D Red Edition  •  Granular Sub-Controls"
	subT.Font = Enum.Font.Gotham
	subT.TextSize = 11
	subT.TextColor3 = PALETTE.TextSecondary
	subT.TextXAlignment = Enum.TextXAlignment.Left
	subT.ZIndex = 4
	subT.Parent = top

	local minB = Instance.new("TextButton")
	minB.Size = UDim2.fromOffset(34, 32)
	minB.Position = UDim2.new(1, -82, 0.5, -16)
	minB.BackgroundColor3 = PALETTE.RowBase
	minB.Text = "-"
	minB.Font = Enum.Font.GothamBold
	minB.TextSize = 13
	minB.TextColor3 = Color3.new(1, 1, 1)
	minB.ZIndex = 6
	minB.Parent = top
	round(minB, 8)
	stroke(minB, PALETTE.Red, 1, 0.45)

	local clsB = Instance.new("TextButton")
	clsB.Size = UDim2.fromOffset(34, 32)
	clsB.Position = UDim2.new(1, -42, 0.5, -16)
	clsB.BackgroundColor3 = PALETTE.RowBase
	clsB.Text = "X"
	clsB.Font = Enum.Font.GothamBold
	clsB.TextSize = 13
	clsB.TextColor3 = Color3.new(1, 1, 1)
	clsB.ZIndex = 6
	clsB.Parent = top
	round(clsB, 8)
	stroke(clsB, PALETTE.RedBright, 1, 0.45)

	minB.MouseButton1Click:Connect(function()
		wrap.Visible = false
		miniHolder.Visible = true
	end)
	clsB.MouseButton1Click:Connect(function()
		sg:Destroy()
	end)
	local wasMini = draggable(miniIcon, miniHolder)
	miniIcon.MouseButton1Click:Connect(function()
		if not wasMini() then
			miniHolder.Visible = false
			wrap.Visible = true
		end
	end)
	draggable(top, wrap)

	local side = Instance.new("Frame")
	side.Size = UDim2.fromOffset(172, 298)
	side.Position = UDim2.fromOffset(12, 62)
	side.BackgroundColor3 = PALETTE.SidebarBg
	side.BackgroundTransparency = 0.22
	side.ZIndex = 3
	side.Parent = main
	round(side, 11)
	stroke(side, PALETTE.Red, 1, 0.72)

	local sPad = Instance.new("UIPadding")
	sPad.PaddingTop = UDim.new(0, 10)
	sPad.PaddingLeft = UDim.new(0, 8)
	sPad.PaddingRight = UDim.new(0, 8)
	sPad.Parent = side

	local sList = Instance.new("UIListLayout")
	sList.Padding = UDim.new(0, 7)
	sList.SortOrder = Enum.SortOrder.LayoutOrder
	sList.Parent = side

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, -200, 0, 298)
	holder.Position = UDim2.fromOffset(190, 62)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 3
	holder.Parent = main

	local pages, tabs = {}, {}

	local function makePage(id)
		local sc = Instance.new("ScrollingFrame")
		sc.Size = UDim2.fromScale(1, 1)
		sc.BackgroundColor3 = PALETTE.CardBase
		sc.BackgroundTransparency = 0.25
		sc.BorderSizePixel = 0
		sc.ScrollBarThickness = 4
		sc.ScrollBarImageColor3 = PALETTE.Red
		sc.ZIndex = 4
		sc.Visible = false
		sc.Parent = holder
		round(sc, 11)
		stroke(sc, PALETTE.Red, 1, 0.72)

		local p = Instance.new("UIPadding")
		p.PaddingTop = UDim.new(0, 10)
		p.PaddingBottom = UDim.new(0, 10)
		p.PaddingLeft = UDim.new(0, 10)
		p.PaddingRight = UDim.new(0, 12)
		p.Parent = sc

		local l = Instance.new("UIListLayout")
		l.Padding = UDim.new(0, 7)
		l.SortOrder = Enum.SortOrder.LayoutOrder
		l.Parent = sc
		l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			sc.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 24)
		end)
		pages[id] = sc
		return sc
	end

	local function openPage(id)
		for k, v in pairs(pages) do
			v.Visible = (k == id)
		end
		for k, b in pairs(tabs) do
			local a = (k == id)
			b.BackgroundColor3 = a and PALETTE.RowHighlight or PALETTE.RowBase
			b.TextColor3 = a and PALETTE.RedBright or PALETTE.TextSecondary
		end
	end

	local function addTab(ord, id, txt)
		local b = Instance.new("TextButton")
		b.LayoutOrder = ord
		b.Size = UDim2.new(1, 0, 0, 38)
		b.BackgroundColor3 = PALETTE.RowBase
		b.Text = "  " .. txt
		b.Font = Enum.Font.GothamBold
		b.TextSize = 12
		b.TextColor3 = PALETTE.TextSecondary
		b.TextXAlignment = Enum.TextXAlignment.Left
		b.AutoButtonColor = false
		b.ZIndex = 4
		b.Parent = side
		round(b, 8)
		stroke(b, PALETTE.Red, 1, 0.75)
		tabs[id] = b
		b.MouseButton1Click:Connect(function()
			openPage(id)
		end)
	end

	local function addHdr(sc, ord, txt)
		local h = Instance.new("TextLabel")
		h.LayoutOrder = ord
		h.Size = UDim2.new(1, 0, 0, 18)
		h.BackgroundTransparency = 1
		h.Text = txt
		h.Font = Enum.Font.GothamBlack
		h.TextSize = 11
		h.TextColor3 = PALETTE.RedBright
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.ZIndex = 5
		h.Parent = sc
	end

	local function addSw(sc, ord, tStr, sStr, getFn, setFn)
		local row = Instance.new("Frame")
		row.LayoutOrder = ord
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundColor3 = PALETTE.RowBase
		row.BackgroundTransparency = 0.14
		row.ZIndex = 5
		row.Parent = sc
		round(row, 9)
		stroke(row, PALETTE.Red, 1, 0.78)

		local l1 = Instance.new("TextLabel")
		l1.Size = UDim2.new(1, -105, 0, 17)
		l1.Position = UDim2.fromOffset(12, 6)
		l1.BackgroundTransparency = 1
		l1.Text = tStr
		l1.Font = Enum.Font.GothamBold
		l1.TextSize = 12
		l1.TextColor3 = Color3.new(1, 1, 1)
		l1.TextXAlignment = Enum.TextXAlignment.Left
		l1.ZIndex = 6
		l1.Parent = row

		local l2 = Instance.new("TextLabel")
		l2.Size = UDim2.new(1, -105, 0, 14)
		l2.Position = UDim2.fromOffset(12, 25)
		l2.BackgroundTransparency = 1
		l2.Text = sStr
		l2.Font = Enum.Font.Gotham
		l2.TextSize = 10
		l2.TextColor3 = PALETTE.TextSecondary
		l2.TextXAlignment = Enum.TextXAlignment.Left
		l2.ZIndex = 6
		l2.Parent = row

		local cur = getFn()
		local tag = Instance.new("TextLabel")
		tag.Size = UDim2.fromOffset(32, 16)
		tag.Position = UDim2.new(1, -96, 0.5, -8)
		tag.BackgroundTransparency = 1
		tag.Text = cur and "เปิด" or "ปิด"
		tag.Font = Enum.Font.GothamBlack
		tag.TextSize = 10
		tag.TextColor3 = cur and PALETTE.Success or PALETTE.TextMuted
		tag.ZIndex = 6
		tag.Parent = row

		local sw = Instance.new("TextButton")
		sw.Size = UDim2.fromOffset(46, 24)
		sw.Position = UDim2.new(1, -56, 0.5, -12)
		sw.BackgroundColor3 = cur and PALETTE.Red or PALETTE.OffTrack
		sw.Text = ""
		sw.AutoButtonColor = false
		sw.ZIndex = 6
		sw.Parent = row
		round(sw, 12)
		stroke(sw, PALETTE.RedBright, 1, 0.55)

		local kb = Instance.new("Frame")
		kb.Size = UDim2.fromOffset(18, 18)
		kb.Position = cur and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
		kb.BackgroundColor3 = Color3.new(1, 1, 1)
		kb.ZIndex = 7
		kb.Parent = sw
		round(kb, 9)

		sw.MouseButton1Click:Connect(function()
			local nv = not getFn()
			setFn(nv)
			tag.Text = nv and "เปิด" or "ปิด"
			tag.TextColor3 = nv and PALETTE.Success or PALETTE.TextMuted
			tween(sw, 0.12, { BackgroundColor3 = nv and PALETTE.Red or PALETTE.OffTrack })
			tween(kb, 0.12, { Position = nv and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) })
		end)
	end

	local function addSld(sc, ord, tStr, mn, mx, suf, getFn, setFn)
		local row = Instance.new("Frame")
		row.LayoutOrder = ord
		row.Size = UDim2.new(1, 0, 0, 52)
		row.BackgroundColor3 = PALETTE.RowBase
		row.BackgroundTransparency = 0.14
		row.ZIndex = 5
		row.Parent = sc
		round(row, 9)
		stroke(row, PALETTE.Red, 1, 0.78)

		local l1 = Instance.new("TextLabel")
		l1.Size = UDim2.new(1, -90, 0, 17)
		l1.Position = UDim2.fromOffset(12, 6)
		l1.BackgroundTransparency = 1
		l1.Text = tStr
		l1.Font = Enum.Font.GothamBold
		l1.TextSize = 12
		l1.TextColor3 = Color3.new(1, 1, 1)
		l1.TextXAlignment = Enum.TextXAlignment.Left
		l1.ZIndex = 6
		l1.Parent = row

		local vl = Instance.new("TextLabel")
		vl.Size = UDim2.fromOffset(72, 17)
		vl.Position = UDim2.new(1, -84, 0, 6)
		vl.BackgroundTransparency = 1
		vl.Text = tostring(getFn()) .. (suf or "")
		vl.Font = Enum.Font.GothamBlack
		vl.TextSize = 11
		vl.TextColor3 = PALETTE.RedBright
		vl.TextXAlignment = Enum.TextXAlignment.Right
		vl.ZIndex = 6
		vl.Parent = row

		local tr = Instance.new("Frame")
		tr.Size = UDim2.new(1, -24, 0, 6)
		tr.Position = UDim2.fromOffset(12, 33)
		tr.BackgroundColor3 = PALETTE.OffTrack
		tr.ZIndex = 6
		tr.Parent = row
		round(tr, 3)

		local fl = Instance.new("Frame")
		fl.Size = UDim2.fromScale(0, 1)
		fl.BackgroundColor3 = PALETTE.Red
		fl.ZIndex = 7
		fl.Parent = tr
		round(fl, 3)

		local th = Instance.new("TextButton")
		th.Size = UDim2.fromOffset(14, 14)
		th.AnchorPoint = Vector2.new(0.5, 0.5)
		th.Position = UDim2.new(0, 0, 0.5, 0)
		th.BackgroundColor3 = Color3.new(1, 1, 1)
		th.Text = ""
		th.ZIndex = 8
		th.Parent = tr
		round(th, 7)
		stroke(th, PALETTE.RedBright, 1.5, 0)

		local function setR(r)
			local num = math.floor((mn + (mx - mn) * math.clamp(r, 0, 1)) + 0.5)
			setFn(num)
			local ar = (num - mn) / math.max(1, (mx - mn))
			fl.Size = UDim2.fromScale(ar, 1)
			th.Position = UDim2.new(ar, 0, 0.5, 0)
			vl.Text = tostring(num) .. (suf or "")
		end
		setR((getFn() - mn) / math.max(1, (mx - mn)))

		local sld = false
		local function upd(inp)
			setR((inp.Position.X - tr.AbsolutePosition.X) / math.max(1, tr.AbsoluteSize.X))
		end
		tr.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				sld = true
				upd(inp)
			end
		end)
		th.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				sld = true
			end
		end)
		UserInputService.InputChanged:Connect(function(inp)
			if sld and inp.UserInputType == Enum.UserInputType.MouseMovement then
				upd(inp)
			end
		end)
		UserInputService.InputEnded:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.MouseButton1 then
				sld = false
			end
		end)
	end

	local function addCycle(sc, ord, tStr, sStr, options, getFn, setFn)
		local row = Instance.new("Frame")
		row.LayoutOrder = ord
		row.Size = UDim2.new(1, 0, 0, 48)
		row.BackgroundColor3 = PALETTE.RowBase
		row.BackgroundTransparency = 0.14
		row.ZIndex = 5
		row.Parent = sc
		round(row, 9)
		stroke(row, PALETTE.Red, 1, 0.78)

		local l1 = Instance.new("TextLabel")
		l1.Size = UDim2.new(1, -135, 0, 17)
		l1.Position = UDim2.fromOffset(12, 6)
		l1.BackgroundTransparency = 1
		l1.Text = tStr
		l1.Font = Enum.Font.GothamBold
		l1.TextSize = 12
		l1.TextColor3 = Color3.new(1, 1, 1)
		l1.TextXAlignment = Enum.TextXAlignment.Left
		l1.ZIndex = 6
		l1.Parent = row

		local l2 = Instance.new("TextLabel")
		l2.Size = UDim2.new(1, -135, 0, 14)
		l2.Position = UDim2.fromOffset(12, 25)
		l2.BackgroundTransparency = 1
		l2.Text = sStr
		l2.Font = Enum.Font.Gotham
		l2.TextSize = 10
		l2.TextColor3 = PALETTE.TextSecondary
		l2.TextXAlignment = Enum.TextXAlignment.Left
		l2.ZIndex = 6
		l2.Parent = row

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.fromOffset(112, 28)
		btn.Position = UDim2.new(1, -122, 0.5, -14)
		btn.BackgroundColor3 = PALETTE.RowHighlight
		btn.Text = tostring(getFn())
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 11
		btn.TextColor3 = PALETTE.RedBright
		btn.AutoButtonColor = false
		btn.ZIndex = 6
		btn.Parent = row
		round(btn, 7)
		stroke(btn, PALETTE.Red, 1, 0.45)

		btn.MouseButton1Click:Connect(function()
			local cur = tostring(getFn())
			local idx = 1
			for i, v in ipairs(options) do
				if v == cur then
					idx = (i % #options) + 1
					break
				end
			end
			setFn(options[idx])
			btn.Text = options[idx]
		end)
	end

	-- แถบหมวดซ้ายมือ (เพิ่ม "กล่องปลา" เป็นหมวดที่ 2)
	addTab(1, "fish", "ตกปลา / ฟาร์ม")
	addTab(2, "box", "กล่องปลา")
	addTab(3, "mini", "มินิเกมและสแกน")

	local p1 = makePage("fish")
	local pBox = makePage("box")
	local p2 = makePage("mini")

	-- หมวด 1: ตกปลา / ฟาร์ม
	addHdr(p1, 1, "MAIN (ตกปลา)")
	addSw(p1, 2, "จับปลาอัตโนมัติ", "เปิดแยกเฉพาะระบบจับปลาอัตโนมัติ", function() return Config.AutoCatch == true end, function(v) Config.AutoCatch = v end)
	addSw(p1, 3, "ดึงอวนเมื่อเต็มอัตโนมัติ", "เปิดแยกเฉพาะระบบดึงอวนเมื่อเต็ม", function() return Config.AutoReelFull == true end, function(v) Config.AutoReelFull = v end)
	addHdr(p1, 4, "อื่นๆ (เก็บของ / แท่น / เงิน)")
	addSld(p1, 5, "เก็บทุก (วิ)", 5, 120, "s", function() return Config.CollectIntervalSec or 44 end, function(v) Config.CollectIntervalSec = v end)
	addSw(p1, 6, "วาร์ปไปเหยียบแท่น", "เปิดแยกเฉพาะการวาร์ปไปเหยียบแท่น", function() return Config.AutoPadTp == true end, function(v) Config.AutoPadTp = v end)
	addSw(p1, 7, "เก็บเงินอัตโนมัติ", "เปิดแยกเฉพาะการเก็บเงินอัตโนมัติ", function() return Config.AutoCollectMoney == true end, function(v) Config.AutoCollectMoney = v end)
	addHdr(p1, 8, "อีเวนต์ & รีเบิร์ธ")
	addSw(p1, 9, "ยิงเมกาโลดอนอัตโนมัติ", "เปิดแยกเฉพาะตอนเมกาโลดอนโผล่", function() return Config.AutoShootMegalodon == true end, function(v) Config.AutoShootMegalodon = v end)
	addSw(p1, 10, "ยิง Bloop อัตโนมัติ", "เปิดแยกเฉพาะตอน Bloop โผล่", function() return Config.AutoShootBloop == true end, function(v) Config.AutoShootBloop = v end)
	addSw(p1, 11, "รีเบิร์ธอัตโนมัติ", "เปิดแยกเฉพาะระบบรีเบิร์ธอัตโนมัติ", function() return Config.AutoRebirth == true end, function(v) Config.AutoRebirth = v end)

	-- หมวด 2: กล่องปลา
	addHdr(pBox, 1, "MAIN (กล่องปลา)")
	addSw(pBox, 2, "ใส่ปลาที่ดีที่สุดอัตโนมัติ", "ใส่ตัวที่ดีที่สุดลงช่องแสดงผลอัตโนมัติ", function() return Config.AutoEquipBestFish == true end, function(v) Config.AutoEquipBestFish = v end)
	addSw(pBox, 3, "ฟิวส์ทั้งหมดอัตโนมัติ", "ฟิวส์รวมปลาอัตโนมัติเมื่อมีปลาพร้อมฟิวส์", function() return Config.AutoFuseAll == true end, function(v) Config.AutoFuseAll = v end)
	addCycle(pBox, 4, "rarity ที่เก็บไว้ (ไม่ขาย)", "คลิกเพื่อสลับระดับความหายากที่ไม่ต้องการขาย", { "None", "Rare", "Epic", "Legendary", "Mythic", "Celestial", "Secret" }, function() return Config.KeepRarity or "None" end, function(v) Config.KeepRarity = v end)
	addSld(pBox, 5, "ขายทุก (วิ)", 5, 120, "s", function() return Config.SellIntervalSec or 30 end, function(v) Config.SellIntervalSec = v end)
	addSw(pBox, 6, "ขายอัตโนมัติ", "ขายปลาอัตโนมัติตามรอบเวลาที่ตั้งไว้", function() return Config.AutoSellFish == true end, function(v) Config.AutoSellFish = v end)
	addHdr(pBox, 7, "ยา (POTIONS)")
	addSw(pBox, 8, "ซื้อยาอัตโนมัติ", "ซื้อโพชั่นอัตโนมัติเมื่อมีสินค้า", function() return Config.AutoBuyPotions == true end, function(v) Config.AutoBuyPotions = v end)
	addSw(pBox, 9, "ใช้ยาอัตโนมัติ", "กดใช้ยา/โพชั่นอัตโนมัติ", function() return Config.AutoUsePotions == true end, function(v) Config.AutoUsePotions = v end)

	-- หมวด 3: มินิเกมและสแกน
	addSw(p2, 1, "เล่นมินิเกมอัตโนมัติ (ตอบสนองทันที)", "จับจังหวะและกดให้อัตโนมัติทันทีที่มินิเกมขึ้น", function() return Config.AutoMiniGame == true end, function(v) Config.AutoMiniGame = v end)
	local rScan = Instance.new("Frame")
	rScan.LayoutOrder = 2
	rScan.Size = UDim2.new(1, 0, 0, 52)
	rScan.BackgroundColor3 = PALETTE.RowBase
	rScan.BackgroundTransparency = 0.14
	rScan.ZIndex = 5
	rScan.Parent = p2
	round(rScan, 9)
	stroke(rScan, PALETTE.Red, 1, 0.78)

	local sLbl = Instance.new("TextLabel")
	sLbl.Size = UDim2.new(1, -135, 0, 17)
	sLbl.Position = UDim2.fromOffset(12, 6)
	sLbl.BackgroundTransparency = 1
	sLbl.Text = "สแกนโครงสร้างเกม"
	sLbl.Font = Enum.Font.GothamBold
	sLbl.TextSize = 12
	sLbl.TextColor3 = Color3.new(1, 1, 1)
	sLbl.TextXAlignment = Enum.TextXAlignment.Left
	sLbl.ZIndex = 6
	sLbl.Parent = rScan

	local sSub = Instance.new("TextLabel")
	sSub.Size = UDim2.new(1, -135, 0, 14)
	sSub.Position = UDim2.fromOffset(12, 26)
	sSub.BackgroundTransparency = 1
	sSub.Text = "พิมพ์รายชื่อ Remote และ GUI ที่ Console"
	sSub.Font = Enum.Font.Gotham
	sSub.TextSize = 10
	sSub.TextColor3 = PALETTE.TextSecondary
	sSub.TextXAlignment = Enum.TextXAlignment.Left
	sSub.ZIndex = 6
	sSub.Parent = rScan

	local sBtn = Instance.new("TextButton")
	sBtn.Size = UDim2.fromOffset(108, 32)
	sBtn.Position = UDim2.new(1, -120, 0.5, -16)
	sBtn.BackgroundColor3 = PALETTE.Red
	sBtn.Text = "สแกนเกม"
	sBtn.Font = Enum.Font.GothamBlack
	sBtn.TextSize = 11
	sBtn.TextColor3 = Color3.new(1, 1, 1)
	sBtn.AutoButtonColor = false
	sBtn.ZIndex = 6
	sBtn.Parent = rScan
	round(sBtn, 8)
	stroke(sBtn, PALETTE.RedBright, 1, 0.35)

	sBtn.MouseButton1Click:Connect(function()
		Config.ScanNow = true
		sBtn.Text = "กำลังสแกน..."
		task.delay(0.8, function()
			if sBtn and sBtn.Parent then
				sBtn.Text = "สแกนเกม"
			end
		end)
	end)

	openPage("fish")

	local rot, clk = 0, 0
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		if not sg or not sg.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end
		rot = (rot + dt * 95) % 360
		mGrad.Rotation = rot
		clk += dt
		local h0 = (clk * 0.28) % 1
		rgb.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.00, Color3.fromHSV(h0, 0.9, 1)),
			ColorSequenceKeypoint.new(0.25, Color3.fromHSV((h0 + 0.16) % 1, 0.9, 1)),
			ColorSequenceKeypoint.new(0.50, Color3.fromHSV((h0 + 0.33) % 1, 0.9, 1)),
			ColorSequenceKeypoint.new(0.75, Color3.fromHSV((h0 + 0.50) % 1, 0.9, 1)),
			ColorSequenceKeypoint.new(1.00, Color3.fromHSV((h0 + 0.67) % 1, 0.9, 1)),
		})
	end)

	print("[UI] Mounted Granular Sub-Controls UI (with Fish Box Tab)")
end

return UI