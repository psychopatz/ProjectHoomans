-- Stable event codes and identity-seed references shared by the store and
-- gossip projection.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Internal = Events.Internal

local MAX_EVENT_CODE = 2147483646
local MAX_SEED = 2147483646
local MAX_DAY = 2147483646
local MAX_EVENT_ID_LENGTH = 64

Events.VERSION = 2
Events.MAX_EVENT_CODE = MAX_EVENT_CODE
Events.MAX_SEED = MAX_SEED
Events.MAX_DAY = MAX_DAY
Events.SHORT_LIMIT = 8
Events.LONG_LIMIT = 6
Events.MAX_GOSSIP = 4
Events.FLAG_SHAREABLE = 1
Events.FLAG_DURABLE = 2

local function positiveInteger(value, maximum)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric
        or numeric == math.huge or numeric == -math.huge
    then
        return nil
    end
    numeric = math.floor(numeric)
    if numeric < 1 or numeric > maximum then
        return nil
    end
    return numeric
end

local function normalizeFlags(value)
    local numeric = tonumber(value)
    if numeric == nil or numeric ~= numeric
        or numeric == math.huge or numeric == -math.huge
    then
        return 0
    end
    return math.max(0, math.min(3, math.floor(numeric)))
end

local function hasFlag(flags, flag)
    flags = normalizeFlags(flags)
    return math.floor(flags / flag) % 2 == 1
end

local function mergeFlags(left, right)
    local output = 0
    if hasFlag(left, Events.FLAG_SHAREABLE)
        or hasFlag(right, Events.FLAG_SHAREABLE)
    then
        output = output + Events.FLAG_SHAREABLE
    end
    if hasFlag(left, Events.FLAG_DURABLE)
        or hasFlag(right, Events.FLAG_DURABLE)
    then
        output = output + Events.FLAG_DURABLE
    end
    return output
end

local function normalizeEventID(value)
    if type(value) ~= "string" then return nil end
    value = string.lower(value)
    if value == "" or #value > MAX_EVENT_ID_LENGTH
        or string.find(value, "%c")
    then
        return nil
    end
    return value
end

local function identityAPI()
    return PNC and PNC.Identity or nil
end

local function stableCode(eventID)
    local identity = identityAPI()
    if identity and type(identity.HashText) == "function" then
        return positiveInteger(
            identity.HashText(
                "pnc:conversation-memory:event:" .. tostring(eventID),
                5381
            ),
            MAX_EVENT_CODE
        )
    end
    return nil
end

local function currentWorldDay()
    local identity = identityAPI()
    local year
    local month
    local day
    local packed
    if not identity or type(identity.CurrentWorldDate) ~= "function"
        or type(identity.EncodeBirthDate) ~= "function"
    then
        return nil
    end
    year, month, day = identity.CurrentWorldDate()
    if year == nil then return nil end
    packed = identity.EncodeBirthDate(year, month, day)
    return positiveInteger(packed, MAX_DAY)
end

local function targetSeed(reference, targetRecord)
    local identity = identityAPI()
    local rawSeed = targetRecord and tonumber(targetRecord.identitySeed)
        or targetRecord and targetRecord.identity
        and tonumber(targetRecord.identity.seed) or nil
    if rawSeed and rawSeed > 0 and identity
        and type(identity.MixSeed) == "function"
    then
        return positiveInteger(
            identity.MixSeed(rawSeed, "pnc:conversation-memory:npc"),
            MAX_SEED
        )
    end
    if identity and type(identity.HashText) == "function" then
        local namespace = "pnc:conversation-memory:"
            .. tostring(reference.kind or "entity")
        local salt = identity.HashText(namespace, 5381)
        return positiveInteger(
            identity.HashText(reference.key, salt),
            MAX_SEED
        )
    end
    return nil
end

Internal.TargetSeed = targetSeed

Internal.PositiveInteger = positiveInteger
Internal.NormalizeFlags = normalizeFlags
Internal.HasFlag = hasFlag
Internal.MergeFlags = mergeFlags
Internal.NormalizeEventID = normalizeEventID
Internal.StableCode = stableCode
Internal.CurrentWorldDay = currentWorldDay

return true
