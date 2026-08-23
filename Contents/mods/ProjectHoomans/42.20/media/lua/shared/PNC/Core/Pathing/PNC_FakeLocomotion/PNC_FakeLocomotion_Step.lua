PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}
PNC.FakeLocomotion.Internal = PNC.FakeLocomotion.Internal or {}

local FakeLocomotion = PNC.FakeLocomotion
local Internal = FakeLocomotion.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl

local function buildStepContext(zombie, record, lane, goal, now)
    local stepDistance, deltaMs = Internal.ComputeStepDistance(
        lane,
        lane and lane.resolvedMode or lane.mode or goal.mode,
        now
    )
    if stepDistance <= 0 then
        return nil, "throttle"
    end
    local zx = zombie:getX()
    local zy = zombie:getY()
    local zz = zombie:getZ()
    local beforeGoalDistance = Core.Distance(zx, zy, goal.x, goal.y)
    local bestGoalDistance = tonumber(lane.bestGoalDistance)
        or beforeGoalDistance
    lane.goalDistance = beforeGoalDistance
    lane.bestGoalDistance = bestGoalDistance
    local steeringX, steeringY = Internal.ResolveSteeringDirection(
        lane,
        zx,
        zy,
        goal,
        deltaMs
    )
    return {
        zombie = zombie,
        record = record,
        lane = lane,
        goal = goal,
        now = now,
        stepDistance = stepDistance,
        zx = zx,
        zy = zy,
        zz = zz,
        bestGoalDistance = bestGoalDistance,
        candidates = Internal.BuildStepCandidates(
            zx,
            zy,
            goal,
            stepDistance,
            lane.steeringSide,
            steeringX,
            steeringY
        ),
        sawNonProgressCandidate = false,
    }
end

local function recordBlockedStep(context)
    local lane = context.lane
    lane.lastStepAt = context.now
    lane.lastStepDistance = 0
    lane.lastProgressDelta = 0
    lane.lastStepLabel = context.sawNonProgressCandidate
        and "stalled"
        or "blocked"
    lane.directStepCount = 0
    lane.steeringSide = tonumber(lane.steeringSide) == 1 and -1 or 1
    return false,
        context.sawNonProgressCandidate and "stalled" or "blocked",
        context.stepDistance
end

function FakeLocomotion.StepTowardGoal(zombie, record, lane, goal, now)
    if not zombie or not record or not lane or not goal then
        return false, "invalid", 0
    end
    -- Multiplayer movement is client-controlled; incremental position writes
    -- must never become a second transport owner.
    if LiveBodyControl
        and LiveBodyControl.IsMultiplayer
        and LiveBodyControl.IsMultiplayer()
    then
        return false, "native_mp_required", 0
    end
    local context, reason =
        buildStepContext(zombie, record, lane, goal, now)
    if not context then return false, reason, 0 end
    local i
    for i = 1, #context.candidates do
        local finished, moved, result, distance =
            Internal.TryStepCandidate(
                context,
                context.candidates[i],
                i
            )
        if finished then return moved, result, distance end
    end
    return recordBlockedStep(context)
end

return FakeLocomotion
