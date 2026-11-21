--!strict
-- หมายเหตุ: หากตอนอัปโหลดมีโฟลเดอร์ roblox-script-hub ซ้อนอยู่ ให้ใช้ URL แบบมี /roblox-script-hub/ ต่อท้าย main/
local BASE_URL = "https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/roblox-script-hub/"

local SupportedGames: { [number]: string } = {
	-- แทนที่ 0000000000 ด้วย PlaceId จริงของแมพ Net a Fish
	[93898234979111] = "games/net_a_fish.lua",
}

local function fetchRemote(relativePath: string): string?
	local ok, result = pcall(function()
		return game:HttpGet(BASE_URL .. relativePath)
	end)
	if not ok or type(result) ~= "string" then
		warn("[Hub] โหลดไฟล์ไม่สำเร็จ:", relativePath, result)
		return nil
	end
	return result
end

local function bootstrap()
	local placeId = game.PlaceId
	local gameScriptPath = SupportedGames[placeId]

	if not gameScriptPath then
		warn("[Hub] แมพนี้ยังไม่รองรับ (PlaceId: " .. tostring(placeId) .. ")")
		return
	end

	local configSrc = fetchRemote("config.lua")
	local utilsSrc = fetchRemote("core/utils.lua")
	local gameSrc = fetchRemote(gameScriptPath)

	if not (configSrc and utilsSrc and gameSrc) then
		return
	end

	local Config = loadstring(configSrc)()
	local Utils = loadstring(utilsSrc)()
	local GameModule = loadstring(gameSrc)()

	if type(GameModule) == "table" and type(GameModule.init) == "function" then
		GameModule.init(Config, Utils)
	end
end

bootstrap()

local BASE_URL = "https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/"