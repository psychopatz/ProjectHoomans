-- Gossip catalog with stable numeric codes suitable for small network payloads.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Data = Memory._registry
local SENTIMENTS = {
    positive = true,
    negative = true,
    neutral = true,
    mixed = true,
}
local CLASSES = {
    colonist = true,
    neutral = true,
    hostile = true,
}

local function normalizeStringList(raw, allowed, limit)
    if raw == nil then
        return nil
    end
    if type(raw) ~= "table" then
        return nil, "string_list_required"
    end
    local values = {}
    local seen = {}
    for i = 1, math.min(#raw, limit) do
        local value = string.lower(tostring(raw[i] or ""))
        if value == "any" then
            return nil
        end
        if value ~= "" and allowed and not allowed[value] then
            return nil, "invalid_list_value:" .. value
        end
        if value ~= "" and not seen[value] then
            seen[value] = true
            values[#values + 1] = value
        end
    end
    if #values == 0 then
        return nil
    end
    return values
end

function Memory.RegisterGossipTemplate(definition)
    if type(definition) ~= "table" then
        return false, "gossip_definition_required"
    end
    local id = tostring(definition.id or "")
    local numericCode = tonumber(definition.code)
    local code = math.floor(numericCode or 0)
    local event = string.lower(tostring(definition.event or ""))
    local sentiment = string.lower(tostring(definition.sentiment or ""))
    local tone = string.lower(tostring(definition.tone or ""))
    local textKey = type(definition.textKey) == "string"
        and definition.textKey or ""
    if id == "" or not numericCode or code ~= numericCode
        or code < 1 or code > 65535 or event == ""
        or tone == "" or not SENTIMENTS[sentiment] or textKey == ""
    then
        return false, "invalid_gossip_identity"
    end
    if Data.gossipByID[id] or Data.gossipByCode[code] then
        return false, "duplicate_gossip_id_or_code"
    end
    local speakerClasses, reason = normalizeStringList(
        definition.speakerClasses,
        CLASSES,
        3
    )
    if reason then
        return false, reason
    end
    local arguments
    arguments, reason = normalizeStringList(
        definition.arguments or {},
        nil,
        8
    )
    if reason then
        return false, "invalid_gossip_arguments"
    end
    arguments = arguments or {}
    local textSource
    textSource, reason = Memory.NormalizeTextSource(
        definition.textSource,
        Memory.GOSSIP_SOURCE
    )
    if not textSource then
        return false, reason
    end
    local entry = {
        id = id,
        code = code,
        event = event,
        sentiment = sentiment,
        tone = tone,
        speakerClasses = speakerClasses,
        arguments = arguments,
        textSource = textSource,
        textKey = textKey,
        weight = math.max(
            1,
            math.min(10000, math.floor(tonumber(definition.weight) or 1))
        ),
    }
    Data.gossipByID[id] = entry
    Data.gossipByCode[code] = entry
    Data.gossipList[#Data.gossipList + 1] = entry
    local eventEntries = Data.gossipByEvent[event]
    if not eventEntries then
        eventEntries = {}
        Data.gossipByEvent[event] = eventEntries
    end
    eventEntries[#eventEntries + 1] = entry
    Memory.RegisterTextKey(textSource, textKey)
    return true, entry
end

function Memory.GetGossipTemplate(idOrCode)
    if type(idOrCode) == "number" then
        return Data.gossipByCode[math.floor(idOrCode)]
    end
    return Data.gossipByID[tostring(idOrCode or "")]
end

function Memory.GetGossipTemplateByCode(code)
    return Data.gossipByCode[math.floor(tonumber(code) or 0)]
end


return Memory
