--[[
    PNC Fake Locomotion
    Server-authoritative embodied movement for live NPC bodies. It keeps zombie
    AI disabled and advances bodies by small controlled steps so behaviors can
    share one locomotion authority in both singleplayer and multiplayer.
]]

PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}

local FakeLocomotion = PNC.FakeLocomotion
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local TraversalQuery = PNC.TraversalQuery

local MAX_STEP_DELTA_MS = 120
local MIN_STEP_INTERVAL_MS = 35
local MAX_NON_PROGRESS_STEPS = 24
local MIN_CANDIDATE_DISTANCE = 0.0001
local MIN_GOAL_PROGRESS = 0.001
local STEERING_RESPONSE_PER_SECOND = 8
local SHARP_TURN_DOT = 0.25
local MIN_FORWARD_STEERING_DOT = 0.35
local FACING_LOOKAHEAD_DISTANCE = 1.0

local function isSquareWalkable(x, y, z, fromX, fromY, fromZ)
    if TraversalQuery and TraversalQuery.CanStep and fromX ~= nil and fromY ~= nil and fromZ ~= nil then
        return TraversalQuery.CanStep(fromX, fromY, fromZ, x, y, z)
    end
    return TraversalQuery and TraversalQuery.CanOccupy and TraversalQuery.CanOccupy(x, y, z) or false, "occupied"
end

local function buildCandidate(label, x, y, z)
    return {
        label = label,
        x = x,
        y = y,
        z = z,
    }
end

local function resolveProfile(lane, mode)
    local profile = lane and lane.motionProfile or nil
    if profile then
        return profile
    end
    if LocomotionProfiles and LocomotionProfiles.GetBaseProfile then
        return LocomotionProfiles.GetBaseProfile(mode)
    end
    return {
        speed = 0.68,
        moveAnim = mode == "run" and "Run" or mode == "sneak" and "SneakWalk" or mode == "crawl" and "Crawl" or "Walk",
    }
end

local function getSpeedForMode(mode, lane)
    local profile = resolveProfile(lane, mode)
    return tonumber(profile and profile.speed) or 0.68
end

function FakeLocomotion.GetModeSpeed(mode)
    return getSpeedForMode(mode)
end

function FakeLocomotion.ComputeAnimSpeed(mode)
    if LocomotionProfiles and LocomotionProfiles.ComputeAnimSpeed then
        return LocomotionProfiles.ComputeAnimSpeed(mode)
    end
    return 1.0
end

local function computeStepDistance(lane, mode, now)
    local lastStepAt = tonumber(lane and lane.lastStepAt or 0) or 0
    local speed = getSpeedForMode(mode, lane)
    local deltaMs
    if lastStepAt <= 0 then
        return speed * 0.05, 50
    end
    deltaMs = math.max(0, now - lastStepAt)
    if deltaMs < MIN_STEP_INTERVAL_MS then
        return 0, deltaMs
    end
    deltaMs = math.min(deltaMs, MAX_STEP_DELTA_MS)
    return speed * (deltaMs / 1000), deltaMs
end

local function resolveSteeringDirection(
    lane,
    zx,
    zy,
    goal,
    deltaMs
)
    local dx = goal.x - zx
    local dy = goal.y - zy
    local len = math.sqrt((dx * dx) + (dy * dy))
    local targetX
    local targetY
    local previousX
    local previousY
    local dot
    local alpha
    local blendedX
    local blendedY
    local blendedLength
    if len <= 0.0001 then
        return nil, nil
    end
    targetX = dx / len
    targetY = dy / len
    previousX = tonumber(lane and lane.steeringDirX)
    previousY = tonumber(lane and lane.steeringDirY)
    if not previousX or not previousY
        or (tonumber(deltaMs) or 0) >= 250
    then
        if lane then
            lane.steeringDirX = targetX
            lane.steeringDirY = targetY
            lane.steeringTargetDirX = targetX
            lane.steeringTargetDirY = targetY
            lane.steeringTurnDot = 1
        end
        return targetX, targetY
    end
    dot = (previousX * targetX) + (previousY * targetY)
    alpha = math.min(
        1,
        math.max(
            0.2,
            ((tonumber(deltaMs) or 50) / 1000)
                * STEERING_RESPONSE_PER_SECOND
        )
    )
    if dot < SHARP_TURN_DOT then
        alpha = math.max(alpha, 0.65)
    end
    blendedX = (previousX * (1 - alpha)) + (targetX * alpha)
    blendedY = (previousY * (1 - alpha)) + (targetY * alpha)
    blendedLength = math.sqrt(
        (blendedX * blendedX) + (blendedY * blendedY)
    )
    if blendedLength <= 0.0001 then
        blendedX = targetX
        blendedY = targetY
    else
        blendedX = blendedX / blendedLength
        blendedY = blendedY / blendedLength
    end
    if (blendedX * targetX) + (blendedY * targetY)
        < MIN_FORWARD_STEERING_DOT
    then
        blendedX = targetX
        blendedY = targetY
    end
    if lane then
        lane.steeringDirX = blendedX
        lane.steeringDirY = blendedY
        lane.steeringTargetDirX = targetX
        lane.steeringTargetDirY = targetY
        lane.steeringTurnDot = dot
    end
    return blendedX, blendedY
