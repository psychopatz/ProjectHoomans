-- Grounded-body recovery orchestration.

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function isRagdollSimulationActive(zombie)
    return zombie
        and zombie.isRagdollSimulationActive
        and zombie:isRagdollSimulationActive() == true
        or false
end

local function promoteSettledRagdoll(zombie, actionState)
    local groundedState
    if not actionState
        or string.find(actionState, "ragdoll", 1, true) == nil
        or isRagdollSimulationActive(zombie)
        or not zombie.changeState
        or not ZombieOnGroundState
        or not ZombieOnGroundState.instance
    then
        return actionState
    end
    groundedState = ZombieOnGroundState.instance()
    if groundedState then
        zombie:changeState(groundedState)
        return LiveBodyControl.GetActionStateName(zombie)
    end
    return actionState
end

function LiveBodyControl.RecoverGroundedBody(record, zombie, reason)
    local now
    local recovery
    if not zombie then return false end
    if PNC.Combat and PNC.Combat.CancelAttackAction then
        PNC.Combat.CancelAttackAction(
            record,
            zombie,
            nil,
            reason or "grounded_recovery"
        )
    elseif record and record.runtime then
        record.runtime.attackAction = nil
    end
    Internal.prepareNativeGetUp(zombie)
    if zombie.setVariable then
        -- PathFindBehavior2 uses this callback-owned variable to select the
        -- get-up transition after a settled floor/ragdoll state.
        zombie:setVariable("ShouldStandUp", true)
    end
    now = Core and Core.Now and Core.Now() or 0
    recovery = record and record.runtime
        and record.runtime.groundedRecovery or nil
    Internal.beginNativeGetUpLease(zombie, now)
    if record and record.runtime then
        recovery = recovery or {}
        recovery.getUpStarted = true
        recovery.getUpStartedAt = now
        record.runtime.groundedRecovery = recovery
        record.runtime.forceSyncEvent = "grounded_recovery"
    end
    if Diagnostics then
        Diagnostics.Increment("Body.GroundedRecoveries")
        Diagnostics.Increment("Body.GetUpAnimations")
        Diagnostics.Increment("Body.NativeGetUpTransitions")
    end
    return true
end

function LiveBodyControl.TickGroundedRecovery(record, zombie, now)
    local grounded, actionState = LiveBodyControl.IsGrounded(zombie)
    local state = record and record.runtime
        and record.runtime.groundedRecovery or nil
    local attacker
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if Internal.intentionallyGrounded(record) then
        if record and record.runtime then
            record.runtime.groundedRecovery = nil
        end
        Internal.clearNativeGetUpLease(zombie)
        return false
    end
    -- Ragdoll simulation owns the body until it settles.  Starting the get-up
    -- lease while physics is still active leaves the carrier in a permanent
    -- floor pose and makes the next animation state fight the physics state.
    if isRagdollSimulationActive(zombie) then
        record.runtime = record.runtime or {}
        state = record.runtime.groundedRecovery or {}
        state.startedAt = now
        record.runtime.groundedRecovery = state
        record.activeBehavior = "Grounded:ragdoll"
        if PNC.BehaviorMoveIntent and PNC.BehaviorMoveIntent.Hold then
            PNC.BehaviorMoveIntent.Hold(record, "actor_ragdoll")
        end
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
        Internal.clearVanillaIntent(zombie)
        return true
    end
    if state and state.getUpStarted == true then
        if grounded or Internal.GETUP_STATES[actionState] == true then
            if not Internal.hasNativeGetUpLease(zombie, now) then
                Internal.beginNativeGetUpLease(zombie, now)
            elseif grounded and zombie.setReanimateTimer then
                zombie:setReanimateTimer(0)
            end
            record.activeBehavior = "Grounded:getting_up"
            if PNC.BehaviorMoveIntent and PNC.BehaviorMoveIntent.Hold then
                PNC.BehaviorMoveIntent.Hold(record, "actor_getting_up")
            end
            return true
        end
        record.runtime.groundedRecovery = nil
        Internal.clearNativeGetUpLease(zombie)
        return false
    end
    if not grounded then
        if record and record.runtime
            and Internal.GETUP_STATES[actionState] ~= true
        then
            record.runtime.groundedRecovery = nil
            Internal.clearNativeGetUpLease(zombie)
        end
        return Internal.GETUP_STATES[actionState] == true
    end
    record.runtime = record.runtime or {}
    state = record.runtime.groundedRecovery or {
        startedAt = now,
        counterAttempted = false,
    }
    record.runtime.groundedRecovery = state
    actionState = promoteSettledRagdoll(zombie, actionState)
    record.activeBehavior = "Grounded:recovering"
    if PNC.Combat and PNC.Combat.CancelAttackAction then
        PNC.Combat.CancelAttackAction(record, zombie, nil, "actor_grounded")
    else
        record.runtime.attackAction = nil
    end
    if PNC.BehaviorMoveIntent and PNC.BehaviorMoveIntent.Hold then
        PNC.BehaviorMoveIntent.Hold(record, "actor_grounded")
    end
    attacker = Internal.resolveGroundAttacker(record, zombie)
    if attacker and Internal.isFriendlyGroundAttacker(record, attacker) then
        return LiveBodyControl.RecoverGroundedBody(
            record,
            zombie,
            "friendly_owner_push"
        )
    end
    if attacker and state.counterAttempted ~= true then
        state.counterAttempted = true
        if Internal.randomUnit() < (
            tonumber(
                PNC.Const and PNC.Const.NPC_GROUNDED_COUNTER_STAGGER_CHANCE
            ) or 0.40
        ) then
            state.counterSucceeded = Internal.counterStagger(
                record,
                zombie,
                attacker
            )
        end
    end
    if now - (tonumber(state.startedAt) or now) >= (
        tonumber(PNC.Const and PNC.Const.NPC_GROUNDED_RECOVERY_MS) or 1400
    ) then
        return LiveBodyControl.RecoverGroundedBody(
            record,
            zombie,
            "grounded_timeout"
        )
    end
    LiveBodyControl.SetManagedBodyUseless(zombie, true)
    Internal.clearVanillaIntent(zombie)
    return true
end
