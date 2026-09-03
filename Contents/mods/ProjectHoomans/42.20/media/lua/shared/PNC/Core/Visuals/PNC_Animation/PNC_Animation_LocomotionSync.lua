PNC = PNC or {}
PNC.Animation = PNC.Animation or {}
PNC.Animation.Internal = PNC.Animation.Internal or {}

local Animation = PNC.Animation
local Internal = Animation.Internal
local Core = PNC.Core
local LiveBodyControl = PNC.LiveBodyControl
local LocomotionProfiles = PNC.LocomotionProfiles
local AnimationTrace = PNC.AnimationTrace

function Animation.SyncLocomotion(zombie, record)
    local profile
    local moving
    local moveAnim
    local walkType
    local engineWalkType
    local animSpeed
    local runtime
    local attackAction
    local path
    local now
    local downedMoving
    local treatment
    local navigation
    if not zombie then
        return
    end
    runtime = record and record.runtime or nil
    treatment = runtime and runtime.selfTreatment or nil
    attackAction = runtime and runtime.attackAction or nil
    path = runtime and runtime.pathing or nil
    navigation = runtime and runtime.localNavigation or nil
    now = Core and Core.Now and Core.Now() or 0
    if treatment and treatment.phase == "bandaging"
        and now < (tonumber(treatment.finishAt) or 0)
    then
        Internal.setManagedUseless(zombie, false, true)
        return
    end
    if record and record.health and record.health.state == "incapacitated" then
        downedMoving = path and (
            path.phase == "requested"
            or path.phase == "active"
            or path.ownerMode == "fake_locomotion"
            or now < (tonumber(path.visualMovingUntil) or 0)
        ) and tostring(path.resolvedMode or path.mode or "") == "crawl"
        Animation.ApplyDowned(
            zombie,
            record,
            downedMoving and (path.motionProfile or true) or false
        )
        return
    end
    if Animation.PumpBumpRelease(zombie, now) then
        Internal.applyBumpLeaseBodyMode(zombie)
        return
    end
    -- The combat authority can clear attackAction before the rendering client
    -- observes the inactive snapshot and calls FinishBump. Keep every
    -- locomotion writer out until the body-local action lease has actually
    -- exited, otherwise Apply/SyncLocomotion can replace the swing for one
    -- frame in that handoff gap.
    if Animation.IsBumpActionActive(zombie, now) then
        Internal.applyBumpLeaseBodyMode(zombie)
        return
    end
    if attackAction and now < (tonumber(attackAction.finishAt) or 0) then
        Internal.setManagedUseless(zombie, false, true)
        return
    end
    if path and now < (tonumber(path.specialMoveUntil) or 0) and path.specialAnim then
        Internal.applyBumpLeaseBodyMode(zombie)
        return
    end
    if navigation
        and navigation.provider == "engine_path"
        and navigation.nativeActive == true
    then
        Animation.SyncNativeLocomotionStyle(zombie, record)
        return
    end
    profile = path and path.motionProfile or nil
    moving = path
        and path.ownerMode ~= "native_backoff"
        and now >= (tonumber(path.nativeBackoffUntil) or 0)
        and (
            path.phase == "requested"
            or path.phase == "active"
            or path.ownerMode == "fake_locomotion"
            or now < (tonumber(path.visualMovingUntil) or 0)
        )
        or false
    moveAnim = path and path.moveAnim or zombie.getVariableString and zombie:getVariableString("PNCMoveAnim") or ""
    walkType = path and path.walkType or zombie.getVariableString and zombie:getVariableString("PNCWalkType") or ""
    engineWalkType = path and path.engineWalkType
        or zombie.getVariableString and zombie:getVariableString("PNCEngineWalkType")
        or zombie.getVariableString and zombie:getVariableString("WalkType")
        or ""
    animSpeed = path and path.animSpeed or zombie.getVariableFloat and zombie:getVariableFloat("PNCAnimSpeed", 1.0) or 1.0
    Internal.setLocomotionVars(zombie, profile or {
        moveAnim = moveAnim ~= "" and moveAnim or "Walk",
        walkType = walkType or "",
        engineWalkType = engineWalkType or "",
        isRunning = path and path.isRunning == true or false,
        isCrawling = path and path.isCrawling == true or false,
    }, moving, animSpeed)
    Internal.applyWalkType(zombie, engineWalkType, animSpeed)
    if zombie.setRunning then
        zombie:setRunning(path and path.isRunning == true)
    end
    if LiveBodyControl and LiveBodyControl.SyncLocomotionState then
        LiveBodyControl.SyncLocomotionState(zombie, moving)
    end
    local keepEngineMovementActive =
        LiveBodyControl
        and LiveBodyControl.ShouldKeepEngineMovementActive
        and LiveBodyControl.ShouldKeepEngineMovementActive(record, zombie)
        or false
    Internal.setManagedUseless(
        zombie,
        not keepEngineMovementActive,
        keepEngineMovementActive
    )
end
