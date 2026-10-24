-- Bounded client handoff for semantic provenance crossing presentation sinks.
-- Core's generic social-flavor queue intentionally keeps nested maps out of
-- its normalized item. This registry carries only the bounded envelope; it
-- never stores rendered text or durable lifecycle state.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Registry = PNC.Semantics.InteractionPresentationRegistry or {}
PNC.Semantics.InteractionPresentationRegistry = Registry

Registry.LIMIT = Registry.LIMIT or 64
Registry.values = Registry.values or {}
Registry.order = Registry.order or {}

function Registry.Remember(eventID, interaction)
    eventID = tostring(eventID or "")
    if eventID == "" or type(interaction) ~= "table" then return false end
    if Registry.values[eventID] == nil then
        while #Registry.order >= Registry.LIMIT do
            local oldest = table.remove(Registry.order, 1)
            Registry.values[oldest] = nil
        end
        Registry.order[#Registry.order + 1] = eventID
    end
    Registry.values[eventID] = interaction
    return true
end

function Registry.Take(eventID)
    eventID = tostring(eventID or "")
    if eventID == "" then return nil end
    local value = Registry.values[eventID]
    Registry.values[eventID] = nil
    return value
end

function Registry.Peek(eventID)
    return Registry.values[tostring(eventID or "")]
end

function Registry.Reset()
    Registry.values = {}
    Registry.order = {}
    return true
end

return Registry
