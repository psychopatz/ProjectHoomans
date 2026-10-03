--[[
    PNC Network Snapshots - Detailed Debug State
    Builds the diagnostic section embedded in a full NPC snapshot.
]]

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts

local CAMP_RESOURCE_DEBUG_MAX = 8
local SEATING_DEBUG_MAX = 12
local SEATING_SPOT_DEBUG_MAX = 16
local CAMP_DEBUG_CACHE_MAX = 64
local campDebugCache = {}
local campDebugCacheOrder = {}

local function copyCampPoint(value)
    if type(value) ~= "table" then return nil end
    if value.x == nil and value.y == nil and value.z == nil then
        return nil
    end
    return {
        x = tonumber(value.x),
        y = tonumber(value.y),
        z = tonumber(value.z),
    }
end

local function cachedCampState(record)
    local service = PNC.CampResourceService
    if service and service.GetCachedSnapshot then
        return service.GetCachedSnapshot(record)
    end
    -- Client-only/debug fixtures may not load the server service. Keep the
    -- compatibility fallback, while production no longer serializes this
    -- table into each NPC record.
    return record and record.campState or nil
end

local function campResourceCategory(resource)
    local resourceKind = tostring(resource and resource.resourceKind or "")
    local detectorId = tostring(resource and resource.detectorId or "")
    local role = tostring(resource and resource.role or "")
    if resourceKind == "sleep_surface"
        or detectorId == "bed"
        or string.sub(role, 1, 6) == "sleep."
    then
        return "bed"
    end
    if resourceKind == "water_source"
        or resourceKind == "world_water"
        or resourceKind == "water_refill"
        or detectorId == "faucet"
        or string.sub(role, 1, 6) == "water."
        or role == "survival.world_water"
    then
        return "water"
    end
    if resourceKind == "seating_surface"
        or detectorId == "seat"
        or string.sub(role, 1, 7) == "living."
    then
        return "seating"
    end
    return "other"
end

