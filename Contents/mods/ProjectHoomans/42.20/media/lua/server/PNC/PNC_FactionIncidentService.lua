-- Server-authoritative faction incident ingestion and escalation.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}

local Service = PNC.FactionIncidentService
local Factions = PNC.Factions
local Types = PNC.FactionTypes
local Constants = PNC.FactionConstants
local Definitions = PNC.FactionIncidentDefinitions
local Math = PNC.FactionDiplomacyMath
local EntityRef = PNC.EntityRef
local Core = PNC.Core
local Balance = PNC.FactionBalance

Service.RuntimeEpisodes = Service.RuntimeEpisodes or {}
Service.RuntimeCallbackIDs = Service.RuntimeCallbackIDs or {}
Service.RuntimeCallbackOrder =
    Service.RuntimeCallbackOrder or {}
Service.LastRuntimePumpAtMS =
    tonumber(Service.LastRuntimePumpAtMS) or 0

local function tuning(name, fallback)
    local value = Balance and Balance.Get and Balance.Get(name)
    return value == nil and fallback or value
end

local function authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

local function finiteTimestamp(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
        or value < 0
    then
        return nil
    end
    return value
end

local function safeEntityKey(value)
    return EntityRef and EntityRef.IsValid
        and EntityRef.IsValid(value) and value or nil
end

local function containsID(relation, incidentID)
    for _, id in ipairs(relation.recentIncidentIDs or {}) do
        if id == incidentID then return true end
    end
    return false
end

local function pushID(relation, incidentID)
    relation.recentIncidentIDs =
        relation.recentIncidentIDs or {}
    relation.recentIncidentIDs[
        #relation.recentIncidentIDs + 1
    ] = incidentID
    while #relation.recentIncidentIDs
        > tuning("recentIncidentIDLimit",
            Constants.RECENT_INCIDENT_ID_LIMIT)
    do
        table.remove(relation.recentIncidentIDs, 1)
    end
end

local function trimIncidents(relation)
    while #relation.incidents > tuning(
        "incidentHistoryLimit", Constants.INCIDENT_LIMIT
    ) do
        local weakest
        for index, incident in ipairs(relation.incidents) do
            if incident.preserve ~= true
                and (
                    not weakest
                    or incident.severity
                        < relation.incidents[weakest].severity
                    or (
                        incident.severity
                            == relation.incidents[weakest].severity
                        and incident.occurredAt
                            < relation.incidents[weakest].occurredAt
                    )
                    or (
                        incident.severity
                            == relation.incidents[weakest].severity
                        and incident.occurredAt
                            == relation.incidents[weakest].occurredAt
                        and incident.id
                            < relation.incidents[weakest].id
                    )
                )
            then
                weakest = index
            end
        end
        table.remove(relation.incidents, weakest or 1)
    end
end

local function applyEffects(relation, definition, multiplier)
    multiplier = tonumber(multiplier) or 1
    relation.standing = Math.ClampStanding(
        relation.standing + definition.standing * multiplier
    )
    relation.trust = Math.ClampTrust(
        relation.trust + definition.trust * multiplier
    )
    relation.fear = Math.ClampFear(
        relation.fear + definition.fear * multiplier
    )
    relation.grievance = Math.ClampGrievance(
        relation.grievance + definition.grievance * multiplier
    )
end

local function warReasonFor(incidentType, leader)
    if incidentType == "member_killed" then
        return leader and "leader_killed" or "member_killed"
    end
    return incidentType == "member_attacked_severe"
        and "severe_assault" or "repeated_aggression"
end

