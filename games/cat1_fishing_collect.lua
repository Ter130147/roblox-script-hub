-- ไฟล์แยกเฉพาะหมวดที่ 1: ตกปลาและเก็บผลผลิต (ไม่แตะร้านค้าหรือปุ่ม Robux)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cat1Module = {}
local lastFishCycleTime = 0
local netThrown = false

function Cat1Module.reset()
    netThrown = false
end

function Cat1Module.step(Config)
    local r = ReplicatedStorage:FindFirstChild("Remotes")
    if not r then
        return
    end

    local spd = tonumber(Config and Config.MiniGameSpeed) or 0.15
    local cycleDelay = math.clamp(spd * 4, 0.65, 2.50)
    if tick() - lastFishCycleTime < cycleDelay then
        return
    end
    lastFishCycleTime = tick()

    local throwNet = r:FindFirstChild("ThrowNet")
    local reelIn = r:FindFirstChild("ReelIn")
    local collectPadReq = r:FindFirstChild("CollectPadReq")

    pcall(function()
        if not netThrown and throwNet and throwNet:IsA("RemoteEvent") then
            throwNet:FireServer()
            netThrown = true
        elseif reelIn and reelIn:IsA("RemoteEvent") then
            reelIn:FireServer()
            netThrown = false
        end
    end)

    pcall(function()
        if collectPadReq and collectPadReq:IsA("RemoteEvent") then
            collectPadReq:FireServer()
        end
    end)
end

return Cat1Module