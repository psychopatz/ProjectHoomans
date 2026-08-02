-- Server-authoritative mutation API for directed personal relationships.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}

local Relationships = PNC.Relationships
local Core = PNC.Core
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef
local Types = PNC.RelationshipTypes
local Math = PNC.RelationshipMath
local Constants = PNC.RelationshipConstants
local DEBUG_CHANGE_LIMIT = 16

local function isAuthority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function resolveObserver(observerNPCID)
    local observerType = type(observerNPCID)
    local record
    if observerType ~= "string" and observerType ~= "number" then
        return nil, "invalid_observer_id"
    end
    observerNPCID = tostring(observerNPCID)
    if observerNPCID == "" or not Registry or not Registry.Get then
        return nil, "invalid_observer_id"
    end
    record = Registry.Get(observerNPCID)
    if type(record) ~= "table"
        or tostring(record.id or "") ~= observerNPCID
        or record.alive == false
    then
        return nil, "observer_not_found"
    end
    return record
end

local function validateTarget(targetKey)
    if type(targetKey) ~= "string" or not EntityRef.IsValid(targetKey) then
        return nil, "invalid_target_key"
    end
    return targetKey
end

local function getRelationship(record, targetKey)
    local social = type(record.social) == "table" and record.social or nil
    local relationships = social
        and type(social.relationships) == "table"
        and social.relationships or nil
    return relationships and relationships[targetKey] or nil
end

local function buildMemorySpec(memorySpec, targetKey)
    if type(memorySpec) ~= "table" then
        return nil
    end
    return {
        id = memorySpec.id,
        type = memorySpec.type,
        aboutKey = memorySpec.aboutKey or targetKey,
        createdAt = memorySpec.createdAt,
        lastEvaluatedAt = memorySpec.lastEvaluatedAt,
        approvalEffect = memorySpec.approvalEffect,
        respectEffect = memorySpec.respectEffect,
        moraleEffect = memorySpec.moraleEffect,
        strength = memorySpec.strength,
        decayPerDay = memorySpec.decayPerDay,
        permanent = memorySpec.permanent,
        shareable = memorySpec.shareable,
        knowledgeSource = memorySpec.knowledgeSource,
        sourceKey = memorySpec.sourceKey,
        tags = memorySpec.tags,
    }
end

local function prepareSocial(record)
    local normalized = Types.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    return normalized, not Types.AreEqual(record.social, normalized)
end

local function appendDebugChange(
    record,
    targetKey,
    before,
    after,
    moraleBefore,
    moraleAfter,
    worldAgeHours,
    changeSpec
)
    changeSpec = type(changeSpec) == "table"
        and changeSpec or {}
    before = type(before) == "table" and before or {}
    after = type(after) == "table" and after or {}
    local approvalBefore = tonumber(before.approval) or 0
    local approvalAfter = tonumber(after.approval) or 0
    local respectBefore = tonumber(before.respect) or 0
    local respectAfter = tonumber(after.respect) or 0
    local familiarityBefore =
        tonumber(before.familiarity) or 0
    local familiarityAfter =
        tonumber(after.familiarity) or 0
    moraleBefore = tonumber(moraleBefore) or 0
    moraleAfter = tonumber(moraleAfter) or 0
    local stateBefore = tostring(before.state or "unknown")
    local stateAfter = tostring(after.state or "unknown")
    local hasChange = approvalBefore ~= approvalAfter
        or respectBefore ~= respectAfter
        or familiarityBefore ~= familiarityAfter
        or moraleBefore ~= moraleAfter
        or stateBefore ~= stateAfter
        or changeSpec.memoryID ~= nil
        or changeSpec.eventID ~= nil
        or (tonumber(changeSpec.removedCount) or 0) > 0
        or changeSpec.kind == "relationship_created"
    if not hasChange then return end
    record.runtime = record.runtime or {}
    local sequence = math.max(
        0,
        math.floor(tonumber(
            record.runtime.relationshipDebugSequence
        ) or 0)
    ) + 1
    record.runtime.relationshipDebugSequence = sequence
    local changes =
        record.runtime.relationshipDebugChanges or {}
    record.runtime.relationshipDebugChanges = changes
    changes[#changes + 1] = {
        sequence = sequence,
        targetKey = targetKey,
        kind = tostring(
            changeSpec.kind or "relationship_changed"
        ),
        eventID = changeSpec.eventID,
        memoryID = changeSpec.memoryID,
        memoryType = changeSpec.memoryType,
        knowledgeSource = changeSpec.knowledgeSource,
        removedCount =
            tonumber(changeSpec.removedCount) or 0,
        worldAgeHours = math.max(
            0,
            tonumber(worldAgeHours) or 0
        ),
        runtimeAt = Core and Core.Now
            and Core.Now() or 0,
        approvalBefore = approvalBefore,
        approvalAfter = approvalAfter,
        approvalDelta = approvalAfter - approvalBefore,
        respectBefore = respectBefore,
        respectAfter = respectAfter,
        respectDelta = respectAfter - respectBefore,
        familiarityBefore = familiarityBefore,
        familiarityAfter = familiarityAfter,
        familiarityDelta =
            familiarityAfter - familiarityBefore,
        moraleBefore = moraleBefore,
        moraleAfter = moraleAfter,
        moraleDelta = moraleAfter - moraleBefore,
        stateBefore = stateBefore,
        stateAfter = stateAfter,
        relationshipRevision =
            tonumber(after.revision) or 0,
    }
    while #changes > DEBUG_CHANGE_LIMIT do
        table.remove(changes, 1)
    end