local function maybeEscalate(
    actorFactionID,
    victimFactionID,
    incident,
    relation,
    spec
)
    if Factions.AreAtWar(actorFactionID, victimFactionID) then
        return false, "already_at_war"
    end
    local victimFaction = Factions.Registry.byID[victimFactionID]
    local policy = victimFaction and victimFaction.policy or {}
    local at = incident.occurredAt
    local truceUntil = Factions.GetTruceUntil(
        actorFactionID,
        victimFactionID
    )
    local leader = spec.targetRecord
        and (
            spec.targetRecord.id == victimFaction.leaderNPCID
            or (
                spec.targetRecord.affiliation
                and spec.targetRecord.affiliation.rank == "leader"
            )
        )
    local shouldDeclare = truceUntil > at
    local reason = shouldDeclare and "truce_broken"
        or warReasonFor(incident.type, leader)
    if not shouldDeclare and incident.type == "member_killed" then
        shouldDeclare = leader
            or (tonumber(policy.retaliation) or 0.5)
                >= tuning("killedRetaliationMinimum", 0.25)
    elseif not shouldDeclare
        and incident.type == "member_attacked_severe"
    then
        local score = relation.grievance
            + (tonumber(policy.retaliation) or 0.5)
                * tuning("escalationRetaliationWeight", 35)
            + (tonumber(policy.aggression) or 0.5)
                * tuning("escalationAggressionWeight", 15)
        shouldDeclare = score
            >= (tonumber(policy.warThreshold) or 70)
            or leader
                and (tonumber(policy.retaliation) or 0.5)
                    >= tuning(
                        "leaderRetaliationMinimum", 0.25
                    )
    elseif not shouldDeclare
        and incident.type == "member_attacked_minor"
    then
        shouldDeclare = relation.state == "hostile"
            and (tonumber(policy.retaliation) or 0.5)
                >= tuning(
                    "hostileMinorRetaliationMinimum", 0.5
                )
    elseif not shouldDeclare
        and incident.type == "personal_grievance_report"
    then
        local rank = tostring(spec.authorityRank or "member")
        local influence = rank == "leader"
            and tuning("leaderAuthorityInfluence", 20)
            or rank == "second"
                and tuning("secondAuthorityInfluence", 15)
            or rank == "officer"
                and tuning("officerAuthorityInfluence", 10)
            or 0
        local score = relation.grievance + influence
            + (tonumber(policy.retaliation) or 0.5)
                * tuning("escalationRetaliationWeight", 35)
            + (tonumber(policy.aggression) or 0.5)
                * tuning("escalationAggressionWeight", 15)
        shouldDeclare = relation.state == "hostile"
            and score >= (tonumber(policy.warThreshold) or 70)
    end
    if not shouldDeclare then
        return false, "escalation_threshold_not_met"
    end
    return Factions.DeclareWar(
        victimFactionID,
        actorFactionID,
        {
            worldAgeHours = at,
            reason = reason,
            instigatorFactionID = victimFactionID,
            triggeringIncidentID = incident.id,
        }
    )
end

