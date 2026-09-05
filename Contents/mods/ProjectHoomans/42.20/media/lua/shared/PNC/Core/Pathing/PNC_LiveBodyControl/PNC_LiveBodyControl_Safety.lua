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
    local wasGrappleOnly
    local modData
    local npcId
    local record
    local keepEngineMovementActive
    local now
    local actionLeaseActive
    local unsafeNativeTraversalState
    local needsImmediateRepair
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
    now = Core.Now and Core.Now() or 0
    keepEngineMovementActive =
        LiveBodyControl.ShouldKeepEngineMovementActive(record, zombie)
    hadTarget = zombie.getTarget and zombie:getTarget() ~= nil or false
    wasUseless = zombie.isUseless and zombie:isUseless() or false
    hadTeeth = zombie.isNoTeeth and not zombie:isNoTeeth() or false
    wasGrappleOnly = zombie.isReanimatedForGrappleOnly
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
        or wasGrappleOnly
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
    if (
            hadTarget
            or (not wasUseless and not keepEngineMovementActive)
            or hadTeeth
            or wasGrappleOnly
        )
        and not SAFETY_REPAIR_LOGGED[zombie]
        and Core.LogWarn
    then
        SAFETY_REPAIR_LOGGED[zombie] = true
        modData = zombie.getModData and zombie:getModData() or nil
        npcId = modData and modData.PNC_UUID or "unknown"
        Core.LogWarn("human_safety_repaired npc=" .. tostring(npcId)
            .. " source=" .. tostring(source or "unknown")
            .. " target=" .. tostring(hadTarget)
            .. " useless=" .. tostring(wasUseless)
            .. " hadTeeth=" .. tostring(hadTeeth)
            .. " grappleOnly=" .. tostring(wasGrappleOnly))
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
