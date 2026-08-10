local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/PNC/WorldDiscovery/"

isClient = function() return true end
isServer = function() return false end
PNC = nil
PsychopatzCore = nil

local files = {
    "PNC_WorldDiscovery.lua",
    "PNC_WorldDiscovery_Actions.lua",
    "PNC_WorldDiscovery_Entities.lua",
    "PNC_WorldDiscovery_Proximity.lua",
    "PNC_WorldDiscovery_Storage.lua",
    "WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts.lua",
    "WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_Api.lua",
    "WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_Context.lua",
    "WorldDiscoveryRadioBroadcasts/PNC_WorldDiscoveryRadioBroadcasts_MessagePacks.lua",
}

for index = 1, #files do
    local ok, reason = pcall(dofile, ROOT .. files[index])
    if not ok then
        error("pure multiplayer client loaded " .. files[index] .. ": " .. tostring(reason))
    end
end

if PNC ~= nil then
    error("server-only discovery files mutated client PNC state")
end

print("pnc world discovery multiplayer client guards: ok")
