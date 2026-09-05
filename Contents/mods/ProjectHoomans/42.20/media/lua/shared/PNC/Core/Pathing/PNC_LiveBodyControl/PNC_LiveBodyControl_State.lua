-- Shared body-state classification and low-level intent/position control.

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}
PNC.LiveBodyControl.Internal = PNC.LiveBodyControl.Internal or {}

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal

Internal.GROUNDED_STATES = {
    ["falldown"] = true,
    ["onground"] = true,
    ["onground-ragdoll"] = true,
    ["staggerback-knockeddown"] = true,
}
Internal.GETUP_STATES = {
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
}
Internal.SUPPRESSED_STATES = {
    ["attack"] = true,
    ["attack-network"] = true,
    ["bumped"] = true,
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["lunge"] = true,
    ["onground"] = true,
    ["onground-ragdoll"] = true,
    ["pathfind"] = true,
    ["sitonground"] = true,
    ["staggerback"] = true,
    ["staggerback-knockeddown"] = true,
    ["thump"] = true,
}
Internal.IDLE_RESET_STATES = {
    ["attack"] = true,
    ["attack-network"] = true,
    ["bumped"] = true,
    ["getup"] = true,
    ["getup-fromonback"] = true,
    ["getup-fromonfront"] = true,
    ["getup-fromsitting"] = true,
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["lunge"] = true,
    ["pathfind"] = true,
    ["thump"] = true,
}

function Internal.clearVanillaIntent(zombie)
    if not zombie then return false end
    if zombie.setTarget then zombie:setTarget(nil) end
    if zombie.setTargetSeenTime then zombie:setTargetSeenTime(0) end
    if zombie.setEatBodyTarget then zombie:setEatBodyTarget(nil, false) end
    if zombie.setThumpTarget
        and (not zombie.getThumpTarget or zombie:getThumpTarget() ~= nil)
    then
        zombie:setThumpTarget(nil)
    end
    if zombie.clearAggroList then zombie:clearAggroList() end
    if zombie.setAttackedBy then zombie:setAttackedBy(nil) end
    return true
end

function Internal.isDamageReactionState(actionState)
    actionState = string.lower(tostring(actionState or ""))
    return string.find(actionState, "staggerback", 1, true) == 1
        or string.find(actionState, "hitreaction", 1, true) == 1
end

function LiveBodyControl.SetAuthoritativePosition(zombie, x, y, z)
    if not zombie then return false end
    zombie:setX(x)
    zombie:setY(y)
    zombie:setZ(z)
    if zombie.setLastX then zombie:setLastX(x) end
    if zombie.setLastY then zombie:setLastY(y) end
    if zombie.setLastZ then zombie:setLastZ(z) end
    return true
end

function LiveBodyControl.IsSuppressedActionState(actionState)
    if not actionState or actionState == "" then return false end
    actionState = string.lower(tostring(actionState))
    return Internal.SUPPRESSED_STATES[actionState] == true
        or Internal.isDamageReactionState(actionState)
end

function LiveBodyControl.GetActionStateName(zombie)
    if not zombie or not zombie.getActionStateName then return "" end
    return string.lower(tostring(zombie:getActionStateName() or ""))
end

function LiveBodyControl.IsGrounded(zombie)
    local actionState
    if not zombie then return false, "" end
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if Internal.GROUNDED_STATES[actionState] == true
        or string.find(actionState, "knockeddown", 1, true) ~= nil
        or string.find(actionState, "ragdoll", 1, true) ~= nil
    then
        return true, actionState
    end
    if zombie.isOnFloor and zombie:isOnFloor() then return true, actionState end
    if zombie.isKnockedDown and zombie:isKnockedDown() then
        return true, actionState
    end
    return false, actionState
end

function LiveBodyControl.SyncLocomotionState(zombie, moving)
    local actionState
    if not zombie then return false end
    moving = moving == true
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if moving then
        return actionState == "walktoward"
            or actionState == "idle"
            or actionState == ""
    end
    if actionState == "walktoward"
        and zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
        return true
    end
    return actionState == "idle" or actionState == ""
end

function LiveBodyControl.SuppressVanillaIntent(
    zombie,
    keepEngineMovementActive
)
    if not Internal.clearVanillaIntent(zombie) then return false end
    if zombie.setVariable then
        -- A managed body is an IsoZombie carrier. Clearing target references
        -- is not enough: the native zombie brain can reacquire a player
        -- between this call and the next maintenance pass.
        zombie:setVariable("NoLungeTarget", true)
        zombie:setVariable("NoLungeAttack", true)
        zombie:setVariable("PNCLive", true)
    end
    LiveBodyControl.SetManagedBodyUseless(
        zombie,
        true,
        keepEngineMovementActive
    )
    return true
end