local function addResourceJob(jobs, seen, value)
    value = tostring(value or "")
    if value ~= "" and not seen[value] then
        seen[value] = true
        jobs[#jobs + 1] = value
    end
end

local function campResourceJobs(resource)
    local jobs = {}
    local seen = {}
    local explicit = resource and (resource.supportedJobs
        or resource.supportedActivities)
    if type(explicit) == "table" then
        for index = 1, #explicit do
            addResourceJob(jobs, seen, explicit[index])
        end
    elseif type(explicit) == "string" then
        addResourceJob(jobs, seen, explicit)
    end

    if #jobs == 0 then
        local category = campResourceCategory(resource)
        if category == "bed" then
            addResourceJob(jobs, seen, "sleep")
        elseif category == "water" then
            addResourceJob(jobs, seen, "drink")
        elseif category == "seating" then
            addResourceJob(jobs, seen, "sit")
        end
    end

    if #jobs == 0 and resource then
        addResourceJob(jobs, seen, resource.capability)
    end
    return jobs
end

local function copyCampResource(resource)
    if type(resource) ~= "table" then return nil end
    local category = campResourceCategory(resource)
    local available = resource.available ~= false
    local blocked = false
    if category == "seating" and type(resource.seatSpots) == "table"
        and #resource.seatSpots > 0
    then
        local usable = false
        local deferred = false
        for index = 1, #resource.seatSpots do
            local spot = resource.seatSpots[index]
            if type(spot) == "table" then
                if spot.validationState == "DEFERRED" then
                    deferred = true
                elseif spot.valid ~= false
                    and spot.approachValid ~= false
                then
                    usable = true
                end
            end
        end
        if not usable and not deferred then
            available = false
            blocked = true
        end
    end
    return {
        resourceKey = tostring(resource.resourceKey or resource.key or ""),
        detectorId = tostring(resource.detectorId or ""),
        resourceKind = tostring(resource.resourceKind or resource.kind or ""),
        role = tostring(resource.role or ""),
        capability = tostring(resource.capability or ""),
        category = category,
        supportedJobs = campResourceJobs(resource),
        x = tonumber(resource.x),
        y = tonumber(resource.y),
        z = tonumber(resource.z),
        originX = tonumber(resource.originX),
        originY = tonumber(resource.originY),
        originZ = tonumber(resource.originZ),
        available = available,
        blocked = blocked,
        selected = resource.selected == true,
    }
end

local function copyCampResourceView(resource, selected, available)
    local output = {}
    if type(resource) ~= "table" then return nil end
    for key, value in pairs(resource) do output[key] = value end
    output.selected = selected == true
    output.available = available ~= false
    return output
end

-- Resource classification is shared by every NPC in a camp. Keep one static
-- diagnostic view per current runtime snapshot and only clone the small
-- per-NPC reservation/selection overlay below. This reduces repeated table
-- work while preserving the existing wire shape and per-NPC activity state.
local function cachedCampDebugBase(state)
    local campId
    local cached
    local output
    local resources
    if type(state) ~= "table" then return nil end
    campId = tostring(state.campId or "")
    cached = campDebugCache[campId]
    if campId ~= "" and cached and cached.state == state then
        return cached
    end
    resources = type(state.resources) == "table" and state.resources or {}
    output = {
        state = state,
        resourceCount = #resources,
        bedCount = 0,
        waterCount = 0,
        seatingCount = 0,
        otherCount = 0,
        facilities = {},
        byKey = {},
    }
    for index = 1, #resources do
        local resource = resources[index]
        local category = campResourceCategory(resource)
        local copied = copyCampResource(resource)
        if category == "bed" then
            output.bedCount = output.bedCount + 1
        elseif category == "water" then
            output.waterCount = output.waterCount + 1
        elseif category == "seating" then
            output.seatingCount = output.seatingCount + 1
        else
            output.otherCount = output.otherCount + 1
        end
        if copied then
            local resourceKey = tostring(resource.resourceKey
                or resource.key or "")
            output.byKey[resourceKey] = copied
            if #output.facilities < CAMP_RESOURCE_DEBUG_MAX then
                output.facilities[#output.facilities + 1] = copied
            end
        end
    end
    if campId ~= "" then
        if not cached then campDebugCacheOrder[#campDebugCacheOrder + 1] = campId end
        campDebugCache[campId] = output
        while #campDebugCacheOrder > CAMP_DEBUG_CACHE_MAX do
            local expired = table.remove(campDebugCacheOrder, 1)
            campDebugCache[expired] = nil
        end
    end
    return output
end

local function copySeatingResource(resource, character, selectedKey,
    selectedTarget)
    if type(resource) ~= "table" then return nil end
    local output = copyCampResource(resource)
    output.seatCount = tonumber(resource.seatCount) or 1
    output.facilityId = resource.facilityId
    output.selected = tostring(resource.resourceKey or "")
        == tostring(selectedKey or "")
    output.available = output.available
        and not (PNC.FacilityReservations
            and PNC.FacilityReservations.ByResource
            and PNC.FacilityReservations.ByResource[
                tostring(resource.resourceKey or "")
            ] ~= nil
            and not output.selected)
    local spots = resource.seatSpots
    local targets = PNC.FacilityInteractionTargets
        and PNC.FacilityInteractionTargets.ResolveResource
        and PNC.FacilityInteractionTargets.ResolveResource(resource, {
            abstract = character == nil, character = character,
            includeInvalid = true,
        }) or nil
    if type(targets) == "table" and #targets > 0 then spots = targets end
    output.spots = {}
    for index = 1, math.min(SEATING_SPOT_DEBUG_MAX, #(spots or {})) do
        local spot = spots[index]
        if type(spot) == "table" and tonumber(spot.x)
            and tonumber(spot.y) and tonumber(spot.z)
        then
            local selectedSpot = output.selected
                and ((selectedTarget
                    and math.abs(tonumber(spot.x) - tonumber(selectedTarget.x or 0)) < 0.2
                    and math.abs(tonumber(spot.y) - tonumber(selectedTarget.y or 0)) < 0.2
                    and math.abs(tonumber(spot.z) - tonumber(selectedTarget.z or 0)) < 0.2)
                    or (selectedTarget == nil and index == 1))
                or false
            output.spots[#output.spots + 1] = {
                x = tonumber(spot.x), y = tonumber(spot.y),
                z = tonumber(spot.z),
                seatAnchorX = tonumber(spot.seatAnchorX or spot.x),
                seatAnchorY = tonumber(spot.seatAnchorY or spot.y),
                seatAnchorZ = tonumber(spot.seatAnchorZ or spot.z),
                direction = spot.direction or spot.seatDirection,
                side = spot.side or spot.seatSide,
                approachKey = spot.approachKey,
                validationState = spot.validationState,
                rejectionReason = spot.rejectionReason,
                routeStatus = spot.routeStatus,
                source = (spot.valid == false or spot.validSpot == false
                    or spot.approachValid == false)
                    and "invalid" or "engine",
                valid = spot.valid ~= false
                    and spot.validSpot ~= false
                    and spot.approachValid ~= false,
                selected = selectedSpot,
            }
        end
    end
    return output
end


Parts.Internal = Parts.Internal or {}
local Internal = Parts.Internal
Internal.copyCampPoint = copyCampPoint
Internal.cachedCampState = cachedCampState
Internal.campResourceCategory = campResourceCategory
Internal.copyCampResource = copyCampResource
Internal.cachedCampDebugBase = cachedCampDebugBase
Internal.copyCampResourceView = copyCampResourceView
Internal.copySeatingResource = copySeatingResource
Internal.CAMP_RESOURCE_DEBUG_MAX = CAMP_RESOURCE_DEBUG_MAX
Internal.SEATING_DEBUG_MAX = SEATING_DEBUG_MAX
Internal.SEATING_SPOT_DEBUG_MAX = SEATING_SPOT_DEBUG_MAX

return Parts
