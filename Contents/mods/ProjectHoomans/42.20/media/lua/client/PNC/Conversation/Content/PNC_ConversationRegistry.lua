-- Build 42.20 registry implementation for common conversation definitions.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Registry = PNC.Conversation.Content or {}
PNC.Conversation.Content = Registry
Registry.greetings = Registry.greetings or {}
Registry.backgrounds = Registry.backgrounds or {}

function Registry.RegisterGreeting(relationshipID, timeID, values)
    relationshipID = tostring(relationshipID or "FirstMeet")
    timeID = tostring(timeID or "twilight")
    local relationship = Registry.greetings[relationshipID] or {}
    Registry.greetings[relationshipID] = relationship
    local bucket = relationship[timeID] or { values = {} }
    relationship[timeID] = bucket
    local index
    for index = 1, #(values or {}) do
        local value = values[index]
        if type(value) == "string" then
            value = { key = value }
        end
        bucket.values[#bucket.values + 1] = value
    end
    return bucket
end

function Registry.RegisterBackground(timeID, definition)
    Registry.backgrounds[tostring(timeID)] = definition
end

local function stableNumber(value)
    local text = tostring(value or "")
    local total = 0
    local index
    for index = 1, #text do total = (total * 33 + string.byte(text, index)) % 2147483647 end
    return total
end

function Registry.GetGreeting(relationshipID, timeID, npcID, day)
    local relationship = Registry.greetings[tostring(relationshipID)]
        or Registry.greetings.FirstMeet
        or {}
    local bucket = relationship[tostring(timeID)]
        or relationship.twilight
        or nil
    local values = bucket and bucket.values or {}
    if #values == 0 then return nil end
    local selection = (
        stableNumber(npcID)
        + stableNumber(relationshipID)
        + stableNumber(timeID)
        + (tonumber(day) or 0)
    ) % #values + 1
    return values[selection]
end

function Registry.GetBackground(timeID)
    local definition = Registry.backgrounds[tostring(timeID)]
        or Registry.backgrounds.twilight
    return definition and definition.id or tostring(timeID or "twilight")
end

return Registry
