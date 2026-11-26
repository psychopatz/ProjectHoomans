if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.AutonomyExecutors.RoamingSeat
local Internal = Service.Internal or {}

local facilityResources = Internal.facilityResources
local interactionTargets = Internal.interactionTargets
local eachObject = Internal.eachObject
local isReserved = Internal.isReserved
local idHash = Internal.idHash
local distanceTo = Internal.distanceTo
local AMBIENT_FACILITY_ID = Internal.AMBIENT_FACILITY_ID
local FLOOR_SCENE_ID = Internal.FLOOR_SCENE_ID

local function floorSquareUsable(square, allowOccupied, x, y, z)
    local pathService
    local checked
    local walkable
    if not square then return false end
    if square.isSolid and square:isSolid() == true then return false end
    if square.isSolidTrans and square:isSolidTrans() == true then
        return false
    end
    if allowOccupied == true then return true end
    pathService = PNC.PathService
    if pathService and pathService.IsSquareWalkable then
        checked, walkable = pcall(pathService.IsSquareWalkable, x, y, z)
        if checked then return walkable == true end
    end
    if square.isFree and square:isFree(false) ~= true then return false end
    return true
end

local function floorSeatCandidate(record, zombie, cell)
    local originX = math.floor(zombie:getX())
    local originY = math.floor(zombie:getY())
    local originZ = math.floor(zombie:getZ())
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 },
    }
    local start = idHash(record and record.id, #offsets) + 1
    local resourceKey = AMBIENT_FACILITY_ID .. ":floor_sit:"
        .. tostring(record and record.id or "npc")
    local worldContext = PNC and PNC.WorldItemContext
    for offset = 0, #offsets - 1 do
        local index = ((start - 1 + offset) % #offsets) + 1
        local delta = offsets[index]
        local gridX = originX + delta[1]
        local gridY = originY + delta[2]
        local x = gridX + 0.5
        local y = gridY + 0.5
        local square
        if worldContext and worldContext.GetSquareSnapshot then
            local snap = worldContext.GetSquareSnapshot(cell, gridX, gridY, originZ)
            square = snap and snap.square or nil
        else
            square = cell:getGridSquare(gridX, gridY, originZ)
        end
        if floorSquareUsable(
            square,
            delta[1] == 0 and delta[2] == 0,
            x,
            y,
            originZ
        ) then
            local resource = {
                kind = "virtual", detectorId = "virtual",
                targetResolver = "floor", resourceKind = "floor_seating",
                role = "living.floor", resourceKey = resourceKey,
                x = x, y = y, z = originZ,
                originX = gridX, originY = gridY, originZ = originZ,
                exclusive = false, available = true, virtual = true,
                sceneId = FLOOR_SCENE_ID, seating = true,
                floorSeating = true, stopDistance = 0.45,
                arrivalDistance = 0.55,
            }
            local target = {
                x = x, y = y, z = originZ,
                sceneId = FLOOR_SCENE_ID, resourceKey = resourceKey,
                resourceKind = "floor_seating", seating = true,
                floorSeating = true, validSpot = true,
                stopDistance = 0.45, arrivalDistance = 0.55,
            }
            return {
                object = nil, resource = resource, target = target,
                targets = { target },
            }
        end
    end
    return nil
end

local function findSeat(record, zombie)
    local cell = type(getCell) == "function" and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    -- Prefer the unified single-pass spatial-bucket scanner when available so
    -- roaming seating shares one cached scan with sleep and water discovery.
    local scanner = PNC.WorldObjects and PNC.WorldObjects.Scanner or nil
    if scanner and type(scanner.FindBestInRadius) == "function"
        and PNC.FacilityResources
        and type(PNC.FacilityResources.InspectSquare) == "function"
    then
        local best = scanner.FindBestInRadius(record, zombie, "living", {
            radius = Service.SEARCH_RADIUS,
            maxObjects = Service.MAX_OBJECTS,
            character = zombie,
            detectorIDs = { "seat" },
        })
        return best or floorSeatCandidate(record, zombie, cell)
    end
    local resourcesService = facilityResources()
    local targetsService = interactionTargets()
    local detector = resourcesService and resourcesService.GetDetector
        and resourcesService.GetDetector("seat") or nil
    local originX = math.floor(zombie:getX())
    local originY = math.floor(zombie:getY())
    local originZ = math.floor(zombie:getZ())
    local best
    local bestDistance
    local examined = 0
    if detector and type(detector.matches) == "function"
        and type(detector.describe) == "function"
        and targetsService and targetsService.ResolveResource
    then
        local worldContext = PNC and PNC.WorldItemContext
        local function checkObject(square, object, objectIndex)
            local resource
            local targets
            local target
            local distance
            local called
            local matched
            local described
            local resolved
            called, matched = pcall(
                detector.matches,
                square,
                object
            )
            if not called or matched ~= true then return end
            if examined >= Service.MAX_OBJECTS then return end
            examined = examined + 1
            described, resource = pcall(
                detector.describe,
                square,
                object,
                {
                    objectIndex = objectIndex,
                    character = zombie,
                }
            )
            if not described or type(resource) ~= "table"
                or isReserved(resource)
            then
                return
            end
            resolved, targets = pcall(
                targetsService.ResolveResource,
                resource,
                { abstract = false, character = zombie }
            )
            if not resolved then return end
            target = targets and targets[1] or nil
            if not target or target.validSpot == false then return end
            distance = distanceTo(zombie, target.x, target.y)
            local resourceKey = tostring(resource.resourceKey or "")
            local bestKey = tostring(best
                and best.resource
                and best.resource.resourceKey or "")
            if not bestDistance or distance < bestDistance
                or distance == bestDistance
                    and resourceKey < bestKey
            then
                bestDistance = distance
                best = {
                    object = object,
                    resource = resource,
                    target = target,
                    targets = targets,
                }
            end
        end
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
                                checkObject(snap.square, objs[oi], oi - 1)
                            end
                        end
                    else
                        local square = cell:getGridSquare(
                            originX + dx, originY + dy, originZ)
                        eachObject(square, function(object, objectIndex)
                            checkObject(square, object, objectIndex)
                        end)
                    end
                end
            end
        end
    end
    return best or floorSeatCandidate(record, zombie, cell)
end

Internal.findSeat = findSeat
Service.FindCandidate = findSeat
