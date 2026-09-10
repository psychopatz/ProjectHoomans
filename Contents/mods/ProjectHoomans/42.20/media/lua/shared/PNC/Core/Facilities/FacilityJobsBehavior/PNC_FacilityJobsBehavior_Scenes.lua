PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local Definitions = PNC.FacilityJobDefinitions

function Internal.OnSceneTick(record, zombie, scene, now)
    local runtime = Internal.State(record)
    local definition = runtime and Definitions.Get(runtime.capability) or nil
    local sceneId = runtime and runtime.sceneId ~= "" and runtime.sceneId
        or definition and definition.sceneId
    if not runtime or not definition or scene.id ~= sceneId then
        return false
    end
    if tostring(runtime.capability or "") == "sleep" then
        -- Sleep effects and sleep-specific recovery begin only after the
        -- animation scene has been accepted. Reaching the bed is not sleep.
        runtime.sleepSceneActive = true
        runtime.phase = "SLEEPING"
    else
        runtime.phase = runtime.seating == true
            and "SEATED" or definition.activityLabel or "WORKING"
    end
    if PNC.FacilityReservations and runtime.reservationId ~= ""
        and now >= (tonumber(runtime.nextReservationRenewAt) or 0)
    then
        PNC.FacilityReservations.Start(runtime.reservationId, 30000)
        runtime.nextReservationRenewAt = now + 10000
    end
    if runtime.taskLeaseId ~= "" and PNC.Tasking
        and PNC.Tasking.Commands and PNC.Tasking.Commands.SetPhase
    then PNC.Tasking.Commands.SetPhase(record.id, "WORKING") end
    if definition.domain == "farming" and PNC.FarmingService
        and PNC.FarmingService.TickLive
    then
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or zombie
        local keepScene = PNC.FarmingService.TickLive(
            record, live, runtime, now)
        if runtime.completionRequested == true then return false end
        if keepScene == false then return false end
    end
    if definition.needEffect and PNC.NeedFacilityEffects
        and PNC.NeedsUtils
    then
        local worldNow = PNC.NeedsUtils.WorldAgeHours()
        local previous = tonumber(runtime.lastEffectWorldHour) or worldNow
        local elapsed = math.max(0, math.min(0.25, worldNow - previous))
        runtime.lastEffectWorldHour = worldNow
        local ok, complete, effectReason, value =
            PNC.NeedFacilityEffects.Tick(
                record, runtime, definition, elapsed, now)
        runtime.effectValue = value
        if not ok then
            runtime.failedReason = effectReason or "NEED_EFFECT_FAILED"
            runtime.completionRequested = true
            return false
        end
        if effectReason and Internal.RecordProgress then
            Internal.RecordProgress(record, now, effectReason)
        end
        if runtime.debugHold ~= true and complete then
            runtime.completionRequested = true
            -- Food and drink apply their gameplay effect during the primary
            -- action, but retain the task lease until the ordered wipe steps
            -- finish. Other needs keep their existing immediate completion.
            return definition.completeWithScene == true
        end
    end
    return true
end

function Internal.OnSceneStopped(record, zombie, scene, reason)
    local runtime = Internal.State(record)
    if not runtime then return end
    runtime.sleepSceneActive = false
    Internal.ClearSleepSurface(record, zombie, runtime)
    Internal.ClearFurnitureSeat(record, zombie, runtime)
    Internal.RestorePosition(record, zombie, runtime)
    runtime.arrivalSettled = false
    if runtime.stopRequested == true then return end
    if runtime.failedReason then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        Internal.Finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return
    end
    if runtime.completionRequested == true or reason == "callback_complete" then
        local leaseId = runtime.taskLeaseId
        Internal.Finish(record, zombie, "complete")
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.Complete(leaseId, "NEED_COMPLETE")
        end
        return
    end
    runtime.phase = "INTERRUPTED"
    runtime.interruptReason = tostring(reason or "interrupted")
end

return Internal
