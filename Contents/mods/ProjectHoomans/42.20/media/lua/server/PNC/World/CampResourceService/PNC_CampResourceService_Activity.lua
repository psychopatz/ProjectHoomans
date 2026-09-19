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

function Service.ResolveActivityTarget(record)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or record and record.orderSpec or nil
    if not activity or activity.campActivity ~= true
        or tostring(activity.facilityId or ""):sub(1, 5) ~= "camp:"
    then return nil end
    local key = tostring(activity.resourceKey or "")
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local abstract = live == nil
    local snapshot = Service.GetSnapshot(record, false)
    for index = 1, #(snapshot and snapshot.resources or {}) do
        local resource = snapshot.resources[index]
        if tostring(resource.resourceKey or "") == key then
            local target
            local resolvedResource
            if tostring(activity.capability or "") == "living" then
                if activity.floorSeating == true
                    or tostring(activity.resourceKind or "")
                        == "floor_seating"
                then
                    target = Internal.FloorSeatTarget(Internal.FloorSeatSlot(
                        record, campContext(record) or {}))
                else
                    target = Internal.ResolveSeat(
                        resource, abstract, live, activity.approachKey)
                end
            elseif tostring(activity.capability or "")
                    == "survival.drink.world"
                or tostring(activity.resourceKind or "") == "world_water"
            then
                target, _, resolvedResource = Internal.ResolveWaterTarget(
                    record, resource, abstract)
            else
                target = Internal.ResolveSleep(resource, abstract, live, nil,
                    activity.reservationId)
            end
            if target and targetWithinCamp(record, target) then
                target.campResource = true
                return target, resolvedResource or resource
            end
        end
    end
    if tostring(activity.capability or "") == "living" then
        if activity.floorSeating == true
            or tostring(activity.resourceKind or "") == "floor_seating"
        then
            local floor = Internal.FloorSeatSlot(record, campContext(record) or {})
            local target = Internal.FloorSeatTarget(floor)
            target.resourceKey = key
            target.resourceKind = activity.resourceKind or floor.resourceKind
            target.sceneId = activity.sceneId ~= ""
                and activity.sceneId or target.sceneId
            if targetWithinCamp(record, target) then
                target.campResource = true
                return target, floor
            end
        end
        local _, target = Service.FindSeat(record, {
            abstract = abstract, force = true, excludeKey = key,
        })
        if target then target.campResource = true end
        return target
    end
    if tostring(activity.capability or "") == "survival.drink.world"
        or tostring(activity.resourceKind or "") == "world_water"
    then
        local _, target, _, source = Service.FindWater(record, {
            abstract = abstract, force = true, excludeKey = key,
        })
        if target then target.campResource = true end
        return target, source
    end
    if tostring(activity.resourceKind or "") == "floor_sleep"
        or tostring(activity.sleepSurface or "") == "floor"
    then
        local target = activity.target or {
            x = activity.x, y = activity.y, z = activity.z,
        }
        if not Resources or not Resources.IsValidSleepTarget
            or not Resources.IsValidSleepTarget({
                resourceKind = "floor_sleep", sleepSurface = "floor",
            }, {
                sceneId = target.sceneId,
                sleepSurface = target.sleepSurface,
                seating = target.seating,
            })
        then
            target = nil
        end
        if not target then
            local floor = Internal.FloorSlot(record, campContext(record) or {})
            target = {
                x = floor.x, y = floor.y, z = floor.z,
                sceneId = floor.sceneId, sleepSurface = floor.sleepSurface,
            }
        end
        target.resourceKey = target.resourceKey or key
        target.resourceKind = target.resourceKind or activity.resourceKind
        target.sleepSurface = target.sleepSurface or activity.sleepSurface
        target.campResource = true
        return target
    end
    local _, target = Service.FindSleep(record, {
        abstract = false, force = true, excludeKey = key,
    })
    if target then target.campResource = true end
    return target
end

function Service.ApplyMaterializationTarget(record, zombie, target)
    if Resources and Resources.ApplyMaterializationTarget then
        return Resources.ApplyMaterializationTarget(record, zombie, target)
    end
    return false
end