end

local function buildStepCandidates(
    zx,
    zy,
    zz,
    goal,
    stepDistance,
    steeringSide,
    directionX,
    directionY
)
    local dx = goal.x - zx
    local dy = goal.y - zy
    local len = math.sqrt((dx * dx) + (dy * dy))
    local ux
    local uy
    local px
    local py
    local candidates
    if len <= 0.0001 then
        return {}
    end
    ux = directionX or (dx / len)
    uy = directionY or (dy / len)
    px = -uy
    py = ux
    if tonumber(steeringSide) == -1 then
        px = -px
        py = -py
    end
    candidates = {
        buildCandidate("direct", zx + (ux * stepDistance), zy + (uy * stepDistance), goal.z),
        buildCandidate("slide_preferred", zx + ((ux + (px * 0.55)) * stepDistance), zy + ((uy + (py * 0.55)) * stepDistance), goal.z),
    }
    -- Do not add a zero-length axis fallback. It used to be accepted as a
    -- successful movement step, keeping blocked NPCs alive forever while they
    -- walked/turned in place.
    if math.abs(ux * stepDistance) >= MIN_CANDIDATE_DISTANCE then
        candidates[#candidates + 1] =
            buildCandidate(
                "axis_x",
                zx + (ux * stepDistance),
                zy,
                goal.z
            )
    end
    if math.abs(uy * stepDistance) >= MIN_CANDIDATE_DISTANCE then
        candidates[#candidates + 1] =
            buildCandidate(
                "axis_y",
                zx,
                zy + (uy * stepDistance),
                goal.z
            )
    end
    candidates[#candidates + 1] =
        buildCandidate(
            "hard_preferred",
            zx + (px * stepDistance),
            zy + (py * stepDistance),
            goal.z
        )
    candidates[#candidates + 1] =
        buildCandidate(
            "slide_other",
            zx + ((ux - (px * 0.55)) * stepDistance),
            zy + ((uy - (py * 0.55)) * stepDistance),
            goal.z
        )
    candidates[#candidates + 1] =
        buildCandidate(
            "hard_other",
            zx - (px * stepDistance),
            zy - (py * stepDistance),
            goal.z
        )
    return candidates
end

function FakeLocomotion.PrepareBody(zombie, lane, now)
    local resolvedMode = lane and lane.resolvedMode or lane and lane.mode or "walk"
    local profile = resolveProfile(lane, resolvedMode)
    if not zombie then
        return
    end
    if LiveBodyControl and LiveBodyControl.ApplyHumanizedBodyFlags then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    if LiveBodyControl and LiveBodyControl.TrySilenceEmitter then
        LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    end
    if zombie.setRunning then
        zombie:setRunning(profile and profile.isRunning == true)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
end

function FakeLocomotion.StepTowardGoal(zombie, record, lane, goal, now)
    local stepDistance
    local deltaMs
    local zx
    local zy
    local zz
    local candidates
    local i
    local candidate
    local walkable
    local blockReason
    local beforeGoalDistance
    local bestGoalDistance
    local candidateGoalDistance
    local progressDelta
    local actualStepDistance
    local progressed
    local steeringX
    local steeringY
    local moveDirX
    local moveDirY
    local sawNonProgressCandidate = false
    if not zombie or not record or not lane or not goal then
        return false, "invalid", 0
    end
    stepDistance, deltaMs = computeStepDistance(
        lane,
        lane and lane.resolvedMode or lane.mode or goal.mode,
        now
    )
    if stepDistance <= 0 then
        return false, "throttle", 0
    end
    zx = zombie:getX()
    zy = zombie:getY()
    zz = zombie:getZ()
    beforeGoalDistance = Core.Distance(zx, zy, goal.x, goal.y)
    bestGoalDistance = tonumber(lane.bestGoalDistance)
        or beforeGoalDistance
    lane.goalDistance = beforeGoalDistance
    lane.bestGoalDistance = bestGoalDistance
    steeringX, steeringY = resolveSteeringDirection(
        lane,
        zx,
        zy,
        goal,
        deltaMs
    )
    candidates = buildStepCandidates(
        zx,
        zy,
        goal.z,
        goal,
        stepDistance,
        lane.steeringSide,
        steeringX,
        steeringY
    )
    for i = 1, #candidates do
        candidate = candidates[i]
        actualStepDistance = Core.Distance(
            zx,
            zy,
            candidate.x,
            candidate.y
        )
        if actualStepDistance < MIN_CANDIDATE_DISTANCE then
            candidate = nil
        end
        if candidate then
            walkable, blockReason = isSquareWalkable(
                candidate.x,
                candidate.y,
                candidate.z,
                zx,
                zy,
                zz
            )
            if i == 1
                and not walkable
                and (
                    blockReason == "door"
                    or blockReason == "window"
                    or blockReason == "fence"
                )
            then
                lane.blockedStepFromX = zx
                lane.blockedStepFromY = zy
                lane.blockedStepFromZ = zz
                lane.blockedStepToX = candidate.x
                lane.blockedStepToY = candidate.y
                lane.blockedStepToZ = candidate.z
                lane.blockedStepReason = blockReason
                lane.lastStepAt = now
                lane.lastStepDistance = 0
                lane.lastStepLabel = blockReason
                return false, "interaction_blocked", stepDistance
            end
            if walkable then
                candidateGoalDistance = Core.Distance(
                    candidate.x,
                    candidate.y,
                    goal.x,
                    goal.y
                )
                -- Compare against the best distance reached for this lane
                -- goal. Alternating away/toward around the same point must
                -- not count as forward progress.
                progressDelta =
                    bestGoalDistance - candidateGoalDistance
                progressed = progressDelta >= MIN_GOAL_PROGRESS
                if not progressed
                    and (tonumber(lane.nonProgressStepCount) or 0)
                        >= MAX_NON_PROGRESS_STEPS
                then
                    sawNonProgressCandidate = true
                else
                    lane.blockedStepFromX = nil
                    lane.blockedStepFromY = nil
                    lane.blockedStepFromZ = nil
                    lane.blockedStepToX = nil
                    lane.blockedStepToY = nil
                    lane.blockedStepToZ = nil
                    lane.blockedStepReason = nil
                    moveDirX = (candidate.x - zx)
                        / actualStepDistance
                    moveDirY = (candidate.y - zy)
                        / actualStepDistance
                    if PNC.PathService
                        and PNC.PathService.ApplyTravelFacing
                    then
                        PNC.PathService.ApplyTravelFacing(
                            zombie,
                            lane,
                            zx + (
                                moveDirX
                                    * FACING_LOOKAHEAD_DISTANCE
                            ),
                            zy + (
                                moveDirY
                                    * FACING_LOOKAHEAD_DISTANCE
                            ),
                            now
                        )
                    elseif zombie.faceLocation then
                        zombie:faceLocation(
                            zx + (
                                moveDirX
                                    * FACING_LOOKAHEAD_DISTANCE
                            ),
                            zy + (
                                moveDirY
                                    * FACING_LOOKAHEAD_DISTANCE
                            )
                        )
                    elseif zombie.faceLocationF then
                        zombie:faceLocationF(
                            zx + (
                                moveDirX
                                    * FACING_LOOKAHEAD_DISTANCE
                            ),
                            zy + (
                                moveDirY
                                    * FACING_LOOKAHEAD_DISTANCE
                            )
                        )
                    end
                    if LiveBodyControl
                        and LiveBodyControl.SetAuthoritativePosition
                    then
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
                    record.x = candidate.x
                    record.y = candidate.y
                    record.z = candidate.z
                    lane.lastStepAt = now
                    lane.lastStepDistance = actualStepDistance
                    lane.lastStepLabel = candidate.label
                    lane.steeringDirX = moveDirX
                    lane.steeringDirY = moveDirY
                    lane.lastProgressDelta = progressDelta
                    lane.goalDistance = candidateGoalDistance
                    if candidateGoalDistance < bestGoalDistance then
                        lane.bestGoalDistance = candidateGoalDistance
                        bestGoalDistance = candidateGoalDistance
                    end
                    if progressed then
                        lane.lastProgressAt = now
                        lane.lastGoalProgressAt = now
                        lane.nonProgressStepCount = 0
                        lane.blockReason = nil
                        if record.runtime
                            and record.runtime.navigationRouter
                        then
                            record.runtime.navigationRouter.lastInvalidationReason = nil
                        end
                    else
                        lane.nonProgressStepCount =
                            (tonumber(
                                lane.nonProgressStepCount
                            ) or 0) + 1
                    end
                    lane.lastX = candidate.x
                    lane.lastY = candidate.y
                    lane.lastZ = candidate.z
                    if candidate.label == "direct" then
                        lane.directStepCount =
                            (tonumber(lane.directStepCount) or 0) + 1
                        if lane.directStepCount >= 6 then
                            lane.steeringSide = nil
                        end
                    else
                        lane.directStepCount = 0
                        if lane.steeringSide == nil then
                            if candidate.label == "slide_other"
                                or candidate.label == "hard_other"
                            then
                                lane.steeringSide = -1
                            else
                                lane.steeringSide = 1
                            end
                        end
                    end
                    if PNC.MotionHints
                        and PNC.MotionHints.Remember
                    then
                        PNC.MotionHints.Remember(
                            lane,
                            zx,
                            zy,
                            zz,
                            candidate.x,
                            candidate.y,
                            candidate.z,
                            now,
                            {
                                kind = "move",
                                speed = lane.speed,
                                profile = lane.motionProfile,
                            }
                        )
                    end
                    return true,
                        candidate.label,
                        actualStepDistance
                end
            end
        end
    end
    lane.lastStepAt = now
    lane.lastStepDistance = 0
    lane.lastProgressDelta = 0
    lane.lastStepLabel = sawNonProgressCandidate
        and "stalled" or "blocked"
    lane.directStepCount = 0
    lane.steeringSide = tonumber(lane.steeringSide) == 1 and -1 or 1
    return false,
        sawNonProgressCandidate and "stalled" or "blocked",
        stepDistance
end
