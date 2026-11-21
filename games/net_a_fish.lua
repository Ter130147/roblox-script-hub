local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local GameModule = {}
local running = false

local function getRemotes()
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        return nil
    end
    return {
        ThrowNet = remotesFolder:FindFirstChild("ThrowNet"),
        ReelIn = remotesFolder:FindFirstChild("ReelIn"),
        ResolveCatch = remotesFolder:FindFirstChild("ResolveCatch"),
        SpearShot = remotesFolder:FindFirstChild("SpearShot"),
        SpearAction = remotesFolder:FindFirstChild("SpearAction"),
        CollectPadReq = remotesFolder:FindFirstChild("CollectPadReq"),
        SellFish = remotesFolder:FindFirstChild("SellFish"),
    }
end

local function findTargetPos()
    local pools = {
        workspace:FindFirstChild("ClientFish"),
        workspace:FindFirstChild("PoolFishLocal"),
        workspace:FindFirstChild("RiverLife"),
    }
    for _, folder in ipairs(pools) do
        if folder then
            for _, item in ipairs(folder:GetDescendants()) do
                if item:IsA("BasePart") then
                    return item.Position
                elseif item:IsA("Model") and item.PrimaryPart then
                    return item.PrimaryPart.Position
                end
            end
        end
    end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        return root.Position + (root.CFrame.LookVector * 12)
    end
    return nil
end

local function farmStep(remotes)
    local targetPos = findTargetPos()

    if remotes.ThrowNet and remotes.ThrowNet:IsA("RemoteEvent") then
        if targetPos then
            pcall(function() remotes.ThrowNet:FireServer(targetPos) end)
        end
        pcall(function() remotes.ThrowNet:FireServer() end)
    end

    if remotes.SpearShot and remotes.SpearShot:IsA("RemoteEvent") and targetPos then
        pcall(function() remotes.SpearShot:FireServer(targetPos) end)
    end

    task.wait(0.25)

    if remotes.ReelIn and remotes.ReelIn:IsA("RemoteEvent") then
        pcall(function() remotes.ReelIn:FireServer() end)
    end

    if remotes.ResolveCatch and remotes.ResolveCatch:IsA("RemoteEvent") then
        pcall(function() remotes.ResolveCatch:FireServer(true) end)
        pcall(function() remotes.ResolveCatch:FireServer() end)
    end

    if remotes.CollectPadReq and remotes.CollectPadReq:IsA("RemoteEvent") then
        pcall(function() remotes.CollectPadReq:FireServer() end)
    end
end

function GameModule.init(Config, Utils)
    if running then
        return
    end
    running = true

    task.spawn(function()
        while running do
            local delayTime = (Config and tonumber(Config.LoopDelay)) or 0.5
            if delayTime < 0.1 then
                delayTime = 0.1
            end

            if Config and Config.AutoFarm then
                local remotes = getRemotes()
                if remotes then
                    farmStep(remotes)
                end
            end

            task.wait(delayTime)
        end
    end)

    print("[Net a Fish] ??????????????????")
end

return GameModule