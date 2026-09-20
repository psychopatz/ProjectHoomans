-- Project at most four locally-rendered gossip lines for one known target.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Data = Memory._registry
local Internal = Events.Internal
local hasFlag = Internal.HasFlag
local resolveTarget = Internal.ResolveEntityReference
local MAX_GOSSIP = Events.MAX_GOSSIP

local function templateUsesOnlySubject(template)
    local arguments = template and template.arguments or nil
    local index
    if type(arguments) ~= "table" then return true end
    for index = 1, #arguments do
        if arguments[index] ~= "subject" then return false end
    end
    return true
end

local function safeSubject(value)
    local output
    if type(value) ~= "string" and type(value) ~= "number" then
        return nil
    end
    output = string.gsub(tostring(value), "%c", "")
    output = string.gsub(output, "^%s+", "")
    output = string.gsub(output, "%s+$", "")
    if output == "" then return nil end
    if #output > 80 then output = string.sub(output, 1, 80) end
    return output
end

local function considerGossip(
    codes,
    seen,
    record,
    eventCode,
    eventDay,
    speakerClass,
    limit
)
    local eventType = Data.eventByCode[eventCode]
    local identity = PNC and PNC.Identity
    local seed = tonumber(record.identitySeed)
        or record.identity and tonumber(record.identity.seed) or 1
    local template
    if #codes >= limit or not eventType or not eventType.gossipEvent
        or type(Memory.SelectGossipTemplate) ~= "function"
    then
        return
    end
    if identity and type(identity.NormalizeSeed) == "function" then
        seed = identity.NormalizeSeed(seed, record.id)
    end
    template = Memory.SelectGossipTemplate(
        eventType.gossipEvent,
        seed,
        tostring(eventCode) .. ":" .. tostring(eventDay or 0),
        { speakerClass = speakerClass }
    )
    if template and templateUsesOnlySubject(template)
        and not seen[template.code]
    then
        seen[template.code] = true
        codes[#codes + 1] = template.code
    end
end

function Events.BuildGossipCodes(
    record,
    targetReference,
    subjectName,
    speakerClass,
    limit
)
    local target = resolveTarget(targetReference)
    local subject = safeSubject(subjectName)
    local normalized
    local codes = {}
    local seen = {}
    local maximum = math.max(
        1,
        math.min(MAX_GOSSIP, math.floor(tonumber(limit) or MAX_GOSSIP))
    )
    local short
    local long
    local index
    local offset
    local currentDay
    if type(record) ~= "table" or not target or not target.seed
        or not subject
    then
        return codes
    end
    normalized = Events.Normalize(record.memory)
    if not normalized then return codes end
    short = normalized.s or {}
    long = normalized.l or {}
    currentDay = Internal.CurrentWorldDay() or normalized.d
    for index = math.floor(#short / 3), 1, -1 do
        offset = (index - 1) * 3 + 1
        if short[offset + 1] == target.seed
            and hasFlag(short[offset + 2], Events.FLAG_SHAREABLE)
        then
            considerGossip(
                codes,
                seen,
                record,
                short[offset],
                currentDay,
                speakerClass,
                maximum
            )
        end
        if #codes >= maximum then return codes end
    end
    for index = math.floor(#long / 4), 1, -1 do
        offset = (index - 1) * 4 + 1
        if long[offset + 1] == target.seed
            and hasFlag(long[offset + 3], Events.FLAG_SHAREABLE)
        then
            considerGossip(
                codes,
                seen,
                record,
                long[offset],
                long[offset + 2],
                speakerClass,
                maximum
            )
        end
        if #codes >= maximum then return codes end
    end
    return codes
end

return true
