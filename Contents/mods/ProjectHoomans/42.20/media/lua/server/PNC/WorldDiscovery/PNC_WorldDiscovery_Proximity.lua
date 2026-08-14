-- Low-frequency physical traversal discovery.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes
local Core = PNC.Core

Discovery.ProximityStateByPlayer =
    Discovery.ProximityStateByPlayer or {}

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
        local state = Discovery.ProximityStateByPlayer[uuid]
        if not state then
            state = { cursor = 1, nextAt = 0 }
            Discovery.ProximityStateByPlayer[uuid] = state
        end
        if now >= (tonumber(state.nextAt) or 0) then
            local entities = Discovery.GetCachedWorldEntities(now)
            if state.entities ~= entities then
                state.entities = entities
                state.cursor = 1
            end
            local changed = false
            local processed = 0
            local budget = math.max(1,
                tonumber(Discovery.PROXIMITY_SCAN_BUDGET) or 24)
            while state.cursor <= #entities and processed < budget do
                local entity = entities[state.cursor]
                state.cursor = state.cursor + 1
                processed = processed + 1
                local range = entity.kind == Types.KIND_SETTLEMENT
                    and Discovery.SETTLEMENT_DISCOVERY_RANGE
                    or Discovery.MOBILE_GROUP_DISCOVERY_RANGE
                if Internal.DistanceSquared(player, entity) <= range * range then
                    local _, reason = Discovery.SetResolvedPhase(player,
                        entity,
                        Types.PHASE_LOCATED, "traversal")
                    changed = changed or reason == "advanced"
                end
            end
            if state.cursor > #entities then
                state.cursor = 1
                state.nextAt = now + Discovery.PROXIMITY_SCAN_MS
                Discovery.LastProximityScanAt[uuid] = now
            else
                state.nextAt = now + Discovery.PROXIMITY_SLICE_MS
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
