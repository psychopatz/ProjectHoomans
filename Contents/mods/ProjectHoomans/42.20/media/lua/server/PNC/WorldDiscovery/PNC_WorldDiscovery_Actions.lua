-- Radio, debug, and conversation discovery sources.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes
local Core = PNC.Core

local function lineSpeaker(context, line)
    local role = type(line) == "table" and line.speakerRole or nil
    role = tostring(role or "primary")
    if role == "secondary" then
        return role, context and context.secondarySpeakerNPCID or nil
    end
    return "primary", context and context.speakerNPCID or nil
end

local function chancePasses(chance, hookName)
    if chance <= 0 then return false end
    if chance >= 100 then return true end
    local roll
    local hook = Discovery[hookName]
    if type(hook) == "function" then
        roll = hook()
    elseif ZombRand then
        roll = ZombRand(100)
    else
        roll = math.random(0, 99)
    end
    return (tonumber(roll) or 99) < chance
end

local function signalRollPasses()
    return chancePasses(Discovery.RadioSignalChance(), "RadioSignalRoll")
end

local function markRadioAttempt(record, at)
    record.lastRadioScanAt = at
    record.radioScanCount = (tonumber(record.radioScanCount) or 0) + 1
    Discovery.Dirty = true
end

local function compactRadioBroadcast(message, context)
    if type(message) ~= "table" or type(message.lines) ~= "table" then
        return nil
    end
    local output = {
        packID = tostring(message.packID or ""),
        eventType = context and context.eventType or "discovery",
        -- This is an internal voice-continuity identity, not a player-facing
        -- disclosure. IdentityIntroduced remains the only name-reveal gate.
        speakerNPCID = context and context.speakerNPCID or nil,
        secondarySpeakerNPCID = context and context.secondarySpeakerNPCID or nil,
        speech = {
            effect_profile = "radio",
            environment = "normal",
            intensity = 0.85,
        },
        lines = {},
    }
    for _, line in ipairs(message.lines) do
        local value = type(line) == "table" and line.text or line
        local speakerRole, speakerID = lineSpeaker(context, line)
        value = tostring(value or "")
        value = string.gsub(value, "<[^>]+>", "")
        value = string.gsub(value, "^%s+", "")
        value = string.gsub(value, "%s+$", "")
        if value ~= "" then
            output.lines[#output.lines + 1] = {
                text = string.sub(value, 1, 600),
                speakerRole = speakerRole,
                speakerNPCID = speakerID,
            }
        end
    end
    return #output.lines > 0 and output or nil
end

function Discovery.RadioAmbient(player, channelID, frequency)
    local record, reason = Internal.PlayerRecord(player, true)
    if not record then return Discovery.BuildSnapshot(player, {
        ok = false, eventType = "ambient", reason = reason,
    }) end
    if not Discovery.RadioDiscoveryEnabled()
        or not Discovery.RadioAmbientEnabled()
    then
        return Discovery.BuildSnapshot(player, {
            ok = false, eventType = "ambient",
            reason = "radio_ambient_disabled",
        })
    end
    local scanChannel = PNC.RadioDiscoveryChannel
    if tostring(channelID or "") ~= scanChannel.ID
        or math.floor(tonumber(frequency) or 0) ~= scanChannel.FREQUENCY
    then
        return Discovery.BuildSnapshot(player, {
            ok = false, eventType = "ambient", reason = "invalid_channel",
        })
    end
    local state = Discovery.RadioAmbientState
        or { lastAiredAt = nil, hasAired = false,
            lastVariant = nil, sequence = 0 }
    state.lastRequestAtByPlayer = state.lastRequestAtByPlayer or {}
    Discovery.RadioAmbientState = state
    local now = Core and Core.Now and Core.Now() or 0
    local key = Internal.CharacterUUID(player) or tostring(player)
    local interval = Discovery.RadioAmbientIntervalMs()
    local previousRequest = tonumber(state.lastRequestAtByPlayer[key]) or 0
    if state.lastRequestAtByPlayer[key] ~= nil
        and now - previousRequest < interval
    then
        return Discovery.BuildSnapshot(player, {
            ok = false, eventType = "ambient",
            reason = "ambient_request_cooldown",
        })
    end
    state.lastRequestAtByPlayer[key] = now
    local globalGap = math.max(1000,
        tonumber(Discovery.RADIO_AMBIENT_GLOBAL_GAP_MS) or 60000)
    if state.hasAired == true
        and now - (tonumber(state.lastAiredAt) or 0) < globalGap
    then
        return Discovery.BuildSnapshot(player, {
            ok = false, eventType = "ambient",
            reason = "ambient_channel_cooldown",
        })
    end
    if not chancePasses(Discovery.RadioAmbientChance(),
        "RadioAmbientRoll")
    then
        return Discovery.BuildSnapshot(player, {
            ok = false, eventType = "ambient", reason = "ambient_missed",
        })
    end
    local aired, broadcastMessage, broadcastContext =
        Discovery.BroadcastRadioAmbient(player)
    if not aired then
        return Discovery.BuildSnapshot(player, {
            ok = false, eventType = "ambient", reason = broadcastMessage,
        })
    end
    state.lastAiredAt = now
    state.hasAired = true
    local sequence = broadcastContext and broadcastContext.ambientSequence
        or state.sequence
    local result = {
        ok = true,
        eventType = "ambient",
        reason = "ambient_broadcast",
        notificationID = "ambient:" .. tostring(sequence) .. ":"
            .. tostring(math.floor(now / 1000)),
        channelID = scanChannel.ID,
    }
    result.radioBroadcast = compactRadioBroadcast(
        broadcastMessage, broadcastContext)
    return Discovery.BuildSnapshot(player, result)
