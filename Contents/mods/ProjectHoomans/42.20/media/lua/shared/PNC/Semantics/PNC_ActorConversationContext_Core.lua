-- Bounded source normalization helpers for actor conversation context.

local Core = {}

Core.PERSONALITY_FIELDS = {
    "socialStyle", "compassion", "sociability", "forgiveness", "bravery",
    "materialism", "aggression", "loyalty",
}

function Core.text(value, fallback)
    if value == nil then return fallback end
    value = tostring(value)
    return value ~= "" and value or fallback
end

function Core.finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return nil end
    return value
end

function Core.boundedNumber(value, minimum, maximum)
    value = Core.finite(value)
    if value == nil then return nil end
    if minimum ~= nil and value < minimum then value = minimum end
    if maximum ~= nil and value > maximum then value = maximum end
    return value
end

function Core.copy(value, depth, seen)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 4 then return nil end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    local count = 0
    for key, item in pairs(value) do
        if count >= 24 then break end
        if type(key) == "string" or type(key) == "number" then
            if type(item) ~= "function" then
                output[key] = Core.copy(item, depth + 1, seen)
                count = count + 1
            end
        end
    end
    return output
end

function Core.sourceValue(context, key)
    if type(context) ~= "table" then return nil end
    if context[key] ~= nil then return context[key] end
    if type(context.npcState) == "table"
        and context.npcState[key] ~= nil
    then return context.npcState[key] end
    local entry = context.entry
    local snapshot = type(entry) == "table" and entry.snapshot or nil
    return type(snapshot) == "table" and snapshot[key] or nil
end

function Core.identitySource(context)
    local identity = type(context) == "table" and context.identity or nil
    local record = type(context) == "table" and context.npcRecord or nil
    if type(identity) == "table" then return identity end
    if type(record) == "table" and type(record.identity) == "table" then
        return record.identity
    end
    return type(record) == "table" and record or {}
end

function Core.sortedIDs(value, limit)
    local output = {}
    local seen = {}
    limit = tonumber(limit) or 32
    if type(value) ~= "table" then return output end
    for key, item in pairs(value) do
        local candidate
        if type(key) == "number" then candidate = item
        elseif item == true then candidate = key
        elseif type(item) == "string" then candidate = item end
        candidate = type(candidate) == "string" and candidate or nil
        if candidate then
            candidate = string.lower(candidate)
            if candidate ~= "" and not seen[candidate]
                and #output < limit
            then
                seen[candidate] = true
                output[#output + 1] = candidate
            end
        end
    end
    table.sort(output)
    return output
end

function Core.personalitySource(context)
    local source = context and context.npcPersonality
    if type(source) ~= "table" then source = context and context.personality end
    if type(source) ~= "table" then source = context and context.socialProfile end
    if type(source) ~= "table" then
        local record = context and context.npcRecord
        source = type(record) == "table" and (
            record.personality or record.socialProfile
                or record.social and record.social.personality
        ) or nil
    end
    return type(source) == "table" and source or {}
end

return Core
