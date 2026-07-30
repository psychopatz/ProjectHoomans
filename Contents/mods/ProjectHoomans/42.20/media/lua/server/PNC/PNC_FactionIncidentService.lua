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

Service.RuntimeEpisodes = Service.RuntimeEpisodes or {}
Service.RuntimeCallbackIDs = Service.RuntimeCallbackIDs or {}

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
        > Constants.RECENT_INCIDENT_ID_LIMIT
    do
        table.remove(relation.recentIncidentIDs, 1)
    end
end

local function trimIncidents(relation)
    while #relation.incidents > Constants.INCIDENT_LIMIT do
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
            or (tonumber(policy.retaliation) or 0.5) >= 0.25
    elseif not shouldDeclare
        and incident.type == "member_attacked_severe"
    then
        local score = relation.grievance
            + (tonumber(policy.retaliation) or 0.5) * 35
            + (tonumber(policy.aggression) or 0.5) * 15
        shouldDeclare = score
            >= (tonumber(policy.warThreshold) or 70)
            or leader
                and (tonumber(policy.retaliation) or 0.5) >= 0.25
    elseif not shouldDeclare
        and incident.type == "member_attacked_minor"
    then
        shouldDeclare = relation.state == "hostile"
            and (tonumber(policy.retaliation) or 0.5) >= 0.5
    elseif not shouldDeclare
        and incident.type == "personal_grievance_report"
    then
        local rank = tostring(spec.authorityRank or "member")
        local influence = rank == "leader" and 20
            or rank == "second" and 15
            or rank == "officer" and 10 or 0
        local score = relation.grievance + influence
            + (tonumber(policy.retaliation) or 0.5) * 35
            + (tonumber(policy.aggression) or 0.5) * 15
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
    if type(spec.callbackID) == "string"
        and spec.callbackID ~= ""
    then
        if Service.RuntimeCallbackIDs[spec.callbackID] then
            return false, "duplicate_callback"
        end
        Service.RuntimeCallbackIDs[spec.callbackID] = at
    end
    local key = episodeKey(
        actorFactionID,
        victimFactionID,
        spec.actorKey,
        spec.subjectKey
    )
    local episode = Service.RuntimeEpisodes[key]
    local withinEpisode = episode
        and at >= episode.lastAt
        and at - episode.lastAt
            <= Constants.ATTACK_AGGREGATION_HOURS
    local incidentType
    if spec.killed == true then
        incidentType = "member_killed"
    elseif spec.severe == true or withinEpisode then
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
        episode = { hitCount = 0 }
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
        Service.RuntimeEpisodes[key] = episode
    end
    return ok, reason, result
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
