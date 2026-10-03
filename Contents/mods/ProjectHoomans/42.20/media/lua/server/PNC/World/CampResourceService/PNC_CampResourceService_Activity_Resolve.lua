if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CampResourceService = PNC.CampResourceService or {}

local Service = PNC.CampResourceService
local Internal = Service.Internal or {}
Service.Internal = Internal
local Resources = PNC.FacilityResources
local campContext = Internal.CampContext
local targetWithinCamp = Internal.TargetWithinCamp

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

return Service
