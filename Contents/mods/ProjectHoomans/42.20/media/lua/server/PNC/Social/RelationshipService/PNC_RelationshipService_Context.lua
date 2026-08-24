if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Core = PNC.Core
local Registry = PNC.Registry
local EntityRef = PNC.EntityRef
local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants

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

Internal.isAuthority = isAuthority
Internal.resolveObserver = resolveObserver
Internal.validateTarget = validateTarget
Internal.getRelationship = getRelationship
Internal.buildMemorySpec = buildMemorySpec
Internal.prepareSocial = prepareSocial
Internal.findMemory = findMemory
Internal.hasRecentEvent = hasRecentEvent
Internal.appendRecentEvent = appendRecentEvent
Internal.finiteNumber = finiteNumber
