-- Fixed topic codes are accumulated as a small per-player bitset for today.
-- No transcript text or topic strings are written to NPC ModData.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Data = Memory._registry
local Internal = Events.Internal
local MAX_TOPIC_BITS = 30
local MAX_TOPIC_MASK = 1073741823
local MAX_TOPIC_PLAYERS = 4
local MAX_ALIASES = 32
local MAX_ALIAS_LENGTH = 64
local MAX_MATCH_TEXT = 160

Data.conversationTopicByID = Data.conversationTopicByID or {}
Data.conversationTopicByBit = Data.conversationTopicByBit or {}
Data.conversationTopicByAlias = Data.conversationTopicByAlias or {}

Events.TOPIC_BIT_LIMIT = MAX_TOPIC_BITS
Events.TOPIC_MASK_LIMIT = MAX_TOPIC_MASK
Events.TOPIC_PLAYER_LIMIT = MAX_TOPIC_PLAYERS

local function normalizedWords(value)
    if type(value) ~= "string" and type(value) ~= "number" then
        return nil
    end
    value = string.lower(tostring(value))
    value = string.gsub(value, "%c", " ")
    value = string.gsub(value, "_", " ")
    value = string.gsub(value, "[^%w%s]", " ")
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    if #value > MAX_MATCH_TEXT then
        value = string.sub(value, 1, MAX_MATCH_TEXT)
        value = string.gsub(value, "%s+$", "")
    end
    return value
end
Internal.NormalizeConversationTopicText = normalizedWords

local function hasBit(mask, bit)
    return math.floor(mask / (2 ^ (bit - 1))) % 2 == 1
end

local function addBit(mask, bit)
    if not hasBit(mask, bit) then
        return mask + 2 ^ (bit - 1)
    end
    return mask
end
Internal.HasConversationTopicBit = hasBit
Internal.AddConversationTopicBit = addBit

local function positiveTopicMask(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric
        or numeric == math.huge or numeric == -math.huge
    then
        return 0
    end
    numeric = math.floor(numeric)
    if numeric < 0 or numeric > MAX_TOPIC_MASK then return 0 end
    return numeric
end

function Events.NormalizeConversationTopicMask(value)
    return positiveTopicMask(value)
end

function Events.FilterConversationTopicMask(value)
    local input = positiveTopicMask(value)
    local output = 0
    local bit
    for bit = 1, MAX_TOPIC_BITS do
        if hasBit(input, bit) and Data.conversationTopicByBit[bit] then
            output = addBit(output, bit)
        end
    end
    return output
end

function Events.MergeConversationTopicMasks(left, right)
    local output = positiveTopicMask(left)
    local incoming = positiveTopicMask(right)
    local bit
    for bit = 1, MAX_TOPIC_BITS do
        if hasBit(incoming, bit) then output = addBit(output, bit) end
    end
    return output
end

function Events.RegisterConversationTopic(definition)
    local id
    local bit
    local label
    local aliases
    local seen
    local old
    local alias
    local owner
    local index
    if type(definition) ~= "table" then
        return false, "topic_definition_required"
    end
    id = string.lower(tostring(definition.id or ""))
    if id == "" or #id > MAX_ALIAS_LENGTH
        or not string.match(id, "^[a-z][a-z0-9_]*$")
    then
        return false, "invalid_topic_id"
    end
    bit = Internal.PositiveInteger(definition.bit, MAX_TOPIC_BITS)
    if not bit then return false, "invalid_topic_bit" end
    label = tostring(definition.label or id)
    if #label > MAX_ALIAS_LENGTH then return false, "invalid_topic_label" end
    label = normalizedWords(label)
    if not label then return false, "invalid_topic_label" end
    old = Data.conversationTopicByID[id]
    if old then
        if old.bit == bit then return true, old end
        return false, "duplicate_topic_id"
    end
    owner = Data.conversationTopicByBit[bit]
    if owner and owner.id ~= id then return false, "duplicate_topic_bit" end

    aliases = {}
    seen = {}
    local function addAlias(value)
        if (type(value) ~= "string" and type(value) ~= "number")
            or #tostring(value) > MAX_ALIAS_LENGTH
        then
            return false
        end
        local normalized = normalizedWords(value)
        if not normalized then return true end
        owner = Data.conversationTopicByAlias[normalized]
        if owner and owner.id ~= id then return false end
        if not seen[normalized] then
            seen[normalized] = true
            aliases[#aliases + 1] = normalized
        end
        return true
    end
    if not addAlias(id) or not addAlias(label) then
        return false, "duplicate_topic_alias"
    end
    if type(definition.aliases) == "table" then
        for index = 1, math.min(#definition.aliases, MAX_ALIASES) do
            if not addAlias(definition.aliases[index]) then
                return false, "duplicate_topic_alias"
            end
        end
    end
    local entry = {
        id = id,
        bit = bit,
        mask = 2 ^ (bit - 1),
        label = label,
        aliases = aliases,
    }
    Data.conversationTopicByID[id] = entry
    Data.conversationTopicByBit[bit] = entry
    for index = 1, #aliases do
        Data.conversationTopicByAlias[aliases[index]] = entry
    end
    return true, entry
end

return Events
