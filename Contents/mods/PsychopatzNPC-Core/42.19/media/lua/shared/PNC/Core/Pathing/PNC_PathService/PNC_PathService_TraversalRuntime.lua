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
local TRAVERSAL_FINISHED_VARIABLE = "PNCTraversalFinished"
local TRAVERSAL_KIND_VARIABLE = "PNCTraversalKind"

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

local function resetTraversalVariables(zombie)
    if not zombie or not zombie.setVariable then
        return
    end
    zombie:setVariable(TRAVERSAL_FINISHED_VARIABLE, false)
    zombie:setVariable(TRAVERSAL_KIND_VARIABLE, "")
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
    -- Animation events own normal completion. This deadline is deliberately
    -- generous and exists only to release a body if the engine drops the XML
    -- End event entirely.
    hardTimeoutMs = math.max(4000, travelDurationMs + finishHoldMs + 2000)
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
    if Internal.applyFacingLocation then
        Internal.applyFacingLocation(zombie, lane, lane.traversalAction.endX, lane.traversalAction.endY, now, "traversal", true)
    end
    if Animation and Animation.PlayBump then
        Animation.PlayBump(zombie, record, lane.traversalAction.anim)
    elseif zombie.setBumpType then
        zombie:setBumpType(lane.traversalAction.anim)
    end
    if Internal.MotionHints and Internal.MotionHints.RememberHold then
        Internal.MotionHints.RememberHold(lane, lane.traversalAction.startX, lane.traversalAction.startY, lane.traversalAction.startZ, now, hardTimeoutMs, {
            kind = lane.traversalAction.kind .. "_hold",
            profile = lane.motionProfile,
        })
    end
    return true
end

function Internal.updateTraversalAction(zombie, record, lane, now)
    local action = lane and lane.traversalAction or nil
    local finished
    local timedOut
    local finishReason
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
    -- The animation owns the visible hop while the authoritative transform is
    -- pinned to takeoff.  Committing early makes fake locomotion visibly slide
    -- through the obstacle before the body finishes vaulting it.
    zombie:setX(tonumber(action.startX) or zombie:getX())
    zombie:setY(tonumber(action.startY) or zombie:getY())
    zombie:setZ(tonumber(action.startZ) or zombie:getZ())
    Internal.syncRecordPosition(record, zombie)
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    finished = isTraversalFinished(zombie, action)
    timedOut = now >= (tonumber(action.hardFinishAt) or now)
    if not finished and not timedOut then
        return true, action.kind
    end
    zombie:setX(tonumber(action.endX) or zombie:getX())
    zombie:setY(tonumber(action.endY) or zombie:getY())
    zombie:setZ(tonumber(action.endZ) or zombie:getZ())
    Internal.syncRecordPosition(record, zombie)
    if Internal.MotionHints and Internal.MotionHints.Remember then
        Internal.MotionHints.Remember(lane, action.startX, action.startY, action.startZ, action.endX, action.endY, action.endZ, now, {
            durationMs = 140,
            kind = action.kind .. "_commit",
            profile = lane.motionProfile,
        })
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
