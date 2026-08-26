-- World lookup and live body-state accessors used across PathService.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Core = Internal.Core
local Animation = Internal.Animation
local LiveBodyControl = Internal.LiveBodyControl
local TraversalQuery = Internal.TraversalQuery

function Internal.clearBlockedStep(lane)
    if not lane then return end
    lane.blockedStepFromX = nil
    lane.blockedStepFromY = nil
    lane.blockedStepFromZ = nil
    lane.blockedStepToX = nil
    lane.blockedStepToY = nil
    lane.blockedStepToZ = nil
    lane.blockedStepReason = nil
end

function Internal.roundHalf(value)
    if value >= 0 then
        return math.floor(value + 0.5)
    end
    return math.ceil(value - 0.5)
end

function Internal.getSquare(x, y, z)
    if not getCell then
        return nil
    end
    return getCell():getGridSquare(math.floor(x), math.floor(y), z)
end

function Internal.isSquareWalkable(x, y, z)
    if TraversalQuery and TraversalQuery.CanTraverseAt then
        return TraversalQuery.CanTraverseAt(x, y, z)
    end
    if TraversalQuery and TraversalQuery.CanOccupy then
        return TraversalQuery.CanOccupy(x, y, z)
    end
    return false
end

function Internal.syncRecordPosition(record, zombie)
    if not record or not zombie then
        return
    end
    record.x = zombie:getX()
    record.y = zombie:getY()
    record.z = zombie:getZ()
end

function Internal.isMovementDebugEnabled(record)
    if Core and Core.IsRecordDebugEnabled then
        return Core.IsRecordDebugEnabled(record)
    end
    return false
end

function Internal.hasActiveAttack(record, now, zombie)
    local runtime = record and record.runtime or nil
    local attackAction = runtime and runtime.attackAction or nil
    now = tonumber(now) or Core.Now()
    if attackAction ~= nil
        and now < (tonumber(attackAction.finishAt) or 0)
    then
        return true
    end
    return zombie ~= nil
        and Animation
        and Animation.IsCombatBumpActionActive
        and Animation.IsCombatBumpActionActive(zombie, now)
        or false
end

function Internal.getActionStateName(zombie)
    if LiveBodyControl and LiveBodyControl.GetActionStateName then
        return LiveBodyControl.GetActionStateName(zombie)
    end
    if not zombie or not zombie.getActionStateName then
        return ""
    end
    return string.lower(tostring(zombie:getActionStateName() or ""))
end

function Internal.hasPath2(zombie)
    if not zombie or not zombie.getPath2 then
        return false
    end
    return zombie:getPath2() ~= nil
end