end

function Discovery.RadioScan(player, channelID, frequency)
    local record, reason = Internal.PlayerRecord(player, true)
    if not record then return Discovery.BuildSnapshot(player, {
        ok = false, reason = reason,
    }) end
    if not Discovery.RadioDiscoveryEnabled() then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "radio_discovery_disabled",
        })
    end
    local scanChannel = PNC.RadioDiscoveryChannel
    if tostring(channelID or "") ~= scanChannel.ID
        or math.floor(tonumber(frequency) or 0) ~= scanChannel.FREQUENCY
    then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "invalid_channel",
        })
    end
    local at = Internal.WorldHour()
    local cooldownHours = Discovery.RadioCooldownHours()
    local lastScanAt = tonumber(record.lastRadioScanAt)
    local hasPreviousScan = (tonumber(record.radioScanCount) or 0) > 0
        or lastScanAt ~= nil and lastScanAt > 0
    local remaining = cooldownHours
        - (at - (lastScanAt or 0))
    if hasPreviousScan and remaining > 0 then
        return Discovery.BuildSnapshot(player, {
            ok = false,
            reason = "radio_cooldown",
            cooldownSeconds = math.ceil(remaining * 3600),
            channelID = scanChannel.ID,
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
        markRadioAttempt(record, at)
        Discovery.Save()
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "no_signal",
            channelID = scanChannel.ID,
        })
    end
    if not signalRollPasses() then
        markRadioAttempt(record, at)
        Discovery.Save()
        return Discovery.BuildSnapshot(player, {
            ok = false,
            reason = "no_signal",
            channelID = scanChannel.ID,
        })
    end
    markRadioAttempt(record, at)
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

function Discovery.CallContact(player, kind, entityID)
    local record, reason = Internal.PlayerRecord(player, true)
    if not record then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = reason,
        })
    end
    kind = tostring(kind or "")
    entityID = tostring(entityID or "")
    if not Types.IsKind(kind) or entityID == "" then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "invalid_contact",
        })
    end
    local entry = record.entities[kind]
        and record.entities[kind][entityID] or nil
    local phase = Types.ClampPhase(entry and entry.phase)
    if not entry or phase < Types.PHASE_RUMORED then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "contact_not_known",
            entityID = entityID, kind = kind,
        })
    end
    local entity = Discovery.ResolveEntity(kind, entityID)
    if not entity then
        return Discovery.BuildSnapshot(player, {
            ok = false, reason = "entity_not_found",
            entityID = entityID, kind = kind,
        })
    end
    local updated, advanceReason
    if phase < Types.PHASE_LOCATED then
        updated, advanceReason = Discovery.SetResolvedPhase(
            player, entity, Types.PHASE_LOCATED, "contact_call", true)
        if not updated then
            return Discovery.BuildSnapshot(player, {
                ok = false, reason = advanceReason,
                entityID = entityID, kind = kind,
            })
        end
        Discovery.Save()
        phase = Types.PHASE_LOCATED
    else
        updated = entry
    end
    return Discovery.BuildSnapshot(player, {
        ok = true,
        reason = phase == Types.PHASE_LOCATED
            and advanceReason == "advanced"
            and "contact_located" or "contact_already_located",
        entityID = entityID,
        kind = kind,
        phase = phase,
        mapUpdated = advanceReason == "advanced",
        factionKnown = updated and updated.factionKnown == true or false,
    })
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
    if action == "radio_ambient" then
        return Discovery.RadioAmbient(player, args.channelID, args.frequency)
    end
    if action == "radio_scan" then
        return Discovery.RadioScan(player, args.channelID, args.frequency)
    end
    if action == "call_contact" then
        return Discovery.CallContact(player, args.kind, args.entityID)
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
    local dirty = false
    if affiliation.communityID then
        local entity = Discovery.ResolveEntity(
            Types.KIND_SETTLEMENT, affiliation.communityID)
        local _, reason = Discovery.SetPhase(
            player,
            Types.KIND_SETTLEMENT,
            affiliation.communityID,
            Types.PHASE_CONTACTED,
            "conversation",
            true
        )
        changed = changed or reason == "advanced"
        dirty = dirty or reason == "advanced"
        if entity then
            local _, arrivalReason = Discovery.MarkContacted(
                player, entity, "conversation", true)
            changed = changed or arrivalReason == "advanced"
            dirty = dirty or arrivalReason == "advanced"
        end
    end
    if affiliation.factionID and PNC.AbstractGroups
        and PNC.AbstractGroups.FindByFactionID
    then
        local group = PNC.AbstractGroups.FindByFactionID(
            affiliation.factionID)
        if group then
            local entity = Discovery.ResolveEntity(
                Types.KIND_MOBILE_GROUP, group.id)
            local _, reason = Discovery.SetPhase(
                player,
                Types.KIND_MOBILE_GROUP,
                group.id,
                Types.PHASE_CONTACTED,
                "conversation",
                true
            )
            changed = changed or reason == "advanced"
            dirty = dirty or reason == "advanced"
            if entity then
                local _, arrivalReason = Discovery.MarkContacted(
                    player, entity, "conversation", true)
                changed = changed or arrivalReason == "advanced"
                dirty = dirty or arrivalReason == "advanced"
            end
        end
    end
    if dirty then Discovery.Save() end
    if changed and PNC.Network and PNC.Network.SendWorldDiscovery then
        PNC.Network.SendWorldDiscovery(player,
            Discovery.BuildSnapshot(player, {
                ok = true, reason = "contacted",
            }))
    end
    return changed
end

return Discovery
