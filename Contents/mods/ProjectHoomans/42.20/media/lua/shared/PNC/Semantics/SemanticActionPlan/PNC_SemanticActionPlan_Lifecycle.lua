-- State transitions for semantic action plans.
-- Runtime providers own movement, inventory, and other gameplay effects.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Plan = PNC.Semantics.ActionPlan
local Internal = Plan.Internal
local normalizeState = Internal.NormalizeState
local copyValue = Internal.CopyValue
local copyOptional = Internal.CopyOptional
local touch = Internal.Touch

local STEP_TRANSITIONS = {
    PENDING = {
        RESOLVING = true, PAUSED = true, FAILED = true, CANCELLED = true,
    },
    RESOLVING = {
        ASSIGNED = true, BLOCKED = true, PAUSED = true,
        FAILED = true, CANCELLED = true,
    },
    ASSIGNED = {
        TRAVEL = true, ARRIVED = true, WAITING = true,
        EXECUTING = true, BLOCKED = true, PAUSED = true,
        COMPLETED = true, FAILED = true, CANCELLED = true,
    },
    TRAVEL = {
        ARRIVED = true, BLOCKED = true, PAUSED = true,
        FAILED = true, CANCELLED = true,
    },
    ARRIVED = {
        WAITING = true, EXECUTING = true, COMPLETED = true,
        BLOCKED = true, PAUSED = true, FAILED = true, CANCELLED = true,
    },
    WAITING = {
        ARRIVED = true, EXECUTING = true, COMPLETED = true,
        BLOCKED = true, PAUSED = true, FAILED = true, CANCELLED = true,
    },
    EXECUTING = {
        COMPLETED = true, BLOCKED = true, PAUSED = true,
        FAILED = true, CANCELLED = true,
    },
    BLOCKED = {
        RESOLVING = true, ASSIGNED = true, PAUSED = true,
        FAILED = true, CANCELLED = true,
    },
    PAUSED = {
        PENDING = true, RESOLVING = true, ASSIGNED = true,
        TRAVEL = true, ARRIVED = true, WAITING = true,
        EXECUTING = true, FAILED = true, CANCELLED = true,
    },
}

local function validate(plan)
    return Plan.Validate(plan)
end

function Plan.Start(plan, now)
    local valid, reason = validate(plan)
    if not valid then return false, reason end
    if plan.state ~= "PENDING" then return false, "plan_not_pending" end
    local step = Plan.Current(plan)
    if not step or step.state ~= "PENDING" then
        return false, "current_step_not_pending"
    end
    plan.state = "RUNNING"
    step.state = "RESOLVING"
    step.revision = (tonumber(step.revision) or 0) + 1
    touch(plan, now)
    return true, plan
end

function Plan.SetStepState(plan, state, details, now)
    local valid, reason = validate(plan)
    if not valid then return false, reason end

    local step = Plan.Current(plan)
    state = normalizeState(state, Plan.STEP_STATES, nil)
    if not step or not state then return false, "step_state_invalid" end
    if plan.state == "COMPLETED" or plan.state == "FAILED"
        or plan.state == "CANCELLED"
    then
        return false, "plan_terminal"
    end
    if state ~= step.state
        and not (STEP_TRANSITIONS[step.state]
            and STEP_TRANSITIONS[step.state][state])
    then
        return false, "invalid_step_transition"
    end

    local copiedDetails, detailsValid
    if details ~= nil then
        copiedDetails, detailsValid = copyValue(details)
        if not detailsValid then return false, "step_details_unsafe" end
    end

    if state == "PAUSED" then step.resumeState = step.state end
    if state ~= "PAUSED" and step.state == "PAUSED" then
        step.resumeState = nil
    end
    step.state = state
    if details ~= nil then step.diagnostics = copiedDetails end
    step.revision = (tonumber(step.revision) or 0) + 1
    touch(plan, now)
    return true, plan
end

