-- Bounded orchestration pump for semantic action plans.
-- A provider owns the actual task, path, inventory, or dialogue effect.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.Semantics.ActionPlanService
local Plan = PNC.Semantics.ActionPlan
local Internal = Service.Internal
local PlanInternal = Plan.Internal
require "PNC/Semantics/PNC_SemanticDiagnostics"
local Trace = PsychopatzCore and PsychopatzCore.DebugTrace
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local ActorControl = PNC.ActorControl

local function bounded(value, maximum)
    if value == nil then return nil end
    value = tostring(value)
    maximum = tonumber(maximum) or 128
    return string.sub(value, 1, maximum)
end

local function auditResultDelivery(plan, status, accepted, reason, sent)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    local metadata = plan and plan.metadata or {}
    return Diagnostics.Record("semantic.task.result_dispatch", {
        npcID = plan and plan.npcID,
        requestID = plan and plan.requestID,
        planID = plan and plan.planID,
        action = metadata.taskAction,
        status = status,
        accepted = accepted == true,
        reason = reason,
        sent = sent == true,
    }, { requestID = plan and plan.requestID })
end

local function notifyTaskResult(plan, status, accepted, reason)
    local runtime = Service.GetRuntimeContext(plan and plan.planID)
    local player = runtime and runtime.player
    local command = PNC.Const
        and PNC.Const.CMD_SEMANTIC_TASK_RESULT or nil
    if not player or type(sendServerCommand) ~= "function"
        or not command
    then
        auditResultDelivery(plan, status, accepted, reason, false)
        return false
    end
    local metadata = plan and plan.metadata or {}
    sendServerCommand(player, PNC.Const.MODULE, command, {
        requestID = bounded(plan and plan.requestID, 128),
        npcID = bounded(plan and plan.npcID, 128),
        action = bounded(metadata.taskAction, 32),
        planID = bounded(plan and plan.planID, 160),
        accepted = accepted == true,
        status = bounded(status, 32),
        reason = bounded(reason, 128),
        siteLabel = bounded(metadata.siteLabel, 64),
        siteScope = bounded(metadata.siteScope, 16),
        siteID = bounded(metadata.siteID, 128),
        siteRoomType = bounded(metadata.siteRoomType, 48),
        siteRisk = bounded(metadata.siteRisk, 32),
    })
    auditResultDelivery(plan, status, accepted, reason, true)
    return true
end

local function traceProgress(plan, event, cause)
    local semanticAudit = Diagnostics
        and type(Diagnostics.IsEnabled) == "function"
        and Diagnostics.IsEnabled() == true
    local legacyTrace = Trace
        and type(Trace.IsEnabled) == "function"
        and Trace.IsEnabled() == true
        and type(Trace.Record) == "function"
    if not semanticAudit and not legacyTrace
    then
        return false
    end
    local step = Plan.Current(plan)
    local diagnostics = step and step.diagnostics or nil
    local assignment = step and step.assignment or nil
    local definition = {
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
            assignmentX = assignment and assignment.x,
            assignmentY = assignment and assignment.y,
            assignmentZ = assignment and assignment.z,
            targetID = assignment and assignment.targetID,
        },
    }
    if semanticAudit then
        Diagnostics.Record(
            definition.event,
            definition.data,
            {
                requestID = definition.requestID,
                dedupeKey = tostring(definition.data.planID or "") .. "|"
                    .. tostring(definition.data.stepID or "") .. "|"
                    .. tostring(definition.data.stepState or "") .. "|"
                    .. tostring(definition.data.reason or ""),
                consoleIntervalMs = 250,
            }
        )
    else
        Trace.Record(definition)
    end
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
        notifyTaskResult(
            plan,
            plan.state == "COMPLETED" and "completed" or "failed",
            plan.state == "COMPLETED",
            step.diagnostics and step.diagnostics.reason
                or plan.failureReason
        )
    elseif Plan.Current(plan)
        and Plan.Current(plan).state == "BLOCKED"
    then
        local current = Plan.Current(plan)
        notifyTaskResult(plan, "blocked", false,
            current.diagnostics and current.diagnostics.reason)
    end
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
                notifyTaskResult(plan, "failed", false, "npc_unavailable")
            end
            Service.ClearRuntimeContext(plan.planID)
            Internal.RemoveActive(plan.planID)
        elseif ActorControl and ActorControl.IsPuppetOwned
            and ActorControl.IsPuppetOwned(record)
        then
            -- Keep the durable plan and its provider context intact while
            -- Puppet Opera temporarily owns the live actor. Its normal
            -- executor will resume after the presentation lease is released.
        else
            local changed = processPlan(plan, record, at)
            if changed then
                Internal.MarkDirty(plan)
                Internal.Emit("SEMANTIC_ACTION_PLAN_STEP_CHANGED",
                    plan, "pump")
                traceProgress(plan, "semantic.action_plan.progress", "pump")
                local current = Plan.Current(plan)
                local diagnostics = current and current.diagnostics or nil
                local blocked = current and current.state == "BLOCKED"
                if Internal.Terminal(plan) or blocked then
                    notifyTaskResult(
                        plan,
                        Internal.Terminal(plan) and plan.state == "COMPLETED"
                            and "completed"
                            or Internal.Terminal(plan) and "failed"
                            or "blocked",
                        plan.state == "COMPLETED",
                        diagnostics and diagnostics.reason
                    )
                end
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
Service.Internal.NotifyTaskResult = notifyTaskResult

return Service
