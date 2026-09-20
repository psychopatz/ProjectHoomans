-- Definitions provide stable event metadata; unregistered social event types
-- receive bounded deterministic fallback codes.
PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

local Memory = PNC.Conversation.Memory
local Events = Memory.Events
local Data = Memory._registry
local Internal = Events.Internal
local normalizeEventID = Internal.NormalizeEventID
local stableCode = Internal.StableCode
local positiveInteger = Internal.PositiveInteger
local MAX_DYNAMIC_TYPES = 128

local function normalizedSources(definition, id)
    local input = definition.sourceTypes or definition.sourceType
    local output = {}
    local seen = {}
    local index
    if type(input) == "string" then
        input = { input }
    elseif type(input) ~= "table" then
        input = { id }
    end
    for index = 1, math.min(#input, 16) do
        local source = normalizeEventID(tostring(input[index] or ""))
        if source and not seen[source] then
            seen[source] = true
            output[#output + 1] = source
        end
    end
    return #output > 0 and output or nil
end

function Events.RegisterType(definition)
    local id
    local code
    local sources
    local salience
    local gossipEvent
    local old
    local collision
    local index
    local entry
    if type(definition) ~= "table" then
        return false, "event_definition_required"
    end
    id = normalizeEventID(definition.id)
    if not id then return false, "invalid_event_id" end
    if definition.code ~= nil then
        code = positiveInteger(definition.code, Events.MAX_EVENT_CODE)
        if not code then return false, "invalid_event_code" end
    else
        code = stableCode(id)
    end
    if not code then return false, "invalid_event_code" end
    sources = normalizedSources(definition, id)
    if not sources then return false, "event_source_required" end
    old = Data.eventByID[id]
    if old then
        if old.code == code then return true, old end
        return false, "duplicate_event_id"
    end
    collision = Data.eventByCode[code]
    if collision and collision.id ~= id then
        return false, "duplicate_event_code"
    end
    for index = 1, #sources do
        old = Data.eventBySource[sources[index]]
        if old and old.id ~= id and old.dynamic ~= true then
            return false, "duplicate_event_source"
        end
    end
    salience = math.max(
        0,
        math.min(255, math.floor(tonumber(definition.salience) or 0))
    )
    gossipEvent = normalizeEventID(definition.gossipEvent)
    entry = {
        id = id,
        code = code,
        sourceTypes = sources,
        salience = salience,
        longTerm = definition.longTerm == true,
        gossipEvent = gossipEvent,
    }
    Data.eventByID[id] = entry
    Data.eventByCode[code] = entry
    Data.eventSourceByCode[code] = id
    for index = 1, #sources do
        local source = sources[index]
        local alias = stableCode(source)
        Data.eventBySource[source] = entry
        if alias then
            old = Data.eventByCode[alias]
            collision = Data.eventSourceByCode[alias]
            if (not old or old.id == id)
                and (not collision or collision == source or collision == id)
            then
                Data.eventByCode[alias] = entry
                Data.eventSourceByCode[alias] = source
            end
        end
    end
    return true, entry
end

local function resolveEventType(sourceType)
    local id = normalizeEventID(sourceType)
    local entry
    local code
    local owner
    if not id then return nil, "invalid_event_source" end
    entry = Data.eventBySource[id]
    if entry then return entry end
    entry = Data.dynamicEventBySource[id]
    if entry then return entry end
    if Data.dynamicEventCount >= MAX_DYNAMIC_TYPES then
        return nil, "event_type_limit"
    end
    code = stableCode(id)
    if not code then return nil, "event_code_unavailable" end
    owner = Data.eventSourceByCode[code]
    if owner and owner ~= id then
        return nil, "event_code_collision"
    end
    entry = {
        id = id,
        code = code,
        sourceTypes = { id },
        salience = 0,
        longTerm = false,
        dynamic = true,
    }
    Data.dynamicEventBySource[id] = entry
    Data.eventSourceByCode[code] = id
    Data.dynamicEventCount = Data.dynamicEventCount + 1
    return entry
end

function Events.GetType(idOrCode)
    local code
    local id
    if type(idOrCode) == "number" then
        code = positiveInteger(idOrCode, Events.MAX_EVENT_CODE)
        return code and Data.eventByCode[code] or nil
    end
    id = normalizeEventID(tostring(idOrCode or ""))
    return id and Data.eventByID[id] or nil
end

Internal.ResolveEventType = resolveEventType

return true
