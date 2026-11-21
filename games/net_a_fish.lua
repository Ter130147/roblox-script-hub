local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local started = false
local lowGfxApplied = false

local function getRemotes()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if not r then
        return nil
    end
    return {
        ThrowNet = r:FindFirstChild("ThrowNet"),
        ReelIn = r:FindFirstChild("ReelIn"),
        ResolveCatch = r:FindFirstChild("ResolveCatch"),
        NetFull = r:FindFirstChild("NetFull"),
        SpearShot = r:FindFirstChild("SpearShot"),
        SpearAction = r:FindFirstChild("SpearAction"),
        CollectPadReq = r:FindFirstChild("CollectPadReq"),
        SellFish = r:FindFirstChild("SellFish"),
        PlaceFish = r:FindFirstChild("PlaceFish"),
        BestSetup = r:FindFirstChild("BestSetup"),
        CoolerAction = r:FindFirstChild("CoolerAction"),
        HotbarAction = r:FindFirstChild("HotbarAction"),
        Potions = r:FindFirstChild("Potions"),
        BuyItem = r:FindFirstChild("BuyItem"),
        Gear = r:FindFirstChild("Gear"),
        SkillTree = r:FindFirstChild("SkillTree"),
        IndexPage = r:FindFirstChild("IndexPage"),
        Rewards = r:FindFirstChild("Rewards"),
        Challenge = r:FindFirstChild("Challenge"),
        Traits = r:FindFirstChild("Traits"),
        SeasonPass = r:FindFirstChild("SeasonPass"),
        Arena = r:FindFirstChild("Arena"),
        RebirthRequest = r:FindFirstChild("RebirthRequest"),
        AFKState = r:FindFirstChild("AFKState"),
    }
end

local function safeFire(rem, ...)
    if rem and rem:IsA("RemoteEvent") then
        local args = { ... }
        pcall(function()
            rem:FireServer(unpack(args))
        end)
    end
end

local function safeInvoke(rem, ...)
    if rem and rem:IsA("RemoteFunction") then
        local args = { ... }
        pcall(function()
            rem:InvokeServer(unpack(args))
        end)
    end
end

local function findPosInFolder(folderName)
    local folder = workspace:FindFirstChild(folderName)
    if not folder then
        return nil
    end
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("BasePart") then
            return d.Position
        elseif d:IsA("Model") and d.PrimaryPart then
            return d.PrimaryPart.Position
        end
    end
    return nil
end

local function getDefaultTargetPos()
    return findPosInFolder("ClientFish")
        or findPosInFolder("PoolFishLocal")
        or findPosInFolder("RiverLife")
        or (function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            return hrp and (hrp.Position + hrp.CFrame.LookVector * 14) or nil
        end)()
end

local function applyLowGraphics(enable)
    if enable and not lowGfxApplied then
        lowGfxApplied = true
        pcall(function()
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 9e9
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then
                    v.Enabled = false
                elseif v:IsA("BasePart") then
                    v.Material = Enum.Material.SmoothPlastic
                end
            end
        end)
    elseif not enable and lowGfxApplied then
        lowGfxApplied = false
        pcall(function()
            Lighting.GlobalShadows = true
        end)
    end
end

local function runScan()
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    print("=== TER HUB SCAN (NET A FISH) ===")
    if r then
        for _, item in ipairs(r:GetChildren()) do
            print(item.ClassName, "->", item.Name)
        end
    end
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Folder") or child:IsA("Model") then
            print("Workspace:", child.ClassName, "->", child.Name)
        end
    end
end

