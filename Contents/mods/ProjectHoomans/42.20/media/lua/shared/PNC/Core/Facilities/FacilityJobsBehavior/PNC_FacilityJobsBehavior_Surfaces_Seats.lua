PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local AuditSeat = Internal.AuditSeat
local ClearFurnitureOccupancy = Internal.ClearFurnitureOccupancy
local MaintainFloorSeatPresentation = Internal.MaintainFloorSeatPresentation

function Internal.ClearFloorSeat(record, zombie, runtime)
    if not runtime or runtime.seating ~= true
        or not Internal.IsFloorSeating(runtime, record and record.orderSpec)
    then return end
    AuditSeat("floor_seat_clear_begin", record, zombie, runtime)
    if zombie then
        ClearFurnitureOccupancy(zombie)
        if zombie.setOnFloor then zombie:setOnFloor(false) end
        if zombie.setSitAgainstWall then zombie:setSitAgainstWall(false) end
        if zombie.setSitOnGround then zombie:setSitOnGround(false) end
        if zombie.setSittingOnFurniture then
            zombie:setSittingOnFurniture(false)
        end
        if zombie.clearVariable then
            zombie:clearVariable("PNCSeated")
            zombie:clearVariable("SitOnFurnitureDirection")
            zombie:clearVariable("SitOnFurnitureStarted")
            zombie:clearVariable("SitOnFurnitureAnim")
        end
    end
    runtime.seatEntered = false
    runtime.seatState = "STANDING"
    AuditSeat("floor_seat_clear_complete", record, zombie, runtime)
end

function Internal.EnterFloorSeat(record, zombie, runtime, order)
    if not runtime or runtime.seating ~= true
        or not Internal.IsFloorSeating(runtime, order)
    then return true end
    AuditSeat("floor_seat_entry_attempt", record, zombie, runtime)
    if not zombie then
        runtime.seatEntered = true
        runtime.seatState = "SEATED"
        runtime.phase = "SEATED"
        AuditSeat("floor_seat_entry_complete", record, zombie, runtime,
            "abstract")
        return true
    end
    if runtime.seatEntered == true then return true end
    ClearFurnitureOccupancy(zombie)
    MaintainFloorSeatPresentation(zombie)
    runtime.seatEntered = true
    runtime.seatState = "SEATED"
    runtime.phase = "SEATED"
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.StabilizePresentationBody
    then
        PNC.LiveBodyControl.StabilizePresentationBody(
            record,
            zombie,
            PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
            "seat"
        )
    end
    AuditSeat("floor_seat_entry_complete", record, zombie, runtime)
    return true
end

function Internal.MaintainFloorSeat(record, zombie, runtime, order)
    if not runtime or runtime.seating ~= true
        or runtime.seatEntered ~= true
        or not Internal.IsFloorSeating(runtime, order)
        or not zombie
    then
        return false
    end
    MaintainFloorSeatPresentation(zombie)
    return true
end

function Internal.ClearFurnitureSeat(record, zombie, runtime)
    if not runtime or runtime.seating ~= true then return end
    if Internal.IsFloorSeating(runtime, record and record.orderSpec) then
        return Internal.ClearFloorSeat(record, zombie, runtime)
    end
    AuditSeat("seat_clear_begin", record, zombie, runtime)
    local object = Internal.LiveSeatObject(record, runtime)
    if object and object.setSatChair then
        object:setSatChair(false)
    end
    if zombie then
        ClearFurnitureOccupancy(zombie)
        if zombie.setOnFloor then zombie:setOnFloor(false) end
        if zombie.setSitAgainstWall then zombie:setSitAgainstWall(false) end
        if zombie.setSitOnGround then zombie:setSitOnGround(false) end
        if zombie.setSittingOnFurniture then
            zombie:setSittingOnFurniture(false)
        end
        if zombie.clearVariable then
            zombie:clearVariable("PNCSeated")
            zombie:clearVariable("SitOnFurnitureDirection")
            zombie:clearVariable("SitOnFurnitureStarted")
            zombie:clearVariable("SitOnFurnitureAnim")
        end
    end
    runtime.seatEntered = false
    runtime.seatState = "STANDING"
    AuditSeat("seat_clear_complete", record, zombie, runtime)
