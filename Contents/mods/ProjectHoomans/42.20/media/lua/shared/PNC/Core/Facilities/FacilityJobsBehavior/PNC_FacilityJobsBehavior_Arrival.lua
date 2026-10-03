-- Facility activity arrival, seating, positioning, and sleep-surface preparation.
-- The tick provider delegates here after activity admission and water
-- approach checks; this provider returns a scene-start decision only.

PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local Diagnostics = PNC.PerformanceScalingDiagnostics
local SEAT_STOP_DISTANCE = Internal.SEAT_STOP_DISTANCE
local SEAT_ARRIVAL_TOLERANCE = Internal.SEAT_ARRIVAL_TOLERANCE

function Internal.PrepareArrival(record, zombie, runtime, order, definition)
    local distance
    local arrivalDistance
    local moveStopDistance
    local refreshed
    local seatReason
    local targetChanged
    local previousSeatKey
    local previousSeatAnchorX
    local previousSeatAnchorY
    local positioned
    local positionReason
    local sceneId
    if Internal.IsFurnitureSeating(runtime, order) and zombie then
        previousSeatKey = runtime.approachKey
        previousSeatAnchorX = runtime.seatAnchor
            and runtime.seatAnchor.x or nil
        previousSeatAnchorY = runtime.seatAnchor
            and runtime.seatAnchor.y or nil
        refreshed, seatReason, targetChanged = Internal.RefreshLiveSeatTarget(
            record, zombie, runtime, order)
        if not refreshed then
            runtime.failedReason = seatReason or "SEAT_TARGET_UNAVAILABLE"
            Internal.Finish(record, zombie, runtime.failedReason)
            return false
        end
        if targetChanged then
            if Diagnostics and Diagnostics.SeatingAuditEnabled == true
                and Diagnostics.LogSeatingState
            then
                Diagnostics.LogSeatingState(
                    "seat_anchor_changed",
                    record,
                    zombie,
                    runtime.animationScene,
                    "seat_target_refreshed",
                    {
                        "oldKey=" .. tostring(previousSeatKey or ""),
                        "newKey=" .. tostring(order.approachKey or ""),
                        "oldX=" .. tostring(previousSeatAnchorX or ""),
                        "oldY=" .. tostring(previousSeatAnchorY or ""),
                        "newX=" .. tostring(order.x or ""),
                        "newY=" .. tostring(order.y or ""),
                    }
                )
            end
            if runtime.seatEntered == true then
                Internal.ClearFurnitureSeat(record, zombie, runtime)
            end
            Internal.ResetPath(record, zombie, "seat_anchor_refreshed")
            runtime.arrivalSettled = false
            runtime.positioned = false
            runtime.facingApplied = false
            runtime.seatEntered = false
        end
    end
    if not Internal.RetrySeatApproach(record, zombie, order, runtime) then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        Internal.Finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return false
    end
    sceneId = order.sceneId ~= "" and order.sceneId or definition.sceneId
    runtime.sceneId = sceneId
    runtime.sleepSurface = order.sleepSurface
    distance = Internal.BodyDistance(zombie, order.x, order.y)
        or PNC.Core.Distance(record.x, record.y, order.x, order.y)
    runtime.distance = distance
    arrivalDistance = runtime.seating == true
        and (tonumber(runtime.seatArrivalDistance)
            or tonumber(order.arrivalDistance)
            or Internal.IsFloorSeating(runtime, order)
                and 0.55 or SEAT_ARRIVAL_TOLERANCE)
        or (tonumber(definition.arrivalDistance) or 0.85)
    moveStopDistance = runtime.seating == true
        and (tonumber(runtime.seatStopDistance)
            or tonumber(order.stopDistance)
            or Internal.IsFloorSeating(runtime, order)
                and 0.45 or SEAT_STOP_DISTANCE)
        or 0.7
    if distance > arrivalDistance
        or math.abs((tonumber(record.z) or 0) - order.z) >= 0.5
    then
        runtime.phase = "TRAVELLING"
        if runtime.taskLeaseId ~= "" and PNC.Tasking
            and PNC.Tasking.Commands
        then PNC.Tasking.Commands.SetPhase(record.id, "TRAVEL") end
        PNC.BehaviorCommon.ClearCombatTarget(record, "facility_travel", zombie)
        PNC.BehaviorCommon.MoveRecord(record, zombie, order.x, order.y, order.z,
            "walk", moveStopDistance, "facility_activity")
        return false
    end
    PNC.BehaviorCommon.ClearCombatTarget(record, "facility_working", zombie)
    if runtime.arrivalSettled ~= true then
        -- Arrival transfers movement ownership to a stationary interaction.
        -- A queued Behavior2 route otherwise remains visible to the scene
        -- safety arbiter and repeatedly interrupts/restarts the sleep bump.
        if Diagnostics and Diagnostics.SeatingAuditEnabled == true
            and Diagnostics.LogSeatingState
        then
            Diagnostics.LogSeatingState(
                "facility_arrival",
                record,
                zombie,
                runtime.animationScene,
                "facility_arrival"
            )
        end
        if tostring(runtime.capability or "") == "sleep"
            and Diagnostics and Diagnostics.SleepAuditEnabled == true
            and Diagnostics.LogSleepState
        then
            Diagnostics.LogSleepState(
                "sleep_arrival",
                record,
                zombie,
                runtime.animationScene,
                "facility_arrival"
            )
        end
        Internal.ResetPath(record, zombie, "facility_arrival")
        runtime.arrivalSettled = true
    end
    PNC.BehaviorCommon.HaltMovement(record, zombie, "facility_working")
    if Internal.IsFurnitureSeating(runtime, order)
        and runtime.positioned ~= true
    then
        positioned, positionReason = Internal.PositionAtSeatAnchor(
            record, zombie, runtime, order)
        if not positioned then
            runtime.failedReason = positionReason or "SEAT_POSITION_FAILED"
            Internal.Finish(record, zombie, runtime.failedReason)
            return false
        end
    end
    if runtime.seating == true and runtime.seatEntered ~= true then
        local seated
        local seatReason
        if Internal.IsFloorSeating(runtime, order) then
            seated, seatReason = Internal.EnterFloorSeat(
                record, zombie, runtime, order)
        else
            seated, seatReason = Internal.EnterFurnitureSeat(
                record, zombie, runtime, order)
        end
        if not seated then
            runtime.failedReason = seatReason or "SEAT_UNAVAILABLE"
            Internal.Finish(record, zombie, runtime.failedReason)
            return false
        end
    end
    if runtime.seating ~= true and runtime.positioned ~= true and zombie then
        if tostring(runtime.capability or "") == "sleep"
            and Internal.TrySnapToSleep
        then
            positioned, positionReason = Internal.TrySnapToSleep(
                record, zombie, runtime, order)
            if not positioned then
                runtime.failedReason = positionReason
                    or "SLEEP_ENTRY_POSITION_FAILED"
                Internal.Finish(record, zombie, runtime.failedReason)
                return false
            end
        elseif order.interactionX and order.interactionY
            and PNC.LiveBodyControl
            and PNC.LiveBodyControl.SetAuthoritativePosition
        then
            runtime.approachPosition = {
                x = zombie:getX(), y = zombie:getY(), z = zombie:getZ(),
            }
            PNC.LiveBodyControl.SetAuthoritativePosition(zombie,
                order.interactionX, order.interactionY,
                order.interactionZ or order.z)
            record.x, record.y, record.z = order.interactionX,
                order.interactionY, order.interactionZ or order.z
            runtime.positioned = true
        end
        if runtime.positioned == true
            and tostring(runtime.capability or "") == "sleep"
            and Diagnostics and Diagnostics.SleepAuditEnabled == true
            and Diagnostics.LogSleepState
        then
            Diagnostics.LogSleepState(
                "sleep_positioned",
                record,
                zombie,
                runtime.animationScene,
                "interaction_positioned",
                {
                    "interactionX=" .. tostring(order.interactionX),
                    "interactionY=" .. tostring(order.interactionY),
                    "interactionZ=" .. tostring(
                        order.interactionZ or order.z),
                }
            )
        end
    end
    if runtime.facingApplied ~= true and zombie then
        local directionName = tostring(order.interactionFacing or "")
        if order.interactionAxis == "x" then directionName = "E"
        elseif order.interactionAxis == "y" then directionName = "S" end
        if directionName ~= "" and IsoDirections
            and zombie.setForwardIsoDirection
        then
            local direction = IsoDirections[directionName]
            if direction then zombie:setForwardIsoDirection(direction) end
        end
        runtime.facingApplied = true
    end
    if tostring(runtime.capability or "") == "sleep" then
        local prepared, sleepReason = Internal.PrepareSleepSurface(
            record, zombie, runtime, order)
        if not prepared then
            local leaseId = runtime.taskLeaseId
            runtime.failedReason = sleepReason or "SLEEP_SURFACE_UNAVAILABLE"
            Internal.Finish(record, zombie, runtime.failedReason)
            if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands
                and PNC.Tasking.Commands.CancelForNPC
            then
                PNC.Tasking.Commands.CancelForNPC(record.id,
                    runtime.failedReason)
            end
            return false
        end
    end
    return true, sceneId
end

return Internal