end

local function commit(record, social, targetKey, relationship,
    relationshipChanged, worldAgeHours, changeSpec)
    local existing = getRelationship(record, targetKey)
    local moraleBefore = record.social
        and record.social.morale or 0
    if relationshipChanged then
        relationship.revision = math.max(
            tonumber(existing and existing.revision) or 0,
            tonumber(relationship.revision) or 0
        ) + 1
    end
    social.relationships[targetKey] = relationship
    if worldAgeHours ~= nil then
        social.lastEvaluatedAt = math.max(
            0,
            tonumber(worldAgeHours) or social.lastEvaluatedAt or 0
        )
    end
    social.revision = math.max(
        tonumber(record.social and record.social.revision) or 0,
        tonumber(social.revision) or 0
    ) + 1
    appendDebugChange(
        record,
        targetKey,
        existing,
        relationship,
        moraleBefore,
        social.morale,
        worldAgeHours,
        changeSpec
    )
    record.social = social
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "social")
    end
    if PNC.Factions
        and PNC.Factions.OnRelationshipChanged
    then
        PNC.Factions.OnRelationshipChanged(
            record,
            targetKey,
            relationship
        )
    end
end

local function findMemory(relationship, memoryID)
    local index
    local memory
    for index, memory in pairs(relationship.memories or {}) do
        if tostring(memory.id or "") == memoryID then
            return index, memory
        end
    end
    return nil
end

local function hasRecentEvent(social, eventID)
    local index
    for index = 1, #(social.recentEventIDs or {}) do
        if social.recentEventIDs[index] == eventID then
            return true
        end
    end
    return false
end

local function appendRecentEvent(social, eventID)
    social.recentEventIDs[#social.recentEventIDs + 1] = eventID
    while #social.recentEventIDs > Constants.RECENT_EVENT_ID_LIMIT do
        table.remove(social.recentEventIDs, 1)
    end
end

local function finiteNumber(value)
    value = tonumber(value)
    if value == nil
        or value ~= value
        or value == math.huge
        or value == -math.huge
    then
        return nil
    end
    return value
end

function Relationships.Get(observerNPCID, targetKey)
    local record
    local reason
    local relationship
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return nil, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return nil, reason
    end
    relationship = getRelationship(record, targetKey)
    if not relationship then
        return nil, "relationship_not_found"
    end
    -- Return a canonical copy so a read API cannot mutate authoritative data.
    return Types.NormalizeRelationship(relationship, targetKey)
end

function Relationships.GetOrCreate(observerNPCID, targetKey)
    local record
    local reason
    local social
    local socialChanged
    local relationship
    local rawRelationship
    local relationshipChanged
    if not isAuthority() then
        return nil, "not_authority"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return nil, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return nil, reason
    end
    social, socialChanged = prepareSocial(record)
    rawRelationship = getRelationship(record, targetKey)
    relationship = rawRelationship
        and Types.NormalizeRelationship(rawRelationship, targetKey)
        or Types.NewRelationship(targetKey)
    relationshipChanged = rawRelationship == nil
        or not Types.AreEqual(rawRelationship, relationship)
    if socialChanged or relationshipChanged then
        commit(
            record,
            social,
            targetKey,
            relationship,
            relationshipChanged,
            nil,
            {
                kind = rawRelationship == nil
                    and "relationship_created"
                    or "relationship_normalized",
            }
        )
    end
    return Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    ), rawRelationship == nil and "created" or "existing"
end

-- Debug-only synthetic baseline support. The server command that calls this
-- is admin gated. Memories, cooldowns, saturation, and familiarity are left
-- intact so the normal recalculation remains explainable and reproducible.
function Relationships.SetDebugBaseline(
    observerNPCID,
    targetKey,
    standing,
    worldAgeHours
)
    local record
    local reason
    local social
    local socialChanged
    local rawRelationship
    local relationship
    if not isAuthority() then return nil, "not_authority" end
    if type(standing) ~= "table" then return nil, "invalid_standing" end
    worldAgeHours = finiteNumber(worldAgeHours)
    if worldAgeHours == nil or worldAgeHours < 0 then
        return nil, "invalid_world_age_hours"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then return nil, reason end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then return nil, reason end
    social, socialChanged = prepareSocial(record)
    rawRelationship = getRelationship(record, targetKey)
    relationship = rawRelationship
        and Types.NormalizeRelationship(rawRelationship, targetKey)
        or Types.NewRelationship(targetKey)
    relationship.baselineApproval = Math.Clamp(
        standing.approval,
        Constants.APPROVAL_MIN,
        Constants.APPROVAL_MAX
    )
    relationship.baselineRespect = Math.Clamp(
        standing.respect,
        Constants.RESPECT_MIN,
        Constants.RESPECT_MAX
    )
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
        socialChanged or not Types.AreEqual(rawRelationship, relationship),
        worldAgeHours,
        { kind = "debug_baseline_set" }
    )
    return Types.NormalizeRelationship(
        record.social.relationships[targetKey],
        targetKey
    )
