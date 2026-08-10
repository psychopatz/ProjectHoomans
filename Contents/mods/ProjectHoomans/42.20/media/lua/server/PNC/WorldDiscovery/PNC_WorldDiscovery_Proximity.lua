-- Low-frequency physical traversal discovery.

if isClient and isClient() and (not isServer or not isServer()) then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes
local Core = PNC.Core

local function onlinePlayers()
    local output = {}
    if isServer and isServer() and getOnlinePlayers then
        local players = getOnlinePlayers()
        for index = 0, players:size() - 1 do
            output[#output + 1] = players:get(index)
        end
    else
        local player = getSpecificPlayer and getSpecificPlayer(0) or nil
        if player then output[1] = player end
    end
    return output
end

function Discovery.UpdateProximity()
    local now = Core.Now()
    for _, player in ipairs(onlinePlayers()) do
        local uuid = Internal.CharacterUUID(player) or tostring(player)
        if now - (tonumber(Discovery.LastProximityScanAt[uuid]) or 0)
            >= Discovery.PROXIMITY_SCAN_MS
        then
            Discovery.LastProximityScanAt[uuid] = now
            local changed = false
            for _, entity in ipairs(Discovery.ListWorldEntities()) do
                local range = entity.kind == Types.KIND_SETTLEMENT
                    and Discovery.SETTLEMENT_DISCOVERY_RANGE
                    or Discovery.MOBILE_GROUP_DISCOVERY_RANGE
                if Internal.DistanceSquared(player, entity) <= range * range then
                    local _, reason = Discovery.SetPhase(player,
                        entity.kind, entity.entityID,
                        Types.PHASE_LOCATED, "traversal")
                    changed = changed or reason == "advanced"
                end
            end
            if changed and PNC.Network
                and PNC.Network.SendWorldDiscovery
            then
                PNC.Network.SendWorldDiscovery(player,
                    Discovery.BuildSnapshot(player, {
                        ok = true, reason = "proximity_discovery",
                    }))
            end
        end
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(Discovery.UpdateProximity)
end

return Discovery
