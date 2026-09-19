-- Camp resource target selection, revalidation, and reservation adapters.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Water = PNC.NearbyWaterService
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"

local function number(value, fallback)
    return Internal.Number(value, fallback)
end

local function floorSlot(record, order)
    local hash = 0
    local id = tostring(record and record.id or "npc")
    for index = 1, #id do
        hash = (hash + (string.byte(id, index) or 0) * index) % 8
    end
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 },
    }
    local slot = Internal.CampScope(order) == CampSite.SCOPES.ROOM
        and offsets[1] or offsets[hash + 1]
    local x = math.floor(number(order.x, record.x or 0)) + slot[1] + 0.5
    local y = math.floor(number(order.y, record.y or 0)) + slot[2] + 0.5
    local campId = tostring(order.campId or "camp:" .. id)
    return {
        kind = "virtual", targetResolver = "floor",
        resourceKind = "floor_sleep", role = "sleep.floor",
        resourceKey = campId .. ":floor:" .. id,
        x = x, y = y, z = number(order.z, record.z or 0),
        originX = math.floor(x), originY = math.floor(y),
        originZ = math.floor(number(order.z, record.z or 0)),
        exclusive = false, available = true,
        sceneId = "facility.sleep.floor", sleepSurface = "floor",
    }
end

local function floorSeatSlot(record, order)
    local hash = 0
    local id = tostring(record and record.id or "npc")
    for index = 1, #id do
        hash = (hash + (string.byte(id, index) or 0) * index) % 8
    end
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 },
    }
    local slot = Internal.CampScope(order) == CampSite.SCOPES.ROOM
        and offsets[1] or offsets[hash + 1]
    local x = math.floor(number(order.x, record.x or 0)) + slot[1] + 0.5
    local y = math.floor(number(order.y, record.y or 0)) + slot[2] + 0.5
    local campId = tostring(order.campId or "camp:" .. id)
    local z = number(order.z, record.z or 0)
    return {
        kind = "virtual", targetResolver = "floor",
        resourceKind = "floor_seating", role = "living.floor",
        resourceKey = campId .. ":floor_sit:" .. id,
        x = x, y = y, z = z,
        originX = math.floor(x), originY = math.floor(y), originZ = math.floor(z),
        exclusive = false, available = true, virtual = true,
        sceneId = "facility.living.sit", seating = true,
        floorSeating = true, stopDistance = 0.45, arrivalDistance = 0.55,
    }
end

local function floorSeatTarget(resource)
    return {
        x = resource.x, y = resource.y, z = resource.z,
        sceneId = resource.sceneId, resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind, seating = true,
        floorSeating = true, stopDistance = resource.stopDistance,
        arrivalDistance = resource.arrivalDistance,
    }
end

local function reserved(resource, excludeKey, target, excludeReservationId)
    local key = tostring(resource and resource.resourceKey or "")
    if key == "" then return false end
    if tostring(excludeKey or "") ~= "" and key == tostring(excludeKey) then
        return true
    end
    if target and target.sleepSlotId
        and PNC.FacilityReservations
        and PNC.FacilityReservations.IsResourceAvailable
    then
        return not PNC.FacilityReservations.IsResourceAvailable(
            resource, target.sleepSlotId, excludeReservationId)
    end
    if resource and (resource.sleepSurface == "bed"
        or resource.sleepSurface == "sofa")
        and PNC.FacilityReservations
        and PNC.FacilityReservations.IsResourceAvailable
    then
        return not PNC.FacilityReservations.IsResourceAvailable(
            resource, nil, excludeReservationId)
    end
    return PNC.FacilityReservations
        and PNC.FacilityReservations.ByResource
        and PNC.FacilityReservations.ByResource[key] ~= nil
end

local function resolveSleep(resource, abstract, character, excludeKey,
    excludeReservationId)
    local sleepSurface = tostring(resource and resource.sleepSurface or "")
    local detectorId = tostring(resource and resource.detectorId or "")
    if type(resource) ~= "table"
        or tostring(resource.resourceKind or "") ~= "sleep_surface"
        or (sleepSurface ~= "bed" and sleepSurface ~= "sofa")
        or detectorId ~= sleepSurface
    then
        return nil, {}
    end
    if tostring(excludeKey or "") ~= ""
        and tostring(resource.resourceKey or "") == tostring(excludeKey)
    then
        return nil, {}
    end
    local targets = Targets and Targets.ResolveResource
        and Targets.ResolveResource(resource, {
            abstract = abstract == true, character = character,
        }) or {}
    for index = 1, #targets do
        local target = targets[index]
        if (not Resources or not Resources.IsValidSleepTarget
            or Resources.IsValidSleepTarget(resource, target))
            and not reserved(resource, nil, target, excludeReservationId)
        then
            return target, targets
        end
    end
    return nil, targets
end

local function resolveSeat(resource, abstract, character, approachKey)
    local targets = Targets and Targets.ResolveResource
        and Targets.ResolveResource(resource, {
            abstract = abstract == true, character = character,
            approachKey = approachKey,
        }) or {}
    return targets[1], targets
end

local function resolveWater(record, resource)
    local key = tostring(resource and resource.resourceKey or "")
    local source
    if key ~= "" and Water and Water.Resolve then
        source = Water.Resolve(record, key)
    end
    -- A reload may change an object ordinal. Use the captured square as a
    -- bounded fallback before declaring the source gone.
    if not source and Water and Water.FindAt and resource then
        source = Water.FindAt(record, resource.originX, resource.originY,
            resource.originZ or resource.z)
    end
    return source
end

