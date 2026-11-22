local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local UI = {}

local PALETTE = {
    WindowBg = Color3.fromRGB(14, 14, 18),
    TopbarBg = Color3.fromRGB(17, 17, 22),
    CardBg = Color3.fromRGB(21, 21, 27),
    RowBg = Color3.fromRGB(27, 27, 35),
    RowHover = Color3.fromRGB(33, 33, 43),
    Border = Color3.fromRGB(44, 44, 56),
    BorderAccent = Color3.fromRGB(124, 77, 255),
    Accent = Color3.fromRGB(132, 86, 255),
    AccentSoft = Color3.fromRGB(58, 41, 102),
    OffTrack = Color3.fromRGB(54, 54, 64),
    TextPrimary = Color3.fromRGB(246, 246, 252),
    TextSecondary = Color3.fromRGB(154, 154, 170),
    TextMuted = Color3.fromRGB(112, 112, 128),
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
    s.Color = col or PALETTE.Border
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

    local miniIcon = Instance.new("TextButton")
    miniIcon.Name = "MiniIconBtn"
    miniIcon.Size = UDim2.fromOffset(52, 52)
    miniIcon.Position = UDim2.new(0, 18, 0.25, 0)
    miniIcon.BackgroundColor3 = PALETTE.TopbarBg
    miniIcon.Text = ""
    miniIcon.AutoButtonColor = false
    miniIcon.Visible = false
    miniIcon.Parent = screenGui
    round(miniIcon, 12)
    stroke(miniIcon, PALETTE.BorderAccent, 1.5, 0.15)

    local miniBadge = Instance.new("Frame")
    miniBadge.Size = UDim2.fromOffset(36, 36)
    miniBadge.Position = UDim2.fromScale(0.5, 0.5)
    miniBadge.AnchorPoint = Vector2.new(0.5, 0.5)
    miniBadge.BackgroundColor3 = PALETTE.Accent
    miniBadge.BorderSizePixel = 0
    miniBadge.Parent = miniIcon
    round(miniBadge, 8)

    local miniText = Instance.new("TextLabel")
    miniText.Size = UDim2.fromScale(1, 1)
    miniText.BackgroundTransparency = 1
    miniText.Text = "TH"
    miniText.Font = Enum.Font.GothamBlack
    miniText.TextSize = 14
    miniText.TextColor3 = Color3.new(1, 1, 1)
    miniText.Parent = miniBadge

    local main = Instance.new("Frame")
    main.Name = "MainWindow"
    main.Size = UDim2.fromOffset(540, 325)
    main.Position = UDim2.fromScale(0.5, 0.5)
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.BackgroundColor3 = PALETTE.WindowBg
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = screenGui
    round(main, 12)
    stroke(main, PALETTE.Border, 1.2, 0.1)

    local gradBg = Instance.new("UIGradient")
    gradBg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 20, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(13, 13, 17)),
    })
    gradBg.Rotation = 35
    gradBg.Parent = main

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 52)
    topbar.BackgroundColor3 = PALETTE.TopbarBg
    topbar.BackgroundTransparency = 0.15
    topbar.BorderSizePixel = 0
    topbar.Parent = main

    local topLine = Instance.new("Frame")
    topLine.Size = UDim2.new(1, 0, 0, 1)
    topLine.Position = UDim2.new(0, 0, 1, -1)
    topLine.BackgroundColor3 = PALETTE.Border
    topLine.BorderSizePixel = 0
    topLine.Parent = topbar

    local logoBox = Instance.new("Frame")
    logoBox.Size = UDim2.fromOffset(32, 32)
    logoBox.Position = UDim2.fromOffset(14, 10)
    logoBox.BackgroundColor3 = PALETTE.Accent
    logoBox.BorderSizePixel = 0
    logoBox.Parent = topbar
    round(logoBox, 8)

    local logoLbl = Instance.new("TextLabel")
    logoLbl.Size = UDim2.fromScale(1, 1)
    logoLbl.BackgroundTransparency = 1
    logoLbl.Text = "TH"
    logoLbl.Font = Enum.Font.GothamBlack
    logoLbl.TextSize = 13
    logoLbl.TextColor3 = Color3.new(1, 1, 1)
    logoLbl.Parent = logoBox

    local hubTitleLbl = Instance.new("TextLabel")
    hubTitleLbl.Size = UDim2.fromOffset(260, 20)
    hubTitleLbl.Position = UDim2.fromOffset(54, 8)
    hubTitleLbl.BackgroundTransparency = 1
    hubTitleLbl.Text = titleText .. "  •  NET A FISH"
    hubTitleLbl.Font = Enum.Font.GothamBold
    hubTitleLbl.TextSize = 14
    hubTitleLbl.TextColor3 = PALETTE.TextPrimary
    hubTitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubTitleLbl.Parent = topbar

    local hubSubLbl = Instance.new("TextLabel")
    hubSubLbl.Size = UDim2.fromOffset(280, 16)
    hubSubLbl.Position = UDim2.fromOffset(54, 28)
    hubSubLbl.BackgroundTransparency = 1
    hubSubLbl.Text = "Auto MiniGame & Scanner"
    hubSubLbl.Font = Enum.Font.Gotham
    hubSubLbl.TextSize = 11
    hubSubLbl.TextColor3 = PALETTE.TextSecondary
    hubSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubSubLbl.Parent = topbar

    local function makeWinBtn(txt, offsetX, isClose)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(32, 32)
        b.Position = UDim2.new(1, offsetX, 0.5, -16)
        b.BackgroundColor3 = PALETTE.RowBg
        b.BackgroundTransparency = 0.4
        b.Text = txt
        b.Font = Enum.Font.GothamBold
        b.TextSize = 13
        b.TextColor3 = PALETTE.TextSecondary
        b.Parent = topbar
        round(b, 7)

        b.MouseEnter:Connect(function()
            tween(b, 0.12, {
                BackgroundColor3 = isClose and Color3.fromRGB(185, 48, 68) or PALETTE.RowHover,
                BackgroundTransparency = 0,
                TextColor3 = PALETTE.TextPrimary,
            })
        end)
        b.MouseLeave:Connect(function()
            tween(b, 0.12, {
                BackgroundColor3 = PALETTE.RowBg,
                BackgroundTransparency = 0.4,
                TextColor3 = PALETTE.TextSecondary,
            })
        end)
        return b
    end

    local minBtn = makeWinBtn("—", -76, false)
    local closeBtn = makeWinBtn("X", -40, true)

    minBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        miniIcon.Visible = true
    end)

    closeBtn.ZIndex = 10
    minBtn.ZIndex = 10
    closeBtn.MouseButton1Click:Connect(function()
        if Config then
            Config.AutoMiniGame = false
            Config.ScanNow = false
        end
        screenGui:Destroy()
    end)

    local wasMiniDragged = makeDraggable(miniIcon, miniIcon)
    miniIcon.MouseButton1Click:Connect(function()
        if not wasMiniDragged() then
            miniIcon.Visible = false
            main.Visible = true
        end
    end)

    makeDraggable(topbar, main)

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -28, 1, -76)
    content.Position = UDim2.fromOffset(14, 64)
    content.BackgroundColor3 = PALETTE.CardBg
    content.BackgroundTransparency = 0.1
    content.BorderSizePixel = 0
    content.Parent = main
    round(content, 10)
    stroke(content, PALETTE.Border, 1, 0.25)

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

    local row1 = Instance.new("Frame")
    row1.LayoutOrder = 1
    row1.Size = UDim2.new(1, 0, 0, 54)
    row1.BackgroundColor3 = PALETTE.RowBg
    row1.BorderSizePixel = 0
    row1.Parent = content
    round(row1, 8)
    stroke(row1, PALETTE.Border, 1, 0.65)

    local lbl1 = Instance.new("TextLabel")
    lbl1.Size = UDim2.new(1, -90, 0, 20)
    lbl1.Position = UDim2.fromOffset(12, 7)
    lbl1.BackgroundTransparency = 1
    lbl1.Text = "เล่นมินิเกมที่เด้งขึ้นมาอัตโนมัติ"
    lbl1.Font = Enum.Font.GothamBold
    lbl1.TextSize = 13
    lbl1.TextColor3 = PALETTE.TextPrimary
    lbl1.TextXAlignment = Enum.TextXAlignment.Left
    lbl1.Parent = row1

    local sub1 = Instance.new("TextLabel")
    sub1.Size = UDim2.new(1, -90, 0, 16)
    sub1.Position = UDim2.fromOffset(12, 29)
    sub1.BackgroundTransparency = 1
    sub1.Text = "ตรวจจับหน้าต่างมินิเกมและยิงสัญญาณอัตโนมัติ"
    sub1.Font = Enum.Font.Gotham
    sub1.TextSize = 11
    sub1.TextColor3 = PALETTE.TextSecondary
    sub1.TextXAlignment = Enum.TextXAlignment.Left
    sub1.Parent = row1

    local tag1 = Instance.new("TextLabel")
    tag1.Size = UDim2.fromOffset(32, 16)
    tag1.Position = UDim2.new(1, -94, 0.5, -8)
    tag1.BackgroundTransparency = 1
    tag1.Text = Config.AutoMiniGame and "ON" or "OFF"
    tag1.Font = Enum.Font.GothamBold
    tag1.TextSize = 10
    tag1.TextColor3 = Config.AutoMiniGame and PALETTE.Success or PALETTE.TextMuted
    tag1.Parent = row1

    local sw = Instance.new("TextButton")
    sw.Size = UDim2.fromOffset(44, 24)
    sw.Position = UDim2.new(1, -56, 0.5, -12)
    sw.BackgroundColor3 = Config.AutoMiniGame and PALETTE.Accent or PALETTE.OffTrack
    sw.Text = ""
    sw.AutoButtonColor = false
    sw.Parent = row1
    round(sw, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.fromOffset(18, 18)
    knob.Position = Config.AutoMiniGame and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.Parent = sw
    round(knob, 9)

    sw.MouseButton1Click:Connect(function()
        Config.AutoMiniGame = not Config.AutoMiniGame
        local on = Config.AutoMiniGame
        tag1.Text = on and "ON" or "OFF"
        tag1.TextColor3 = on and PALETTE.Success or PALETTE.TextMuted
        tween(sw, 0.14, { BackgroundColor3 = on and PALETTE.Accent or PALETTE.OffTrack })
        tween(knob, 0.14, { Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) })
    end)

    local row2 = Instance.new("Frame")
    row2.LayoutOrder = 2
    row2.Size = UDim2.new(1, 0, 0, 54)
    row2.BackgroundColor3 = PALETTE.RowBg
    row2.BorderSizePixel = 0
    row2.Parent = content
    round(row2, 8)
    stroke(row2, PALETTE.Border, 1, 0.65)

    local minV, maxV = 0.10, 1.50
    local cur = tonumber(Config.MiniGameSpeed) or 0.15

    local lbl2 = Instance.new("TextLabel")
    lbl2.Size = UDim2.new(1, -100, 0, 20)
    lbl2.Position = UDim2.fromOffset(12, 7)
    lbl2.BackgroundTransparency = 1
    lbl2.Text = "ความเร็วในการกดมินิเกม"
    lbl2.Font = Enum.Font.GothamMedium
    lbl2.TextSize = 13
    lbl2.TextColor3 = PALETTE.TextPrimary
    lbl2.TextXAlignment = Enum.TextXAlignment.Left
    lbl2.Parent = row2

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.fromOffset(80, 20)
    valLbl.Position = UDim2.new(1, -92, 0, 7)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = string.format("%.2f วิ", cur)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 12
    valLbl.TextColor3 = PALETTE.Accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = row2

    local track = Instance.new("TextButton")
    track.Size = UDim2.new(1, -24, 0, 7)
    track.Position = UDim2.fromOffset(12, 36)
    track.BackgroundColor3 = PALETTE.OffTrack
    track.Text = ""
    track.AutoButtonColor = false
    track.Parent = row2
    round(track, 4)

    local ratio = math.clamp((cur - minV) / (maxV - minV), 0, 1)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(ratio, 0, 1, 0)
    fill.BackgroundColor3 = PALETTE.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    round(fill, 4)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.fromOffset(15, 15)
    thumb.Position = UDim2.new(ratio, -7.5, 0.5, -7.5)
    thumb.BackgroundColor3 = Color3.new(1, 1, 1)
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    round(thumb, 8)

    local sliding = false
    local function applyX(px)
        local r = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = minV + (maxV - minV) * r
        local v = math.floor(raw * 100 + 0.5) / 100
        Config.MiniGameSpeed = v
        valLbl.Text = string.format("%.2f วิ", v)
        fill.Size = UDim2.new(r, 0, 1, 0)
        thumb.Position = UDim2.new(r, -7.5, 0.5, -7.5)
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

    local row3 = Instance.new("Frame")
    row3.LayoutOrder = 3
    row3.Size = UDim2.new(1, 0, 0, 52)
    row3.BackgroundColor3 = PALETTE.RowBg
    row3.BorderSizePixel = 0
    row3.Parent = content
    round(row3, 8)
    stroke(row3, PALETTE.Border, 1, 0.65)

    local lbl3 = Instance.new("TextLabel")
    lbl3.Size = UDim2.new(1, -155, 0, 20)
    lbl3.Position = UDim2.fromOffset(12, 7)
    lbl3.BackgroundTransparency = 1
    lbl3.Text = "สแกนไฟล์และโครงสร้างเกม"
    lbl3.Font = Enum.Font.GothamBold
    lbl3.TextSize = 13
    lbl3.TextColor3 = PALETTE.TextPrimary
    lbl3.TextXAlignment = Enum.TextXAlignment.Left
    lbl3.Parent = row3

    local sub3 = Instance.new("TextLabel")
    sub3.Size = UDim2.new(1, -155, 0, 16)
    sub3.Position = UDim2.fromOffset(12, 29)
    sub3.BackgroundTransparency = 1
    sub3.Text = "แสดงรายชื่อ Remote, GUI และวัตถุในแมพที่ Console"
    sub3.Font = Enum.Font.Gotham
    sub3.TextSize = 11
    sub3.TextColor3 = PALETTE.TextSecondary
    sub3.TextXAlignment = Enum.TextXAlignment.Left
    sub3.Parent = row3

    local scanBtn = Instance.new("TextButton")
    scanBtn.Size = UDim2.fromOffset(132, 32)
    scanBtn.Position = UDim2.new(1, -144, 0.5, -16)
    scanBtn.BackgroundColor3 = PALETTE.AccentSoft
    scanBtn.Text = "สแกนเกม"
    scanBtn.Font = Enum.Font.GothamBold
    scanBtn.TextSize = 12
    scanBtn.TextColor3 = PALETTE.TextPrimary
    scanBtn.Parent = row3
    round(scanBtn, 7)
    stroke(scanBtn, PALETTE.BorderAccent, 1, 0.35)

    scanBtn.MouseButton1Click:Connect(function()
        Config.ScanNow = true
        scanBtn.Text = "กำลังสแกน..."
        task.delay(0.8, function()
            if scanBtn and scanBtn.Parent then
                scanBtn.Text = "สแกนเกม ✓"
                task.delay(0.8, function()
                    if scanBtn and scanBtn.Parent then
                        scanBtn.Text = "สแกนเกม"
                    end
                end)
            end
        end)
    end)

    print("[UI] Mounted Mini Icon v2")
end

return UI