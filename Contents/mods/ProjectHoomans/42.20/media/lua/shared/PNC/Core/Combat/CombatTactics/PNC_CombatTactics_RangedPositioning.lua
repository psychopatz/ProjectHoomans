-- Clear-shot strafing and ranged distance maintenance.

PNC = PNC or {}
PNC.CombatTactics = PNC.CombatTactics or {}

local Tactics = PNC.CombatTactics
Tactics.Internal = Tactics.Internal or {}

local Internal = Tactics.Internal
local Core = PNC.Core
local Const = PNC.Const
local TraversalQuery = PNC.TraversalQuery

function Tactics.RepositionForClearShot(record, zombie, target)
    local state
    local now
    local dx
    local dy
    local length
    local direction
    local distance
    local candidateX
    local candidateY
    local alternateX
    local alternateY
    local z
    if not record or not zombie or not target then return false, nil end
    now = Core.Now()
    state = Internal.EnsureRetreatState(record)
    if Internal.ContinueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "clearing_fire_lane"
    end
    if now < (tonumber(state.retryAt) or 0) then
        return false, "retreat_stalled"
    end
    dx = target.x - record.x
    dy = target.y - record.y
    length = math.sqrt((dx * dx) + (dy * dy))
    if length <= 0.001 then return false, "invalid_fire_lane" end
    direction = Internal.StableDirection(record.id) < math.pi and 1 or -1
    distance = tonumber(Const.RANGED_FIRE_LANE_STRAFE_DISTANCE) or 1.6
    candidateX = record.x + (-dy / length) * distance * direction
    candidateY = record.y + (dx / length) * distance * direction
    alternateX = record.x - (-dy / length) * distance * direction
    alternateY = record.y - (dx / length) * distance * direction
    z = target.z or record.z
    if TraversalQuery and TraversalQuery.CanOccupy
        and not TraversalQuery.CanOccupy(candidateX, candidateY, z)
    then
        candidateX = alternateX
        candidateY = alternateY
    end
    state.phase = "strafe"
    state.reason = "clearing_fire_lane"
    state.lockUntil = now + (tonumber(Const.RANGED_FIRE_LANE_LOCK_MS) or 500)
    state.goalX = candidateX
    state.goalY = candidateY
    state.goalZ = z
    state.goalMode = "walk"
    state.goalStopDistance = 0.25
    state.recoveryMode = nil
    state.safetyRadius = nil
    state.reengagePending = false
    state.refreshAt = now + 220
    state.startedAt = now
    state.lastProgressAt = now
    state.lastX = zombie and zombie.getX and zombie:getX()
        or tonumber(record.x) or 0
    state.lastY = zombie and zombie.getY and zombie:getY()
        or tonumber(record.y) or 0
    Internal.SetRetreatState(record, true, nil)
    Internal.RequestMove(
        record, zombie, candidateX, candidateY, z,
        "walk", 0.25, "clearing_fire_lane", {
            source = "combat_retreat",
            priority = 100,
            lockKey = "combat_retreat",
            lockUntil = state.lockUntil,
        }
    )
    return true, "clearing_fire_lane"
end

function Tactics.MaintainRangedSpacing(record, zombie, target)
    local state
    local now
    local dist
    local preferredMin
    local report
    local pressure
    local sourceX
    local sourceY
    local centroidCount
    local retreatDistance
    local mode
    local reason
    local attackRetreatTriggered
    if not record or not zombie or not target then return false, nil end
    now = Core.Now()
    state = Internal.EnsureRetreatState(record)
    if Internal.ContinueLockedRetreat(record, zombie, target, state, now) then
        return true, state.reason or "ranged_disengage"
    end
    dist = math.sqrt(tonumber(target.distSq or 0) or 0)
    preferredMin = tonumber(Const.RANGED_PREFERRED_MIN_DISTANCE) or 5.0
    report = Internal.AssessThreat(record, target)
    attackRetreatTriggered = Tactics.IsHordeAttackRetreatTriggered(
        state, report, now
    )
    pressure = target.kind == "zombie" and (
        report.pressureCount >= (tonumber(Const.RANGED_PRESSURE_COUNT) or 2)
        or (
            report.hordeCount >= (tonumber(Const.COMBAT_HORDE_COUNT) or 4)
            and attackRetreatTriggered
        )
        or (
            dist < preferredMin
            and report.targetCrowdCount >= Const.COMBAT_TARGET_CROWD_COUNT
        )
    )
    if dist >= preferredMin and not pressure then
        Internal.ClearActiveRetreat(record, state)
        return false, nil
    end
    if pressure then
        sourceX, sourceY, centroidCount = Internal.BuildZombieThreatCentroid(
            record, Const.COMBAT_HORDE_RADIUS
        )
    end
    retreatDistance = (tonumber(Const.RANGED_RETREAT_STEP) or 3.2)
        + math.max(0, preferredMin - dist)
        + math.min(tonumber(centroidCount) or 0, 5) * 0.2
    mode = pressure
        and report.staminaRatio > Const.COMBAT_RETREAT_STAMINA_RATIO
        and "run" or "walk"
    reason = pressure and "ranged_avoiding_horde" or "ranged_disengage"
    return Internal.StartRetreat(
        record, zombie, target, math.min(5.5, retreatDistance),
        mode, 0.45, math.max(Const.COMBAT_KITE_RETREAT_LOCK_MS, 650),
        reason,
        report.staminaRatio <= Const.COMBAT_RETREAT_STAMINA_RATIO
            and "retreat" or nil,
        sourceX, sourceY, record.z
    )
