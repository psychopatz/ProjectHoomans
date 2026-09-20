-- Compact player/day storage and prompt projection for topic masks.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Data = Memory._registry
local Internal = Events.Internal
local positiveInteger = Internal.PositiveInteger
local MAX_TOPIC_PLAYERS = Events.TOPIC_PLAYER_LIMIT
local MAX_TOPIC_BITS = Events.TOPIC_BIT_LIMIT

local function hasBit(mask, bit)
    return math.floor(mask / (2 ^ (bit - 1))) % 2 == 1
end

local function cleanPlayerUUID(value)
    value = tostring(value or "")
    value = string.gsub(value, "%c", "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    local lowered = string.lower(value)
    if value == "" or #value > 128 or lowered == "unbound"
        or lowered == "unbound-player" or lowered == "ambient-player"
        or string.find(value, ":", 1, true)
    then
        return nil
    end
    return value
end

function Events.ConversationPlayerSeed(record, playerUUID)
    local identity = PNC and PNC.Identity
    local seed = type(record) == "table" and tonumber(record.identitySeed)
        or type(record) == "table" and type(record.identity) == "table"
        and tonumber(record.identity.seed) or nil
    local uuid = cleanPlayerUUID(playerUUID)
    local output
    if not uuid or not identity then return nil end
    seed = Internal.PositiveInteger(seed, Events.MAX_SEED)
    if seed and type(identity.MixSeed) == "function" then
        local ok, mixed = pcall(
            identity.MixSeed,
            seed,
            "pnc:conversation-memory:player:" .. uuid
        )
        output = ok and Internal.PositiveInteger(mixed, Events.MAX_SEED)
            or nil
        if output then return output end
    end
    if type(identity.HashText) == "function" then
        local saltOK, salt = pcall(identity.HashText,
            "pnc:conversation-memory:player",
            5381
        )
        if not saltOK then return nil end
        local hashOK, hash = pcall(identity.HashText,
            tostring(record and record.id or "npc") .. ":" .. uuid,
            salt
        )
        if not hashOK then return nil end
        return Internal.PositiveInteger(
            hash,
            Events.MAX_SEED
        )
    end
    return nil
end

local function upsertTopicPlayer(values, seed, mask)
    local count = math.floor(#values / 2)
    local index
    local offset
    local oldMask
    local mergedMask
    for index = 1, count do
        offset = (index - 1) * 2 + 1
        if values[offset] == seed then
            oldMask = Events.NormalizeConversationTopicMask(values[offset + 1])
            mergedMask = Events.MergeConversationTopicMasks(oldMask, mask)
            if oldMask == mergedMask then return false end
            table.remove(values, offset)
            table.remove(values, offset)
            values[#values + 1] = seed
            values[#values + 1] = mergedMask
            return true
        end
    end
    if count >= MAX_TOPIC_PLAYERS then
        table.remove(values, 1)
        table.remove(values, 1)
    end
    values[#values + 1] = seed
    values[#values + 1] = mask
    return true
end

Internal.UpsertConversationTopicPlayer = upsertTopicPlayer

local function topicLabels(mask, maximum)
    local labels = {}
    local bit
    local topic
    mask = Events.FilterConversationTopicMask(mask)
    maximum = math.max(0, math.min(8, math.floor(tonumber(maximum) or 8)))
    for bit = 1, MAX_TOPIC_BITS do
        if #labels >= maximum then break end
        topic = Data.conversationTopicByBit[bit]
        if topic and hasBit(mask, bit) then
            labels[#labels + 1] = topic.label
        end
    end
    return labels
end

function Memory.BuildWorkingConversationTopicFacts(session, limit)
    local mask = Events.GetConversationTopicMask(session)
    local labels = topicLabels(mask, limit)
    if #labels <= 0 then return labels end
    return {
        {
            kind = "conversation_working",
            truth_status = "observed_this_session",
            content = "During this conversation, you discussed "
                .. table.concat(labels, ", ") .. " with this player.",
        },
    }
end

function Memory.BuildConversationTopicFacts(record, playerUUID, limit)
    local normalized = type(record) == "table"
        and Events.Normalize(record.memory) or nil
    local seed = Events.ConversationPlayerSeed(record, playerUUID)
    local topics = normalized and normalized.t or nil
    local maximum = math.max(0, math.min(8, math.floor(
        tonumber(limit) or 8
    )))
    local mask = 0
    local index
    local offset
    if maximum <= 0 or not seed or type(topics) ~= "table" then
        return {}
    end
    for index = 1, math.floor(#topics / 2) do
        offset = (index - 1) * 2 + 1
        if topics[offset] == seed then
            mask = Events.NormalizeConversationTopicMask(
                topics[offset + 1]
            )
            break
        end
    end
    local labels = topicLabels(mask, maximum)
    if #labels <= 0 then return labels end
    return {
        {
            kind = "conversation_today",
            truth_status = "remembered_today",
            content = "Earlier today, you discussed "
                .. table.concat(labels, ", ") .. " with this player.",
        },
    }
end
return Events
