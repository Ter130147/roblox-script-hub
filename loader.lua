_G.TerNetAFishLoaded = nil

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
if pg and pg:FindFirstChild("TerHubProUI") then
    pg.TerHubProUI:Destroy()
end

local BASE = "https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/"

local function fetchModule(relPath)
    local sep = string.find(relPath, "?", 1, true) and "&" or "?"
    local url = BASE .. relPath .. sep .. "cb=" .. tostring(os.clock()) .. "_" .. tostring(math.random(10000, 99999))
    local ok, src = pcall(function()
        return game:HttpGet(url, true)
    end)
    if not ok or type(src) ~= "string" then
        warn("[Loader] โหลดไม่สำเร็จ:", relPath)
        return nil
    end
    local fn, err = loadstring(src)
    if not fn then
        warn("[Loader] Syntax error ใน " .. relPath .. ":", err)
        return nil
    end
    return fn()
end

local Config = fetchModule("config.lua") or {
    AutoMiniGame = true,
    MiniGameSpeed = 0.15,
    ScanNow = false,
}

local Utils = fetchModule("core/utils.lua") or {}
local UI = fetchModule("ui.lua")

if UI and type(UI.init) == "function" then
    UI.init(Config, "TER HUB")
end

local gameScript = "games/template_game.lua"
if game.PlaceId == 93898234979111 then
    gameScript = "games/net_a_fish/init.lua"
end

local GameModule = fetchModule(gameScript)
if GameModule and type(GameModule.init) == "function" then
    GameModule.init(Config, Utils)
end