-- Non-locomotion recovery and native path/body ownership reset.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Core = Internal.Core
local LiveBodyControl = Internal.LiveBodyControl

local ALLOWED_MOVE_ACTION_STATES = {
    [""] = true,
    ["idle"] = true,
    ["walktoward"] = true,
}

local function resetNonLocomotionTracking(lane)
    if not lane then
        return
    end
    lane.lastNonLocomotionState = nil
    lane.lastNonLocomotionAt = 0
end

function Internal.tryRecoverNonLocomotionState(record, zombie, lane, now)
    local actionState
    if not zombie or not lane then
        return false, nil
    end
    now = tonumber(now) or Core.Now()
    actionState = Internal.getActionStateName(zombie)
    if ALLOWED_MOVE_ACTION_STATES[actionState or ""] then
        resetNonLocomotionTracking(lane)
        return false, actionState
    end
    if Internal.hasActiveAttack(record, now, zombie)
        or (tonumber(lane.specialMoveUntil) or 0) > now
        or (tonumber(lane.combatFacingUntil) or 0) > now
        or (LiveBodyControl and LiveBodyControl.IsSuppressedActionState and LiveBodyControl.IsSuppressedActionState(actionState))
    then
        resetNonLocomotionTracking(lane)
        return false, actionState
    end
    if tostring(lane.ownerMode or "") ~= "fake_locomotion" then
        resetNonLocomotionTracking(lane)
        return false, actionState
    end
    if lane.lastNonLocomotionState ~= actionState then
        lane.lastNonLocomotionState = actionState
        lane.lastNonLocomotionAt = now
        return false, actionState
    end
    if (now - (tonumber(lane.lastNonLocomotionAt) or 0)) < Internal.NON_LOCOMOTION_RECOVERY_MS then
        return false, actionState
    end
    Internal.hardResetMoveOwner(zombie)
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
    if zombie.changeState and ZombieIdleState and ZombieIdleState.instance then
        zombie:changeState(ZombieIdleState.instance())
    end
    resetNonLocomotionTracking(lane)
    return true, actionState
end

function Internal.resetPathController(zombie)
    local behavior
    if not zombie then
        return
    end
    if Internal.getActionStateName and Internal.getActionStateName(zombie) == "walktoward"
        and zombie.changeState and ZombieIdleState and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    if zombie.getPathFindBehavior2 then
        behavior = zombie:getPathFindBehavior2()
        if behavior then
            behavior:cancel()
            behavior:reset()
        end
    end
    if zombie.setPath2 then
        zombie:setPath2(nil)
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
end

function Internal.hardResetMoveOwner(zombie, preserveVisualMotion)
    if not zombie then
        return
    end
    Internal.resetPathController(zombie)
    if zombie.clearAggroList then
        zombie:clearAggroList()
    end
    if zombie.setTarget then
        zombie:setTarget(nil)
    end
    if preserveVisualMotion ~= true
        and zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    if preserveVisualMotion ~= true and zombie.setRunning then
        zombie:setRunning(false)
    end
end
