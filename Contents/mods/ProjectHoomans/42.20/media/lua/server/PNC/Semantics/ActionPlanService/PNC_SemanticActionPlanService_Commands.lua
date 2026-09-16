-- Submission, lifecycle commands, persistence attachment, and queries.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.Semantics.ActionPlanService
local Internal = Service.Internal
local Plan = Internal.Plan
local key = Internal.Key
local now = Internal.Now
local terminal = Internal.Terminal
local addActive = Internal.AddActive
local removeActive = Internal.RemoveActive
local markDirty = Internal.MarkDirty
local emit = Internal.Emit
local safeCall = Internal.SafeCall
local replaceIndexes = Internal.ReplaceIndexes

function Service.Attach(record)
    local raw = record and record.semanticActionPlan
    local plan
    local reason
    if type(raw) ~= "table" or key(record.id) == "" then return nil end
    plan, reason = Plan.Normalize(raw)
    if not plan then
        record.semanticActionPlan = nil
        return nil, reason
    end
    plan.npcID = key(record.id)
    record.semanticActionPlan = plan
    replaceIndexes(plan, Service.ByNPC[plan.npcID])
    return plan
end

function Service.Submit(raw, context)
    local plan
    local reason
    local record
    local previous
    local started
    if not (PNC.Core and (not PNC.Core.IsAuthority
        or PNC.Core.IsAuthority() == true))
    then
        return false, "server_authority_required"
    end
    plan, reason = Plan.Normalize(raw)
    if not plan then return false, reason end
    record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(plan.npcID) or nil
    if not record or record.alive == false then
        return false, "npc_not_found"
    end
    previous = Service.ByNPC[plan.npcID]
    if previous and not terminal(previous) then
        return false, "npc_action_plan_active"
    end
    started, reason = Plan.Start(plan, now())
    if not started then return false, reason end
    record.semanticActionPlan = plan
    replaceIndexes(plan, previous)
    -- Keep live request context outside the persisted plan. Providers may use
    -- it for dynamic targets, while serialization remains primitive-only.
    Service.SetRuntimeContext(plan.planID, context)
    markDirty(plan)
    emit("SEMANTIC_ACTION_PLAN_SUBMITTED", plan, "submitted")
    return true, plan
end

function Service.Get(npcID)
    local id = key(npcID)
    local plan = Service.ByNPC[id]
    if not plan and PNC.Registry and PNC.Registry.Get then
        plan = Service.Attach(PNC.Registry.Get(id))
    end
    return plan and Plan.Clone(plan) or nil
end

function Service.GetMutable(npcID)
    return Service.ByNPC[key(npcID)]
end

function Service.Cancel(npcID, reason)
    local plan = Service.ByNPC[key(npcID)]
    local record
    local provider
    local step
    local ok
    local result
    local callbackReason
    if not plan then return false, "plan_not_found" end
    if terminal(plan) then return false, "plan_terminal" end
    record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(plan.npcID) or nil
    step = Plan.Current(plan)
    provider = step and Service.GetProvider(step.action) or nil
    if provider and provider.Cancel then
        ok, result, callbackReason = safeCall(
            provider.Cancel, plan, step, record, reason)
        if not ok or result == false then
            return false, callbackReason or "provider_cancel_rejected"
        end
    end
    ok, result = Plan.Cancel(plan, reason, now())
    if not ok then return false, result end
    Service.ClearRuntimeContext(plan.planID)
    removeActive(plan.planID)
    markDirty(plan)
    emit("SEMANTIC_ACTION_PLAN_CANCELLED", plan, reason or "cancelled")
    return true, plan
end

function Service.Pause(npcID, reason)
    local plan = Service.ByNPC[key(npcID)]
    local ok
    local result
    if not plan then return false, "plan_not_found" end
    ok, result = Plan.Pause(plan, reason, now())
    if not ok then return false, result end
    removeActive(plan.planID)
    markDirty(plan)
    emit("SEMANTIC_ACTION_PLAN_PAUSED", plan, reason or "paused")
    return true, plan
end

function Service.Retry(npcID)
    local plan = Service.ByNPC[key(npcID)]
    local step
    local ok
    local result
    if not plan then return false, "plan_not_found" end
    if plan.state ~= "RUNNING" then return false, "plan_not_running" end
    step = Plan.Current(plan)
    if not step or step.state ~= "BLOCKED" then
        return false, "current_step_not_blocked"
    end
    ok, result = Plan.SetStepState(plan, "RESOLVING", {
        retry = true,
    }, now())
    if not ok then return false, result end
    addActive(plan)
    markDirty(plan)
    emit("SEMANTIC_ACTION_PLAN_RETRIED", plan, "retry")
    return true, plan
end

function Service.Resume(npcID)
    local plan = Service.ByNPC[key(npcID)]
    local ok
    local result
    if not plan then return false, "plan_not_found" end
    ok, result = Plan.Resume(plan, now())
    if not ok then return false, result end
    addActive(plan)
    markDirty(plan)
    emit("SEMANTIC_ACTION_PLAN_RESUMED", plan, "resumed")
    return true, plan
end

function Service.ReconcileIndex()
    if not PNC.Registry or not PNC.Registry.ForEach then return 0 end
    local attached = 0
    PNC.Registry.ForEach(function(record)
        local id = record and key(record.id) or ""
        if id ~= "" and record.semanticActionPlan
            and not Service.ByNPC[id]
        then
            local plan = Service.Attach(record)
            if plan and not terminal(plan) then attached = attached + 1 end
        end
    end)
    return attached
end

function Service.Queries.Get(npcID)
    return Service.Get(npcID)
end

function Service.Queries.ActiveCount()
    return #Service.Active
end

return Service