function Service.AddIncident(
    actorFactionID,
    victimFactionID,
    incidentType,
    spec
)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    spec = type(spec) == "table" and spec or {}
    local actorFaction = Factions.Registry.byID[actorFactionID]
    local victimFaction = Factions.Registry.byID[victimFactionID]
    local definition = Definitions.Get(incidentType)
    local at = finiteTimestamp(spec.worldAgeHours)
    if not actorFaction or not victimFaction
        or actorFactionID == victimFactionID
    then
        return false, "invalid_faction_pair"
    end
    if not definition then return false, "invalid_incident_type" end
    if not at then return false, "invalid_world_age" end
    local relationSourceID = spec.relationSourceFactionID
        or victimFactionID
    local relationTargetID = spec.relationTargetFactionID
        or actorFactionID
    if relationSourceID ~= actorFactionID
        and relationSourceID ~= victimFactionID
    then
        return false, "invalid_relation_source"
    end
    if relationTargetID ~= actorFactionID
        and relationTargetID ~= victimFactionID
    then
        return false, "invalid_relation_target"
    end
    local relationOwner =
        Factions.Registry.byID[relationSourceID]
    local relation = Types.NormalizeRelation(
        relationOwner.relations[relationTargetID],
        relationSourceID,
        relationTargetID
    )
    local incidentID = tostring(
        spec.externalID
        or table.concat({
            "incident",
            incidentType,
            actorFactionID,
            victimFactionID,
            tostring(at),
            tostring(spec.actorKey or ""),
            tostring(spec.subjectKey or ""),
        }, ":")
    )
    if containsID(relation, incidentID)
        and spec.upgradeIncidentID ~= incidentID
    then
        return false, "duplicate_incident_id"
    end

    local oldDefinition
    local upgradedIndex
    if spec.upgradeIncidentID then
        for index, existing in ipairs(relation.incidents) do
            if existing.id == spec.upgradeIncidentID then
                oldDefinition = Definitions.Get(existing.type)
                upgradedIndex = index
                incidentID = existing.id
                break
            end
        end
        if not upgradedIndex then
            return false, "incident_to_upgrade_not_found"
        end
    end

    local grievanceBonus = 0
    local fearBonus = 0
    if spec.targetRecord and victimFaction.leaderNPCID
        == spec.targetRecord.id
        and (
            incidentType == "member_killed"
            or incidentType == "member_attacked_severe"
        )
    then
        grievanceBonus = 20
        fearBonus = 10
    end
    local incident = Types.NormalizeIncident({
        id = incidentID,
        type = incidentType,
        sourceFactionID = actorFactionID,
        targetFactionID = victimFactionID,
        actorKey = safeEntityKey(spec.actorKey),
        subjectKey = safeEntityKey(spec.subjectKey),
        occurredAt = at,
        standingEffect = definition.standing,
        trustEffect = definition.trust,
        fearEffect = definition.fear + fearBonus,
        grievanceEffect = definition.grievance + grievanceBonus,
        severity = definition.severity,
        public = spec.public ~= false,
        witnessed = spec.witnessed ~= false,
        preserve = definition.preserve,
        tags = definition.tags,
    }, relationSourceID, relationTargetID)
    if not incident then return false, "invalid_incident" end

    if oldDefinition then
        applyEffects(relation, {
            standing = definition.standing - oldDefinition.standing,
            trust = definition.trust - oldDefinition.trust,
            fear = definition.fear - oldDefinition.fear + fearBonus,
            grievance = definition.grievance
                - oldDefinition.grievance + grievanceBonus,
        }, 1)
        relation.incidents[upgradedIndex] = incident
    else
        applyEffects(relation, {
            standing = incident.standingEffect,
            trust = incident.trustEffect,
            fear = incident.fearEffect,
            grievance = incident.grievanceEffect,
        }, 1)
        relation.incidents[#relation.incidents + 1] = incident
        pushID(relation, incidentID)
    end
    relation.lastEvaluatedAt = at
    local resolved = Math.ResolveState(relation, at)
    if resolved ~= relation.state then
        relation.previousState = relation.state
        relation.state = resolved
    end
    trimIncidents(relation)
    local ok, reason, committed =
        Factions.CommitDirectedRelation(
            relationSourceID,
            relationTargetID,
            relation,
            "faction_incident_" .. incidentType
        )
    if not ok then return false, reason, committed end
    local allianceBroken = false
    if committed.allied == true
        and (
            incidentType == "member_attacked_minor"
            or incidentType == "member_attacked_severe"
            or incidentType == "member_killed"
            or incidentType == "member_abandoned"
        )
    then
        allianceBroken = Factions.BreakAlliance(
            actorFactionID,
            victimFactionID,
            {
                worldAgeHours = at,
                instigatorFactionID = actorFactionID,
            }
        ) == true
        committed = Factions.GetRelation(
            relationSourceID,
            relationTargetID
        ) or committed
    end
    local escalated, escalationReason = maybeEscalate(
        actorFactionID,
        victimFactionID,
        incident,
        committed,
        spec
    )
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordIncident({
            operation = "add_incident",
            worldAgeHours = at,
            actorKey = incident.actorKey,
            subjectKey = incident.subjectKey,
            sourceFactionID = actorFactionID,
            targetFactionID = victimFactionID,
            result = upgradedIndex and "upgraded" or "created",
            reason = incidentType,
            incidentID = incident.id,
            relationRevision = committed.revision,
        })
        PNC.FactionTelemetry.RecordEscalation({
            operation = "evaluate_escalation",
            worldAgeHours = at,
            sourceFactionID = victimFactionID,
            targetFactionID = actorFactionID,
            result = escalated == true
                and "war_declared" or "no_war",
            reason = escalationReason,
            incidentID = incident.id,
            grievance = committed.grievance,
        })
    end
    return true, upgradedIndex and "incident_upgraded"
        or "incident_added", {
        incident = incident,
        relation = committed,
        allianceBroken = allianceBroken,
        warDeclared = escalated == true,
        escalationReason = escalationReason,
    }
end

local function episodeKey(
    actorFactionID,
    victimFactionID,
    actorKey,
    subjectKey
)
    return table.concat({
        actorFactionID,
        victimFactionID,
        tostring(actorKey or ""),
        tostring(subjectKey or ""),
    }, "|")
end

function Service.RecordAttack(
    actorFactionID,
    victimFactionID,
    spec
)
    spec = type(spec) == "table" and spec or {}
    local at = finiteTimestamp(spec.worldAgeHours)
    if not at then return false, "invalid_world_age" end
    local actorKey = safeEntityKey(spec.actorKey)
    local subjectKey = safeEntityKey(spec.subjectKey)
    if not actorKey or not subjectKey then
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordAggregation({
                operation = "record_attack",
                worldAgeHours = at,
                result = "rejected",
                reason = "invalid_attack_entity_key",
            })
        end
        return false, "invalid_attack_entity_key"
    end
    local damage = math.max(0, tonumber(spec.damage) or 0)
    if spec.killed ~= true and spec.severe ~= true
        and damage > 0
        and damage < tuning("minorAttackDamageThreshold", 0)
    then
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordAggregation({
                operation = "record_attack",
                worldAgeHours = at,
                actorKey = spec.actorKey,
                subjectKey = spec.subjectKey,
                sourceFactionID = actorFactionID,
                targetFactionID = victimFactionID,
                result = "rejected",
                reason = "below_minor_damage_threshold",
                accumulatedDamage = damage,
            })
        end
        return false, "below_minor_damage_threshold"
    end
    if type(spec.callbackID) == "string"
        and spec.callbackID ~= ""
    then
        if Service.RuntimeCallbackIDs[spec.callbackID] then
            if PNC.FactionTelemetry then
                PNC.FactionTelemetry.RecordAggregation({
                    operation = "record_attack",
                    worldAgeHours = at,
                    sourceFactionID = actorFactionID,
                    targetFactionID = victimFactionID,
                    result = "duplicate",
                    reason = "duplicate_callback",
                    callbackID = spec.callbackID,
                })
            end
            return false, "duplicate_callback"
        end
        Service.RuntimeCallbackIDs[spec.callbackID] = at
        Service.RuntimeCallbackOrder[
            #Service.RuntimeCallbackOrder + 1
        ] = spec.callbackID
        while #Service.RuntimeCallbackOrder
            > tuning("callbackDedupeLimit", 2048)
        do
            local oldest = table.remove(
                Service.RuntimeCallbackOrder, 1
            )
            Service.RuntimeCallbackIDs[oldest] = nil
        end
    end
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
    if spec.killed ~= true
        and spec.severe ~= true
        and damage > 0
        and damage < tuning("minorAttackDamageThreshold", 0)
    then
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordAggregation({
                operation = "record_attack",
                worldAgeHours = at,
                actorKey = spec.actorKey,
                subjectKey = spec.subjectKey,
                sourceFactionID = actorFactionID,
                targetFactionID = victimFactionID,
                encounterKey = key,
                result = "rejected",
                reason = "damage_below_minor_threshold",
                accumulatedDamage = damage,
            })
        end
        return false, "damage_below_minor_threshold"
    end
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

function Service.RecordPositiveEvent(
    actorFactionID,
    beneficiaryFactionID,
    incidentType,
    spec
)
    if incidentType ~= "member_rescued"
        and incidentType ~= "member_protected"
        and incidentType ~= "members_fought_together"
        and incidentType ~= "member_abandoned"
    then
        return false, "unsupported_social_incident"
    end
    return Service.AddIncident(
        actorFactionID,
        beneficiaryFactionID,
        incidentType,
        spec
    )
end

return Service
