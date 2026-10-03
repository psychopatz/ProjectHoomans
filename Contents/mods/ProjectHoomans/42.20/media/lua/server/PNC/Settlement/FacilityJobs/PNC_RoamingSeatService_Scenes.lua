if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.RoamingSeat
local Internal = Service.Internal or {}
local Core = PNC.Core
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon
local Jobs = PNC.FacilityJobs
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Reservations = PNC.FacilityReservations
local Diagnostics = PNC.PerformanceScalingDiagnostics
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local facilityJobs = Internal.facilityJobs
local facilityReservations = Internal.facilityReservations
local currentTime = Internal.currentTime
local isSeatOrder = Internal.isSeatOrder
local finish = Internal.finish
local stop = Internal.stop
function Service.OnSceneTick(record, zombie, scene, at)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    at = currentTime(at)
    if not state or not scene or scene.id ~= state.sceneId then return false end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    if not zombie or not isSeatOrder(record, state)
        or record.alive == false
    then
        return false
    end
    if state.floorSeating == true and state.seatEntered ~= true then
        -- A released floor seat must not be kept alive by the persistent
        -- scene. The scene owner will perform the normal stop cleanup.
        return false
    end
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
    local reservations = facilityReservations()
    if state.floorSeating == true and seating
        and seating.MaintainFloorSeat
    then
        seating.MaintainFloorSeat(record, zombie, state, state)
    end
    if reservations and reservations.Start
        and at >= (tonumber(state.nextReservationRenewAt) or 0)
    then
        local renewed, renewal = reservations.Start(
            state.reservationId, 30000)
        if Diagnostics and Diagnostics.LogSeatingState then
            Diagnostics.LogSeatingState(
                "seat_reservation_renewed",
                record,
                zombie,
                scene,
                renewed == true and "renewed" or "renew_failed",
                {
                    "renewalResult=" .. tostring(type(renewal) == "table"
                        and renewal.state or renewal or ""),
                    "expiresAt=" .. tostring(type(renewal) == "table"
                        and renewal.expiresAt or ""),
                }
            )
        end
        state.nextReservationRenewAt = at + 10000
    end
    return state.seatUntil == nil
        or at < (tonumber(state.seatUntil) or at)
end

function Service.OnSceneStopped(record, zombie, scene, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
    if not state or not scene or scene.id ~= state.sceneId then return end
    if Diagnostics and Diagnostics.LogSeatingState then
        Diagnostics.LogSeatingState(
            "seat_scene_stopped",
            record,
            zombie,
            scene,
            reason or "roaming_seat_scene_stopped"
        )
    end
    if seating and seating.ClearFurnitureSeat then
        seating.ClearFurnitureSeat(record, zombie, state)
    end
    if seating and seating.RestorePosition then
        seating.RestorePosition(record, zombie, state)
    end
    if seating and seating.ResetPath then
        seating.ResetPath(record, zombie, "roaming_seat_scene_stopped")
    end
    state.positioned = false
    state.arrivalSettled = false
    if tostring(reason or "") == "interrupted:combat"
        and state.stopRequested ~= true
    then
        state.phase = "INTERRUPTED"
        state.nextSeatValidationAt = currentTime() + 1000
        return
    end
    finish(record, zombie, reason or "roaming_seat_scene_stopped")
end

function Service.Stop(record, zombie, reason)
    return stop(record, zombie, reason or "roaming_seat_stopped")
end

