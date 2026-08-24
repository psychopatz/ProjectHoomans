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
local buildMemorySpec = Internal.buildMemorySpec
local findMemory = Internal.findMemory
local commit = Internal.commit

function Relationships.AddMemory(observerNPCID, targetKey, memorySpec)
    local record
    local reason
    local social
    local relationship
    local memory
    local worldAgeHours
    local withinLimit
    local index
    if not isAuthority() then
        return false, "not_authority"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return false, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return false, reason
    end
    memory = Types.NewMemory(buildMemorySpec(memorySpec, targetKey))
    if not memory or memory.aboutKey ~= targetKey then
        return false, "invalid_memory"
    end
    social = Types.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    relationship = getRelationship(record, targetKey)
    relationship = relationship
        and Types.NormalizeRelationship(relationship, targetKey)
        or Types.NewRelationship(targetKey)
    if findMemory(relationship, memory.id) then
        return false, "duplicate_memory_id"
    end
    relationship.memories[#relationship.memories + 1] = memory
    worldAgeHours = math.max(
        tonumber(relationship.lastEvaluatedAt) or 0,
        tonumber(memory.createdAt) or 0
    )
    relationship, _, withinLimit = Math.PruneMemories(
        relationship,
        targetKey,
        worldAgeHours,
        Constants.MEMORY_LIMIT
    )
    if not withinLimit then
        return false, "permanent_memory_limit"
    end
    index = findMemory(relationship, memory.id)
    if not index then
        return false, "memory_pruned_by_limit"
    end
    relationship = Math.RecalculateRelationship(
        relationship,
        targetKey,
        worldAgeHours
    )
    commit(
        record,
        social,
        targetKey,
        relationship,
        true,
        worldAgeHours,
        {
            kind = "memory_added",
            memoryID = memory.id,
            memoryType = memory.type,
            knowledgeSource = memory.knowledgeSource,
        }
    )
    return true, "added", Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    )
end

function Relationships.RemoveMemory(observerNPCID, targetKey, memoryID)
    local record
    local reason
    local social
    local relationship
    local index
    local removedMemory
    local worldAgeHours
    if not isAuthority() then
        return false, "not_authority"
    end
    if type(memoryID) ~= "string" or memoryID == "" then
        return false, "invalid_memory_id"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return false, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return false, reason
    end
    relationship = getRelationship(record, targetKey)
    if not relationship then
        return false, "relationship_not_found"
    end
    social = Types.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    relationship = Types.NormalizeRelationship(relationship, targetKey)
    index = findMemory(relationship, memoryID)
    if not index then
        return false, "memory_not_found"
    end
    removedMemory = relationship.memories[index]
    table.remove(relationship.memories, index)
    worldAgeHours = relationship.lastEvaluatedAt
    relationship = Math.RecalculateRelationship(
        relationship,
        targetKey,
        worldAgeHours
    )
    commit(
        record,
        social,
        targetKey,
        relationship,
        true,
        worldAgeHours,
        {
            kind = "memory_removed",
            memoryID = memoryID,
            memoryType = removedMemory
                and removedMemory.type or nil,
            knowledgeSource = removedMemory
                and removedMemory.knowledgeSource or nil,
            removedCount = 1,
        }
    )
    return true, "removed"
end
