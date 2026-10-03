-- Orphaned activity reconciliation for the task pump.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Leases = PNC.TaskLeaseService
local ActorControl = PNC.ActorControl
local H = Tasking.Internal
local Events = Tasking.Events

local function reconcileOrphanedActivities(at)
    if at < (tonumber(Tasking.NextOrphanReconcileAt) or 0) then
        return 0
    end
    Tasking.NextOrphanReconcileAt = at
        + Tasking.ORPHAN_RECONCILE_INTERVAL_MS
    if not PNC.Registry or not PNC.Registry.ForEach
        or not PNC.FacilityJobs or not PNC.FacilityJobs.Stop
    then return 0 end
    local recovered = 0
    PNC.Registry.ForEach(function(record)
        if ActorControl and ActorControl.IsPuppetOwned
            and ActorControl.IsPuppetOwned(record)
        then
            -- A Puppet lease is a temporary presentation override. Do not
            -- let orphan cleanup erase the facility runtime that the scene
            -- will hand back to after release.
            return
        end
        local activity = record and record.runtime
            and record.runtime.facilityActivity or nil
        local leaseId = activity and tostring(activity.taskLeaseId or "") or ""
        -- Automatic need activities always carry a task lease. Manual and
        -- ambient activities intentionally do not, so they are not treated
        -- as stale just because they are lease-free.
        if activity and activity.automatic == true and leaseId ~= ""
            and not Leases.Get(leaseId)
        then
            local ok, stopped, stopReason = H.SafeCall(
                "task_orphan_facility_stop",
                PNC.FacilityJobs.Stop,
                {
                    npcId = record and record.id,
                    leaseId = leaseId,
                    domain = "NeedFacility",
                },
                record,
                "orphaned_facility_activity"
            )
            if ok and stopped == true then
                recovered = recovered + 1
                Events.Emit("ORPHANED_FACILITY_ACTIVITY_RECOVERED", {
                    record = record, source = "Tasking.OrphanRecovery",
                })
            elseif ok then
                H.RecordFailure(
                    "task_orphan_facility_stop",
                    {
                        npcId = record and record.id,
                        leaseId = leaseId,
                        domain = "NeedFacility",
                    },
                    stopReason or "ORPHAN_FACILITY_STOP_REJECTED"
                )
            end
        end
    end)
    return recovered
end

H.PumpReconcileOrphanedActivities = reconcileOrphanedActivities

