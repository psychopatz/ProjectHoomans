if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionIncidentService = PNC.FactionIncidentService or {}
PNC.FactionIncidentService.Internal =
    PNC.FactionIncidentService.Internal or {}

local Service = PNC.FactionIncidentService
local Internal = Service.Internal
local Factions = PNC.Factions
local Types = PNC.FactionTypes
local Definitions = PNC.FactionIncidentDefinitions
local Math = PNC.FactionDiplomacyMath
local authority = Internal.authority
local finiteTimestamp = Internal.finiteTimestamp
local safeEntityKey = Internal.safeEntityKey
local containsID = Internal.containsID
local pushID = Internal.pushID
local trimIncidents = Internal.trimIncidents
local applyEffects = Internal.applyEffects
local maybeEscalate = Internal.maybeEscalate

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
