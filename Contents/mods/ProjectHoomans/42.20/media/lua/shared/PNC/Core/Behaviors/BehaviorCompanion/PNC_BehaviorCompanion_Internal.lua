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

function Internal.HoldAndFaceOwner(record, zombie, owner, mode, reason)
    local _, changed = Internal.SetFollowMode(record, mode)
    record.activeBehavior = mode == "idle_near_owner"
        and "FollowOwner:idle" or "FollowOwner:formation_hold"
    Common.ClearCombatTarget(record, reason)
    if not zombie then return true end

    if changed then
        Common.HaltMovement(record, zombie, "follow_hold")
        Animation.Apply(zombie, record, "Idle")
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
    local ownerX = owner:getX()
    local ownerY = owner:getY()
    local elapsed = now - (tonumber(state.ownerSampleAt) or now)
    local moved = false
    local dx
    local dy
    local epsilon = tonumber(Const.FOLLOW_OWNER_MOVE_EPSILON) or 0.08

    if owner.isPlayerMoving and owner:isPlayerMoving() then
        moved = true
    elseif owner.isRunning and owner:isRunning() then
        moved = true
    elseif owner.isSprinting and owner:isSprinting() then
        moved = true
    elseif state.ownerSampleX ~= nil and elapsed > 0 then
        dx = ownerX - state.ownerSampleX
        dy = ownerY - state.ownerSampleY
        moved = (dx * dx) + (dy * dy) >= epsilon * epsilon
    end

    state.ownerMoving = moved
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
