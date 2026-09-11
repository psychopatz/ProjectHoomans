-- Shared body-state classification and low-level intent/position control.

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}
PNC.LiveBodyControl.Internal = PNC.LiveBodyControl.Internal or {}

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local VANILLA_PASSAGE_GUARD_LOGGED = setmetatable({}, { __mode = "k" })

local NATIVE_PASSAGE_STATES = {
    ["climbfence"] = true,
    ["climbwindow"] = true,
    ["climbwall"] = true,
}

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
    ["walktoward"] = true,
    ["walktowardnetwork"] = true,
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
    ["walktoward"] = true,
    ["walktowardnetwork"] = true,
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

-- Read the action-context state through IsoGameCharacter's exposed wrapper.
-- getActionContext() returns an internal Java ActionContext userdata in Build
-- 42. Its methods are not exposed as a Lua object, so do not index it here.
function LiveBodyControl.GetActionContextStateName(zombie)
    local value
    if not zombie then
        return ""
    end
    if zombie.getCurrentActionContextStateName then
        value = zombie:getCurrentActionContextStateName()
    elseif zombie.getActionStateName then
        value = zombie:getActionStateName()
    end
    return string.lower(tostring(value or ""))
end

function LiveBodyControl.IsNativePassageState(actionState)
    return NATIVE_PASSAGE_STATES[
        string.lower(tostring(actionState or ""))
    ] == true
end

function LiveBodyControl.IsTraversalBumpType(bumpType)
    local value = string.lower(tostring(bumpType or ""))
    return string.find(value, "climbwindow", 1, true) ~= nil
        or string.find(value, "climbfence", 1, true) ~= nil
        or string.find(value, "climbwall", 1, true) ~= nil
end

local function passageObjectAtFeeler(zombie)
    local current
    local feeler
    if not zombie then return nil end
    current = zombie.getCurrentSquare and zombie:getCurrentSquare()
        or zombie.getSquare and zombie:getSquare() or nil
    feeler = zombie.getFeelerTile and zombie.getFeelersize
        and zombie:getFeelerTile(zombie:getFeelersize()) or nil
    if not current or not feeler
        or not current.testCollideSpecialObjects
    then
        return nil
    end
    return current:testCollideSpecialObjects(feeler)
end

-- IsoZombie.tryThump() runs after OnZombieUpdate and independently scans the
-- feeler tile. Managed IsoZombie carriers cannot safely enter that window
-- state because the Java path drops player-only BodyDamage fields. Detect the
-- same special object before the engine reaches tryThump and hand the frame
-- back to PNC's path/traversal retry lane.
function LiveBodyControl.GetVanillaPassageAhead(zombie)
    local object = passageObjectAtFeeler(zombie)
    local kind
    if not object or not instanceof then
        return nil, nil
    end
    if instanceof(object, "IsoWindow") then
        kind = "window"
    elseif instanceof(object, "IsoWindowFrame") then
        kind = "window_frame"
    elseif instanceof(object, "IsoThumpable") then
        kind = "thumpable"
    elseif instanceof(object, "IsoDoor") then
        kind = "door"
    else
        return nil, nil
    end
    return object, kind
end

local function passageMovementState(actionState)
    return actionState == "pathfind"
        or actionState == "walktoward"
        or actionState == "walktowardnetwork"
        or actionState == "lunge"
        or actionState == "lungenetwork"
end

function LiveBodyControl.BlockVanillaPassage(zombie, lane, now)
    local modData
    local actionState
    local object
    local kind
    local behavior
    if not zombie then return false end
    object, kind = LiveBodyControl.GetVanillaPassageAhead(zombie)
    if not object then
        VANILLA_PASSAGE_GUARD_LOGGED[zombie] = nil
        return false
    end
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if not passageMovementState(actionState) then
        return false
    end
    modData = zombie.getModData and zombie:getModData() or nil
    if modData
        and modData.PNC_BumpActionLease == true
        and LiveBodyControl.IsTraversalBumpType(
            modData.PNC_BumpRequestedType
        )
    then
        return false
    end
    behavior = zombie.getPathFindBehavior2
        and zombie:getPathFindBehavior2() or nil
    if behavior then
        if behavior.cancel then behavior:cancel() end
        if behavior.reset then behavior:reset() end
    end
    if zombie.setPath2 then zombie:setPath2(nil) end
    Internal.clearVanillaIntent(zombie)
    if LiveBodyControl.SuppressZombieState then
        LiveBodyControl.SuppressZombieState(zombie, lane, now)
    elseif zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    if not VANILLA_PASSAGE_GUARD_LOGGED[zombie]
        and PNC.Core
        and PNC.Core.LogWarn
    then
        VANILLA_PASSAGE_GUARD_LOGGED[zombie] = true
        PNC.Core.LogWarn(
            "[PNC][PATH] vanilla_passage_guard kind=" .. tostring(kind)
                .. " action=" .. tostring(actionState)
                .. " bump=" .. tostring(
                    modData and modData.PNC_BumpRequestedType or ""
                )
        )
    end
    return true, kind
