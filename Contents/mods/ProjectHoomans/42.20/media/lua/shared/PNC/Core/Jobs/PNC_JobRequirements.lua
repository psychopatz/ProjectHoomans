PNC = PNC or {}
PNC.JobRequirements = PNC.JobRequirements or {}

local Registry = PNC.JobRequirements
Registry.Definitions = Registry.Definitions or {}
Registry.Order = Registry.Order or {}

local function operationKey(operation)
    return string.upper(tostring(operation or ""))
end

local function copyValue(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, child in pairs(value) do
        output[key] = copyValue(child)
    end
    return output
end

function Registry.Register(operation, definition)
    local key = operationKey(operation)
    if key == "" or type(definition) ~= "table" then return false end
    if type(definition.requirements) ~= "table"
        or #definition.requirements < 1
    then
        return false
    end
    if not Registry.Definitions[key] then
        Registry.Order[#Registry.Order + 1] = key
    end
    Registry.Definitions[key] = definition
    return true
end

function Registry.Get(operation)
    return Registry.Definitions[operationKey(operation)]
end

function Registry.GetRequirements(operation)
    local definition = Registry.Get(operation)
    return definition and definition.requirements or nil
end

function Registry.Describe(operation)
    local definition = Registry.Get(operation)
    return definition and copyValue(definition) or nil
end

-- Requirements are data, not behavior. Jobs may register additional
-- operations (fishing, farming, and so on) without changing the storage
-- debug transaction or the live/abstract inventory adapters.
Registry.Register("LUMBER", {
    labelKey = "UI_PNC_Job_Lumber",
    requirements = {
        {
            role = "primary_tool",
            labelKey = "UI_PNC_JobRequirement_LumberTool",
            candidates = {
                "Base.Axe",
                "Base.HandAxe",
                "Base.WoodAxe",
                "Base.AxeStone",
            },
            quantity = 1,
            durable = true,
            equipSlot = "primary",
            validator = "lumber_tool",
        },
    },
})

return Registry
