--!strict
local GameModule = {}

function GameModule.init(Config, Utils)
	print("[Hub] โหลดโมดูลแมพเรียบร้อย")

	-- ลูปหลักของแมพ (ทำงานเฉพาะตอนเปิด Config.AutoFarm)
	task.spawn(function()
		while Config.Enabled do
			if Config.AutoFarm then
				local ok, err = pcall(function()
					local root = Utils.getRootPart()
					if not root then
						return
					end

					-- TODO: ใส่ลอจิกเฉพาะของแมพตรงนี้ (เช่น หาเป้าหมาย / กดใช้งาน / ฟาร์ม)
				end)

				if not ok then
					warn("[GameModule Error]:", err)
				end
			end

			task.wait(Config.LoopDelay)
		end
	end)
end

return GameModule