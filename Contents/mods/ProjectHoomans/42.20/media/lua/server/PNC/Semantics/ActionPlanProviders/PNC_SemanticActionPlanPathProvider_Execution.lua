if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Provider = PNC.Semantics.ActionPlanPathProvider
local Registry = Provider.Registry
local PathService = Provider.PathService
local Common = Provider.Common
local MoveIntent = Provider.MoveIntent

local function number(value)
    return tonumber(value)
end

local function liveBody(record)
    return Registry and Registry.GetLiveZombie and record
        and Registry.GetLiveZombie(record.id) or nil
end

local function bodyCoordinate(body, method, fallback)
    if body and type(body[method]) == "function" then
        return number(body[method](body)) or number(fallback) or 0
    end
    return number(fallback) or 0
end

local function atTarget(record, body, assignment)
    local x = bodyCoordinate(body, "getX", record and record.x)
    local y = bodyCoordinate(body, "getY", record and record.y)
    local z = bodyCoordinate(body, "getZ", record and record.z)
    local dx = x - assignment.x
    local dy = y - assignment.y
    local distance = number(assignment.stopDistance) or 0.7
    return (dx * dx) + (dy * dy) <= distance * distance
        and math.abs(z - assignment.z) < 0.75
end

local function clearMovement(record, body, reason)
    if PathService and PathService.Commands
        and type(PathService.Commands.Reset) == "function"
    then
        return PathService.Commands.Reset(record, body, reason)
    end
    if PathService and type(PathService.Reset) == "function" then
        return PathService.Reset(body, record, reason)
    end
    if MoveIntent and type(MoveIntent.Hold) == "function" then
        return MoveIntent.Hold(record, reason)
    end
    return false
end

local function requestMovement(plan, record, body, assignment)
    local reason = "semantic_action_plan:" .. tostring(plan.planID)
    local navigation = {
        navigationPolicy = "local",
        finalX = assignment.x,
        finalY = assignment.y,
        finalZ = assignment.z,
    }
    record.activeJob = "SemanticActionPlan"
    record.activeBehavior = "SemanticActionPlan:MOVE_TO"
    if body and Common and type(Common.MoveRecord) == "function" then
        local moved, state = Common.MoveRecord(
            record,
            body,
            assignment.x,
            assignment.y,
            assignment.z,
            assignment.mode,
            assignment.stopDistance,
            reason,
            navigation
        )
        if moved == false then return false, state or "movement_rejected" end
        return true, state or "move_intent"
    end
    if not body and PathService
        and type(PathService.AdvanceAbstract) == "function"
    then
        return true, "abstract_move"
    end
    return false, "path_service_unavailable"
end

local function refreshDynamicAssignment(plan, step, record, body)
    local assignment = step and step.assignment
    local previous = assignment
    local runtime
    local refreshed
    local reason
    local dx
    local dy
    local dz
    local changed
    if type(assignment) ~= "table" or assignment.dynamic ~= true then
        return assignment, nil, false
    end

    runtime = Provider.Service
        and type(Provider.Service.GetRuntimeContext) == "function"
        and Provider.Service.GetRuntimeContext(plan.planID)
        or nil
    refreshed, reason = Provider.AssignmentFor(
        step, record, body, runtime, {
            planID = plan.planID,
            requestID = plan.requestID,
        })
    if not refreshed then return nil, reason end
    dx = (number(refreshed.x) or 0) - (number(previous.x) or 0)
    dy = (number(refreshed.y) or 0) - (number(previous.y) or 0)
    dz = (number(refreshed.z) or 0) - (number(previous.z) or 0)
    changed = (dx * dx) + (dy * dy) >= 0.75 * 0.75
        or math.abs(dz) >= 0.5
    -- This is a live execution assignment. It stays primitive, but its
    -- coordinates may follow a moving player without retaining a Java object
    -- in the persisted plan.
    step.assignment = refreshed
    return refreshed, nil, changed
