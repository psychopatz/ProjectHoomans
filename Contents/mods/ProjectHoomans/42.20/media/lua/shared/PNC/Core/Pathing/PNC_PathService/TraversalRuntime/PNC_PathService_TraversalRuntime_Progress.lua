-- Per-frame traversal phase evaluation and authoritative movement.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Runtime = Internal.TraversalRuntime
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local TraversalAction = PNC.TraversalAction

local function clamp01(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function easeInOut(progress)
    progress = clamp01(progress)
    if progress < 0.5 then return 2 * progress * progress end
    local inverse = (-2 * progress) + 2
    return 1 - ((inverse * inverse) * 0.5)
end

local function advanceTraversalPhase(zombie, record, action, now)
    local phase
    local progress
    local phaseStartedAt
    local crossPendingAt
    local startedCrossing
    phase,
        progress,
        phaseStartedAt,
        crossPendingAt,
        startedCrossing = TraversalAction.Evaluate(
            action,
            now,
            Runtime.getTraversalPhase(zombie)
        )
    action.phase = phase
    action.crossPendingAt = crossPendingAt
    if not startedCrossing then return progress end
    action.phaseStartedAt = phaseStartedAt
    if Animation and Animation.PlayBump then
        Animation.PlayBump(
            zombie,
            record,
            action.endAnim,
            {
                keepManagedUseless = true,
                leaseUntil = action.hardFinishAt,
            }
        )
    elseif zombie.setBumpType then
        zombie:setBumpType(action.endAnim)
    end
    return progress
end

local function setTraversalPosition(zombie, record, lane, now, x, y, z)
    if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
        LiveBodyControl.SetAuthoritativePosition(zombie, x, y, z)
    else
        zombie:setX(x)
        zombie:setY(y)
        zombie:setZ(z)
    end
    Internal.syncRecordPosition(record, zombie)
    lane.lastPhysicalMoveAt = now
end

function Internal.updateTraversalAction(zombie, record, lane, now)
    local action = lane and lane.traversalAction or nil
    local finished
    local timedOut
    local finishReason
    local actionState
    local progress
    local eased
    local nextX
    local nextY
    local nextZ
    local crossed
    local previousPhase
    local observedPhase
    if not action then return false, nil end
    if LiveBodyControl
        and LiveBodyControl.IsMultiplayer
        and LiveBodyControl.IsMultiplayer()
    then
        Internal.clearTraversalAction(zombie, lane, "native_mp_owner")
        return false, "native_mp_owner"
    end
    if not zombie or not record then
        Internal.clearTraversalAction(zombie, lane, "body_missing")
        return false, "body_missing"
    end
    now = tonumber(now) or Internal.Core.Now()
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
    if zombie.setPath2 then zombie:setPath2(nil) end
    if zombie.setTarget then zombie:setTarget(nil) end
    previousPhase = action.phase
    observedPhase = Runtime.getTraversalPhase(zombie)
    progress = advanceTraversalPhase(zombie, record, action, now)
    if action.kind == "fence_climb"
        and previousPhase ~= action.phase
        and Internal.logMoveDebug
    then
        Internal.logMoveDebug(
            record,
            zombie,
            lane,
            "fence_phase",
            action.phase,
            "observed=" .. tostring(observedPhase)
                .. " action=" .. tostring(
                    Runtime.getActionStateName(zombie)
                )
                .. " elapsedMs=" .. tostring(
                    now - (tonumber(action.startedAt) or now)
                )
                .. " pos=" .. tostring(zombie:getX())
                .. "," .. tostring(zombie:getY())
                .. " target=" .. tostring(action.endX)
                .. "," .. tostring(action.endY)
        )
    end
    if action.kind == "fence_climb"
        and previousPhase == "up"
        and action.phase == "cross_pending"
        and tostring(observedPhase) ~= "transfer"
        and Internal.logMoveWarning
    then
        Internal.logMoveWarning(
            record,
            zombie,
            lane,
            "fence_transfer_signal_missing",
            "timer_fallback",
            "elapsedMs=" .. tostring(
                now - (tonumber(action.startedAt) or now)
            )
                .. " action=" .. tostring(
                    Runtime.getActionStateName(zombie)
                )
                .. " pos=" .. tostring(zombie:getX())
                .. "," .. tostring(zombie:getY())
                .. " target=" .. tostring(action.endX)
                .. "," .. tostring(action.endY)
        )
    end
    eased = easeInOut(progress)
    nextX = (tonumber(action.startX) or zombie:getX())
        + (((tonumber(action.endX) or zombie:getX())
        - (tonumber(action.startX) or zombie:getX())) * eased)
    nextY = (tonumber(action.startY) or zombie:getY())
        + (((tonumber(action.endY) or zombie:getY())
        - (tonumber(action.startY) or zombie:getY())) * eased)
    nextZ = (tonumber(action.startZ) or zombie:getZ())
        + (((tonumber(action.endZ) or zombie:getZ())
        - (tonumber(action.startZ) or zombie:getZ())) * eased)
    setTraversalPosition(zombie, record, lane, now, nextX, nextY, nextZ)
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    actionState = Runtime.getActionStateName(zombie)
    if actionState == "bumped" then action.sawBumpState = true end
    finished = Runtime.isTraversalFinished(zombie, action)
    if not finished
        and action.sawBumpState == true
        and progress >= 1
        and actionState ~= "bumped"
    then
        finished = true
    end
    timedOut = now >= (tonumber(action.hardFinishAt) or now)
    if progress < 1 then return true, action.kind end
    if action.kind == "window_smash"
        and action.interactionApplied ~= true
    then
        action.interactionApplied = true
        if Internal.smashWindowForNPC then
            Internal.smashWindowForNPC(zombie, action.obstacle)
        end
    end
    nextX = tonumber(action.endX) or zombie:getX()
    nextY = tonumber(action.endY) or zombie:getY()
    nextZ = tonumber(action.endZ) or zombie:getZ()
    setTraversalPosition(zombie, record, lane, now, nextX, nextY, nextZ)
    crossed = Runtime.isFenceCrossed(zombie, action)
    if not crossed and not timedOut then
        return true, action.kind .. "_same_side"
    end
    if not finished and not timedOut then
        return true, action.kind .. "_finish"
    end
    finishReason = crossed
        and (finished and "anim_finished" or "hard_timeout")
        or "same_side"
    if finishReason == "hard_timeout" and Internal.logMoveWarning then
        Internal.logMoveWarning(
            record,
            zombie,
            lane,
            "traversal_hard_timeout",
            action.kind,
            "anim=" .. tostring(action.anim or "nil")
        )
    end
    Internal.clearTraversalAction(zombie, lane, finishReason)
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    return false, "completed"
end
