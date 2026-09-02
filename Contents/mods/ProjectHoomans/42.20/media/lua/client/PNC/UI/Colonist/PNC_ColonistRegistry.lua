-- Registry for colonist-specific tabs exposed by the unified Colony menu.
--
-- Other client modules can register a tab through
-- PNC.ColonistUI.RegisterTab(definition).  The window observes Revision so a
-- tab injected after the window was opened is added on the next layout pass.

PNC = PNC or {}
PNC.ColonistUI = PNC.ColonistUI or {}

local ColonistUI = PNC.ColonistUI
local Registry = ColonistUI.TabRegistry or {
    ordered = {},
    byID = {},
    nextSequence = 0,
    Revision = 0,
}
ColonistUI.TabRegistry = Registry
Registry.ordered = Registry.ordered or {}
Registry.byID = Registry.byID or {}
Registry.nextSequence = Registry.nextSequence or 0
Registry.Revision = tonumber(Registry.Revision) or 0

local function sortTabs()
    table.sort(Registry.ordered, function(left, right)
        local leftOrder = tonumber(left.order) or 1000
        local rightOrder = tonumber(right.order) or 1000
        if leftOrder == rightOrder then
            return (tonumber(left._sequence) or 0)
                < (tonumber(right._sequence) or 0)
        end
        return leftOrder < rightOrder
    end)
end

function Registry.Register(definition)
    if type(definition) ~= "table" then return false end
    local id = tostring(definition.id or "")
    if id == "" or Registry.byID[id] then return false end
    Registry.nextSequence = Registry.nextSequence + 1
    definition.id = id
    definition._sequence = Registry.nextSequence
    Registry.byID[id] = definition
    Registry.ordered[#Registry.ordered + 1] = definition
    sortTabs()
    Registry.Revision = Registry.Revision + 1
    return true
end

function Registry.Get(id)
    return Registry.byID[tostring(id or "")]
end

function Registry.All()
    return Registry.ordered
end

function ColonistUI.RegisterTab(definition)
    return Registry.Register(definition)
end

return Registry
