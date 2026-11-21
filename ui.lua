local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local UI = {}

local PALETTE = {
    WindowBg = Color3.fromRGB(14, 14, 18),
    SidebarBg = Color3.fromRGB(11, 11, 14),
    TopbarBg = Color3.fromRGB(17, 17, 22),
    CardBg = Color3.fromRGB(21, 21, 27),
    RowBg = Color3.fromRGB(27, 27, 35),
    RowHover = Color3.fromRGB(33, 33, 43),
    TabActive = Color3.fromRGB(30, 26, 44),
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

    -- ปุ่มลอยเปิด/ปิดหน้าต่าง (เผื่อพับหรือปิดแล้วเปิดใหม่)
    local quickToggle = Instance.new("TextButton")
    quickToggle.Name = "QuickToggleBtn"
    quickToggle.Size = UDim2.fromOffset(118, 34)
    quickToggle.Position = UDim2.new(0, 16, 0.5, -17)
    quickToggle.BackgroundColor3 = PALETTE.TopbarBg
    quickToggle.Text = "✦  " .. titleText
    quickToggle.Font = Enum.Font.GothamBold
    quickToggle.TextSize = 12
    quickToggle.TextColor3 = PALETTE.TextPrimary
    quickToggle.Visible = false
    quickToggle.Parent = screenGui
    round(quickToggle, 8)
    stroke(quickToggle, PALETTE.BorderAccent, 1.2, 0.25)

    -- หน้าต่างหลัก
    local main = Instance.new("Frame")
    main.Name = "MainWindow"
    main.Size = UDim2.fromOffset(880, 535)
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

    -- Topbar
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

    local logoGrad = Instance.new("UIGradient")
    logoGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(156, 112, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(92, 48, 224)),
    })
    logoGrad.Rotation = 135
    logoGrad.Parent = logoBox

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
    hubSubLbl.Size = UDim2.fromOffset(320, 16)
    hubSubLbl.Position = UDim2.fromOffset(54, 28)
    hubSubLbl.BackgroundTransparency = 1
    hubSubLbl.Text = "Pro Control Panel  •  PlaceId 93898234979111"
    hubSubLbl.Font = Enum.Font.Gotham
    hubSubLbl.TextSize = 11
    hubSubLbl.TextColor3 = PALETTE.TextSecondary
    hubSubLbl.TextXAlignment = Enum.TextXAlignment.Left
    hubSubLbl.Parent = topbar

    -- ป้ายสถานะออนไลน์มุมขวาบน
    local statusPill = Instance.new("Frame")
    statusPill.Size = UDim2.fromOffset(92, 24)
    statusPill.Position = UDim2.new(1, -176, 0.5, -12)
    statusPill.BackgroundColor3 = PALETTE.RowBg
    statusPill.BorderSizePixel = 0
    statusPill.Parent = topbar
    round(statusPill, 12)
    stroke(statusPill, PALETTE.Border, 1, 0.2)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.fromOffset(7, 7)
    dot.Position = UDim2.fromOffset(10, 8.5)
    dot.BackgroundColor3 = PALETTE.Success
    dot.BorderSizePixel = 0
    dot.Parent = statusPill
    round(dot, 4)

    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -24, 1, 0)
    statusText.Position = UDim2.fromOffset(22, 0)
    statusText.BackgroundTransparency = 1
    statusText.Text = "READY"
    statusText.Font = Enum.Font.GothamBold
    statusText.TextSize = 10
    statusText.TextColor3 = PALETTE.Success
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = statusPill

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
    local closeBtn = makeWinBtn("✕", -40, true)

    local isCollapsed = false
    minBtn.MouseButton1Click:Connect(function()
        isCollapsed = not isCollapsed
        tween(main, 0.18, {
            Size = isCollapsed and UDim2.fromOffset(880, 52) or UDim2.fromOffset(880, 535),
        })
    end)

    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
        quickToggle.Visible = true
    end)

    quickToggle.MouseButton1Click:Connect(function()
        quickToggle.Visible = false
        main.Visible = true
    end)

    -- ลากหน้าต่าง
    local dragging, dragOrigin, winOrigin = false, nil, nil
    topbar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragOrigin = inp.Position
            winOrigin = main.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local d = inp.Position - dragOrigin
            main.Position = UDim2.new(
                winOrigin.X.Scale,
                winOrigin.X.Offset + d.X,
                winOrigin.Y.Scale,
                winOrigin.Y.Offset + d.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Sidebar ซ้าย
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 196, 1, -52)
    sidebar.Position = UDim2.fromOffset(0, 52)
    sidebar.BackgroundColor3 = PALETTE.SidebarBg
    sidebar.BackgroundTransparency = 0.25
    sidebar.BorderSizePixel = 0
    sidebar.Parent = main

    local sideLine = Instance.new("Frame")
    sideLine.Size = UDim2.new(0, 1, 1, 0)
    sideLine.Position = UDim2.new(1, -1, 0, 0)
    sideLine.BackgroundColor3 = PALETTE.Border
    sideLine.BorderSizePixel = 0
    sideLine.Parent = sidebar

    local userCard = Instance.new("Frame")
    userCard.Size = UDim2.new(1, -20, 0, 44)
    userCard.Position = UDim2.fromOffset(10, 12)
    userCard.BackgroundColor3 = PALETTE.CardBg
    userCard.BorderSizePixel = 0
    userCard.Parent = sidebar
    round(userCard, 8)
    stroke(userCard, PALETTE.Border, 1, 0.35)

    local userLbl = Instance.new("TextLabel")
    userLbl.Size = UDim2.new(1, -16, 1, 0)
    userLbl.Position = UDim2.fromOffset(12, 0)
    userLbl.BackgroundTransparency = 1
    userLbl.Text = "👤  " .. LocalPlayer.DisplayName
    userLbl.Font = Enum.Font.GothamBold
    userLbl.TextSize = 12
    userLbl.TextColor3 = PALETTE.TextPrimary
    userLbl.TextXAlignment = Enum.TextXAlignment.Left
    userLbl.TextTruncate = Enum.TextTruncate.AtEnd
    userLbl.Parent = userCard

    local navHolder = Instance.new("Frame")
    navHolder.Size = UDim2.new(1, -20, 1, -72)
    navHolder.Position = UDim2.fromOffset(10, 64)
    navHolder.BackgroundTransparency = 1
    navHolder.Parent = sidebar

    local navLayout = Instance.new("UIListLayout")
    navLayout.Padding = UDim.new(0, 5)
    navLayout.SortOrder = Enum.SortOrder.LayoutOrder
    navLayout.Parent = navHolder

    -- Content Area ขวา
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -196, 1, -52)
    content.Position = UDim2.fromOffset(196, 52)
    content.BackgroundTransparency = 1
    content.Parent = main

    local pages = {}
    local tabs = {}

    local function activateTab(id)
        for k, p in pairs(pages) do
            p.Visible = (k == id)
        end
        for k, t in pairs(tabs) do
            local active = (k == id)
            tween(t.Btn, 0.14, {
                BackgroundColor3 = active and PALETTE.TabActive or PALETTE.SidebarBg,
                BackgroundTransparency = active and 0.15 or 1,
            })
            t.Bar.Visible = active
            t.Text.TextColor3 = active and PALETTE.TextPrimary or PALETTE.TextSecondary
            t.Text.Font = active and Enum.Font.GothamBold or Enum.Font.GothamMedium
        end
    end

    local function createPage(id, icon, name, order)
        local btn = Instance.new("TextButton")
        btn.Name = "Tab_" .. id
        btn.LayoutOrder = order
        btn.Size = UDim2.new(1, 0, 0, 38)
        btn.BackgroundColor3 = PALETTE.TabActive
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = navHolder
        round(btn, 8)

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 3, 0, 20)
        bar.Position = UDim2.new(0, 4, 0.5, -10)
        bar.BackgroundColor3 = PALETTE.Accent
        bar.BorderSizePixel = 0
        bar.Visible = false
        bar.Parent = btn
        round(bar, 2)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -22, 1, 0)
        lbl.Position = UDim2.fromOffset(16, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. "   " .. name
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = PALETTE.TextSecondary
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        local page = Instance.new("ScrollingFrame")
        page.Name = "Page_" .. id
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = PALETTE.Accent
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = content

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 14)
        pad.PaddingBottom = UDim.new(0, 16)
        pad.PaddingLeft = UDim.new(0, 14)
        pad.PaddingRight = UDim.new(0, 14)
        pad.Parent = page

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 12)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        btn.MouseButton1Click:Connect(function()
            activateTab(id)
        end)

        pages[id] = page
        tabs[id] = { Btn = btn, Bar = bar, Text = lbl }
        return page
    end

    local function createCard(page, title, badgeTxt, order)
        local card = Instance.new("Frame")
        card.LayoutOrder = order
        card.Size = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = PALETTE.CardBg
        card.BackgroundTransparency = 0.1
        card.BorderSizePixel = 0
        card.Parent = page
        round(card, 10)
        stroke(card, PALETTE.Border, 1, 0.25)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 12)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = card

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = card

        local head = Instance.new("Frame")
        head.LayoutOrder = 0
        head.Size = UDim2.new(1, 0, 0, 24)
        head.BackgroundTransparency = 1
        head.Parent = card

        local titleLbl = Instance.new("TextLabel")
        titleLbl.Size = UDim2.new(1, -110, 1, 0)
        titleLbl.BackgroundTransparency = 1
        titleLbl.Text = title
        titleLbl.Font = Enum.Font.GothamBold
        titleLbl.TextSize = 13
        titleLbl.TextColor3 = PALETTE.TextPrimary
        titleLbl.TextXAlignment = Enum.TextXAlignment.Left
        titleLbl.Parent = head

        if badgeTxt then
            local badge = Instance.new("TextLabel")
            badge.Size = UDim2.fromOffset(96, 20)
            badge.Position = UDim2.new(1, -96, 0.5, -10)
            badge.BackgroundColor3 = PALETTE.RowBg
            badge.Text = badgeTxt
            badge.Font = Enum.Font.GothamBold
            badge.TextSize = 10
            badge.TextColor3 = PALETTE.TextSecondary
            badge.Parent = head
            round(badge, 6)
        end

        return card
    end

    local function createToggle(card, title, desc, key, order)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, desc and 52 or 40)
        row.BackgroundColor3 = PALETTE.RowBg
        row.BorderSizePixel = 0
        row.Parent = card
        round(row, 8)
        stroke(row, PALETTE.Border, 1, 0.65)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -82, 0, 20)
        lbl.Position = UDim2.fromOffset(12, desc and 7 or 10)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = PALETTE.TextPrimary
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        if desc then
            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(1, -82, 0, 16)
            sub.Position = UDim2.fromOffset(12, 28)
            sub.BackgroundTransparency = 1
            sub.Text = desc
            sub.Font = Enum.Font.Gotham
            sub.TextSize = 11
            sub.TextColor3 = PALETTE.TextSecondary
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.Parent = row
        end

        local tag = Instance.new("TextLabel")
        tag.Size = UDim2.fromOffset(32, 16)
        tag.Position = UDim2.new(1, -94, 0.5, -8)
        tag.BackgroundTransparency = 1
        tag.Text = Config[key] and "ON" or "OFF"
        tag.Font = Enum.Font.GothamBold
        tag.TextSize = 10
        tag.TextColor3 = Config[key] and PALETTE.Success or PALETTE.TextMuted
        tag.Parent = row

        local sw = Instance.new("TextButton")
        sw.Size = UDim2.fromOffset(44, 24)
        sw.Position = UDim2.new(1, -56, 0.5, -12)
        sw.BackgroundColor3 = Config[key] and PALETTE.Accent or PALETTE.OffTrack
        sw.Text = ""
        sw.AutoButtonColor = false
        sw.Parent = row
        round(sw, 12)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(18, 18)
        knob.Position = Config[key] and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = sw
        round(knob, 9)

        row.MouseEnter:Connect(function()
            tween(row, 0.12, { BackgroundColor3 = PALETTE.RowHover })
        end)
        row.MouseLeave:Connect(function()
            tween(row, 0.12, { BackgroundColor3 = PALETTE.RowBg })
        end)

        sw.MouseButton1Click:Connect(function()
            Config[key] = not Config[key]
            local on = Config[key]
            tag.Text = on and "ON" or "OFF"
            tag.TextColor3 = on and PALETTE.Success or PALETTE.TextMuted
            tween(sw, 0.14, { BackgroundColor3 = on and PALETTE.Accent or PALETTE.OffTrack })
            tween(knob, 0.14, { Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) })
        end)
    end

    local function createSlider(card, title, minV, maxV, suffix, key, order)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 54)
        row.BackgroundColor3 = PALETTE.RowBg
        row.BorderSizePixel = 0
        row.Parent = card
        round(row, 8)
        stroke(row, PALETTE.Border, 1, 0.65)

        local cur = tonumber(Config[key]) or minV

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -100, 0, 20)
        lbl.Position = UDim2.fromOffset(12, 7)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = PALETTE.TextPrimary
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.fromOffset(80, 20)
        valLbl.Position = UDim2.new(1, -92, 0, 7)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(cur) .. (suffix or "")
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12
        valLbl.TextColor3 = PALETTE.Accent
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        local track = Instance.new("TextButton")
        track.Size = UDim2.new(1, -24, 0, 7)
        track.Position = UDim2.fromOffset(12, 36)
        track.BackgroundColor3 = PALETTE.OffTrack
        track.Text = ""
        track.AutoButtonColor = false
        track.Parent = row
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

        local draggingSlider = false
        local function applyX(px)
            local r = math.clamp((px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
            local v = math.floor(minV + (maxV - minV) * r + 0.5)
            Config[key] = v
            valLbl.Text = tostring(v) .. (suffix or "")
            fill.Size = UDim2.new(r, 0, 1, 0)
            thumb.Position = UDim2.new(r, -7.5, 0.5, -7.5)
        end

        track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = true
                applyX(inp.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if draggingSlider and inp.UserInputType == Enum.UserInputType.MouseMovement then
                applyX(inp.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                draggingSlider = false
            end
        end)
    end

    local function createActionBtn(card, title, desc, onClick, order)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 48)
        row.BackgroundColor3 = PALETTE.RowBg
        row.BorderSizePixel = 0
        row.Parent = card
        round(row, 8)
        stroke(row, PALETTE.Border, 1, 0.65)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -155, 0, 20)
        lbl.Position = UDim2.fromOffset(12, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = PALETTE.TextPrimary
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1, -155, 0, 16)
        sub.Position = UDim2.fromOffset(12, 26)
        sub.BackgroundTransparency = 1
        sub.Text = desc
        sub.Font = Enum.Font.Gotham
        sub.TextSize = 11
        sub.TextColor3 = PALETTE.TextSecondary
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.Parent = row

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.fromOffset(132, 30)
        btn.Position = UDim2.new(1, -144, 0.5, -15)
        btn.BackgroundColor3 = PALETTE.AccentSoft
        btn.Text = "กดเพื่อทำงาน"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = PALETTE.TextPrimary
        btn.Parent = row
        round(btn, 7)
        stroke(btn, PALETTE.BorderAccent, 1, 0.35)

        btn.MouseButton1Click:Connect(function()
            btn.Text = "กำลังทำ..."
            pcall(onClick)
            task.delay(0.8, function()
                if btn and btn.Parent then
                    btn.Text = "สำเร็จ ✓"
                    task.delay(0.8, function()
                        if btn and btn.Parent then
                            btn.Text = "กดเพื่อทำงาน"
                        end
                    end)
                end
            end)
        end)
    end

    -- สร้าง 6 แท็บ
    local pFish    = createPage("fish", "🐟", "ตกปลา", 1)
    local pCooler  = createPage("cooler", "📦", "กล่องปลา", 2)
    local pUpgrade = createPage("upgrade", "⬆️", "อัปเกรด", 3)
    local pReward  = createPage("reward", "🎁", "รางวัล", 4)
    local pArena   = createPage("arena", "⚔️", "อารีนา", 5)
    local pSetting = createPage("setting", "⚙️", "ตั้งค่า", 6)

    -- 1. ตกปลา
    local cFishMain = createCard(pFish, "Main • การจับปลา", "AUTO FARM", 1)
    createToggle(cFishMain, "จับปลาอัตโนมัติ", "โยนอวน เล็งเป้าหมาย และยืนยันการจับต่อเนื่อง", "AutoCatch", 1)
    createToggle(cFishMain, "ดึงอวนเมื่อเต็มอัตโนมัติ", "สั่ง ReelIn และเช็กสถานะ NetFull ต่อเนื่อง", "AutoReelFull", 2)

    local cFishPad = createCard(pFish, "อื่น ๆ • เก็บเงินและแท่น", "PAD & CASH", 2)
    createSlider(cFishPad, "รอบการเก็บเงิน/เช็กแท่น", 5, 120, " วิ", "CollectInterval", 1)
    createToggle(cFishPad, "วาร์ปไปเหยียบแท่น", "ย้ายตัวละครไปยังแท่น/จุดเก็บเงินตามรอบที่ตั้ง", "WarpToPad", 2)
    createToggle(cFishPad, "เก็บเงินอัตโนมัติ", "ยิง CollectPadReq เพื่อเก็บเงินและของตกหล่น", "AutoCollectCash", 3)

    local cFishEvt = createCard(pFish, "อีเวนต์ • บอสและรีเบิร์ธ", "BOSS & REBIRTH", 3)
    createToggle(cFishEvt, "ยิงเมกาโลดอนอัตโนมัติ", "ตรวจจับ MegalodonLocal / BossEvent แล้วสั่งยิง", "AutoShootMeg", 1)
    createToggle(cFishEvt, "ยิง Bloop อัตโนมัติ", "ตรวจจับ BloopLocal แล้วสั่งยิงอัตโนมัติ", "AutoShootBloop", 2)
    createToggle(cFishEvt, "รีเบิร์ธอัตโนมัติ", "ส่ง RebirthRequest เมื่อถึงเงื่อนไข", "AutoRebirth", 3)

    -- 2. กล่องปลา
    local cCoolMain = createCard(pCooler, "Main • จัดการปลาและขาย", "INVENTORY", 1)
    createToggle(cCoolMain, "ใส่ปลาที่ดีที่สุดอัตโนมัติ", "เรียก BestSetup / PlaceFish อัตโนมัติ", "AutoEquipBest", 1)
    createToggle(cCoolMain, "ฟิวส์ทั้งหมดอัตโนมัติ", "เรียก CoolerAction / HotbarAction สำหรับฟิวส์ปลา", "AutoFuseAll", 2)
    createSlider(cCoolMain, "รอบการขายปลา", 5, 180, " วิ", "SellInterval", 3)
    createToggle(cCoolMain, "ขายปลาอัตโนมัติ", "ยิง SellFish ตามรอบเวลาที่ตั้งไว้", "AutoSell", 4)

    local cCoolPot = createCard(pCooler, "ยา • บูสต์และโพชัน", "POTIONS", 2)
    createToggle(cCoolPot, "ซื้อยาอัตโนมัติ", "เรียก Potions / BuyItem สำหรับเติมยา", "AutoBuyPotion", 1)
    createToggle(cCoolPot, "ใช้ยาอัตโนมัติ", "เปิดใช้งานยาบูสต์ในคลังอัตโนมัติ", "AutoUsePotion", 2)

    -- 3. อัปเกรด
    local cUpg1 = createCard(pUpgrade, "อวน & ค่าสถานะ", "UPGRADES", 1)
    createToggle(cUpg1, "ซื้ออวนขั้นถัดไปอัตโนมัติ", "เช็กและซื้อ Gear / อวนอัตโนมัติ", "AutoUpgradeNet", 1)
    createToggle(cUpg1, "อัปเกรดสกิลทั้งหมดอัตโนมัติ", "อัปเกรด SkillTree อัตโนมัติ", "AutoUpgradeAllSkills", 2)
    createToggle(cUpg1, "อัปเกรดค่าพลังตกปลาทั้งหมด", "อัปเกรดค่าสถานะการจับปลาอัตโนมัติ", "AutoUpgradeAllFishing", 3)

    -- 4. รางวัล
    local cRew1 = createCard(pReward, "Main • เก็บรางวัลและโบนัส", "REWARDS", 1)
    createToggle(cRew1, "รับรางวัล Index อัตโนมัติ", "รับรางวัลสมุดปลา IndexPage", "AutoClaimIndex", 1)
    createToggle(cRew1, "หมุนวงล้ออัตโนมัติ", "กดรับ/หมุนรางวัล Rewards อัตโนมัติ", "AutoSpin", 2)
    createToggle(cRew1, "รับของขวัญออนไลน์ + รายวันอัตโนมัติ", "เก็บของขวัญสะสมเวลารายวัน", "AutoClaimDaily", 3)
    createToggle(cRew1, "รับรางวัลเควสต์อัตโนมัติ", "เคลมรางวัล Challenge / เควสต์", "AutoClaimQuest", 4)
    createToggle(cRew1, "ใส่ Trait ดีสุดอัตโนมัติ", "อัปเดต Trait ที่ดีที่สุด", "AutoEquipTrait", 5)
    createToggle(cRew1, "รับรางวัล Season Pass อัตโนมัติ", "เคลมของรางวัล SeasonPass", "AutoClaimPass", 6)

    -- 5. อารีนา
    local cArena1 = createCard(pArena, "Main • โหมดต่อสู้อารีนา", "ARENA", 1)
    createToggle(cArena1, "ตีอารีนาอัตโนมัติ", "เรียกใช้งานระบบ Arena อัตโนมัติ", "AutoArena", 1)

    -- 6. ตั้งค่า
    local cSet1 = createCard(pSetting, "ระบบป้องกันและประสิทธิภาพ", "SYSTEM", 1)
    createToggle(cSet1, "กันหลุด AFK", "ส่งสัญญาณกันหลุดห้องอัตโนมัติ (แนะนำให้เปิด)", "AntiAFK", 1)
    createToggle(cSet1, "โหมดสเปกต่ำ", "ลดรายละเอียดเอฟเฟกต์/เงาเพื่อเพิ่ม FPS", "LowGraphics", 2)
    createActionBtn(cSet1, "สแกน Remote & โฟลเดอร์แมพ", "พิมพ์รายชื่อ Remote และวัตถุในเกมลง Console", function()
        Config.ScanNow = true
    end, 3)

    activateTab("fish")
    print("[UI] Mounted Pro Layout")
end

return UI