PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}
PNC.FakeLocomotion.Internal = PNC.FakeLocomotion.Internal or {}

local Internal = PNC.FakeLocomotion.Internal

function Internal.ResolveSteeringDirection(lane, zx, zy, goal, deltaMs)
    local constants = Internal.Constants
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
    if len <= 0.0001 then return nil, nil end
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
                * constants.STEERING_RESPONSE_PER_SECOND
        )
    )
    if dot < constants.SHARP_TURN_DOT then
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
        < constants.MIN_FORWARD_STEERING_DOT
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

local function buildCandidate(label, x, y, z)
    return { label = label, x = x, y = y, z = z }
end

function Internal.BuildStepCandidates(
    zx,
    zy,
    goal,
    stepDistance,
    steeringSide,
    directionX,
    directionY
)
    local minimum = Internal.Constants.MIN_CANDIDATE_DISTANCE
    local dx = goal.x - zx
    local dy = goal.y - zy
    local len = math.sqrt((dx * dx) + (dy * dy))
    local ux
    local uy
    local px
    local py
    local candidates
    if len <= 0.0001 then return {} end
    ux = directionX or (dx / len)
    uy = directionY or (dy / len)
    px = -uy
    py = ux
    if tonumber(steeringSide) == -1 then
        px = -px
        py = -py
    end
    candidates = {
        buildCandidate(
            "direct",
            zx + (ux * stepDistance),
            zy + (uy * stepDistance),
            goal.z
        ),
        buildCandidate(
            "slide_preferred",
            zx + ((ux + (px * 0.55)) * stepDistance),
            zy + ((uy + (py * 0.55)) * stepDistance),
            goal.z
        ),
    }
    if math.abs(ux * stepDistance) >= minimum then
        candidates[#candidates + 1] = buildCandidate(
            "axis_x",
            zx + (ux * stepDistance),
            zy,
            goal.z
        )
    end
    if math.abs(uy * stepDistance) >= minimum then
        candidates[#candidates + 1] = buildCandidate(
            "axis_y",
            zx,
            zy + (uy * stepDistance),
            goal.z
        )
    end
    candidates[#candidates + 1] = buildCandidate(
        "hard_preferred",
        zx + (px * stepDistance),
        zy + (py * stepDistance),
        goal.z
    )
    candidates[#candidates + 1] = buildCandidate(
        "slide_other",
        zx + ((ux - (px * 0.55)) * stepDistance),
        zy + ((uy - (py * 0.55)) * stepDistance),
        goal.z
    )
    candidates[#candidates + 1] = buildCandidate(
        "hard_other",
        zx - (px * stepDistance),
        zy - (py * stepDistance),
        goal.z
    )
    return candidates
end

return Internal
