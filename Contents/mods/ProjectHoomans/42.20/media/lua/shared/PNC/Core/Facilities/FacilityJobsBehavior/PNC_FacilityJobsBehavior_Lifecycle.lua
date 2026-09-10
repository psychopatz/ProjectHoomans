PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Jobs = PNC.FacilityJobs
local Internal = PNC.FacilityJobsBehaviorInternal

function Internal.HasLiveTaskLease(leaseId)
    leaseId = tostring(leaseId or "")
    if leaseId == "" then return false end
    local leases = PNC.TaskLeaseService
    if not leases or type(leases.Get) ~= "function" then
        -- This module is shared. Clients do not own the server lease table,
        -- so an opaque client-side ID is not evidence of an orphan.
        return true
    end
    return leases.Get(leaseId) ~= nil
end

function Internal.RestorePosition(record, zombie, runtime)
    if not runtime or runtime.positioned ~= true then return end
    local position = runtime.approachPosition
    if zombie and position and PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        PNC.LiveBodyControl.SetAuthoritativePosition(
            zombie, position.x, position.y, position.z)
        record.x, record.y, record.z = position.x, position.y, position.z
    end
    runtime.positioned = false
end

function Internal.StopAnimationScene(record, zombie, reason)
    local runtime = record.runtime
    local internal
    if record.runtime.animationScene and PNC.AnimationScenes then
        -- Scene callbacks are extension points. Keep the activity cleanup
        -- alive if one of them fails, but do not add protected calls around
        -- ordinary facility logic.
        pcall(PNC.AnimationScenes.Stop, record, zombie,
            reason or "player_stop")
        if runtime.animationScene then
            -- A failed scene stop can leave the blocking scene pointer behind
            -- even though the command has already moved on. Use the scene
            -- lifecycle's normal clear path when available, then guarantee
            -- that the stale pointer cannot consume the next behavior tick.
            internal = PNC.AnimationScenes.Internal
            if internal and internal.ClearScene then
                internal.ClearScene(record, zombie,
                    reason or "player_stop", true)
            end
            runtime.animationScene = nil
        end
    end
end

function Internal.ReleaseTaskLeaseAfterAbort(record, leaseId, reason)
    local commands
    local cancelled
    local cancelReason
    local leases
    local lease
    local released
    leaseId = tostring(leaseId or "")
    if leaseId == "" then return true end

    -- The facility activity has already been cleared before this call. That
    -- lets the normal provider cancellation path release the lease without
    -- entering Jobs.Stop and restoring the old order recursively.
    commands = PNC.Tasking and PNC.Tasking.Commands
    if commands and commands.CancelForNPC then
        cancelled, cancelReason = commands.CancelForNPC(
            record.id, reason or "order_changed")
        if cancelled == true and cancelReason ~= "CANCELLATION_DEFERRED" then
            return true
        end
    end

    leases = PNC.TaskLeaseService
    if leases and leases.Get and leases.Release then
        lease = leases.Get(leaseId)
        if not lease then return true end
        released = leases.Release(leaseId, reason or "order_changed")
        return released == true
    end
    return cancelled ~= false
end

function Internal.Finish(record, zombie, reason, restoreOrder)
    local runtime = Internal.State(record)
    if not runtime or runtime.finishing == true then return false end
    runtime.finishing = true
    runtime.sleepSceneActive = false
    Internal.RestorePosition(record, zombie, runtime)
    if PNC.FacilityReservations and runtime.reservationId ~= ""
        and not Internal.HasLiveTaskLease(runtime.taskLeaseId)
    then
        PNC.FacilityReservations.Release(
            runtime.reservationId,
            reason == "rested" and "complete" or tostring(reason or "stopped"))
    end
    local previous = runtime.previousOrder
    Internal.ClearSleepSurface(record, zombie, runtime)
    Internal.ClearFurnitureSeat(record, zombie, runtime)
    if runtime.seating == true and PNC.SeatingRuntime
        and PNC.SeatingRuntime.LiveObjects
    then
        PNC.SeatingRuntime.LiveObjects[tostring(record.id)] = nil
    end
    if PNC.SleepRuntime and PNC.SleepRuntime.LiveObjects then
        PNC.SleepRuntime.LiveObjects[tostring(record.id)] = nil
    end
    record.runtime.facilityActivity = nil
    record.runtime.facilityDebugWork = nil
    record.runtime.seatedThreat = nil
    record.runtime.seatedThreatNextScanAt = nil
    record.runtime.seatedThreatNextValidateAt = nil
    if restoreOrder ~= false then
        PNC.OrderSystem.SetOrder(record, previous)
    end
    return true
end

-- Order changes are authoritative commands. Unlike Jobs.Stop, this path must
-- not restore runtime.previousOrder because the caller is already installing
-- a different order (follow, home, camp, and so on).
function Internal.AbortForOrderChange(record, zombie, reason)
    local runtime = Internal.State(record)
    local leaseId
    local finished
    local abortReason = reason or "order_changed"
    if not runtime then return false, "facility_activity_not_active" end

    zombie = zombie or PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    leaseId = tostring(runtime.taskLeaseId or "")
    runtime.stopRequested = true
    Internal.StopAnimationScene(record, zombie, abortReason)
    finished = Internal.Finish(record, zombie, abortReason, false)
    if not finished then return false, "facility_activity_abort_failed" end
    record.activeJob = nil
    record.activeBehavior = nil
    Internal.ReleaseTaskLeaseAfterAbort(record, leaseId, abortReason)
    return true, "facility_activity_aborted"
end

function Internal.Stop(record, reason)
    local runtime = Internal.State(record)
    local zombie
    if not runtime then return false, "facility_activity_not_active" end
    zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    runtime.stopRequested = true
    runtime.sleepSceneActive = false
    -- Cleanup must continue even if scene interruption throws. Otherwise the
    -- activity and its reservation survive without an owner.
    Internal.StopAnimationScene(record, zombie, reason)
    local finished = Internal.Finish(record, zombie, reason or "player_stop")
    return finished == true, "facility_activity_stopped"
end

-- Facility work is the owner of the effect clock. Tasking may observe this
-- value for recovery, but it must never infer progress from an executor tick
-- or a reservation renewal alone.
function Internal.RecordProgress(record, at, reason)
    local runtime = Internal.State(record)
    if not runtime then return false end
    runtime.lastProgressAt = tonumber(at) or PNC.Core.Now()
    runtime.lastProgressReason = tostring(reason or "facility_progress")
    return true
end

return Jobs
