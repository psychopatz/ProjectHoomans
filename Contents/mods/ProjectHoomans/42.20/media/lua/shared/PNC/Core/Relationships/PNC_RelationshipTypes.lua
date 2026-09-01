-- Defensive constructors and canonical normalizers for social persistence.

PNC = PNC or {}
PNC.RelationshipTypes = PNC.RelationshipTypes or {}

local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants
local EntityRef = PNC.EntityRef
local ProfileTypes = PNC.SocialProfileTypes
local ConductTypes = PNC.ConductTypes

local function finiteNumber(value)
    local numeric = tonumber(value)
    if numeric == nil
        or numeric ~= numeric
        or numeric == math.huge
        or numeric == -math.huge
    then
        return nil
    end
    return numeric
end

local function clamp(value, minimum, maximum, fallback)
    local numeric = finiteNumber(value)
    if numeric == nil then
        numeric = fallback
    end
    if numeric < minimum then
        return minimum
    end
    if numeric > maximum then
        return maximum
    end
    return numeric
end

local function nonNegative(value, fallback)
    local numeric = finiteNumber(value)
    if numeric == nil then
        numeric = fallback or 0
    end
    return math.max(0, numeric)
end

local function revision(value)
    return math.max(0, math.floor(finiteNumber(value) or 0))
end

local function normalizeRequiredString(value)
    if type(value) ~= "string" or value == "" or string.find(value, "%c") then
        return nil
    end
    return value
end

local function normalizeTags(value)
    local output = {}
    local key
    local enabled
    if type(value) ~= "table" then
        return output
    end
    for key, enabled in pairs(value) do
        if enabled == true and type(key) == "string" and key ~= ""
            and not string.find(key, "%c")
        then
            output[key] = true
        end
    end
    return output
end

local function normalizeNumericMap(value)
    local output = {}
    local key
    local numeric
    if type(value) ~= "table" then
        return output
    end
    for key, numeric in pairs(value) do
        if type(key) == "string" and key ~= "" then
            numeric = finiteNumber(numeric)
            if numeric ~= nil then
                output[key] = numeric
            end
        end
    end
    return output
end

local function normalizeSaturationMap(value)
    local output = {}
    local key
    local entry
    local approval
    local respect
    if type(value) ~= "table" then
        return output
    end
    for key, entry in pairs(value) do
        if type(key) == "string" and key ~= "" then
            if type(entry) == "table" then
                approval = finiteNumber(entry.approval)
                respect = finiteNumber(entry.respect)
                if approval ~= nil or respect ~= nil then
                    output[key] = {
                        approval = approval or 0,
                        respect = respect or 0,
                    }
                end
            else
                -- Preserve the Phase 1 numeric placeholder representation.
                -- Phase 2 writes structured entries but old/future data must
                -- continue to normalize without being destroyed.
                entry = finiteNumber(entry)
                if entry ~= nil then
                    output[key] = entry
                end
            end
        end
    end
    return output
end

