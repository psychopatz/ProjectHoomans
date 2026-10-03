-- Facility resource capacity and selection policy.
--
-- Scanning produces descriptors; this provider decides how those descriptors
-- satisfy facility bindings, reservation slots, activity capacity, and the
-- explicit virtual-resource fallback used by abstract activities.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local Internal = Resources.Internal or {}

local function firstRegionPoint(region)
    local bounds = GridRegion.bounds(region)
    if not bounds then return nil end
    return { x = bounds.minX + 0.5, y = bounds.minY + 0.5,
        z = bounds.minZ }
end

local function floorRegionPoint(region, npcId)
    local normalized = GridRegion.normalize(region)
    local candidates = {}
    local id = tostring(npcId or "floor")
    local hash = 0
    for index = 1, #id do
        hash = (hash + (string.byte(id, index) or 0) * index) % 2147483647
    end
    for z, level in pairs(normalized.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            for index = 1, #spans, 2 do
                for x = spans[index], spans[index + 1] do
                    candidates[#candidates + 1] = { x = x, y = y, z = z }
                end
            end
        end
    end
    if #candidates == 0 then return nil end
    table.sort(candidates, function(left, right)
        if left.z ~= right.z then return left.z < right.z end
        if left.y ~= right.y then return left.y < right.y end
        return left.x < right.x
    end)
    local candidate = candidates[(hash % #candidates) + 1]
    return {
        x = candidate.x + 0.5, y = candidate.y + 0.5, z = candidate.z,
    }
end

local function binding(facility, capability)
    local level = facility and PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.GetLevel(facility.definitionId,
            facility.level) or nil
    return level and level.resourceBindings
        and level.resourceBindings[tostring(capability or "")] or nil
end

local function bindingDetectorMatches(resourceBinding, resource)
    if not resourceBinding then return false end
    local detectorIds = resourceBinding.detectorIds
    if type(detectorIds) == "table" and #detectorIds > 0 then
        for index = 1, #detectorIds do
            if tostring(resource.detectorId) == tostring(detectorIds[index]) then
                return true
            end
        end
        return false
    end
    return not resourceBinding.detectorId
        or tostring(resource.detectorId) == tostring(resourceBinding.detectorId)
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
            if bindingDetectorMatches(resourceBinding, resource)
            then
                count = count + (tostring(capability or "") == "sleep"
                    and Resources.GetSleepCapacity(resource) or 1)
            end
        end
        -- A confirmed physical resource count is the automatic room
        -- occupancy limit. A missing/unloaded scan falls back to the
        -- definition's activity limit until the room can be inspected.
        if count > 0 and not (resourceBinding.virtual
            and resourceBinding.virtual.allowActivityOverflow == true)
        then
            return count, "detected", scan.status
        end
    end

    local fallback = activityLimit(facility, capability)
    return fallback and math.max(1, math.floor(tonumber(fallback) or 1))
        or nil, "default", scan and scan.status or nil
end

function Resources.GetSleepCapacity(resource)
    if type(resource) ~= "table" then return 1 end
    local explicit = tonumber(resource.sleepCapacity
        or resource.bedCapacity)
    if explicit and explicit >= 1 then
        return math.min(2, math.floor(explicit))
    end
    if tostring(resource.sleepSurface or resource.detectorId or "") == "sofa"
    then
        return 1
    end
    local width = tonumber(resource.gridWidth
        or resource.sleepGridWidth) or 1
    local height = tonumber(resource.gridHeight
        or resource.sleepGridHeight) or 1
    return math.max(width, height) >= 2 and 2 or 1
end

local function isSleepResource(resource)
    local surface = tostring(resource and resource.sleepSurface or "")
    return tostring(resource and resource.resourceKind or "")
        == "sleep_surface"
        and (surface == "bed" or surface == "sofa")
end

local function resourceSlotAvailable(resource, target)
    local reservations = PNC.FacilityReservations
    local key = tostring(resource and resource.resourceKey or "")
    if key == "" then return false end
    if isSleepResource(resource) and reservations
        and reservations.IsResourceAvailable
    then
        return reservations.IsResourceAvailable(resource,
            target and target.sleepSlotId)
    end
    if target and target.sleepSlotId and reservations
        and reservations.ByResourceSlot
    then
        return reservations.ByResourceSlot[key .. ":"
            .. tostring(target.sleepSlotId)] == nil
            and not (reservations.ByResource
                and reservations.ByResource[key])
    end
    return not (reservations and reservations.ByResource
        and reservations.ByResource[key] ~= nil)
end

local function resourceReserved(resource)
    return not resourceSlotAvailable(resource)
end

local function virtualResource(facility, bindingData, npcId)
    local virtual = bindingData and bindingData.virtual
    local point = virtual and virtual.floorSeating == true
        and floorRegionPoint(facility and facility.constructionRegion, npcId)
        or firstRegionPoint(facility and facility.constructionRegion)
    local resourceKey
    local npcKey = tostring(npcId or "")
    if not virtual or not point then return nil end
    resourceKey = tostring(facility.id) .. ":"
        .. tostring(virtual.key or "default")
    if virtual.perNpc == true and npcKey ~= "" then
        resourceKey = resourceKey .. ":" .. npcKey
    end
    return {
        detectorId = "virtual",
        resourceKind = tostring(virtual.resourceKind or "virtual"),
        role = tostring(virtual.role or bindingData.role or ""),
        resourceKey = resourceKey,
        x = point.x, y = point.y, z = point.z,
        originX = math.floor(point.x), originY = math.floor(point.y),
        originZ = math.floor(point.z), exclusive = virtual.exclusive == true,
        virtual = true, available = true,
        seating = virtual.seating == true,
        floorSeating = virtual.floorSeating == true,
    }
end

local function virtualTarget(resource, bindingData)
    local virtual = bindingData and bindingData.virtual or {}
    return { {
        x = resource.x, y = resource.y, z = resource.z,
        sceneId = virtual.sceneId, sleepSurface = virtual.sleepSurface,
        resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind,
        seating = virtual.seating == true,
        floorSeating = virtual.floorSeating == true,
        stopDistance = tonumber(virtual.stopDistance),
        arrivalDistance = tonumber(virtual.arrivalDistance),
    } }
end

-- A sleep activity is allowed to resolve only to a physical sleep surface or
-- the explicit floor fallback. This guard is intentionally independent from
-- detector selection because activities can outlive a scan and rehydrate by
-- a saved resource key.
function Resources.IsValidSleepTarget(resource, target)
    if type(target) ~= "table" then return false end
    if target.seating == true then return false end
    local resourceKind = tostring(resource and resource.resourceKind or "")
    if resourceKind == "seating_surface" then return false end
    local surface = tostring(target.sleepSurface
        or resource and resource.sleepSurface or "")
    if surface == "floor" then
        return tostring(target.sceneId or "") == "facility.sleep.floor"
    end
    if surface ~= "bed" and surface ~= "sofa" then return false end
    local detectorId = tostring(resource and resource.detectorId or "")
    if detectorId ~= "" and detectorId ~= surface then return false end
    local object = target.object or target.furnitureObject
        or resource and resource.object
    if object and SquareRules.ClassifySleepSurface then
        local ok, classified = pcall(SquareRules.ClassifySleepSurface, object)
        if not ok or classified ~= surface then return false end
    end
    return tostring(target.sceneId or "") == "facility.sleep." .. surface
        and (resourceKind == "" or resourceKind == "sleep_surface")
end

function Resources.Select(facility, capability, options)
    options = type(options) == "table" and options or {}
    local bindingData = binding(facility, capability)
    if not bindingData then return nil end
    local resources, scanStatus = Resources.GetResources(
        facility, bindingData.detectorIds or bindingData.detectorId)
    if tostring(capability or "") == "sleep" then
        table.sort(resources, function(left, right)
            local leftPriority = tonumber(left.sleepPriority) or 0
            local rightPriority = tonumber(right.sleepPriority) or 0
            if leftPriority ~= rightPriority then
                return leftPriority > rightPriority
            end
            return tostring(left.resourceKey or "")
                < tostring(right.resourceKey or "")
        end)
    end
    local requestedKey = tostring(options.resourceKey or "")
    for index = 1, #resources do
        local resource = resources[index]
        local keyMatches = requestedKey == ""
            or requestedKey == tostring(resource.resourceKey)
        if keyMatches then
            local targets = PNC.FacilityInteractionTargets
                and PNC.FacilityInteractionTargets.ResolveResource
                and PNC.FacilityInteractionTargets.ResolveResource(resource, {
                    abstract = options.abstract == true,
                    character = options.character,
                }) or {}
            local target
            if tostring(capability or "") == "sleep" then
                for targetIndex = 1, #targets do
                    local candidate = targets[targetIndex]
                    if Resources.IsValidSleepTarget(resource, candidate)
                        and resourceSlotAvailable(resource, candidate)
                    then
                        target = candidate
                        break
                    end
                end
            elseif resourceSlotAvailable(resource, targets[1]) then
                target = targets[1]
            end
            if target
            then
                return { resource = resource, target = target, targets = targets,
                    role = resource.role or bindingData.role,
                    resourceKind = resource.resourceKind or bindingData.resourceKind,
                    resourceKey = resource.resourceKey,
                    sleepSlotId = target.sleepSlotId,
                    sleepCapacity = target.sleepCapacity
                        or Resources.GetSleepCapacity(resource),
                    bedCapacity = target.bedCapacity
                        or Resources.GetSleepCapacity(resource),
                    scanStatus = scanStatus }
            end
        end
    end
    local virtual = virtualResource(facility, bindingData, options.npcId)
    if virtual and not resourceReserved(virtual) then
        local targets = virtualTarget(virtual, bindingData)
        local target = targets[1]
        if tostring(capability or "") ~= "sleep"
            or Resources.IsValidSleepTarget(virtual, target)
        then
            return { resource = virtual, target = target, targets = targets,
                role = virtual.role, resourceKind = virtual.resourceKind,
                resourceKey = virtual.resourceKey,
                sleepSlotId = target and target.sleepSlotId,
                sleepCapacity = target and target.sleepCapacity
                    or Resources.GetSleepCapacity(virtual),
                floorSeating = virtual.floorSeating == true,
                scanStatus = scanStatus }
        end
    end
    return nil
end

Resources.Internal = Internal
Resources.Internal.VirtualResource = virtualResource
Resources.Internal.VirtualTarget = virtualTarget

return Resources
