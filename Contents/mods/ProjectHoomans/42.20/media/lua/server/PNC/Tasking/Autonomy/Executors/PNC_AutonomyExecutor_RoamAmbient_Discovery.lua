-- Bounded nearby bed/sofa discovery for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamAmbient = PNC.AutonomyExecutors.RoamAmbient or {}

local Service = PNC.AutonomyExecutors.RoamAmbient

Service.SEARCH_RADIUS = 6
Service.MAX_OBJECTS = 96

local function eachObject(square, visitor)
    local objects = square and square.getObjects
        and square:getObjects() or nil
    if not objects then return end
    if objects.size and objects.get then
        for index = 0, objects:size() - 1 do
            visitor(objects:get(index), index)
        end
        return
    end
    for index = 1, #objects do visitor(objects[index], index) end
end

local function distanceTo(zombie, x, y)
    if PNC.Core and PNC.Core.Distance then
        return PNC.Core.Distance(zombie:getX(), zombie:getY(), x, y)
    end
    local dx = zombie:getX() - x
    local dy = zombie:getY() - y
    return math.sqrt(dx * dx + dy * dy)
end

local function reserved(resource, target)
    local reservations = PNC.FacilityReservations
    local key = tostring(resource and resource.resourceKey or "")
    if target and target.sleepSlotId and reservations
        and reservations.IsResourceAvailable
    then
        return not reservations.IsResourceAvailable(
            resource, target.sleepSlotId)
    end
    return key ~= "" and reservations and reservations.ByResource
        and reservations.ByResource[key] ~= nil
end

function Service.FindSleepSurface(zombie)
    if not zombie then return nil end
    -- Prefer the unified single-pass spatial-bucket scanner when available so
    -- roaming sleep/seat/water discovery shares one cached scan per area.
    local scanner = PNC.WorldObjects and PNC.WorldObjects.Scanner or nil
    if scanner and type(scanner.FindBestInRadius) == "function"
        and PNC.FacilityResources
        and type(PNC.FacilityResources.InspectSquare) == "function"
    then
        return scanner.FindBestInRadius(nil, zombie, "sleep", {
            radius = Service.SEARCH_RADIUS,
            maxObjects = Service.MAX_OBJECTS,
            character = zombie,
            detectorIDs = { "bed", "sofa" },
        })
    end
    local cell = type(getCell) == "function" and getCell() or nil
    local resources = PNC.FacilityResources
    local targetsSvc = PNC.FacilityInteractionTargets
    local detectorIDs = { "bed", "sofa" }
    local originX = math.floor(zombie:getX())
    local originY = math.floor(zombie:getY())
    local originZ = math.floor(zombie:getZ())
    local best
    local examined = 0
    local detectorIndex
    if not cell or not cell.getGridSquare or not resources
        or not resources.GetDetector or not targetsSvc
        or not targetsSvc.ResolveResource
    then
        return nil
    end
    local worldContext = PNC and PNC.WorldItemContext
    for detectorIndex = 1, #detectorIDs do
        local detector = resources.GetDetector(detectorIDs[detectorIndex])
        if detector and type(detector.matches) == "function"
            and type(detector.describe) == "function"
        then
            local function inspectObject(square, object, objectIndex)
                if examined >= Service.MAX_OBJECTS then return end
                examined = examined + 1
                if detector.matches(square, object) ~= true then return end
                local resource = detector.describe(square, object, {
                    objectIndex = objectIndex, character = zombie,
                })
                if type(resource) ~= "table" then
                    return
                end
                local targets = targetsSvc.ResolveResource(resource, {
                    abstract = false, character = zombie,
                })
                local target
                local targetIndex
                for targetIndex = 1, #(targets or {}) do
                    if not reserved(resource, targets[targetIndex]) then
                        target = targets[targetIndex]
                        break
                    end
                end
                if not target or target.validSpot == false then return end
                local priority = tonumber(resource.sleepPriority) or
                    (detectorIDs[detectorIndex] == "bed" and 100 or 50)
                local distance = distanceTo(zombie, target.x, target.y)
                if not best or priority > best.priority
                    or priority == best.priority
                        and distance < best.distance
                then
                    best = {
                        object = object, resource = resource,
                        target = target, targets = targets,
                        priority = priority,
                        distance = distance,
                    }
                end
            end
            local dx
            local dy
            for dx = -Service.SEARCH_RADIUS, Service.SEARCH_RADIUS do
                for dy = -Service.SEARCH_RADIUS, Service.SEARCH_RADIUS do
                    if dx * dx + dy * dy <= Service.SEARCH_RADIUS
                        * Service.SEARCH_RADIUS
                    then
                        if worldContext and worldContext.GetSquareSnapshot then
                            local snap = worldContext.GetSquareSnapshot(
                                cell, originX + dx, originY + dy, originZ)
                            if snap and snap.square then
                                local objs = snap.objects or {}
                                for oi = 1, #objs do
                                    inspectObject(snap.square, objs[oi], oi - 1)
                                end
                            end
                        else
                            local square = cell:getGridSquare(
                                originX + dx, originY + dy, originZ)
                            eachObject(square, function(object, objectIndex)
                                inspectObject(square, object, objectIndex)
                            end)
                        end
                    end
                end
            end
        end
    end
    return best
end

return Service
