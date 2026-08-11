PNC = PNC or {}
PNC.ProvisionPolicy = PNC.ProvisionPolicy or {}

local Policy = PNC.ProvisionPolicy
local Registry = PNC.ProvisionRuleRegistry

Policy.SCHEMA_VERSION = 2
Policy.DEFAULT_POLICY_ID = "default"

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then return nil end
    return value
end

local function fieldByID(definition, fieldID)
    for _, field in ipairs(definition.ui.fields or {}) do
        if field.id == fieldID then return field end
    end
    return nil
end

function Policy.ValidateRule(ruleID, values, strict, sparse)
    local definition = Registry.Get(ruleID)
    if not definition then return nil, "unknown_rule" end
    if type(values) ~= "table" then return nil, "rule_values_invalid" end
    local output = {}
    for key, value in pairs(values) do
        if key == "enabled" then
            if type(value) ~= "boolean" then
                return nil, "field_type_invalid"
            end
            output.enabled = value
        else
            local field = fieldByID(definition, key)
            if not field then
                if strict then return nil, "unknown_field" end
            elseif field.type == "number" then
                local number = finite(value)
                if not number then return nil, "field_type_invalid" end
                if number < (tonumber(field.min) or -math.huge)
                    or number > (tonumber(field.max) or math.huge)
                then return nil, "field_out_of_range" end
                output[key] = number
            else
                return nil, "field_type_invalid"
            end
        end
    end
    local defaults = definition.defaults or {}
    if not sparse then
        if output.enabled == nil then output.enabled = defaults.enabled == true end
        for _, field in ipairs(definition.ui.fields or {}) do
            if output[field.id] == nil then output[field.id] = defaults[field.id] end
        end
    end
    if definition.mode == "THRESHOLD_TARGET"
        and output.target ~= nil and output.refillBelow ~= nil
        and output.target < output.refillBelow
    then return nil, "target_below_refill" end
    return output
end

function Policy.Defaults(revision)
    local default = { parentPolicyId = nil }
    for _, definition in ipairs(Registry.List()) do
        default[definition.id] = copy(definition.defaults)
    end
    return {
        schemaVersion = Policy.SCHEMA_VERSION,
        revision = math.max(1, math.floor(tonumber(revision) or 1)),
        policies = { [Policy.DEFAULT_POLICY_ID] = default },
    }
end

function Policy.Normalize(value)
    local source = type(value) == "table" and value or {}
    local output = Policy.Defaults(source.revision)
    local sourcePolicies = type(source.policies) == "table"
        and source.policies or {}
    for policyID, sourcePolicy in pairs(sourcePolicies) do
        if type(policyID) == "string" and type(sourcePolicy) == "table" then
            local target = { parentPolicyId = type(sourcePolicy.parentPolicyId)
                == "string" and sourcePolicy.parentPolicyId or nil }
            for _, definition in ipairs(Registry.List()) do
                local values = sourcePolicy[definition.id]
                if tonumber(source.schemaVersion) == 1
                    and (definition.measure == "HUNGER_UTILITY"
                        or definition.measure == "THIRST_UTILITY")
                    and type(values) == "table"
                then
                    values = copy(values)
                    if tonumber(values.refillBelow) then
                        values.refillBelow = values.refillBelow / 100
                    end
                    if tonumber(values.target) then
                        values.target = values.target / 100
                    end
                end
                local normalized = values and Policy.ValidateRule(
                    definition.id, values, false,
                    policyID ~= Policy.DEFAULT_POLICY_ID) or nil
                if normalized then target[definition.id] = normalized
                elseif policyID == Policy.DEFAULT_POLICY_ID then
                    target[definition.id] = copy(definition.defaults)
                end
            end
            output.policies[policyID] = target
        end
    end
    return output
end

function Policy.ValidateSubmission(value)
    if type(value) ~= "table" then return nil, "policy_invalid" end
    if tonumber(value.schemaVersion) ~= Policy.SCHEMA_VERSION then
        return nil, "schema_invalid"
    end
    if type(value.policyId) ~= "string"
        or value.policyId ~= Policy.DEFAULT_POLICY_ID
    then return nil, "policy_id_invalid" end
    if type(value.rules) ~= "table" then return nil, "rules_invalid" end
    local rules = {}
    for ruleID, values in pairs(value.rules) do
        if not Registry.Get(ruleID) then return nil, "unknown_rule" end
        local normalized, reason = Policy.ValidateRule(ruleID, values, true)
        if not normalized then return nil, reason end
        rules[ruleID] = normalized
    end
    for _, definition in ipairs(Registry.List()) do
        if not rules[definition.id] then return nil, "rule_missing" end
    end
    return { policyId = value.policyId, rules = rules }
end

function Policy.GetRule(value, policyID, ruleID)
    local normalized = Policy.Normalize(value)
    local policy = normalized.policies[policyID or Policy.DEFAULT_POLICY_ID]
    return policy and policy[ruleID] and copy(policy[ruleID]) or nil
end

return Policy
