-- Managed-body safety enforcement and suppressed-state recovery.

local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local Core = PNC.Core
local Diagnostics = PNC.PerformanceScalingDiagnostics
local SAFETY_REPAIR_LOGGED = setmetatable({}, { __mode = "k" })

function LiveBodyControl.EnforceManagedSafety(zombie, source)
    local actionState
    local hadTarget
    local wasUseless
    local hadTeeth
    local hadNativeCorpseDragFlag
    local modData
    local npcId
    local record
    local keepEngineMovementActive
    local now
    local actionLeaseActive
    local unsafeNativeTraversalState
    local needsImmediateRepair
    local seatedLockActive
    local sleepLockActive
    local bumpType
    if not zombie or not Core or not Core.IsManagedNPCBody
        or not Core.IsManagedNPCBody(zombie)
    then
        return false
    end
    if LiveBodyControl.RefreshNativeRemoteHeartbeat then
        LiveBodyControl.RefreshNativeRemoteHeartbeat(zombie)
    end
    if PNC.Registry and PNC.Registry.FindRecordByZombie then
        record = PNC.Registry.FindRecordByZombie(zombie)
    end
    if record
        and record.runtime
        and record.runtime.facilityActivity
        and record.runtime.facilityActivity.sleepWakePending == true
        and PNC.FacilityJobsBehaviorInternal
        and PNC.FacilityJobsBehaviorInternal.TickSleepWake
    then
        -- A stopped sleep scene may be followed by an order change, which
        -- removes FacilityActivity from normal job selection. Pump its wake
        -- transaction from the shared safety heartbeat so native release and
        -- surface cleanup cannot be stranded.
        PNC.FacilityJobsBehaviorInternal.TickSleepWake(record, zombie)
        return true
    end
    modData = zombie.getModData and zombie:getModData() or nil
    now = Core.Now and Core.Now() or 0
    seatedLockActive = LiveBodyControl.IsSeated
        and LiveBodyControl.IsSeated(record)
        and not LiveBodyControl.IsSeatedCombatActive(record, now)
        or false
    sleepLockActive = LiveBodyControl.IsSleeping
        and LiveBodyControl.IsSleeping(record)
        and not LiveBodyControl.IsSleepingCombatActive(record, now)
        or false
    bumpType = tostring(modData and modData.PNC_BumpRequestedType or "")
    -- A pre-fix seat lease may still carry the old default (false). Repair
    -- that state at the guard boundary so the lease cannot make this managed
    -- body useful while the seat owns the presentation.
    if seatedLockActive
        and modData
        and Internal.hasBumpActionLease(zombie, now)
        and bumpType == "PNC_SitChair"
    then
        modData.PNC_BumpKeepUseless = true
    end
    -- Sleep is also a persistent presentation lease. Older or replicated
    -- bodies may still carry the historical default that made the zombie
    -- engine useful, so repair it at the same shared safety boundary.
    if sleepLockActive
        and modData
        and Internal.hasBumpActionLease(zombie, now)
        and (bumpType == "PNC_Sleep" or bumpType == "PNC_SleepBed")
    then
        modData.PNC_BumpKeepUseless = true
    end
    keepEngineMovementActive =
        LiveBodyControl.ShouldKeepEngineMovementActive(record, zombie)
    hadTarget = zombie.getTarget and zombie:getTarget() ~= nil or false
    wasUseless = zombie.isUseless and zombie:isUseless() or false
    hadTeeth = zombie.isNoTeeth and not zombie:isNoTeeth() or false
    hadNativeCorpseDragFlag = zombie.isReanimatedForGrappleOnly
        and zombie:isReanimatedForGrappleOnly() or false
    actionState = LiveBodyControl.GetActionStateName(zombie)
    unsafeNativeTraversalState = actionState == "climbfence"
        or actionState == "climbwindow"
    actionLeaseActive = Internal.hasBumpActionLease(zombie, now)
        or Internal.hasNativeGetUpLease(zombie, now)
        or keepEngineMovementActive
            and (Internal.GROUNDED_STATES[actionState] == true
                or Internal.GETUP_STATES[actionState] == true)
    if actionState == "thump" and Diagnostics then
        Diagnostics.Increment("Body.UnsafeThumpStates")
    end
    needsImmediateRepair = hadTarget
        or (not wasUseless and not keepEngineMovementActive)
        or hadTeeth
        or hadNativeCorpseDragFlag
        or seatedLockActive
            and LiveBodyControl.IsSeatedNativeResetState(actionState)
        or sleepLockActive
            and LiveBodyControl.IsSleepingNativeResetState(actionState)
        or (
            (not keepEngineMovementActive or unsafeNativeTraversalState)
            and not actionLeaseActive
            and LiveBodyControl.IsSuppressedActionState(actionState)
        )
    LiveBodyControl.MaintainHumanizedBody(
        zombie,
        now,
        keepEngineMovementActive,
        needsImmediateRepair
    )
    if (not keepEngineMovementActive or unsafeNativeTraversalState)
        and not actionLeaseActive
        and LiveBodyControl.IsSuppressedActionState(actionState)
    then
        LiveBodyControl.SuppressZombieState(zombie, nil, now, true)
    end
    if seatedLockActive or sleepLockActive then
        -- The shared suppressed-state list intentionally does not claim
        -- turnalerted. Stationary presentation ownership does: it is a
        -- native zombie alert transition that can otherwise reacquire
        -- movement after this callback.
        LiveBodyControl.ReleaseSeatedMovement(
            record,
            zombie,
            sleepLockActive and "sleep_safety" or "seated_safety"
        )
        Internal.clearVanillaIntent(zombie)
        if seatedLockActive
            and LiveBodyControl.IsSeatedNativeResetState(actionState)
        then
            LiveBodyControl.ResetSeatedNativeMovementState(zombie)
        end
        if sleepLockActive
            and LiveBodyControl.IsSleepingNativeResetState(actionState)
        then
            LiveBodyControl.ResetSleepingNativeMovementState(zombie)
        end
    end
    if (
            hadTarget
            or (not wasUseless and not keepEngineMovementActive)
            or hadTeeth
            or hadNativeCorpseDragFlag
        )
        and not SAFETY_REPAIR_LOGGED[zombie]
        and Core.LogWarn
    then
        SAFETY_REPAIR_LOGGED[zombie] = true
        npcId = modData and modData.PNC_UUID or "unknown"
        Core.LogWarn("human_safety_repaired npc=" .. tostring(npcId)
            .. " source=" .. tostring(source or "unknown")
            .. " target=" .. tostring(hadTarget)
            .. " useless=" .. tostring(wasUseless)
            .. " hadTeeth=" .. tostring(hadTeeth)
            .. " nativeCorpseDragFlag=" .. tostring(hadNativeCorpseDragFlag))
    end
    return true
