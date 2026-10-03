-- Camp activity acquisition, target revalidation, and lifecycle cleanup.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local Resources = PNC.FacilityResources

local function number(value, fallback)
    return Internal.Number(value, fallback)
end

local function campOrder(record)
    return Internal.CampOrder(record)
end

local function campContext(record)
    return Internal.CampContext(record)
end

local function targetWithinCamp(record, target)
    return Internal.TargetWithinCamp(record, target)
end

local function applyTarget(record, target)
    if not target then return false end
    local activity = record.runtime and record.runtime.facilityActivity or {}
    local order = record.orderSpec or {}
    order.x, order.y, order.z = target.x, target.y, target.z
    order.seatAnchorX = target.seatAnchorX
    order.seatAnchorY = target.seatAnchorY
    order.seatAnchorZ = target.seatAnchorZ
    order.interactionX, order.interactionY, order.interactionZ =
        target.interactionX, target.interactionY, target.interactionZ
    order.interactionSurfaceOffset = target.interactionSurfaceOffset
    order.interactionAxis, order.interactionFacing = target.interactionAxis,
        target.interactionFacing
    order.sleepAnchorX, order.sleepAnchorY, order.sleepAnchorZ =
        target.sleepAnchorX, target.sleepAnchorY, target.sleepAnchorZ
    order.sleepAxis, order.sleepFacing = target.sleepAxis, target.sleepFacing
    order.sleepSprite = target.sleepSprite
    order.sleepGridX, order.sleepGridY = target.sleepGridX, target.sleepGridY
    order.sleepGridWidth, order.sleepGridHeight = target.sleepGridWidth,
        target.sleepGridHeight
    order.sleepSlotId = target.sleepSlotId
    order.sleepSlotIndex = target.sleepSlotIndex
    order.sleepCapacity = target.sleepCapacity or target.bedCapacity
    order.bedCapacity = target.bedCapacity or target.sleepCapacity
    order.seatDirection, order.seatSide = target.seatDirection,
        target.seatSide
    if target.approachKey ~= nil then order.approachKey = target.approachKey end
    if target.validSpot ~= nil then order.validSpot = target.validSpot end
    order.validationState = target.validationState
    order.rejectionReason = target.rejectionReason
    order.routeStatus = target.routeStatus
    if target.stopDistance ~= nil then order.stopDistance = target.stopDistance end
    if target.arrivalDistance ~= nil then
        order.arrivalDistance = target.arrivalDistance
    end
    order.sceneId, order.sleepSurface = target.sceneId or "",
        target.sleepSurface or ""
    if target.resourceKind ~= nil then
        order.resourceKind = tostring(target.resourceKind)
    end
    if target.seating ~= nil then order.seating = target.seating == true end
    order.floorSeating = target.floorSeating == true
        or tostring(target.resourceKind or "") == "floor_seating"
    activity.target = { x = target.x, y = target.y, z = target.z }
    activity.seatAnchor = target.seatAnchorX and {
        x = tonumber(target.seatAnchorX),
        y = tonumber(target.seatAnchorY),
        z = tonumber(target.seatAnchorZ or target.z),
    } or nil
    activity.sceneId, activity.sleepSurface = order.sceneId, order.sleepSurface
    activity.sleepSlotId = order.sleepSlotId
    activity.sleepSlotIndex = order.sleepSlotIndex
    activity.sleepCapacity = order.sleepCapacity
    activity.bedCapacity = order.bedCapacity
    if target.resourceKind ~= nil then
        activity.resourceKind = tostring(target.resourceKind)
    end
    if target.seating ~= nil then activity.seating = target.seating == true end
    activity.floorSeating = target.floorSeating == true
        or tostring(target.resourceKind or "") == "floor_seating"
    if tostring(activity.capability or "") == "sleep" then
        PNC.SleepRuntime = PNC.SleepRuntime or {}
        PNC.SleepRuntime.LiveObjects = PNC.SleepRuntime.LiveObjects or {}
        PNC.SleepRuntime.LiveObjects[tostring(record.id)] = target.object
    end
    activity.seatDirection, activity.seatSide = order.seatDirection,
        order.seatSide
    activity.approachKey = order.approachKey or activity.approachKey
    activity.validSpot = order.validSpot ~= false
    activity.seatValidation = tostring(order.validationState or "")
    activity.seatRejectionReason = tostring(order.rejectionReason or "")
    activity.seatRouteStatus = tostring(order.routeStatus or "UNTESTED")
    if order.stopDistance ~= nil then
        activity.seatStopDistance = tonumber(order.stopDistance)
    end
    if order.arrivalDistance ~= nil then
        activity.seatArrivalDistance = tonumber(order.arrivalDistance)
    end
    return true
