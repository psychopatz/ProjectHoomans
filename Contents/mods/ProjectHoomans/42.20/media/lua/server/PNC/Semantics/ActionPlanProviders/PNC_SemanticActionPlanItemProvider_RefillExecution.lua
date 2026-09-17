-- Authoritative REFILL execution after a queued MOVE_TO step.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Provider = PNC.Semantics.ActionPlanItemProvider
local Support = Provider.ConsumptionSupport
local Water = PNC.WaterContainerService
local NearbyWater = PNC.NearbyWaterService

local function refillContext(record, plan)
    local policy = PNC.WaterHydrationPolicy
    if not policy or not policy.GetContext then
        return nil, "WATER_POLICY_UNAVAILABLE"
    end
    local manualOverride = type(plan) == "table"
        and plan.manualOverride == true
    return policy.GetContext(record, { manualOverride = manualOverride })
end

local function refillSelection(plan, step, record)
    local context, contextReason = refillContext(record, plan)
    if not context then return nil, contextReason end
    local selection, reason = Support.Select(record, step)
    local item
    if selection and Water and type(Water.FindContainer) == "function" then
        item, reason = Water.FindContainer(record, selection.itemID)
        if item then return selection, "matched" end
    end
    -- Preserve the existing authoritative fallback for records that have not
    -- received a MarketSense classification yet.
    if Water and type(Water.ResolveHydrationPlan) == "function" then
        local hydration, hydrationReason = Water.ResolveHydrationPlan(
            record, "refill")
        if type(hydration) == "table" and hydration.containerID then
            return {
                itemID = tostring(hydration.containerID),
                fullType = hydration.activityItemFullType
                    or hydration.container and hydration.container.type,
                available = 1, quantity = 1,
            }, "hydration_fallback"
        end
        reason = hydrationReason or reason
    end
    return nil, reason or "WATER_CONTAINER_NOT_REFILLABLE"
end

local function previousMove(plan)
    local steps = plan and plan.steps or {}
    local current = tonumber(plan and plan.currentStep) or #steps + 1
    for index = current - 1, 1, -1 do
        local step = steps[index]
        if step and step.action == "MOVE_TO" then return step end
    end
end

local function resolve(plan, step, record)
    local selection, reason = refillSelection(plan, step, record)
    Support.Audit("semantic.refill.resolve", plan, step, {
        status = selection and "resolved" or "failed",
        reason = reason,
        itemID = selection and selection.itemID,
        fullType = selection and selection.fullType,
    })
    return selection, reason
end

local function execute(plan, step, record)
    local context, contextReason = refillContext(record, plan)
    if not context then
        return { blocked = true, reason = contextReason }
    end
    local assignment = step and step.assignment
    local selection, reason = refillSelection(plan, step, record)
    local item
    local move = previousMove(plan)
    local moveAssignment = move and move.assignment
    local sourceKey = moveAssignment
        and (moveAssignment.resourceKey or moveAssignment.targetID)
    local source
    local amount
    local resultItemID
    local ok
    if type(assignment) == "table" and assignment.itemID
        and (not selection or tostring(selection.itemID)
            ~= tostring(assignment.itemID))
    then selection, reason = Support.Select(record, step, assignment) end
    if not selection then
        return { blocked = true, reason = reason or "item_not_found" }
    end
    if not Water or type(Water.FindContainer) ~= "function"
        or type(Water.Refill) ~= "function"
    then return { blocked = true, reason = "water_container_service_unavailable" }
    end
    item, reason = Water.FindContainer(record, selection.itemID)
    if not item then
        return { blocked = true,
            reason = reason or "WATER_CONTAINER_NOT_REFILLABLE" }
    end
    if not sourceKey or tostring(sourceKey) == "" then
        return { blocked = true, reason = "refill_source_assignment_missing" }
    end
    if not NearbyWater or type(NearbyWater.ResolveFillSource)
        ~= "function"
    then return { blocked = true, reason = "water_service_unavailable" }
    end
    source, reason = NearbyWater.ResolveFillSource(record, sourceKey)
    if not source then
        return { blocked = true,
            reason = reason or "WATER_FILL_SOURCE_UNAVAILABLE" }
    end
    ok, amount, resultItemID = Water.Refill(record, item.id, source)
    Support.Audit("semantic.refill.commit", plan, step, {
        status = ok == true and "completed" or "failed",
        reason = ok == true and nil or amount,
        itemID = resultItemID or item.id,
        sourceKey = source.key,
        amount = ok == true and amount or nil,
    })
    if ok ~= true then
        return { blocked = true, reason = amount or "WATER_REFILL_FAILED" }
    end
    if PNC.NeedFacilityEffects
        and PNC.NeedFacilityEffects.ApplyWaterRefillSuccess
    then
        PNC.NeedFacilityEffects.ApplyWaterRefillSuccess(record, {
            activityItemID = resultItemID or item.id,
            activityItemFullType = item.type or item.fullType,
            resourceKey = source.key,
        }, amount)
    end
    return {
        complete = true,
        result = {
            itemID = resultItemID or item.id,
            fullType = item.type or item.fullType,
            sourceKey = source.key,
            amount = tonumber(amount) or 0,
        },
    }
end

Provider.Refill = Provider.Refill or {}
function Provider.Refill.Resolve(plan, step, record)
    return resolve(plan, step, record)
end
function Provider.Refill.Start(plan, step, record)
    return execute(plan, step, record)
end
function Provider.Refill.Tick(plan, step, record)
    return execute(plan, step, record)
end

return Provider.Refill
