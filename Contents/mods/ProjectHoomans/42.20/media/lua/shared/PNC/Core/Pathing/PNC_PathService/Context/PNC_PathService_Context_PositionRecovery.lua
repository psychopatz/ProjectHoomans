-- Invalid live-position recovery and vehicle-goal quarantine.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Core = Internal.Core

local function activeMovementGoal(record, lane)
    local intent = record and record.runtime and record.runtime.moveIntent or nil
    if intent and intent.kind == "move" then
        return intent
    end
    return lane and (lane.pendingGoal or lane.goal) or nil
end

local function quarantineVehicleBlockedGoal(record, lane, fromX, fromY, fromZ, now)
    local goal = activeMovementGoal(record, lane)
    if not lane or not goal then
        return
    end
    lane.vehicleBlockedGoalX = tonumber(goal.x)
    lane.vehicleBlockedGoalY = tonumber(goal.y)
    lane.vehicleBlockedGoalZ = tonumber(goal.z)
    lane.vehicleBlockedFromX = tonumber(fromX)
    lane.vehicleBlockedFromY = tonumber(fromY)
    lane.vehicleBlockedFromZ = tonumber(fromZ)
    lane.vehicleBlockedAt = tonumber(now) or Core.Now()
    lane.vehicleBlockedReason = tostring(
        goal.reason or lane.intentReason or "vehicle_path_blocked"
    )
    lane.pendingGoal = nil
    lane.cancelReason = "vehicle_path_blocked"
    if lane.phase == "active" or lane.phase == "requested"
        or lane.phase == "cancel_pending"
    then
        lane.phase = "cancel_pending"
    else
        lane.phase = "idle"
        lane.ownerMode = "idle"
    end
end

local function applyRecoveredBody(
    record,
    zombie,
    lane,
    now,
    reason,
    fromX,
    fromY,
    fromZ,
    safeX,
    safeY,
    safeZ
)
    if Internal.LiveBodyControl and Internal.LiveBodyControl.SetAuthoritativePosition then
        Internal.LiveBodyControl.SetAuthoritativePosition(zombie, safeX, safeY, safeZ)
    else
        zombie:setX(safeX)
        zombie:setY(safeY)
        zombie:setZ(safeZ)
    end
    Internal.syncRecordPosition(record, zombie)
    lane.lastProgressAt = now
    lane.lastIssueAt = now
    lane.lastStepAt = now
    lane.lastX = safeX
    lane.lastY = safeY
    lane.lastZ = safeZ
    lane.noProgressCount = 0
    lane.recoveryCount = (tonumber(lane.recoveryCount) or 0) + 1
    lane.lastRecoveryReason = "position_" .. tostring(reason)
    lane.lastRecoverAt = now
    Internal.clearBlockedStep(lane)
    lane.steeringSide = nil
    lane.directStepCount = 0
    if reason == "vehicle" then
        if lane.traversalAction and Internal.clearTraversalAction then
            Internal.clearTraversalAction(
                zombie,
                lane,
                "vehicle_position_recovery"
            )
        end
        quarantineVehicleBlockedGoal(
            record,
            lane,
            fromX,
            fromY,
            fromZ,
            now
        )
    end
end

local function recordRecovery(
    record,
    now,
    reason,
    fromX,
    fromY,
    fromZ,
    safeX,
    safeY,
    safeZ
)
    local recovery
    local message
    local logKey
    local shouldLog
    record.runtime = record.runtime or {}
    recovery = record.runtime.positionRecovery or {}
    record.runtime.positionRecovery = recovery
    recovery.count = (tonumber(recovery.count) or 0) + 1
    recovery.lastAt = now
    recovery.lastEvent = "live_unstuck"
    recovery.lastReason = reason
    recovery.fromX = fromX
    recovery.fromY = fromY
    recovery.fromZ = fromZ
    recovery.toX = safeX
    recovery.toY = safeY
    recovery.toZ = safeZ
    record.runtime.forceSyncEvent = "position_recovery"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "position_recovery")
    end
    message = "NPC position recovery npc=" .. tostring(record.id)
        .. " name=" .. tostring(record.name or "Unknown NPC")
        .. " event=live_unstuck"
        .. " reason=" .. tostring(reason)
        .. " from=" .. tostring(fromX) .. "," .. tostring(fromY) .. "," .. tostring(fromZ)
        .. " to=" .. tostring(safeX) .. "," .. tostring(safeY) .. "," .. tostring(safeZ)
        .. " count=" .. tostring(recovery.count)
    logKey = tostring(reason)
        .. ":"
        .. tostring(math.floor(tonumber(fromX) or 0))
        .. ":"
        .. tostring(math.floor(tonumber(fromY) or 0))
        .. ":"
        .. tostring(math.floor(tonumber(fromZ) or 0))
    shouldLog = recovery.lastLogKey ~= logKey
        or now - (tonumber(recovery.lastLogAt) or 0)
            >= Internal.POSITION_RECOVERY_LOG_INTERVAL_MS
    if shouldLog then
        recovery.lastLogKey = logKey
        recovery.lastLogAt = now
        recovery.suppressedLogs = 0
        Core.LogWarn(message)
        if Core.LogRecordDebug then
            Core.LogRecordDebug(record, message)
        end
    else
        recovery.suppressedLogs = (tonumber(recovery.suppressedLogs) or 0) + 1
    end
end

function Internal.repairInvalidBodyPosition(record, zombie, lane, now)
    local query = Internal.TraversalQuery or PNC.TraversalQuery
    local reason
    local fromX
    local fromY
    local fromZ
    local safeX
    local safeY
    local safeZ
    if not record or not zombie or not lane
        or not query
        or not query.GetOccupancyReason
        or not query.FindNearestOccupable
    then
        return false, nil
    end
    now = tonumber(now) or Core.Now()
    if now < (tonumber(lane.nextPositionSafetyAt) or 0) then
        return false, nil
    end
    lane.nextPositionSafetyAt = now + 500
    fromX = zombie:getX()
    fromY = zombie:getY()
    fromZ = zombie:getZ()
    reason = query.GetOccupancyReason(fromX, fromY, fromZ)
    -- The current body naturally makes some square APIs report occupied.
    -- Repair only immutable geometry or a vehicle footprint here.
    if reason ~= "vehicle" and reason ~= "solid" and reason ~= "solid_trans" then
        return false, reason
    end
    safeX, safeY, safeZ = query.FindNearestOccupable(
        fromX,
        fromY,
        fromZ,
        4
    )
    if safeX == nil or safeY == nil or safeZ == nil then
        return false, "no_safe_square:" .. tostring(reason)
    end
    applyRecoveredBody(
        record,
        zombie,
        lane,
        now,
        reason,
        fromX,
        fromY,
        fromZ,
        safeX,
        safeY,
        safeZ
    )
    recordRecovery(
        record,
        now,
        reason,
        fromX,
        fromY,
        fromZ,
        safeX,
        safeY,
        safeZ
    )
    return true, reason
end