function GameModule.init(Config, Utils)
    if started then
        return
    end
    started = true

    -- กันหลุด AFK
    LocalPlayer.Idled:Connect(function()
        if Config and Config.AntiAFK then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
            local rem = getRemotes()
            if rem then
                safeFire(rem.AFKState, false)
            end
        end
    end)

    local lastCollect = 0
    local lastSell = 0
    local lastUtility = 0

    task.spawn(function()
        while started do
            local now = tick()
            local rem = getRemotes()

            if Config.ScanNow then
                Config.ScanNow = false
                runScan()
            end

            applyLowGraphics(Config.LowGraphics == true)

            if rem then
                -- 1. จับปลา & ดึงอวน
                if Config.AutoCatch then
                    local pos = getDefaultTargetPos()
                    if pos then
                        safeFire(rem.ThrowNet, pos)
                    else
                        safeFire(rem.ThrowNet)
                    end
                    task.wait(0.2)
                    safeFire(rem.ReelIn)
                    safeFire(rem.ResolveCatch, true)
                    safeFire(rem.ResolveCatch)
                elseif Config.AutoReelFull then
                    safeFire(rem.ReelIn)
                    safeFire(rem.ResolveCatch, true)
                end

                -- 2. ยิงบอสอีเวนต์ (Megalodon / Bloop)
                if Config.AutoShootMeg then
                    local megPos = findPosInFolder("MegalodonLocal")
                    if megPos then
                        safeFire(rem.SpearShot, megPos)
                        safeInvoke(rem.SpearAction, "Shoot", megPos)
                    end
                end

                if Config.AutoShootBloop then
                    local bloopPos = findPosInFolder("BloopLocal")
                    if bloopPos then
                        safeFire(rem.SpearShot, bloopPos)
                        safeInvoke(rem.SpearAction, "Shoot", bloopPos)
                    end
                end

                -- 3. เก็บเงินและวาร์ปเหยียบแท่นตามรอบ
                local collectDelay = tonumber(Config.CollectInterval) or 25
                if now - lastCollect >= collectDelay then
                    lastCollect = now
                    if Config.AutoCollectCash then
                        safeFire(rem.CollectPadReq)
                    end
                    if Config.WarpToPad then
                        local padFolder = workspace:FindFirstChild("NetVisual_Base3") or workspace:FindFirstChild("Map")
                        local char = LocalPlayer.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if padFolder and hrp then
                            for _, p in ipairs(padFolder:GetDescendants()) do
                                if p:IsA("BasePart") and string.find(string.lower(p.Name), "pad") then
                                    pcall(function()
                                        hrp.CFrame = p.CFrame + Vector3.new(0, 3.5, 0)
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end

                -- 4. ขายปลาตามรอบ
                local sellDelay = tonumber(Config.SellInterval) or 30
                if Config.AutoSell and (now - lastSell >= sellDelay) then
                    lastSell = now
                    safeFire(rem.SellFish)
                end

                -- 5. งานรอง: กล่องปลา, อัปเกรด, รางวัล, อารีนา, รีเบิร์ธ
                if now - lastUtility >= 3 then
                    lastUtility = now

                    if Config.AutoEquipBest then
                        safeFire(rem.BestSetup)
                        safeFire(rem.PlaceFish)
                    end

                    if Config.AutoFuseAll then
                        safeInvoke(rem.CoolerAction, "FuseAll")
                        safeFire(rem.HotbarAction, "FuseAll")
                    end

                    if Config.AutoBuyPotion then
                        safeInvoke(rem.Potions, "BuyBest")
                        safeFire(rem.BuyItem, "Potion")
                    end

                    if Config.AutoUsePotion then
                        safeInvoke(rem.Potions, "UseBest")
                    end

                    if Config.AutoUpgradeNet then
                        safeInvoke(rem.Gear, "Upgrade")
                    end

                    if Config.AutoUpgradeAllSkills then
                        safeInvoke(rem.SkillTree, "UpgradeAll")
                    end

                    if Config.AutoUpgradeAllFishing then
                        safeInvoke(rem.Gear, "UpgradeStats")
                    end

                    if Config.AutoClaimIndex then
                        safeFire(rem.IndexPage, "ClaimAll")
                    end

                    if Config.AutoSpin then
                        safeInvoke(rem.Rewards, "Spin")
                    end

                    if Config.AutoClaimDaily then
                        safeInvoke(rem.Rewards, "ClaimDaily")
                        safeInvoke(rem.Rewards, "ClaimOnline")
                    end

                    if Config.AutoClaimQuest then
                        safeInvoke(rem.Challenge, "ClaimAll")
                    end

                    if Config.AutoEquipTrait then
                        safeInvoke(rem.Traits, "EquipBest")
                    end

                    if Config.AutoClaimPass then
                        safeInvoke(rem.SeasonPass, "ClaimAll")
                    end

                    if Config.AutoArena then
                        safeInvoke(rem.Arena, "AutoBattle")
                    end

                    if Config.AutoRebirth then
                        safeFire(rem.RebirthRequest)
                    end
                end
            end

            task.wait(0.35)
        end
    end)

    print("[Net a Fish] โหลดโมดูลเรียบร้อย")
end

return GameModule