end

function Internal.EnterFurnitureSeat(record, zombie, runtime, order)
    if not runtime or runtime.seating ~= true then return true end
    AuditSeat("seat_entry_attempt", record, zombie, runtime)
    if not zombie then
        -- Abstract execution records the chosen spot/resource; no Java body
        -- state exists until materialization.
        runtime.seatEntered = true
        runtime.phase = "SITTING"
        AuditSeat("seat_entry_complete", record, zombie, runtime,
            "abstract")
        return true
    end
    if runtime.seatEntered == true then return true end
    local object = Internal.LiveSeatObject(record, runtime)
    if not object then
        AuditSeat("seat_entry_failed", record, zombie, runtime,
            "SEAT_OBJECT_UNAVAILABLE")
        return false, "SEAT_OBJECT_UNAVAILABLE"
    end
    if object.isFurnitureOccupied then
        if object:isFurnitureOccupied(zombie) == true then
            AuditSeat("seat_entry_failed", record, zombie, runtime,
                "SEAT_OCCUPIED")
            return false, "SEAT_OCCUPIED"
        end
    end
    local directionName = tostring(runtime.seatDirection or "")
    local side = tostring(runtime.seatSide or "")
    if directionName == "" then directionName = tostring(order.seatDirection or "") end
    if side == "" then side = tostring(order.seatSide or "") end
    if directionName == "" then directionName = "S" end
    if side == "" then side = "Front" end
    if runtime.validSpot == false then
        AuditSeat("seat_entry_failed", record, zombie, runtime,
            "SEAT_SPOT_INVALID")
        return false, "SEAT_SPOT_INVALID"
    end
    local direction = IsoDirections and IsoDirections[directionName] or nil
    if not direction and IsoDirections and IsoDirections.fromString then
        direction = IsoDirections.fromString(directionName)
    end
    if object.setSatChair then object:setSatChair(true) end
    if zombie.setOnFloor then zombie:setOnFloor(false) end
    if zombie.setSitAgainstWall then zombie:setSitAgainstWall(false) end
    if zombie.setSitOnGround then zombie:setSitOnGround(false) end
    if zombie.setSitOnFurnitureObject then
        zombie:setSitOnFurnitureObject(object)
    end
    if direction and zombie.setSitOnFurnitureDirection then
        zombie:setSitOnFurnitureDirection(direction)
    end
    if zombie.setVariable then
        zombie:setVariable("SitOnFurnitureDirection", side)
        zombie:setVariable("PNCSeated", true)
        if zombie.clearVariable then
            zombie:clearVariable("SitOnFurnitureAnim")
            zombie:clearVariable("SitOnFurnitureStarted")
        end
    end
    if zombie.setSittingOnFurniture then
        zombie:setSittingOnFurniture(true)
    end
    if not Internal.ApplySeatFacing(zombie, direction, side) then
        AuditSeat("seat_entry_failed", record, zombie, runtime,
            "SEAT_FACING_UNAVAILABLE", { "partialState=true" })
        return false, "SEAT_FACING_UNAVAILABLE"
    end
    if zombie.reportEvent then zombie:reportEvent("EventSitOnFurniture") end
    if zombie.setIsResting then zombie:setIsResting(true) end
    runtime.seatEntered = true
    runtime.seatState = "SEATED"
    runtime.phase = "SEATED"
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.StabilizePresentationBody
    then
        PNC.LiveBodyControl.StabilizePresentationBody(
            record,
            zombie,
            PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
            "seat"
        )
    end
    AuditSeat("seat_entry_complete", record, zombie, runtime)
    return true
end


return Internal
