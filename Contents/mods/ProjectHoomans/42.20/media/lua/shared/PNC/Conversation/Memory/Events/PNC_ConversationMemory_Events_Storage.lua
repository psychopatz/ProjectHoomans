-- Flat numeric arrays keep ModData allocation and traversal bounded.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Data = Memory._registry
local Internal = Events.Internal
local positiveInteger = Internal.PositiveInteger
local normalizeFlags = Internal.NormalizeFlags
local hasFlag = Internal.HasFlag
local mergeFlags = Internal.MergeFlags
local currentWorldDay = Internal.CurrentWorldDay

local NORMALIZE_LONG_LIMIT = 64

local function removeSegment(values, index, width)
    local count
    for count = 1, width do
        table.remove(values, index)
    end
end

local function upsertShort(values, code, seed, flags)
    local count = math.floor(#values / 3)
    local index
    local offset
    local oldFlags
    local mergedFlags
    for index = 1, count do
        offset = (index - 1) * 3 + 1
        if values[offset] == code and values[offset + 1] == seed then
            oldFlags = normalizeFlags(values[offset + 2])
            mergedFlags = mergeFlags(oldFlags, flags)
            if index == count and oldFlags == mergedFlags then
                return false
            end
            removeSegment(values, offset, 3)
            values[#values + 1] = code
            values[#values + 1] = seed
            values[#values + 1] = mergedFlags
            return true
        end
    end
    values[#values + 1] = code
    values[#values + 1] = seed
    values[#values + 1] = flags
    while #values > Events.SHORT_LIMIT * 3 do
        removeSegment(values, 1, 3)
    end
    return true
end

Internal.UpsertShort = upsertShort

local function salienceFor(code, flags)
    local entry = Data.eventByCode[code]
    if entry and entry.salience > 0 then
        return entry.salience
    end
    return hasFlag(flags, Events.FLAG_DURABLE) and 220 or 0
end

local function upsertLong(values, code, seed, day, flags)
    local count = math.floor(#values / 4)
    local index
    local offset
    local oldDay
    local oldFlags
    local newDay
    local mergedFlags
    local incomingScore
    local weakestIndex
    local weakestScore
    local weakestDay
    flags = mergeFlags(flags, Events.FLAG_DURABLE)
    for index = 1, count do
        offset = (index - 1) * 4 + 1
        if values[offset] == code and values[offset + 1] == seed then
            oldDay = positiveInteger(values[offset + 2], 2147483646) or day
            oldFlags = normalizeFlags(values[offset + 3])
            newDay = math.max(oldDay, day)
            mergedFlags = mergeFlags(oldFlags, flags)
            if index == count and oldDay == newDay
                and oldFlags == mergedFlags
            then
                return false
            end
            removeSegment(values, offset, 4)
            values[#values + 1] = code
            values[#values + 1] = seed
            values[#values + 1] = newDay
            values[#values + 1] = mergedFlags
            return true
        end
    end
    if count < Events.LONG_LIMIT then
        values[#values + 1] = code
        values[#values + 1] = seed
        values[#values + 1] = day
        values[#values + 1] = flags
        return true
    end
    incomingScore = salienceFor(code, flags)
    weakestIndex = 1
    weakestScore = math.huge
    weakestDay = math.huge
    for index = 1, count do
        offset = (index - 1) * 4 + 1
        local score = salienceFor(values[offset], values[offset + 3])
        local existingDay = positiveInteger(values[offset + 2], 2147483646)
            or 0
        if score < weakestScore
            or score == weakestScore and existingDay < weakestDay
        then
            weakestIndex = index
            weakestScore = score
            weakestDay = existingDay
        end
    end
    if incomingScore < weakestScore
        or incomingScore == weakestScore and day <= weakestDay
    then
        return false
    end
    removeSegment(values, (weakestIndex - 1) * 4 + 1, 4)
    values[#values + 1] = code
    values[#values + 1] = seed
    values[#values + 1] = day
    values[#values + 1] = flags
    return true
end

Internal.UpsertLong = upsertLong

local function normalizeShort(raw, output)
    local total
    local first
    local index
    local offset
    local code
    local seed
    local flags
    if type(raw) ~= "table" then return end
    total = math.floor(#raw / 3)
    first = math.max(1, total - Events.SHORT_LIMIT + 1)
    for index = first, total do
        offset = (index - 1) * 3 + 1
        code = positiveInteger(raw[offset], 2147483646)
        seed = positiveInteger(raw[offset + 1], 2147483646)
        flags = normalizeFlags(raw[offset + 2])
        if code and seed then
            upsertShort(output, code, seed, flags)
        end
    end
end

local function normalizeLong(raw, output)
    local total
    local first
    local index
    local offset
    local code
    local seed
    local day
    local flags
    if type(raw) ~= "table" then return end
    total = math.min(math.floor(#raw / 4), NORMALIZE_LONG_LIMIT)
    first = math.max(1, math.floor(#raw / 4) - total + 1)
    for index = first, first + total - 1 do
        offset = (index - 1) * 4 + 1
        code = positiveInteger(raw[offset], 2147483646)
        seed = positiveInteger(raw[offset + 1], 2147483646)
        day = positiveInteger(raw[offset + 2], 2147483646)
        flags = mergeFlags(
            normalizeFlags(raw[offset + 3]),
            Events.FLAG_DURABLE
        )
        if code and seed and day then
            upsertLong(output, code, seed, day, flags)
        end
    end
end

local function normalizeTopicPlayers(raw, output)
    local total
    local first
    local index
    local offset
    local seed
    local mask
    if type(raw) ~= "table" then return end
    total = math.floor(#raw / 2)
    first = math.max(1, total - Events.TOPIC_PLAYER_LIMIT + 1)
    for index = first, total do
        offset = (index - 1) * 2 + 1
        seed = positiveInteger(raw[offset], Events.MAX_SEED)
        mask = Events.NormalizeConversationTopicMask(raw[offset + 1])
        if seed and mask > 0 then
            Internal.UpsertConversationTopicPlayer(output, seed, mask)
        end
    end
end

function Events.Normalize(raw)
    local output
    local currentDay
    local storedDay
    local shortIsCurrent
    local short
    local long
    local topicPlayers
    if type(raw) ~= "table" then return nil end
    currentDay = currentWorldDay()
    storedDay = positiveInteger(raw.d or raw.day, 2147483646)
    shortIsCurrent = storedDay ~= nil
        and (currentDay == nil or storedDay == currentDay)
    output = { v = Events.VERSION }
    short = {}
    long = {}
    topicPlayers = {}
    if shortIsCurrent then
        normalizeShort(raw.s or raw.short, short)
        normalizeTopicPlayers(raw.t, topicPlayers)
    end
    normalizeLong(raw.l or raw.long, long)
    if #short > 0 then
        output.s = short
    end
    if #topicPlayers > 0 then output.t = topicPlayers end
    if output.s ~= nil or output.t ~= nil then
        output.d = currentDay or storedDay
    end
    if #long > 0 then
        output.l = long
    end
    if output.s == nil and output.t == nil and output.l == nil then
        return nil
    end
    return output
end

function Events.Serialize(raw)
    return Events.Normalize(raw)
end

return true
