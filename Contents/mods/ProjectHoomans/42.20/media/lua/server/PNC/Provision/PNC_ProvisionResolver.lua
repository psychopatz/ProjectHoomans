if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.ProvisionResolver = PNC.ProvisionResolver or {}

local Resolver = PNC.ProvisionResolver
local Policy = PNC.ProvisionPolicy
local Registry = PNC.ProvisionRuleRegistry

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function overlay(target, source)
    for ruleID, values in pairs(type(source) == "table" and source or {}) do
        if ruleID ~= "parentPolicyId" and type(values) == "table" then
            target[ruleID] = target[ruleID] or {}
            for fieldID, value in pairs(values) do
                target[ruleID][fieldID] = copy(value)
            end
        end
    end
end

function Resolver.GetEffectivePolicy(record)
    if not record then return nil, "npc_missing" end
    local faction, reason = PNC.Factions.GetNPCFaction(record.id)
    if not faction then return nil, reason end
    local provision = Policy.Normalize(faction.provision)
    local source = provision.policies.default or {}
    local effective = {
        schemaVersion = provision.schemaVersion,
        revision = provision.revision,
        policyId = "default",
        source = "faction_default",
        rules = {},
    }
    for _, definition in ipairs(Registry.List()) do
        effective.rules[definition.id] = copy(
            source[definition.id] or definition.defaults
        )
    end
    -- Reserved sparse overlays. They are not populated or persisted by the
    -- initial UI, but establish faction -> role -> NPC resolution order.
    local role = record.affiliation and record.affiliation.role
    local rolePolicy = role and provision.policies["role:" .. role] or nil
    if rolePolicy then
        overlay(effective.rules, rolePolicy)
        effective.source = "role_override"
    end
    if type(record.provisionOverrides) == "table" then
        overlay(effective.rules, record.provisionOverrides)
        effective.source = "npc_override"
    end
    return effective
end

function Resolver.GetEffectiveRule(record, ruleID)
    local policy, reason = Resolver.GetEffectivePolicy(record)
    if not policy then return nil, reason end
    local values = policy.rules[tostring(ruleID or "")]
    if not values then return nil, "unknown_rule" end
    return copy(values), {
        policyId = policy.policyId,
        revision = policy.revision,
        source = policy.source,
    }
end

return Resolver
