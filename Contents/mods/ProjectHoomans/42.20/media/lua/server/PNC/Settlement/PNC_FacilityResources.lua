-- Generic world-resource discovery for zone-backed facilities.
--
-- Facilities own regions; detectors describe the world objects found inside
-- those regions. The resulting descriptors are runtime resources, not
-- persisted editable facility components. This keeps furniture discovery
-- reusable for beds, chairs, tables, and future faction-owned facilities.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"

Resources.Detectors = Resources.Detectors or {}
Resources.Cache = Resources.Cache or {}
Resources.SCAN_TTL_MS = Resources.SCAN_TTL_MS or 5000
Resources.MAX_CAPACITY = Resources.MAX_CAPACITY or 999

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

local function eachObject(square, visitor)
    local objects = square and square.getObjects
        and square:getObjects() or nil
    if not objects then return end
    if objects.size and objects.get then
        for index = 0, objects:size() - 1 do
            visitor(objects:get(index))
        end
        return
    end
    for index = 1, #objects do visitor(objects[index]) end
end

local function copyDescriptor(resource)
    local output = {}
    for key, value in pairs(resource or {}) do
        -- Java object references are valid for the live server cache but must
        -- never cross the snapshot/save boundary.
        if key ~= "object" and type(value) ~= "function"
            and type(value) ~= "userdata"
        then
            output[key] = value
        end
    end
    return output
end

-- Runtime callers may keep the descriptor on an activity or reservation.
-- Expose the same boundary used by settlement snapshots so Java world objects
-- never become part of persisted/debuggable runtime state.
Resources.CopyDescriptor = copyDescriptor

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

function Resources.Register(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.matches) ~= "function"
        or type(definition.describe) ~= "function"
    then
        return false, "INVALID_RESOURCE_DETECTOR"
    end
    definition.id = id
    Resources.Detectors[id] = definition
    Resources.Cache = {}
    return true, definition
end

