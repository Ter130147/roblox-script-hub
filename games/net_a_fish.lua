local src = game:HttpGet("https://raw.githubusercontent.com/Ter130147/roblox-script-hub/main/games/net_a_fish/init.lua?cb=" .. tostring(os.clock()) .. "_" .. tostring(math.random(10000,99999)), true)
local fn = loadstring(src)
return fn and fn() or {}