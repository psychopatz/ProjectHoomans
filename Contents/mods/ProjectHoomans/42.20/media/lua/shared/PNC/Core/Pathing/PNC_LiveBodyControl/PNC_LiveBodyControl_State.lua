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

-- A seated managed body must not retain a native zombie movement/alert state
-- after the chair has become the presentation owner. Keep this narrower than
-- SUPPRESSED_STATES: turnalerted is still meaningful to ordinary movement,
-- but it is an unsafe native handoff while the body is seated.
local SEATED_NATIVE_RESET_STATES = {
    ["turnalerted"] = true,
    ["pathfind"] = true,
    ["walktoward"] = true,
    ["walktowardnetwork"] = true,
    ["lunge"] = true,
    ["lungenetwork"] = true,
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

function LiveBodyControl.IsSeated(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local roamingSeat = runtime and runtime.roamingSeat or nil
    if activity and activity.seating == true
        and (activity.seatEntered == true
            or activity.phase == "SEAT_ENTRY"
            or activity.phase == "SITTING"
            or activity.phase == "SEATED")
    then
        return true
    end
    return roamingSeat and roamingSeat.seating == true
        and (roamingSeat.seatEntered == true
            or roamingSeat.phase == "SEAT_ENTRY"
            or roamingSeat.phase == "SITTING"
            or roamingSeat.phase == "SEATED")
        or false
end

function LiveBodyControl.ReleaseSeatedMovement(record, zombie, reason)
    local runtime = record and record.runtime or nil
    local intent = runtime and runtime.moveIntent or nil
    local hasMovementOwner = runtime and (
        runtime.pathing ~= nil
            or runtime.localNavigation ~= nil
            or intent and intent.kind == "move"
    )
    if not hasMovementOwner then return false end
    if PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(zombie, record)
        return true
    end
    if PNC.EnginePathPlanner and PNC.EnginePathPlanner.Invalidate then
        PNC.EnginePathPlanner.Invalidate(record, reason or "seated_hold", zombie)
    end
    if runtime then
        runtime.moveIntent = nil
        runtime.pathing = nil
        runtime.localNavigation = nil
    end
    return true
end

function LiveBodyControl.IsSeatedCombatActive(record, now)
    local runtime = record and record.runtime or nil
    local health = record and record.health or nil
    local attackAction = runtime and runtime.attackAction or nil
    local target = runtime and runtime.target or nil
    local seatedThreat = runtime and runtime.seatedThreat or nil
    if not runtime then return false end
    now = tonumber(now) or (PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0)
    if type(target) == "table" and target.kind ~= nil then return true end
    if type(attackAction) == "table"
        and (attackAction.finishAt == nil
            or now < (tonumber(attackAction.finishAt) or 0))
    then
        return true
    end
    if seatedThreat and seatedThreat.active == true then return true end
    if now < (tonumber(runtime.inCombatUntil) or 0) then return true end
    return now < (tonumber(health and health.recentDamageUntil) or 0)
end

function LiveBodyControl.IsSeatedNativeResetState(actionState)
    actionState = string.lower(tostring(actionState or ""))
    return SEATED_NATIVE_RESET_STATES[actionState] == true
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

-- Seating has a second native-state lane that is not covered by the generic
-- movement state classes (notably turnalerted). Keep that reset explicitly
-- scoped to a live seat owner so combat and unrelated NPC movement cannot be
-- cleared by a general recovery call.
function LiveBodyControl.ResetSeatedNativeMovementState(zombie)
    local actionState
    if not zombie
        or not zombie.changeState
        or not ZombieIdleState
        or not ZombieIdleState.instance
    then
        return false
    end
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if not LiveBodyControl.IsSeatedNativeResetState(actionState) then
        return false
    end
    zombie:changeState(ZombieIdleState.instance())
    return true
end

-- Seat entry can occur between zombie-update callbacks. Stabilize the native
-- carrier at that ownership boundary so a stale walk/alert action cannot
-- survive into the first furniture scene frame.
function LiveBodyControl.StabilizeSeatedBody(record, zombie, now)
    local modData
    local actionState
    if not zombie or not LiveBodyControl.IsSeated(record)
        or LiveBodyControl.IsSeatedCombatActive(record, now)
    then
        return false
    end
    now = tonumber(now) or (PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0)
    LiveBodyControl.ReleaseSeatedMovement(record, zombie, "seated_entry")
    modData = zombie.getModData and zombie:getModData() or nil
    if Internal.hasBumpActionLease(zombie, now) then
        Internal.clearVanillaIntent(zombie)
        Internal.applyActionLeaseSafeguards(zombie, modData)
        return true
    end
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if LiveBodyControl.IsSeatedNativeResetState(actionState) then
        LiveBodyControl.ResetSeatedNativeMovementState(zombie)
    end
    LiveBodyControl.ApplyHumanizedBodyFlags(zombie, false)
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