local function resolveWaterTarget(record, resource, abstract)
    local source = resolveWater(record, resource)
    local target
    local targets
    if source and Water and Water.BuildApproach then
        target, targets = Water.BuildApproach(record, source)
        if target then
            target.sceneId = target.sceneId or "survival.drink.world"
            target.resourceKey = resource.resourceKey
            target.resourceKind = "world_water"
            return target, targets, source
        end
    end
    if abstract == true then
        return {
            x = number(resource.x, resource.originX or 0),
            y = number(resource.y, resource.originY or 0),
            z = number(resource.z, resource.originZ or 0),
            sceneId = "survival.drink.world",
            resourceKey = resource.resourceKey,
            resourceKind = "world_water",
        }, nil, resource
    end
    return nil, nil, source
end

function Service.FindSleep(record, options)
    options = type(options) == "table" and options or {}
    local state = Service.GetSnapshot(record, options.force == true)
    local resources = state and state.resources or {}
    local selected
    local live = options.character
        or PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
    for index = 1, #resources do
        local resource = resources[index]
        local sleepSurface = tostring(resource.sleepSurface or "")
        if tostring(resource.resourceKind or "") == "sleep_surface"
            and tostring(resource.detectorId or "") == sleepSurface
            and (sleepSurface == "bed" or sleepSurface == "sofa")
        then
            local target, targets = resolveSleep(resource, options.abstract,
                live, options.excludeKey, options.excludeReservationId)
            if target and Internal.TargetWithinCamp(record, target) then
                local priority = tonumber(resource.sleepPriority) or 0
                if not selected
                    or priority > selected.priority
                    or (priority == selected.priority
                        and tostring(resource.resourceKey or "")
                            < tostring(selected.resource.resourceKey or ""))
                then
                    selected = {
                        resource = resource, target = target, targets = targets,
                        priority = priority,
                    }
                end
            end
        end
    end
    if selected then
        return selected.resource, selected.target, selected.targets
    end
    if options.allowFloor ~= false then
        local resource = floorSlot(record, Internal.CampContext(record) or {})
        return resource, {
            x = resource.x, y = resource.y, z = resource.z,
            sceneId = resource.sceneId, sleepSurface = resource.sleepSurface,
            resourceKey = resource.resourceKey,
            resourceKind = resource.resourceKind,
        }, nil
    end
    return nil, nil, nil, "CAMP_SLEEP_UNAVAILABLE"
end

function Service.FindSeat(record, options)
    options = type(options) == "table" and options or {}
    local state = Service.GetSnapshot(record, options.force == true)
    local resources = state and state.resources or {}
    local live = options.character
        or PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
    for index = 1, #resources do
        local resource = resources[index]
        if tostring(resource.resourceKind or "") == "seating_surface"
            and not reserved(resource, options.excludeKey)
        then
            local target, targets = resolveSeat(
                resource, options.abstract, live)
            if target and Internal.TargetWithinCamp(record, target) then
                return resource, target, targets
            end
        end
    end
    if options.allowFloor ~= false then
        local resource = floorSeatSlot(record, Internal.CampContext(record) or {})
        local target = floorSeatTarget(resource)
        if Internal.TargetWithinCamp(record, target) then
            return resource, target, nil
        end
    end
    return nil, nil, nil, "CAMP_SEAT_UNAVAILABLE"
end

function Service.FindWater(record, options)
    options = type(options) == "table" and options or {}
    local state = Service.GetSnapshot(record, options.force == true)
    local resources = state and state.resources or {}
    local excludeKey = tostring(options.excludeKey or "")
    for index = 1, #resources do
        local resource = resources[index]
        local key = tostring(resource.resourceKey or "")
        if tostring(resource.resourceKind or "") == "water_source"
            and key ~= excludeKey and not reserved(resource, excludeKey)
        then
            local target, targets, source = resolveWaterTarget(
                record, resource, options.abstract == true)
            if target and Internal.TargetWithinCamp(record, target) then
                return resource, target, targets, source
            end
        end
    end
    return nil, nil, nil, nil, "CAMP_WATER_UNAVAILABLE"
end

local function reserve(record, resource, campId, target)
    local reservations = PNC.FacilityReservations
    if not reservations or not reservations.ReserveResource then
        return false, "CAMP_RESERVATIONS_UNAVAILABLE"
    end
    return reservations.ReserveResource(
        Internal.CampFacilityId(campId), resource, record.id, "sleep", 30000,
        {
            campId = campId, campResource = true,
            sleepSlotId = target and target.sleepSlotId,
            sleepCapacity = target and target.sleepCapacity
                or resource and resource.sleepCapacity,
        })
end

local function reserveSeat(record, resource, campId)
    local reservations = PNC.FacilityReservations
    if not reservations or not reservations.ReserveResource then
        return false, "CAMP_RESERVATIONS_UNAVAILABLE"
    end
    return reservations.ReserveResource(
        Internal.CampFacilityId(campId), resource, record.id, "living", 30000,
        { campId = campId, campResource = true })
end

local function reserveWater(record, resource, campId)
    local reservations = PNC.FacilityReservations
    if not reservations or not reservations.ReserveResource then
        return false, "CAMP_RESERVATIONS_UNAVAILABLE"
    end
    return reservations.ReserveResource(
        Internal.CampFacilityId(campId), resource, record.id, "world_water", 30000,
        { campId = campId, campResource = true })
end

Internal.FloorSlot = floorSlot
Internal.FloorSeatSlot = floorSeatSlot
Internal.FloorSeatTarget = floorSeatTarget
Internal.Reserved = reserved
Internal.ResolveSleep = resolveSleep
Internal.ResolveSeat = resolveSeat
Internal.ResolveWater = resolveWater
Internal.ResolveWaterTarget = resolveWaterTarget
Internal.Reserve = reserve
Internal.ReserveSeat = reserveSeat
Internal.ReserveWater = reserveWater

return Service
