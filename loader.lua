local BASE_URL = "https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/"

local SupportedGames = {
    [93898234979111] = "games/net_a_fish.lua",
}

local function stripBom(str)
    if type(str) ~= "string" then
        return str
    end
    if string.sub(str, 1, 3) == "\239\187\191" then
        return string.sub(str, 4)
    end
    return str
end

local function fetchRemote(relativePath)
    local ok, result = pcall(function()
        return game:HttpGet(BASE_URL .. relativePath)
    end)
    if not ok or type(result) ~= "string" then
        warn("[Hub] โหลดไฟล์ไม่สำเร็จ:", relativePath, result)
        return nil
    end
    return stripBom(result)
end

local function loadLuaSource(src, label)
    local cleanSrc = stripBom(src)
    local fn, compileErr = loadstring(cleanSrc)
    if not fn then
        warn("[Hub] Compile Error ใน " .. label .. ":", compileErr)
        return nil
    end

    local ok, modOrErr = pcall(fn)
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
    local uiSrc = fetchRemote("ui.lua")

    if not (configSrc and utilsSrc and gameSrc) then
        return
    end

    local Config = loadLuaSource(configSrc, "config.lua")
    local Utils = loadLuaSource(utilsSrc, "core/utils.lua")
    local GameModule = loadLuaSource(gameSrc, gameScriptPath)

    if not (Config and Utils and GameModule) then
        return
    end

    if uiSrc then
        local UI = loadLuaSource(uiSrc, "ui.lua")
        if type(UI) == "table" and type(UI.init) == "function" then
            UI.init(Config, "TER HUB")
        end
    end

    if type(GameModule) == "table" and type(GameModule.init) == "function" then
        GameModule.init(Config, Utils)
    else
        warn("[Hub] โมดูลแมพไม่มีฟังก์ชัน init:", gameScriptPath)
    end
end

bootstrap()