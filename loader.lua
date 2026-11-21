local function loadLuaSource(src: string, label: string): any
	local chunk, compileErr = loadstring(src)
	if not chunk then
		warn("[Hub] Compile Error ใน " .. label .. ":", compileErr)
		return nil
	end

	local ok, modOrErr = pcall(chunk)
	if not ok then
		warn("[Hub] Runtime Error ตอนรัน " .. label .. ":", modOrErr)
		return nil
	end

	return modOrErr
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

	local Config = loadLuaSource(configSrc, "config.lua")
	local Utils = loadLuaSource(utilsSrc, "core/utils.lua")
	local GameModule = loadLuaSource(gameSrc, gameScriptPath)

	if not (Config and Utils and GameModule) then
		return
	end

	if type(GameModule) == "table" and type(GameModule.init) == "function" then
		GameModule.init(Config, Utils)
	else
		warn("[Hub] โมดูลแมพไม่มีฟังก์ชัน init:", gameScriptPath)
	end
end