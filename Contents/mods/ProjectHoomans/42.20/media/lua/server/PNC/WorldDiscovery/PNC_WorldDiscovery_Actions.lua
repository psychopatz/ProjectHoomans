-- Radio, debug, and conversation discovery sources.

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

function Discovery.RadioScan(player)
    local record, reason = Internal.PlayerRecord(player, true)
    if not record then return Discovery.BuildSnapshot(player, {
        ok = false, reason = reason,
    }) end
    local at = Internal.WorldHour()
    local remaining = Discovery.RADIO_COOLDOWN_HOURS
        - (at - (tonumber(record.lastRadioScanAt) or 0))
    if record.lastRadioScanAt and record.lastRadioScanAt > 0
        and remaining > 0
    then
        return Discovery.BuildSnapshot(player, {
            ok = false,
            reason = "radio_cooldown",
            cooldownSeconds = math.ceil(remaining * 3600),
        })
    end
    record.lastRadioScanAt = at
    Discovery.Dirty = true
    local best
    local bestDistance
    for _, entity in ipairs(Discovery.ListWorldEntities()) do
        local entry = record.entities[entity.kind][entity.entityID]
        local phase = Types.ClampPhase(entry and entry.phase)
        local distance = Internal.DistanceSquared(player, entity)
        if phase < Types.PHASE_LOCATED
            and distance <= Discovery.RADIO_RANGE * Discovery.RADIO_RANGE
            and (not bestDistance or distance < bestDistance)
        then
            best, bestDistance = entity, distance
        end
    end
    if not best then
        Discovery.Save()
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "no_signal",
        })
    end
    local existing = record.entities[best.kind][best.entityID]
    local nextPhase = existing and Types.PHASE_LOCATED
        or Types.PHASE_RUMORED
    Discovery.SetPhase(player, best.kind, best.entityID,
        nextPhase, "radio")
    return Discovery.BuildSnapshot(player, {
        ok = true,
        reason = nextPhase == Types.PHASE_RUMORED
            and "signal_detected" or "signal_located",
        entityID = best.entityID,
        kind = best.kind,
        phase = nextPhase,
    })
end

function Discovery.CanUseDebug(player)
    if not isServer or not isServer() then
        return isDebugEnabled and isDebugEnabled() == true
            or getCore and getCore() and getCore():getDebug() == true
    end
    local access = player and player.getAccessLevel
        and tostring(player:getAccessLevel() or "") or ""
    return string.lower(access) == "admin"
end

function Discovery.HandleAction(player, args)
    args = type(args) == "table" and args or {}
    local action = tostring(args.action or "snapshot")
    if action == "radio_scan" then return Discovery.RadioScan(player) end
    if action == "debug_discover" then
        if not Discovery.CanUseDebug(player) then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "not_authorized",
            })
        end
        local entry, reason = Discovery.SetPhase(
            player, tostring(args.kind or ""),
            tostring(args.entityID or ""),
            Types.PHASE_LOCATED, "debug_map"
        )
        return Discovery.BuildSnapshot(player, {
            ok = entry ~= nil,
            reason = reason,
            entityID = args.entityID,
            kind = args.kind,
            phase = entry and entry.phase,
        })
    end
    return Discovery.BuildSnapshot(player)
end

function Discovery.DiscoverNPCContext(player, npcID)
    local npc = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    local affiliation = npc and npc.affiliation or {}
    local changed = false
    if affiliation.communityID then
        local _, reason = Discovery.SetPhase(player,
            Types.KIND_SETTLEMENT, affiliation.communityID,
            Types.PHASE_CONTACTED, "conversation")
        changed = changed or reason == "advanced"
    end
    if affiliation.factionID and PNC.AbstractGroups
        and PNC.AbstractGroups.FindByFactionID
    then
        local group = PNC.AbstractGroups.FindByFactionID(
            affiliation.factionID)
        if group then
            local _, reason = Discovery.SetPhase(player,
                Types.KIND_MOBILE_GROUP, group.id,
                Types.PHASE_CONTACTED, "conversation")
            changed = changed or reason == "advanced"
        end
    end
    if changed and PNC.Network and PNC.Network.SendWorldDiscovery then
        PNC.Network.SendWorldDiscovery(player,
            Discovery.BuildSnapshot(player, {
                ok = true, reason = "contacted",
            }))
    end
    return changed
end

return Discovery