function Service.RefreshActivity(record, zombie)
    local runtime = record and record.runtime
        and record.runtime.facilityActivity or nil
    if not runtime or runtime.campActivity ~= true
        or (tostring(runtime.capability or "") ~= "sleep"
            and tostring(runtime.capability or "") ~= "living"
            and tostring(runtime.capability or "")
                ~= "survival.drink.world")
    then return true end
    local target, liveResource = Service.ResolveActivityTarget(record)
    if target
        and (tostring(runtime.capability or "") == "living"
            or tostring(runtime.capability or "") == "survival.drink.world"
            or tostring(target.sleepSurface or "")
                == tostring(runtime.sleepSurface or ""))
        and (target.resourceKey == nil
            or tostring(runtime.resourceKey or "")
                == tostring(target.resourceKey or ""))
    then
        applyTarget(record, target)
        if liveResource then runtime.resource = liveResource end
        return true
    end
    local oldKey = tostring(runtime.resourceKey or "")
    local live = zombie or PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local abstract = live == nil
    local resource, replacement, targets, replacementSource
    local isLiving = tostring(runtime.capability or "") == "living"
    local isWater = tostring(runtime.capability or "")
        == "survival.drink.world"
    if isLiving then
        resource, replacement, targets = Service.FindSeat(record, {
            abstract = abstract, force = true, excludeKey = oldKey,
        })
    elseif isWater then
        resource, replacement, targets, replacementSource =
            Service.FindWater(record, {
            abstract = abstract, force = true, excludeKey = oldKey,
            })
    else
        resource, replacement, targets = Service.FindSleep(record, {
            abstract = abstract, force = true, excludeKey = oldKey,
        })
    end
    if not resource or not replacement then
        return false, isLiving and "CAMP_SEAT_TARGET_UNAVAILABLE"
            or isWater and "CAMP_WATER_TARGET_UNAVAILABLE"
            or "CAMP_SLEEP_TARGET_UNAVAILABLE"
    end
    local order = record.orderSpec or {}
    local campId = tostring(runtime.campId or order.campId or record.id)
    local reserveFunction = isLiving and Internal.ReserveSeat
        or isWater and Internal.ReserveWater or Internal.Reserve
    local ok, reservation = reserveFunction(record, resource, campId)
    if not ok then
        return false, reservation or (isLiving
            and "CAMP_SEAT_RESERVATION_FAILED"
            or isWater and "CAMP_WATER_RESERVATION_FAILED"
            or "CAMP_SLEEP_RESERVATION_FAILED")
    end
    if PNC.FacilityReservations and runtime.reservationId
        and PNC.FacilityReservations.Release
    then
        PNC.FacilityReservations.Release(runtime.reservationId,
            "camp_resource_replaced")
    end
    runtime.reservationId = reservation.id
    runtime.resource = replacementSource or resource
    runtime.resourceKey = tostring(resource.resourceKey or "")
    runtime.resourceKind = isWater and "world_water"
        or tostring(resource.resourceKind or "")
    if isLiving then
        runtime.floorSeating = resource.floorSeating == true
            or replacement.floorSeating == true
            or tostring(resource.resourceKind or "") == "floor_seating"
    end
    runtime.approachCandidates = targets
    runtime.approachIndex = 1
    order.reservationId = reservation.id
    order.resourceKey = runtime.resourceKey
    order.resourceKind = runtime.resourceKind
    applyTarget(record, replacement)
    local lease = runtime.taskLeaseId ~= "" and PNC.TaskLeaseService
        and PNC.TaskLeaseService.Get
        and PNC.TaskLeaseService.Get(runtime.taskLeaseId) or nil
    if lease then
        lease.reservationId = reservation.id
        lease.resourceKey = runtime.resourceKey
        lease.resourceKind = runtime.resourceKind
    end
    Internal.MarkDirty(record, "camp_activity_resource_refreshed")
    return true
end

function Service.OnOrderChanged(record, previous, current)
    local campKind = tostring(Const.ORDER_CAMP or "camp")
    local activityKind = "facility_activity"
    local previousKind = tostring(previous and previous.kind or "")
    local currentKind = tostring(current and current.kind or "")
    local currentIsCampActivity = currentKind == activityKind
        and current and current.campActivity == true
    if currentKind == campKind then
        if previousKind ~= campKind then
            Internal.DetachRecord(record)
        end
        Service.Attach(record, current)
    elseif currentIsCampActivity then
        -- Need activities replace the durable camp order temporarily. Keep the
        -- shared cache attached until the activity restores or ends.
        Service.Attach(record, current)
    elseif currentKind ~= activityKind then
        Internal.DetachRecord(record)
        Internal.MarkDirty(record, "camp_ended")
    end
end

Internal.ApplyTarget = applyTarget

return Service
