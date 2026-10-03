if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Const = PNC.Const or {}
local applyTarget = Internal.ApplyTarget

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
