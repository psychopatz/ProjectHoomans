PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}
PNC.FakeLocomotion.Internal = PNC.FakeLocomotion.Internal or {}

local Internal = PNC.FakeLocomotion.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local TraversalQuery = PNC.TraversalQuery

local function isSquareWalkable(x, y, z, fromX, fromY, fromZ)
    if TraversalQuery
        and TraversalQuery.CanStep
        and fromX ~= nil
        and fromY ~= nil
        and fromZ ~= nil
    then
        return TraversalQuery.CanStep(fromX, fromY, fromZ, x, y, z)
    end
    return TraversalQuery
        and TraversalQuery.CanOccupy
        and TraversalQuery.CanOccupy(x, y, z)
        or false,
        "occupied"
end

local function recordInteractionBlock(context, candidate, reason)
    local lane = context.lane
    lane.blockedStepFromX = context.zx
    lane.blockedStepFromY = context.zy
    lane.blockedStepFromZ = context.zz
    lane.blockedStepToX = candidate.x
    lane.blockedStepToY = candidate.y
    lane.blockedStepToZ = candidate.z
    lane.blockedStepReason = reason
    lane.lastStepAt = context.now
    lane.lastStepDistance = 0
    lane.lastStepLabel = reason
end

local function applyFacing(context, moveDirX, moveDirY)
    local zombie = context.zombie
    local lookahead = Internal.Constants.FACING_LOOKAHEAD_DISTANCE
    local facingX = context.zx + (moveDirX * lookahead)
    local facingY = context.zy + (moveDirY * lookahead)
    if PNC.PathService and PNC.PathService.ApplyTravelFacing then
        PNC.PathService.ApplyTravelFacing(
            zombie,
            context.lane,
            facingX,
            facingY,
            context.now
        )
    elseif zombie.faceLocation then
        zombie:faceLocation(facingX, facingY)
    elseif zombie.faceLocationF then
        zombie:faceLocationF(facingX, facingY)
    end
end

local function applyPosition(context, candidate)
    local zombie = context.zombie
    if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
        LiveBodyControl.SetAuthoritativePosition(
            zombie,
            candidate.x,
            candidate.y,
            candidate.z
        )
    else
        zombie:setX(candidate.x)
        zombie:setY(candidate.y)
        zombie:setZ(candidate.z)
    end
    context.record.x = candidate.x
    context.record.y = candidate.y
    context.record.z = candidate.z
end

local function clearPassageBlock(lane)
    lane.blockedStepFromX = nil
    lane.blockedStepFromY = nil
    lane.blockedStepFromZ = nil
    lane.blockedStepToX = nil
    lane.blockedStepToY = nil
    lane.blockedStepToZ = nil
    lane.blockedStepReason = nil
end

local function recordProgress(
    context,
    candidate,
    actualStepDistance,
    candidateGoalDistance,
    progressDelta,
    progressed,
    moveDirX,
    moveDirY
)
    local lane = context.lane
    lane.lastStepAt = context.now
    lane.lastStepDistance = actualStepDistance
    lane.lastPhysicalMoveAt = context.now
    lane.lastStepLabel = candidate.label
    lane.steeringDirX = moveDirX
    lane.steeringDirY = moveDirY
    lane.lastProgressDelta = progressDelta
    lane.goalDistance = candidateGoalDistance
    if candidateGoalDistance < context.bestGoalDistance then
        lane.bestGoalDistance = candidateGoalDistance
        context.bestGoalDistance = candidateGoalDistance
    end
    if progressed then
        lane.lastProgressAt = context.now
        lane.lastGoalProgressAt = context.now
        lane.nonProgressStepCount = 0
        lane.blockReason = nil
        if context.record.runtime
            and context.record.runtime.navigationRouter
        then
            context.record.runtime.navigationRouter.lastInvalidationReason =
                nil
        end
    else
        lane.nonProgressStepCount =
            (tonumber(lane.nonProgressStepCount) or 0) + 1
    end
    lane.lastX = candidate.x
    lane.lastY = candidate.y
    lane.lastZ = candidate.z
end

local function recordSteeringChoice(lane, label)
    if label == "direct" then
        lane.directStepCount = (tonumber(lane.directStepCount) or 0) + 1
        if lane.directStepCount >= 6 then lane.steeringSide = nil end
        return
    end
    lane.directStepCount = 0
    if lane.steeringSide == nil then
        if label == "slide_other" or label == "hard_other" then
            lane.steeringSide = -1
        else
            lane.steeringSide = 1
        end
    end
end

local function rememberMotion(context, candidate)
    if not PNC.MotionHints or not PNC.MotionHints.Remember then return end
    PNC.MotionHints.Remember(
        context.lane,
        context.zx,
        context.zy,
        context.zz,
        candidate.x,
        candidate.y,
        candidate.z,
        context.now,
        {
            kind = "move",
            speed = context.lane.speed,
            profile = context.lane.motionProfile,
        }
    )
end

local function applyCandidate(
    context,
    candidate,
    actualStepDistance,
    candidateGoalDistance,
    progressDelta,
    progressed
)
    local moveDirX = (candidate.x - context.zx) / actualStepDistance
    local moveDirY = (candidate.y - context.zy) / actualStepDistance
    clearPassageBlock(context.lane)
    applyFacing(context, moveDirX, moveDirY)
    applyPosition(context, candidate)
    recordProgress(
        context,
        candidate,
        actualStepDistance,
        candidateGoalDistance,
        progressDelta,
        progressed,
        moveDirX,
        moveDirY
    )
    recordSteeringChoice(context.lane, candidate.label)
    rememberMotion(context, candidate)
end

function Internal.TryStepCandidate(context, candidate, index)
    local minimum = Internal.Constants.MIN_CANDIDATE_DISTANCE
    local actualStepDistance = Core.Distance(
        context.zx,
        context.zy,
        candidate.x,
        candidate.y
    )
    if actualStepDistance < minimum then return false end
    local walkable, blockReason = isSquareWalkable(
        candidate.x,
        candidate.y,
        candidate.z,
        context.zx,
        context.zy,
        context.zz
    )
    if index == 1
        and not walkable
        and (
            blockReason == "door"
            or blockReason == "window"
            or blockReason == "fence"
        )
    then
        recordInteractionBlock(context, candidate, blockReason)
        return true, false, "interaction_blocked", context.stepDistance
    end
    if not walkable then return false end
    local candidateGoalDistance = Core.Distance(
        candidate.x,
        candidate.y,
        context.goal.x,
        context.goal.y
    )
    local progressDelta =
        context.bestGoalDistance - candidateGoalDistance
    local progressed =
        progressDelta >= Internal.Constants.MIN_GOAL_PROGRESS
    if not progressed
        and (tonumber(context.lane.nonProgressStepCount) or 0)
            >= Internal.Constants.MAX_NON_PROGRESS_STEPS
    then
        context.sawNonProgressCandidate = true
        return false
    end
    applyCandidate(
        context,
        candidate,
        actualStepDistance,
        candidateGoalDistance,
        progressDelta,
        progressed
    )
    return true, true, candidate.label, actualStepDistance
end

return Internal
