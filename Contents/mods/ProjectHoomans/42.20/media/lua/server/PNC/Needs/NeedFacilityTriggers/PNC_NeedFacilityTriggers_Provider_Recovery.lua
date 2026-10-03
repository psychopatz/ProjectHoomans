if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Internal = Triggers.Internal
local Definitions = PNC.NeedFacilityTriggerDefinitions
local AwayRoutes = PNC.NeedFacilityAwayRoutes
local HomeRoute = PNC.NeedFacilityHomeRoute

local recordFor = Internal.RecordFor
local definitionFor = Internal.DefinitionFor
local taskPhaseFor = Internal.TaskPhaseFor
local campPlacementLocked = Internal.CampPlacementLocked
local Recovery = PNC.Tasking and PNC.Tasking.Internal

function Triggers.GetRecoveryState(lease)
    local record = recordFor(lease and lease.npcId)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    local progressAt = activity and activity.lastProgressAt
        or lease and lease.lastProgressAt
    if not record or record.alive == false or not activity
        or tostring(activity.taskLeaseId or "")
            ~= tostring(lease and lease.leaseId or "")
    then
        return {
            invalid = true,
            phase = lease and lease.phase or "WAITING",
            lastProgressAt = progressAt,
        }
    end
    local definition = definitionFor(lease)
    -- Activities without a logical effect (for example a plain living-room
    -- pose) have no truthful progress signal yet. Keep them out of the
    -- effect watchdog until their owner exposes one.
    local activityDefinition = PNC.FacilityJobDefinitions
        and PNC.FacilityJobDefinitions.Get
        and PNC.FacilityJobDefinitions.Get(
            activity.capability or lease and lease.capability)
    if not definition or not activityDefinition
        or not activityDefinition.needEffect
    then
        return { phase = "WAITING", lastProgressAt = progressAt }
    end
    local phase = taskPhaseFor(activity, lease)
    local snapshot = {
        phase = phase,
        lastProgressAt = progressAt,
        watchable = false,
    }
    if phase == "TRAVEL" then
        if Recovery and Recovery.ApplyMovementRecovery then
            snapshot = Recovery.ApplyMovementRecovery(snapshot, lease, record)
        else
            -- Keep isolated provider tests and partial-load diagnostics
            -- compatible with the same PathService observation contract.
            local pathService = PNC.PathService
            local zombie = PNC.Registry and PNC.Registry.GetLiveZombie
                and PNC.Registry.GetLiveZombie(record.id) or nil
            local movement = pathService
                and pathService.GetMovementRecoveryState
                and pathService.GetMovementRecoveryState(record, zombie)
                or nil
            if movement then
                if tonumber(movement.lastProgressAt)
                    and tonumber(movement.lastProgressAt) > 0
                then
                    snapshot.lastProgressAt = movement.lastProgressAt
                end
                snapshot.movement = movement
                if movement.active == true then
                    snapshot.watchable = movement.watchable == true
                    snapshot.forceRecovery = movement.forceRecovery == true
                    snapshot.recoveryReason = movement.forceRecovery == true
                        and "path_traversal_timeout" or nil
                else
                    snapshot.watchable = true
                    snapshot.timeoutMs = 15000
                    snapshot.recoveryReason = "path_lane_inactive"
                end
            else
                snapshot.watchable = true
                snapshot.timeoutMs = 15000
                snapshot.recoveryReason = "path_lane_missing"
            end
        end
    elseif phase == "WORKING" then
        snapshot.watchable = true
    elseif activity.phase == "QUEUED"
        or activity.phase == "STARTING"
        or activity.phase == "INTERRUPTED"
    then
        -- Scene startup and a failed startup retry are preparation, not
        -- effect progress. They still need a short bounded cleanup window so
        -- a stale blocking scene cannot retain the reservation forever.
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "facility_scene_start_timeout"
    end
    return snapshot
end

