-- Shared state and geometry primitives for companion behavior modules.

local Companion = PNC.BehaviorCompanion
local Internal = Companion.Internal
local Animation = PNC.Animation
local Common = PNC.BehaviorCommon
local Const = PNC.Const

function Internal.GetFollowState(record)
    record.runtime = record.runtime or {}
    record.runtime.followState = record.runtime.followState
        or { mode = "moving" }
    return record.runtime.followState
end

function Internal.SetFollowMode(record, mode)
    local state = Internal.GetFollowState(record)
    local changed = state.mode ~= mode
    state.mode = mode
    return state, changed
end

function Internal.ResetFollowMoveIssue(record)
    local state = Internal.GetFollowState(record)
    state.issuedTargetX = nil
    state.issuedTargetY = nil
    state.issuedTargetZ = nil
    state.issuedMode = nil
    state.issuedAvoidance = nil
    state.issuedAt = 0
end

function Internal.ShouldIssueFollowMove(record, target, mode, now)
    local state = Internal.GetFollowState(record)
    local epsilon = tonumber(Const.FOLLOW_MOVE_INTENT_EPSILON) or 0.35
    local dx
    local dy
    local changed
    if not target then return true end
    dx = (tonumber(target.x) or 0) - (
        tonumber(state.issuedTargetX) or math.huge
    )
    dy = (tonumber(target.y) or 0) - (
        tonumber(state.issuedTargetY) or math.huge
    )
    changed = state.issuedTargetX == nil
        or (dx * dx) + (dy * dy) >= epsilon * epsilon
        or math.abs(
            (tonumber(target.z) or 0)
                - (tonumber(state.issuedTargetZ) or 0)
        ) >= 1
        or tostring(state.issuedMode or "") ~= tostring(mode or "walk")
        or (state.issuedAvoidance == true) ~= (target.avoidance == true)
        or now - (tonumber(state.issuedAt) or 0) >= (
            tonumber(Const.FOLLOW_MOVE_INTENT_REFRESH_MS) or 1500
        )
    if not changed then return false end
    state.issuedTargetX = tonumber(target.x)
    state.issuedTargetY = tonumber(target.y)
    state.issuedTargetZ = tonumber(target.z)
    state.issuedMode = tostring(mode or "walk")
    state.issuedAvoidance = target.avoidance == true
    state.issuedAt = now
    return true
end

function Internal.HoldAndFaceOwner(record, zombie, owner, mode, reason)
    local _, changed = Internal.SetFollowMode(record, mode)
    Internal.ResetFollowMoveIssue(record)
    record.activeBehavior = mode == "idle_near_owner"
        and "FollowOwner:idle" or "FollowOwner:formation_hold"
    Common.ClearCombatTarget(record, reason)
    if not zombie then return true end

    if changed then
        Common.HaltMovement(record, zombie, "follow_hold")
        if Animation and Animation.Apply then
            Animation.Apply(zombie, record, "Idle")
        end
    end
    if PNC.PathService and PNC.PathService.RequestIdleFacing then
        PNC.PathService.RequestIdleFacing(
            record,
            zombie,
            owner:getX(),
            owner:getY(),
            "follow_owner"
        )
    elseif zombie.faceThisObject then
        zombie:faceThisObject(owner)
    elseif zombie.faceLocationF then
        zombie:faceLocationF(owner:getX(), owner:getY())
    end
    return true
end

function Internal.NormalizeDirection(dx, dy)
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len <= 0.0001 then
        return nil, nil
    end
    return dx / len, dy / len
end

function Internal.ResolveOwnerForward(owner)
    local forward
    local fx
    local fy
    if not owner or not owner.getForwardDirection then
        return 0, 1
    end
    forward = owner:getForwardDirection()
    fx = forward and tonumber(forward:getX()) or 0
    fy = forward and tonumber(forward:getY()) or 0
    fx, fy = Internal.NormalizeDirection(fx, fy)
    if fx and fy then
        return fx, fy
    end
    return 0, 1
end

function Internal.UpdateOwnerMotionState(record, owner, now)
    local state = Internal.GetFollowState(record)
    local wasMoving = state.ownerMoving == true
    local ownerX = owner:getX()
    local ownerY = owner:getY()
    local elapsed = now - (tonumber(state.ownerSampleAt) or now)
    local moved = false
    local dx
    local dy
    local epsilon = tonumber(Const.FOLLOW_OWNER_MOVE_EPSILON) or 0.08

    if owner.isPlayerMoving or owner.isRunning or owner.isSprinting then
        moved = (owner.isPlayerMoving and owner:isPlayerMoving())
            or (owner.isRunning and owner:isRunning())
            or (owner.isSprinting and owner:isSprinting())
            or false
    elseif state.ownerSampleX ~= nil and elapsed > 0 then
        dx = ownerX - state.ownerSampleX
        dy = ownerY - state.ownerSampleY
        moved = (dx * dx) + (dy * dy) >= epsilon * epsilon
    end

    state.ownerMoving = moved
    if moved and not wasMoving then
        state.nextThreatScanAt = 0
    end
    state.ownerSampleX = ownerX
    state.ownerSampleY = ownerY
    state.ownerSampleAt = now
    return state
end

function Internal.UpdateOwnerCombatState(record, owner, now)
    local state = Internal.GetFollowState(record)
    local attacking = owner and owner.isAttacking and owner:isAttacking()
    if not attacking and owner and owner.isAttackStarted then
        attacking = owner:isAttackStarted()
    end
    if attacking then
        state.ownerEngagedUntil = now + (
            tonumber(Const.FOLLOW_OWNER_COMBAT_MEMORY_MS) or 1400
        )
    end
    state.ownerEngaged = now < (tonumber(state.ownerEngagedUntil) or 0)
    return state.ownerEngaged
end