end

function LiveBodyControl.SuppressZombieState(
    zombie,
    lane,
    now,
    bodyFlagsApplied
)
    local actionState = LiveBodyControl.GetActionStateName(zombie)
    local needsIdleReset
    if not zombie then return false, actionState end
    if not LiveBodyControl.IsSuppressedActionState(actionState) then
        return false, actionState
    end
    if bodyFlagsApplied ~= true then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    needsIdleReset = Internal.IDLE_RESET_STATES[actionState or ""] == true
    if Internal.isDamageReactionState(actionState) then
        LiveBodyControl.ReleaseDamageReaction(zombie, actionState)
    end
    if zombie.setVariable and actionState == "climbfence" then
        zombie:setVariable("ClimbFenceStarted", false)
        zombie:setVariable("ClimbFenceFinished", true)
        zombie:setVariable("ClimbFenceOutcome", "")
    elseif zombie.setVariable and actionState == "climbwindow" then
        zombie:setVariable("ClimbWindowStarted", false)
        zombie:setVariable("ClimbWindowFinished", true)
        zombie:setVariable("ClimbWindowOutcome", "")
    end
    LiveBodyControl.SetManagedBodyUseless(zombie, true)
    if needsIdleReset
        and zombie.changeState
        and ZombieIdleState
        and ZombieIdleState.instance
    then
        zombie:changeState(ZombieIdleState.instance())
    end
    LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    return true, actionState
end
