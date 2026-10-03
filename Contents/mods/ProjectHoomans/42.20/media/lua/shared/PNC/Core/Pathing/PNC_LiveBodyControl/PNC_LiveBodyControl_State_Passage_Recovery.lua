local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local ActorControl = PNC.ActorControl
function LiveBodyControl.ResetNativePassageActionContext(zombie)
    local actionState
    local recovered = false
    local context
    local group
    local initialState
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

    -- ActionContext is Java-backed userdata in Build 42. Kahlua throws when
    -- Lua indexes an unexposed Java method instead of returning nil, so only
    -- inspect plain Lua table adapters here. The completion variables above
    -- let the engine-owned context return to idle on its next update.
    if zombie.getActionContext then
        context = zombie:getActionContext()
    end
    if type(context) == "table" and context.getGroup then
        group = context:getGroup()
    end
    if type(group) == "table" and group.getInitialState then
        initialState = group:getInitialState()
    end
    if type(context) == "table"
        and context.setCurrentState
        and initialState
    then
        context:setCurrentState(initialState)
        recovered = true
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
        or not zombie.changeState
        or not ZombieIdleState
        or not ZombieIdleState.instance
    then
        return false
    end
    if zombie.isCurrentState and PathFindState
        and PathFindState.instance
        and zombie:isCurrentState(PathFindState.instance())
    then
        moving = true
    elseif zombie.isCurrentState and WalkTowardState
        and WalkTowardState.instance
        and zombie:isCurrentState(WalkTowardState.instance())
    then
        moving = true
    elseif zombie.isCurrentState and WalkTowardNetworkState
        and WalkTowardNetworkState.instance
        and zombie:isCurrentState(WalkTowardNetworkState.instance())
    then
        moving = true
    elseif zombie.isCurrentState and LungeState
        and LungeState.instance
        and zombie:isCurrentState(LungeState.instance())
    then
        moving = true
    elseif zombie.isCurrentState and LungeNetworkState
        and LungeNetworkState.instance
        and zombie:isCurrentState(LungeNetworkState.instance())
    then
        moving = true
    elseif zombie.isCurrentState and ClimbThroughWindowState
        and ClimbThroughWindowState.instance
        and zombie:isCurrentState(ClimbThroughWindowState.instance())
    then
        moving = true
    elseif zombie.isCurrentState and ClimbOverFenceState
        and ClimbOverFenceState.instance
        and zombie:isCurrentState(ClimbOverFenceState.instance())
    then
        moving = true
    elseif zombie.isCurrentState and ClimbOverWallState
        and ClimbOverWallState.instance
        and zombie:isCurrentState(ClimbOverWallState.instance())
    then
        moving = true
    end
    if not moving then return false end
    zombie:changeState(ZombieIdleState.instance())
    return true
end

-- Stationary presentations have a second native-state lane that is not
-- covered by the generic movement state classes (notably turnalerted). Keep
-- that reset explicit so combat and unrelated NPC movement cannot be cleared
-- by a general recovery call.
