-- Unified bounded spatial scanner for all registered world-object detectors.
--
-- Replaces duplicate radius-scanning loops across RoamingSeat, RoamAmbient,
-- and nearby object discovery. A single pass over a spatial bucket populates
-- every registered object type (seat, bed, sofa, faucet, and future plug-ins)
-- and shares the short-TTL cache across nearby NPCs and capabilities.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldObjects = PNC.WorldObjects or {}
PNC.WorldObjects.Scanner = PNC.WorldObjects.Scanner or {}

local Scanner = PNC.WorldObjects.Scanner

Scanner.VERSION = 1
Scanner.DEFAULT_RADIUS = 6
Scanner.MAX_RADIUS = 24
Scanner.DEFAULT_MAX_OBJECTS = 128
Scanner.DEFAULT_CACHE_MS = 2500
Scanner.BUCKET_SIZE = 4
Scanner.MAX_CACHE_ENTRIES = 64

local cache = {}
local cacheCount = 0

local function nowMs()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        local value = tonumber(PNC.Core.Now())
        if value ~= nil then return value end
    end
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and tonumber(value) ~= nil then return tonumber(value) end
    end
    return 0
end

local function distanceTo(x1, y1, x2, y2)
    if PNC.Core and type(PNC.Core.Distance) == "function" then
        return PNC.Core.Distance(x1, y1, x2, y2)
    end
    local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
    local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function registry()
    return PNC.FacilityResources
end

local function bucketKey(x, y, z, radius)
    local size = math.max(1, math.floor(tonumber(Scanner.BUCKET_SIZE) or 4))
    local bx = math.floor(math.floor(x) / size)
    local by = math.floor(math.floor(y) / size)
    return tostring(bx) .. ":" .. tostring(by) .. ":"
        .. tostring(math.floor(z)) .. ":" .. tostring(radius)
end

local function isReserved(resource, target)
    local reservations = PNC.FacilityReservations
    if not reservations then return false end
    local key = tostring(resource and resource.resourceKey or "")
    if target and target.sleepSlotId
        and type(reservations.IsResourceAvailable) == "function"
    then
        return not reservations.IsResourceAvailable(resource, target.sleepSlotId)
    end
    if key == "" then return false end
    if type(reservations.IsReserved) == "function" then
        return reservations.IsReserved(nil, key) == true
    end
    return reservations.ByResource and reservations.ByResource[key] ~= nil
end

local function matchesCapability(resource, capability, detectorFilter)
    local reg = registry()
    local detectorId = tostring(resource and resource.detectorId or "")
    if detectorFilter and not detectorFilter[detectorId] then
        return false
    end
    if not capability or capability == "" then return true end
    local resCap = resource and resource.capability or nil
    if not resCap and reg and type(reg.GetDetector) == "function"
        and detectorId ~= ""
    then
        local detector = reg.GetDetector(detectorId)
        resCap = detector and detector.capability or nil
    end
    return tostring(resCap or "") == tostring(capability)
end

