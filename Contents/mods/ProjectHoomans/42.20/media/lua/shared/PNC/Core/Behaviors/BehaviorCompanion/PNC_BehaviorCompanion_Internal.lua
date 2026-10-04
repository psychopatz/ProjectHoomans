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

function Internal.GetFollowOwnerKey(record, owner)
    local onlineID = owner and owner.getOnlineID
        and tonumber(owner:getOnlineID())
        or tonumber(record and record.ownerOnlineID)
    if onlineID ~= nil then
        return "id:" .. tostring(onlineID)
    end
    return "user:" .. tostring(
        owner and owner.getUsername and owner:getUsername()
            or record and record.ownerUsername
            or ""
    )
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
    local navigation
    local safetyRefresh
    if not target then return true end
    dx = (tonumber(target.x) or 0) - (
        tonumber(state.issuedTargetX) or math.huge
    )
    dy = (tonumber(target.y) or 0) - (
        tonumber(state.issuedTargetY) or math.huge
    )
    navigation = record.runtime and record.runtime.localNavigation or nil
    safetyRefresh = now - (tonumber(state.issuedAt) or 0)
        >= (tonumber(Const.FOLLOW_MOVE_INTENT_REFRESH_MS) or 2000)
    -- A live native route does not need to be reissued just because the
    -- follower has been walking for a while. Keep the safety refresh for a
    -- stalled route, but let a route with recent physical progress continue
    -- under its existing native controller.
    if safetyRefresh
        and navigation
        and navigation.provider == "engine_path"
        and navigation.nativeActive == true
        and now - (tonumber(navigation.lastPhysicalProgressAt) or now) < (
            tonumber(Const.FOLLOW_MOVE_INTENT_REFRESH_MS) or 2000
        )
    then
        safetyRefresh = false
    end
    changed = state.issuedTargetX == nil
        or (dx * dx) + (dy * dy) >= epsilon * epsilon
        or math.abs(
            (tonumber(target.z) or 0)
                - (tonumber(state.issuedTargetZ) or 0)
        ) >= 1
        or tostring(state.issuedMode or "") ~= tostring(mode or "walk")
        or (state.issuedAvoidance == true) ~= (target.avoidance == true)
        or safetyRefresh
    if not changed then return false end
    state.issuedTargetX = tonumber(target.x)
    state.issuedTargetY = tonumber(target.y)
    state.issuedTargetZ = tonumber(target.z)
    state.issuedMode = tostring(mode or "walk")
    state.issuedAvoidance = target.avoidance == true
    state.issuedAt = now
    return true
end

function Internal.HoldAndFaceOwner(record, zombie, owner, mode, reason, now)
    local state, changed = Internal.SetFollowMode(record, mode)
    local runtime = record.runtime or {}
    local path = runtime.pathing
    local navigation = runtime.localNavigation
    local combatNeedsClear
    local movementNeedsRepair
    local holdRefreshDue
    local facingDue
    local facingApplied
    now = tonumber(now)
        or PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or 0

    -- A hold is a lease, not a per-tick command. Only reset the movement
    -- intent when entering the lease; repeatedly clearing it made the hold
    -- path look active to every downstream movement/presentation service.
    if changed then
        Internal.ResetFollowMoveIssue(record)
        state.holdCombatCleared = false
        state.holdNextRefreshAt = 0
        state.holdFacingNextAt = 0
    end
    record.activeBehavior = mode == "idle_near_owner"
        and "FollowOwner:idle" or "FollowOwner:formation_hold"

    combatNeedsClear = changed
        or runtime.target ~= nil
        or runtime.attackAction ~= nil
        or (tonumber(runtime.inCombatUntil) or 0) > now
        or state.holdCombatCleared ~= true
    movementNeedsRepair = changed
        or path and (
            path.phase == "requested"
            or path.phase == "active"
            or path.traversalAction ~= nil
        )
        or navigation and (
            navigation.nativeActive == true
            or navigation.nativeTraversalState ~= nil
        )
    holdRefreshDue = changed
        or combatNeedsClear
        or movementNeedsRepair
        or now >= (tonumber(state.holdNextRefreshAt) or 0)

    -- Keep the hot path to a few field reads while the follower remains in a
    -- stable formation hold. Owner movement and combat are decided by the
    -- enclosing follow tick before this function, while the route checks
    -- above repair unexpected native/path ownership immediately.
    if not holdRefreshDue then
        return true
    end

    if combatNeedsClear then
        Common.ClearCombatTarget(record, reason)
        state.holdCombatCleared = true
    end
    if not zombie then return true end

    if changed or movementNeedsRepair then
        Common.HaltMovement(record, zombie, "follow_hold")
        if changed and Animation and Animation.Apply then
            Animation.Apply(zombie, record, "Idle")
        end
    end
    facingDue = changed
        or now >= (tonumber(state.holdFacingNextAt) or 0)
    if facingDue then
        if PNC.PathService and PNC.PathService.RequestAmbientFacing
            and PNC.PathService.RequestAmbientFacing(
                record,
                zombie,
                "follow_owner"
            )
        then
            facingApplied = true
        end
        if not facingApplied
            and PNC.PathService
            and PNC.PathService.RequestIdleFacing
        then
            PNC.PathService.RequestIdleFacing(
                record,
                zombie,
                owner:getX(),
                owner:getY(),
                "follow_owner"
            )
            facingApplied = true
        elseif not facingApplied and zombie.faceThisObject then
            zombie:faceThisObject(owner)
            facingApplied = true
        elseif not facingApplied and zombie.faceLocationF then
            zombie:faceLocationF(owner:getX(), owner:getY())
            facingApplied = true
        end
        state.holdFacingNextAt = now + (
            tonumber(Const.FOLLOW_HOLD_FACING_INTERVAL_MS) or 750
        )
    end
    state.holdNextRefreshAt = now + (
        tonumber(Const.FOLLOW_HOLD_REFRESH_MS) or 1000
    )
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
    local reportedMoving
    local dx
    local dy
    local epsilon = tonumber(Const.FOLLOW_OWNER_MOVE_EPSILON) or 0.08

    reportedMoving = (owner.isPlayerMoving and owner:isPlayerMoving())
        or (owner.isRunning and owner:isRunning())
        or (owner.isSprinting and owner:isSprinting())
        or false
    if reportedMoving then
        moved = true
    elseif state.ownerSampleX ~= nil and elapsed > 0 then
        dx = ownerX - state.ownerSampleX
        dy = ownerY - state.ownerSampleY
        moved = (dx * dx) + (dy * dy) >= epsilon * epsilon
    end

    state.ownerMoving = moved
    state.ownerMovingChanged = moved ~= wasMoving
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
