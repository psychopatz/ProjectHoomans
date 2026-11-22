if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.AutonomyExecutors.RoamingSeat
local Internal = Service.Internal or {}
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local facilityJobs = Internal.facilityJobs
local currentTime = Internal.currentTime
local distanceTo = Internal.distanceTo
local isSeatOrder = Internal.isSeatOrder
local stop = Internal.stop

function Service.Tick(record, zombie, at)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
    local scene
    local distance
    local refreshed
    local reason
    local seated
    local started
    at = currentTime(at)
    if not state then return false end
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    if not isSeatOrder(record, state) or not zombie
        or record.alive == false
    then
        stop(record, zombie, "roaming_seat_order_changed")
        return true
    end
    if runtime.facilityActivity or runtime.workOrderId
        or runtime.attackAction or runtime.combatTarget
    then
        stop(record, zombie, "roaming_seat_preempted")
        return true
    end
    if state.seatUntil and at >= state.seatUntil then
        stop(record, zombie, "roaming_seat_timeout")
        return true
    end
    scene = runtime.animationScene
    if scene and scene.id == state.sceneId then return false end
    if scene then
        stop(record, zombie, "roaming_seat_scene_replaced")
        return true
    end
    if not seating then
        stop(record, zombie, "roaming_seat_api_unavailable")
        return true
    end
    if at >= (tonumber(state.nextSeatValidationAt) or 0) then
        refreshed, reason = seating.RefreshLiveSeatTarget(
            record, zombie, state, state)
        state.nextSeatValidationAt = at + 1000
        runtime.target = nil
        if not refreshed then
            stop(record, zombie, reason or "roaming_seat_invalid")
            return true
        end
    end
    if runtime.pathing and (runtime.pathing.phase == "blocked"
        or runtime.pathing.ownerMode == "blocked")
    then
        if not seating.RetryApproach(record, zombie, state, state) then
            stop(record, zombie, state.failedReason
                or "roaming_seat_unreachable")
            return true
        end
        runtime.target = nil
        return true
    end
    distance = distanceTo(zombie, state.x, state.y)
    if distance > (tonumber(state.seatArrivalDistance) or 0.14)
        or math.abs((tonumber(zombie:getZ()) or 0)
            - (tonumber(state.z) or 0)) >= 0.5
    then
        local common = PNC.BehaviorCommon
        state.phase = "TRAVELLING"
        record.activeBehavior = "Roam:seat:travel"
        if common and common.ClearCombatTarget then
            common.ClearCombatTarget(record, "roaming_seat_travel", zombie)
        end
        if common and common.MoveRecord then
            common.MoveRecord(record, zombie, state.x, state.y, state.z,
                "walk", tonumber(state.seatStopDistance) or 0.10,
                "roaming_seat")
        end
        return true
    end
    if state.arrivalSettled ~= true then
        local common = PNC.BehaviorCommon
        seating.ResetPath(record, zombie, "roaming_seat_arrival")
        if common and common.HaltMovement then
            common.HaltMovement(record, zombie, "roaming_seat_arrival")
        end
        state.arrivalSettled = true
    end
    if not state.floorSeating and state.positioned ~= true then
        local positioned, positionReason = seating.PositionAtSeatAnchor(
            record, zombie, state, state)
        if not positioned then
            stop(record, zombie, positionReason or "roaming_seat_position")
            return true
        end
    end
    if state.seatEntered ~= true then
        if state.floorSeating == true then
            seated, reason = seating.EnterFloorSeat(
                record, zombie, state, state)
        else
            seated, reason = seating.EnterFurnitureSeat(
                record, zombie, state, state)
        end
        if not seated then
            stop(record, zombie, reason or "roaming_seat_entry")
            return true
        end
    end
    state.phase = "STARTING"
    record.activeBehavior = "Roam:seat:starting"
    started = PNC.AnimationScenes and PNC.AnimationScenes.Request
        and PNC.AnimationScenes.Request(record, zombie, state.sceneId, {
            reason = "roaming_ambient_seat",
            repeatMode = "loop",
        })
    if started ~= true then
        stop(record, zombie, "roaming_seat_scene_failed")
        return true
    end
    state.phase = "SEATED"
    return true
end
