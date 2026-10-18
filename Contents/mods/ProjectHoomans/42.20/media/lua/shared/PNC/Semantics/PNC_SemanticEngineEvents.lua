-- Bounded semantic notifications for authoritative engine observations.
--
-- Events are facts about something that happened. They are deliberately not
-- an action queue: commands use the existing authority adapters and never
-- enter this bus. Producers may be server adapters, client observers, or
-- deterministic harness fixtures without changing consumers.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Events = PNC.Semantics.EngineEvents or {}
PNC.Semantics.EngineEvents = Events

Events.VERSION = 1
Events.MAX_TYPES = 32
Events.MAX_RECENT = 64
Events.TYPES = Events.TYPES or {}
Events.SUBSCRIBERS = Events.SUBSCRIBERS or {}
Events.RECENT = Events.RECENT or {}
Events.COUNTS = Events.COUNTS or {}

local function scalar(value)
    local valueType = type(value)
    if valueType == "string" then
        value = string.sub(value, 1, 128)
        return value ~= "" and value or nil
    end
    if valueType == "boolean" then return value end
    if valueType == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
    then
        return value
    end
    return nil
end

local function boundedContext(value)
    local output = {}
    local count = 0
    local key
    local item
    if type(value) ~= "table" then return output end
    for key, item in pairs(value) do
        if count >= 16 then break end
        item = scalar(item)
        if item ~= nil and (type(key) == "string" or type(key) == "number") then
            output[key] = item
            count = count + 1
        end
    end
    return output
end

function Events.RegisterType(eventType, definition)
    eventType = tostring(eventType or "")
    if eventType == "" or #eventType > 96 then
        return false, "invalid_engine_event_type"
    end
    if type(definition) ~= "table" then definition = {} end
    Events.TYPES[eventType] = {
        type = eventType,
        scope = tostring(definition.scope or "engine"),
        authority = tostring(definition.authority or "server"),
        description = tostring(definition.description or ""),
    }
    return true, Events.TYPES[eventType]
end

function Events.Register(id, handler)
    id = tostring(id or "")
    if id == "" or #id > 96 or type(handler) ~= "function" then
        return false, "invalid_engine_event_subscriber"
    end
    Events.SUBSCRIBERS[id] = handler
    return true
end

function Events.Unregister(id)
    id = tostring(id or "")
    if Events.SUBSCRIBERS[id] == nil then return false end
    Events.SUBSCRIBERS[id] = nil
    return true
end

function Events.Publish(eventType, payload)
    local event = {}
    local key
    local value
    local id
    local callback
    local ok
    eventType = tostring(eventType or "")
    if eventType == "" then return false, "event_type_required" end
    for key, value in pairs(type(payload) == "table" and payload or {}) do
        value = scalar(value)
        if value ~= nil and (type(key) == "string" or type(key) == "number") then
            event[key] = value
        end
    end
    event.type = eventType
    event.schemaVersion = Events.VERSION
    Events.RECENT[#Events.RECENT + 1] = event
    while #Events.RECENT > Events.MAX_RECENT do
        table.remove(Events.RECENT, 1)
    end
    Events.COUNTS[eventType] = (tonumber(Events.COUNTS[eventType]) or 0) + 1
    for id, callback in pairs(Events.SUBSCRIBERS) do
        ok = pcall(callback, event)
        if not ok then
            -- A subscriber is an optional observation consumer. Its failure
            -- must never prevent the authoritative producer from returning.
        end
    end
    return true, event
end

function Events.ListTypes()
    local output = {}
    local eventType
    for eventType in pairs(Events.TYPES) do
        output[#output + 1] = Events.TYPES[eventType]
    end
    table.sort(output, function(left, right) return left.type < right.type end)
    return output
end

function Events.Recent()
    local output = {}
    local index
    for index = 1, #Events.RECENT do
        output[index] = Events.RECENT[index]
    end
    return output
end

function Events.Reset()
    Events.RECENT = {}
    Events.COUNTS = {}
end

Events.RegisterType("engine:zombie_killed", {
    scope = "player",
    authority = "server",
    description = "A server-observed player zombie kill.",
})

return Events
