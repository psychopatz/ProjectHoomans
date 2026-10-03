-- Compact camp resource diagnostics shared by snapshot surfaces.
local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Internal = Parts.Internal
local copyCampPoint = Internal.copyCampPoint
local cachedCampState = Internal.cachedCampState
local cachedCampDebugBase = Internal.cachedCampDebugBase
local copyCampResourceView = Internal.copyCampResourceView
local PNC = PNC

function Parts.BuildCampResourceDebugState(record)
    local order = record and record.orderSpec or nil
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local state = cachedCampState(record)
    local orderIsCamp = tostring(order and order.kind or "") == "camp"
    local activityIsCamp = activity and activity.campActivity == true or false
    local resources = state and state.resources or {}
    local campId
    local anchorX
    local anchorY
    local anchorZ
    local campRadius
    local resourceRadius
    local facilities = {}
    local activeResource
    local static
    if type(resources) ~= "table" then resources = {} end
    if not orderIsCamp and not activityIsCamp and type(state) ~= "table" then
        return nil
    end

    campId = tostring(state and state.campId
        or activity and activity.campId
        or order and order.campId
        or "")
    anchorX = tonumber(state and state.anchorX
        or activity and activity.campX
        or order and order.x
        or record and record.x or 0)
    anchorY = tonumber(state and state.anchorY
        or activity and activity.campY
        or order and order.y
        or record and record.y or 0)
    anchorZ = tonumber(state and state.anchorZ
        or activity and activity.campZ
        or order and order.z
        or record and record.z or 0)
    campRadius = tonumber(state and state.campRadius
        or activity and activity.campRadius
        or order and order.radius or 3)
    resourceRadius = tonumber(state and state.resourceRadius
        or activity and activity.resourceRadius
        or order and order.resourceRadius or 12)

    static = cachedCampDebugBase(state)
    if static then
        for index = 1, #static.facilities do
            local base = static.facilities[index]
            local resourceKey = tostring(base.resourceKey or "")
            local selected = activity
                and tostring(activity.resourceKey or "") ~= ""
                and tostring(activity.resourceKey) == resourceKey
            local reserved = PNC.FacilityReservations
                and PNC.FacilityReservations.ByResource
                and PNC.FacilityReservations.ByResource[resourceKey]
                ~= nil
            facilities[#facilities + 1] = copyCampResourceView(
                base, selected == true,
                base.available and (not reserved or selected == true)
            )
        end
        if activity and tostring(activity.resourceKey or "") ~= "" then
            activeResource = static.byKey[
                tostring(activity.resourceKey or "")]
            activeResource = copyCampResourceView(
                activeResource,
                activeResource and activeResource.selected or false,
                activeResource and activeResource.available or nil
            )
        end
    end

    return {
        active = orderIsCamp or activityIsCamp,
        mode = activityIsCamp and "activity" or "camp",
        campId = campId,
        anchor = { x = anchorX, y = anchorY, z = anchorZ },
        campRadius = campRadius,
        resourceRadius = resourceRadius,
        capturedAtWorldHour = tonumber(state and state.capturedAtWorldHour),
        resourceCount = static and static.resourceCount or #resources,
        bedCount = static and static.bedCount or 0,
        waterCount = static and static.waterCount or 0,
        seatingCount = static and static.seatingCount or 0,
        otherCount = static and static.otherCount or 0,
        facilities = facilities,
        facilitiesTruncated = #resources > #facilities,
            activeResource = activeResource,
            activity = activityIsCamp and {
            capability = tostring(activity.capability or ""),
            phase = tostring(activity.phase or ""),
            resourceKind = tostring(activity.resourceKind or ""),
            resourceKey = tostring(activity.resourceKey or ""),
            sleepSurface = tostring(activity.sleepSurface or ""),
            abstract = activity.abstract == true,
                target = copyCampPoint(activity.target),
            } or nil,
    }
end


return Parts
