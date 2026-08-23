--[[
    PNC Traversal Runtime
    Owns single-player/fallback transform progression for fence and window
    climbs. Multiplayer uses the delegated native zombie path controller.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}

local PathService = PNC.PathService
PathService.Internal = PathService.Internal or {}

local Internal = PathService.Internal
local Animation = PNC.Animation
local LiveBodyControl = PNC.LiveBodyControl
local TraversalAction = PNC.TraversalAction
local TraversalQuery = PNC.TraversalQuery
local TRAVERSAL_FINISHED_VARIABLE = "PNCTraversalFinished"
local TRAVERSAL_KIND_VARIABLE = "PNCTraversalKind"
local TRAVERSAL_PHASE_VARIABLE = "PNCTraversalPhase"
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

local function getTraversalPhase(zombie)
    if not zombie then
        return ""
    end
    if zombie.getVariableString then
        return string.lower(tostring(
            zombie:getVariableString(TRAVERSAL_PHASE_VARIABLE) or ""
        ))
    end
    return ""
end

local function isTraversalFinished(zombie, action)
    local value
    if isBumpFinished(zombie) then
        return true
    end
    if getTraversalPhase(zombie) == "finished" then
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

local function isFenceCrossed(zombie, action)
    local query = Internal.TraversalQuery
        or TraversalQuery
        or PNC.TraversalQuery
    if not action or action.kind ~= "fence_climb" then
        return true
    end
    if query and query.IsFenceCrossed then
        return query.IsFenceCrossed(
            zombie and zombie:getX() or nil,
            zombie and zombie:getY() or nil,
            zombie and zombie:getZ() or nil,
            action.fromSquare,
            action.toSquare
        )
    end
    if not zombie or not action.toSquare then
        return false
    end
    return math.floor(zombie:getX()) == action.toSquare:getX()
        and math.floor(zombie:getY()) == action.toSquare:getY()
        and math.floor(zombie:getZ()) == action.toSquare:getZ()
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
    zombie:setVariable(TRAVERSAL_PHASE_VARIABLE, "")
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
    local hardTimeoutMs
    -- Native PathFindBehavior2 owns doors, windows, fences, and stairs in MP.
    -- This scripted interpolated traversal remains SP-only.
    if LiveBodyControl
        and LiveBodyControl.IsMultiplayer
        and LiveBodyControl.IsMultiplayer()
    then
        return false
    end
    if not zombie or not record or not lane or type(spec) ~= "table" then
        return false
    end
    -- Collision processing runs ahead of movement processing in Bandits. Make
    -- that ownership transfer explicit here as well: an obstacle action must
    -- cancel Behavior2 before it creates the scripted traversal lease.
    if PNC.EnginePathPlanner
        and PNC.EnginePathPlanner.Invalidate
    then
        PNC.EnginePathPlanner.Invalidate(
            record,
            "scripted_" .. tostring(spec.kind or "traversal"),
            zombie
        )
    end
    now = Internal.Core.Now()
    lane.traversalAction = TraversalAction.Create(
        spec,
        now,
        zombie:getX(),
        zombie:getY(),
        zombie:getZ()
    )
    hardTimeoutMs = lane.traversalAction.hardFinishAt - now
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
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
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
        Animation.PlayBump(
            zombie,
            record,
            lane.traversalAction.twoPhase
                and lane.traversalAction.startAnim
                or lane.traversalAction.anim,
            {
                keepManagedUseless = true,
                leaseUntil = lane.traversalAction.hardFinishAt,
            }
        )
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
                durationMs = lane.traversalAction.travelDurationMs,
                kind = lane.traversalAction.kind,
                profile = lane.motionProfile,
            }
        )
    end
    return true
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
            getTraversalPhase(zombie)
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
    if not action then
        return false, nil
    end
    if LiveBodyControl
        and LiveBodyControl.IsMultiplayer
        and LiveBodyControl.IsMultiplayer()
    then
        Internal.clearTraversalAction(
            zombie,
            lane,
            "native_mp_owner"
        )
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
    if zombie.setPath2 then
        zombie:setPath2(nil)
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    progress = advanceTraversalPhase(zombie, record, action, now)
    eased = easeInOut(progress)
    nextX = (tonumber(action.startX) or zombie:getX()) + (((tonumber(action.endX) or zombie:getX()) - (tonumber(action.startX) or zombie:getX())) * eased)
    nextY = (tonumber(action.startY) or zombie:getY()) + (((tonumber(action.endY) or zombie:getY()) - (tonumber(action.startY) or zombie:getY())) * eased)
    nextZ = (tonumber(action.startZ) or zombie:getZ()) + (((tonumber(action.endZ) or zombie:getZ()) - (tonumber(action.startZ) or zombie:getZ())) * eased)
    if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
        LiveBodyControl.SetAuthoritativePosition(zombie, nextX, nextY, nextZ)
    else
        zombie:setX(nextX)
        zombie:setY(nextY)
        zombie:setZ(nextZ)
    end
    Internal.syncRecordPosition(record, zombie)
    lane.lastPhysicalMoveAt = now
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
    if LiveBodyControl and LiveBodyControl.SetAuthoritativePosition then
        LiveBodyControl.SetAuthoritativePosition(zombie, nextX, nextY, nextZ)
    else
        zombie:setX(nextX)
        zombie:setY(nextY)
        zombie:setZ(nextZ)
    end
    Internal.syncRecordPosition(record, zombie)
    lane.lastPhysicalMoveAt = now
    crossed = isFenceCrossed(zombie, action)
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
        Internal.logMoveWarning(record, zombie, lane, "traversal_hard_timeout", action.kind, "anim=" .. tostring(action.anim or "nil"))
    end
    Internal.clearTraversalAction(zombie, lane, finishReason)
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    return false, "completed"
end