end

-- Recover a stale vanilla passage through the exposed character state and
-- traversal variables. ActionContext itself is internal Java userdata and
-- cannot be indexed or mutated from Lua in Build 42.
function LiveBodyControl.ResetNativePassageActionContext(zombie)
    local actionState
    local recovered = false
    if not zombie then
        return false
    end
    actionState = LiveBodyControl.GetActionContextStateName(zombie)
    if not LiveBodyControl.IsNativePassageState(actionState) then
        return false
    end

    -- Set the normal completion latch first so the engine ActionContext can
    -- transition climbfence/climbwindow back to idle on its next update.
    if LiveBodyControl.SuppressZombieState then
        recovered = LiveBodyControl.SuppressZombieState(
            zombie, nil, nil
        ) == true
    end

    if LiveBodyControl.ResetNativeMovementState
        and LiveBodyControl.ResetNativeMovementState(zombie)
    then
        recovered = true
    end
    return recovered
end

-- Animation scenes and native passage playback share the same BumpType and
-- action-state channels. A drink/wipe scene must not replace a live window
-- or fence owner; doing so leaves the passage controller with no valid
-- completion edge.
function LiveBodyControl.CheckBumpOwnership(zombie, incomingBumpType, now)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    local currentBump = modData
        and tostring(modData.PNC_BumpRequestedType or "") or ""
    local actionState = LiveBodyControl.GetActionContextStateName(zombie)
    local incomingTraversal = LiveBodyControl.IsTraversalBumpType(
        incomingBumpType
    )
    local leaseActive = modData
        and modData.PNC_BumpActionLease == true
    local releasePending = modData
        and modData.PNC_BumpReleasePending == true
    local leaseUntil
    now = tonumber(now)
        or PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if leaseActive then
        leaseUntil = tonumber(modData.PNC_BumpActionLeaseUntil)
        if leaseUntil and now > leaseUntil and not releasePending then
            leaseActive = false
        end
    end
    if (leaseActive or releasePending)
        and LiveBodyControl.IsTraversalBumpType(currentBump)
        and not incomingTraversal
    then
        return false, "traversal_owner", actionState, currentBump
    end
    if LiveBodyControl.IsNativePassageState(actionState)
        and not incomingTraversal
        and not (
            (leaseActive or releasePending)
            and LiveBodyControl.IsTraversalBumpType(currentBump)
        )
    then
        LiveBodyControl.ResetNativePassageActionContext(zombie)
        -- Recovery may fail on a partially replicated body. The important
        -- invariant is still that a drink/attack/treatment can never claim a
        -- native passage state in that frame. Leave the scene key unset so it
        -- can retry after the ActionContext reaches idle.
        return false, "native_passage_owner", actionState, currentBump
    end
    return true, nil, actionState, currentBump
end

-- The legacy zombie state machine is updated after OnZombieUpdate. A managed
-- passage owns movement through PNC's traversal action, but the old movement
-- state can still reach IsoZombie.tryThump/collideWith in that same engine
-- frame and enter vanilla window/fence states. Those states assume a player
-- BodyDamage carrier and can leave a managed zombie in a permanent bump pose.
-- Clear only the legacy movement/traversal states that can initiate or retain
-- vanilla passage handling; leave combat and already-owned action states alone.
function LiveBodyControl.ResetNativeMovementState(zombie)
    local moving = false
    if not zombie
        or not zombie.isCurrentState
        or not zombie.changeState
        or not ZombieIdleState
        or not ZombieIdleState.instance
    then
        return false
    end
    if PathFindState
        and PathFindState.instance
        and zombie:isCurrentState(PathFindState.instance())
    then
        moving = true
    elseif WalkTowardState
        and WalkTowardState.instance
        and zombie:isCurrentState(WalkTowardState.instance())
    then
        moving = true
    elseif WalkTowardNetworkState
        and WalkTowardNetworkState.instance
        and zombie:isCurrentState(WalkTowardNetworkState.instance())
    then
        moving = true
    elseif LungeState
        and LungeState.instance
        and zombie:isCurrentState(LungeState.instance())
    then
        moving = true
    elseif LungeNetworkState
        and LungeNetworkState.instance
        and zombie:isCurrentState(LungeNetworkState.instance())
    then
        moving = true
    elseif ClimbThroughWindowState
        and ClimbThroughWindowState.instance
        and zombie:isCurrentState(ClimbThroughWindowState.instance())
    then
        moving = true
    elseif ClimbOverFenceState
        and ClimbOverFenceState.instance
        and zombie:isCurrentState(ClimbOverFenceState.instance())
    then
        moving = true
    elseif ClimbOverWallState
        and ClimbOverWallState.instance
        and zombie:isCurrentState(ClimbOverWallState.instance())
    then
        moving = true
    end
    if not moving then return false end
    zombie:changeState(ZombieIdleState.instance())
    return true
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
