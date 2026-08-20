PNC = PNC or {}
PNC.FacilityComponentPolicy = PNC.FacilityComponentPolicy or {}

local Policy = PNC.FacilityComponentPolicy

local DEFAULT_COSTS = {
    { fullType = "Base.Money", amount = 1 },
}

local function copyCosts(costs)
    local output = {}
    for _, cost in ipairs(costs or {}) do
        output[#output + 1] = {
            fullType = tostring(cost.fullType or "Base.Money"),
            amount = math.max(1, math.floor(
                tonumber(cost.amount or cost.quantity) or 1)),
        }
    end
    return output
end

local function componentConfig(definition, levelData, field, role)
    local levelConfig = levelData and levelData[field]
    local definitionConfig = definition and definition[field]
    local key = tostring(role or "")
    local value = levelConfig and levelConfig[key]
    if value ~= nil then return value end
    return definitionConfig and definitionConfig[key] or nil
end

function Policy.GetCosts(definition, levelData, role)
    return copyCosts(componentConfig(
        definition, levelData, "componentCosts", role) or DEFAULT_COSTS)
end

function Policy.GetBuildWork(definition, levelData, role)
    local work = componentConfig(definition, levelData, "componentWork", role)
    return math.max(1, tonumber(work) or 40)
end

function Policy.RequiresConstruction(definition, levelData, role, kind)
    local config = definition and definition.componentConstruction
    local levelConfig = levelData and levelData.componentConstruction
    local value = levelConfig and levelConfig[tostring(role or "")]
    if value == nil then
        value = config and config[tostring(role or "")]
    end
    if value == nil then
        value = levelConfig and levelConfig.default
    end
    if value == nil then
        value = config and config.default
    end
    if value == nil then value = true end
    return value ~= false
end

function Policy.DescribeCosts(costs)
    local output = {}
    for _, cost in ipairs(costs or {}) do
        output[#output + 1] = tostring(cost.amount or 1) .. "x "
            .. tostring(cost.fullType or "Base.Money")
    end
    return table.concat(output, ", ")
end

return Policy
