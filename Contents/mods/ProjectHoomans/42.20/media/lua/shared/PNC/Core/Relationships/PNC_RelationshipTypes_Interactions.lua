-- Relationship interaction and journal normalizers.

PNC = PNC or {}
PNC.RelationshipTypes = PNC.RelationshipTypes or {}
local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants
local Internal = Types.Internal or {}
Types.Internal = Internal
local finiteNumber = Internal.FiniteNumber
local clamp = Internal.Clamp
local nonNegative = Internal.NonNegative
local revision = Internal.Revision
local boundedString = Internal.BoundedString

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


Internal.NormalizeRelationshipSnapshot = normalizeRelationshipSnapshot
Internal.NormalizeInteraction = normalizeInteraction
Internal.NormalizeInteractionJournal = normalizeInteractionJournal
Internal.MemorySignature = memorySignature

return Types
