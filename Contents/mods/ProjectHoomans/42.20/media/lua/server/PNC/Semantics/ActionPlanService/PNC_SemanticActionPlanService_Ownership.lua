-- Optional behavior-ownership query for the shared behavior coordinator.
-- The service owns only the plan lease; providers still own their effects.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.Semantics.ActionPlanService
local Plan = Service.Internal.Plan
local key = Service.Internal.Key

local YIELD_STEP_STATES = {
    PENDING = true,
    RESOLVING = true,
    ASSIGNED = true,
    TRAVEL = true,
    ARRIVED = true,
    WAITING = true,
    EXECUTING = true,
}

local function currentPlan(record)
    local id = key(record and record.id)
    local plan = id ~= "" and Service.ByNPC[id] or nil
    if not plan and record and type(Service.Attach) == "function" then
        plan = Service.Attach(record)
    end
    return plan
end

function Service.GetExecutionOwner(record)
    local plan = currentPlan(record)
    local step = plan and Plan.Current(plan) or nil
    if not plan or plan.state ~= "RUNNING"
        or not step or not YIELD_STEP_STATES[step.state]
    then
        return nil
    end
    return {
        planID = plan.planID,
        stepID = step.id,
        action = step.action,
        stepState = step.state,
        interruptPolicy = plan.interruptPolicy,
    }
end

function Service.ShouldYieldBehavior(record)
    return Service.GetExecutionOwner(record) ~= nil
end

return Service
