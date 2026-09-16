-- Mention index and discourse-focus storage for semantic dialogue context.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Context = PNC.Semantics.DialogueContextState
local Internal = Context.Internal

local function copyValue(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= Context.MAX_METADATA_DEPTH then return nil end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do
        if type(key) ~= "function" and type(item) ~= "function" then
            output[key] = copyValue(item, depth + 1)
        end
    end
    return output
end

local function textValue(value, maximum)
    value = tostring(value or "")
    maximum = tonumber(maximum) or Context.MAX_TEXT
    if #value > maximum then return string.sub(value, 1, maximum) end
    return value
end

local function symbolValue(value)
    value = string.upper(tostring(value or ""))
    value = string.gsub(value, "[%s%-]+", "_")
    value = string.gsub(value, "[^%w_%.:]", "")
    return value ~= "" and value or nil
end

local function timestampValue(options)
    if type(options) == "table" and options.timestamp ~= nil then
        return options.timestamp
    end
    if getTimeInMillis then return getTimeInMillis() end
    if getTimestampMs then return getTimestampMs() end
    return 0
end

local function identityValue(value)
    if type(value) ~= "table" then return nil end
    local fields = { "id", "entityID", "itemID", "uuid" }
    local index
    local result
    for index = 1, #fields do
        result = value[fields[index]]
        if result ~= nil and tostring(result) ~= "" then
            return tostring(result)
        end
    end
    return nil
end

local function normalizedText(value)
    value = string.lower(tostring(value or ""))
    value = string.gsub(value, "%s+", " ")
    return string.gsub(value, "^%s*(.-)%s*$", "%1")
end

local function mentionKey(value)
    local identity = identityValue(value)
    if identity then return "id:" .. identity end
    local entityType = string.lower(tostring(
        value.entityType or value.type or value.kind or "entity"
    ))
    local concept = symbolValue(value.concept or value.category) or ""
    local text = normalizedText(value.text or value.name or value.value)
    if concept == "" and text == "" then return nil end
    return "mention:" .. entityType .. ":" .. concept .. ":" .. text
end

local function mentionFrom(value, options, sequence, timestamp)
    if type(value) ~= "table" then return nil end
    if value.unresolved == true and value.reference ~= nil then return nil end

    local key = mentionKey(value)
    if not key then return nil end
    local entityType = value.entityType or value.type or value.kind
    local output = {
        key = key,
        id = value.id,
        entityID = value.entityID,
        itemID = value.itemID,
        uuid = value.uuid,
        entityType = entityType and string.lower(tostring(entityType)) or nil,
        concept = symbolValue(value.concept or value.category),
        category = symbolValue(value.category),
        text = value.text and textValue(value.text)
            or value.name and textValue(value.name)
            or value.value and textValue(value.value) or nil,
        value = value.value and textValue(value.value) or nil,
        name = value.name and textValue(value.name) or nil,
        quantity = value.quantity,
        ownerID = value.ownerID or value.owner,
        source = options.source or value.source,
        role = options.role or value.role,
        topic = options.topic or value.topic,
        firstTurn = sequence,
        lastTurn = sequence,
        firstTimestamp = timestamp,
        lastTimestamp = timestamp,
        lastRole = options.role or value.role,
        mentionCount = 1,
        capabilities = copyValue(value.capabilities),
        tags = copyValue(value.tags)
            or value.classification and copyValue(value.classification.tags),
        semanticCapabilities = copyValue(value.semanticCapabilities)
            or value.classification
            and copyValue(value.classification.semanticCapabilities),
        marketRole = value.marketRole
            or value.classification and value.classification.marketRole,
        marketSenseTags = copyValue(value.marketSenseTags)
            or value.classification
            and copyValue(value.classification.marketSenseTags),
        classification = copyValue(value.classification),
    }

    if type(output.capabilities) ~= "table" then output.capabilities = {} end
    local fields = {
        "edible", "drinkable", "refillable", "transferable", "portable",
        "consumable",
    }
    local index
    local field
    for index = 1, #fields do
        field = fields[index]
        if value[field] ~= nil and output.capabilities[field] == nil then
            output.capabilities[field] = value[field]
        end
    end
    if type(output.semanticCapabilities) == "table" then
        local capability
        local value
        for capability, value in pairs(output.semanticCapabilities) do
            if output.capabilities[capability] == nil then
                output.capabilities[capability] = copyValue(value)
            end
        end
    end
    return output
end

local function removeKey(list, key)
    local index
    for index = #list, 1, -1 do
        if list[index] == key then table.remove(list, index) end
    end
end

local function moveToFront(list, key, limit)
    removeKey(list, key)
    table.insert(list, 1, key)
    if limit then
        while #list > limit do table.remove(list) end
    end
end

local function mergeMap(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then return end
    local key
    local value
    for key, value in pairs(source) do
        if target[key] == nil then target[key] = copyValue(value) end
    end
end

Internal.CopyValue = copyValue
Internal.TextValue = textValue
Internal.TimestampValue = timestampValue
Internal.MentionFrom = mentionFrom
Internal.RemoveKey = removeKey
Internal.MoveToFront = moveToFront
Internal.MergeMap = mergeMap

function Context:RecordMention(value, options)
    options = type(options) == "table" and options or {}
    local sequence = tonumber(
        options.turn or options.sequence or self.sequence
    ) or 0
    local timestamp = options.timestamp or timestampValue(options)
    local mention = mentionFrom(value, options, sequence, timestamp)
    if not mention then return false, "invalid_mention" end

    local existing = self.mentionsByKey[mention.key]
    if existing then
        existing.lastTurn = mention.lastTurn
        existing.lastTimestamp = mention.lastTimestamp
        existing.mentionCount = (tonumber(existing.mentionCount) or 0) + 1
        existing.lastRole = mention.lastRole or existing.lastRole
        existing.role = mention.role or existing.role
        existing.topic = mention.topic or existing.topic
        existing.source = mention.source or existing.source
        existing.ownerID = mention.ownerID or existing.ownerID
        existing.quantity = mention.quantity or existing.quantity
        existing.marketRole = mention.marketRole or existing.marketRole
        existing.marketSenseTags = mention.marketSenseTags
            or existing.marketSenseTags
        existing.classification = mention.classification
            or existing.classification
        if type(existing.semanticCapabilities) ~= "table" then
            existing.semanticCapabilities = {}
        end
        mergeMap(existing.capabilities, mention.capabilities)
        mergeMap(existing.semanticCapabilities,
            mention.semanticCapabilities)
        mergeMap(existing.tags, mention.tags)
        mention = existing
    else
        self.mentionsByKey[mention.key] = mention
    end

    moveToFront(self.mentionOrder, mention.key)
    local role = string.lower(tostring(mention.lastRole or mention.role or ""))
    if role ~= "query" and options.focus ~= false then
        moveToFront(self.focusKeys, mention.key, self.maxFocus)
    end
    while #self.mentionOrder > self.maxMentions do
        local oldKey = table.remove(self.mentionOrder)
        self.mentionsByKey[oldKey] = nil
        removeKey(self.focusKeys, oldKey)
    end
    return true, copyValue(mention)
end

Context.AddMention = Context.RecordMention

return Context