-- Scans all registered object detectors within a circular radius in one pass
-- and caches the resulting primitive descriptors by spatial bucket.
function Scanner.ScanRadius(originX, originY, originZ, options)
    options = type(options) == "table" and options or {}
    local reg = registry()
    local cell = options.cell or (type(getCell) == "function" and getCell() or nil)
    if not reg or type(reg.InspectSquare) ~= "function"
        or not cell or type(cell.getGridSquare) ~= "function"
    then
        return nil, "WORLD_SCANNER_UNAVAILABLE"
    end
    originX = tonumber(originX)
    originY = tonumber(originY)
    originZ = tonumber(originZ) or 0
    if originX == nil or originY == nil then
        return nil, "SCAN_ORIGIN_INVALID"
    end
    local radius = math.max(1, math.min(
        Scanner.MAX_RADIUS,
        math.floor(tonumber(options.radius) or Scanner.DEFAULT_RADIUS)
    ))
    local cacheMs = tonumber(options.cacheMs)
    if cacheMs == nil then cacheMs = Scanner.DEFAULT_CACHE_MS end
    local at = nowMs()
    local key = bucketKey(originX, originY, originZ, radius)
    if options.force ~= true and cacheMs > 0 then
        local cached = cache[key]
        if cached and at - cached.at <= cacheMs then
            return cached.snapshot
        end
    end

    local maxObjects = math.max(1, math.floor(
        tonumber(options.maxObjects) or Scanner.DEFAULT_MAX_OBJECTS))
    local baseX = math.floor(originX)
    local baseY = math.floor(originY)
    local baseZ = math.floor(originZ)
    local radiusSq = radius * radius
    local worldContext = PNC and PNC.WorldItemContext or nil
    local resources = {}
    local liveObjects = {}
    local seen = {}
    local emitted = 0
    local inspectCtx = {
        record = options.record,
        character = options.character,
    }
    local function addDescriptor(desc)
        if type(desc) ~= "table" or emitted >= maxObjects then return end
        local resKey = tostring(desc.resourceKey or desc.key or "")
        if resKey == "" or seen[resKey] then return end
        seen[resKey] = true
        if desc.object ~= nil then
            liveObjects[resKey] = desc.object
        end
        local copy = type(reg.CopyDescriptor) == "function"
            and reg.CopyDescriptor(desc) or desc
        copy.resourceKey = resKey
        resources[#resources + 1] = copy
        emitted = emitted + 1
    end

    for dx = -radius, radius do
        if emitted >= maxObjects then break end
        for dy = -radius, radius do
            if emitted >= maxObjects then break end
            if dx * dx + dy * dy <= radiusSq then
                local square
                local cachedObjects
                if worldContext and worldContext.GetSquareSnapshot then
                    local snap = worldContext.GetSquareSnapshot(
                        cell, baseX + dx, baseY + dy, baseZ)
                    if snap and snap.square then
                        square = snap.square
                        cachedObjects = snap.objects
                    end
                else
                    square = cell:getGridSquare(baseX + dx, baseY + dy, baseZ)
                end
                if square then
                    inspectCtx.cachedSquareObjects = cachedObjects
                    reg.InspectSquare(square, addDescriptor, inspectCtx)
                    inspectCtx.cachedSquareObjects = nil
                end
            end
        end
    end

    local snapshot = {
        key = key,
        at = at,
        originX = baseX,
        originY = baseY,
        originZ = baseZ,
        radius = radius,
        resources = resources,
        liveObjects = liveObjects,
    }
    if cacheMs > 0 then
        if cacheCount >= Scanner.MAX_CACHE_ENTRIES then
            cache = {}
            cacheCount = 0
        end
        if not cache[key] then cacheCount = cacheCount + 1 end
        cache[key] = { at = at, snapshot = snapshot }
    end
    return snapshot
end

-- Finds the best unreserved world object matching `capability` within radius,
-- ranked by priority (highest first), then distance (nearest first), then key.
function Scanner.FindBestInRadius(record, origin, capability, options)
    options = type(options) == "table" and options or {}
    local targetsSvc = PNC.FacilityInteractionTargets
    if not origin or not targetsSvc
        or type(targetsSvc.ResolveResource) ~= "function"
    then
        return nil
    end
    local ox = origin.getX and tonumber(origin:getX()) or tonumber(origin.x)
    local oy = origin.getY and tonumber(origin:getY()) or tonumber(origin.y)
    local oz = origin.getZ and tonumber(origin:getZ()) or tonumber(origin.z) or 0
    if ox == nil or oy == nil then return nil end

    local snapshot = Scanner.ScanRadius(ox, oy, oz, {
        radius = options.radius,
        maxObjects = options.maxObjects,
        cacheMs = options.cacheMs,
        force = options.force,
        cell = options.cell,
        record = record,
        character = options.character or origin,
    })
    if not snapshot or type(snapshot.resources) ~= "table" then return nil end

    local detectorFilter
    if type(options.detectorIDs) == "table" and #options.detectorIDs > 0 then
        detectorFilter = {}
        for i = 1, #options.detectorIDs do
            detectorFilter[tostring(options.detectorIDs[i])] = true
        end
    end

    local radius = tonumber(options.radius) or Scanner.DEFAULT_RADIUS
    local best
    for index = 1, #snapshot.resources do
        local resource = snapshot.resources[index]
        if matchesCapability(resource, capability, detectorFilter) then
            local rx = tonumber(resource.x or resource.originX)
            local ry = tonumber(resource.y or resource.originY)
            if rx == nil or ry == nil
                or distanceTo(ox, oy, rx, ry) <= radius + 1.5
            then
                local okResolve, targets = pcall(
                    targetsSvc.ResolveResource,
                    resource,
                    {
                        abstract = options.abstract == true,
                        character = options.character or origin,
                    }
                )
                if okResolve and type(targets) == "table" then
                    local target
                    for tIdx = 1, #targets do
                        local candidate = targets[tIdx]
                        if candidate and candidate.validSpot ~= false
                            and (options.allowReserved == true
                                or not isReserved(resource, candidate))
                        then
                            target = candidate
                            break
                        end
                    end
                    if target then
                        local dist = distanceTo(ox, oy, target.x, target.y)
                        local priority = tonumber(resource.sleepPriority)
                            or tonumber(resource.priority) or 0
                        local resKey = tostring(resource.resourceKey or "")
                        local bestKey = tostring(best and best.resource
                            and best.resource.resourceKey or "")
                        if not best
                            or priority > best.priority
                            or (priority == best.priority and dist < best.distance)
                            or (priority == best.priority and dist == best.distance
                                and resKey < bestKey)
                        then
                            best = {
                                object = target.object
                                    or (snapshot.liveObjects
                                        and snapshot.liveObjects[resKey]),
                                resource = resource,
                                target = target,
                                targets = targets,
                                priority = priority,
                                distance = dist,
                            }
                        end
                    end
                end
            end
        end
    end
    return best
end

function Scanner.ClearCache()
    cache = {}
    cacheCount = 0
end

return Scanner
