if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}
PNC.FactionIncidentService.Internal =
    PNC.FactionIncidentService.Internal or {}

local Service = PNC.FactionIncidentService
local Internal = Service.Internal
local Factions = PNC.Factions
local Constants = PNC.FactionConstants
local tuning = Internal.tuning
local episodeKey = Internal.episodeKey
local validateAttack = Internal.validateAttack

function Service.RecordAttack(
    actorFactionID,
    victimFactionID,
    spec
)
    spec = type(spec) == "table" and spec or {}
    local prepared, preflightReason = validateAttack(
        actorFactionID, victimFactionID, spec)
    if not prepared then return false, preflightReason end
    local at = prepared.at
    local actorKey = prepared.actorKey
    local subjectKey = prepared.subjectKey
    local damage = prepared.damage
    local key = episodeKey(
        actorFactionID,
        victimFactionID,
        actorKey,
        subjectKey
    )
    local episode = Service.RuntimeEpisodes[key]
    local aggregationHours = tuning(
        "attackAggregationHours",
        Constants.ATTACK_AGGREGATION_HOURS
    )
    local withinEpisode = episode
        and at >= episode.lastAt
        and at - episode.lastAt
            <= aggregationHours
    local nextHitCount = withinEpisode
        and (episode.hitCount or 0) + 1 or 1
    local severe = spec.severe == true
        or damage > 0
            and damage >= tuning(
                "severeAttackDamageThreshold", 25
            )
        or nextHitCount >= tuning("repeatedAttackCount", 2)
    local incidentType
    if spec.killed == true then
        incidentType = "member_killed"
    elseif severe then
        incidentType = "member_attacked_severe"
    else
        incidentType = "member_attacked_minor"
    end
    local externalID
    local upgradeIncidentID
    if withinEpisode then
        externalID = episode.incidentID
        if episode.type ~= incidentType then
            upgradeIncidentID = episode.incidentID
        else
            episode.lastAt = at
            episode.hitCount = episode.hitCount + 1
            episode.totalDamage =
                (episode.totalDamage or 0) + damage
            episode.maximumDamage = math.max(
                episode.maximumDamage or 0, damage
            )
            episode.expiresAt = at + aggregationHours
            episode.state = "duplicate"
            if PNC.FactionTelemetry then
                PNC.FactionTelemetry.RecordAggregation({
                    operation = "record_attack",
                    worldAgeHours = at,
                    actorKey = spec.actorKey,
                    subjectKey = spec.subjectKey,
                    sourceFactionID = actorFactionID,
                    targetFactionID = victimFactionID,
                    encounterKey = key,
                    result = "duplicate",
                    reason = "incident_already_finalized",
                    incidentID = episode.incidentID,
                    firstHitAt = episode.firstAt,
                    lastHitAt = episode.lastAt,
                    hitCount = episode.hitCount,
                    accumulatedDamage = episode.totalDamage,
                    maximumDamage = episode.maximumDamage,
                    expiryTime = episode.expiresAt,
                })
            end
            return false, "attack_aggregated"
        end
    else
        externalID = table.concat({
            "attack",
            actorFactionID,
            victimFactionID,
            tostring(spec.actorKey or ""),
            tostring(spec.subjectKey or ""),
            tostring(at),
        }, ":")
        episode = {
            id = externalID,
            key = key,
            firstAt = at,
            hitCount = 0,
            totalDamage = 0,
            maximumDamage = 0,
            state = "new",
        }
    end
    local request = {}
    for name, value in pairs(spec) do request[name] = value end
    request.externalID = externalID
    request.upgradeIncidentID = upgradeIncidentID
    local ok, reason, result = Service.AddIncident(
        actorFactionID,
        victimFactionID,
        incidentType,
        request
    )
    if ok then
        episode.incidentID = externalID
        episode.type = incidentType
        episode.lastAt = at
        episode.hitCount = (episode.hitCount or 0) + 1
        episode.totalDamage =
            (episode.totalDamage or 0) + damage
        episode.maximumDamage = math.max(
            episode.maximumDamage or 0, damage
        )
        episode.expiresAt = at + aggregationHours
        episode.actorKey = actorKey
        episode.subjectKey = subjectKey
        episode.sourceFactionID = actorFactionID
        episode.targetFactionID = victimFactionID
        episode.leaderVictim = spec.targetRecord ~= nil
            and Factions.Registry.byID[victimFactionID] ~= nil
            and Factions.Registry.byID[victimFactionID]
                .leaderNPCID == spec.targetRecord.id
        local intentionality = type(spec.intentionality)
            == "string" and spec.intentionality
            or "intentional"
        if intentionality ~= "intentional"
            and intentionality ~= "accidental"
            and intentionality ~= "self_defense"
            and intentionality ~= "unknown"
        then
            intentionality = "unknown"
        end
        episode.intentionality = intentionality
        episode.state = upgradeIncidentID
            and "upgraded_to_severe"
            or incidentType == "member_attacked_minor"
                and "finalized_minor" or "finalized_severe"
        Service.RuntimeEpisodes[key] = episode
    end
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordAggregation({
            operation = "record_attack",
            worldAgeHours = at,
            actorKey = spec.actorKey,
            subjectKey = spec.subjectKey,
            sourceFactionID = actorFactionID,
            targetFactionID = victimFactionID,
            encounterKey = key,
            result = ok and episode.state or "rejected",
            reason = reason,
            incidentID = episode.incidentID,
            firstHitAt = episode.firstAt,
            lastHitAt = episode.lastAt,
            hitCount = episode.hitCount,
            accumulatedDamage = episode.totalDamage,
            maximumDamage = episode.maximumDamage,
            leaderVictim = episode.leaderVictim,
            intentionality = episode.intentionality,
            severityBand = episode.type,
            finalizedIncidentType = episode.type,
            expiryTime = episode.expiresAt,
        })
    end
    return ok, reason, result
end
