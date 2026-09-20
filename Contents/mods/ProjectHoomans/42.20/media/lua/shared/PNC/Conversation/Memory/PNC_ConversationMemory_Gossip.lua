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

local function matchesSpeaker(entry, speakerClass)
    if not speakerClass or not entry.speakerClasses then
        return true
    end
    for i = 1, #entry.speakerClasses do
        if entry.speakerClasses[i] == speakerClass then
            return true
        end
    end
    return false
end

function Memory.GetGossipTemplates(criteria)
    if type(criteria) == "string" then
        criteria = { event = criteria }
    end
    criteria = type(criteria) == "table" and criteria or {}
    local candidates = Data.gossipList
    if criteria.event ~= nil then
        candidates = Data.gossipByEvent[tostring(criteria.event)] or {}
    end
    local results = {}
    local speakerClass = criteria.speakerClass
        and string.lower(tostring(criteria.speakerClass)) or nil
    local sentiment = criteria.sentiment
        and string.lower(tostring(criteria.sentiment)) or nil
    local tone = criteria.tone and string.lower(tostring(criteria.tone)) or nil
    for i = 1, #candidates do
        local entry = candidates[i]
        if (not sentiment or entry.sentiment == sentiment)
            and (not tone or entry.tone == tone)
            and matchesSpeaker(entry, speakerClass)
        then
            results[#results + 1] = entry
        end
    end
    return results
end

function Memory.SelectGossipTemplate(event, seed, salt, filters)
    filters = type(filters) == "table" and filters or {}
    local candidates = Memory.GetGossipTemplates({
        event = event,
        sentiment = filters.sentiment,
        tone = filters.tone,
        speakerClass = filters.speakerClass,
    })
    local totalWeight = 0
    for i = 1, #candidates do
        totalWeight = totalWeight + candidates[i].weight
    end
    if totalWeight <= 0 then
        return nil
    end
    local identityAPI = PNC.Identity
    local roll
    if identityAPI and type(identityAPI.Range) == "function" then
        roll = identityAPI.Range(
            seed,
            "pnc:gossip:" .. tostring(event) .. ":" .. tostring(salt or ""),
            1,
            totalWeight
        )
    else
        roll = (math.floor(tonumber(seed) or 1) % totalWeight) + 1
    end
    for i = 1, #candidates do
        local entry = candidates[i]
        if roll <= entry.weight then
            return entry
        end
        roll = roll - entry.weight
    end
    return candidates[#candidates]
end

function Memory.GetGossipText(template, language)
    local entry = type(template) == "table"
        and template or Memory.GetGossipTemplate(template)
    if not entry then
        return nil, "unknown_gossip_template"
    end
    return Memory.GetText(entry.textSource, entry.textKey, language)
end

function Memory.RenderGossipTemplate(template, arguments, language)
    local text, reason = Memory.GetGossipText(template, language)
    if not text then
        return nil, reason
    end
    return Memory.RenderText(text, arguments)
end

function Memory.BuildGossipPacket(template, arguments)
    local entry = type(template) == "table"
        and template or Memory.GetGossipTemplate(template)
    if not entry then
        return nil, "unknown_gossip_template"
    end
    if #entry.arguments == 0 then
        return { c = entry.code }
    end
    arguments = type(arguments) == "table" and arguments or {}
    local packedArguments = {}
    for i = 1, #entry.arguments do
        local name = entry.arguments[i]
        local value = arguments[name]
        if value == nil then
            value = arguments[i]
        end
        packedArguments[i] = value == nil and "" or value
    end
    return { c = entry.code, a = packedArguments }
end

function Memory.RenderGossipPacket(packet, language)
    if type(packet) ~= "table" then
        return nil, "gossip_packet_required"
    end
    local entry = Memory.GetGossipTemplateByCode(packet.c)
    if not entry then
        return nil, "unknown_gossip_code"
    end
    local arguments = {}
    local packedArguments = type(packet.a) == "table" and packet.a or {}
    for i = 1, #entry.arguments do
        arguments[entry.arguments[i]] = packedArguments[i]
    end
    return Memory.RenderGossipTemplate(entry, arguments, language)
end
