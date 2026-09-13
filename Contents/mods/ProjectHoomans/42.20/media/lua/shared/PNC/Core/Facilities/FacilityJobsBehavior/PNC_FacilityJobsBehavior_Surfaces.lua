PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function auditSeat(eventName, record, zombie, runtime, reason, extra)
    if Diagnostics and Diagnostics.LogSeatingState then
        Diagnostics.LogSeatingState(
            eventName,
            record,
            zombie,
            runtime and runtime.animationScene or nil,
            reason,
            extra
        )
    end
end

local function clearFurnitureOccupancy(zombie)
    if not zombie then return end
    if zombie.setIsResting then zombie:setIsResting(false) end
    if zombie.setSitOnFurnitureObject then
        zombie:setSitOnFurnitureObject(nil)
    end
    if zombie.setSitOnFurnitureDirection then
        zombie:setSitOnFurnitureDirection(nil)
    end
end

function Internal.SleepDirection(order)
    local directionName = tostring(order and order.sleepFacing or "")
    local axis = tostring(order and (order.sleepAxis or order.interactionAxis)
        or "")
    if axis == "x" then directionName = "E"
    elseif axis == "y" then directionName = "S" end
    if directionName == "" then
        directionName = tostring(order and order.interactionFacing or "")
    end
    if IsoDirections and IsoDirections[directionName] then
        return IsoDirections[directionName]
    end
    return IsoDirections and IsoDirections.S or nil
end

function Internal.ClearSleepSurface(record, zombie, runtime, objectOverride,
    surfaceOverride)
    local surface = tostring(surfaceOverride or runtime
        and runtime.sleepSurface or "")
    local object = objectOverride or Internal.LiveSleepObject(record, runtime)
    if surface == "bed" or surface == "sofa" then
        if object and object.setSatChair then object:setSatChair(false) end
        if zombie then
            clearFurnitureOccupancy(zombie)
            if zombie.setBed then zombie:setBed(nil) end
            if zombie.clearVariable then
                zombie:clearVariable("OnBedDirection")
                zombie:clearVariable("OnBedStarted")
                zombie:clearVariable("OnBedAnim")
            end
        end
    end
    if PNC.SleepRuntime and PNC.SleepRuntime.LiveObjects and record then
        local key = tostring(record.id)
        if objectOverride == nil
            or PNC.SleepRuntime.LiveObjects[key] == objectOverride
        then
            PNC.SleepRuntime.LiveObjects[key] = nil
        end
    end
    runtime.sleepSurfaceEntered = false
end

function Internal.PrepareSleepSurface(record, zombie, runtime, order)
    local surface = tostring(runtime and runtime.sleepSurface
        or order and order.sleepSurface or "")
    if surface ~= "bed" and surface ~= "sofa" then return true end
    if runtime.sleepSurfaceEntered == true then return true end
    if not zombie then return true end
    local object = Internal.LiveSleepObject(record, runtime)
    if not object then return false, "SLEEP_OBJECT_UNAVAILABLE" end
    -- Unit/integration doubles may only expose the occupancy mutators. A live
    -- IsoObject exposes sprite/properties methods, so only physical objects
    -- are subject to this final classification gate.
    if object.getSprite or object.getProperties then
        local classified = SquareRules.ClassifySleepSurface(object)
        if classified ~= surface then
            return false, "SLEEP_OBJECT_NOT_" .. string.upper(surface)
        end
    end
    if object.isFurnitureOccupied
        and object:isFurnitureOccupied(zombie) == true
    then
        return false, "SLEEP_SURFACE_OCCUPIED"
    end
    if object.setSatChair then object:setSatChair(true) end
    if zombie.setOnFloor then zombie:setOnFloor(false) end
    if zombie.setSitOnGround then zombie:setSitOnGround(false) end
    if zombie.setSitOnFurnitureObject then
        zombie:setSitOnFurnitureObject(object)
    end
    local direction = Internal.SleepDirection(order)
    if direction and zombie.setSitOnFurnitureDirection then
        zombie:setSitOnFurnitureDirection(direction)
    end
    if zombie.reportEvent then zombie:reportEvent("EventSitOnFurniture") end
    if zombie.setIsResting then zombie:setIsResting(true) end
    if zombie.setBed then zombie:setBed(object) end
    runtime.sleepSurfaceEntered = true
    return true
end

function Internal.ClearFurnitureSeat(record, zombie, runtime)
    if not runtime or runtime.seating ~= true then return end
    auditSeat("seat_clear_begin", record, zombie, runtime)
    local object = Internal.LiveSeatObject(record, runtime)
    if object and object.setSatChair then
        object:setSatChair(false)
    end
    if zombie then
        clearFurnitureOccupancy(zombie)
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
    auditSeat("seat_clear_complete", record, zombie, runtime)
end

function Internal.EnterFurnitureSeat(record, zombie, runtime, order)
    if not runtime or runtime.seating ~= true then return true end
    auditSeat("seat_entry_attempt", record, zombie, runtime)
    if not zombie then
        -- Abstract execution records the chosen spot/resource; no Java body
        -- state exists until materialization.
        runtime.seatEntered = true
        runtime.phase = "SITTING"
        auditSeat("seat_entry_complete", record, zombie, runtime,
            "abstract")
        return true
    end
    if runtime.seatEntered == true then return true end
    local object = Internal.LiveSeatObject(record, runtime)
    if not object then
        auditSeat("seat_entry_failed", record, zombie, runtime,
            "SEAT_OBJECT_UNAVAILABLE")
        return false, "SEAT_OBJECT_UNAVAILABLE"
    end
    if object.isFurnitureOccupied then
        if object:isFurnitureOccupied(zombie) == true then
            auditSeat("seat_entry_failed", record, zombie, runtime,
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
        auditSeat("seat_entry_failed", record, zombie, runtime,
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
        auditSeat("seat_entry_failed", record, zombie, runtime,
            "SEAT_FACING_UNAVAILABLE", { "partialState=true" })
        return false, "SEAT_FACING_UNAVAILABLE"
    end
    if zombie.reportEvent then zombie:reportEvent("EventSitOnFurniture") end
    if zombie.setIsResting then zombie:setIsResting(true) end
    runtime.seatEntered = true
    runtime.seatState = "SEATED"
    runtime.phase = "SEATED"
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.StabilizeSeatedBody
    then
        PNC.LiveBodyControl.StabilizeSeatedBody(
            record,
            zombie,
            PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
        )
    end
    auditSeat("seat_entry_complete", record, zombie, runtime)
    return true
end

return Internal