end

function Provider.Resolve(plan, step, record)
    local body = liveBody(record)
    local runtime = Provider.Service
        and type(Provider.Service.GetRuntimeContext) == "function"
        and Provider.Service.GetRuntimeContext(plan.planID)
        or nil
    local assignment, reason = Provider.AssignmentFor(
        step, record, body, runtime, {
            planID = plan.planID,
            requestID = plan.requestID,
        })
    if not assignment then return nil, reason end
    if not record or record.alive == false then
        return nil, "npc_unavailable"
    end
    return assignment
end

function Provider.Start(plan, step, record)
    local assignment = step and step.assignment
    local body
    local moved
    local reason
    if type(assignment) ~= "table" then
        return { blocked = true, reason = "movement_assignment_missing" }
    end
    body = liveBody(record)
    assignment, reason = refreshDynamicAssignment(
        plan, step, record, body)
    if not assignment then
        return { blocked = true, reason = reason or "dynamic_target_unavailable" }
    end
    if body and atTarget(record, body, assignment) then
        return { state = "ARRIVED" }
    end
    moved, reason = requestMovement(plan, record, body, assignment)
    if not moved then return { blocked = true, reason = reason } end
    return { state = "TRAVEL" }
end

function Provider.Tick(plan, step, record)
    local assignment = step and step.assignment
    local body
    local movement
    local arrived
    local reason
    local dynamicChanged
    if type(assignment) ~= "table" then
        return { blocked = true, reason = "movement_assignment_missing" }
    end
    body = liveBody(record)
    assignment, reason, dynamicChanged = refreshDynamicAssignment(
        plan, step, record, body)
    if not assignment then
        return { blocked = true, reason = reason or "dynamic_target_unavailable" }
    end
    if not body then
        if PathService and type(PathService.AdvanceAbstract) == "function" then
            arrived = PathService.AdvanceAbstract(
                record,
                assignment.x,
                assignment.y,
                assignment.z,
                assignment.stopDistance
            )
            if arrived == true then
                if step.state == "ARRIVED" then
                    return { complete = true, result = {
                        targetID = assignment.targetID,
                        mode = "abstract",
                    } }
                end
                return { state = "ARRIVED" }
            end
            return { state = "TRAVEL" }
        end
        return { blocked = true, reason = "abstract_path_unavailable" }
    end

    if atTarget(record, body, assignment) then
        if step.state ~= "ARRIVED" then
            clearMovement(record, body, "semantic_action_plan_arrived")
        end
        if step.state == "ARRIVED" then
            return { complete = true, result = {
                targetID = assignment.targetID,
                x = assignment.x,
                y = assignment.y,
                z = assignment.z,
            } }
        end
        return { state = "ARRIVED" }
    end

    if dynamicChanged then
        local reissued, reissueReason = requestMovement(
            plan, record, body, assignment)
        if not reissued then
            return { blocked = true, reason = reissueReason }
        end
        return { state = "TRAVEL", diagnostics = {
            reason = "dynamic_target_updated",
        } }
    end

    movement = PathService
        and type(PathService.GetMovementRecoveryState) == "function"
        and PathService.GetMovementRecoveryState(record, body)
        or nil
    if movement and movement.phase == "blocked" then
        return { blocked = true,
            reason = movement.lastProgressReason or "path_blocked" }
    end
    if movement and (movement.active == true
        or movement.phase == "active"
        or movement.phase == "requested"
    ) then
        return { state = "TRAVEL" }
    end

    local reissued, reissueReason = requestMovement(
        plan, record, body, assignment)
    if not reissued then
        return { blocked = true, reason = reissueReason }
    end
    return { state = "TRAVEL", diagnostics = {
        reason = "movement_lane_reissued",
    } }
end

function Provider.Cancel(_, _, record, reason)
    return clearMovement(record, liveBody(record),
        reason or "semantic_action_plan_cancelled") ~= false
end

return Provider
