if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Types = PNC.RelationshipTypes
local Math = PNC.RelationshipMath
local Constants = PNC.RelationshipConstants
local isAuthority = Internal.isAuthority
local resolveObserver = Internal.resolveObserver
local validateTarget = Internal.validateTarget
local getRelationship = Internal.getRelationship
local prepareSocial = Internal.prepareSocial
local commit = Internal.commit

function Relationships.Recalculate(observerNPCID, targetKey, worldAgeHours)
    local record
    local reason
    local social
    local socialChanged
    local rawRelationship
    local relationship
    local relationshipChanged
    if not isAuthority() then
        return false, "not_authority"
    end
    worldAgeHours = tonumber(worldAgeHours)
    if worldAgeHours == nil
        or worldAgeHours ~= worldAgeHours
        or worldAgeHours == math.huge
        or worldAgeHours == -math.huge
        or worldAgeHours < 0
    then
        return false, "invalid_world_age_hours"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return false, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return false, reason
    end
    social, socialChanged = prepareSocial(record)
    rawRelationship = getRelationship(record, targetKey)
    relationship = rawRelationship
        and Types.NormalizeRelationship(rawRelationship, targetKey)
        or Types.NewRelationship(targetKey)
    relationship, relationshipChanged =
        Math.RecalculateRelationship(
            relationship,
            targetKey,
            worldAgeHours
        )
    relationshipChanged = rawRelationship == nil
        or relationshipChanged
        or not Types.AreEqual(rawRelationship, relationship)
    if not socialChanged and not relationshipChanged
        and tonumber(social.lastEvaluatedAt) == worldAgeHours
    then
        return false, "unchanged", Types.NormalizeRelationship(
            relationship,
            targetKey
        )
    end
    commit(
        record,
        social,
        targetKey,
        relationship,
        relationshipChanged,
        worldAgeHours,
        {
            kind = "relationship_recalculated",
        }
    )
    return true, "recalculated", Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    )
end

function Relationships.PruneMemories(
    observerNPCID,
    targetKey,
    worldAgeHours
)
    local record
    local reason
    local social
    local socialChanged
    local rawRelationship
    local relationship
    local removed
    local withinLimit
    local changed
    if not isAuthority() then
        return false, "not_authority"
    end
    worldAgeHours = tonumber(worldAgeHours)
    if worldAgeHours == nil
        or worldAgeHours ~= worldAgeHours
        or worldAgeHours == math.huge
        or worldAgeHours == -math.huge
        or worldAgeHours < 0
    then
        return false, "invalid_world_age_hours"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return false, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return false, reason
    end
    rawRelationship = getRelationship(record, targetKey)
    if not rawRelationship then
        return false, "relationship_not_found"
    end
    social, socialChanged = prepareSocial(record)
    relationship, removed, withinLimit = Math.PruneMemories(
        rawRelationship,
        targetKey,
        worldAgeHours,
        Constants.MEMORY_LIMIT
    )
    if not withinLimit then
        return false, "permanent_memory_limit"
    end
    relationship = Math.RecalculateRelationship(
        relationship,
        targetKey,
        worldAgeHours
    )
    changed = not Types.AreEqual(rawRelationship, relationship)
    if not socialChanged and not changed
        and tonumber(social.lastEvaluatedAt) == worldAgeHours
    then
        return false, "unchanged", 0
    end
    commit(
        record,
        social,
        targetKey,
        relationship,
        changed,
        worldAgeHours,
        {
            kind = "memories_pruned",
            removedCount = removed,
        }
    )
    return true, "pruned", removed
end
