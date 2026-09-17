-- Bounded, serializable Puppet Opera diagnostics.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Trace = PNC.PuppetOpera.Trace or {}

local Trace = PNC.PuppetOpera.Trace

local function copyFields(fields)
    local result = {}
    if type(fields) ~= "table" then return result end
    local key
    local value
    for key, value in pairs(fields) do
        if type(value) ~= "table" and type(value) ~= "function"
            and type(value) ~= "userdata"
        then
            result[key] = value
        end
    end
    return result
end

function Trace.New(maxEvents)
    return {
        events = {},
        maxEvents = math.max(16, math.min(512, tonumber(maxEvents) or 128)),
        sequence = 0,
    }
end

function Trace.Add(trace, now, eventName, fields)
    if type(trace) ~= "table" then return nil end
    trace.events = trace.events or {}
    trace.sequence = (tonumber(trace.sequence) or 0) + 1
    local event = copyFields(fields)
    event.sequence = trace.sequence
    event.at = tonumber(now) or 0
    event.event = tostring(eventName or "event")
    trace.events[#trace.events + 1] = event
    local maximum = tonumber(trace.maxEvents) or 128
    while #trace.events > maximum do
        table.remove(trace.events, 1)
    end
    return event
end

function Trace.Snapshot(trace)
    local result = {}
    local events = trace and trace.events or {}
    local index
    local event
    for index, event in ipairs(events) do
        result[index] = copyFields(event)
    end
    return result
end

function Trace.Last(trace)
    local events = trace and trace.events or nil
    return events and events[#events] or nil
end

function Trace.Format(trace)
    local lines = {}
    local events = trace and trace.events or {}
    local index
    local event
    for index, event in ipairs(events) do
        lines[index] = string.format(
            "#%s %s @%s phase=%s actor=%s beat=%s reason=%s",
            tostring(event.sequence or index),
            tostring(event.event or "event"),
            tostring(event.at or 0),
            tostring(event.phase or "-"),
            tostring(event.actor or "-"),
            tostring(event.beat or "-"),
            tostring(event.reason or "-")
        )
    end
    return table.concat(lines, "\n")
end

return Trace
