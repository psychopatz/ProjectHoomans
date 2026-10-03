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

local function auditSleep(eventName, record, zombie, runtime, reason, extra)
    if Diagnostics and Diagnostics.SleepAuditEnabled == true
        and Diagnostics.LogSleepState
    then
        Diagnostics.LogSleepState(
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

local function maintainFloorSeatPresentation(zombie)
    if not zombie then return end
    -- Ground sit clips are looped, but these native flags are still shared
    -- with the vanilla action state. Reassert only the sitting presentation;
    -- the owner callbacks call this while the seat lease is authoritative.
    if zombie.setOnFloor then zombie:setOnFloor(false) end
    if zombie.setSitAgainstWall then zombie:setSitAgainstWall(false) end
    if zombie.setSitOnGround then zombie:setSitOnGround(true) end
    if zombie.setSitOnFurnitureObject then
        zombie:setSitOnFurnitureObject(nil)
    end
    if zombie.setSitOnFurnitureDirection then
        zombie:setSitOnFurnitureDirection(nil)
    end
    if zombie.setSittingOnFurniture then
        zombie:setSittingOnFurniture(false)
    end
    if zombie.setVariable then
        zombie:setVariable("PNCSeated", true)
        if zombie.clearVariable then
            zombie:clearVariable("SitOnFurnitureDirection")
            zombie:clearVariable("SitOnFurnitureStarted")
            zombie:clearVariable("SitOnFurnitureAnim")
        end
    end
    if zombie.setIsResting then zombie:setIsResting(true) end
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

Internal.AuditSeat = auditSeat
Internal.AuditSleep = auditSleep
Internal.ClearFurnitureOccupancy = clearFurnitureOccupancy
Internal.MaintainFloorSeatPresentation = maintainFloorSeatPresentation

return Internal
