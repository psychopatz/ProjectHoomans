-- Bounded seating diagnostics for camp and home activity.
local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Internal = Parts.Internal
local copyCampPoint = Internal.copyCampPoint
local cachedCampState = Internal.cachedCampState
local copySeatingResource = Internal.copySeatingResource
local SEATING_DEBUG_MAX = Internal.SEATING_DEBUG_MAX
local PNC = PNC

function Parts.BuildSeatingDebugState(record)
    local order = record and record.orderSpec or nil
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local orderKind = tostring(order and order.kind or "")
    local previousOrder = activity and activity.previousOrder or nil
    local camped = orderKind == tostring(PNC.Const and PNC.Const.ORDER_CAMP
        or "camp") or activity and activity.campActivity == true
    local atHome = orderKind == "colony_home"
        or tostring(previousOrder and previousOrder.kind or "")
            == "colony_home"
    local selectedKey = activity and activity.seating == true
        and activity.resourceKey or nil
    local selectedTarget = activity and activity.seating == true
        and activity.target or nil
    local character = record and PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local facilities = {}
    local sourceCount = 0
    local bodyPosition
    local seatAnchor
    local seatDistance

    if character and character.getX and character.getY and character.getZ then
        local bodyX, bodyY, bodyZ = character:getX(), character:getY(),
            character:getZ()
        bodyPosition = { x = tonumber(bodyX), y = tonumber(bodyY),
            z = tonumber(bodyZ) }
    end
    if activity and activity.seating == true then
        seatAnchor = copyCampPoint(activity.seatAnchor or activity.target)
        if bodyPosition and seatAnchor then
            seatDistance = PNC.Core.Distance(
                bodyPosition.x, bodyPosition.y,
                seatAnchor.x, seatAnchor.y)
        end
    end

    local function add(resource, facilityId)
        if type(resource) ~= "table"
            or tostring(resource.resourceKind or "")
                ~= "seating_surface"
        then return end
        sourceCount = sourceCount + 1
        if #facilities >= SEATING_DEBUG_MAX then return end
        local copied = copySeatingResource(
            resource, character, selectedKey, selectedTarget)
        if copied then
            copied.facilityId = facilityId or copied.facilityId
            facilities[#facilities + 1] = copied
        end
    end

    if camped then
        local state = cachedCampState(record)
        for index = 1, #(state and state.resources or {}) do
            add(state.resources[index], tostring(
                state and state.campId or activity and activity.campId or ""))
        end
    elseif atHome and PNC.HomeDutyService
        and PNC.HomeDutyService.GetBase and PNC.FacilityService
        and PNC.FacilityService.ListByCapability
    then
        local base = PNC.HomeDutyService.GetBase(record)
        local homes = base and PNC.FacilityService.ListByCapability(
            base.id, "living") or {}
        for facilityIndex = 1, #homes do
            local facility = homes[facilityIndex]
            local resources = PNC.FacilityResources
                and PNC.FacilityResources.GetResources
                and PNC.FacilityResources.GetResources(facility, "seat") or {}
            for resourceIndex = 1, #resources do
                add(resources[resourceIndex], facility.id)
            end
        end
    end

    if activity and activity.seating == true and activity.resource
        and sourceCount == 0
    then
        add(activity.resource, activity.facilityId)
    end
    if sourceCount == 0 and not camped and not atHome then return nil end
    return {
        active = activity and activity.seating == true or false,
        mode = camped and "camp" or atHome and "home" or "none",
        facilityCount = #facilities,
        foundCount = sourceCount,
        selectedResourceKey = selectedKey,
        phase = activity and activity.seating == true
            and tostring(activity.phase or "") or "IDLE",
        target = activity and activity.seating == true
            and copyCampPoint(activity.target) or nil,
        anchor = seatAnchor,
        body = bodyPosition,
        distance = seatDistance,
        seatState = activity and activity.seating == true
            and tostring(activity.seatState or activity.phase or "") or nil,
        seatDirection = activity and activity.seating == true
            and tostring(activity.seatDirection or "") or nil,
        seatSide = activity and activity.seating == true
            and tostring(activity.seatSide or "") or nil,
        approachKey = activity and activity.seating == true
            and tostring(activity.approachKey or "") or nil,
        stopDistance = activity and activity.seating == true
            and tonumber(activity.seatStopDistance) or nil,
        arrivalDistance = activity and activity.seating == true
            and tonumber(activity.seatArrivalDistance) or nil,
        facilities = facilities,
        facilitiesTruncated = sourceCount > #facilities,
    }
end

-- Compact, primitive-only camp diagnostics shared by detailed and presence
-- snapshots. The full camp resource state remains a bounded server runtime
-- cache; nameplates only receive bounded information needed to explain what
-- the NPC found.

return Parts
