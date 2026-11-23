local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local UI = {}

local PALETTE = {
    ShadowDeep = Color3.fromRGB(6, 4, 5),
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
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextSecondary = Color3.fromRGB(172, 158, 164),
    TextMuted = Color3.fromRGB(122, 110, 116),
    Success = Color3.fromRGB(74, 222, 128),
}

local function round(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
    return c
end

local function stroke(inst, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or PALETTE.Red
    s.Thickness = thick or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = inst
    return s
end

local function tween(inst, time, props)
    local info = TweenInfo.new(time or 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tw = TweenService:Create(inst, info, props)
    tw:Play()
    return tw
end

local function addShimmerGradient(parent, c1, c2, c3)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0.0, c1), ColorSequenceKeypoint.new(0.5, c2), ColorSequenceKeypoint.new(1.0, c3) })
    g.Parent = parent
    return g
end

local function makeDraggable(dragHandle, targetFrame)
    local dragging, dragOrigin, startPos = false, nil, nil
    local moved = false
    dragHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; moved = false; dragOrigin = inp.Position; startPos = targetFrame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragOrigin
            if d.Magnitude > 4 then moved = true end
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return function() return moved end
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
    Config.AutoMiniGame = Config.AutoMiniGame or false
    Config.MiniGameInstant = true

    local titleText = hubTitle or "TER HUB"
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("TerHubProUI")
    if existing then existing:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TerHubProUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Parent = playerGui

    local miniHolder = Instance.new("Frame")
    miniHolder.Name = "MiniIconHolder"
    miniHolder.Size = UDim2.fromOffset(48, 52)
    miniHolder.Position = UDim2.new(0, 18, 0.25, 0)
    miniHolder.BackgroundTransparency = 1
    miniHolder.Visible = false
    miniHolder.Parent = screenGui

    local miniShadow = Instance.new("Frame")
    miniShadow.Size = UDim2.fromOffset(44, 44)
    miniShadow.Position = UDim2.fromOffset(2, 6)
    miniShadow.BackgroundColor3 = PALETTE.ShadowDeep
    miniShadow.BackgroundTransparency = 0.25
    miniShadow.BorderSizePixel = 0
    miniShadow.Parent = miniHolder
    round(miniShadow, 11)

    local miniExtrude = Instance.new("Frame")
    miniExtrude.Size = UDim2.fromOffset(44, 44)
    miniExtrude.Position = UDim2.fromOffset(2, 4)
    miniExtrude.BackgroundColor3 = PALETTE.RedDark
    miniExtrude.BorderSizePixel = 0
    miniExtrude.Parent = miniHolder
    round(miniExtrude, 11)

    local miniIcon = Instance.new("TextButton")
    miniIcon.Name = "MiniIconBtn"
    miniIcon.Size = UDim2.fromOffset(44, 44)
    miniIcon.Position = UDim2.fromOffset(2, 1)
    miniIcon.BackgroundColor3 = PALETTE.WindowTop
    miniIcon.Text = ""
    miniIcon.AutoButtonColor = false
    miniIcon.Parent = miniHolder
    round(miniIcon, 11)
    local miniStroke = stroke(miniIcon, PALETTE.Red, 1.5, 0)
    local miniStrokeGrad = addShimmerGradient(miniStroke, PALETTE.RedDark, PALETTE.RedBright, PALETTE.CrimsonDeep)

    local miniBadge = Instance.new("Frame")
    miniBadge.Size = UDim2.fromOffset(32, 32)
    miniBadge.Position = UDim2.fromScale(0.5, 0.5)
    miniBadge.AnchorPoint = Vector2.new(0.5, 0.5)
    miniBadge.BackgroundColor3 = PALETTE.Red
    miniBadge.BorderSizePixel = 0
    miniBadge.Parent = miniIcon
    round(miniBadge, 8)
    stroke(miniBadge, PALETTE.RedBright, 1, 0.35)
    local badgeGrad = addShimmerGradient(miniBadge, PALETTE.RedBright, PALETTE.Red, PALETTE.CrimsonDeep)
    badgeGrad.Rotation = 45

    local miniText = Instance.new("TextLabel")
    miniText.Size = UDim2.fromScale(1, 1)
    miniText.BackgroundTransparency = 1
    miniText.Text = "Ter"
    miniText.Font = Enum.Font.GothamBlack
    miniText.TextSize = 11
    miniText.TextColor3 = Color3.new(1, 1, 1)
    miniText.ZIndex = 3
    miniText.Parent = miniBadge

    miniIcon.MouseButton1Down:Connect(function() tween(miniIcon, 0.08, { Position = UDim2.fromOffset(2, 3) }) end)
    miniIcon.MouseButton1Up:Connect(function() tween(miniIcon, 0.12, { Position = UDim2.fromOffset(2, 1) }) end)

    local mainWrapper = Instance.new("Frame")
    mainWrapper.Name = "MainWrapper"
    mainWrapper.Size = UDim2.fromOffset(632, 382)
    mainWrapper.Position = UDim2.fromScale(0.5, 0.5)
    mainWrapper.AnchorPoint = Vector2.new(0.5, 0.5)
    mainWrapper.BackgroundTransparency = 1
    mainWrapper.Parent = screenGui

    local deepShadow = Instance.new("Frame")
    deepShadow.Size = UDim2.fromOffset(620, 368)
    deepShadow.Position = UDim2.fromOffset(6, 12)
    deepShadow.BackgroundColor3 = PALETTE.ShadowDeep
    deepShadow.BackgroundTransparency = 0.28
    deepShadow.BorderSizePixel = 0
    deepShadow.Parent = mainWrapper
    round(deepShadow, 15)

    local bevelBase = Instance.new("Frame")
    bevelBase.Size = UDim2.fromOffset(620, 368)
    bevelBase.Position = UDim2.fromOffset(6, 8)
    bevelBase.BackgroundColor3 = PALETTE.RedDark
    bevelBase.BorderSizePixel = 0
    bevelBase.Parent = mainWrapper
    round(bevelBase, 14)

    local main = Instance.new("Frame")
    main.Name = "MainWindow"
    main.Size = UDim2.fromOffset(620, 368)
    main.Position = UDim2.fromOffset(6, 2)
    main.BackgroundColor3 = PALETTE.WindowBase
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = mainWrapper
    round(main, 14)

    local mainStroke = stroke(main, PALETTE.Red, 1.6, 0)
    local mainStrokeGrad = addShimmerGradient(mainStroke, PALETTE.RedDark, PALETTE.RedBright, PALETTE.CrimsonDeep)
    local gradBg = addShimmerGradient(main, Color3.fromRGB(48, 12, 20), Color3.fromRGB(14, 12, 16), Color3.fromRGB(38, 10, 16))
    gradBg.Rotation = 32

    local bgFxLayer = Instance.new("Frame")
    bgFxLayer.Name = "BgAnimatedFx"
    bgFxLayer.Size = UDim2.fromScale(1, 1)
    bgFxLayer.BackgroundTransparency = 1
    bgFxLayer.ClipsDescendants = true
    bgFxLayer.ZIndex = 1
    bgFxLayer.Parent = main

    local gridHolder = Instance.new("Frame")
    gridHolder.Name = "CrimsonGrid"
    gridHolder.Size = UDim2.fromScale(1, 1)
    gridHolder.BackgroundTransparency = 1
    gridHolder.ZIndex = 1
    gridHolder.Parent = bgFxLayer

    for gx = 0.1, 0.9, 0.1 do
        local vLine = Instance.new("Frame")
        vLine.Size = UDim2.new(0, 1, 1, 0); vLine.Position = UDim2.new(gx, 0, 0, 0)
        vLine.BackgroundColor3 = PALETTE.Red; vLine.BackgroundTransparency = 0.89; vLine.BorderSizePixel = 0; vLine.ZIndex = 1; vLine.Parent = gridHolder
    end
    for gy = 0.14, 0.92, 0.14 do
        local hLine = Instance.new("Frame")
        hLine.Size = UDim2.new(1, 0, 0, 1); hLine.Position = UDim2.new(0, 0, gy, 0)
        hLine.BackgroundColor3 = PALETTE.Red; hLine.BackgroundTransparency = 0.89; hLine.BorderSizePixel = 0; hLine.ZIndex = 1; hLine.Parent = gridHolder
    end

    local sweepBeam = Instance.new("Frame")
    sweepBeam.Name = "CrimsonSweep1"; sweepBeam.Size = UDim2.new(0.48, 0, 1.9, 0); sweepBeam.Position = UDim2.new(-0.5, 0, -0.45, 0)
    sweepBeam.Rotation = 24; sweepBeam.BackgroundColor3 = PALETTE.RedBright; sweepBeam.BackgroundTransparency = 0.72; sweepBeam.BorderSizePixel = 0; sweepBeam.ZIndex = 1; sweepBeam.Parent = bgFxLayer
    local sweepGrad = Instance.new("UIGradient")
    sweepGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0.0, 1), NumberSequenceKeypoint.new(0.32, 0.50), NumberSequenceKeypoint.new(0.5, 0.14), NumberSequenceKeypoint.new(0.68, 0.50), NumberSequenceKeypoint.new(1.0, 1) })
    sweepGrad.Parent = sweepBeam

    local sweepBeam2 = Instance.new("Frame")
    sweepBeam2.Name = "CrimsonSweep2"; sweepBeam2.Size = UDim2.new(0.32, 0, 1.9, 0); sweepBeam2.Position = UDim2.new(1.1, 0, -0.45, 0)
    sweepBeam2.Rotation = -22; sweepBeam2.BackgroundColor3 = PALETTE.Red; sweepBeam2.BackgroundTransparency = 0.78; sweepBeam2.BorderSizePixel = 0; sweepBeam2.ZIndex = 1; sweepBeam2.Parent = bgFxLayer
    local sweepGrad2 = Instance.new("UIGradient")
    sweepGrad2.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0.0, 1), NumberSequenceKeypoint.new(0.5, 0.22), NumberSequenceKeypoint.new(1.0, 1) })
    sweepGrad2.Parent = sweepBeam2

    local scanBar = Instance.new("Frame")
    scanBar.Name = "HorizontalScanBar"; scanBar.Size = UDim2.new(1, 0, 0, 14); scanBar.Position = UDim2.new(0, 0, 0, 0)
    scanBar.BackgroundColor3 = PALETTE.RedBright; scanBar.BackgroundTransparency = 0.76; scanBar.BorderSizePixel = 0; scanBar.ZIndex = 1; scanBar.Parent = bgFxLayer
    local scanGrad = Instance.new("UIGradient")
    scanGrad.Rotation = 90; scanGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0.0, 1), NumberSequenceKeypoint.new(0.5, 0.25), NumberSequenceKeypoint.new(1.0, 1) })
    scanGrad.Parent = scanBar

    local rings = {}
    for rIdx = 1, 3 do
        local ring = Instance.new("Frame")
        ring.Name = "RadarRing_" .. tostring(rIdx); ring.AnchorPoint = Vector2.new(0.5, 0.5); ring.Position = UDim2.fromScale(0.62, 0.56); ring.Size = UDim2.fromOffset(40, 40)
        ring.BackgroundTransparency = 1; ring.BorderSizePixel = 0; ring.ZIndex = 1; ring.Parent = bgFxLayer
        round(ring, 999)
        local rStroke = stroke(ring, PALETTE.RedBright, 1.5, 0.65)
        table.insert(rings, { frame = ring, stroke = rStroke, phase = (rIdx - 1) / 3 })
    end

    local embers = {}
    local rng = Random.new()
    for i = 1, 34 do
        local dot = Instance.new("Frame")
        local sz = rng:NextInteger(3, 8)
        dot.Name = "Ember_" .. tostring(i); dot.Size = UDim2.fromOffset(sz, sz); dot.Position = UDim2.new(rng:NextNumber(0.02, 0.98), 0, rng:NextNumber(0.05, 1.05), 0)
        dot.BackgroundColor3 = (i % 3 == 0) and Color3.fromRGB(255, 130, 145) or ((i % 2 == 0) and PALETTE.RedBright or PALETTE.Red)
        dot.BackgroundTransparency = rng:NextNumber(0.18, 0.55); dot.BorderSizePixel = 0; dot.ZIndex = 1; dot.Parent = bgFxLayer
        round(dot, math.ceil(sz * 0.5))
        table.insert(embers, { frame = dot, x = dot.Position.X.Scale, y = dot.Position.Y.Scale, speedY = rng:NextNumber(0.06, 0.18), swayAmp = rng:NextNumber(0.012, 0.032), swaySpeed = rng:NextNumber(1.6, 3.6), phase = rng:NextNumber(0, math.pi * 2), baseTrans = dot.BackgroundTransparency })
    end

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"; topbar.Size = UDim2.new(1, 0, 0, 54); topbar.BackgroundColor3 = PALETTE.WindowTop; topbar.BackgroundTransparency = 0.24; topbar.BorderSizePixel = 0; topbar.ZIndex = 3; topbar.Parent = main
    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, -20, 0, 1); topDivider.Position = UDim2.new(0, 10, 1, -1); topDivider.BackgroundColor3 = PALETTE.Red; topDivider.BackgroundTransparency = 0.55; topDivider.BorderSizePixel = 0; topDivider.ZIndex = 4; topDivider.Parent = topbar

    local logoBox = Instance.new("Frame")
    logoBox.Size = UDim2.fromOffset(36, 36); logoBox.Position = UDim2.fromOffset(14, 9); logoBox.BackgroundColor3 = PALETTE.Red; logoBox.BorderSizePixel = 0; logoBox.ZIndex = 4; logoBox.Parent = topbar
    round(logoBox, 9); stroke(logoBox, PALETTE.RedBright, 1, 0.35)
    local logoLbl = Instance.new("TextLabel")
    logoLbl.Size = UDim2.fromScale(1, 1); logoLbl.BackgroundTransparency = 1; logoLbl.Text = "Ter"; logoLbl.Font = Enum.Font.GothamBlack; logoLbl.TextSize = 13; logoLbl.TextColor3 = Color3.new(1, 1, 1); logoLbl.ZIndex = 5; logoLbl.Parent = logoBox

    local hubTitleLbl = Instance.new("TextLabel")
    hubTitleLbl.Size = UDim2.fromOffset(420, 20); hubTitleLbl.Position = UDim2.fromOffset(60, 8); hubTitleLbl.BackgroundTransparency = 1; hubTitleLbl.Text = titleText .. "  •  NET A FISH"; hubTitleLbl.Font = Enum.Font.GothamBlack; hubTitleLbl.TextSize = 14; hubTitleLbl.TextColor3 = Color3.new(1, 1, 1); hubTitleLbl.TextXAlignment = Enum.TextXAlignment.Left; hubTitleLbl.ZIndex = 4; hubTitleLbl.Parent = topbar
    local titleRgbGrad = Instance.new("UIGradient"); titleRgbGrad.Name = "MapNameRgbGradient"; titleRgbGrad.Parent = hubTitleLbl

    local hubSubLbl = Instance.new("TextLabel")
    hubSubLbl.Size = UDim2.fromOffset(420, 16); hubSubLbl.Position = UDim2.fromOffset(60, 28); hubSubLbl.BackgroundTransparency = 1; hubSubLbl.Text = "3D Red Edition  •  Granular Sub-Controls"; hubSubLbl.Font = Enum.Font.Gotham; hubSubLbl.TextSize = 11; hubSubLbl.TextColor3 = PALETTE.TextSecondary; hubSubLbl.TextXAlignment = Enum.TextXAlignment.Left; hubSubLbl.ZIndex = 4; hubSubLbl.Parent = topbar

    local function make3DWinBtn(txt, offsetX, isClose)
        local holder = Instance.new("Frame"); holder.Size = UDim2.fromOffset(34, 36); holder.Position = UDim2.new(1, offsetX, 0.5, -18); holder.BackgroundTransparency = 1; holder.ZIndex = 10; holder.Parent = topbar
        local base = Instance.new("Frame"); base.Size = UDim2.fromOffset(34, 32); base.Position = UDim2.fromOffset(0, 4); base.BackgroundColor3 = isClose and PALETTE.CrimsonDeep or PALETTE.RedDark; base.BorderSizePixel = 0; base.ZIndex = 10; base.Parent = holder; round(base, 8)
        local btn = Instance.new("TextButton"); btn.Size = UDim2.fromOffset(34, 32); btn.Position = UDim2.fromOffset(0, 0); btn.BackgroundColor3 = PALETTE.RowBase; btn.Text = txt; btn.Font = Enum.Font.GothamBold; btn.TextSize = 13; btn.TextColor3 = PALETTE.TextPrimary; btn.AutoButtonColor = false; btn.ZIndex = 11; btn.Parent = holder; round(btn, 8); stroke(btn, isClose and PALETTE.RedBright or PALETTE.Red, 1, 0.45)
        btn.MouseButton1Down:Connect(function() tween(btn, 0.06, { Position = UDim2.fromOffset(0, 3) }) end)
        btn.MouseButton1Up:Connect(function() tween(btn, 0.10, { Position = UDim2.fromOffset(0, 0) }) end)
        return btn
    end

    local minBtn = make3DWinBtn("-", -82, false)
    local closeBtn = make3DWinBtn("X", -42, true)
    minBtn.MouseButton1Click:Connect(function() mainWrapper.Visible = false; miniHolder.Visible = true end)
    closeBtn.MouseButton1Click:Connect(function() if Config then Config.AutoMiniGame = false; Config.AutoFishCollect = false; Config.AutoCatch = false; Config.AutoReelFull = false; Config.AutoPadTp = false; Config.AutoCollectMoney = false; Config.AutoShootMegalodon = false; Config.AutoShootBloop = false; Config.AutoRebirth = false; Config.ScanNow = false end; screenGui:Destroy() end)
    local wasMiniDragged = makeDraggable(miniIcon, miniHolder)
    miniIcon.MouseButton1Click:Connect(function() if not wasMiniDragged() then miniHolder.Visible = false; mainWrapper.Visible = true end end)
    makeDraggable(topbar, mainWrapper)

    local sidebar = Instance.new("Frame"); sidebar.Name = "Sidebar"; sidebar.Size = UDim2.fromOffset(172, 298); sidebar.Position = UDim2.fromOffset(12, 62); sidebar.BackgroundColor3 = PALETTE.SidebarBg; sidebar.BackgroundTransparency = 0.22; sidebar.BorderSizePixel = 0; sidebar.ZIndex = 3; sidebar.Parent = main; round(sidebar, 11); stroke(sidebar, PALETTE.Red, 1, 0.72)
    local sidePad = Instance.new("UIPadding"); sidePad.PaddingTop = UDim.new(0, 10); sidePad.PaddingLeft = UDim.new(0, 8); sidePad.PaddingRight = UDim.new(0, 8); sidePad.Parent = sidebar
    local sideLayout = Instance.new("UIListLayout"); sideLayout.Padding = UDim.new(0, 7); sideLayout.SortOrder = Enum.SortOrder.LayoutOrder; sideLayout.Parent = sidebar

    local pagesHolder = Instance.new("Frame"); pagesHolder.Name = "PagesHolder"; pagesHolder.Size = UDim2.new(1, -200, 0, 298); pagesHolder.Position = UDim2.fromOffset(190, 62); pagesHolder.BackgroundTransparency = 1; pagesHolder.ZIndex = 3; pagesHolder.Parent = main
    local pages, navBtns = {}, {}

    local function createPage(pageId)
        local sc = Instance.new("ScrollingFrame"); sc.Name = "Page_" .. pageId; sc.Size = UDim2.fromScale(1, 1); sc.BackgroundColor3 = PALETTE.CardBase; sc.BackgroundTransparency = 0.25; sc.BorderSizePixel = 0; sc.ScrollBarThickness = 4; sc.ScrollBarImageColor3 = PALETTE.Red; sc.CanvasSize = UDim2.new(0, 0, 0, 280); sc.ZIndex = 4; sc.Visible = false; sc.Parent = pagesHolder; round(sc, 11); stroke(sc, PALETTE.Red, 1, 0.72)
        local p = Instance.new("UIPadding"); p.PaddingTop = UDim.new(0, 10); p.PaddingBottom = UDim.new(0, 10); p.PaddingLeft = UDim.new(0, 10); p.PaddingRight = UDim.new(0, 12); p.Parent = sc
        local l = Instance.new("UIListLayout"); l.Padding = UDim.new(0, 8); l.SortOrder = Enum.SortOrder.LayoutOrder; l.Parent = sc
        l:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sc.CanvasSize = UDim2.new(0, 0, 0, l.AbsoluteContentSize.Y + 24) end)
        pages[pageId] = sc; return sc
    end

    local function selectPage(pageId)
        for id, pg in pairs(pages) do pg.Visible = (id == pageId) end
        for id, nb in pairs(navBtns) do local active = (id == pageId); nb.BackgroundColor3 = active and PALETTE.RowHighlight or PALETTE.RowBase; nb.TextColor3 = active and PALETTE.RedBright or PALETTE.TextSecondary end
    end

    local function addNavTab(order, pageId, labelTxt)
        local btn = Instance.new("TextButton"); btn.LayoutOrder = order; btn.Size = UDim2.new(1, 0, 0, 38); btn.BackgroundColor3 = PALETTE.RowBase; btn.Text = "  " .. labelTxt; btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.TextColor3 = PALETTE.TextSecondary; btn.TextXAlignment = Enum.TextXAlignment.Left; btn.AutoButtonColor = false; btn.ZIndex = 4; btn.Parent = sidebar; round(btn, 8); stroke(btn, PALETTE.Red, 1, 0.75)
        navBtns[pageId] = btn
        btn.MouseButton1Click:Connect(function() selectPage(pageId) end)
    end

    local function addSectionHeader(parentScroll, order, titleStr)
        local hdr = Instance.new("TextLabel"); hdr.LayoutOrder = order; hdr.Size = UDim2.new(1, 0, 0, 20); hdr.BackgroundTransparency = 1; hdr.Text = titleStr; hdr.Font = Enum.Font.GothamBlack; hdr.TextSize = 11; hdr.TextColor3 = PALETTE.RedBright; hdr.TextXAlignment = Enum.TextXAlignment.Left; hdr.ZIndex = 6; hdr.Parent = parentScroll
    end

    local function make3DRow(parentScroll, order, height)
        local wrap = Instance.new("Frame"); wrap.LayoutOrder = order; wrap.Size = UDim2.new(1, 0, 0, height + 3); wrap.BackgroundTransparency = 1; wrap.ZIndex = 5; wrap.Parent = parentScroll
        local base = Instance.new("Frame"); base.Size = UDim2.new(1, 0, 0, height); base.Position = UDim2.fromOffset(0, 3); base.BackgroundColor3 = PALETTE.ShadowDeep; base.BorderSizePixel = 0; base.ZIndex = 5; base.Parent = wrap; round(base, 9)
        local card = Instance.new("Frame"); card.Size = UDim2.new(1, 0, 0, height); card.Position = UDim2.fromOffset(0, 0); card.BackgroundColor3 = PALETTE.RowBase; card.BackgroundTransparency = 0.14; card.BorderSizePixel = 0; card.ZIndex = 6; card.Parent = wrap; round(card, 9); stroke(card, PALETTE.Red, 1, 0.78)
        return card
    end

    local function addSwitch(parentScroll, order, titleStr, subStr, getState, setState)
        local row = make3DRow(parentScroll, order, 50)
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -105, 0, 17); lbl.Position = UDim2.fromOffset(12, 6); lbl.BackgroundTransparency = 1; lbl.Text = titleStr; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = PALETTE.TextPrimary; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 7; lbl.Parent = row
        local sub = Instance.new("TextLabel"); sub.Size = UDim2.new(1, -105, 0, 14); sub.Position = UDim2.fromOffset(12, 26); sub.BackgroundTransparency = 1; sub.Text = subStr; sub.Font = Enum.Font.Gotham; sub.TextSize = 10; sub.TextColor3 = PALETTE.TextSecondary; sub.TextXAlignment = Enum.TextXAlignment.Left; sub.ZIndex = 7; sub.Parent = row
        local initOn = getState()
        local tag = Instance.new("TextLabel"); tag.Size = UDim2.fromOffset(32, 16); tag.Position = UDim2.new(1, -96, 0.5, -8); tag.BackgroundTransparency = 1; tag.Text = initOn and "ON" or "OFF"; tag.Font = Enum.Font.GothamBlack; tag.TextSize = 10; tag.TextColor3 = initOn and PALETTE.Success or PALETTE.TextMuted; tag.ZIndex = 7; tag.Parent = row
        local sw = Instance.new("TextButton"); sw.Size = UDim2.fromOffset(46, 24); sw.Position = UDim2.new(1, -56, 0.5, -12); sw.BackgroundColor3 = initOn and PALETTE.Red or PALETTE.OffTrack; sw.Text = ""; sw.AutoButtonColor = false; sw.ZIndex = 7; sw.Parent = row; round(sw, 12); stroke(sw, PALETTE.RedBright, 1, 0.55)
        local knob = Instance.new("Frame"); knob.Size = UDim2.fromOffset(18, 18); knob.Position = initOn and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3); knob.BackgroundColor3 = Color3.new(1, 1, 1); knob.BorderSizePixel = 0; knob.ZIndex = 8; knob.Parent = sw; round(knob, 9)
        sw.MouseButton1Click:Connect(function()
            local nextVal = not getState(); setState(nextVal)
            tag.Text = nextVal and "ON" or "OFF"; tag.TextColor3 = nextVal and PALETTE.Success or PALETTE.TextMuted
            tween(sw, 0.14, { BackgroundColor3 = nextVal and PALETTE.Red or PALETTE.OffTrack })
            tween(knob, 0.14, { Position = nextVal and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) })
        end)
    end

    local function addSlider(parentScroll, order, titleStr, minVal, maxVal, suffixStr, getVal, setVal)
        local row = make3DRow(parentScroll, order, 54)
        local lbl = Instance.new("TextLabel"); lbl.Size = UDim2.new(1, -90, 0, 17); lbl.Position = UDim2.fromOffset(12, 6); lbl.BackgroundTransparency = 1; lbl.Text = titleStr; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextColor3 = PALETTE.TextPrimary; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 7; lbl.Parent = row
        local valLbl = Instance.new("TextLabel"); valLbl.Size = UDim2.fromOffset(72, 17); valLbl.Position = UDim2.new(1, -84, 0, 6); valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(getVal()) .. (suffixStr or ""); valLbl.Font = Enum.Font.GothamBlack; valLbl.TextSize = 11; valLbl.TextColor3 = PALETTE.RedBright; valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 7; valLbl.Parent = row
        local track = Instance.new("Frame"); track.Size = UDim2.new(1, -24, 0, 6); track.Position = UDim2.fromOffset(12, 34); track.BackgroundColor3 = PALETTE.OffTrack; track.BorderSizePixel = 0; track.ZIndex = 7; track.Parent = row; round(track, 3)
        local fill = Instance.new("Frame"); fill.Size = UDim2.fromScale(0, 1); fill.BackgroundColor3 = PALETTE.Red; fill.BorderSizePixel = 0; fill.ZIndex = 8; fill.Parent = track; round(fill, 3)
        local thumb = Instance.new("TextButton"); thumb.Size = UDim2.fromOffset(14, 14); thumb.AnchorPoint = Vector2.new(0.5, 0.5); thumb.Position = UDim2.new(0, 0, 0.5, 0); thumb.BackgroundColor3 = Color3.new(1, 1, 1); thumb.Text = ""; thumb.AutoButtonColor = false; thumb.ZIndex = 9; thumb.Parent = track; round(thumb, 7); stroke(thumb, PALETTE.RedBright, 1.5, 0)
        local function applyRatio(r)
            local clamped = math.clamp(r, 0, 1)
            local num = math.floor((minVal + (maxVal - minVal) * clamped) + 0.5)
            setVal(num)
            local actualRatio = (num - minVal) / math.max(1, (maxVal - minVal))
            fill.Size = UDim2.fromScale(actualRatio, 1); thumb.Position = UDim2.new(actualRatio, 0, 0.5, 0); valLbl.Text = tostring(num) .. (suffixStr or "")
        end
        applyRatio((getVal() - minVal) / math.max(1, (maxVal - minVal)))
        local sliding = false
        local function updateFromInput(inp) applyRatio((inp.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X)) end
        track.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true; updateFromInput(inp) end end)
        thumb.InputBegan:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end end)
        UserInputService.InputChanged:Connect(function(inp) if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then updateFromInput(inp) end end)
        UserInputService.InputEnded:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end end)
    end

    addNavTab(1, "fishing", "ตกปลา / ฟาร์ม")
    addNavTab(2, "minigame", "มินิเกมและสแกน")

    local pFish = createPage("fishing")
    local pMini = createPage("minigame")

    addSectionHeader(pFish, 1, "MAIN (ตกปลา)")
    addSwitch(pFish, 2, "จับปลาอัตโนมัติ", "เปิดแยกเฉพาะระบบจับปลาอัตโนมัติ", function() return Config.AutoCatch == true end, function(v) Config.AutoCatch = v end)
    addSwitch(pFish, 3, "ดึงอวนเมื่อเต็มอัตโนมัติ", "เปิดแยกเฉพาะระบบดึงอวนเมื่อเต็ม", function() return Config.AutoReelFull == true end, function(v) Config.AutoReelFull = v end)

    addSectionHeader(pFish, 4, "อื่นๆ (เก็บของ / แท่น / เงิน)")
    addSlider(pFish, 5, "เก็บทุก (วิ)", 5, 120, "s", function() return Config.CollectIntervalSec or 44 end, function(v) Config.CollectIntervalSec = v end)
    addSwitch(pFish, 6, "วาร์ปไปเหยียบแท่น", "เปิดแยกเฉพาะการวาร์ปไปเหยียบแท่น", function() return Config.AutoPadTp == true end, function(v) Config.AutoPadTp = v end)
    addSwitch(pFish, 7, "เก็บเงินอัตโนมัติ", "เปิดแยกเฉพาะการเก็บเงินอัตโนมัติ", function() return Config.AutoCollectMoney == true end, function(v) Config.AutoCollectMoney = v end)

    addSectionHeader(pFish, 8, "อีเวนต์ & รีเบิร์ธ")
    addSwitch(pFish, 9, "ยิงเมกาโลดอนอัตโนมัติ", "เปิดแยกเฉพาะตอนเมกาโลดอนโผล่", function() return Config.AutoShootMegalodon == true end, function(v) Config.AutoShootMegalodon = v end)
    addSwitch(pFish, 10, "ยิง Bloop อัตโนมัติ", "เปิดแยกเฉพาะตอน Bloop โผล่", function() return Config.AutoShootBloop == true end, function(v) Config.AutoShootBloop = v end)
    addSwitch(pFish, 11, "รีเบิร์ธอัตโนมัติ", "เปิดแยกเฉพาะระบบรีเบิร์ธอัตโนมัติ", function() return Config.AutoRebirth == true end, function(v) Config.AutoRebirth = v end)

    addSwitch(pMini, 1, "เล่นมินิเกมอัตโนมัติ (ตอบสนองทันที)", "จับจังหวะและกดให้อัตโนมัติทันทีที่มินิเกมขึ้น", function() return Config.AutoMiniGame == true end, function(v) Config.AutoMiniGame = v end)

    local rowScan = make3DRow(pMini, 2, 54)
    local lblScan = Instance.new("TextLabel"); lblScan.Size = UDim2.new(1, -135, 0, 18); lblScan.Position = UDim2.fromOffset(12, 7); lblScan.BackgroundTransparency = 1; lblScan.Text = "สแกนโครงสร้างเกม"; lblScan.Font = Enum.Font.GothamBold; lblScan.TextSize = 12; lblScan.TextColor3 = PALETTE.TextPrimary; lblScan.TextXAlignment = Enum.TextXAlignment.Left; lblScan.ZIndex = 7; lblScan.Parent = rowScan
    local subScan = Instance.new("TextLabel"); subScan.Size = UDim2.new(1, -135, 0, 15); subScan.Position = UDim2.fromOffset(12, 27); subScan.BackgroundTransparency = 1; subScan.Text = "พิมพ์รายชื่อ Remote และ GUI ที่ Console"; subScan.Font = Enum.Font.Gotham; subScan.TextSize = 10; subScan.TextColor3 = PALETTE.TextSecondary; subScan.TextXAlignment = Enum.TextXAlignment.Left; subScan.ZIndex = 7; subScan.Parent = rowScan
    local scanBtn = Instance.new("TextButton"); scanBtn.Size = UDim2.fromOffset(108, 32); scanBtn.Position = UDim2.new(1, -120, 0.5, -16); scanBtn.BackgroundColor3 = PALETTE.Red; scanBtn.Text = "สแกนเกม"; scanBtn.Font = Enum.Font.GothamBlack; scanBtn.TextSize = 11; scanBtn.TextColor3 = Color3.new(1, 1, 1); scanBtn.AutoButtonColor = false; scanBtn.ZIndex = 7; scanBtn.Parent = rowScan; round(scanBtn, 8); stroke(scanBtn, PALETTE.RedBright, 1, 0.35)
    scanBtn.MouseButton1Click:Connect(function() Config.ScanNow = true; scanBtn.Text = "กำลังสแกน..."; task.delay(0.8, function() if scanBtn and scanBtn.Parent then scanBtn.Text = "สแกนเกม" end end) end)

    selectPage("fishing")

    local rot, sweepX, sweep2X, scanY, fxClock = 0, -0.55, 1.15, -0.05, 0
    local animConn
    animConn = RunService.RenderStepped:Connect(function(dt)
        if not screenGui or not screenGui.Parent then if animConn then animConn:Disconnect() end return end
        rot = (rot + dt * 95) % 360; mainStrokeGrad.Rotation = rot; miniStrokeGrad.Rotation = -rot; fxClock += dt
        local h0 = (fxClock * 0.28) % 1
        titleRgbGrad.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0.00, Color3.fromHSV(h0, 0.9, 1)), ColorSequenceKeypoint.new(0.25, Color3.fromHSV((h0 + 0.16) % 1, 0.9, 1)), ColorSequenceKeypoint.new(0.50, Color3.fromHSV((h0 + 0.33) % 1, 0.9, 1)), ColorSequenceKeypoint.new(0.75, Color3.fromHSV((h0 + 0.50) % 1, 0.9, 1)), ColorSequenceKeypoint.new(1.00, Color3.fromHSV((h0 + 0.67) % 1, 0.9, 1)) })
        sweepX += dt * 0.52; if sweepX > 1.28 then sweepX = -0.55 end; sweepBeam.Position = UDim2.new(sweepX, 0, -0.45, 0)
        sweep2X -= dt * 0.36; if sweep2X < -0.45 then sweep2X = 1.18 end; sweepBeam2.Position = UDim2.new(sweep2X, 0, -0.45, 0)
        scanY += dt * 0.28; if scanY > 1.05 then scanY = -0.06 end; scanBar.Position = UDim2.new(0, 0, scanY, 0)
        gridHolder.Position = UDim2.new(math.sin(fxClock * 0.7) * 0.008, 0, math.cos(fxClock * 0.6) * 0.008, 0)
        for _, rg in ipairs(rings) do local prog = (fxClock * 0.42 + rg.phase) % 1; rg.frame.Size = UDim2.fromOffset(40 + prog * 310, 40 + prog * 310); rg.stroke.Transparency = 0.38 + prog * 0.62 end
        for _, em in ipairs(embers) do em.y -= em.speedY * dt; if em.y < -0.06 then em.y = 1.04 end; em.frame.Position = UDim2.new(em.x + math.sin(fxClock * em.swaySpeed + em.phase) * em.swayAmp, 0, em.y, 0); em.frame.BackgroundTransparency = math.clamp(em.baseTrans + math.sin(fxClock * 4.2 + em.phase) * 0.16, 0.08, 0.78) end
    end)

    print("[UI] Mounted Granular Sub-Controls UI")
end

return UI