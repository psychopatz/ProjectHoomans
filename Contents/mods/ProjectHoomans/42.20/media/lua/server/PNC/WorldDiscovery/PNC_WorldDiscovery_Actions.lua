-- Radio, debug, and conversation discovery sources.

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

function Discovery.RadioScan(player, channelID, frequency)
    local record, reason = Internal.PlayerRecord(player, true)
    if not record then return Discovery.BuildSnapshot(player, {
        ok = false, reason = reason,
    }) end
    local scanChannel = PNC.RadioDiscoveryChannel
    if tostring(channelID or "") ~= scanChannel.ID
        or math.floor(tonumber(frequency) or 0) ~= scanChannel.FREQUENCY
    then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "invalid_channel",
        })
    end
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
            channelID = scanChannel.ID,
        })
    end
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
            channelID = scanChannel.ID,
        })
    end
    record.lastRadioScanAt = at
    Discovery.Dirty = true
    local existing = record.entities[best.kind][best.entityID]
    local nextPhase = existing and Types.PHASE_LOCATED
        or Types.PHASE_RUMORED
    Discovery.SetPhase(player, best.kind, best.entityID,
        nextPhase, "radio")
    local _, _, broadcast = Discovery.BroadcastRadioDiscovery(
        player, best, nextPhase
    )
    return Discovery.BuildSnapshot(player, {
        ok = true,
        reason = nextPhase == Types.PHASE_RUMORED
            and "signal_detected" or "signal_located",
        entityID = best.entityID,
        kind = best.kind,
        phase = nextPhase,
        groupType = best.groupType,
        identityRevealed = broadcast
            and broadcast.identityIntroduced == true or false,
        notificationID = tostring(best.entityID) .. ":"
            .. tostring(nextPhase) .. ":"
            .. tostring(record.revision or 0),
        channelID = scanChannel.ID,
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
    if action == "radio_scan" then
        return Discovery.RadioScan(player, args.channelID, args.frequency)
    end
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
    if action == "debug_discover_all" then
        if not Discovery.CanUseDebug(player) then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "not_authorized",
            })
        end
        local scope = tostring(args.scope or "all")
        local requestedKind = scope == "settlements"
            and Types.KIND_SETTLEMENT
            or scope == "mobile_groups"
                and Types.KIND_MOBILE_GROUP or nil
        if scope ~= "all" and not requestedKind then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "invalid_scope",
            })
        end
        local advanced = 0
        for _, entity in ipairs(Discovery.ListWorldEntities()) do
            if not requestedKind or entity.kind == requestedKind then
                local _, reason = Discovery.SetPhase(
                    player, entity.kind, entity.entityID,
                    Types.PHASE_LOCATED, "debug_map_all", true
                )
                if reason == "advanced" then advanced = advanced + 1 end
            end
        end
        Discovery.Save()
        return Discovery.BuildSnapshot(player, {
            ok = true,
            reason = "debug_discovered_all",
            scope = scope,
            count = advanced,
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
