local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local UI = {}

local COLORS = {
    BgMain = Color3.fromRGB(16, 16, 19),
    BgSidebar = Color3.fromRGB(13, 13, 16),
    BgTopbar = Color3.fromRGB(14, 14, 17),
    BgSection = Color3.fromRGB(22, 22, 26),
    BgRow = Color3.fromRGB(28, 28, 33),
    BgTabActive = Color3.fromRGB(32, 32, 38),
    Stroke = Color3.fromRGB(42, 42, 50),
    Accent = Color3.fromRGB(124, 77, 255),
    ToggleOff = Color3.fromRGB(58, 58, 66),
    TextMain = Color3.fromRGB(242, 242, 247),
    TextSub = Color3.fromRGB(150, 150, 162),
}

local function addCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function addStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.Stroke
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

function UI.init(Config, hubTitle)
    local titleText = hubTitle or "TER HUB"
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local old = playerGui:FindFirstChild("TerHubModernUI")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TerHubModernUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = playerGui

    -- หน้าต่างหลัก
    local window = Instance.new("Frame")
    window.Name = "MainWindow"
    window.Size = UDim2.fromOffset(860, 520)
    window.Position = UDim2.fromScale(0.5, 0.5)
    window.AnchorPoint = Vector2.new(0.5, 0.5)
    window.BackgroundColor3 = COLORS.BgMain
    window.BorderSizePixel = 0
    window.ClipsDescendants = true
    window.Parent = gui
    addCorner(window, 10)
    addStroke(window, COLORS.Stroke, 1)

    -- แถบด้านบน (Topbar)
    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 48)
    topbar.BackgroundColor3 = COLORS.BgTopbar
    topbar.BorderSizePixel = 0
    topbar.Parent = window

    local topDivider = Instance.new("Frame")
    topDivider.Size = UDim2.new(1, 0, 0, 1)
    topDivider.Position = UDim2.new(0, 0, 1, -1)
    topDivider.BackgroundColor3 = COLORS.Stroke
    topDivider.BorderSizePixel = 0
    topDivider.Parent = topbar

    local logoBadge = Instance.new("Frame")
    logoBadge.Size = UDim2.fromOffset(28, 28)
    logoBadge.Position = UDim2.fromOffset(14, 10)
    logoBadge.BackgroundColor3 = COLORS.Accent
    logoBadge.BorderSizePixel = 0
    logoBadge.Parent = topbar
    addCorner(logoBadge, 6)

    local logoText = Instance.new("TextLabel")
    logoText.Size = UDim2.fromScale(1, 1)
    logoText.BackgroundTransparency = 1
    logoText.Text = "T"
    logoText.Font = Enum.Font.GothamBold
    logoText.TextSize = 15
    logoText.TextColor3 = Color3.new(1, 1, 1)
    logoText.Parent = logoBadge

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Size = UDim2.fromOffset(320, 20)
    titleLbl.Position = UDim2.fromOffset(52, 7)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = titleText
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 14
    titleLbl.TextColor3 = COLORS.TextMain
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Parent = topbar

    local subLbl = Instance.new("TextLabel")
    subLbl.Size = UDim2.fromOffset(320, 16)
    subLbl.Position = UDim2.fromOffset(52, 26)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "Net a Fish  •  v1.0"
    subLbl.Font = Enum.Font.Gotham
    subLbl.TextSize = 11
    subLbl.TextColor3 = COLORS.TextSub
    subLbl.TextXAlignment = Enum.TextXAlignment.Left
    subLbl.Parent = topbar

    -- ปุ่มย่อ / ปิดมุมขวาบน
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(30, 30)
    minBtn.Position = UDim2.new(1, -72, 0, 9)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "—"
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 13
    minBtn.TextColor3 = COLORS.TextSub
    minBtn.Parent = topbar

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(30, 30)
    closeBtn.Position = UDim2.new(1, -38, 0, 9)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.TextColor3 = COLORS.TextSub
    closeBtn.Parent = topbar

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            window.Size = UDim2.fromOffset(860, 48)
        else
            window.Size = UDim2.fromOffset(860, 520)
        end
    end)

    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    -- ระบบลากหน้าต่างจาก Topbar
    local dragging, dragStart, startPos = false, nil, nil
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- แถบเมนูด้านซ้าย (Sidebar)
    local sidebar = Instance.new("Frame")
    sidebar.Name = "Sidebar"
    sidebar.Size = UDim2.new(0, 185, 1, -48)
    sidebar.Position = UDim2.fromOffset(0, 48)
    sidebar.BackgroundColor3 = COLORS.BgSidebar
    sidebar.BorderSizePixel = 0
    sidebar.Parent = window

    local sideDivider = Instance.new("Frame")
    sideDivider.Size = UDim2.new(0, 1, 1, 0)
    sideDivider.Position = UDim2.new(1, -1, 0, 0)
    sideDivider.BackgroundColor3 = COLORS.Stroke
    sideDivider.BorderSizePixel = 0
    sideDivider.Parent = sidebar

    -- ชื่อผู้เล่นด้านบน Sidebar
    local profileBox = Instance.new("Frame")
    profileBox.Size = UDim2.new(1, -16, 0, 38)
    profileBox.Position = UDim2.fromOffset(8, 10)
    profileBox.BackgroundTransparency = 1
    profileBox.Parent = sidebar

    local profileLbl = Instance.new("TextLabel")
    profileLbl.Size = UDim2.new(1, -12, 1, 0)
    profileLbl.Position = UDim2.fromOffset(10, 0)
    profileLbl.BackgroundTransparency = 1
    profileLbl.Text = "👤  " .. LocalPlayer.Name
    profileLbl.Font = Enum.Font.GothamMedium
    profileLbl.TextSize = 13
    profileLbl.TextColor3 = COLORS.TextSub
    profileLbl.TextXAlignment = Enum.TextXAlignment.Left
    profileLbl.Parent = profileBox

    local tabList = Instance.new("Frame")
    tabList.Size = UDim2.new(1, -16, 1, -58)
    tabList.Position = UDim2.fromOffset(8, 52)
    tabList.BackgroundTransparency = 1
    tabList.Parent = sidebar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabList

    -- พื้นที่แสดงเนื้อหาฝั่งขวา
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.Size = UDim2.new(1, -185, 1, -48)
    contentArea.Position = UDim2.fromOffset(185, 48)
    contentArea.BackgroundTransparency = 1
    contentArea.Parent = window

    local pages = {}
    local tabButtons = {}

    local function selectTab(tabKey)
        for key, page in pairs(pages) do
            page.Visible = (key == tabKey)
        end
        for key, btnObj in pairs(tabButtons) do
            if key == tabKey then
                btnObj.Button.BackgroundColor3 = COLORS.BgTabActive
                btnObj.Button.BackgroundTransparency = 0
                btnObj.Indicator.Visible = true
                btnObj.Label.TextColor3 = COLORS.TextMain
            else
                btnObj.Button.BackgroundTransparency = 1
                btnObj.Indicator.Visible = false
                btnObj.Label.TextColor3 = COLORS.TextSub
            end
        end
    end

    local function createTab(key, iconText, labelText, order)
        local btn = Instance.new("TextButton")
        btn.Name = key .. "Tab"
        btn.LayoutOrder = order
        btn.Size = UDim2.new(1, 0, 0, 36)
        btn.BackgroundColor3 = COLORS.BgTabActive
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.Parent = tabList
        addCorner(btn, 7)

        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0, 3, 0, 18)
        indicator.Position = UDim2.new(0, 3, 0.5, -9)
        indicator.BackgroundColor3 = COLORS.Accent
        indicator.BorderSizePixel = 0
        indicator.Visible = false
        indicator.Parent = btn
        addCorner(indicator, 2)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -18, 1, 0)
        lbl.Position = UDim2.fromOffset(14, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = iconText .. "   " .. labelText
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = COLORS.TextSub
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn

        local page = Instance.new("ScrollingFrame")
        page.Name = key .. "Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.ScrollBarImageColor3 = COLORS.Stroke
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Visible = false
        page.Parent = contentArea

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 14)
        pad.PaddingBottom = UDim.new(0, 14)
        pad.PaddingLeft = UDim.new(0, 14)
        pad.PaddingRight = UDim.new(0, 14)
        pad.Parent = page

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 12)
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Parent = page

        btn.MouseButton1Click:Connect(function()
            selectTab(key)
        end)

        pages[key] = page
        tabButtons[key] = {
            Button = btn,
            Indicator = indicator,
            Label = lbl,
        }
        return page
    end

    local function createSection(page, title, order)
        local card = Instance.new("Frame")
        card.LayoutOrder = order
        card.Size = UDim2.new(1, 0, 0, 0)
        card.AutomaticSize = Enum.AutomaticSize.Y
        card.BackgroundColor3 = COLORS.BgSection
        card.BorderSizePixel = 0
        card.Parent = page
        addCorner(card, 9)
        addStroke(card, COLORS.Stroke, 1)

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10)
        pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 12)
        pad.PaddingRight = UDim.new(0, 12)
        pad.Parent = card

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = card

        local secTitle = Instance.new("TextLabel")
        secTitle.LayoutOrder = 0
        secTitle.Size = UDim2.new(1, 0, 0, 22)
        secTitle.BackgroundTransparency = 1
        secTitle.Text = title
        secTitle.Font = Enum.Font.GothamBold
        secTitle.TextSize = 13
        secTitle.TextColor3 = COLORS.TextMain
        secTitle.TextXAlignment = Enum.TextXAlignment.Left
        secTitle.Parent = card

        return card
    end

    local function addToggle(section, labelText, subText, configKey, order)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, subText and 48 or 38)
        row.BackgroundColor3 = COLORS.BgRow
        row.BorderSizePixel = 0
        row.Parent = section
        addCorner(row, 7)

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -74, 0, 20)
        lbl.Position = UDim2.fromOffset(12, subText and 6 or 9)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = COLORS.TextMain
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        if subText then
            local sub = Instance.new("TextLabel")
            sub.Size = UDim2.new(1, -74, 0, 16)
            sub.Position = UDim2.fromOffset(12, 26)
            sub.BackgroundTransparency = 1
            sub.Text = subText
            sub.Font = Enum.Font.Gotham
            sub.TextSize = 11
            sub.TextColor3 = COLORS.TextSub
            sub.TextXAlignment = Enum.TextXAlignment.Left
            sub.Parent = row
        end

        local switchBtn = Instance.new("TextButton")
        switchBtn.Size = UDim2.fromOffset(42, 22)
        switchBtn.Position = UDim2.new(1, -54, 0.5, -11)
        switchBtn.BackgroundColor3 = Config[configKey] and COLORS.Accent or COLORS.ToggleOff
        switchBtn.Text = ""
        switchBtn.AutoButtonColor = false
        switchBtn.Parent = row
        addCorner(switchBtn, 11)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.fromOffset(16, 16)
        knob.Position = Config[configKey] and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
        knob.BackgroundColor3 = Color3.new(1, 1, 1)
        knob.BorderSizePixel = 0
        knob.Parent = switchBtn
        addCorner(knob, 8)

        switchBtn.MouseButton1Click:Connect(function()
            Config[configKey] = not Config[configKey]
            local state = Config[configKey]
            switchBtn.BackgroundColor3 = state and COLORS.Accent or COLORS.ToggleOff
            knob.Position = state and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3)
        end)
    end

    local function addSlider(section, labelText, minVal, maxVal, configKey, order)
        local row = Instance.new("Frame")
        row.LayoutOrder = order
        row.Size = UDim2.new(1, 0, 0, 50)
        row.BackgroundColor3 = COLORS.BgRow
        row.BorderSizePixel = 0
        row.Parent = section
        addCorner(row, 7)

        local currentVal = tonumber(Config[configKey]) or minVal

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -80, 0, 20)
        lbl.Position = UDim2.fromOffset(12, 6)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.Font = Enum.Font.GothamMedium
        lbl.TextSize = 13
        lbl.TextColor3 = COLORS.TextMain
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = row

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.fromOffset(60, 20)
        valLbl.Position = UDim2.new(1, -72, 0, 6)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = tostring(currentVal)
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextSize = 12
        valLbl.TextColor3 = COLORS.TextSub
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        local track = Instance.new("TextButton")
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.fromOffset(12, 34)
        track.BackgroundColor3 = COLORS.ToggleOff
        track.Text = ""
        track.AutoButtonColor = false
        track.Parent = row
        addCorner(track, 3)

        local ratio = math.clamp((currentVal - minVal) / (maxVal - minVal), 0, 1)
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        fill.BackgroundColor3 = COLORS.Accent
        fill.BorderSizePixel = 0
        fill.Parent = track
        addCorner(fill, 3)

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(14, 14)
        thumb.Position = UDim2.new(ratio, -7, 0.5, -7)
        thumb.BackgroundColor3 = Color3.new(1, 1, 1)
        thumb.BorderSizePixel = 0
        thumb.Parent = track
        addCorner(thumb, 7)

        local sliding = false
        local function updateSlider(mouseX)
            local rel = math.clamp((mouseX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            local newVal = math.floor(minVal + (maxVal - minVal) * rel + 0.5)
            Config[configKey] = newVal
            valLbl.Text = tostring(newVal)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -7, 0.5, -7)
        end

        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = true
                updateSlider(input.Position.X)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                sliding = false
            end
        end)
    end

    -- สร้างแท็บทั้ง 6 หมวดเหมือนในภาพ
    local tabFishing = createTab("fishing", "🐟", "ตกปลา", 1)
    local tabCooler  = createTab("cooler", "📦", "กล่องปลา", 2)
    local tabUpgrade = createTab("upgrade", "⬆️", "อัปเกรด", 3)
    local tabReward  = createTab("reward", "🎁", "รางวัล", 4)
    local tabArena   = createTab("arena", "⚔️", "อารีนา", 5)
    local tabSetting = createTab("setting", "⚙️", "ตั้งค่า", 6)

    -- 1. หน้า ตกปลา
    local secFishMain = createSection(tabFishing, "Main", 1)
    addToggle(secFishMain, "จับปลาอัตโนมัติ", "โยนอวนและจับปลาอัตโนมัติ", "AutoCatch", 1)
    addToggle(secFishMain, "ดึงอวนเมื่อเต็มอัตโนมัติ", nil, "AutoReelFull", 2)

    local secFishMisc = createSection(tabFishing, "อื่น ๆ", 2)
    addSlider(secFishMisc, "เก็บทุก (วิ)", 1, 120, "CollectInterval", 1)
    addToggle(secFishMisc, "วาร์ปไปเหยียบแท่น", nil, "WarpToPad", 2)
    addToggle(secFishMisc, "เก็บเงินอัตโนมัติ", nil, "AutoCollectCash", 3)

    local secFishEvent = createSection(tabFishing, "อีเวนต์", 3)
    addToggle(secFishEvent, "ยิงเมกาโลดอนอัตโนมัติ", "รอเมกาโลดอนโผล่", "AutoShootMeg", 1)
    addToggle(secFishEvent, "ยิง Bloop อัตโนมัติ", "รอ Bloop โผล่", "AutoShootBloop", 2)
    addToggle(secFishEvent, "รีเบิร์ธอัตโนมัติ", nil, "AutoRebirth", 3)

    -- 2. หน้า กล่องปลา
    local secCoolerMain = createSection(tabCooler, "Main", 1)
    addToggle(secCoolerMain, "ใส่ปลาที่ดีที่สุดอัตโนมัติ", nil, "AutoEquipBest", 1)
    addToggle(secCoolerMain, "ฟิวส์ทั้งหมดอัตโนมัติ", nil, "AutoFuseAll", 2)
    addSlider(secCoolerMain, "ขายทุก (วิ)", 5, 120, "SellInterval", 3)
    addToggle(secCoolerMain, "ขายอัตโนมัติ", nil, "AutoSell", 4)

    local secCoolerPotion = createSection(tabCooler, "ยา", 2)
    addToggle(secCoolerPotion, "ซื้อยาอัตโนมัติ", nil, "AutoBuyPotion", 1)
    addToggle(secCoolerPotion, "ใช้ยาอัตโนมัติ", nil, "AutoUsePotion", 2)

    -- 3. หน้า อัปเกรด
    local secUpgNet = createSection(tabUpgrade, "อวน", 1)
    addToggle(secUpgNet, "ซื้ออวนขั้นถัดไปอัตโนมัติ", nil, "AutoUpgradeNet", 1)

    local secUpgSkill = createSection(tabUpgrade, "สกิลทรี", 2)
    addToggle(secUpgSkill, "อัปเกรดสกิลทั้งหมดอัตโนมัติ", nil, "AutoUpgradeAllSkills", 1)

    local secUpgFish = createSection(tabUpgrade, "การตกปลา", 3)
    addToggle(secUpgFish, "อัปเกรดค่าพลังตกปลาทั้งหมด", nil, "AutoUpgradeAllFishing", 1)

    -- 4. หน้า รางวัล
    local secRewardMain = createSection(tabReward, "Main", 1)
    addToggle(secRewardMain, "รับรางวัล Index อัตโนมัติ", nil, "AutoClaimIndex", 1)
    addToggle(secRewardMain, "หมุนวงล้ออัตโนมัติ", nil, "AutoSpin", 2)
    addToggle(secRewardMain, "รับของขวัญออนไลน์ + รายวันอัตโนมัติ", nil, "AutoClaimDaily", 3)
    addToggle(secRewardMain, "รับรางวัลเควสต์อัตโนมัติ", nil, "AutoClaimQuest", 4)
    addToggle(secRewardMain, "ใส่ Trait ดีสุดอัตโนมัติ", nil, "AutoEquipTrait", 5)
    addToggle(secRewardMain, "รับรางวัล Season Pass อัตโนมัติ", nil, "AutoClaimPass", 6)

    -- 5. หน้า อารีนา
    local secArenaMain = createSection(tabArena, "Main", 1)
    addToggle(secArenaMain, "ตีอารีนาอัตโนมัติ", "จัดทีม 3 ตัวพลังสูงสุดอัตโนมัติ", "AutoArena", 1)

    -- 6. หน้า ตั้งค่า
    local secSetPerf = createSection(tabSetting, "Performance & Main", 1)
    addToggle(secSetPerf, "กันหลุด AFK", nil, "AntiAFK", 1)
    addToggle(secSetPerf, "โหมดสเปกต่ำ", nil, "LowGraphics", 2)

    selectTab("fishing")
    print("[UI] Mounted Modern Layout")
end

return UI