local function normalizeStringList(value, maximum)
    local seen = {}
    local output = {}
    local extras = {}
    local index
    local key
    local item
    if type(value) ~= "table" then
        return output
    end
    -- Numeric insertion order is meaningful for the bounded recent-event
    -- cache. Malformed map entries are repaired deterministically afterward.
    for index = 1, #value do
        item = normalizeRequiredString(value[index])
        if item and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
    end
    for key, item in pairs(value) do
        if type(key) ~= "number"
            or key < 1
            or key > #value
            or key ~= math.floor(key)
        then
            item = normalizeRequiredString(item)
            if item and not seen[item] then
                extras[#extras + 1] = item
            end
        end
    end
    table.sort(extras)
    for index = 1, #extras do
        item = extras[index]
        item = normalizeRequiredString(item)
        if item and not seen[item] then
            seen[item] = true
            output[#output + 1] = item
        end
    end
    while #output > maximum do
        table.remove(output, 1)
    end
    return output
end

local function boundedString(value, maximum)
    value = normalizeRequiredString(value)
    if not value then return nil end
    return string.sub(value, 1, maximum or 256)
end

local function normalizeRelationshipSnapshot(value)
    local source = type(value) == "table" and value or {}
    local state = tostring(source.state or Constants.STATE_UNKNOWN)
    if not Constants.VALID_STATES[state] then
        state = Constants.STATE_UNKNOWN
    end
    return {
        approval = clamp(source.approval,
            Constants.APPROVAL_MIN, Constants.APPROVAL_MAX, 0),
        respect = clamp(source.respect,
            Constants.RESPECT_MIN, Constants.RESPECT_MAX, 0),
        familiarity = clamp(source.familiarity,
            Constants.FAMILIARITY_MIN, Constants.FAMILIARITY_MAX, 0),
        state = state,
        revision = revision(source.revision),
    }
end

local function normalizeInteraction(value)
    local source = type(value) == "table" and value or {}
    local eventID = boundedString(source.eventID or source.id, 256)
    local output
    local delta
    local itemTypes
    local index
    local item
    if not eventID then return nil end
    output = {
        eventID = eventID,
        sequence = revision(source.sequence),
        kind = boundedString(source.kind, 64) or "social_event",
        source = boundedString(source.source, 64),
        interactionType = boundedString(source.interactionType, 96),
        memoryID = boundedString(source.memoryID, 256),
        memoryType = boundedString(source.memoryType, 96),
        at = nonNegative(source.at or source.worldAgeHours, 0),
        worldAgeHours = nonNegative(source.worldAgeHours or source.at, 0),
        blockID = boundedString(source.blockID, 128),
        categoryID = boundedString(source.categoryID, 128),
        nodeID = boundedString(source.nodeID, 128),
        choiceID = boundedString(source.choiceID, 128),
        outcomeID = boundedString(source.outcomeID, 128),
        responseKey = boundedString(source.responseKey, 256),
        playerTextKey = boundedString(source.playerTextKey, 256),
        npcTextKey = boundedString(source.npcTextKey, 256),
        playerText = boundedString(source.playerText, 512),
        npcText = boundedString(source.npcText, 512),
        playerFlavorID = boundedString(source.playerFlavorID, 256),
        npcFlavorID = boundedString(source.npcFlavorID
            or source.replyFlavorID or source.flavorID, 256),
        emote = boundedString(source.emote, 64),
        reaction = boundedString(source.reaction, 64),
        intensity = boundedString(source.intensity, 32),
        subtype = boundedString(source.subtype, 64),
        itemSummary = boundedString(source.itemSummary, 256),
        npcType = boundedString(source.npcType, 32),
        relationshipTier = boundedString(source.relationshipTier, 32),
        greetingState = boundedString(source.greetingState, 32),
        greetingDay = source.greetingDay ~= nil
            and math.max(0, math.floor(nonNegative(source.greetingDay, 0)))
            or nil,
        applied = source.applied == true,
    }
    delta = type(source.delta) == "table" and source.delta or nil
    if delta then
        output.delta = {
            approval = clamp(delta.approval,
                Constants.APPROVAL_MIN, Constants.APPROVAL_MAX, 0),
            respect = clamp(delta.respect,
                Constants.RESPECT_MIN, Constants.RESPECT_MAX, 0),
            familiarity = clamp(delta.familiarity,
                Constants.FAMILIARITY_MIN, Constants.FAMILIARITY_MAX, 0),
        }
    end
    if type(source.before) == "table" then
        output.before = normalizeRelationshipSnapshot(source.before)
    end
    if type(source.after) == "table" then
        output.after = normalizeRelationshipSnapshot(source.after)
    end
    itemTypes = type(source.itemTypes) == "table" and source.itemTypes or nil
    if itemTypes then
        output.itemTypes = {}
        for index = 1, #itemTypes do
            item = boundedString(itemTypes[index], 128)
            if item then output.itemTypes[#output.itemTypes + 1] = item end
        end
    end
    return output
end

local function normalizeInteractionJournal(value)
    local output = {}
    local seen = {}
    local source = type(value) == "table" and value or {}
    local index
    local entry
    local normalized
    for index = 1, #source do
        entry = source[index]
        normalized = normalizeInteraction(entry)
        if normalized and not seen[normalized.eventID] then
            seen[normalized.eventID] = true
            output[#output + 1] = normalized
        end
    end
    while #output > Constants.INTERACTION_JOURNAL_LIMIT do
        table.remove(output, 1)
    end
    return output
end

local function memorySignature(memory)
    local tagNames = {}
    local encodedTags = {}
    local tag
    local function encode(value)
        value = tostring(value or "")
        return tostring(#value) .. ":" .. value
    end
    for tag, _ in pairs(memory.tags) do
        tagNames[#tagNames + 1] = tag
    end
    table.sort(tagNames)
    for index = 1, #tagNames do
        encodedTags[index] = encode(tagNames[index])
    end
    return table.concat({
        encode(memory.id),
        encode(memory.type),
        encode(memory.aboutKey),
        encode(memory.createdAt),
        encode(memory.lastEvaluatedAt),
        encode(memory.approvalEffect),
        encode(memory.respectEffect),
        encode(memory.moraleEffect),
        encode(memory.strength),
        encode(memory.decayPerDay),
        encode(memory.permanent),
        encode(memory.shareable),
        encode(memory.knowledgeSource),
        encode(memory.sourceKey),
        encode(table.concat(encodedTags, "")),
    }, "")
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
    id = normalizeRequiredString(source.id)
    memoryType = normalizeRequiredString(source.type)
    aboutKey = EntityRef.IsValid(source.aboutKey) and source.aboutKey or nil
    knowledgeSource = tostring(source.knowledgeSource or
        Constants.KNOWLEDGE_EXPERIENCED)
    if not Constants.VALID_KNOWLEDGE_SOURCES[knowledgeSource] then
        knowledgeSource = Constants.KNOWLEDGE_EXPERIENCED
    end
    sourceKey = EntityRef.IsValid(source.sourceKey) and source.sourceKey or nil
    if not id or not memoryType or not aboutKey then
        return nil
    end
    return {
        id = id,
        type = memoryType,
        aboutKey = aboutKey,
        createdAt = nonNegative(source.createdAt, 0),
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
end

function Types.NewMemory(spec)
    return Types.NormalizeMemory(spec)
end

function Types.NewRelationship(targetKey)
    local parsed = EntityRef.Parse(targetKey)
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
    }
end

function Types.NormalizeRelationship(value, targetKey)
    local parsed = EntityRef.Parse(targetKey)
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
        revision = revision(source.revision),
    }
end

function Types.NewSocialState(value, identitySeed, archetypeID)
    return Types.NormalizeSocialState(value, identitySeed, archetypeID)
end

function Types.NormalizeSocialState(value, identitySeed, archetypeID)
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
            personalityOverrides
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
    }
end

Types.NormalizeRelationshipSnapshot = normalizeRelationshipSnapshot
Types.NormalizeInteraction = normalizeInteraction
Types.NormalizeInteractionJournal = normalizeInteractionJournal

return Types
