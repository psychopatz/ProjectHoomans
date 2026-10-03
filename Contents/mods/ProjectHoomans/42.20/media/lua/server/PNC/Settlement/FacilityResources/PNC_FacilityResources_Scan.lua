-- Facility resource scanning and cache lifecycle.
--
-- Detector registration stays in the root resource namespace because bed,
-- sofa, and seat providers register there. This provider owns the world scan,
-- descriptor normalization, and facility cache contract used by consumers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
local Internal = Resources.Internal or {}
local eachObject = Internal.EachObject

local function integer(value, fallback)
    local number = tonumber(value)
    if not number then return fallback end
    return math.floor(number)
end

local function sortedKeys(source)
    local keys = {}
    for key, _ in pairs(source or {}) do keys[#keys + 1] = tostring(key) end
    table.sort(keys)
    return keys
end

local function defaultKey(detectorId, resource)
    local x = tonumber(resource and resource.x)
        or tonumber(resource and resource.originX) or 0
    local y = tonumber(resource and resource.y)
        or tonumber(resource and resource.originY) or 0
    local z = tonumber(resource and resource.z)
        or tonumber(resource and resource.originZ) or 0
    return tostring(detectorId) .. ":" .. tostring(math.floor(x * 2 + 0.5))
        .. ":" .. tostring(math.floor(y * 2 + 0.5)) .. ":" .. tostring(z)
end

local function detectorList(ids)
    local output = {}
    if type(ids) == "table" and #ids > 0 then
        for index = 1, #ids do
            local detector = Resources.GetDetector(ids[index])
            if detector then output[#output + 1] = detector end
        end
    else
        for _, id in ipairs(sortedKeys(Resources.Detectors)) do
            output[#output + 1] = Resources.Detectors[id]
        end
    end
    return output
end

local function descriptorKey(detector, resource)
    local key = type(detector.key) == "function"
        and detector.key(resource) or nil
    return tostring(key or defaultKey(detector.id, resource))
end

Resources.Internal = Internal
Resources.Internal.DescriptorKey = descriptorKey

local function scanRegion(region, ids)
    local result = { status = "READY", resources = {}, scannedAt = PNC.Core
        and PNC.Core.Now and PNC.Core.Now() or 0 }
    local detectors = detectorList(ids)
    local seen = {}
    local cell = type(getCell) == "function" and getCell() or nil
    if not cell or not cell.getGridSquare then
        result.status = "UNAVAILABLE"
        return result
    end

    local normalized = GridRegion.normalize(region)
    local zKeys = sortedKeys(normalized.levels)
    for zIndex = 1, #zKeys do
        local z = tonumber(zKeys[zIndex])
        local level = normalized.levels[z] or normalized.levels[zKeys[zIndex]]
        local yKeys = sortedKeys(level and level.rows or {})
        for yIndex = 1, #yKeys do
            local y = tonumber(yKeys[yIndex])
            local spans = level.rows[y] or level.rows[yKeys[yIndex]]
            for spanIndex = 1, #(spans or {}), 2 do
                local first = tonumber(spans[spanIndex]) or 0
                local last = tonumber(spans[spanIndex + 1]) or first
                for x = first, last do
                    local square = cell:getGridSquare(x, y, z)
                    if not square then
                        result.status = "UNLOADED"
                    else
                        for detectorIndex = 1, #detectors do
                            local detector = detectors[detectorIndex]
                            local function emit(object, alreadyMatched, objectIndex)
                                if not object then return end
                                if not alreadyMatched then
                                    local matchedOk, matched = pcall(
                                        detector.matches, square, object)
                                    if not matchedOk or matched ~= true then
                                        return
                                    end
                                end
                                local describedOk, resource = pcall(
                                    detector.describe,
                                    square,
                                    object,
                                    { objectIndex = objectIndex }
                                )
                                if not describedOk or type(resource) ~= "table" then
                                    return
                                end
                                local key = descriptorKey(detector, resource)
                                if seen[key] then return end
                                seen[key] = true
                                resource.detectorId = detector.id
                                resource.resourceKind = resource.resourceKind
                                    or detector.resourceKind or detector.id
                                resource.role = resource.role or detector.role
                                resource.resourceKey = key
                                resource.originX = integer(resource.originX, x)
                                resource.originY = integer(resource.originY, y)
                                resource.originZ = integer(resource.originZ, z)
                                resource.exclusive = resource.exclusive ~= false
                                resource.available = true
                                result.resources[#result.resources + 1] = resource
                            end
                            if type(detector.collect) == "function" then
                                pcall(detector.collect, square, function(object, objectIndex)
                                    emit(object, true, objectIndex)
                                end)
                            end
                            eachObject(square, function(object, objectIndex)
                                emit(object, false, objectIndex)
                            end)
                        end
                    end
                end
            end
        end
    end
    table.sort(result.resources, function(a, b)
        return tostring(a.resourceKey or "") < tostring(b.resourceKey or "")
    end)
    return result
end

function Resources.ScanRegion(region, detectorIds)
    if not region or GridRegion.countTiles(region) <= 0 then
        return { status = "EMPTY", resources = {}, scannedAt = 0 }
    end
    return scanRegion(region, detectorIds)
end

function Resources.Refresh(facility)
    if type(facility) ~= "table" or not facility.id then
        return { status = "FACILITY_NOT_FOUND", resources = {} }
    end
    if not FacilityState.IsBuilt(facility) then
        local notBuilt = { status = "NOT_BUILT", resources = {}, scannedAt = 0 }
        Resources.Cache[tostring(facility.id)] = notBuilt
        return notBuilt
    end
    local result = Resources.ScanRegion(facility.constructionRegion)
    result.facilityId = facility.id
    Resources.Cache[tostring(facility.id)] = result
    return result
end

function Resources.Invalidate(facilityOrId)
    local id = type(facilityOrId) == "table" and facilityOrId.id or facilityOrId
    Resources.Cache[tostring(id or "")] = nil
end

function Resources.GetScan(facility, force)
    if type(facility) ~= "table" or not facility.id then
        return { status = "FACILITY_NOT_FOUND", resources = {} }
    end
    local key = tostring(facility.id)
    local cached = Resources.Cache[key]
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    if not force and cached
        and now - (tonumber(cached.scannedAt) or 0)
            < Resources.SCAN_TTL_MS
    then
        return cached
    end
    return Resources.Refresh(facility)
end

function Resources.GetResources(facility, detectorId, force)
    local scan = Resources.GetScan(facility, force)
    local resources = {}
    local detectorIds = type(detectorId) == "table" and detectorId or nil
    local function matchesDetector(resource)
        if not detectorId then return true end
        if detectorIds then
            for index = 1, #detectorIds do
                if tostring(resource.detectorId) == tostring(detectorIds[index]) then
                    return true
                end
            end
            return false
        end
        return tostring(resource.detectorId) == tostring(detectorId)
    end
    for index = 1, #(scan.resources or {}) do
        local resource = scan.resources[index]
        if matchesDetector(resource) then
            resources[#resources + 1] = resource
        end
    end
    return resources, scan.status, scan
end

return Resources
