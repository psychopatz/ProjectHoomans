if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Evaluator = PNC.ProvisionEvaluator
local H = Evaluator.Internal
local Registry = PNC.ProvisionRuleRegistry
local Resolver = PNC.ProvisionResolver
local SupplyInventory = PNC.SupplyInventory
local SupplyQueries = SupplyInventory.Queries or SupplyInventory
local Metrics = PNC.SupplyMetrics

function Evaluator.Measure(record, definition)
    local request = H.RequestFor(definition)
    H.EnsurePersonalInventory(record)
    local candidates = SupplyQueries.FindPersonal(record, request, 999999)
    local amount = 0
    for _, candidate in ipairs(candidates) do
        local descriptor = candidate.descriptor
        local quantity = math.max(1, tonumber(descriptor.quantity) or 1)
        if definition.measure == "HUNGER_UTILITY" then
            amount = amount + descriptor.hunger * quantity
        elseif definition.measure == "THIRST_UTILITY" then
            amount = amount + descriptor.thirst
                * math.max(0, tonumber(descriptor.remainingUses) or 0)
                * quantity
        elseif definition.measure == "COUNT" then
            amount = amount + quantity
        end
    end
    return amount
end

function Evaluator.Evaluate(record, ruleOrID)
    local definition = type(ruleOrID) == "table" and ruleOrID
        or Registry.Get(ruleOrID)
    if not record or record.alive == false then return nil, "npc_missing" end
    if not definition then return nil, "unknown_rule" end
    local values, source = Resolver.GetEffectiveRule(record, definition.id)
    if not values then return nil, source end
    Metrics.Set("provisionPolicyRevision", source.revision or 0)
    local runtime = H.ProvisionRuntime(record)
    local onHand = Evaluator.Measure(record, definition)
    local incoming = math.max(0,
        tonumber(runtime.incoming[definition.id]) or 0)
    local available = onHand + incoming
    local target = math.max(0, tonumber(values.target) or 0)
    local threshold = math.max(0, tonumber(values.refillBelow) or 0)
    local refilling = runtime.refilling[definition.id] == true
    if values.enabled ~= true then
        refilling = false
    elseif definition.mode == "THRESHOLD_TARGET" then
        -- Authoritative threshold semantic: a refill starts only when the
        -- available amount is strictly less than refillBelow.
        if available < threshold then refilling = true end
        if available >= target then refilling = false end
    elseif definition.mode == "EXACT" then
        refilling = available ~= target
    elseif definition.mode == "MAXIMUM" then
        refilling = false
    elseif definition.evaluate then
        refilling = definition.evaluate(record, values, available) == true
    end
    runtime.refilling[definition.id] = refilling
    local deficit = refilling and math.max(0, target - available) or 0
    local result = {
        ruleId = definition.id,
        mode = definition.mode,
        measure = definition.measure,
        enabled = values.enabled == true,
        satisfied = deficit <= 0,
        refilling = refilling,
        onHand = onHand,
        incoming = incoming,
        refillBelow = threshold,
        target = target,
        deficit = deficit,
        policyRevision = source.revision,
        policySource = source.source,
        evaluatedAt = PNC.NeedsUtils.WorldAgeHours(),
    }
    runtime.evaluations[definition.id] = result
    runtime.lastEvaluation = result.evaluatedAt
    Metrics.Increment("provisionRulesEvaluated")
    Metrics.Increment(result.satisfied and "provisionRulesSatisfied"
        or "provisionRulesDeficient")
    return result
end

function Evaluator.BuildRequest(record, definition, evaluation)
    if not evaluation or evaluation.deficit <= 0 then return nil end
    local required = {}
    if definition.measure == "HUNGER_UTILITY" then
        required.hunger = evaluation.deficit
        required.thirst = 0
    elseif definition.measure == "THIRST_UTILITY" then
        required.thirst = evaluation.deficit
    else
        required.count = math.max(1, math.ceil(evaluation.deficit))
    end
    return {
        requesterId = record.id,
        purpose = "PROVISION",
        resourceKind = definition.resourceKind or definition.selector,
        treatment = definition.treatment,
        required = required,
        target = evaluation.target,
        priority = definition.priority,
        sourcePolicy = definition.sourcePolicy or "CURRENT_BASE",
        fulfillment = definition.fulfillment or "INSTANT",
    }
end

function Evaluator.GetDebugState(record)
    local runtime = record and record.runtime and record.runtime.provision
    return runtime and PNC.Core.DeepCopy(runtime) or {
        incoming = {}, refilling = {}, evaluations = {}, dirtyRules = {},
    }
end
