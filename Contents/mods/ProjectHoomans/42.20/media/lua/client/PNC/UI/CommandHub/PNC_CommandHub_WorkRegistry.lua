-- Data-driven work authorization catalog.
--
-- The Work window only renders this registry. Adding a new colony job requires
-- a definition here (or a later Register call), not another UI branch.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.WorkRegistry = PNC.CommandHub.WorkRegistry or {}

local Registry = PNC.CommandHub.WorkRegistry
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
        return nil, "invalid_work_definition"
    end
    local id = tostring(definition.id or "")
    if id == "" then return nil, "invalid_work_definition" end
    definition.id = id
    definition.titleKey = definition.titleKey
        or ("UI_PNC_Job_" .. id)
    definition.titleFallback = definition.titleFallback or id
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

local defaults = {
    { id = "Constructor", order = 10,
        titleKey = "UI_PNC_Job_Constructor", titleFallback = "CONSTRUCTOR" },
    { id = "Researcher", order = 20,
        titleKey = "UI_PNC_Job_Researcher", titleFallback = "RESEARCHER" },
    { id = "WorkshopWorker", order = 30,
        titleKey = "UI_PNC_Job_WorkshopWorker",
        titleFallback = "WORKSHOP WORKER" },
    { id = "Farmer", order = 40,
        titleKey = "UI_PNC_Job_Farmer", titleFallback = "FARMER" },
    { id = "Fishing", order = 50,
        titleKey = "UI_PNC_Job_Fishing", titleFallback = "FISHING" },
    { id = "Lumber", order = 60,
        titleKey = "UI_PNC_Job_Lumber", titleFallback = "LUMBER" },
    { id = "CorpseHaul", order = 70,
        titleKey = "UI_PNC_Job_CorpseHaul", titleFallback = "CORPSE HAUL" },
}

for _, definition in ipairs(defaults) do
    if not Registry.Get(definition.id) then Registry.Register(definition) end
end

-- Keep the client catalog aware of shared jobs added by another subsystem.
-- Such jobs receive a safe fallback label until they provide localized text.
for _, id in ipairs(PNC.WorkDefinitions
    and PNC.WorkDefinitions.COLONY_JOBS or {}) do
    if not Registry.Get(id) then
        Registry.Register({ id = id, titleFallback = tostring(id) })
    end
end

return Registry
