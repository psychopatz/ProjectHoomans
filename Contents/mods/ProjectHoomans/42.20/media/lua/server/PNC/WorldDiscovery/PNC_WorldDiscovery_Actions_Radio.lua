if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Discovery = PNC.WorldDiscovery
local Internal = Discovery.Internal
local Types = PNC.WorldDiscoveryTypes
local Core = PNC.Core
local chancePasses = Internal.ChancePasses
local signalRollPasses = Internal.SignalRollPasses
local markRadioAttempt = Internal.MarkRadioAttempt
local compactRadioBroadcast = Internal.CompactRadioBroadcast

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
        factionRevealed = broadcastContext
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

