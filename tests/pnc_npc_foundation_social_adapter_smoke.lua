local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Travel/PNC_Travel.lua")
local Core = require "PsychopatzCore/Actors/PsychopatzActors"
local CoreSocial = PsychopatzCore.Social
local Adapter = PNC.Persistence.CoreSocial

local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = deepCopy(item)
    end
    return copy
end

local function equalValue(left, right, seen)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    if left == right then return true end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then return true end
    seen[left][right] = true
    for key, value in pairs(left) do
        if not equalValue(value, right[key], seen) then return false end
    end
    for key in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function prepareSourceRecord(id)
    local record = PNC.Types.NewRecord({
        id = id,
        displayName = "Parity Merchant",
        identitySeed = 731,
        archetypeID = "parity_merchant",
        uniqueDefinitionVersion = 1,
        tacticalClass = "neutral",
        x = 104.5,
        y = 208.25,
        z = 0,
        anchorX = 100,
        anchorY = 200,
        anchorZ = 0,
        equipment = { worn = {}, attached = {} },
    })
    local targetKey = "npc:p0b_friend"
    local relationship = PNC.RelationshipTypes.NewRelationship(targetKey)
    relationship.memories = {
        PNC.RelationshipTypes.NewMemory({
            id = "memory:p0b:friend",
            type = "trade_helped",
            aboutKey = targetKey,
            createdAt = 14,
            lastEvaluatedAt = 14,
            approvalEffect = 11,
            respectEffect = 7,
            strength = 1,
            knowledgeSource = "experienced",
        }),
    }
    record.social.relationships[targetKey] = relationship
    record.social.revision = 3
    return record, targetKey
end

T.truthy(Adapter, "Core social adapter was not registered")
local sourceRecord, targetKey = prepareSourceRecord("npc:p4:social")
local originalSocial = deepCopy(sourceRecord.social)
local projected, projectReason = Adapter.Project(sourceRecord, PsychopatzCore)
T.truthy(projected, projectReason)
local projMemories = CoreSocial.GetMemoriesForTarget(projected, targetKey)
T.equal(projMemories[1].id,
    "memory:p0b:friend", "relationship memory projected")
T.equal(projected.relationships[targetKey].memories, nil,
    "actor-level memoryBank omits embedded relationship.memories")
T.equal(projected.relationships[targetKey].targetKey, targetKey,
    "relationship direction projected")
T.equal(projected.revision, sourceRecord.social.revision,
    "social revision projected")
T.truthy(projected.personality, "personality projected")
T.truthy(equalValue(sourceRecord.social, originalSocial),
    "projection changed Hoomans source social state")

local event = {
    targetKey = targetKey,
    eventID = "event:p4:authorized",
    type = "conversation_completed",
    approvalDelta = 6,
    respectDelta = 2,
    familiarityDelta = 5,
    createdAt = 88,
    authority = "server",
    authorized = true,
}
local approvalBeforeEvent = projected.relationships[targetKey].approval
local applied, eventReason = Adapter.RecordAuthorizedEvent(projected,
    PsychopatzCore, event)
T.truthy(applied, eventReason)
T.equal(applied.relationships[targetKey].approval,
    approvalBeforeEvent + 6,
    "authorized approval delta")
local appliedMemories = CoreSocial.GetMemoriesForTarget(applied, targetKey)
T.equal(appliedMemories[#appliedMemories].id, event.eventID, "authorized event memory")

local duplicate, duplicateReason = Adapter.RecordAuthorizedEvent(applied,
    PsychopatzCore, event)
T.equal(duplicate, nil, "duplicate social event accepted")
T.equal(duplicateReason, "duplicate_event", "duplicate social event reason")

local unauthorized, unauthorizedReason = Adapter.RecordAuthorizedEvent(
    projected, PsychopatzCore, {
        targetKey = targetKey,
        eventID = "event:p4:client",
        authority = "client",
        authorized = false,
    })
T.equal(unauthorized, nil, "unauthorized social event accepted")
T.equal(unauthorizedReason, "server_authority_required",
    "unauthorized social event reason")

local missing, missingReason = Adapter.Project({}, PsychopatzCore)
T.equal(missing, nil, "missing social source accepted")
T.equal(missingReason, "source_social_missing", "missing social reason")

T.finish("pnc_npc_foundation_social_adapter_smoke")