-- Providers may keep only bounded identifiers, coordinates, and other plain
-- data here. Live Java objects must stay in the provider/runtime layer.
function Plan.SetStepAssignment(plan, assignment, now)
    local valid, reason = validate(plan)
    local step
    local copied
    local assignmentValid
    if not valid then return false, reason end
    step = Plan.Current(plan)
    if not step then return false, "current_step_invalid" end
    if plan.state == "COMPLETED" or plan.state == "FAILED"
        or plan.state == "CANCELLED"
    then
        return false, "plan_terminal"
    end
    copied, assignmentValid = copyOptional(assignment)
    if not assignmentValid then return false, "step_assignment_unsafe" end
    step.assignment = copied
    step.revision = (tonumber(step.revision) or 0) + 1
    touch(plan, now)
    return true, plan
end

function Plan.Advance(plan, result, now)
    local valid, reason = validate(plan)
    if not valid then return false, reason end
    if plan.state ~= "RUNNING" then return false, "plan_not_running" end
    local step = Plan.Current(plan)
    if not step or step.state ~= "COMPLETED" then
        return false, "current_step_not_complete"
    end

    local copied, resultValid = copyOptional(result)
    if not resultValid then return false, "step_result_unsafe" end
    step.result = copied
    step.revision = (tonumber(step.revision) or 0) + 1
    plan.currentStep = plan.currentStep + 1
    if plan.currentStep > #plan.steps then
        plan.state = "COMPLETED"
    else
        plan.steps[plan.currentStep].state = "PENDING"
    end
    touch(plan, now)
    return true, plan
end

function Plan.Fail(plan, reason, now)
    local valid, validationReason = validate(plan)
    if not valid then return false, validationReason end
    if plan.state == "COMPLETED" or plan.state == "CANCELLED" then
        return false, "plan_terminal"
    end
    local step = Plan.Current(plan)
    if step and step.state ~= "FAILED" then
        local changed, transitionReason = Plan.SetStepState(
            plan, "FAILED", { reason = tostring(reason or "failed") }, now)
        if not changed then return false, transitionReason end
    end
    plan.state = "FAILED"
    touch(plan, now)
    return true, plan
end

function Plan.Cancel(plan, reason, now)
    local valid, validationReason = validate(plan)
    if not valid then return false, validationReason end
    if plan.state == "COMPLETED" then return false, "plan_terminal" end
    local step = Plan.Current(plan)
    if step and step.state ~= "CANCELLED" then
        local changed, transitionReason = Plan.SetStepState(
            plan, "CANCELLED", { reason = tostring(reason or "cancelled") }, now)
        if not changed then return false, transitionReason end
    end
    plan.state = "CANCELLED"
    touch(plan, now)
    return true, plan
end

function Plan.Pause(plan, reason, now)
    local valid, validationReason = validate(plan)
    if not valid then return false, validationReason end
    if plan.state ~= "RUNNING" then return false, "plan_not_running" end
    local changed, transitionReason = Plan.SetStepState(
        plan, "PAUSED", { reason = tostring(reason or "paused") }, now)
    if not changed then return false, transitionReason end
    plan.state = "PAUSED"
    touch(plan, now)
    return true, plan
end

function Plan.Resume(plan, now)
    local valid, validationReason = validate(plan)
    if not valid then return false, validationReason end
    if plan.state ~= "PAUSED" then return false, "plan_not_paused" end
    local step = Plan.Current(plan)
    if not step or step.state ~= "PAUSED" then
        return false, "current_step_not_paused"
    end
    local resumeState = step.resumeState or "PENDING"
    if resumeState == "COMPLETED" or resumeState == "FAILED"
        or resumeState == "CANCELLED"
    then
        resumeState = "PENDING"
    end
    step.resumeState = nil
    step.state = resumeState
    plan.state = "RUNNING"
    step.revision = (tonumber(step.revision) or 0) + 1
    touch(plan, now)
    return true, plan
end

Plan.Internal.StepTransitions = STEP_TRANSITIONS

return Plan
