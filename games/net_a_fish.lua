--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local NetAFish = {}

-- ปรับรายชื่อ Remote หรือโฟลเดอร์ให้ตรงกับโครงสร้างจริงของแมพ Net a Fish
local function findNetRemote(): RemoteEvent?
	-- ตัวอย่างการค้นหา RemoteEvent แบบปลอดภัย ไม่ให้ error หากชื่อเปลี่ยน
	for _, descendant in ipairs(ReplicatedStorage:GetDescendants()) do
		if descendant:IsA("RemoteEvent") then
			local lowerName = string.lower(descendant.Name)
			if string.find(lowerName, "net", 1, true) or string.find(lowerName, "catch", 1, true) or string.find(lowerName, "fish", 1, true) then
				return descendant
			end
		end
	end
	return nil
end

local function equipNetIfNeeded()
	local character = LocalPlayer.Character
	local backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
	if not character or not backpack then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	-- ถ้ายังไม่ได้ถือเครื่องมือ ให้หา Tool ที่เกี่ยวข้องกับแห/จับปลาใน Backpack
	local hasEquippedTool = character:FindFirstChildOfClass("Tool") ~= nil
	if hasEquippedTool then
		return
	end

	for _, item in ipairs(backpack:GetChildren()) do
		if item:IsA("Tool") then
			local lowerName = string.lower(item.Name)
			if string.find(lowerName, "net", 1, true) or string.find(lowerName, "rod", 1, true) then
				humanoid:EquipTool(item)
				break
			end
		end
	end
end

function NetAFish.init(Config, Utils)
	print("[Net a Fish] โหลดโมดูลเรียบร้อย")
	local netRemote = findNetRemote()

	task.spawn(function()
		while Config.Enabled do
			if Config.AutoFarm then
				local ok, err = pcall(function()
					local root = Utils.getRootPart()
					if not root then
						return
					end

					equipNetIfNeeded()

					-- TODO: ปรับให้ตรงกับระบบจับปลาของแมพ Net a Fish
					-- ตัวอย่างเช่น:
					-- 1. วาร์ปไปยังจุดน้ำ/จุดปลาที่ต้องการด้วย Utils.safeTeleport(targetCFrame)
					-- 2. ถ้าแมพใช้ RemoteEvent ให้เรียก netRemote:FireServer(...) พร้อมเช็ก nil ก่อนเสมอ
					if netRemote then
						-- netRemote:FireServer()
					end
				end)

				if not ok then
					warn("[Net a Fish Error]:", err)
				end
			end

			task.wait(Config.LoopDelay)
		end
	end)
end

return NetAFish