function Resources.GetDetector(id)
    return Resources.Detectors[tostring(id or "")]
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
                            local function emit(object, alreadyMatched)
                                if not object then return end
                                if not alreadyMatched then
                                    local matchedOk, matched = pcall(
                                        detector.matches, square, object)
                                    if not matchedOk or matched ~= true then
                                        return
                                    end
                                end
                                local describedOk, resource = pcall(
                                    detector.describe, square, object)
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
                                pcall(detector.collect, square, function(object)
                                    emit(object, true)
                                end)
                            end
                            eachObject(square, function(object)
                                emit(object, false)
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
    local state = tostring(facility.constructionState or "BUILT")
    if state ~= "BUILT" then
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
    for index = 1, #(scan.resources or {}) do
        local resource = scan.resources[index]
        if not detectorId or tostring(resource.detectorId) == tostring(detectorId) then
            resources[#resources + 1] = resource
        end
    end
    return resources, scan.status, scan
end

local function firstRegionPoint(region)
    local bounds = GridRegion.bounds(region)
    if not bounds then return nil end
    return { x = bounds.minX + 0.5, y = bounds.minY + 0.5,
        z = bounds.minZ }
end

local function binding(facility, capability)
    local level = facility and PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.GetLevel(facility.definitionId,
            facility.level) or nil
    return level and level.resourceBindings
        and level.resourceBindings[tostring(capability or "")] or nil
end

function Resources.GetBinding(facility, capability)
    return binding(facility, capability)
end

function Resources.NormalizeCapacity(value)
    if value == nil then return nil end
    if type(value) == "string" then
        local text = string.lower(value)
        if text == "" or text == "auto" then return nil end
    end
    local capacity = tonumber(value)
    if not capacity or capacity ~= math.floor(capacity)
        or capacity < 1 or capacity > Resources.MAX_CAPACITY
    then
        return nil, "INVALID_ROOM_CAPACITY"
    end
    return capacity
end

local function activityLimit(facility, capability)
    local level = facility and PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.GetLevel(facility.definitionId,
            facility.level) or nil
    return level and level.activityLimits
        and level.activityLimits[tostring(capability or "")]
        and level.activityLimits[tostring(capability or "")].maxConcurrent
end

function Resources.GetCapacity(facility, capability, suppliedScan)
    if type(facility) ~= "table" then return nil, "missing" end
    local configured, reason = Resources.NormalizeCapacity(facility.capacity)
    if reason then
        configured = nil
    end
    if configured then return configured, "configured" end

    local resourceBinding = binding(facility, capability)
    local scan = suppliedScan
    if resourceBinding then
        scan = scan or Resources.GetScan(facility)
        local count = 0
        for index = 1, #(scan.resources or {}) do
            local resource = scan.resources[index]
            if not resourceBinding.detectorId
                or tostring(resource.detectorId)
                    == tostring(resourceBinding.detectorId)
            then
                count = count + 1
            end
        end
        -- A confirmed physical resource count is the automatic room
        -- occupancy limit. A missing/unloaded scan falls back to the
        -- definition's activity limit until the room can be inspected.
        if count > 0 then return count, "detected", scan.status end
    end

    local fallback = activityLimit(facility, capability)
    return fallback and math.max(1, math.floor(tonumber(fallback) or 1))
        or nil, "default", scan and scan.status or nil
end

local function resourceReserved(resource)
    local reservations = PNC.FacilityReservations
    return reservations and reservations.ByResource
        and reservations.ByResource[tostring(resource.resourceKey or "")] ~= nil
end

local function virtualResource(facility, bindingData)
    local virtual = bindingData and bindingData.virtual
    local point = firstRegionPoint(facility and facility.constructionRegion)
    if not virtual or not point then return nil end
    return {
        detectorId = "virtual",
        resourceKind = tostring(virtual.resourceKind or "virtual"),
        role = tostring(bindingData.role or ""),
        resourceKey = tostring(facility.id) .. ":"
            .. tostring(virtual.key or "default"),
        x = point.x, y = point.y, z = point.z,
        originX = math.floor(point.x), originY = math.floor(point.y),
        originZ = math.floor(point.z), exclusive = virtual.exclusive == true,
        virtual = true, available = true,
    }
end

local function virtualTarget(resource, bindingData)
    local virtual = bindingData and bindingData.virtual or {}
    return { {
        x = resource.x, y = resource.y, z = resource.z,
        sceneId = virtual.sceneId, sleepSurface = virtual.sleepSurface,
        resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind,
    } }
end

function Resources.Select(facility, capability, options)
    options = type(options) == "table" and options or {}
    local bindingData = binding(facility, capability)
    if not bindingData then return nil end
    local resources, scanStatus = Resources.GetResources(
        facility, bindingData.detectorId)
    local requestedKey = tostring(options.resourceKey or "")
    for index = 1, #resources do
        local resource = resources[index]
        local keyMatches = requestedKey == ""
            or requestedKey == tostring(resource.resourceKey)
        if keyMatches and not resourceReserved(resource) then
            local targets = PNC.FacilityInteractionTargets
                and PNC.FacilityInteractionTargets.ResolveResource
                and PNC.FacilityInteractionTargets.ResolveResource(resource, {
                    abstract = options.abstract == true,
                }) or {}
            local target = targets[1]
            if target then
                return { resource = resource, target = target, targets = targets,
                    role = resource.role or bindingData.role,
                    resourceKind = resource.resourceKind or bindingData.resourceKind,
                    resourceKey = resource.resourceKey,
                    scanStatus = scanStatus }
            end
        end
    end
    local virtual = virtualResource(facility, bindingData)
    if virtual and not resourceReserved(virtual) then
        local targets = virtualTarget(virtual, bindingData)
        return { resource = virtual, target = targets[1], targets = targets,
            role = virtual.role, resourceKind = virtual.resourceKind,
            resourceKey = virtual.resourceKey, scanStatus = scanStatus }
    end
    return nil
end

function Resources.BuildSnapshot(facility)
    local scan = Resources.GetScan(facility)
    local resources = {}
    local components = {}
    local counts = {}
    for index = 1, #(scan.resources or {}) do
        local resource = scan.resources[index]
        local copy = copyDescriptor(resource)
        resources[#resources + 1] = copy
        local role = tostring(copy.role or copy.detectorId or "resource")
        counts[role] = (counts[role] or 0) + 1
        copy.kind = "discovered"
        copy.readOnly = true
        components[#components + 1] = copy
    end
    local bedCount = tonumber(counts["sleep.bed"]) or 0
    if not binding(facility, "sleep") then
        return { resources = resources, components = components }
    end
    local capacity, capacityMode = Resources.GetCapacity(
        facility, "sleep", scan)
    local configuredCapacity = Resources.NormalizeCapacity(facility.capacity)
    local profile = {
        scanStatus = scan.status,
        resourceCounts = counts,
        bedCount = bedCount,
        capacity = capacity,
        capacityOverride = configuredCapacity,
        capacityMode = configuredCapacity and "configured" or capacityMode,
        classification = (configuredCapacity or bedCount) > 1
            and "barracks" or "bedroom",
        roomLabelKey = (configuredCapacity or bedCount) > 1
            and "UI_PNC_Facility_Barracks"
            or "UI_PNC_Facility_Bedroom",
    }
    if bedCount == 0 then profile.sleepSurface = "floor" end
    return { resources = resources, components = components, profile = profile }
end

function Resources.ResolveActivityTarget(record)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or record and record.orderSpec or nil
    local facilityId = activity and activity.facilityId or nil
    local facility = PNC.SettlementRepository and PNC.SettlementRepository
        .GetFacility(facilityId) or nil
    local resourceKey = tostring(activity and activity.resourceKey or "")
    if not facility or resourceKey == "" then return nil end
    local function findResource(resources)
        for index = 1, #resources do
            local resource = resources[index]
            if tostring(resource.resourceKey) == resourceKey then
                local targets = PNC.FacilityInteractionTargets
                    and PNC.FacilityInteractionTargets.ResolveResource
                    and PNC.FacilityInteractionTargets.ResolveResource(resource, {
                        abstract = false,
                    }) or {}
                if targets[1] then return targets[1], resource end
            end
        end
        return nil
    end
    local resources = Resources.GetResources(facility)
    local target, resource = findResource(resources)
    if target then return target, resource end
    -- A saved resource can outlive the current chunk. Force one refresh only
    -- after the cached descriptor failed, preserving the cached bed for the
    -- normal unloaded-chunk handoff path.
    resources = Resources.GetResources(facility, nil, true)
    target, resource = findResource(resources)
    if target then return target, resource end
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    for _, capabilityBinding in pairs(level and level.resourceBindings or {}) do
        if capabilityBinding.virtual
            and tostring(capabilityBinding.virtual.resourceKind or "")
                == tostring(activity.resourceKind or "")
        then
            local virtual = virtualResource(facility, capabilityBinding)
            if virtual and virtual.resourceKey == resourceKey then
                return virtualTarget(virtual, capabilityBinding)[1], virtual
            end
        end
    end
    return nil
end

function Resources.ApplyMaterializationTarget(record, zombie, target)
    if not record or not zombie or type(target) ~= "table" then return false end
    if target.interactionX and target.interactionY
        and PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        local z = target.interactionZ or target.z
        PNC.LiveBodyControl.SetAuthoritativePosition(
            zombie, target.interactionX, target.interactionY, z)
        record.x, record.y, record.z = target.interactionX,
            target.interactionY, z
    end
    local directionName = tostring(target.interactionFacing or "")
    if directionName == "" and target.interactionAxis == "x" then
        directionName = "E"
    elseif directionName == "" and target.interactionAxis == "y" then
        directionName = "S"
    end
    if directionName ~= "" and IsoDirections
        and zombie.setForwardIsoDirection
    then
        local direction = IsoDirections[directionName]
        if direction then
            pcall(zombie.setForwardIsoDirection, zombie, direction)
        end
    end
    return target.interactionX ~= nil and target.interactionY ~= nil
end

Resources.Register("bed", {
    resourceKind = "sleep_surface",
    role = "sleep.bed",
    collect = function(square, add)
        local object = SquareRules.FindBed(square)
        if object then add(object) end
    end,
    matches = function(_, object)
        return SquareRules.IsActualBed(object)
    end,
    describe = function(square, object)
        local bed = SquareRules.DescribeBed(square, object)
        if not bed then return nil end
        bed.resourceKind = "sleep_surface"
        bed.role = "sleep.bed"
        return bed
    end,
    key = function(resource)
        return "bed:" .. tostring(math.floor((tonumber(resource.x) or 0) * 2 + 0.5))
            .. ":" .. tostring(math.floor((tonumber(resource.y) or 0) * 2 + 0.5))
            .. ":" .. tostring(tonumber(resource.z) or 0)
    end,
})

return Resources