end

local RELOAD_KITE_ANGLES = { 0, 0.785398, -0.785398, 1.570796, -1.570796 }

local function canStepTo(zombie, nx, ny, nz)
    local cell = type(getCell) == "function" and getCell() or nil
    if not cell or type(cell.getGridSquare) ~= "function" then
        return true
    end
    local nextSq = cell:getGridSquare(math.floor(nx), math.floor(ny), math.floor(nz))
    if not nextSq then return false end
    if type(nextSq.isSolidFloor) == "function" and nextSq:isSolidFloor() ~= true then
        return false
    end
    if type(nextSq.isFree) == "function" and nextSq:isFree(false) ~= true then
        return false
    end
    local curSq = zombie and type(zombie.getCurrentSquare) == "function"
        and zombie:getCurrentSquare() or nil
    if curSq and curSq ~= nextSq
        and type(curSq.isBlockedTo) == "function"
        and curSq:isBlockedTo(nextSq) == true
    then
        return false
    end
    return true
end

-- Collision-safe backpedal step while a reload bump animation is playing.
-- Moves the body away from nearby threats without switching Java action states
-- into PathFindState, so the reload animation continues uninterrupted.
function Tactics.StepReloadKite(record, zombie, target, now)
    if not record or not zombie or not target then return false, nil end
    now = tonumber(now) or (Core and Core.Now and Core.Now()) or 0
    record.runtime = record.runtime or {}
    if (tonumber(record.runtime.grappleHoldUntil) or 0) > now then
        return false, "grappled"
    end
    local rx = type(zombie.getX) == "function" and tonumber(zombie:getX()) or tonumber(record.x)
    local ry = type(zombie.getY) == "function" and tonumber(zombie:getY()) or tonumber(record.y)
    local rz = type(zombie.getZ) == "function" and tonumber(zombie:getZ()) or tonumber(record.z) or 0
    if rx == nil or ry == nil then return false, nil end

    local dist = math.sqrt(tonumber(target.distSq or 0) or 0)
    local preferredMin = tonumber(Const and Const.RANGED_PREFERRED_MIN_DISTANCE) or 5.0
    local report = Internal.AssessThreat and Internal.AssessThreat(record, target) or nil
    local pressure = report and (tonumber(report.pressureCount) or 0) >= 1
    if dist >= preferredMin and not pressure then
        record.runtime.lastReloadKiteAt = now
        return false, nil
    end

    local threatX, threatY = tonumber(target.x), tonumber(target.y)
    if pressure and Internal.BuildZombieThreatCentroid then
        local cx, cy = Internal.BuildZombieThreatCentroid(
            record, tonumber(Const and Const.COMBAT_HORDE_RADIUS) or 6
        )
        if cx ~= nil and cy ~= nil then
            threatX, threatY = cx, cy
        end
    end
    if threatX == nil or threatY == nil then return false, nil end

    local dx, dy = rx - threatX, ry - threatY
    local len = math.sqrt((dx * dx) + (dy * dy))
    if len < 0.001 then
        dx, dy = 1, 0
    else
        dx, dy = dx / len, dy / len
    end

    local lastAt = tonumber(record.runtime.lastReloadKiteAt) or (now - 100)
    local dt = math.max(0.04, math.min(0.25, (now - lastAt) / 1000))
    record.runtime.lastReloadKiteAt = now
    local step = math.min(0.34, 1.65 * dt)

    local baseAngle = math.atan2(dy, dx)
    for i = 1, #RELOAD_KITE_ANGLES do
        local ang = baseAngle + RELOAD_KITE_ANGLES[i]
        local nx = rx + math.cos(ang) * step
        local ny = ry + math.sin(ang) * step
        if canStepTo(zombie, nx, ny, rz) then
            if type(zombie.setX) == "function" then zombie:setX(nx) end
            if type(zombie.setY) == "function" then zombie:setY(ny) end
            if type(zombie.setNextX) == "function" then zombie:setNextX(nx) end
            if type(zombie.setNextY) == "function" then zombie:setNextY(ny) end
            record.x = nx
            record.y = ny
            return true, "reloading_kiting"
        end
    end
    return false, "reload_kite_blocked"
end

return Tactics
