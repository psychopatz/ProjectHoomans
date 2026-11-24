-- Relationship and social-state public constructors.

PNC = PNC or {}
PNC.RelationshipTypes = PNC.RelationshipTypes or {}
local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants
local EntityRef = PNC.EntityRef
local ProfileTypes = PNC.SocialProfileTypes
local ConductTypes = PNC.ConductTypes
local Internal = Types.Internal or {}
Types.Internal = Internal
local normalizeRequiredString = Internal.NormalizeRequiredString
local normalizeTags = Internal.NormalizeTags
local normalizeNumericMap = Internal.NormalizeNumericMap
local normalizeSaturationMap = Internal.NormalizeSaturationMap
local normalizeStringList = Internal.NormalizeStringList
local nonNegative = Internal.NonNegative
local clamp = Internal.Clamp
local revision = Internal.Revision
local memorySignature = Internal.MemorySignature
local normalizeRelationshipSnapshot = Internal.NormalizeRelationshipSnapshot
local normalizeInteraction = Internal.NormalizeInteraction
local normalizeInteractionJournal = Internal.NormalizeInteractionJournal
local boundedString = Internal.BoundedString

local function copyExtensions(val)
    if type(val) ~= "table" then return {} end
    local res = {}
    for k, v in pairs(val) do
        if type(v) == "table" then
            local sub = {}
            for sk, sv in pairs(v) do sub[sk] = sv end
            res[k] = sub
        else
            res[k] = v
        end
    end
    return res
end

local function normalizeBond(value)
    local source = type(value) == "table" and value or {}
    local class = tostring(source.class or "none")
    local kind = type(source.kind) == "string" and source.kind or nil
    if not Constants.VALID_BOND_CLASSES[class] then
        class = "none"
    end
    if class == "family" then
        if not kind or not Constants.VALID_FAMILY_BOND_KINDS[kind] then
            class = "none"
            kind = nil
        end
    else
        kind = nil
    end
    return {
        schemaVersion = Constants.DURABLE_BOND_SCHEMA_VERSION,
        class = class,
        kind = kind,
        establishedAt = nonNegative(source.establishedAt, 0),
        source = boundedString(source.source, 96),
    }
end

