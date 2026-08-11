PNC = PNC or {}
PNC.ProvisionRuleRegistry = PNC.ProvisionRuleRegistry or {}

local Registry = PNC.ProvisionRuleRegistry

Registry.Modes = Registry.Modes or {
    THRESHOLD_TARGET = true,
    EXACT = true,
    MAXIMUM = true,
    CUSTOM = true,
}
Registry.Categories = Registry.Categories or {
    survival = { id = "survival", order = 10,
        labelKey = "UI_PNC_Provision_Category_Survival" },
    medical = { id = "medical", order = 20,
        labelKey = "UI_PNC_Provision_Category_Medical" },
    combat = { id = "combat", order = 30,
        labelKey = "UI_PNC_Provision_Category_Combat" },
    utility = { id = "utility", order = 40,
        labelKey = "UI_PNC_Provision_Category_Utility" },
    mission = { id = "mission", order = 50,
        labelKey = "UI_PNC_Provision_Category_Mission" },
}
Registry.ByID = Registry.ByID or {}

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

local function validID(value)
    return type(value) == "string" and value ~= ""
        and string.match(value, "^[%w_%-]+$") ~= nil
end

function Registry.RegisterCategory(definition)
    if type(definition) ~= "table" or not validID(definition.id) then
        return false, "category_invalid"
    end
    Registry.Categories[definition.id] = copy(definition)
    return true
end

function Registry.Register(definition)
    if type(definition) ~= "table" or not validID(definition.id) then
        return false, "rule_id_invalid"
    end
    if not Registry.Modes[definition.mode or "THRESHOLD_TARGET"] then
        return false, "rule_mode_invalid"
    end
    if type(definition.defaults) ~= "table"
        or type(definition.ui) ~= "table"
        or type(definition.ui.fields) ~= "table"
    then
        return false, "rule_definition_incomplete"
    end
    local normalized = copy(definition)
    normalized.mode = normalized.mode or "THRESHOLD_TARGET"
    normalized.category = normalized.category or normalized.ui.category
        or "utility"
    normalized.priority = math.max(0,
        math.min(100, tonumber(normalized.priority) or 30))
    Registry.ByID[normalized.id] = normalized
    return true
end

function Registry.Get(ruleID)
    local definition = Registry.ByID[tostring(ruleID or "")]
    return definition and copy(definition) or nil
end

function Registry.List()
    local output = {}
    for _, definition in pairs(Registry.ByID) do
        output[#output + 1] = copy(definition)
    end
    table.sort(output, function(left, right)
        local leftCategory = Registry.Categories[left.category] or {}
        local rightCategory = Registry.Categories[right.category] or {}
        local leftOrder = tonumber(leftCategory.order) or 999
        local rightOrder = tonumber(rightCategory.order) or 999
        if leftOrder ~= rightOrder then return leftOrder < rightOrder end
        local leftRuleOrder = tonumber(left.order) or 999
        local rightRuleOrder = tonumber(right.order) or 999
        if leftRuleOrder ~= rightRuleOrder then
            return leftRuleOrder < rightRuleOrder
        end
        return left.id < right.id
    end)
    return output
end

function Registry.ListCategories()
    local output = {}
    for _, definition in pairs(Registry.Categories) do
        output[#output + 1] = copy(definition)
    end
    table.sort(output, function(left, right)
        if left.order ~= right.order then return left.order < right.order end
        return left.id < right.id
    end)
    return output
end

function Registry.DefaultRule(ruleID)
    local definition = Registry.ByID[tostring(ruleID or "")]
    return definition and copy(definition.defaults) or nil
end

return Registry
