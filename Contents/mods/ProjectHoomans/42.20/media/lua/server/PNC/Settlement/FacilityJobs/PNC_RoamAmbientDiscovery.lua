-- Bounded nearby bed/sofa discovery for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamAmbient = PNC.RoamAmbient or {}

local Service = PNC.RoamAmbient
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Reservations = PNC.FacilityReservations

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

local function reserved(resource)
    local key = tostring(resource and resource.resourceKey or "")
    return key ~= "" and Reservations and Reservations.ByResource
        and Reservations.ByResource[key] ~= nil
end

function Service.FindSleepSurface(zombie)
    local cell = type(getCell) == "function" and getCell() or nil
    local detectorIDs = { "bed", "sofa" }
    local originX = math.floor(zombie:getX())
    local originY = math.floor(zombie:getY())
    local originZ = math.floor(zombie:getZ())
    local best
    local examined = 0
    local detectorIndex
    if not cell or not cell.getGridSquare or not Resources
        or not Resources.GetDetector or not Targets
        or not Targets.ResolveResource
    then
        return nil
    end
    for detectorIndex = 1, #detectorIDs do
        local detector = Resources.GetDetector(detectorIDs[detectorIndex])
        if detector and type(detector.matches) == "function"
            and type(detector.describe) == "function"
        then
            local dx
            local dy
            for dx = -Service.SEARCH_RADIUS, Service.SEARCH_RADIUS do
                for dy = -Service.SEARCH_RADIUS, Service.SEARCH_RADIUS do
                    if dx * dx + dy * dy <= Service.SEARCH_RADIUS
                        * Service.SEARCH_RADIUS
                    then
                        local square = cell:getGridSquare(
                            originX + dx, originY + dy, originZ)
                        eachObject(square, function(object, objectIndex)
                            if examined >= Service.MAX_OBJECTS then return end
                            examined = examined + 1
                            if detector.matches(square, object) ~= true then return end
                            local resource = detector.describe(square, object, {
                                objectIndex = objectIndex, character = zombie,
                            })
                            if type(resource) ~= "table" or reserved(resource) then
                                return
                            end
                            local targets = Targets.ResolveResource(resource, {
                                abstract = false, character = zombie,
                            })
                            local target = targets and targets[1] or nil
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
                                    target = target, priority = priority,
                                    distance = distance,
                                }
                            end
                        end)
                    end
                end
            end
        end
    end
    return best
end

return Service
