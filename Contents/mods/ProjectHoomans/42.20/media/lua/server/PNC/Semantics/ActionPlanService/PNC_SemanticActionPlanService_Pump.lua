-- Bounded orchestration pump for semantic action plans.
-- A provider owns the actual task, path, inventory, or dialogue effect.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.Semantics.ActionPlanService
local Plan = PNC.Semantics.ActionPlan
local Internal = Service.Internal
local PlanInternal = Plan.Internal
local Trace = PsychopatzCore and PsychopatzCore.DebugTrace

local function traceProgress(plan, event, cause)
    if not Trace or type(Trace.IsEnabled) ~= "function"
        or Trace.IsEnabled() ~= true
        or type(Trace.Record) ~= "function"
    then
        return false
    end
    local step = Plan.Current(plan)
    local diagnostics = step and step.diagnostics or nil
    Trace.Record({
        source = "ProjectHoomans.Semantics",
        event = event or "semantic.action_plan.progress",
        requestID = plan and plan.requestID,
        data = {
            planID = plan and plan.planID,
            npcID = plan and plan.npcID,
            planState = plan and plan.state,
            currentStep = plan and plan.currentStep,
            stepID = step and step.id,
            action = step and step.action,
            stepState = step and step.state,
            cause = cause,
            reason = diagnostics and diagnostics.reason,
        },
    })
    return true
end

local function providerFor(step)
    return step and Service.GetProvider(step.action) or nil
end

local function outcomeTable(outcome)
    if type(outcome) == "string" then return { state = outcome } end
    return type(outcome) == "table" and outcome or nil
end

local function applyOutcome(plan, step, outcome, at)
    local normalized = outcomeTable(outcome)
    local nextState
    local details
    local changed
    local reason
    local leaseID
    local normalizedLeaseID
    if not normalized then return false, "provider_outcome_missing" end

    details = normalized.details or normalized.diagnostics
    if normalized.failed == true then
        return Plan.Fail(plan, normalized.reason or "provider_failed", at)
    end
    if normalized.blocked == true then
        return Plan.SetStepState(plan, "BLOCKED", {
            reason = tostring(normalized.reason or "provider_blocked"),
            details = details,
        }, at)
    end

    leaseID = normalized.leaseID or normalized.leaseId
    if leaseID ~= nil then
        normalizedLeaseID = PlanInternal.NormalizeID(leaseID, nil)
        if not normalizedLeaseID then return false, "provider_lease_id_invalid" end
        step.leaseID = normalizedLeaseID
    end

    nextState = normalized.state or normalized.phase
    if normalized.complete == true then nextState = "COMPLETED" end
    if not nextState then
        return false, "provider_state_missing"
    end
    nextState = PlanInternal.NormalizeState(
        nextState, Plan.STEP_STATES, nil)
    if not nextState then return false, "provider_state_invalid" end

    changed, reason = Plan.SetStepState(plan, nextState, details, at)
    if not changed then return false, reason end
    if nextState == "COMPLETED" then
        changed, reason = Plan.Advance(plan, normalized.result, at)
        if not changed then return false, reason end
    end
    return true, plan
end

local function failProvider(plan, reason, at)
    local failed, failureReason = Plan.Fail(plan, reason, at)
    if not failed then return false, failureReason end
    return true, plan
end

local function processPlan(plan, record, at)
    local step = Plan.Current(plan)
    local provider
    local callbackOK
    local value
    local reason
    local changed
    if not step then return failProvider(plan, "current_step_missing", at) end
    if plan.state ~= "RUNNING" or step.state == "PAUSED"
        or step.state == "BLOCKED"
    then
        return false, "plan_not_ready"
    end
    if step.state == "PENDING" then
        return Plan.SetStepState(plan, "RESOLVING", nil, at)
    end

    provider = providerFor(step)
    if not provider then
        changed, reason = Plan.SetStepState(plan, "BLOCKED", {
            reason = "action_provider_missing",
            action = step.action,
        }, at)
        return changed, reason
    end

    if step.state == "RESOLVING" then
        callbackOK, value, reason = Internal.SafeCall(
            provider.Resolve, plan, step, record)
        if not callbackOK then
            return failProvider(plan, "provider_resolve_failed", at)
        end
        if value == nil or value == false then
            return Plan.SetStepState(plan, "BLOCKED", {
                reason = tostring(reason or "target_unresolved"),
                action = step.action,
            }, at)
        end
        changed, reason = Plan.SetStepAssignment(plan, value, at)
        if not changed then return false, reason end
        return Plan.SetStepState(plan, "ASSIGNED", {
            resolved = true,
            action = step.action,
        }, at)
    end

    if step.state == "ASSIGNED" then
        callbackOK, value, reason = Internal.SafeCall(
            provider.Start, plan, step, record)
    else
        callbackOK, value, reason = Internal.SafeCall(
            provider.Tick, plan, step, record)
    end
    if not callbackOK then
        return failProvider(plan, "provider_execution_failed", at)
    end
    if value == false or value == nil then
        return Plan.SetStepState(plan, "BLOCKED", {
            reason = tostring(reason or "provider_waiting"),
            action = step.action,
        }, at)
    end
    return applyOutcome(plan, step, value, at)
