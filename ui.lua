local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local UI = {}

local PALETTE = {
    ShadowDeep = Color3.fromRGB(5, 5, 8),
    WindowBase = Color3.fromRGB(12, 12, 16),
    WindowTop = Color3.fromRGB(20, 19, 28),
    CardBase = Color3.fromRGB(16, 16, 22),
    RowBase = Color3.fromRGB(24, 24, 33),
    RowHighlight = Color3.fromRGB(34, 33, 46),
    Gold = Color3.fromRGB(245, 196, 83),
    GoldBright = Color3.fromRGB(255, 224, 130),
    GoldDark = Color3.fromRGB(150, 110, 32),
    Accent = Color3.fromRGB(132, 86, 255),
    OffTrack = Color3.fromRGB(46, 46, 58),
    TextPrimary = Color3.fromRGB(248, 248, 255),
    TextSecondary = Color3.fromRGB(165, 165, 182),
    TextMuted = Color3.fromRGB(115, 115, 132),
    Success = Color3.fromRGB(74, 222, 128),
    Danger = Color3.fromRGB(215, 58, 78),
}

local function round(inst, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = inst
    return c
end

local function stroke(inst, col, thick, trans)
    local s = Instance.new("UIStroke")
    s.Color = col or PALETTE.Gold
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

    -- ==========================================
    -- 1. ปุ่มไอคอนย่อ 3D (TH) แบบนูนมีเงาและขอบแสงวิ่ง
    -- ==========================================
    local miniHolder = Instance.new("Frame")
    miniHolder.Name = "MiniIconHolder"
    miniHolder.Size = UDim2.fromOffset(60, 64)
    miniHolder.Position = UDim2.new(0, 18, 0.25, 0)
    miniHolder.BackgroundTransparency = 1
    miniHolder.Visible = false
    miniHolder.Parent = screenGui

    -- เงาฐาน 3D ด้านล่างปุ่มย่อ
    local miniShadow = Instance.new("Frame")
    miniShadow.Size = UDim2.fromOffset(56, 56)
    miniShadow.Position = UDim2.fromOffset(2, 7)
    miniShadow.BackgroundColor3 = PALETTE.ShadowDeep
    miniShadow.BackgroundTransparency = 0.25
    miniShadow.BorderSizePixel = 0
    miniShadow.Parent = miniHolder
    round(miniShadow, 14)

    -- ขอบฐาน 3D สีทองเข้ม
    local miniExtrude = Instance.new("Frame")
    miniExtrude.Size = UDim2.fromOffset(56, 56)
    miniExtrude.Position = UDim2.fromOffset(2, 5)
    miniExtrude.BackgroundColor3 = PALETTE.GoldDark
    miniExtrude.BorderSizePixel = 0
    miniExtrude.Parent = miniHolder
    round(miniExtrude, 14)

    -- ตัวปุ่มย่อด้านบน
    local miniIcon = Instance.new("TextButton")
    miniIcon.Name = "MiniIconBtn"
    miniIcon.Size = UDim2.fromOffset(56, 56)
    miniIcon.Position = UDim2.fromOffset(2, 1)
    miniIcon.BackgroundColor3 = PALETTE.WindowTop
    miniIcon.Text = ""
    miniIcon.AutoButtonColor = false
    miniIcon.Parent = miniHolder
    round(miniIcon, 14)
    local miniStroke = stroke(miniIcon, PALETTE.Gold, 1.8, 0)
    local miniStrokeGrad = addShimmerGradient(miniStroke, PALETTE.GoldDark, PALETTE.GoldBright, PALETTE.Accent)

    local miniBadge = Instance.new("Frame")
    miniBadge.Size = UDim2.fromOffset(40, 40)
    miniBadge.Position = UDim2.fromScale(0.5, 0.5)
    miniBadge.AnchorPoint = Vector2.new(0.5, 0.5)
    miniBadge.BackgroundColor3 = PALETTE.Accent
    miniBadge.BorderSizePixel = 0
    miniBadge.Parent = miniIcon
    round(miniBadge, 10)
    local badgeGrad = addShimmerGradient(miniBadge, Color3.fromRGB(165, 115, 255), Color3.fromRGB(108, 64, 230), PALETTE.Gold)
    badgeGrad.Rotation = 45

    local miniText = Instance.new("TextLabel")
    miniText.Size = UDim2.fromScale(1, 1)
    miniText.BackgroundTransparency = 1
    miniText.Text = "TH"
    miniText.Font = Enum.Font.GothamBlack
    miniText.TextSize = 16
    miniText.TextColor3 = Color3.new(1, 1, 1)
    miniText.Parent = miniBadge

    -- เอฟเฟกต์กดปุ่มย่อ 3D ยุบตัว
    miniIcon.MouseButton1Down:Connect(function()
        tween(miniIcon, 0.08, { Position = UDim2.fromOffset(2, 4) })
    end)
    miniIcon.MouseButton1Up:Connect(function()
        tween(miniIcon, 0.12, { Position = UDim2.fromOffset(2, 1) })
    end)

    -- ==========================================
    -- 2. หน้าต่างหลัก 3D (Layered Depth + Shimmer)
    -- ==========================================
    local mainWrapper = Instance.new("Frame")
    mainWrapper.Name = "MainWrapper"
    mainWrapper.Size = UDim2.fromOffset(552, 342)
    mainWrapper.Position = UDim2.fromScale(0.5, 0.5)
    mainWrapper.AnchorPoint = Vector2.new(0.5, 0.5)
    mainWrapper.BackgroundTransparency = 1
    mainWrapper.Parent = screenGui

    -- ชั้นเงา 3D ลึกด้านหลัง
    local deepShadow = Instance.new("Frame")
    deepShadow.Size = UDim2.fromOffset(540, 328)
    deepShadow.Position = UDim2.fromOffset(6, 12)
    deepShadow.BackgroundColor3 = PALETTE.ShadowDeep
    deepShadow.BackgroundTransparency = 0.28
    deepShadow.BorderSizePixel = 0
    deepShadow.Parent = mainWrapper
    round(deepShadow, 15)

    -- ชั้นความหนาขอบล่าง 3D (Extrusion Bevel)
    local bevelBase = Instance.new("Frame")
    bevelBase.Size = UDim2.fromOffset(540, 328)
    bevelBase.Position = UDim2.fromOffset(6, 8)
    bevelBase.BackgroundColor3 = PALETTE.GoldDark
    bevelBase.BorderSizePixel = 0
    bevelBase.Parent = mainWrapper
    round(bevelBase, 14)

    -- ตัวหน้าต่างหลักด้านหน้า
    local main = Instance.new("Frame")
    main.Name = "MainWindow"
    main.Size = UDim2.fromOffset(540, 328)
    main.Position = UDim2.fromOffset(6, 2)
    main.BackgroundColor3 = PALETTE.WindowBase
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = mainWrapper
    round(main, 14)

    local mainStroke = stroke(main, PALETTE.Gold, 1.6, 0)
    local mainStrokeGrad = addShimmerGradient(mainStroke, PALETTE.GoldDark, PALETTE.GoldBright, PALETTE.Accent)

    local gradBg = addShimmerGradient(main, Color3.fromRGB(25, 23, 36), Color3.fromRGB(14, 14, 19), Color3.fromRGB(19, 17, 26))
    gradBg.Rotation = 32

    -- แสงไฮไลต์ขอบบนแบบกระจก 3D
    local topGloss = Instance.new("Frame")
    topGloss.Size = UDim2.new(1, -24, 0, 1)
    topGloss.Position = UDim2.fromOffset(12, 1)
    topGloss.BackgroundColor3 = PALETTE.GoldBright
    topGloss.BackgroundTransparency = 0.45
    topGloss.BorderSizePixel = 0
    topGloss.Parent = main

    -- แถบหัวหน้าต่าง (Topbar)
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
    topDivider.BackgroundColor3 = PALETTE.Gold
    topDivider.BackgroundTransparency = 0.65
    topDivider.BorderSizePixel = 0
    topDivider.Parent = topbar

    -- โลโก้ TH แบบ 3D ใน Topbar
    local logoShadow = Instance.new("Frame")
    logoShadow.Size = UDim2.fromOffset(36, 36)
    logoShadow.Position = UDim2.fromOffset(14, 12)
    logoShadow.BackgroundColor3 = PALETTE.GoldDark
    logoShadow.BorderSizePixel = 0
    logoShadow.Parent = topbar
    round(logoShadow, 9)

    local logoBox = Instance.new("Frame")
    logoBox.Size = UDim2.fromOffset(36, 36)
    logoBox.Position = UDim2.fromOffset(14, 9)
    logoBox.BackgroundColor3 = PALETTE.Accent
    logoBox.BorderSizePixel = 0
    logoBox.Parent = topbar
    round(logoBox, 9)
    stroke(logoBox, PALETTE.GoldBright, 1, 0.35)
    local logoGrad = addShimmerGradient(logoBox, Color3.fromRGB(162, 110, 255), Color3.fromRGB(115, 70, 235), PALETTE.Gold)
    logoGrad.Rotation = 45

    local logoLbl = Instance.new("TextLabel")
    logoLbl.Size = UDim2.fromScale(1, 1)
    logoLbl.BackgroundTransparency = 1
    logoLbl.Text = "TH"
    logoLbl.Font = Enum.Font.GothamBlack
    logoLbl.TextSize = 14
    logoLbl.TextColor3 = Color3.new(1, 1, 1)
    logoLbl.Parent = logoBox

    local hubTitleLbl = Instance.new("TextLabel")
    hubTitleLbl.Size = UDim2.fromOffset(300, 20)
    hubTitleLbl.Position = UDim2.fromOffset(60, 9)
    hubTitleLbl.BackgroundTransparency = 1
    hubTitleLbl.Text = titleText .. "  •  NET A FISH"
    hubTitleLbl.Font = Enum.Font.GothamBlack
    hubTitleLbl.TextSize = 14
    hubTitleLbl.TextColor3 = PALETTE.GoldBright
    hubTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubTitleLbl.Parent = topbar

    local hubSubLbl = Instance.new("TextLabel")
    hubSubLbl.Size = UDim2.fromOffset(300, 16)
    hubSubLbl.Position = UDim2.fromOffset(60, 30)
    hubSubLbl.BackgroundTransparency = 1
    hubSubLbl.Text = "3D Edition  •  Auto MiniGame & Scanner"
    hubSubLbl.Font = Enum.Font.Gotham
    hubSubLbl.TextSize = 11
    hubSubLbl.TextColor3 = PALETTE.TextSecondary
    hubSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubSubLbl.Parent = topbar

    -- ปุ่มควบคุมหน้าต่างแบบ 3D กดยุบตัวได้
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
        base.BackgroundColor3 = isClose and Color3.fromRGB(115, 25, 38) or PALETTE.GoldDark
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
        stroke(btn, isClose and PALETTE.Danger or PALETTE.Gold, 1, 0.45)

        btn.MouseEnter:Connect(function()
            tween(btn, 0.12, {
                BackgroundColor3 = isClose and PALETTE.Danger or PALETTE.RowHighlight,
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

    -- พื้นที่การ์ดด้านในแบบ 3D
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -28, 1, -80)
    content.Position = UDim2.fromOffset(14, 66)
    content.BackgroundColor3 = PALETTE.CardBase
    content.BorderSizePixel = 0
    content.Parent = main
    round(content, 12)
    stroke(content, PALETTE.Gold, 1, 0.72)

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 12)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = content

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = content

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
        stroke(card, PALETTE.Gold, 1, 0.78)
        return card
    end

    -- แถวที่ 1: สวิตช์เปิด-ปิดเล่นมินิเกมอัตโนมัติ
    local row1 = make3DRow(1, 56)

    local lbl1 = Instance.new("TextLabel")
    lbl1.Size = UDim2.new(1, -105, 0, 20)
    lbl1.Position = UDim2.fromOffset(14, 8)
    lbl1.BackgroundTransparency = 1
    lbl1.Text = "เล่นมินิเกมที่เด้งขึ้นมาอัตโนมัติ"
    lbl1.Font = Enum.Font.GothamBold
    lbl1.TextSize = 13
    lbl1.TextColor3 = PALETTE.TextPrimary
    lbl1.TextXAlignment = Enum.TextXAlignment.Left
    lbl1.Parent = row1

    local sub1 = Instance.new("TextLabel")
    sub1.Size = UDim2.new(1, -105, 0, 16)
    sub1.Position = UDim2.fromOffset(14, 30)
    sub1.BackgroundTransparency = 1
    sub1.Text = "ตรวจจับหน้าต่างมินิเกมและเล่นให้อัตโนมัติ"
    sub1.Font = Enum.Font.Gotham
    sub1.TextSize = 11
    sub1.TextColor3 = PALETTE.TextSecondary
    sub1.TextXAlignment = Enum.TextXAlignment.Left
    sub1.Parent = row1

    local tag1 = Instance.new("TextLabel")
    tag1.Size = UDim2.fromOffset(34, 16)
    tag1.Position = UDim2.new(1, -98, 0.5, -8)
    tag1.BackgroundTransparency = 1
    tag1.Text = Config.AutoMiniGame and "ON" or "OFF"
    tag1.Font = Enum.Font.GothamBlack
    tag1.TextSize = 10
    tag1.TextColor3 = Config.AutoMiniGame and PALETTE.Success or PALETTE.TextMuted
    tag1.Parent = row1

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.fromOffset(46, 24)
    sw.Position = UDim2.new(1, -58, 0.5, -12)
    sw.BackgroundColor3 = Config.AutoMiniGame and PALETTE.Gold or PALETTE.OffTrack
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = row1
    round(sw, 12)
    stroke(sw, PALETTE.GoldBright, 1, 0.55)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = Config.AutoMiniGame and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    round(knob, 9)

    sw.MouseButton1Click:Connect(function()
        Config.AutoMiniGame = not Config.AutoMiniGame
        local on = Config.AutoMiniGame
        tag1.Text = on and "ON" or "OFF"
        tag1.TextColor3 = on and PALETTE.Success or PALETTE.TextMuted
        tween(sw, 0.14, { BackgroundColor3 = on and PALETTE.Gold or PALETTE.OffTrack })
        tween(knob, 0.14, { Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3) })
    end)

    -- แถวที่ 2: แถบเลื่อนปรับความเร็วรอบแบบ 3D
    local row2 = make3DRow(2, 56)

    local minV, maxV = 0.10, 1.50
    local cur = tonumber(Config.MiniGameSpeed) or 0.15

    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, -105, 0, 20)
    lbl2.Position = UDim2.fromOffset(14, 8)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = "ความเร็วในการกดมินิเกม"
    lbl2.Font = Enum.Font.GothamMedium
    lbl2.TextSize = 13
    lbl2.TextColor3 = PALETTE.TextPrimary
    lbl2.TextXAlignment = Enum.TextXAlignment.Left
    lbl2.Parent = row2

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.fromOffset(80, 20)
    valLbl.Position = UDim2.new(1, -94, 0, 8)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = string.format("%.2f วิ", cur)
    valLbl.Font = Enum.Font.GothamBlack
    valLbl.TextSize = 12
    valLbl.TextColor3 = PALETTE.GoldBright
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row2

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -28, 0, 8)
    track.Position = UDim2.fromOffset(14, 37)
    track.BackgroundColor3 = PALETTE.OffTrack
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row2
    round(track, 4)

    local ratio = math.clamp((cur - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(ratio, 0, 1, 0)
    fill.BackgroundColor3 = PALETTE.Gold
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, 4)
    addShimmerGradient(fill, PALETTE.GoldDark, PALETTE.GoldBright, PALETTE.Accent)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(16, 16)
    thumb.Position = UDim2.new(ratio, -8, 0.5, -8)
    thumb.BackgroundColor3 = PALETTE.GoldBright
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

    -- แถวที่ 3: ปุ่มสแกนเกมแบบ 3D กดยุบตัวได้
    local row3 = make3DRow(3, 56)

    local lbl3 = Instance.new("TextLabel")
    lbl3.Size = UDim2.new(1, -160, 0, 20)
    lbl3.Position = UDim2.fromOffset(14, 8)
    lbl3.BackgroundTransparency = 1
    lbl3.Text = "สแกนไฟล์และโครงสร้างเกม"
    lbl3.Font = Enum.Font.GothamBold
    lbl3.TextSize = 13
    lbl3.TextColor3 = PALETTE.TextPrimary
    lbl3.TextXAlignment = Enum.TextXAlignment.Left
    lbl3.Parent = row3

    local sub3 = Instance.new("TextLabel")
    sub3.Size = UDim2.new(1, -160, 0, 16)
    sub3.Position = UDim2.fromOffset(14, 30)
    sub3.BackgroundTransparency = 1
    sub3.Text = "แสดงรายชื่อ Remote, GUI และวัตถุในแมพที่ Console"
    sub3.Font = Enum.Font.Gotham
    sub3.TextSize = 11
    sub3.TextColor3 = PALETTE.TextSecondary
    sub3.TextXAlignment = Enum.TextXAlignment.Left
    sub3.Parent = row3

    local scanHolder = Instance.new("Frame")
    scanHolder.Size = UDim2.fromOffset(134, 36)
    scanHolder.Position = UDim2.new(1, -146, 0.5, -18)
    scanHolder.BackgroundTransparency = 1
    scanHolder.Parent = row3

    local scanBase = Instance.new("Frame")
    scanBase.Size = UDim2.fromOffset(134, 32)
    scanBase.Position = UDim2.fromOffset(0, 4)
    scanBase.BackgroundColor3 = PALETTE.GoldDark
    scanBase.BorderSizePixel = 0
    scanBase.Parent = scanHolder
    round(scanBase, 8)

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.fromOffset(134, 32)
    scanBtn.Position = UDim2.fromOffset(0, 0)
    scanBtn.BackgroundColor3 = PALETTE.Accent
    scanBtn.Text = "สแกนเกม"
    scanBtn.Font = Enum.Font.GothamBlack
    scanBtn.TextSize = 12
    scanBtn.TextColor3 = Color3.new(1, 1, 1)
    scanBtn.AutoButtonColor = false
    scanBtn.Parent = scanHolder
    round(scanBtn, 8)
    stroke(scanBtn, PALETTE.GoldBright, 1, 0.35)
    addShimmerGradient(scanBtn, Color3.fromRGB(150, 98, 255), Color3.fromRGB(102, 58, 215), PALETTE.GoldDark)

    scanBtn.MouseButton1Down:Connect(function()
        tween(scanBtn, 0.06, { Position = UDim2.fromOffset(0, 3) })
    end)
    scanBtn.MouseButton1Up:Connect(function()
        tween(scanBtn, 0.10, { Position = UDim2.fromOffset(0, 0) })
    end)

    scanBtn.MouseButton1Click:Connect(function()
        Config.ScanNow = true
        scanBtn.Text = "กำลังสแกน..."
        task.delay(0.8, function()
            if scanBtn and scanBtn.Parent then
                scanBtn.Text = "สแกนเกม OK"
                task.delay(0.8, function()
                    if scanBtn and scanBtn.Parent then
                        scanBtn.Text = "สแกนเกม"
                    end
                end)
            end
        end)
    end)

    -- ลูปหมุนแสง Shimmer ขอบทอง-ม่วงอัตโนมัติ
    local rot = 0
    local animConn
    animConn = RunService.RenderStepped:Connect(function(dt)
        if not screenGui or not screenGui.Parent then
            if animConn then
                animConn:Disconnect()
            end
            return
        end
        rot = (rot + dt * 75) % 360
        mainStrokeGrad.Rotation = rot
        miniStrokeGrad.Rotation = -rot
    end)

    print("[UI] Mounted 3D Dark & Gold Edition")
end

return UI