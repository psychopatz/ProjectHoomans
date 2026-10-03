local LiveBodyControl = PNC.LiveBodyControl
local Internal = LiveBodyControl.Internal
local ActorControl = PNC.ActorControl

local PRESENTATION_NATIVE_RESET_STATES = Internal.PRESENTATION_NATIVE_RESET_STATES

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

function LiveBodyControl.ReleasePresentationMovement(
    record,
    zombie,
    reason,
    owner
)
    local runtime = record and record.runtime or nil
    local intent = runtime and runtime.moveIntent or nil
    local hasMovementOwner = runtime and (
        runtime.pathing ~= nil
            or runtime.localNavigation ~= nil
            or intent and intent.kind == "move"
    )
    if not hasMovementOwner then return false end
    if ActorControl and ActorControl.CanWrite then
        local controlOwner = owner
        if ActorControl.ResolveOwner then
            controlOwner = ActorControl.ResolveOwner(owner, reason)
        end
        local accepted = ActorControl.CanWrite(
            record,
            controlOwner,
            "presentation_movement_release",
            { reason = reason }
        )
        if accepted ~= true then
            return false, "puppet_opera_writer_blocked:presentation_release"
        end
    end
    if PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(zombie, record, reason, owner)
        return true
    end
    if PNC.EnginePathPlanner and PNC.EnginePathPlanner.Invalidate then
        PNC.EnginePathPlanner.Invalidate(
            record,
            reason or "presentation_hold",
            zombie
        )
    end
    if runtime then
        runtime.moveIntent = nil
        runtime.pathing = nil
        runtime.localNavigation = nil
    end
    return true
end

function LiveBodyControl.IsPresentationCombatActive(record, now)
    local runtime = record and record.runtime or nil
    local health = record and record.health or nil
    local attackAction = runtime and runtime.attackAction or nil
    local target = runtime and runtime.target or nil
    local threatGuard = runtime and runtime.threatGuard or nil
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
    if now < (tonumber(runtime.inCombatUntil) or 0) then return true end
    return now < (tonumber(health and health.recentDamageUntil) or 0)
        or threatGuard and threatGuard.active == true
        or false
end

function LiveBodyControl.IsPresentationNativeResetState(actionState)
    actionState = string.lower(tostring(actionState or ""))
    return PRESENTATION_NATIVE_RESET_STATES[actionState] == true
end

function LiveBodyControl.IsSleeping(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local phase = activity and tostring(activity.phase or "") or ""
    if not activity or tostring(activity.capability or "") ~= "sleep" then
        return false
    end
    return activity.sleepWakePending == true
        or activity.sleepSceneActive == true
        or (phase == "STARTING" and activity.arrivalSettled == true)
end

function LiveBodyControl.IsSleepWakeActive(record)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    return activity
        and tostring(activity.capability or "") == "sleep"
        and activity.sleepWakePending == true
        or false
end

-- Resolve the one stationary presentation that currently owns the native
-- carrier. Combat is an explicit override; a sleep wake transaction remains
-- authoritative until it finishes its native release and surface cleanup.
function LiveBodyControl.ResolveStationaryPresentation(record, now)
    if LiveBodyControl.IsSleepWakeActive(record) then
        return "sleep_wake", "sleep_wake"
    end
    if LiveBodyControl.IsSeated(record)
        and not LiveBodyControl.IsPresentationCombatActive(record, now)
    then
        return "seat", "seated_safety"
    end
    if LiveBodyControl.IsSleeping(record)
        and not LiveBodyControl.IsPresentationCombatActive(record, now)
    then
        return "sleep", "sleep_safety"
    end
    return nil, nil
end

function LiveBodyControl.IsStationaryPresentationBumpType(kind, bumpType)
    kind = tostring(kind or "")
    bumpType = tostring(bumpType or "")
    if kind == "seat" then
        return bumpType == "PNC_SitChair"
            or bumpType == "PNC_Sit"
            or bumpType == "PNC_SitAction"
            or bumpType == "PNC_SitMaking"
            or bumpType == "PNC_SitRubHands"
    end
    return kind == "sleep"
        and (bumpType == "PNC_Sleep" or bumpType == "PNC_SleepBed")
end

-- Read the action-context state through IsoGameCharacter's exposed wrapper.
-- getActionContext() returns an internal Java ActionContext userdata in Build
-- 42. Its methods are not exposed as a Lua object, so do not index it here.

function LiveBodyControl.ResetPresentationNativeMovementState(zombie)
    local actionState
    if not zombie
        or not zombie.changeState
        or not ZombieIdleState
        or not ZombieIdleState.instance
    then
        return false
    end
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if not LiveBodyControl.IsPresentationNativeResetState(actionState) then
        return false
    end
    zombie:changeState(ZombieIdleState.instance())
    return true
end

-- Presentation entry can occur between zombie-update callbacks. Stabilize the
-- native carrier at that ownership boundary so a stale walk/alert action
-- cannot survive into the first presentation frame.
function LiveBodyControl.StabilizePresentationBody(record, zombie, now, kind)
    local modData
    local actionState
    local active
    local combatActive
    local reason
    if kind == "seat" then
        active = LiveBodyControl.IsSeated(record)
        combatActive = LiveBodyControl.IsPresentationCombatActive(record, now)
        reason = "seated_entry"
    elseif kind == "sleep" then
        active = LiveBodyControl.IsSleeping(record)
        combatActive = LiveBodyControl.IsPresentationCombatActive(record, now)
        reason = "sleep_entry"
    end
    if not zombie or not active or combatActive
    then
        return false
    end
    now = tonumber(now) or (PNC.Core and PNC.Core.Now
        and PNC.Core.Now() or 0)
    LiveBodyControl.ReleasePresentationMovement(record, zombie, reason)
    modData = zombie.getModData and zombie:getModData() or nil
    if kind == "sleep"
        and modData
        and Internal.hasBumpActionLease(zombie, now)
        and LiveBodyControl.IsStationaryPresentationBumpType(
            kind,
            modData.PNC_BumpRequestedType
        )
    then
        modData.PNC_BumpKeepUseless = true
    end
    if Internal.hasBumpActionLease(zombie, now) then
        Internal.clearVanillaIntent(zombie)
        Internal.applyActionLeaseSafeguards(zombie, modData)
        return true
    end
    actionState = LiveBodyControl.GetActionStateName(zombie)
    if LiveBodyControl.IsPresentationNativeResetState(actionState) then
        LiveBodyControl.ResetPresentationNativeMovementState(zombie)
    end
    LiveBodyControl.ApplyHumanizedBodyFlags(zombie, false)
    return true
end

