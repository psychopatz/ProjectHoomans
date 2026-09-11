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

local function isLiveRecord(record)
    if not record or record.alive == false then return false end
    if PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id)
    then
        return true
    end
    return PNC.Const
        and record.presenceState == PNC.Const.PRESENCE_LIVE
        or false
end

local function nearestFor(player, record)
    local distance = 0
    if record then
        local dx = (tonumber(record.x) or 0) - (tonumber(player:getX()) or 0)
        local dy = (tonumber(record.y) or 0) - (tonumber(player:getY()) or 0)
        distance = dx * dx + dy * dy
    end
    return { player = player, distSq = distance }
end

function Discovery.ResolvePhysicalPresence(player, entity)
    if not entity or entity.kind ~= Types.KIND_MOBILE_GROUP then
        return Types.PRESENCE_UNKNOWN
    end
    local group = PNC.AbstractGroups and PNC.AbstractGroups.Get
        and PNC.AbstractGroups.Get(entity.entityID) or nil
    if not group or type(group.memberIds) ~= "table" then
        return Types.PRESENCE_ABSENT
    end
    local liveCount = 0
    for _, npcID in ipairs(group.memberIds) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if isLiveRecord(record) then liveCount = liveCount + 1 end
    end
    if liveCount > 0 then return Types.PRESENCE_PRESENT end

    -- Abstract members can have stale positions after a strategic relocation.
    -- Put them at the authoritative group site before asking the normal,
    -- budgeted presence system to materialize them.
    if PNC.AbstractGroups.SynchronizeMembersAtLocation then
        PNC.AbstractGroups.SynchronizeMembersAtLocation(group)
    end
    local attempted = 0
    local limit = math.max(1, math.floor(
        tonumber(Discovery.ARRIVAL_MATERIALIZE_LIMIT) or 8
    ))
    for _, npcID in ipairs(group.memberIds) do
        if attempted >= limit then break end
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        local forceAbstract = record and record.runtime
            and record.runtime.forceAbstract == true
        if record and record.alive ~= false
            and not forceAbstract
            and PNC.Const
            and record.presenceState ~= PNC.Const.PRESENCE_LIVE
            and PNC.Presence and PNC.Presence.Materialize
        then
            attempted = attempted + 1
            local ok, body = pcall(
                PNC.Presence.Materialize,
                record,
                "range_enter",
                nearestFor(player, record)
            )
            if not ok and Core and Core.LogWarn then
                Core.LogWarn("WorldDiscovery arrival materialization failed npc="
                    .. tostring(record.id) .. " error=" .. tostring(body))
            end
        end
    end
    for _, npcID in ipairs(group.memberIds) do
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(npcID) or nil
        if isLiveRecord(record) then liveCount = liveCount + 1 end
    end
    return liveCount > 0
        and Types.PRESENCE_PRESENT or Types.PRESENCE_ABSENT
end

function Discovery.UpdateProximity()
    local now = Core.Now()
    for _, player in ipairs(onlinePlayers()) do
        local uuid = Internal.CharacterUUID(player) or tostring(player)
        local playerRecord = Internal.PlayerRecord(player, true)
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
            local dirty = false
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
                    local entry = playerRecord
                        and playerRecord.entities[entity.kind]
                        and playerRecord.entities[entity.kind][entity.entityID]
                    local _, reason = Discovery.SetResolvedPhase(
                        player,
                        entity,
                        Types.PHASE_LOCATED,
                        "traversal",
                        true
                    )
                    changed = changed or reason == "advanced"
                    dirty = dirty or reason == "advanced"
                    if not entry
                        or Types.ArrivalState(entry.arrivalState)
                            == Types.ARRIVAL_UNCHECKED
                    then
                        local presence = Discovery.ResolvePhysicalPresence(
                            player, entity)
                        local _, arrivalReason = Discovery.MarkArrived(
                            player,
                            entity,
                            presence,
                            "traversal",
                            true
                        )
                        changed = changed or arrivalReason == "advanced"
                        dirty = dirty or arrivalReason == "advanced"
                        if Core and Core.LogInfo then
                            Core.LogInfo("WorldDiscovery arrival entity="
                                .. tostring(entity.entityID)
                                .. " kind=" .. tostring(entity.kind)
                                .. " presence=" .. tostring(presence))
                        end
                    end
                end
            end
            if state.cursor > #entities then
                state.cursor = 1
                state.nextAt = now + Discovery.PROXIMITY_SCAN_MS
                Discovery.LastProximityScanAt[uuid] = now
            else
                state.nextAt = now + Discovery.PROXIMITY_SLICE_MS
            end
            if dirty then Discovery.Save() end
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
