-- Low-frequency environmental scanning for stationary NPC presentation.
-- This is deliberately separate from native movement recovery: it only owns
-- a short facing lease and never changes a Java action state or sound alert.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local PathService = PNC.PathService
local Internal = PathService.Internal
local Core = PNC.Core
local Const = PNC.Const or {}

local SCAN_ANGLES = {
    -math.pi / 3,
    math.pi / 3,
    math.pi,
    0,
}

local function getState(record)
    local runtime
    local state
    if not record then return nil end
    runtime = record.runtime or {}
    record.runtime = runtime
    state = runtime.ambientFacing or {}
    runtime.ambientFacing = state
    state.nextAt = tonumber(state.nextAt) or 0
    state.activeUntil = tonumber(state.activeUntil) or 0
    state.cycle = tonumber(state.cycle) or 0
    state.lastTargetX = state.lastTargetX ~= nil
        and tonumber(state.lastTargetX) or nil
    state.lastTargetY = state.lastTargetY ~= nil
        and tonumber(state.lastTargetY) or nil
    return state
end

local function isEligible(record, zombie, now)
    local runtime = record and record.runtime or nil
    local path = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    local followState = runtime and runtime.followState or nil
    local treatment = runtime and runtime.selfTreatment or nil
    local actionState
    if not record or not zombie
        or record.alive == false
        or record.presenceState ~= Const.PRESENCE_LIVE
        or zombie.isDead and zombie:isDead()
        or zombie.isAlive and zombie:isAlive() == false
        or record.health
            and tostring(record.health.state or "normal") ~= "normal"
        or runtime and runtime.target ~= nil
        or runtime and runtime.attackAction ~= nil
        or runtime and now < (tonumber(runtime.inCombatUntil) or 0)
        or record.health
            and now < (tonumber(record.health.recentDamageUntil) or 0)
        or followState and followState.ownerMoving == true
        or treatment and treatment.phase == "bandaging"
        or record.orderSpec
            and record.orderSpec.kind == "facility_activity"
    then
        return false
    end
    if path and (
        path.phase == "requested"
        or path.phase == "active"
        or path.traversalAction ~= nil
        or path.vanillaFenceAction ~= nil
        or now < (tonumber(path.visualMovingUntil) or 0)
        or now < (tonumber(path.specialMoveUntil) or 0)
    ) then
        return false
    end
    if navigation and (
        navigation.nativeActive == true
        or navigation.nativeTraversalState ~= nil
    ) then
        return false
    end
    if runtime and runtime.animationScene ~= nil then
        return false
    end
    if zombie.getActionStateName then
        actionState = string.lower(tostring(zombie:getActionStateName() or ""))
        if actionState ~= "" and actionState ~= "idle" then
            return false
        end
    end
    return true
end

local function getForwardDirection(zombie, lane)
    local forward
    local directionX
    local directionY
    if zombie and zombie.getForwardDirection then
        forward = zombie:getForwardDirection()
    end
    directionX = forward and tonumber(forward:getX()) or nil
    directionY = forward and tonumber(forward:getY()) or nil
    if not directionX or not directionY
        or math.abs(directionX) + math.abs(directionY) <= 0.0001
    then
        directionX = lane and tonumber(lane.lastFacingDirX) or nil
        directionY = lane and tonumber(lane.lastFacingDirY) or nil
    end
    if not directionX or not directionY then
        directionX = 0
        directionY = 1
    end
    return Internal.normalizeDirection(directionX, directionY)
end

local function nextInterval(state)
    local minimum = tonumber(Internal.AMBIENT_FACING_MIN_INTERVAL_MS)
        or 5000
    local jitterMax = math.max(
        0,
        tonumber(Internal.AMBIENT_FACING_JITTER_MS) or 2500
    )
    state.cycle = (state.cycle % 997) + 1
    return minimum + ((state.cycle * 1103) % (jitterMax + 1))
end

local function scheduleRetry(state, now)
    state.nextAt = now + math.max(
        250,
        tonumber(Internal.AMBIENT_FACING_RETRY_MS) or 1500
    )
end

local function scanTarget(zombie, lane, state)
    local directionX
    local directionY
    local angle
    local cosAngle
    local sinAngle
    local targetX
    local targetY
    local distance = tonumber(Internal.AMBIENT_FACING_DISTANCE) or 3.0
    local index = (state.cycle % #SCAN_ANGLES) + 1
    directionX, directionY = getForwardDirection(zombie, lane)
    angle = SCAN_ANGLES[index]
    cosAngle = math.cos(angle)
    sinAngle = math.sin(angle)
    targetX = zombie:getX()
        + ((directionX * cosAngle) - (directionY * sinAngle)) * distance
    targetY = zombie:getY()
        + ((directionX * sinAngle) + (directionY * cosAngle)) * distance
    return targetX, targetY
end

function PathService.RequestAmbientFacing(record, zombie, reason)
    local lane
    local state
    local now
    local targetX
    local targetY
    local previousOwner
    local applied
    if not record or not zombie or not Core or not Core.Now then
        return false
    end

    state = getState(record)
    now = Core.Now()

    -- Cooldown is the normal path. Keep the ambient service out of the
    -- movement-lane initializer and the heavier eligibility checks until a
    -- look is actually due; this is called from the visual tick.
    if state.activeUntil <= now and state.nextAt > now then
        return false
    end

    if state.activeUntil > now then
        lane = Internal.ensureMoveLane(record)
        if not lane then
            state.activeUntil = 0
            scheduleRetry(state, now)
            return false
        end
        Internal.clearExpiredCombatFacing(lane, now)
        if not isEligible(record, zombie, now) then
            state.activeUntil = 0
            scheduleRetry(state, now)
            return false
        end
        if (tonumber(lane.combatFacingUntil) or 0) > now then
            state.activeUntil = 0
            state.nextAt = math.max(
                tonumber(state.nextAt) or 0,
                now + (tonumber(Internal.AMBIENT_FACING_MIN_INTERVAL_MS) or 5000)
            )
            return false
        end
        return true
    end

    if state.nextAt <= 0 then
        state.nextAt = now + (
            tonumber(Internal.AMBIENT_FACING_INITIAL_DELAY_MS) or 4000
        )
        return false
    end
    if now < state.nextAt then
        return false
    end

    lane = Internal.ensureMoveLane(record)
    if not lane then
        scheduleRetry(state, now)
        return false
    end
    Internal.clearExpiredCombatFacing(lane, now)
    if not isEligible(record, zombie, now) then
        scheduleRetry(state, now)
        return false
    end
    if (tonumber(lane.combatFacingUntil) or 0) > now then
        state.nextAt = math.max(
            tonumber(state.nextAt) or 0,
            now + (tonumber(Internal.AMBIENT_FACING_MIN_INTERVAL_MS) or 5000)
        )
        return false
    end

    targetX, targetY = scanTarget(zombie, lane, state)
    previousOwner = lane.facingOwner
    applied = Internal.applyFacingLocation(
        zombie,
        lane,
        targetX,
        targetY,
        now,
        "ambient_idle",
        previousOwner ~= "ambient_idle"
    )
    state.lastReason = tostring(reason or "ambient_idle")
    if not applied then
        state.activeUntil = 0
        scheduleRetry(state, now)
        return false
    end
    state.lastTargetX = targetX
    state.lastTargetY = targetY
    state.activeUntil = now + (
        tonumber(Internal.AMBIENT_FACING_LEASE_MS) or 850
    )
    state.nextAt = now + nextInterval(state)
    return true
end

return PathService
