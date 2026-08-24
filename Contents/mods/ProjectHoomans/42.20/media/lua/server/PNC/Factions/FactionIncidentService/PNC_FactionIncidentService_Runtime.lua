if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}
PNC.FactionIncidentService.Internal =
    PNC.FactionIncidentService.Internal or {}

local Service = PNC.FactionIncidentService
local Internal = Service.Internal
local Core = PNC.Core
local tuning = Internal.tuning
local finiteTimestamp = Internal.finiteTimestamp
local safeEntityKey = Internal.safeEntityKey

function Service.PumpRuntime(worldAgeHours)
    local at = finiteTimestamp(worldAgeHours)
    if not at then return 0 end
    local nowMS = Core and Core.Now and Core.Now() or 0
    if nowMS > 0
        and nowMS - Service.LastRuntimePumpAtMS < 1000
    then
        return 0
    end
    Service.LastRuntimePumpAtMS = nowMS
    local removed = 0
    for key, episode in pairs(Service.RuntimeEpisodes) do
        if (tonumber(episode.expiresAt) or 0) <= at then
            Service.RuntimeEpisodes[key] = nil
            removed = removed + 1
            if PNC.FactionTelemetry then
                PNC.FactionTelemetry.RecordAggregation({
                    operation = "expire_episode",
                    worldAgeHours = at,
                    actorKey = episode.actorKey,
                    subjectKey = episode.subjectKey,
                    sourceFactionID = episode.sourceFactionID,
                    targetFactionID = episode.targetFactionID,
                    encounterKey = key,
                    result = episode.type
                        == "member_attacked_minor"
                        and "finalized_minor"
                        or "finalized_severe",
                    reason = "aggregation_window_expired",
                    incidentID = episode.incidentID,
                    hitCount = episode.hitCount,
                    accumulatedDamage = episode.totalDamage,
                    maximumDamage = episode.maximumDamage,
                })
            end
        end
    end
    local callbackCutoff = at
        - tuning("callbackDedupeHours", 1)
    for callbackID, createdAt in pairs(
        Service.RuntimeCallbackIDs
    ) do
        if (tonumber(createdAt) or 0) <= callbackCutoff then
            Service.RuntimeCallbackIDs[callbackID] = nil
        end
    end
    local retained = {}
    for _, callbackID in ipairs(
        Service.RuntimeCallbackOrder
    ) do
        if Service.RuntimeCallbackIDs[callbackID] then
            retained[#retained + 1] = callbackID
        end
    end
    Service.RuntimeCallbackOrder = retained
    return removed
end

function Service.CleanupEntity(entityKey, worldAgeHours, reason)
    if not safeEntityKey(entityKey) then
        return 0, "invalid_entity_key"
    end
    local removed = 0
    for key, episode in pairs(Service.RuntimeEpisodes) do
        if episode.actorKey == entityKey
            or episode.subjectKey == entityKey
        then
            Service.RuntimeEpisodes[key] = nil
            removed = removed + 1
            if PNC.FactionTelemetry then
                PNC.FactionTelemetry.RecordAggregation({
                    operation = "cleanup_entity",
                    worldAgeHours = finiteTimestamp(worldAgeHours)
                        or 0,
                    actorKey = episode.actorKey,
                    subjectKey = episode.subjectKey,
                    sourceFactionID = episode.sourceFactionID,
                    targetFactionID = episode.targetFactionID,
                    encounterKey = key,
                    result = "canceled",
                    reason = tostring(reason or "entity_cleanup"),
                    incidentID = episode.incidentID,
                })
            end
        end
    end
    return removed, "cleaned"
end

function Service.GetActiveEpisodes()
    local output = {}
    for _, episode in pairs(Service.RuntimeEpisodes) do
        output[#output + 1] = {
            id = episode.id,
            key = episode.key,
            actorKey = episode.actorKey,
            subjectKey = episode.subjectKey,
            sourceFactionID = episode.sourceFactionID,
            targetFactionID = episode.targetFactionID,
            incidentID = episode.incidentID,
            type = episode.type,
            state = episode.state,
            firstAt = episode.firstAt,
            lastAt = episode.lastAt,
            expiresAt = episode.expiresAt,
            hitCount = episode.hitCount,
            totalDamage = episode.totalDamage,
            maximumDamage = episode.maximumDamage,
            leaderVictim = episode.leaderVictim,
            intentionality = episode.intentionality,
        }
    end
    table.sort(output, function(left, right)
        return tostring(left.key) < tostring(right.key)
    end)
    return output
end