end

function Service.Report(planID, stepID, outcome, at)
    local plan = Service.ByID[Internal.Key(planID)]
    local step = plan and Plan.Current(plan) or nil
    local changed
    local reason
    if not plan then return false, "plan_not_found" end
    if not step or tostring(step.id) ~= tostring(stepID or "") then
        return false, "stale_plan_step"
    end
    if plan.state ~= "RUNNING" then return false, "plan_not_running" end
    changed, reason = applyOutcome(plan, step, outcome,
        tonumber(at) or Internal.Now())
    if not changed then return false, reason end
    Internal.MarkDirty(plan)
    Internal.Emit("SEMANTIC_ACTION_PLAN_STEP_CHANGED", plan, "reported")
    if Internal.Terminal(plan) then
        Service.ClearRuntimeContext(plan.planID)
        Internal.RemoveActive(plan.planID)
    end
    return true, plan
end

function Service.Pump(at, budget)
    at = tonumber(at) or Internal.Now()
    if at < (tonumber(Service.NextPumpAt) or 0) then return 0 end
    Service.NextPumpAt = at + Service.PUMP_INTERVAL_MS

    if at >= (tonumber(Service.NextReconcileAt) or 0) then
        Service.NextReconcileAt = at + Service.RECONCILE_INTERVAL_MS
        Service.ReconcileIndex()
    end

    local maximum = math.max(1, math.floor(tonumber(budget)
        or Service.MAX_ACTIVE_PLANS_PER_PUMP))
    local snapshotCount = math.min(#Service.Active, maximum)
    local processed = 0
    for _ = 1, snapshotCount do
        if #Service.Active <= 0 then break end
        Service.ActiveCursor = (Service.ActiveCursor % #Service.Active) + 1
        local planID = Service.Active[Service.ActiveCursor]
        local plan = Service.ByID[planID]
        local record = plan and PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(plan.npcID) or nil
        if not plan then
            Internal.RemoveActive(planID)
        elseif Internal.Terminal(plan) then
            Service.ClearRuntimeContext(plan.planID)
            Internal.RemoveActive(plan.planID)
        elseif not record or record.alive == false then
            local changed = Plan.Fail(plan, "npc_unavailable", at)
            if changed then
                Internal.MarkDirty(plan)
                traceProgress(plan, "semantic.action_plan.progress",
                    "npc_unavailable")
            end
            Service.ClearRuntimeContext(plan.planID)
            Internal.RemoveActive(plan.planID)
        else
            local changed = processPlan(plan, record, at)
            if changed then
                Internal.MarkDirty(plan)
                Internal.Emit("SEMANTIC_ACTION_PLAN_STEP_CHANGED",
                    plan, "pump")
                traceProgress(plan, "semantic.action_plan.progress", "pump")
            end
            if Internal.Terminal(plan)
                or (Plan.Current(plan)
                    and (Plan.Current(plan).state == "BLOCKED"
                        or Plan.Current(plan).state == "PAUSED"))
            then
                if Internal.Terminal(plan) then
                    Service.ClearRuntimeContext(plan.planID)
                end
                Internal.RemoveActive(plan.planID)
            end
            processed = processed + 1
        end
    end
    return processed
end

Service.Internal.ApplyOutcome = applyOutcome
Service.Internal.ProcessPlan = processPlan

return Service
