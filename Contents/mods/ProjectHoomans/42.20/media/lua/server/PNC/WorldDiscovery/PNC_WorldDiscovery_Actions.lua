-- Radio, debug, and conversation discovery sources.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes

local function compactRadioBroadcast(message, context)
    if type(message) ~= "table" or type(message.lines) ~= "table" then
        return nil
    end
    local output = {
        packID = tostring(message.packID or ""),
        speakerNPCID = context and context.identityIntroduced == true
            and context.speakerNPCID or nil,
        speech = {
            effect_profile = "radio",
            environment = "normal",
            intensity = 0.85,
        },
        lines = {},
    }
    for _, line in ipairs(message.lines) do
        local value = type(line) == "table" and line.text or line
        value = tostring(value or "")
        value = string.gsub(value, "<[^>]+>", "")
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")
        if value ~= "" then
            output.lines[#output.lines + 1] = string.sub(value, 1, 600)
        end
    end
    return #output.lines > 0 and output or nil
end

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
    local aired, broadcastMessage, broadcastContext =
        Discovery.BroadcastRadioDiscovery(player, best, nextPhase)
    local result = {
        ok = true,
        reason = nextPhase == Types.PHASE_RUMORED
            and "signal_detected" or "signal_located",
        entityID = best.entityID,
        kind = best.kind,
        phase = nextPhase,
        groupType = best.groupType,
        identityRevealed = broadcastContext
            and broadcastContext.identityIntroduced == true or false,
        notificationID = tostring(best.entityID) .. ":"
            .. tostring(nextPhase) .. ":"
            .. tostring(record.revision or 0),
        channelID = scanChannel.ID,
    }
    if aired then
        result.radioBroadcast = compactRadioBroadcast(
            broadcastMessage, broadcastContext
        )
    end
    return Discovery.BuildSnapshot(player, result)
end

function Discovery.CanUseDebug(player)
    local coreDebug = PsychopatzCore and PsychopatzCore.Debug
    if not coreDebug or type(coreDebug.CanUse) ~= "function" then
        local ok, loaded = pcall(require, "PsychopatzCore/Debug/PsychopatzDebug")
        if ok then coreDebug = loaded end
    end
    return coreDebug and coreDebug.CanUse
        and coreDebug.CanUse(player) == true or false
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
    if action == "debug_reset" then
        if not Discovery.CanUseDebug(player) then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = "not_authorized",
            })
        end
        local ok, reason = Discovery.ResetPlayer(player)
        return Discovery.BuildSnapshot(player, {
            ok = ok == true,
            reason = ok and "debug_reset" or reason,
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
