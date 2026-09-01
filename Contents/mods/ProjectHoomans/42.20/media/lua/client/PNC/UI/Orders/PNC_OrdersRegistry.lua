-- Reusable client-side order catalog.
--
-- An order definition describes how the Orders window presents and starts a
-- task. Domain services remain authoritative; future activities only need to
-- register a definition here and provide their existing map/action command.

PNC = PNC or {}
PNC.OrderUIRegistry = PNC.OrderUIRegistry or {}

local Registry = PNC.OrderUIRegistry
Registry.Definitions = Registry.Definitions or {}
Registry.Ordered = Registry.Ordered or {}

local function rebuild()
    local output = {}
    for _, definition in pairs(Registry.Definitions) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        local leftOrder = tonumber(left.order) or 100
        local rightOrder = tonumber(right.order) or 100
        if leftOrder == rightOrder then
            return tostring(left.id) < tostring(right.id)
        end
        return leftOrder < rightOrder
    end)
    Registry.Ordered = output
end

function Registry.Register(definition)
    if type(definition) ~= "table" then
        return nil, "invalid_order_definition"
    end
    local id = tostring(definition.id or "")
    if id == "" or tostring(definition.job or "") == "" then
        return nil, "invalid_order_definition"
    end
    definition.id = id
    Registry.Definitions[id] = definition
    rebuild()
    return definition
end

function Registry.Get(id)
    return Registry.Definitions[tostring(id or "")]
end

function Registry.All()
    return Registry.Ordered
end

Registry.Register({
    id = "fishing",
    order = 10,
    job = "Fishing",
    orderKind = "fishing",
    titleKey = "UI_PNC_Orders_Fishing",
    titleFallback = "FISHING",
    descriptionKey = "UI_PNC_Orders_FishingDescription",
    descriptionFallback = "Assign colonists to a shoreline fishing zone.",
    mapCommand = "fishing_zone",
})

Registry.Register({
    id = "lumber",
    order = 20,
    job = "Lumber",
    orderKind = "lumber",
    titleKey = "UI_PNC_Orders_Lumber",
    titleFallback = "CHOP TREES",
    descriptionKey = "UI_PNC_Orders_LumberDescription",
    descriptionFallback = "Assign colonists to a bounded tree-cutting zone.",
    mapCommand = "lumber_zone",
})

Registry.Register({
    id = "corpse_haul",
    order = 30,
    job = "CorpseHaul",
    orderKind = "corpse_haul",
    titleKey = "UI_PNC_Orders_CorpseHaul",
    titleFallback = "GRAB CORPSES",
    descriptionKey = "UI_PNC_Orders_CorpseHaulDescription",
    descriptionFallback = "Automatically move eligible corpses to a stockpile.",
})

return Registry
