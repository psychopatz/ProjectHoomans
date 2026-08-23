-- Pure phase/timing contract shared by native and scripted traversal.

PNC = PNC or {}
PNC.TraversalAction = PNC.TraversalAction or {}

local TraversalAction = PNC.TraversalAction
local DEFAULT_TRANSITION_SETTLE_MS = 50

local function clamp01(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function upFinishAt(action, now)
    local deadline = tonumber(action and action.upFinishAt)
    if deadline then return deadline end
    return (tonumber(action and action.phaseStartedAt)
        or tonumber(action and action.startedAt)
        or now)
        + math.max(1, tonumber(action and action.upDurationMs) or 1)
end

function TraversalAction.Create(spec, now, currentX, currentY, currentZ)
    if type(spec) ~= "table" then return nil end
    now = tonumber(now) or 0
    local travelDurationMs = math.max(
        250,
        tonumber(spec.travelDurationMs) or 600
    )
    local finishHoldMs = math.max(
        120,
        tonumber(spec.finishHoldMs) or 320
    )
    local twoPhase = spec.kind == "fence_climb"
        and tostring(spec.startAnim or "") ~= ""
        and tostring(spec.endAnim or "") ~= ""
    if twoPhase then
        travelDurationMs = math.max(
            250,
            tonumber(spec.crossingDurationMs) or travelDurationMs
        )
    end
    local hardTimeoutMs = travelDurationMs
        + math.min(finishHoldMs, 320)
    if twoPhase then
        hardTimeoutMs = hardTimeoutMs
            + math.max(250, tonumber(spec.upDurationMs) or 420)
    end
    return {
        kind = tostring(spec.kind or "traversal"),
        anim = tostring(spec.anim or "PNC_ClimbFence"),
        startAnim = twoPhase and tostring(spec.startAnim) or nil,
        endAnim = twoPhase and tostring(spec.endAnim) or nil,
        twoPhase = twoPhase,
        phase = twoPhase and "up" or "single",
        phaseStartedAt = now,
        upDurationMs = twoPhase
            and math.max(250, tonumber(spec.upDurationMs) or 700) or 0,
        finishHoldMs = finishHoldMs,
        startX = tonumber(spec.fromX) or currentX,
        startY = tonumber(spec.fromY) or currentY,
        startZ = tonumber(spec.fromZ) or currentZ,
        endX = tonumber(spec.toX) or currentX,
        endY = tonumber(spec.toY) or currentY,
        endZ = tonumber(spec.toZ) or currentZ,
        startedAt = now,
        travelDurationMs = travelDurationMs,
        hardFinishAt = now + hardTimeoutMs,
        sawBumpState = false,
        obstacle = spec.obstacle,
        fromSquare = spec.fromSquare,
        toSquare = spec.toSquare,
        interactionApplied = false,
    }
end

function TraversalAction.Evaluate(action, now, observedPhase)
    if type(action) ~= "table" then
        return "single", 0, tonumber(now) or 0, nil, false
    end
    now = tonumber(now) or 0
    local phase = tostring(action.phase or "single")
    local phaseStartedAt = tonumber(action.crossingStartedAt)
        or tonumber(action.phaseStartedAt)
        or tonumber(action.startedAt)
        or now
    local crossPendingAt = tonumber(action.crossPendingAt)
    local startedCrossing = false

    if action.twoPhase == true and phase == "up" then
        local transferReady = tostring(observedPhase or "") == "transfer"
            or now >= upFinishAt(action, now)
        if transferReady then
            phase = "cross_pending"
            crossPendingAt = now
        end
    end

    if action.twoPhase == true and phase == "cross_pending"
        and now >= (crossPendingAt or now)
            + math.max(0, tonumber(action.transitionSettleMs)
                or DEFAULT_TRANSITION_SETTLE_MS)
    then
        phase = "cross"
        phaseStartedAt = now
        startedCrossing = true
    end

    local progress = 0
    if phase == "cross" then
        progress = clamp01(
            (now - phaseStartedAt)
                / math.max(1, tonumber(action.crossingDurationMs)
                    or tonumber(action.travelDurationMs) or 1)
        )
    elseif phase ~= "up" and phase ~= "cross_pending" then
        progress = clamp01(
            (now - (tonumber(action.startedAt) or now))
                / math.max(1, tonumber(action.travelDurationMs) or 1)
        )
    end

    return phase,
        progress,
        phaseStartedAt,
        crossPendingAt,
        startedCrossing
end

return TraversalAction