end

local function getNumeric(observerNPCID, targetKey, field)
    local relationship
    local reason
    relationship, reason = Relationships.Get(observerNPCID, targetKey)
    if not relationship then
        return nil, reason
    end
    return relationship[field]
end

function Relationships.GetApproval(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "approval")
end

function Relationships.GetRespect(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "respect")
end

function Relationships.GetFamiliarity(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "familiarity")
end

function Relationships.GetState(observerNPCID, targetKey)
    return getNumeric(observerNPCID, targetKey, "state")
end

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

-- Atomic Phase 2 mutation boundary. Social-event processing owns definition
-- lookup and attribution; this API owns all persistent relationship changes.
function Relationships.ApplyEventMutation(
    observerNPCID,
    targetKey,
    mutation
)
    local record
    local reason
    local social
    local relationship
    local memory
    local eventID
    local worldAgeHours
    local familiarityDelta
    local moraleDelta
    local saturationType
    local saturation
    local cooldownType
    local cooldownUntil
    local withinLimit
    if not isAuthority() then
        return false, "not_authority"
    end
    if type(mutation) ~= "table" then
        return false, "invalid_event_mutation"
    end
    eventID = type(mutation.eventID) == "string"
        and mutation.eventID or nil
    worldAgeHours = finiteNumber(mutation.worldAgeHours)
    familiarityDelta = finiteNumber(mutation.familiarityDelta) or 0
    moraleDelta = finiteNumber(mutation.moraleDelta) or 0
    if not eventID or eventID == "" or not worldAgeHours
        or worldAgeHours < 0
    then
        return false, "invalid_event_mutation"
    end
    record, reason = resolveObserver(observerNPCID)
    if not record then
        return false, reason
    end
    targetKey, reason = validateTarget(targetKey)
    if not targetKey then
        return false, reason
    end
    memory = Types.NewMemory(buildMemorySpec(mutation.memory, targetKey))
    if not memory or memory.aboutKey ~= targetKey then
        return false, "invalid_memory"
    end
    social = Types.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    if hasRecentEvent(social, eventID) then
        return false, "duplicate_event"
    end
    relationship = getRelationship(record, targetKey)
    relationship = relationship
        and Types.NormalizeRelationship(relationship, targetKey)
        or Types.NewRelationship(targetKey)
    if findMemory(relationship, memory.id) then
        return false, "duplicate_memory_id"
    end
    cooldownType = type(mutation.cooldownType) == "string"
        and mutation.cooldownType or nil
    cooldownUntil = finiteNumber(mutation.cooldownUntil)
    if cooldownType and cooldownUntil then
        relationship.cooldowns[cooldownType] =
            math.max(0, cooldownUntil)
    end
    saturationType = type(mutation.saturationType) == "string"
        and mutation.saturationType or nil
    saturation = type(mutation.saturation) == "table"
        and mutation.saturation or nil
    if saturationType and saturation then
        relationship.saturation[saturationType] = {
            approval = finiteNumber(saturation.approval) or 0,
            respect = finiteNumber(saturation.respect) or 0,
        }
    end
    relationship.memories[#relationship.memories + 1] = memory
    relationship.familiarity = math.max(
        Constants.FAMILIARITY_MIN,
        math.min(
            Constants.FAMILIARITY_MAX,
            (tonumber(relationship.familiarity) or 0)
                + familiarityDelta
        )
    )
    relationship.lastInteractionAt = math.max(
        tonumber(relationship.lastInteractionAt) or 0,
        worldAgeHours
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
    if not findMemory(relationship, memory.id) then
        return false, "memory_pruned_by_limit"
    end
    relationship = Math.RecalculateRelationship(
        relationship,
        targetKey,
        worldAgeHours
    )
    social.morale = math.max(
        Constants.MORALE_MIN,
        math.min(
            Constants.MORALE_MAX,
            (tonumber(social.morale) or 0) + moraleDelta
        )
    )
    appendRecentEvent(social, eventID)
    commit(
        record,
        social,
        targetKey,
        relationship,
        true,
        worldAgeHours,
        {
            kind = "social_event",
            eventID = eventID,
            memoryID = memory.id,
            memoryType = memory.type,
            knowledgeSource = memory.knowledgeSource,
        }
    )
    return true, "applied", {
        relationship = Types.NormalizeRelationship(
            record.social.relationships[targetKey],
            targetKey
        ),
        morale = record.social.morale,
        memoryID = memory.id,
    }
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

return Relationships
