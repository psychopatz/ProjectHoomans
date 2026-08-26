if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Internal.relationPair(sourceFactionID, targetFactionID)
    local source = Internal.registryRecord(sourceFactionID)
    local target = Internal.registryRecord(targetFactionID)
    if not source or not target
        or sourceFactionID == targetFactionID
    then
        return nil, nil, "invalid_faction_pair"
    end
    return source, target
end

function Internal.currentRelation(source, targetFactionID)
    return Types.NormalizeRelation(
        source.relations and source.relations[targetFactionID],
        source.id,
        targetFactionID
    )
end

function Factions.GetRelation(sourceFactionID, targetFactionID)
    Factions.EnsureLoaded()
    local source, _, reason = Internal.relationPair(
        sourceFactionID,
        targetFactionID
    )
    if not source then return nil, reason end
    local relation = source.relations
        and source.relations[targetFactionID] or nil
    if not relation then return nil, "relation_not_found" end
    return Internal.copy(Types.NormalizeRelation(
        relation,
        sourceFactionID,
        targetFactionID
    ))
end

function Factions.AreAtWar(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local first = Internal.registryRecord(firstFactionID)
    local second = Internal.registryRecord(secondFactionID)
    if not first or not second then return false end
    local forward = first.relations
        and first.relations[secondFactionID]
    local reverse = second.relations
        and second.relations[firstFactionID]
    return forward ~= nil and reverse ~= nil
        and forward.atWar == true and reverse.atWar == true
end

function Factions.AreAllied(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local first = Internal.registryRecord(firstFactionID)
    local second = Internal.registryRecord(secondFactionID)
    if not first or not second then return false end
    local forward = first.relations
        and first.relations[secondFactionID]
    local reverse = second.relations
        and second.relations[firstFactionID]
    return forward ~= nil and reverse ~= nil
        and forward.allied == true and reverse.allied == true
end

function Factions.GetTruceUntil(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local first = Internal.registryRecord(firstFactionID)
    local second = Internal.registryRecord(secondFactionID)
    if not first or not second then return 0 end
    local forward = first.relations
        and first.relations[secondFactionID]
    local reverse = second.relations
        and second.relations[firstFactionID]
    if not forward or not reverse then return 0 end
    local left = tonumber(forward.truceUntil) or 0
    local right = tonumber(reverse.truceUntil) or 0
    return left == right and left or 0
end

function Factions.IsFactionAtWar(factionID)
    local faction = Internal.registryRecord(factionID)
    if not faction then return false end
    for targetID, relation in pairs(faction.relations or {}) do
        if relation.atWar == true
            and Factions.AreAtWar(factionID, targetID)
        then
            return true
        end
    end
    return false
end

function Internal.rememberIncidentID(relation, incidentID)
    relation.recentIncidentIDs =
        relation.recentIncidentIDs or {}
    for _, existingID in ipairs(relation.recentIncidentIDs) do
        if existingID == incidentID then return false end
    end
    relation.recentIncidentIDs[
        #relation.recentIncidentIDs + 1
    ] = incidentID
    while #relation.recentIncidentIDs
        > (
            PNC.FactionBalance
            and PNC.FactionBalance.Get(
                "recentIncidentIDLimit"
            ) or Constants.RECENT_INCIDENT_ID_LIMIT
        )
    do
        table.remove(relation.recentIncidentIDs, 1)
    end
    return true
end

function Internal.appendAudit(
    relation,
    relationSourceID,
    relationTargetID,
    incidentType,
    at,
    initiatingFactionID
)
    local incidentID = table.concat({
        "treaty",
        incidentType,
        tostring(at),
        tostring(initiatingFactionID or relationSourceID),
        relationSourceID,
        relationTargetID,
    }, ":")
    if not Internal.rememberIncidentID(relation, incidentID) then
        return false
    end
    local definition =
        PNC.FactionIncidentDefinitions.Get(incidentType)
    local incident = Types.NormalizeIncident({
        id = incidentID,
        type = incidentType,
        sourceFactionID = initiatingFactionID
            or relationSourceID,
        targetFactionID = initiatingFactionID == relationTargetID
            and relationSourceID or relationTargetID,
        occurredAt = at,
        standingEffect = definition.standing,
        trustEffect = definition.trust,
        fearEffect = definition.fear,
        grievanceEffect = definition.grievance,
        severity = definition.severity,
        public = true,
        witnessed = true,
        preserve = true,
        tags = definition.tags,
    }, relationSourceID, relationTargetID)
    if incident then
        relation.incidents[#relation.incidents + 1] = incident
    end
    return incident ~= nil
end

function Internal.reconcilePair(
    firstFactionID,
    secondFactionID,
    reason,
    worldAgeHours
)
    if not PNC.FactionBehavior
        or not PNC.FactionBehavior.QueueTreatyReconciliation
    then
        return
    end
    PNC.FactionBehavior.QueueTreatyReconciliation(
        firstFactionID,
        secondFactionID,
        reason,
        worldAgeHours
    )
    if PNC.FactionBehavior.PumpReconciliation then
        PNC.FactionBehavior.PumpReconciliation()
    end
end

function Factions.CommitDirectedRelation(
    sourceFactionID,
    targetFactionID,
    relation,
    reason
)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local source, _, pairReason = Internal.relationPair(
        sourceFactionID,
        targetFactionID
    )
    if not source then return false, pairReason end
    local existing = Internal.currentRelation(source, targetFactionID)
    local normalized = Types.NormalizeRelation(
        relation,
        sourceFactionID,
        targetFactionID
    )
    normalized.revision = existing.revision
    if Types.AreEqual(existing, normalized) then
        return false, "unchanged", Internal.copy(existing)
    end
    normalized.revision = existing.revision + 1
    source.relations[targetFactionID] = normalized
    Internal.touchFaction(source)
    Internal.touchRegistry()
    Internal.reconcilePair(
        sourceFactionID,
        targetFactionID,
        reason or "directed_relation_changed"
    )
    return true, "updated", Internal.copy(normalized)
end

function Factions.RecalculateRelation(
    sourceFactionID,
    targetFactionID,
    worldAgeHours
)
    local source, _, reason = Internal.relationPair(
        sourceFactionID,
        targetFactionID
    )
    if not source then return false, reason end
    local relation = Internal.currentRelation(source, targetFactionID)
    local recalculated, changed =
        PNC.FactionDiplomacyMath.RecalculateRelation(
            relation,
            Internal.finiteTimestamp(worldAgeHours, 0)
        )
    if not changed then
        return false, "unchanged", Internal.copy(relation)
    end
    return Factions.CommitDirectedRelation(
        sourceFactionID,
        targetFactionID,
        recalculated,
        "diplomacy_recalculated"
    )
end

return Factions