end

function Service.AcquireSleep(record, options)
    options = type(options) == "table" and options or {}
    local order = campOrder(record)
    if not order then return nil, "NOT_CAMPED" end
    local resource, target, targets, reason = Service.FindSleep(record, options)
    if not resource then return nil, reason or "CAMP_SLEEP_UNAVAILABLE" end
    local campId = tostring(order.campId or "camp:" .. tostring(record.id))
    local ok, reservation = Internal.Reserve(record, resource, campId, target)
    if not ok then return nil, reservation or "CAMP_SLEEP_RESERVATION_FAILED" end
    return {
        ok = true, facilityId = Internal.CampFacilityId(campId), componentId = "",
        reservationId = reservation.id, role = resource.role,
        resource = resource, resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind, target = target,
        sleepSlotId = target and target.sleepSlotId,
        sleepSlotIndex = target and target.sleepSlotIndex,
        sleepCapacity = target and target.sleepCapacity
            or resource.sleepCapacity,
        approachCandidates = targets, campId = campId, campActivity = true,
        sleepVariant = "CAMP_NEARBY",
        sleepTargetPolicy = resource.sleepSurface == "sofa"
            and "CAMP_NEARBY_SOFA"
            or resource.resourceKind == "sleep_surface"
                and "CAMP_NEARBY_BED" or "CAMP_FLOOR_FALLBACK",
        campX = order.x, campY = order.y, campZ = order.z,
        campRadius = number(order.radius, Const.CAMP_RADIUS or 3),
        resourceRadius = number(order.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
        executionMode = options.abstract == true and "ABSTRACT" or "LIVE",
    }
end

function Service.AcquireSeat(record, options)
    options = type(options) == "table" and options or {}
    local order = campOrder(record)
    if not order then return nil, "NOT_CAMPED" end
    local resource, target, targets, reason = Service.FindSeat(record, options)
    if not resource then return nil, reason or "CAMP_SEAT_UNAVAILABLE" end
    local campId = tostring(order.campId or "camp:" .. tostring(record.id))
    local ok, reservation = Internal.ReserveSeat(record, resource, campId)
    if not ok then return nil, reservation or "CAMP_SEAT_RESERVATION_FAILED" end
    return {
        ok = true, facilityId = Internal.CampFacilityId(campId), componentId = "",
        reservationId = reservation.id, role = resource.role,
        resource = resource, resourceKey = resource.resourceKey,
        resourceKind = resource.resourceKind, target = target,
        approachCandidates = targets, campId = campId, campActivity = true,
        campX = order.x, campY = order.y, campZ = order.z,
        campRadius = number(order.radius, Const.CAMP_RADIUS or 3),
        resourceRadius = number(order.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
        seating = true,
        floorSeating = resource.floorSeating == true
            or target and target.floorSeating == true,
        executionMode = options.abstract == true and "ABSTRACT" or "LIVE",
    }
end

function Service.AcquireWater(record, options)
    options = type(options) == "table" and options or {}
    local order = campOrder(record)
    if not order then return nil, "NOT_CAMPED" end
    local resource, target, targets, source, reason = Service.FindWater(
        record, options)
    if not resource then return nil, reason or "CAMP_WATER_UNAVAILABLE" end
    local campId = tostring(order.campId or "camp:" .. tostring(record.id))
    local ok, reservation = Internal.ReserveWater(record, resource, campId)
    if not ok then return nil, reservation or "CAMP_WATER_RESERVATION_FAILED" end
    return {
        ok = true, facilityId = Internal.CampFacilityId(campId), componentId = "",
        reservationId = reservation.id,
        role = resource.role or "survival.world_water",
        resource = resource, resourceKey = resource.resourceKey,
        resourceKind = "world_water", target = target,
        approachCandidates = targets, campId = campId, campActivity = true,
        campX = order.x, campY = order.y, campZ = order.z,
        campRadius = number(order.radius, Const.CAMP_RADIUS or 3),
        resourceRadius = number(order.resourceRadius,
            Const.CAMP_RESOURCE_RADIUS or 12),
        waterSource = source,
        executionMode = options.abstract == true and "ABSTRACT" or "LIVE",
    }
end

Internal.ApplyTarget = applyTarget

return Service
