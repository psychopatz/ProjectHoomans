--[[
    PNC Traversal Runtime
    Owns the server-authoritative lifetime and transform progression of fence
    and window climbs.  Intent updates remain pending while this action owns
    the body; clients only interpolate the resulting authoritative snapshots.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

local Internal = PathService.Internal
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local TRAVERSAL_FINISHED_VARIABLE = "PNCTraversalFinished"
local TRAVERSAL_KIND_VARIABLE = "PNCTraversalKind"

local function clamp01(value)
    return math.max(0, math.min(1, tonumber(value) or 0))
end

local function easeInOut(progress)
    progress = clamp01(progress)
    if progress < 0.5 then
        return 2 * progress * progress
    end
    local inverse = (-2 * progress) + 2
    return 1 - ((inverse * inverse) * 0.5)
end

local function isBumpFinished(zombie)
    local value
    if not zombie then
        return true
    end
    if zombie.getVariableBoolean and zombie:getVariableBoolean("BumpAnimFinished") == true then
        return true
    end
    if zombie.getVariableString then
        value = string.lower(tostring(zombie:getVariableString("BumpAnimFinished") or ""))
        return value == "true" or value == "1"
    end
    return false
end

local function isTraversalFinished(zombie, action)
    local value
    if isBumpFinished(zombie) then
        return true
    end
    if not zombie or not action then
        return false
    end
    if zombie.getVariableBoolean and zombie:getVariableBoolean(TRAVERSAL_FINISHED_VARIABLE) == true then
        return true
    end
    if zombie.getVariableString then
        value = string.lower(tostring(zombie:getVariableString(TRAVERSAL_FINISHED_VARIABLE) or ""))
        return value == "true" or value == "1"
    end
    return false
end

local function getActionStateName(zombie)
    if zombie and zombie.getActionStateName then
        return string.lower(tostring(zombie:getActionStateName() or ""))
    end
    return ""
end

local function resetTraversalVariables(zombie)
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable(TRAVERSAL_FINISHED_VARIABLE, false)
    zombie:setVariable(TRAVERSAL_KIND_VARIABLE, "")
end

local function resetEngineTraversalVariables(zombie, kind)
    if not zombie or not zombie.setVariable then
        return
    end
    if kind == "fence_climb" then
        zombie:setVariable("ClimbFenceStarted", false)
        zombie:setVariable("ClimbFenceFinished", true)
        zombie:setVariable("ClimbFenceOutcome", "")
    elseif kind == "window_climb" then
        zombie:setVariable("ClimbWindowStarted", false)
        zombie:setVariable("ClimbWindowOutcome", "")
    end
end

function Internal.clearTraversalAction(zombie, lane, reason)
    if not lane then
        return
    end
    if Animation and Animation.FinishBump then
        Animation.FinishBump(zombie, true)
    end
    resetTraversalVariables(zombie)
    lane.traversalAction = nil
    lane.specialMoveUntil = 0
    lane.specialAnim = nil
    lane.ownerMode = "fake_locomotion"
    lane.lastTraversalFinishReason = reason or "completed"
    if lane.lastSpecialActionKey then
        lane.lastSpecialActionAt = Internal.Core.Now()
    end
end

function Internal.beginTraversalAction(zombie, record, lane, spec)
    local now
    local travelDurationMs
    local finishHoldMs
    local hardTimeoutMs
    if not zombie or not record or not lane or type(spec) ~= "table" then
        return false
    end
    now = Internal.Core.Now()
    travelDurationMs = math.max(250, tonumber(spec.travelDurationMs) or 600)
    finishHoldMs = math.max(120, tonumber(spec.finishHoldMs) or 320)
    -- Completion events are preferred, but a missing event must never pin an
    -- NPC on the obstacle for several seconds.
    hardTimeoutMs = travelDurationMs + math.min(finishHoldMs, 320)
    lane.traversalAction = {
        kind = tostring(spec.kind or "traversal"),
        anim = tostring(spec.anim or "PNC_ClimbFence"),
        startX = tonumber(spec.fromX) or zombie:getX(),
        startY = tonumber(spec.fromY) or zombie:getY(),
        startZ = tonumber(spec.fromZ) or zombie:getZ(),
        endX = tonumber(spec.toX) or zombie:getX(),
        endY = tonumber(spec.toY) or zombie:getY(),
        endZ = tonumber(spec.toZ) or zombie:getZ(),
        startedAt = now,
        travelDurationMs = travelDurationMs,
        hardFinishAt = now + hardTimeoutMs,
        sawBumpState = false,
    }
    lane.specialMoveUntil = now + hardTimeoutMs
    lane.specialAnim = lane.traversalAction.anim
    lane.ownerMode = lane.traversalAction.kind
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    resetTraversalVariables(zombie)
    if zombie.setVariable then
        zombie:setVariable(TRAVERSAL_KIND_VARIABLE, lane.traversalAction.kind)
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if zombie.setPath2 then
        zombie:setPath2(nil)
    end
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.setRunning then
        zombie:setRunning(false)
    end
    -- Engine pathing may have entered its own climb state on the collision
    -- frame. Exit that state before selecting PNC's bump node; otherwise the
    -- bump End event is never evaluated and traversal can only hard-timeout.
    if LiveBodyControl and LiveBodyControl.SuppressZombieState then
        LiveBodyControl.SuppressZombieState(zombie, lane, now)
    end
    resetEngineTraversalVariables(zombie, lane.traversalAction.kind)
    if Internal.applyFacingLocation then
        Internal.applyFacingLocation(zombie, lane, lane.traversalAction.endX, lane.traversalAction.endY, now, "traversal", true)
    end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(zombie, record, lane.traversalAction.anim)
    elseif zombie.setBumpType then
        zombie:setBumpType(lane.traversalAction.anim)
    end
    if Internal.MotionHints and Internal.MotionHints.Remember then
        Internal.MotionHints.Remember(
            lane,
            lane.traversalAction.startX,
            lane.traversalAction.startY,
            lane.traversalAction.startZ,
            lane.traversalAction.endX,
            lane.traversalAction.endY,
            lane.traversalAction.endZ,
            now,
            {
                durationMs = travelDurationMs,
                kind = lane.traversalAction.kind,
                profile = lane.motionProfile,
            }
        )
    end
    return true
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
    if not action then
        return false, nil
    end
    if not zombie or not record then
        Internal.clearTraversalAction(zombie, lane, "body_missing")
        return false, "body_missing"
    end
    now = tonumber(now) or Internal.Core.Now()
    if zombie.setUseless then
        zombie:setUseless(true)
    end
    if zombie.setPath2 then
        zombie:setPath2(nil)
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    progress = clamp01((now - (tonumber(action.startedAt) or now)) / math.max(1, tonumber(action.travelDurationMs) or 1))
    eased = easeInOut(progress)
    nextX = (tonumber(action.startX) or zombie:getX()) + (((tonumber(action.endX) or zombie:getX()) - (tonumber(action.startX) or zombie:getX())) * eased)
    nextY = (tonumber(action.startY) or zombie:getY()) + (((tonumber(action.endY) or zombie:getY()) - (tonumber(action.startY) or zombie:getY())) * eased)
    nextZ = (tonumber(action.startZ) or zombie:getZ()) + (((tonumber(action.endZ) or zombie:getZ()) - (tonumber(action.startZ) or zombie:getZ())) * eased)
    zombie:setX(nextX)
    zombie:setY(nextY)
    zombie:setZ(nextZ)
    Internal.syncRecordPosition(record, zombie)
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    actionState = getActionStateName(zombie)
    if actionState == "bumped" then
        action.sawBumpState = true
    end
    finished = isTraversalFinished(zombie, action)
    if not finished
        and action.sawBumpState == true
        and progress >= 1
        and actionState ~= "bumped"
    then
        finished = true
    end
    timedOut = now >= (tonumber(action.hardFinishAt) or now)
    if progress < 1 then
        return true, action.kind
    end
    zombie:setX(tonumber(action.endX) or zombie:getX())
    zombie:setY(tonumber(action.endY) or zombie:getY())
    zombie:setZ(tonumber(action.endZ) or zombie:getZ())
    Internal.syncRecordPosition(record, zombie)
    if not finished and not timedOut then
        return true, action.kind .. "_finish"
    end
    finishReason = finished and "anim_finished" or "hard_timeout"
    if finishReason == "hard_timeout" and Internal.logMoveWarning then
        Internal.logMoveWarning(record, zombie, lane, "traversal_hard_timeout", action.kind, "anim=" .. tostring(action.anim or "nil"))
    end
    Internal.clearTraversalAction(zombie, lane, finishReason)
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    return false, "completed"
end
