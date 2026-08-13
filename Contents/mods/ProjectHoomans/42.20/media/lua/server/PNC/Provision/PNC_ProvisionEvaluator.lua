if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.ProvisionEvaluator = PNC.ProvisionEvaluator or {}

local Evaluator = PNC.ProvisionEvaluator
local Registry = PNC.ProvisionRuleRegistry
local Resolver = PNC.ProvisionResolver
local SupplyInventory = PNC.SupplyInventory
local SupplyCommands = SupplyInventory.Commands or SupplyInventory
local SupplyQueries = SupplyInventory.Queries or SupplyInventory
local Metrics = PNC.SupplyMetrics
local Access = PNC.StorageAccessPolicy
local Selector = PNC.SupplySelector
local Index = PNC.SupplyIndex

local function ensurePersonalInventory(record)
    if SupplyCommands.EnsurePersonalInventory then
        SupplyCommands.EnsurePersonalInventory(record)
    end
end

local function provisionRuntime(record)
    record.runtime = record.runtime or {}
    record.runtime.provision = record.runtime.provision or {
        incoming = {}, refilling = {}, evaluations = {}, dirtyRules = {},
    }
    return record.runtime.provision
end

local function requestFor(definition)
    return {
        resourceKind = definition.resourceKind or definition.selector,
        treatment = definition.treatment,
        required = {},
    }
end

function Evaluator.Measure(record, definition)
    local request = requestFor(definition)
    ensurePersonalInventory(record)
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
    local runtime = provisionRuntime(record)
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

function Evaluator.MeasureStorage(storage)
    local output = {}
    if not storage or not storage.inventory then return output end
    for _, definition in ipairs(Registry.List()) do
        local request = requestFor(definition)
        local entries = Index.Query(storage, request)
        local amount = 0
        local calories = 0
        local items = {}
        for index = 1, #entries do
            local descriptor = entries[index].descriptor
            local quantity = math.max(1, tonumber(descriptor.quantity) or 1)
            if definition.measure == "HUNGER_UTILITY" then
                amount = amount + descriptor.hunger * quantity
                calories = calories + (tonumber(descriptor.calories) or 0)
                    * quantity
            elseif definition.measure == "THIRST_UTILITY" then
                amount = amount + descriptor.thirst
                    * math.max(0, tonumber(descriptor.remainingUses) or 0)
                    * quantity
            elseif definition.measure == "COUNT" then
                amount = amount + quantity
            end
            if #items < 12 then
                items[#items + 1] = {
                    fullType = descriptor.fullType,
                    quantity = quantity,
                    hunger = descriptor.hunger,
                    thirst = descriptor.thirst,
                    calories = descriptor.calories,
                    remainingUses = descriptor.remainingUses,
                }
            end
        end
        output[definition.id] = {
            amount = amount,
            calories = calories,
            candidateTypes = #entries,
            items = items,
        }
    end
    return output
end

local function personalItems(record, definition)
    local output = {}
    ensurePersonalInventory(record)
    local candidates = SupplyQueries.FindPersonal(
        record, requestFor(definition), 999999
    )
    for index = 1, math.min(#candidates, 12) do
        local descriptor = candidates[index].descriptor
        output[#output + 1] = {
            fullType = descriptor.fullType,
            quantity = descriptor.quantity,
            hunger = descriptor.hunger,
            thirst = descriptor.thirst,
            remainingUses = descriptor.remainingUses,
            bandage = descriptor.bandage == true,
            unsafe = descriptor.unsafe == true,
        }
    end
    return output
end

local function queued(record, ruleID)
    local scheduler = PNC.ProvisionScheduler
    for _, entry in ipairs(scheduler and scheduler.Queue or {}) do
        if tostring(entry.npcID) == tostring(record.id)
            and tostring(entry.ruleID) == tostring(ruleID)
        then
            return true, entry.readyAt
        end
    end
    return false, nil
end

function Evaluator.Inspect(record)
    if not record or record.alive == false then return nil, "npc_missing" end
    local storage, accessReason, community = Access.Resolve(record)
    if not community and PNC.Communities and PNC.Communities.GetNPCCommunity then
        community = PNC.Communities.GetNPCCommunity(record.id)
    end
    local home = community and community.home or nil
    local homeDistance
    if home and tonumber(record.x) and tonumber(record.y) and tonumber(record.z) then
        local dx = tonumber(record.x) - tonumber(home.x)
        local dy = tonumber(record.y) - tonumber(home.y)
        local dz = tonumber(record.z) - tonumber(home.z)
        homeDistance = math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    local output = {
        npcID = record.id,
        name = tostring(record.name or record.id),
        inventoryRevision = record.inventory and record.inventory.revision or 0,
        inventoryMode = PNC.Inventory.GetPersistenceMode(record),
        storageAccess = storage ~= nil,
        storageAccessReason = storage and "allowed"
            or tostring(accessReason or "unknown"),
        storageAccessMode = Access.GetAccessMode
            and Access.GetAccessMode() or "unknown",
        storageID = storage and storage.id or nil,
        location = { x = record.x, y = record.y, z = record.z },
        home = home,
        homeDistance = homeDistance,
        storageSummary = Evaluator.MeasureStorage(storage),
        rules = {},
        generatedAt = PNC.NeedsUtils.WorldAgeHours(),
    }
    for _, definition in ipairs(Registry.List()) do
        local evaluation, evaluationReason = Evaluator.Evaluate(
            record, definition
        )
        local isQueued, readyAt = queued(record, definition.id)
        local laneKind = definition.resourceKind or definition.selector
        local supply = record.runtime and record.runtime.supply
        local lane = supply and supply.byKind and supply.byKind[laneKind] or {}
        local rule = {
            id = definition.id,
            measure = definition.measure,
            evaluationReason = evaluationReason,
            enabled = evaluation and evaluation.enabled == true,
            onHand = evaluation and evaluation.onHand or 0,
            refillBelow = evaluation and evaluation.refillBelow or 0,
            target = evaluation and evaluation.target or 0,
            deficit = evaluation and evaluation.deficit or 0,
            refilling = evaluation and evaluation.refilling == true,
            queued = isQueued,
            readyAt = readyAt,
            personalItems = personalItems(record, definition),
            phase = lane.phase,
            lastResult = lane.lastResult,
            lastFailureReason = lane.lastFailureReason,
            nextRetry = lane.nextRetry,
            personalCandidateCount = lane.personalCandidateCount,
            storageCandidateCount = 0,
            selected = {},
        }
        if storage and evaluation and evaluation.deficit > 0 then
            local request = Evaluator.BuildRequest(
                record, definition, evaluation
            )
            if request then
                local selected, candidateCount = Selector.SelectFromStorage(
                    storage, request
                )
                rule.storageCandidateCount = candidateCount
                for index = 1, math.min(#selected, 8) do
                    rule.selected[#rule.selected + 1] = {
                        fullType = selected[index].descriptor.fullType,
                        quantity = selected[index].quantity,
                        hunger = selected[index].descriptor.hunger,
                        thirst = selected[index].descriptor.thirst,
                        remainingUses = selected[index].descriptor.remainingUses,
                        bandage = selected[index].descriptor.bandage == true,
                        unsafe = selected[index].descriptor.unsafe == true,
                    }
                end
            end
        end
        output.rules[#output.rules + 1] = rule
    end
    return output
end

return Evaluator
