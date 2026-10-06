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

local function hasMeaningfulRelationship(relationship)
    if type(relationship) ~= "table" then return false end
    if tonumber(relationship.baselineApproval) ~= 0
        or tonumber(relationship.baselineRespect) ~= 0
        or tonumber(relationship.approval) ~= 0
        or tonumber(relationship.respect) ~= 0
        or tonumber(relationship.familiarity) ~= 0
        or tostring(relationship.state or "unknown") ~= "unknown"
        or #(relationship.memories or {}) > 0
        or #(relationship.interactionJournal or {}) > 0
    then
        return true
    end
    return false
end

local function retargetMemoryReferences(relationship, legacyTargetKey,
    canonicalTargetKey)
    local index
    local memory
    for index, memory in ipairs(relationship.memories or {}) do
        if memory.aboutKey == legacyTargetKey then
            memory.aboutKey = canonicalTargetKey
        end
        if memory.sourceKey == legacyTargetKey then
            memory.sourceKey = canonicalTargetKey
        end
    end
end

-- Move a relationship whose target identity was written with the legacy
-- presentation identity into the canonical player entity key. An existing
-- meaningful canonical relationship is preserved; this avoids overwriting
-- post-refactor interactions merely because a legacy duplicate remains.
function Relationships.MigrateTargetKey(
    observerNPCID,
    legacyTargetKey,
    canonicalTargetKey,
    worldAgeHours
)
    local record
    local reason
    local social
    local socialChanged
    local legacyRelationship
    local canonicalRelationship
    local relationship
    if not isAuthority() then return false, "not_authority" end
    record, reason = resolveObserver(observerNPCID)
    if not record then return false, reason end
    legacyTargetKey, reason = validateTarget(legacyTargetKey)
    if not legacyTargetKey then return false, reason end
    canonicalTargetKey, reason = validateTarget(canonicalTargetKey)
    if not canonicalTargetKey then return false, reason end
    if legacyTargetKey == canonicalTargetKey then
        return true, "same_target_key"
    end
    social, socialChanged = prepareSocial(record)
    legacyRelationship = getRelationship(record, legacyTargetKey)
    if not legacyRelationship then
        return false, "source_not_found"
    end
    canonicalRelationship = getRelationship(record, canonicalTargetKey)
    if canonicalRelationship then
        canonicalRelationship = Types.NormalizeRelationship(
            canonicalRelationship,
            canonicalTargetKey
        )
        if hasMeaningfulRelationship(canonicalRelationship) then
            return false, "target_exists"
        end
    end
    relationship = Types.NormalizeRelationship(
        legacyRelationship,
        canonicalTargetKey
    )
    if not relationship then return false, "relationship_invalid" end
    retargetMemoryReferences(
        relationship,
        legacyTargetKey,
        canonicalTargetKey
    )
    social.relationships[legacyTargetKey] = nil
    commit(
        record,
        social,
        canonicalTargetKey,
        relationship,
        true,
        worldAgeHours,
        {
            kind = "relationship_key_migrated",
            legacyTargetKey = legacyTargetKey,
        }
    )
    return true, "migrated", Types.NormalizeRelationship(
        record.social.relationships[canonicalTargetKey],
        canonicalTargetKey
    )
end

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
