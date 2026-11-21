--!strict
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Utils = {}

function Utils.getRootPart(): BasePart?
	local character = LocalPlayer.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function Utils.safeTeleport(targetCFrame: CFrame): boolean
	local root = Utils.getRootPart()
	if not root then
		return false
	end

	local ok = pcall(function()
		root.CFrame = targetCFrame
	end)
	return ok
end

return Utils