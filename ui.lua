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
    CardBase = Color3.fromRGB(17, 15, 19),
    RowBase = Color3.fromRGB(26, 21, 25),
    RowHighlight = Color3.fromRGB(38, 26, 31),
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
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.0, c1),
        ColorSequenceKeypoint.new(0.5, c2),
        ColorSequenceKeypoint.new(1.0, c3),
    })
    g.Parent = parent
    return g
end

local function makeDraggable(dragHandle, targetFrame)
    local dragging, dragOrigin, startPos = false, nil, nil
    local moved = false

    dragHandle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            moved = false
            dragOrigin = inp.Position
            startPos = targetFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragOrigin
            if d.Magnitude > 4 then
                moved = true
            end
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + d.X,
                startPos.Y.Scale,
                startPos.Y.Offset + d.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return function()
        return moved
    end
end

function UI.init(Config, hubTitle)
    if Config.AutoFishCollect == nil then
        Config.AutoFishCollect = false
    end

    local titleText = hubTitle or "TER HUB"
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local existing = playerGui:FindFirstChild("TerHubProUI")
    if existing then
        existing:Destroy()
    end

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

    miniIcon.MouseButton1Down:Connect(function()
        tween(miniIcon, 0.08, { Position = UDim2.fromOffset(2, 3) })
    end)
    miniIcon.MouseButton1Up:Connect(function()
        tween(miniIcon, 0.12, { Position = UDim2.fromOffset(2, 1) })
    end)

    local mainWrapper = Instance.new("Frame")
    mainWrapper.Name = "MainWrapper"
    mainWrapper.Size = UDim2.fromOffset(552, 362)
    mainWrapper.Position = UDim2.fromScale(0.5, 0.5)
    mainWrapper.AnchorPoint = Vector2.new(0.5, 0.5)
    mainWrapper.BackgroundTransparency = 1
    mainWrapper.Parent = screenGui

    local deepShadow = Instance.new("Frame")
    deepShadow.Size = UDim2.fromOffset(540, 348)
    deepShadow.Position = UDim2.fromOffset(6, 12)
    deepShadow.BackgroundColor3 = PALETTE.ShadowDeep
    deepShadow.BackgroundTransparency = 0.28
    deepShadow.BorderSizePixel = 0
    deepShadow.Parent = mainWrapper
    round(deepShadow, 15)

    local bevelBase = Instance.new("Frame")
    bevelBase.Size = UDim2.fromOffset(540, 348)
    bevelBase.Position = UDim2.fromOffset(6, 8)
    bevelBase.BackgroundColor3 = PALETTE.RedDark
    bevelBase.BorderSizePixel = 0
    bevelBase.Parent = mainWrapper
    round(bevelBase, 14)

    local main = Instance.new("Frame")
    main.Name = "MainWindow"
    main.Size = UDim2.fromOffset(540, 348)
    main.Position = UDim2.fromOffset(6, 2)
    main.BackgroundColor3 = PALETTE.WindowBase
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = mainWrapper
    round(main, 14)

    local mainStroke = stroke(main, PALETTE.Red, 1.6, 0)
    local mainStrokeGrad = addShimmerGradient(mainStroke, PALETTE.RedDark, PALETTE.RedBright, PALETTE.CrimsonDeep)

    local gradBg = addShimmerGradient(main, Color3.fromRGB(30, 15, 20), Color3.fromRGB(14, 13, 17), Color3.fromRGB(24, 12, 16))
    gradBg.Rotation = 32

    local topGloss = Instance.new("Frame")
    topGloss.Size = UDim2.new(1, -24, 0, 1)
    topGloss.Position = UDim2.fromOffset(12, 1)
    topGloss.BackgroundColor3 = PALETTE.RedBright
    topGloss.BackgroundTransparency = 0.45
    topGloss.BorderSizePixel = 0
    topGloss.Parent = main

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 56)
    topbar.BackgroundColor3 = PALETTE.WindowTop
    topbar.BackgroundTransparency = 0.25
    topbar.BorderSizePixel = 0
    topbar.Parent = main

    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, -24, 0, 1)
    topDivider.Position = UDim2.new(0, 12, 1, -1)
    topDivider.BackgroundColor3 = PALETTE.Red
    topDivider.BackgroundTransparency = 0.6
    topDivider.BorderSizePixel = 0
    topDivider.Parent = topbar

    local logoShadow = Instance.new("Frame")
    logoShadow.Size = UDim2.fromOffset(38, 38)
    logoShadow.Position = UDim2.fromOffset(14, 11)
    logoShadow.BackgroundColor3 = PALETTE.RedDark
    logoShadow.BorderSizePixel = 0
    logoShadow.Parent = topbar
    round(logoShadow, 9)

    local logoBox = Instance.new("Frame")
    logoBox.Size = UDim2.fromOffset(38, 38)
    logoBox.Position = UDim2.fromOffset(14, 8)
    logoBox.BackgroundColor3 = PALETTE.Red
    logoBox.BorderSizePixel = 0
    logoBox.Parent = topbar
    round(logoBox, 9)
    stroke(logoBox, PALETTE.RedBright, 1, 0.35)
    local logoGrad = addShimmerGradient(logoBox, PALETTE.RedBright, PALETTE.Red, PALETTE.CrimsonDeep)
    logoGrad.Rotation = 45

    local logoLbl = Instance.new("TextLabel")
    logoLbl.Size = UDim2.fromScale(1, 1)
    logoLbl.BackgroundTransparency = 1
    logoLbl.Text = "Ter"
    logoLbl.Font = Enum.Font.GothamBlack
    logoLbl.TextSize = 13
    logoLbl.TextColor3 = Color3.new(1, 1, 1)
    logoLbl.ZIndex = 3
    logoLbl.Parent = logoBox

    local hubTitleLbl = Instance.new("TextLabel")
    hubTitleLbl.Size = UDim2.fromOffset(300, 20)
    hubTitleLbl.Position = UDim2.fromOffset(62, 9)
    hubTitleLbl.BackgroundTransparency = 1
    hubTitleLbl.Text = titleText .. "  •  NET A FISH"
    hubTitleLbl.Font = Enum.Font.GothamBlack
    hubTitleLbl.TextSize = 14
    hubTitleLbl.TextColor3 = PALETTE.RedBright
    hubTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubTitleLbl.Parent = topbar

    local hubSubLbl = Instance.new("TextLabel")
    hubSubLbl.Size = UDim2.fromOffset(300, 16)
    hubSubLbl.Position = UDim2.fromOffset(62, 30)
    hubSubLbl.BackgroundTransparency = 1
    hubSubLbl.Text = "3D Red Edition  •  Cat 1 & MiniGame"
    hubSubLbl.Font = Enum.Font.Gotham
    hubSubLbl.TextSize = 11
    hubSubLbl.TextColor3 = PALETTE.TextSecondary
    hubSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubSubLbl.Parent = topbar

    local function make3DWinBtn(txt, offsetX, isClose)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.fromOffset(34, 36)
        holder.Position = UDim2.new(1, offsetX, 0.5, -18)
        holder.BackgroundTransparency = 1
        holder.ZIndex = 10
        holder.Parent = topbar

        local base = Instance.new("Frame")
        base.Size = UDim2.fromOffset(34, 32)
        base.Position = UDim2.fromOffset(0, 4)
        base.BackgroundColor3 = isClose and PALETTE.CrimsonDeep or PALETTE.RedDark
        base.BorderSizePixel = 0
        base.ZIndex = 10
        base.Parent = holder
        round(base, 8)

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(34, 32)
        btn.Position = UDim2.fromOffset(0, 0)
        btn.BackgroundColor3 = PALETTE.RowBase
        btn.Text = txt
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = PALETTE.TextPrimary
        btn.AutoButtonColor = false
        btn.ZIndex = 11
        btn.Parent = holder
        round(btn, 8)
        stroke(btn, isClose and PALETTE.RedBright or PALETTE.Red, 1, 0.45)

        btn.MouseEnter:Connect(function()
            tween(btn, 0.12, {
                BackgroundColor3 = isClose and PALETTE.Red or PALETTE.RowHighlight,
            })
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, 0.12, {
                BackgroundColor3 = PALETTE.RowBase,
                Position = UDim2.fromOffset(0, 0),
            })
        end)
        btn.MouseButton1Down:Connect(function()
            tween(btn, 0.06, { Position = UDim2.fromOffset(0, 3) })
        end)
        btn.MouseButton1Up:Connect(function()
            tween(btn, 0.10, { Position = UDim2.fromOffset(0, 0) })
        end)

        return btn
    end

    local minBtn = make3DWinBtn("-", -82, false)
    local closeBtn = make3DWinBtn("X", -42, true)

    minBtn.MouseButton1Click:Connect(function()
        mainWrapper.Visible = false
        miniHolder.Visible = true
    end)

    closeBtn.MouseButton1Click:Connect(function()
        if Config then
            Config.AutoMiniGame = false
            Config.AutoFishCollect = false
            Config.ScanNow = false
        end
        screenGui:Destroy()
    end)

    local wasMiniDragged = makeDraggable(miniIcon, miniHolder)
    miniIcon.MouseButton1Click:Connect(function()
        if not wasMiniDragged() then
            miniHolder.Visible = false
            mainWrapper.Visible = true
        end
    end)

    makeDraggable(topbar, mainWrapper)

    local content = Instance.new("ScrollingFrame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -28, 1, -80)
    content.Position = UDim2.fromOffset(14, 66)
    content.BackgroundColor3 = PALETTE.CardBase
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = PALETTE.Red
    content.CanvasSize = UDim2.new(0, 0, 0, 290)
    content.Parent = main
    round(content, 12)
    stroke(content, PALETTE.Red, 1, 0.72)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 24)
    end)

    local function make3DRow(order, height)
        local wrap = Instance.new("Frame")
        wrap.LayoutOrder = order
        wrap.Size = UDim2.new(1, 0, 0, height + 3)
        wrap.BackgroundTransparency = 1
        wrap.Parent = content

        local base = Instance.new("Frame")
        base.Size = UDim2.new(1, 0, 0, height)
        base.Position = UDim2.fromOffset(0, 3)
        base.BackgroundColor3 = PALETTE.ShadowDeep
        base.BorderSizePixel = 0
        base.Parent = wrap
        round(base, 9)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, height)
        card.Position = UDim2.fromOffset(0, 0)
        card.BackgroundColor3 = PALETTE.RowBase
        card.BorderSizePixel = 0
        card.Parent = wrap
        round(card, 9)
        stroke(card, PALETTE.Red, 1, 0.78)
        return card
    end

    local function makeSwitchRow(order, titleStr, subStr, getState, setState)
        local row = make3DRow(order, 52)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -105, 0, 18)
        lbl.Position = UDim2.fromOffset(14, 7)
        lbl.BackgroundTransparency = 1
        lbl.Text = titleStr
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextColor3 = PALETTE.TextPrimary
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -105, 0, 15)
        sub.Position = UDim2.fromOffset(14, 27)
        sub.BackgroundTransparency = 1
        sub.Text = subStr
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 10
        sub.TextColor3 = PALETTE.TextSecondary
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row

        local initOn = getState()
        local tag = Instance.new("TextLabel")
        tag.Size = UDim2.fromOffset(34, 16)
        tag.Position = UDim2.new(1, -98, 0.5, -8)
        tag.BackgroundTransparency = 1
        tag.Text = initOn and "ON" or "OFF"
        tag.Font = Enum.Font.GothamBlack
        tag.TextSize = 10
        tag.TextColor3 = initOn and PALETTE.Success or PALETTE.TextMuted
        tag.Parent = row

        local sw = Instance.new("TextButton")
        sw.Size = UDim2.fromOffset(46, 24)
        sw.Position = UDim2.new(1, -58, 0.5, -12)
        sw.BackgroundColor3 = initOn and PALETTE.Red or PALETTE.OffTrack
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = row
        round(sw, 12)
        stroke(sw, PALETTE.RedBright, 1, 0.55)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(18, 18)
        knob.Position = initOn and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = sw
        round(knob, 9)

        sw.MouseButton1Click:Connect(function()
            local nextVal = not getState()
            setState(nextVal)
            tag.Text = nextVal and "ON" or "OFF"
            tag.TextColor3 = nextVal and PALETTE.Success or PALETTE.TextMuted
            tween(sw, 0.14, { BackgroundColor3 = nextVal and PALETTE.Red or PALETTE.OffTrack })
            tween(knob, 0.14, { Position = nextVal and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) })
        end)
    end

    -- หมวดที่ 1: ตกปลาและเก็บผลผลิตอัตโนมัติ
    makeSwitchRow(
        1,
        "[หมวด 1] ตกปลาและเก็บผลผลิตอัตโนมัติ",
        "โยนอวน ดึงอวน และเก็บผลผลิต/เงินจากจุดเก็บ",
        function()
            return Config.AutoFishCollect == true
        end,
        function(v)
            Config.AutoFishCollect = v
        end
    )

    -- ระบบมินิเกมอัตโนมัติ
    makeSwitchRow(
        2,
        "เล่นมินิเกมที่เด้งขึ้นมาอัตโนมัติ",
        "ตรวจจับหน้าต่างมินิเกมและเล่นให้อัตโนมัติ",
        function()
            return Config.AutoMiniGame == true
        end,
        function(v)
            Config.AutoMiniGame = v
        end
    )

    -- แถบเลื่อนปรับความเร็ว
    local row3 = make3DRow(3, 52)
    local minV, maxV = 0.10, 1.50
    local cur = tonumber(Config.MiniGameSpeed) or 0.15

    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, -105, 0, 18)
    lbl2.Position = UDim2.fromOffset(14, 7)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = "ความเร็วในการกด / หน่วงจังหวะ"
    lbl2.Font = Enum.Font.GothamMedium
    lbl2.TextSize = 12
    lbl2.TextColor3 = PALETTE.TextPrimary
    lbl2.TextXAlignment = Enum.TextXAlignment.Left
    lbl2.Parent = row3

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.fromOffset(80, 18)
    valLbl.Position = UDim2.new(1, -94, 0, 7)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = string.format("%.2f วิ", cur)
    valLbl.Font = Enum.Font.GothamBlack
    valLbl.TextSize = 12
    valLbl.TextColor3 = PALETTE.RedBright
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row3

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -28, 0, 8)
    track.Position = UDim2.fromOffset(14, 34)
    track.BackgroundColor3 = PALETTE.OffTrack
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row3
    round(track, 4)

    local ratio = math.clamp((cur - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(ratio, 0, 1, 0)
    fill.BackgroundColor3 = PALETTE.Red
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, 4)
    addShimmerGradient(fill, PALETTE.RedDark, PALETTE.RedBright, PALETTE.Red)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(16, 16)
    thumb.Position = UDim2.new(ratio, -8, 0.5, -8)
    thumb.BackgroundColor3 = PALETTE.RedBright
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    round(thumb, 8)
    stroke(thumb, PALETTE.ShadowDeep, 1.5, 0.2)

    local sliding = false
    local function applyX(px)
        local r = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minV + (maxV - minV) * r
        local v = math.floor(raw * 100 + 0.5) / 100
        Config.MiniGameSpeed = v
        valLbl.Text = string.format("%.2f วิ", v)
        fill.Size = UDim2.new(r, 0, 1, 0)
        thumb.Position = UDim2.new(r, -8, 0.5, -8)
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = true
            applyX(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if sliding and inp.UserInputType == Enum.UserInputType.MouseMovement then
            applyX(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            sliding = false
        end
    end)

    -- ปุ่มสแกนเกม
    local row4 = make3DRow(4, 52)

    local lbl3 = Instance.new("TextLabel")
    lbl3.Size = UDim2.new(1, -160, 0, 18)
    lbl3.Position = UDim2.fromOffset(14, 7)
    lbl3.BackgroundTransparency = 1
    lbl3.Text = "สแกนไฟล์และโครงสร้างเกม"
    lbl3.Font = Enum.Font.GothamBold
    lbl3.TextSize = 12
    lbl3.TextColor3 = PALETTE.TextPrimary
    lbl3.TextXAlignment = Enum.TextXAlignment.Left
    lbl3.Parent = row4

    local sub3 = Instance.new("TextLabel")
    sub3.Size = UDim2.new(1, -160, 0, 15)
    sub3.Position = UDim2.fromOffset(14, 27)
    sub3.BackgroundTransparency = 1
    sub3.Text = "แสดงรายชื่อ Remote, GUI และวัตถุในแมพที่ Console"
    sub3.Font = Enum.Font.Gotham
    sub3.TextSize = 10
    sub3.TextColor3 = PALETTE.TextSecondary
    sub3.TextXAlignment = Enum.TextXAlignment.Left
    sub3.Parent = row4

    local scanHolder = Instance.new("Frame")
    scanHolder.Size = UDim2.fromOffset(134, 34)
    scanHolder.Position = UDim2.new(1, -146, 0.5, -17)
    scanHolder.BackgroundTransparency = 1
    scanHolder.ZIndex = 5
    scanHolder.Parent = row4

    local scanBase = Instance.new("Frame")
    scanBase.Size = UDim2.fromOffset(134, 30)
    scanBase.Position = UDim2.fromOffset(0, 4)
    scanBase.BackgroundColor3 = PALETTE.CrimsonDeep
    scanBase.BorderSizePixel = 0
    scanBase.ZIndex = 5
    scanBase.Parent = scanHolder
    round(scanBase, 8)

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.fromOffset(134, 30)
    scanBtn.Position = UDim2.fromOffset(0, 0)
    scanBtn.BackgroundColor3 = PALETTE.Red
    scanBtn.Text = ""
    scanBtn.AutoButtonColor = false
    scanBtn.ZIndex = 6
    scanBtn.Parent = scanHolder
    round(scanBtn, 8)
    stroke(scanBtn, PALETTE.RedBright, 1.2, 0.25)
    addShimmerGradient(scanBtn, Color3.fromRGB(235, 55, 78), Color3.fromRGB(190, 32, 52), Color3.fromRGB(145, 20, 36))

    local scanText = Instance.new("TextLabel")
    scanText.Size = UDim2.fromScale(1, 1)
    scanText.BackgroundTransparency = 1
    scanText.Text = "สแกนเกม"
    scanText.Font = Enum.Font.GothamBlack
    scanText.TextSize = 12
    scanText.TextColor3 = Color3.new(1, 1, 1)
    scanText.TextStrokeColor3 = Color3.fromRGB(40, 5, 10)
    scanText.TextStrokeTransparency = 0.2
    scanText.ZIndex = 8
    scanText.Parent = scanBtn

    scanBtn.MouseButton1Down:Connect(function()
        tween(scanBtn, 0.06, { Position = UDim2.fromOffset(0, 3) })
    end)
    scanBtn.MouseButton1Up:Connect(function()
        tween(scanBtn, 0.10, { Position = UDim2.fromOffset(0, 0) })
    end)

    scanBtn.MouseButton1Click:Connect(function()
        Config.ScanNow = true
        scanText.Text = "กำลังสแกน..."
        task.delay(0.8, function()
            if scanText and scanText.Parent then
                scanText.Text = "สแกนเกม OK"
                task.delay(0.8, function()
                    if scanText and scanText.Parent then
                        scanText.Text = "สแกนเกม"
                    end
                end)
            end
        end)
    end)

    local rot = 0
    local animConn
    animConn = RunService.RenderStepped:Connect(function(dt)
        if not screenGui or not screenGui.Parent then
            if animConn then
                animConn:Disconnect()
            end
            return
        end
        rot = (rot + dt * 80) % 360
        mainStrokeGrad.Rotation = rot
        miniStrokeGrad.Rotation = -rot
    end)

    print("[UI] Mounted 3D Black & Red Edition with Category 1")
end

return UI