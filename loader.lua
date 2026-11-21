local BASE_URL = "https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/"

local SupportedGames = {
    [93898234979111] = "games/net_a_fish.lua",
}

local function stripBom(str)
    if type(str) == "string" and string.sub(str, 1, 3) == "\239\187\191" then
        return string.sub(str, 4)
    end
    return str
end

local function fetchRemote(relativePath)
    local ok, result = pcall(function()
        return game:HttpGet(BASE_URL .. relativePath .. "?t=" .. tostring(tick()))
    end)
    if not ok or type(result) ~= "string" then
        warn("[Hub] Failed to fetch:", relativePath, result)
        return nil
    end
    return stripBom(result)
end

local function loadLuaSource(src, label)
    local fn, compileErr = loadstring(stripBom(src))
    if not fn then
        warn("[Hub] Compile Error in " .. label .. ":", compileErr)
        return nil
    end
    local ok, modOrErr = pcall(fn)
    if not ok then
        warn("[Hub] Runtime Error in " .. label .. ":", modOrErr)
        return nil
    end
    return modOrErr
end

local function bootstrap()
    local placeId = game.PlaceId
    local gameScriptPath = SupportedGames[placeId]
    if not gameScriptPath then
        warn("[Hub] Unsupported PlaceId:", placeId)
        return
    end

    local configSrc = fetchRemote("config.lua")
    local uiSrc = fetchRemote("ui.lua")
    local utilsSrc = fetchRemote("core/utils.lua")
    local gameSrc = fetchRemote(gameScriptPath)

    if not (configSrc and uiSrc and utilsSrc and gameSrc) then
        return
    end

    local Config = loadLuaSource(configSrc, "config.lua")
    local UI = loadLuaSource(uiSrc, "ui.lua")
    local Utils = loadLuaSource(utilsSrc, "core/utils.lua")
    local GameModule = loadLuaSource(gameSrc, gameScriptPath)

    if not (Config and UI and Utils and GameModule) then
        return
    end

    if type(UI) == "table" and type(UI.init) == "function" then
        UI.init(Config, "TER HUB")
    end

    if type(GameModule) == "table" and type(GameModule.init) == "function" then
        GameModule.init(Config, Utils)
    end
end

bootstrap()