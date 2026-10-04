local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local ActorControl = PNC.ActorControl

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
    local record
    if not zombie then return false end
    record = PNC.Registry and PNC.Registry.FindRecordByZombie
        and PNC.Registry.FindRecordByZombie(zombie) or nil
    -- This is the legacy authoritative-position escape hatch used by seat,
    -- abstract-recovery, and traversal helpers. Puppet Opera placement is
    -- movement-owned and must never be replaced by a raw coordinate write.
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        if ActorControl.NoteBlocked then
            ActorControl.NoteBlocked(
                record,
                "authoritative_position",
                "puppet_opera_writer_blocked:authoritative_position"
            )
        end
        return false
    end
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

function LiveBodyControl.EnforceManagedNativeIntent(zombie)
    -- Callers are already on a managed-body boundary. This primitive owns
    -- only the native intent reset; higher-level body suppression adds its
    -- own useless/movement state after calling it.
    local actionState
    local modData
    local record
    local lane
    local ownedTraversal = false
    if not zombie then return false end
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if LiveBodyControl.IsNativePassageState
        and LiveBodyControl.IsNativePassageState(actionState)
    then
        modData = zombie.getModData and zombie:getModData() or nil
        ownedTraversal = modData
            and modData.PNC_BumpActionLease == true
            and LiveBodyControl.IsTraversalBumpType
            and LiveBodyControl.IsTraversalBumpType(
                modData.PNC_BumpRequestedType
            )
            or false
        if not ownedTraversal
            and PNC.Registry
            and PNC.Registry.FindRecordByZombie
        then
            record = PNC.Registry.FindRecordByZombie(zombie)
            lane = record and record.runtime
                and record.runtime.pathing or nil
            ownedTraversal = lane
                and (lane.traversalAction ~= nil
                    or lane.vanillaFenceAction ~= nil)
                or false
        end
        if not ownedTraversal then
            -- IsoZombie carriers do not have the player BodyDamage object
            -- expected by ClimbOverFenceState/ClimbThroughWindowState. A
            -- stale native passage state must be released before Java can
            -- re-enter the same state and throw every frame.
            local behavior = zombie.getPathFindBehavior2
                and zombie:getPathFindBehavior2() or nil
            if behavior then
                if behavior.cancel then behavior:cancel() end
                if behavior.reset then behavior:reset() end
            end
            if zombie.setPath2 then zombie:setPath2(nil) end
            if LiveBodyControl.SuppressZombieState then
                LiveBodyControl.SuppressZombieState(
                    zombie,
                    nil,
                    PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
                    true
                )
            end
            if record and record.runtime then
                record.runtime.nativePassageRecovery = {
                    state = actionState,
                    reason = "unowned_managed_native_passage",
                    at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
                }
            end
        end
    end
    if not Internal.clearVanillaIntent(zombie) then return false end
    if zombie.setVariable then
        -- A managed body is an IsoZombie carrier. Clearing target references
        -- is not enough: the native zombie brain can reacquire a player
        -- between this call and the next maintenance pass.
        zombie:setVariable("NoLungeTarget", true)
        zombie:setVariable("NoLungeAttack", true)
        zombie:setVariable("PNCLive", true)
    end
    -- Native combat must never target a managed shell. PNC's abstract bite
    -- lane uses BumpedChr and Health.ApplyDamage, so this does not disable
    -- NPC-vs-zombie combat; it only blocks the player-shaped Java path.
    if zombie.setZombiesDontAttack then
        zombie:setZombiesDontAttack(true)
    end
    return true
end

function LiveBodyControl.SuppressVanillaIntent(
    zombie,
    keepEngineMovementActive
)
    if not LiveBodyControl.EnforceManagedNativeIntent(zombie) then
        return false
    end
    LiveBodyControl.SetManagedBodyUseless(
        zombie,
        true,
        keepEngineMovementActive
    )
    return true
end