local function normalizeMemories(value)
    local byID = {}
    local output = {}
    local _
    local memory
    local existing
    if type(value) ~= "table" then
        return output
    end
    for _, memory in pairs(value) do
        memory = Types.NormalizeMemory(memory)
        if memory then
            existing = byID[memory.id]
            if not existing
                or memorySignature(memory) < memorySignature(existing)
            then
                byID[memory.id] = memory
            end
        end
    end
    for _, memory in pairs(byID) do
        output[#output + 1] = memory
    end
    table.sort(output, function(left, right)
        if left.createdAt ~= right.createdAt then
            return left.createdAt < right.createdAt
        end
        return left.id < right.id
    end)
    return output
end

function Types.AreEqual(left, right, seen)
    local leftType = type(left)
    local key
    if leftType ~= type(right) then
        return false
    end
    if leftType ~= "table" then
        return left == right
    end
    if left == right then
        return true
    end
    seen = seen or {}
    seen[left] = seen[left] or {}
    if seen[left][right] then
        return true
    end
    seen[left][right] = true
    for key, _ in pairs(left) do
        if not Types.AreEqual(left[key], right[key], seen) then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then
            return false
        end
    end
    return true
end

function Types.NormalizeMemory(value)
    local source = type(value) == "table" and value or nil
    local id
    local memoryType
    local aboutKey
    local knowledgeSource
    local sourceKey
    if not source then
        return nil
    end
    id = normalizeRequiredString(source.id or source.eventID)
    memoryType = normalizeRequiredString(source.type)
    local validAbout = EntityRef.IsCoreTargetValid
        and EntityRef.IsCoreTargetValid(source.aboutKey)
        or EntityRef.IsValid(source.aboutKey)
    aboutKey = validAbout and source.aboutKey or nil
    knowledgeSource = tostring(source.knowledgeSource or
        Constants.KNOWLEDGE_EXPERIENCED)
    if not Constants.VALID_KNOWLEDGE_SOURCES[knowledgeSource] then
        knowledgeSource = Constants.KNOWLEDGE_EXPERIENCED
    end
    local validSource = EntityRef.IsCoreTargetValid
        and EntityRef.IsCoreTargetValid(source.sourceKey)
        or EntityRef.IsValid(source.sourceKey)
    sourceKey = validSource and source.sourceKey or nil
    if not id or not memoryType or not aboutKey then
        return nil
    end
    local normalized = {
        id = id,
        type = memoryType,
        aboutKey = aboutKey,
        createdAt = nonNegative(source.createdAt, 0),
        eventSequence = source.eventSequence ~= nil
            and math.max(1, math.min(2147483646, revision(source.eventSequence))) or nil,
        lastEvaluatedAt = nonNegative(
            source.lastEvaluatedAt,
            nonNegative(source.createdAt, 0)
        ),
        approvalEffect = clamp(
            source.approvalEffect,
            Constants.MEMORY_EFFECT_MIN,
            Constants.MEMORY_EFFECT_MAX,
            0
        ),
        respectEffect = clamp(
            source.respectEffect,
            Constants.MEMORY_EFFECT_MIN,
            Constants.MEMORY_EFFECT_MAX,
            0
        ),
        moraleEffect = clamp(
            source.moraleEffect,
            Constants.MEMORY_EFFECT_MIN,
            Constants.MEMORY_EFFECT_MAX,
            0
        ),
        strength = clamp(
            source.strength,
            Constants.MEMORY_STRENGTH_MIN,
            Constants.MEMORY_STRENGTH_MAX,
            1
        ),
        decayPerDay = clamp(
            source.decayPerDay,
            Constants.DECAY_PER_DAY_MIN,
            Constants.DECAY_PER_DAY_MAX,
            0
        ),
        permanent = source.permanent == true,
        shareable = source.shareable == true,
        knowledgeSource = knowledgeSource,
        sourceKey = sourceKey,
        tags = normalizeTags(source.tags),
    }
    if type(source.retentionClass) == "string" and source.retentionClass ~= "" then
        normalized.retentionClass = source.retentionClass
    end
    if tonumber(source.salience) ~= nil then
        normalized.salience = math.floor(clamp(source.salience, 0, 255, 100))
    end
    if type(source.consolidationKey) == "string" and source.consolidationKey ~= "" then
        normalized.consolidationKey = source.consolidationKey
    end
    if tonumber(source.count) ~= nil then
        normalized.count = math.max(1, math.floor(tonumber(source.count)))
    end
    if tonumber(source.firstCreatedAt) ~= nil then
        normalized.firstCreatedAt = nonNegative(source.firstCreatedAt, normalized.createdAt)
    end
    if type(source.lastEventID) == "string" and source.lastEventID ~= "" then
        normalized.lastEventID = source.lastEventID
    end
    if type(source.sourceMode) == "string" and source.sourceMode ~= "" then
        normalized.sourceMode = source.sourceMode
    end
    if tonumber(source.confidence) ~= nil then
        normalized.confidence = clamp(source.confidence, 0, 1, 1)
    end
    if tonumber(source.familiarityEffect) ~= nil then
        normalized.familiarityEffect = clamp(source.familiarityEffect, 0, 100, 0)
    end
    return normalized
end

function Types.NewMemory(spec)
    return Types.NormalizeMemory(spec)
end

local function parseTargetFlexible(targetKey)
    local parsed = EntityRef.Parse(targetKey)
    if parsed then return parsed end
    local social = PsychopatzCore and PsychopatzCore.Actors
        and PsychopatzCore.Actors.Social or nil
    if social and type(social.ParseTargetKey) == "function" then
        local coreParsed = social.ParseTargetKey(targetKey)
        if coreParsed then
            return {
                key = coreParsed.key,
                kind = coreParsed.kind,
                targetID = coreParsed.id,
            }
        end
    end
    return nil
end

function Types.NewRelationship(targetKey)
    local parsed = parseTargetFlexible(targetKey)
    if not parsed then
        return nil
    end
    return {
        targetKind = parsed.kind,
        targetID = parsed.targetID,
        baselineApproval = 0,
        baselineRespect = 0,
        approval = 0,
        respect = 0,
        familiarity = 0,
        state = Constants.STATE_UNKNOWN,
        previousState = Constants.STATE_UNKNOWN,
        memories = {},
        saturation = {},
        cooldowns = {},
        interactionJournal = {},
        interactionRevision = 0,
        lastInteractionAt = 0,
        lastEvaluatedAt = 0,
        revision = 0,
        bond = normalizeBond(nil),
    }
end

function Types.NormalizeRelationship(value, targetKey)
    local parsed = parseTargetFlexible(targetKey)
    local source = type(value) == "table" and value or {}
    local state
    local previousState
    if not parsed then
        return nil
    end
    state = tostring(source.state or "")
    if not Constants.VALID_STATES[state] then
        state = Constants.STATE_UNKNOWN
    end
    previousState = tostring(source.previousState or "")
    if not Constants.VALID_STATES[previousState] then
        previousState = Constants.STATE_UNKNOWN
    end
    return {
        targetKind = parsed.kind,
        targetID = parsed.targetID,
        baselineApproval = clamp(
            source.baselineApproval,
            Constants.APPROVAL_MIN,
            Constants.APPROVAL_MAX,
            0
        ),
        baselineRespect = clamp(
            source.baselineRespect,
            Constants.RESPECT_MIN,
            Constants.RESPECT_MAX,
            0
        ),
        approval = clamp(
            source.approval,
            Constants.APPROVAL_MIN,
            Constants.APPROVAL_MAX,
            0
        ),
        respect = clamp(
            source.respect,
            Constants.RESPECT_MIN,
            Constants.RESPECT_MAX,
            0
        ),
        familiarity = clamp(
            source.familiarity,
            Constants.FAMILIARITY_MIN,
            Constants.FAMILIARITY_MAX,
            0
        ),
        state = state,
        previousState = previousState,
        memories = normalizeMemories(source.memories),
        saturation = normalizeSaturationMap(source.saturation),
        cooldowns = normalizeNumericMap(source.cooldowns),
        interactionJournal = normalizeInteractionJournal(
            source.interactionJournal
        ),
        interactionRevision = revision(source.interactionRevision),
        lastInteractionAt = nonNegative(source.lastInteractionAt, 0),
        lastEvaluatedAt = nonNegative(source.lastEvaluatedAt, 0),
        knowsName = source.knowsName == true and true or nil,
        firstMetAt = tonumber(source.firstMetAt) ~= nil
            and nonNegative(source.firstMetAt, 0) or nil,
        revision = revision(source.revision),
        bond = normalizeBond(source.bond),
        extensions = copyExtensions(source.extensions),
    }
end

local function cloneFlatMap(src)
    local out = {}
    if type(src) ~= "table" then return out end
    for k, v in pairs(src) do out[k] = v end
    return out
end

function Types.CloneRelationshipForMutation(value, targetKey)
    if type(value) == "table"
        and value.targetKind ~= nil
        and type(value.memories) == "table"
        and type(value.interactionJournal) == "table"
        and type(value.saturation) == "table"
        and type(value.cooldowns) == "table"
        and type(value.bond) == "table"
        and Constants.VALID_STATES[tostring(value.state or "")]
    then
        local memories = {}
        local srcMemories = value.memories
        for i = 1, #srcMemories do
            local m = srcMemories[i]
            if type(m) == "table" then
                local mc = {}
                for k, v in pairs(m) do mc[k] = v end
                if type(m.tags) == "table" then
                    mc.tags = cloneFlatMap(m.tags)
                end
                memories[#memories + 1] = mc
            end
        end
        local satCopy = {}
        for k, v in pairs(value.saturation) do
            if type(v) == "table" then
                satCopy[k] = cloneFlatMap(v)
            end
        end
        local journalCopy = {}
        local srcJournal = value.interactionJournal
        for i = 1, #srcJournal do
            journalCopy[i] = srcJournal[i]
        end
        local prevState = tostring(value.previousState or "")
        if not Constants.VALID_STATES[prevState] then
            prevState = Constants.STATE_UNKNOWN
        end
        return {
            targetKind = value.targetKind,
            targetID = value.targetID,
            baselineApproval = tonumber(value.baselineApproval) or 0,
            baselineRespect = tonumber(value.baselineRespect) or 0,
            approval = tonumber(value.approval) or 0,
            respect = tonumber(value.respect) or 0,
            familiarity = tonumber(value.familiarity) or 0,
            state = value.state,
            previousState = prevState,
            memories = memories,
            saturation = satCopy,
            cooldowns = cloneFlatMap(value.cooldowns),
            interactionJournal = journalCopy,
            interactionRevision = tonumber(value.interactionRevision) or 0,
            lastInteractionAt = tonumber(value.lastInteractionAt) or 0,
            lastEvaluatedAt = tonumber(value.lastEvaluatedAt) or 0,
            revision = tonumber(value.revision) or 0,
            bond = cloneFlatMap(value.bond),
            extensions = copyExtensions(value.extensions),
        }
    end
    return Types.NormalizeRelationship(value, targetKey)
end

function Types.NewSocialState(value, identitySeed, archetypeID, traitSource)
    return Types.NormalizeSocialState(
        value, identitySeed, archetypeID, traitSource)
end

function Types.NormalizeSocialState(
    value,
    identitySeed,
    archetypeID,
    traitSource
)
    local source = type(value) == "table" and value or {}
    local relationships = {}
    local personalityOverrides = ProfileTypes
        and ProfileTypes.NormalizeNPCPersonalityOverrides(
            source.personalityOverrides
        ) or {}
    local personality = ProfileTypes
        and ProfileTypes.NormalizeNPCPersonality(
            source.personality,
            identitySeed,
            archetypeID,
            personalityOverrides,
            traitSource
        ) or nil
    local targetKey
    local relationship
    if type(source.relationships) == "table" then
        for targetKey, relationship in pairs(source.relationships) do
            if type(targetKey) == "string" then
                relationship =
                    Types.NormalizeRelationship(relationship, targetKey)
                if relationship then
                    relationships[targetKey] = relationship
                end
            end
        end
    end
    return {
        schemaVersion = Constants.SOCIAL_SCHEMA_VERSION,
        revision = revision(source.revision),
        morale = clamp(
            source.morale,
            Constants.MORALE_MIN,
            Constants.MORALE_MAX,
            0
        ),
        moraleBaseline = clamp(
            source.moraleBaseline,
            Constants.MORALE_MIN,
            Constants.MORALE_MAX,
            0
        ),
        relationships = relationships,
        recentEventIDs = normalizeStringList(
            source.recentEventIDs,
            Constants.RECENT_EVENT_ID_LIMIT
        ),
        lastEvaluatedAt = nonNegative(source.lastEvaluatedAt, 0),
        personality = personality,
        personalityOverrides = personalityOverrides,
        conduct = ConductTypes
            and ConductTypes.NormalizeConductRecord(source.conduct)
            or nil,
        extensions = copyExtensions(source.extensions),
    }
end

Types.NormalizeRelationshipSnapshot = normalizeRelationshipSnapshot
Types.NormalizeInteraction = normalizeInteraction
Types.NormalizeInteractionJournal = normalizeInteractionJournal
Types.NormalizeBond = normalizeBond


return Types
