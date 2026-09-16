-- Data-driven compatibility rules between semantic actions and entities.
--
-- The rules intentionally speak in capabilities (edible, drinkable, ...),
-- not item names or categories. MarketSense can provide those capabilities
-- without requiring this module to know its catalog.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Constraints = PNC.Semantics.ContextConstraints or {}
PNC.Semantics.ContextConstraints = Constraints

Constraints.VERSION = 1
Constraints.Actions = Constraints.Actions or {}

local function normalized(value)
    value = string.upper(tostring(value or ""))
    value = string.gsub(value, "[%s%-]+", "_")
    return value
end

local function copyList(value)
    if type(value) == "string" then return { normalized(value) } end
    if type(value) ~= "table" then return {} end
    local output = {}
    local index
    for index = 1, #value do output[index] = normalized(value[index]) end
    return output
end

local function copyMap(value)
    if type(value) ~= "table" then return {} end
    local output = {}
    local key
    local item
    for key, item in pairs(value) do output[key] = item end
    return output
end

function Constraints.RegisterAction(action, definition)
    action = normalized(action)
    if action == "" or type(definition) ~= "table" then
        return false, "invalid_action_constraint"
    end
    local stored = {
        action = action,
        requires = copyList(
            definition.requires or definition.requiredCapabilities
        ),
        conflicts = copyList(definition.conflicts),
        metadata = copyMap(definition.metadata),
    }
    Constraints.Actions[action] = stored
    return true, stored
end

function Constraints.GetAction(action)
    return Constraints.Actions[normalized(action)]
end

local function valueFromContainer(container, capability)
    if type(container) ~= "table" then return nil, false end
    if container[capability] ~= nil then return container[capability], true end
    local lower = string.lower(capability)
    if container[lower] ~= nil then return container[lower], true end
    if type(container.tags) == "table" then
        local nested, known = valueFromContainer(container.tags, capability)
        if known then return nested, true end
    end
    local index
    for index = 1, #container do
        if normalized(container[index]) == capability then return true, true end
    end
    return nil, false
end

local function capabilityValue(candidate, capability)
    if type(candidate) ~= "table" then return nil, false end
    capability = normalized(capability)
    local aliases = {
        string.lower(capability),
        capability,
    }
    local index
    local alias
    for index = 1, #aliases do
        alias = aliases[index]
        if candidate[alias] ~= nil then return candidate[alias], true end
    end

    local containers = {
        candidate.capabilities,
        candidate.tags,
        candidate.properties,
        candidate.marketSenseTags,
        candidate.itemTags,
        candidate.classification,
    }
    local container
    local value
    local known
    for index = 1, #containers do
        container = containers[index]
        value, known = valueFromContainer(container, capability)
        if known then return value, true end
    end
    return nil, false
end

function Constraints.Has(candidate, capability)
    return capabilityValue(candidate, capability)
end

function Constraints.Check(action, candidate)
    local definition = Constraints.GetAction(action)
    if not definition then return true, "no_constraint", {} end

    local details = {
        action = definition.action,
        required = {},
        satisfied = {},
        unknown = {},
        conflicts = {},
    }
    local index
    local requirement
    local value
    local known
    for index = 1, #definition.requires do
        requirement = definition.requires[index]
        details.required[#details.required + 1] = requirement
        value, known = capabilityValue(candidate, requirement)
        if known and value == false then
            details.conflicts[#details.conflicts + 1] = requirement
            return false, "capability_false", details
        elseif known and value ~= nil then
            details.satisfied[#details.satisfied + 1] = requirement
        else
            details.unknown[#details.unknown + 1] = requirement
        end
    end

    for index = 1, #definition.conflicts do
        requirement = definition.conflicts[index]
        value, known = capabilityValue(candidate, requirement)
        if known and value ~= false and value ~= nil then
            details.conflicts[#details.conflicts + 1] = requirement
            return false, "conflicting_capability", details
        end
    end

    if #details.unknown > 0 then return nil, "capability_unknown", details end
    return true, "compatible", details
end

-- Core action semantics. Domain modules can register additional actions or
-- replace these definitions without modifying the resolver.
Constraints.RegisterAction("EAT", { requires = { "edible" } })
Constraints.RegisterAction("DRINK", { requires = { "drinkable" } })
Constraints.RegisterAction("REFILL", { requires = { "refillable" } })
Constraints.RegisterAction("CONSUME", { requires = { "consumable" } })

return Constraints
