PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local AuditSleep = Internal.AuditSleep
local ClearFurnitureOccupancy = Internal.ClearFurnitureOccupancy

function Internal.ClearSleepSurface(record, zombie, runtime, objectOverride,
    surfaceOverride)
    local surface = tostring(surfaceOverride or runtime
        and runtime.sleepSurface or "")
    local object = objectOverride or Internal.LiveSleepObject(record, runtime)
    local trackedOccupancy = runtime and runtime.sleepSurfaceOccupancyKey
    local occupancyKey = trackedOccupancy
        or runtime and runtime.resourceKey
        or object and tostring(object) or ""
    local occupants = PNC.SleepRuntime and PNC.SleepRuntime.SurfaceOccupants
    local occupantCount = trackedOccupancy and occupants
        and tonumber(occupants[occupancyKey]) or 0
    if surface == "bed" or surface == "sofa" then
        AuditSleep("sleep_surface_clear_begin", record, zombie, runtime,
            "clear", {
                "objectPresent=" .. tostring(object ~= nil),
            })
        if trackedOccupancy and occupantCount > 1 then
            occupants[occupancyKey] = occupantCount - 1
        elseif trackedOccupancy then
            if occupants then occupants[occupancyKey] = nil end
            if object and object.setSatChair then object:setSatChair(false) end
        elseif object and object.setSatChair then
            object:setSatChair(false)
        end
        if zombie then
            ClearFurnitureOccupancy(zombie)
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
    runtime.sleepSurfaceOccupancyKey = nil
    runtime.sleepSurfaceEntered = false
    if surface == "bed" or surface == "sofa" then
        AuditSleep("sleep_surface_clear_complete", record, zombie, runtime,
            "clear")
    end
end

function Internal.PrepareSleepSurface(record, zombie, runtime, order)
    local surface = tostring(runtime and runtime.sleepSurface
        or order and order.sleepSurface or "")
    local classified
    local occupied = false
    local occupancyKey
    local occupants
    local occupantCount
    local capacity
    if surface ~= "bed" and surface ~= "sofa" then return true end
    if runtime.sleepSurfaceEntered == true then return true end
    AuditSleep("sleep_surface_entry_attempt", record, zombie, runtime,
        "prepare", {
            "surface=" .. surface,
            "bodyPresent=" .. tostring(zombie ~= nil),
        })
    if not zombie then
        AuditSleep("sleep_surface_entry_complete", record, zombie, runtime,
            "abstract")
        return true
    end
    local object = Internal.LiveSleepObject(record, runtime)
    if not object then
        AuditSleep("sleep_surface_entry_failed", record, zombie, runtime,
            "SLEEP_OBJECT_UNAVAILABLE", { "objectPresent=false" })
        return false, "SLEEP_OBJECT_UNAVAILABLE"
    end
    -- Unit/integration doubles may only expose the occupancy mutators. A live
    -- IsoObject exposes sprite/properties methods, so only physical objects
    -- are subject to this final classification gate.
    if object.getSprite or object.getProperties then
        classified = SquareRules.ClassifySleepSurface(object)
        if classified ~= surface then
            AuditSleep("sleep_surface_entry_failed", record, zombie, runtime,
                "SLEEP_OBJECT_NOT_" .. string.upper(surface), {
                    "objectPresent=true",
                    "classified=" .. tostring(classified or ""),
                })
            return false, "SLEEP_OBJECT_NOT_" .. string.upper(surface)
        end
    end
    if object.isFurnitureOccupied
        and object:isFurnitureOccupied(zombie) == true
    then
        occupied = true
        AuditSleep("sleep_surface_entry_failed", record, zombie, runtime,
            "SLEEP_SURFACE_OCCUPIED", {
                "objectPresent=true",
                "classified=" .. tostring(classified or ""),
                "occupied=true",
            })
        return false, "SLEEP_SURFACE_OCCUPIED"
    end
    occupancyKey = tostring(runtime.resourceKey or "")
    if occupancyKey == "" then occupancyKey = tostring(object) end
    occupants = PNC.SleepRuntime.SurfaceOccupants
    occupantCount = tonumber(occupants[occupancyKey]) or 0
    capacity = math.max(1, math.floor(tonumber(runtime.sleepCapacity
        or order and (order.sleepCapacity or order.bedCapacity) or 1) or 1))
    if occupantCount >= capacity then
        AuditSleep("sleep_surface_entry_failed", record, zombie, runtime,
            "SLEEP_SURFACE_CAPACITY_REACHED", {
                "objectPresent=true", "capacity=" .. tostring(capacity),
            })
        return false, "SLEEP_SURFACE_CAPACITY_REACHED"
    end
    occupants[occupancyKey] = occupantCount + 1
    runtime.sleepSurfaceOccupancyKey = occupancyKey
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
    AuditSleep("sleep_surface_entry_complete", record, zombie, runtime,
        "prepared", {
            "objectPresent=true",
            "classified=" .. tostring(classified or surface),
            "occupied=" .. tostring(occupied),
        })
    return true
end


return Internal
