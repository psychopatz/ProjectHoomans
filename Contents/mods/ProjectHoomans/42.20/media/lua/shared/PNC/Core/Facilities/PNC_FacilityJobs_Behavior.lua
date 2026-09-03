-- Runtime behavior for data-defined facility activities. Server services
-- acquire targets/reservations; this module owns travel, scenes, effects, and
-- interruption-safe body placement.

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}

local Jobs = PNC.FacilityJobs
local Definitions = PNC.FacilityJobDefinitions
local KIND = "facility_activity"
local JOB = "FacilityActivity"
local SEAT_STOP_DISTANCE = 0.10
local SEAT_ARRIVAL_TOLERANCE = 0.14
local MAX_SCENE_START_ATTEMPTS = 3

PNC.SeatingRuntime = PNC.SeatingRuntime or {}
PNC.SeatingRuntime.LiveObjects = PNC.SeatingRuntime.LiveObjects or {}
local applySeatFacing

local function normalize(_, spec)
    return {
        kind = KIND,
        capability = tostring(spec.capability or ""),
        facilityId = tostring(spec.facilityId or ""),
        facilityName = tostring(spec.facilityName or spec.facilityId or "Facility"),
        componentId = tostring(spec.componentId or ""),
        componentRole = tostring(spec.componentRole or ""),
        reservationId = tostring(spec.reservationId or ""),
        x = tonumber(spec.x) or 0,
        y = tonumber(spec.y) or 0,
        z = tonumber(spec.z) or 0,
        interactionX = tonumber(spec.interactionX),
        interactionY = tonumber(spec.interactionY),
        interactionZ = tonumber(spec.interactionZ),
        interactionSurfaceOffset = tonumber(spec.interactionSurfaceOffset),
        interactionAxis = tostring(spec.interactionAxis or ""),
        interactionFacing = tostring(spec.interactionFacing or ""),
        seatDirection = tostring(spec.seatDirection or ""),
        seatSide = tostring(spec.seatSide or ""),
        approachKey = tostring(spec.approachKey or ""),
        validSpot = spec.validSpot ~= false,
        seatAnchorX = tonumber(spec.seatAnchorX),
        seatAnchorY = tonumber(spec.seatAnchorY),
        seatAnchorZ = tonumber(spec.seatAnchorZ),
        validationState = tostring(spec.validationState or ""),
        rejectionReason = tostring(spec.rejectionReason or ""),
        routeStatus = tostring(spec.routeStatus or "UNTESTED"),
        stopDistance = tonumber(spec.stopDistance),
        arrivalDistance = tonumber(spec.arrivalDistance),
        seating = spec.seating == true,
        sceneId = tostring(spec.sceneId or ""),
        sleepSurface = tostring(spec.sleepSurface or ""),
        taskLeaseId = tostring(spec.taskLeaseId or ""),
        resourceKind = tostring(spec.resourceKind or ""),
        resourceKey = tostring(spec.resourceKey or ""),
        campActivity = spec.campActivity == true,
        campId = tostring(spec.campId or ""),
        campX = tonumber(spec.campX),
        campY = tonumber(spec.campY),
        campZ = tonumber(spec.campZ),
        campRadius = tonumber(spec.campRadius),
        resourceRadius = tonumber(spec.resourceRadius),
        activityItemFullType = tostring(spec.activityItemFullType or ""),
        debugHold = spec.debugHold == true,
    }
end

local function state(record)
    return record and record.runtime and record.runtime.facilityActivity or nil
end

local function currentTime(runtime)
    if PNC.Core and PNC.Core.Now then return PNC.Core.Now() end
    return tonumber(runtime and runtime.lastProgressAt) or 1
end

local function liveSeatObject(record, runtime)
    local objects = PNC.SeatingRuntime and PNC.SeatingRuntime.LiveObjects
    local object = objects and objects[tostring(record and record.id or "")]
    if object then return object end
    if runtime and runtime.resource and PNC.FacilityResources
        and PNC.FacilityResources.ResolveLiveObject
    then
        object = PNC.FacilityResources.ResolveLiveObject(runtime.resource)
        if object and objects and record and record.id then
            objects[tostring(record.id)] = object
        end
    end
    return object
end

local function clearFurnitureSeat(record, zombie, runtime)
    if not runtime or runtime.seating ~= true then return end
    local object = liveSeatObject(record, runtime)
    if object and object.setSatChair then
        object:setSatChair(false)
    end
    if zombie then
        if zombie.setIsResting then zombie:setIsResting(false) end
        if zombie.setOnFloor then zombie:setOnFloor(false) end
        if zombie.setSitAgainstWall then zombie:setSitAgainstWall(false) end
        if zombie.setSitOnGround then zombie:setSitOnGround(false) end
        if zombie.setSittingOnFurniture then
            zombie:setSittingOnFurniture(false)
        end
        if zombie.setSitOnFurnitureObject then
            zombie:setSitOnFurnitureObject(nil)
        end
        if zombie.setSitOnFurnitureDirection then
            zombie:setSitOnFurnitureDirection(nil)
        end
        if zombie.clearVariable then
            zombie:clearVariable("PNCSeated")
            zombie:clearVariable("SitOnFurnitureDirection")
            zombie:clearVariable("SitOnFurnitureStarted")
            zombie:clearVariable("SitOnFurnitureAnim")
        end
    end
    runtime.seatEntered = false
    runtime.seatState = "STANDING"
end

local function enterFurnitureSeat(record, zombie, runtime, order)
    if not runtime or runtime.seating ~= true then return true end
    if not zombie then
        -- Abstract execution records the chosen spot/resource; no Java body
        -- state exists until materialization.
        runtime.seatEntered = true
        runtime.phase = "SITTING"
        return true
    end
    if runtime.seatEntered == true then return true end
    local object = liveSeatObject(record, runtime)
    if not object then return false, "SEAT_OBJECT_UNAVAILABLE" end
    if object.isFurnitureOccupied then
        if object:isFurnitureOccupied(zombie) == true then
            return false, "SEAT_OCCUPIED"
        end
    end
    local directionName = tostring(runtime.seatDirection or "")
    local side = tostring(runtime.seatSide or "")
    if directionName == "" then directionName = tostring(order.seatDirection or "") end
    if side == "" then side = tostring(order.seatSide or "") end
    if directionName == "" then directionName = "S" end
    if side == "" then side = "Front" end
    if runtime.validSpot == false then return false, "SEAT_SPOT_INVALID" end
    local direction = IsoDirections and IsoDirections[directionName] or nil
    if not direction and IsoDirections and IsoDirections.fromString then
        direction = IsoDirections.fromString(directionName)
    end
    if object.setSatChair then object:setSatChair(true) end
    if zombie.setOnFloor then zombie:setOnFloor(false) end
    if zombie.setSitAgainstWall then zombie:setSitAgainstWall(false) end
    if zombie.setSitOnGround then zombie:setSitOnGround(false) end
    if zombie.setSitOnFurnitureObject then
        zombie:setSitOnFurnitureObject(object)
    end
    if direction and zombie.setSitOnFurnitureDirection then
        zombie:setSitOnFurnitureDirection(direction)
    end
    if zombie.setVariable then
        zombie:setVariable("SitOnFurnitureDirection", side)
        zombie:setVariable("PNCSeated", true)
        if zombie.clearVariable then
            zombie:clearVariable("SitOnFurnitureAnim")
            zombie:clearVariable("SitOnFurnitureStarted")
        end
    end
    if zombie.setSittingOnFurniture then
        zombie:setSittingOnFurniture(true)
    end
    if not applySeatFacing(zombie, direction, side) then
        return false, "SEAT_FACING_UNAVAILABLE"
    end
    if zombie.reportEvent then zombie:reportEvent("EventSitOnFurniture") end
    if zombie.setIsResting then zombie:setIsResting(true) end
    runtime.seatEntered = true
    runtime.seatState = "SEATED"
    runtime.phase = "SEATED"
    return true
end

local function hasLiveTaskLease(leaseId)
    leaseId = tostring(leaseId or "")
    if leaseId == "" then return false end
    local leases = PNC.TaskLeaseService
    if not leases or type(leases.Get) ~= "function" then
        -- This module is shared. Clients do not own the server lease table,
        -- so an opaque client-side ID is not evidence of an orphan.
        return true
    end
    return leases.Get(leaseId) ~= nil
end

local function restorePosition(record, zombie, runtime)
    if not runtime or runtime.positioned ~= true then return end
    local position = runtime.approachPosition
    if zombie and position and PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        PNC.LiveBodyControl.SetAuthoritativePosition(
            zombie, position.x, position.y, position.z)
        record.x, record.y, record.z = position.x, position.y, position.z
    end
    runtime.positioned = false
end

local function resetPath(record, zombie, reason)
    if not PNC.PathService or not PNC.PathService.Reset then return end
    if PNC.PathService.Commands and PNC.PathService.Commands.Reset then
        PNC.PathService.Commands.Reset(record, zombie, reason)
    else
        PNC.PathService.Reset(zombie, record)
    end
end

local function bodyDistance(zombie, x, y)
    if zombie and zombie.getX and zombie.getY then
        return PNC.Core.Distance(zombie:getX(), zombie:getY(), x, y)
    end
    return nil
end

local function seatSpotUsable(spot, failedApproaches, index)
    if type(spot) ~= "table"
        or spot.valid == false or spot.validSpot == false
        or spot.approachValid == false
    then
        return false
    end
    local key = tostring(spot.approachKey or "")
    if key ~= "" and failedApproaches and failedApproaches[key] then
        return false
    end
    return not (key == "" and failedApproaches
        and failedApproaches["index:" .. tostring(index)])
end

local function chooseSeatSpot(spots, wantedKey, zombie, failedApproaches)
    local nearest
    local nearestDistance
    for index = 1, #(spots or {}) do
        local spot = spots[index]
        if seatSpotUsable(spot, failedApproaches, index)
            and tostring(spot.approachKey or "") == tostring(wantedKey or "")
        then
            return spot
        end
        if seatSpotUsable(spot, failedApproaches, index)
            and zombie and zombie.getX
            and zombie.getY and tonumber(spot.x) and tonumber(spot.y)
        then
            local dx = zombie:getX() - spot.x
            local dy = zombie:getY() - spot.y
            local distance = (dx * dx) + (dy * dy)
            if not nearestDistance or distance < nearestDistance then
                nearest, nearestDistance = spot, distance
            end
        end
    end
    return nearest
end

-- SeatingManager is evaluated again at the live movement boundary. Abstract
-- camp state keeps the approachKey, but the exact point is always refreshed
-- against the current character/object pair before a chair pose is entered.
local function refreshLiveSeatTarget(record, zombie, runtime, order)
    local resources = PNC.FacilityResources
    local object
    local spots
    local wantedKey
    local spot
    local changed
    local failedApproaches
    local firstRejection
    if not runtime or runtime.seating ~= true or not zombie then
        return true, nil, false
    end
    if not resources or not resources.BuildSeatSpots then
        return true, nil, false
    end
    object = liveSeatObject(record, runtime)
    if not object then return false, "SEAT_OBJECT_UNAVAILABLE", false end
    spots = resources.BuildSeatSpots(zombie, object)
    if type(spots) ~= "table" or #spots == 0 then
        return false, "SEAT_SPOT_UNAVAILABLE", false
    end
    wantedKey = tostring(runtime.approachKey or "")
    if wantedKey == "" then wantedKey = tostring(order.approachKey or "") end
    failedApproaches = runtime.failedApproaches or {}
    for index = 1, #spots do
        local candidate = spots[index]
        if type(candidate) == "table" and candidate.rejectionReason
            and not firstRejection
        then
            firstRejection = tostring(candidate.rejectionReason)
        end
    end
    spot = chooseSeatSpot(spots, wantedKey, zombie, failedApproaches)
    if not spot or not tonumber(spot.x) or not tonumber(spot.y)
        or not tonumber(spot.z)
    then
        runtime.seatRejectionReason = firstRejection or "no_valid_approach"
        return false, "SEAT_APPROACH_UNAVAILABLE", false
    end
    changed = math.abs((tonumber(order.x) or 0) - spot.x) > 0.02
        or math.abs((tonumber(order.y) or 0) - spot.y) > 0.02
        or math.abs((tonumber(order.z) or 0) - spot.z) > 0.02
        or tostring(runtime.approachKey or "")
            ~= tostring(spot.approachKey or "")
        or math.abs((tonumber(order.seatAnchorX) or spot.x)
            - (tonumber(spot.seatAnchorX) or spot.x)) > 0.02
        or math.abs((tonumber(order.seatAnchorY) or spot.y)
            - (tonumber(spot.seatAnchorY) or spot.y)) > 0.02
        or math.abs((tonumber(order.seatAnchorZ) or spot.z)
            - (tonumber(spot.seatAnchorZ) or spot.z)) > 0.02
    order.x, order.y, order.z = spot.x, spot.y, spot.z
    order.approachKey = spot.approachKey
    order.seatDirection = spot.direction
    order.seatSide = spot.side
    order.validSpot = spot.valid ~= false and spot.approachValid ~= false
    order.seatAnchorX = tonumber(spot.seatAnchorX or spot.x)
    order.seatAnchorY = tonumber(spot.seatAnchorY or spot.y)
    order.seatAnchorZ = tonumber(spot.seatAnchorZ or spot.z)
    order.validationState = spot.validationState or "VALID"
    order.rejectionReason = spot.rejectionReason
    order.routeStatus = spot.routeStatus or "UNTESTED"
    order.stopDistance = SEAT_STOP_DISTANCE
    order.arrivalDistance = SEAT_ARRIVAL_TOLERANCE
    runtime.target = { x = spot.x, y = spot.y, z = spot.z }
    runtime.seatDirection = tostring(spot.direction or "")
    runtime.seatSide = tostring(spot.side or "")
    runtime.approachKey = tostring(spot.approachKey or "")
    runtime.validSpot = order.validSpot
    runtime.seatValidation = tostring(order.validationState or "")
    runtime.seatRejectionReason = tostring(order.rejectionReason or "")
    runtime.seatRouteStatus = tostring(order.routeStatus or "UNTESTED")
    runtime.seatStopDistance = SEAT_STOP_DISTANCE
    runtime.seatArrivalDistance = SEAT_ARRIVAL_TOLERANCE
    runtime.seatAnchor = {
        x = order.seatAnchorX, y = order.seatAnchorY, z = order.seatAnchorZ,
    }
    runtime.resource = runtime.resource or {}
    runtime.resource.seatSpots = spots
    runtime.approachCandidates = {}
    runtime.approachIndex = 1
    for index = 1, #spots do
        local candidate = spots[index]
        if type(candidate) == "table" then
            local copied = {
                x = tonumber(candidate.x), y = tonumber(candidate.y),
                z = tonumber(candidate.z),
                seatAnchorX = tonumber(candidate.seatAnchorX or candidate.x),
                seatAnchorY = tonumber(candidate.seatAnchorY or candidate.y),
                seatAnchorZ = tonumber(candidate.seatAnchorZ or candidate.z),
                seatDirection = candidate.direction,
                seatSide = candidate.side,
                approachKey = candidate.approachKey,
                validSpot = candidate.valid,
                approachValid = candidate.approachValid,
                validationState = candidate.validationState,
                rejectionReason = candidate.rejectionReason,
                routeStatus = candidate.routeStatus,
            }
            runtime.approachCandidates[#runtime.approachCandidates + 1] = copied
            if tostring(candidate.approachKey or "")
                == tostring(spot.approachKey or "")
            then
                runtime.approachIndex = #runtime.approachCandidates
            end
        end
    end
    return true, nil, changed
end

applySeatFacing = function(zombie, direction, side)
    local before = direction
    if not direction then return false end
    if side == "Left" and direction.RotRight then
        before = direction:RotRight(2)
    elseif side == "Right" and direction.RotLeft then
        before = direction:RotLeft(2)
    end
    if zombie.setForwardIsoDirection then
        zombie:setForwardIsoDirection(before)
    end
    -- AnimationPlayer is opaque Java userdata in Kahlua on this build. The
    -- vanilla player state can index it internally, but Lua must not probe or
    -- call methods on that object. setForwardIsoDirection is the exposed
    -- character boundary and the PNC bump node consumes that facing.
    return true
end

local function positionAtSeatAnchor(record, zombie, runtime, order)
    local x = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.x)
        or tonumber(order.seatAnchorX)
        or tonumber(order.x)
    local y = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.y)
        or tonumber(order.seatAnchorY)
        or tonumber(order.y)
    local z = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.z)
        or tonumber(order.seatAnchorZ)
        or tonumber(order.z)
    local bodyX
    local bodyY
    if not runtime or runtime.seating ~= true or not zombie then return true end
    if not x or not y or not z then return false, "SEAT_ANCHOR_INVALID" end
    if runtime.positioned == true then return true end
    if not PNC.LiveBodyControl
        or not PNC.LiveBodyControl.SetAuthoritativePosition
    then
        return false, "SEAT_POSITION_CONTROL_UNAVAILABLE"
    end
    bodyX = zombie.getX and zombie:getX() or record.x
    bodyY = zombie.getY and zombie:getY() or record.y
    runtime.approachPosition = { x = bodyX, y = bodyY, z = record.z }
    PNC.LiveBodyControl.SetAuthoritativePosition(zombie, x, y, z)
    record.x, record.y, record.z = x, y, z
    runtime.seatAnchor = { x = x, y = y, z = z }
    runtime.positioned = true
    runtime.phase = "SEAT_ENTRY"
    return true
end

local function retrySeatApproach(record, zombie, order, runtime)
    if not runtime or runtime.seating ~= true then return true end
    local lane = record.runtime and record.runtime.pathing or nil
    if not lane or (lane.phase ~= "blocked" and lane.ownerMode ~= "blocked") then
        return true
    end
    local candidates = runtime.approachCandidates or {}
    runtime.failedApproaches = runtime.failedApproaches or {}
    local current = math.max(1, tonumber(runtime.approachIndex) or 1)
    local active = candidates[current]
    local activeKey = active and tostring(active.approachKey or "") or ""
    if activeKey ~= "" then
        runtime.failedApproaches[activeKey] = true
    else
        runtime.failedApproaches["index:" .. tostring(current)] = true
    end
    local nextIndex = current + 1
    local candidate
    while candidates[nextIndex] do
        candidate = candidates[nextIndex]
        if seatSpotUsable(candidate, runtime.failedApproaches, nextIndex)
            and tonumber(candidate.x) and tonumber(candidate.y)
            and tonumber(candidate.z)
        then
            break
        end
        nextIndex = nextIndex + 1
        candidate = nil
    end
    if not candidate then
        runtime.failedReason = "SEAT_APPROACH_UNREACHABLE"
        runtime.seatRouteStatus = "BLOCKED"
        return false
    end
    runtime.approachIndex = nextIndex
    order.x, order.y, order.z = candidate.x, candidate.y, candidate.z
    order.seatAnchorX = candidate.seatAnchorX or candidate.x
    order.seatAnchorY = candidate.seatAnchorY or candidate.y
    order.seatAnchorZ = candidate.seatAnchorZ or candidate.z
    order.seatDirection = candidate.seatDirection or candidate.direction
    order.seatSide = candidate.seatSide or candidate.side
    order.approachKey = candidate.approachKey
    order.validSpot = candidate.validSpot ~= false
        and candidate.approachValid ~= false
    order.validationState = candidate.validationState or "VALID"
    order.rejectionReason = candidate.rejectionReason
    order.routeStatus = "RETRYING"
    runtime.target = { x = order.x, y = order.y, z = order.z }
    runtime.seatAnchor = {
        x = tonumber(order.seatAnchorX), y = tonumber(order.seatAnchorY),
        z = tonumber(order.seatAnchorZ),
    }
    runtime.seatDirection = tostring(order.seatDirection or "")
    runtime.seatSide = tostring(order.seatSide or "")
    runtime.approachKey = tostring(order.approachKey or "")
    runtime.validSpot = order.validSpot
    runtime.seatValidation = tostring(order.validationState or "")
    runtime.seatRejectionReason = tostring(order.rejectionReason or "")
    runtime.seatRouteStatus = "RETRYING"
    runtime.distance = nil
    runtime.arrivalSettled = false
    runtime.positioned = false
    runtime.seatEntered = false
    runtime.phase = "REPATHING"
    resetPath(record, zombie, "seat_approach_retry")
    return true
end

local function retryWaterApproach(record, zombie, order, runtime)
    if runtime.resourceKind ~= "nearby_water" then return true end
    local lane = record.runtime and record.runtime.pathing or nil
    if not lane or (lane.phase ~= "blocked" and lane.ownerMode ~= "blocked") then
        return true
    end
    local candidates = runtime.approachCandidates or {}
    runtime.failedApproaches = runtime.failedApproaches or {}
    local current = math.max(1, tonumber(runtime.approachIndex) or 1)
    local active = candidates[current]
    if active and active.approachKey then
        runtime.failedApproaches[active.approachKey] = true
    end
    local nextIndex = current + 1
    while candidates[nextIndex]
        and runtime.failedApproaches[candidates[nextIndex].approachKey]
    do
        nextIndex = nextIndex + 1
    end
    local candidate = candidates[nextIndex]
    if not candidate then
        runtime.failedReason = "WATER_APPROACH_UNREACHABLE"
        return false
    end
    runtime.approachIndex = nextIndex
    order.x, order.y, order.z = candidate.x, candidate.y, candidate.z
    order.interactionFacing = candidate.interactionFacing or ""
    runtime.target = { x = order.x, y = order.y, z = order.z }
    runtime.distance = nil
    runtime.phase = "REPATHING"
    resetPath(record, zombie, "water_approach_retry")
    return true
end

local function refreshCampActivity(record, zombie)
    local runtime = state(record)
    if not runtime or runtime.campActivity ~= true then return true end
    if not PNC.CampResourceService
        or not PNC.CampResourceService.RefreshActivity
    then return true end
    local ok, reason = PNC.CampResourceService.RefreshActivity(record, zombie)
    if ok == false then
        runtime.failedReason = reason
            or runtime.seating == true
            and "CAMP_SEAT_TARGET_UNAVAILABLE"
            or "CAMP_SLEEP_TARGET_UNAVAILABLE"
        return false
    end
    return true
end

local function campActivityBounds(record, runtime)
    local state = record and record.campState or nil
    local anchorX = tonumber(runtime and runtime.campX)
        or tonumber(state and state.anchorX)
        or tonumber(record and record.anchorX)
        or tonumber(record and record.x)
        or 0
    local anchorY = tonumber(runtime and runtime.campY)
        or tonumber(state and state.anchorY)
        or tonumber(record and record.anchorY)
        or tonumber(record and record.y)
        or 0
    local anchorZ = tonumber(runtime and runtime.campZ)
        or tonumber(state and state.anchorZ)
        or tonumber(record and record.anchorZ)
        or tonumber(record and record.z)
        or 0
    local campRadius = tonumber(runtime and runtime.campRadius)
        or tonumber(state and state.campRadius)
        or tonumber(record and record.orderSpec
            and record.orderSpec.radius)
        or tonumber(PNC.Const and PNC.Const.CAMP_RADIUS)
        or 3
    local resourceRadius = tonumber(runtime and runtime.resourceRadius)
        or tonumber(state and state.resourceRadius)
        or tonumber(PNC.Const and PNC.Const.CAMP_RESOURCE_RADIUS)
        or 12
    return anchorX, anchorY, anchorZ,
        math.max(0.5, math.min(24, campRadius)),
        math.max(1, math.min(24, resourceRadius))
end

local function campActivityIsSafe(record, zombie, runtime, order)
    if not runtime or runtime.campActivity ~= true then return true end
    local anchorX, anchorY, anchorZ, campRadius = campActivityBounds(
        record, runtime)
    local targetX = tonumber(order and order.x)
    local targetY = tonumber(order and order.y)
    local targetZ = tonumber(order and order.z)
    local anchorTargetX = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.x)
        or tonumber(order and order.seatAnchorX)
    local anchorTargetY = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.y)
        or tonumber(order and order.seatAnchorY)
    local anchorTargetZ = tonumber(runtime and runtime.seatAnchor
        and runtime.seatAnchor.z)
        or tonumber(order and order.seatAnchorZ)
    local targetDistance
    local anchorDistance
    local bodyDistanceFromCamp
    if not targetX or not targetY or not targetZ
        or math.abs(targetZ - anchorZ) > 0.5
    then
        return false, "CAMP_ACTIVITY_TARGET_INVALID"
    end
    targetDistance = PNC.Core.Distance(
        targetX, targetY, anchorX, anchorY)
    if targetDistance > campRadius + 0.5 then
        return false, "CAMP_ACTIVITY_TARGET_OUT_OF_RANGE"
    end
    if anchorTargetX and anchorTargetY and anchorTargetZ then
        if math.abs(anchorTargetZ - anchorZ) > 0.5 then
            return false, "CAMP_ACTIVITY_TARGET_INVALID"
        end
        anchorDistance = PNC.Core.Distance(
            anchorTargetX, anchorTargetY, anchorX, anchorY)
        if anchorDistance > campRadius + 0.5 then
            return false, "CAMP_ACTIVITY_TARGET_OUT_OF_RANGE"
        end
    end
    if zombie and zombie.getX and zombie.getY then
        bodyDistanceFromCamp = PNC.Core.Distance(
            zombie:getX(), zombie:getY(), anchorX, anchorY)
        if bodyDistanceFromCamp > campRadius + 1.0 then
            return false, "CAMP_ACTIVITY_LEFT_AREA"
        end
    end
    return true
end

local function finish(record, zombie, reason, restoreOrder)
    local runtime = state(record)
    if not runtime or runtime.finishing == true then return false end
    runtime.finishing = true
    restorePosition(record, zombie, runtime)
    if PNC.FacilityReservations and runtime.reservationId ~= ""
        and not hasLiveTaskLease(runtime.taskLeaseId)
    then
        PNC.FacilityReservations.Release(
            runtime.reservationId,
            reason == "rested" and "complete" or tostring(reason or "stopped"))
    end
    local previous = runtime.previousOrder
    clearFurnitureSeat(record, zombie, runtime)
    if runtime.seating == true and PNC.SeatingRuntime
        and PNC.SeatingRuntime.LiveObjects
    then
        PNC.SeatingRuntime.LiveObjects[tostring(record.id)] = nil
    end
    record.runtime.facilityActivity = nil
    record.runtime.facilityDebugWork = nil
    record.runtime.seatedThreat = nil
    record.runtime.seatedThreatNextScanAt = nil
    record.runtime.seatedThreatNextValidateAt = nil
    if restoreOrder ~= false then
        PNC.OrderSystem.SetOrder(record, previous)
    end
    return true
end

local function stopAnimationScene(record, zombie, reason)
    local runtime = record.runtime
    local internal
    if record.runtime.animationScene and PNC.AnimationScenes then
        -- Scene callbacks are extension points. Keep the activity cleanup
        -- alive if one of them fails, but do not add protected calls around
        -- ordinary facility logic.
        pcall(PNC.AnimationScenes.Stop, record, zombie,
            reason or "player_stop")
        if runtime.animationScene then
            -- A failed scene stop can leave the blocking scene pointer behind
            -- even though the command has already moved on. Use the scene
            -- lifecycle's normal clear path when available, then guarantee
            -- that the stale pointer cannot consume the next behavior tick.
            internal = PNC.AnimationScenes.Internal
            if internal and internal.ClearScene then
                internal.ClearScene(record, zombie,
                    reason or "player_stop", true)
            end
            runtime.animationScene = nil
        end
    end
end

local function releaseTaskLeaseAfterAbort(record, leaseId, reason)
    local commands
    local cancelled
    local cancelReason
    local leases
    local lease
    local released
    leaseId = tostring(leaseId or "")
    if leaseId == "" then return true end

    -- The facility activity has already been cleared before this call. That
    -- lets the normal provider cancellation path release the lease without
    -- entering Jobs.Stop and restoring the old order recursively.
    commands = PNC.Tasking and PNC.Tasking.Commands
    if commands and commands.CancelForNPC then
        cancelled, cancelReason = commands.CancelForNPC(
            record.id, reason or "order_changed")
        if cancelled == true and cancelReason ~= "CANCELLATION_DEFERRED" then
            return true
        end
    end

    leases = PNC.TaskLeaseService
    if leases and leases.Get and leases.Release then
        lease = leases.Get(leaseId)
        if not lease then return true end
        released = leases.Release(leaseId, reason or "order_changed")
        return released == true
    end
    return cancelled ~= false
end

-- Order changes are authoritative commands. Unlike Jobs.Stop, this path must
-- not restore runtime.previousOrder because the caller is already installing
-- a different order (follow, home, camp, and so on).
function Jobs.AbortForOrderChange(record, zombie, reason)
    local runtime = state(record)
    local leaseId
    local finished
    local abortReason = reason or "order_changed"
    if not runtime then return false, "facility_activity_not_active" end

    zombie = zombie or PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    leaseId = tostring(runtime.taskLeaseId or "")
    runtime.stopRequested = true
    stopAnimationScene(record, zombie, abortReason)
    finished = finish(record, zombie, abortReason, false)
    if not finished then return false, "facility_activity_abort_failed" end
    record.activeJob = nil
    record.activeBehavior = nil
    releaseTaskLeaseAfterAbort(record, leaseId, abortReason)
    return true, "facility_activity_aborted"
end

function Jobs.Stop(record, reason)
    local runtime = state(record)
    local zombie
    if not runtime then return false, "facility_activity_not_active" end
    zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    runtime.stopRequested = true
    -- Cleanup must continue even if scene interruption throws. Otherwise the
    -- activity and its reservation survive without an owner.
    stopAnimationScene(record, zombie, reason)
    local finished = finish(record, zombie, reason or "player_stop")
    return finished == true, "facility_activity_stopped"
end

-- Facility work is the owner of the effect clock. Tasking may observe this
-- value for recovery, but it must never infer progress from an executor tick
-- or a reservation renewal alone.
function Jobs.RecordProgress(record, at, reason)
    local runtime = state(record)
    if not runtime then return false end
    runtime.lastProgressAt = tonumber(at) or PNC.Core.Now()
    runtime.lastProgressReason = tostring(reason or "facility_progress")
    return true
end

function Jobs.OnSceneTick(record, zombie, scene, now)
    local runtime = state(record)
    local definition = runtime and Definitions.Get(runtime.capability) or nil
    local sceneId = runtime and runtime.sceneId ~= "" and runtime.sceneId
        or definition and definition.sceneId
    if not runtime or not definition or scene.id ~= sceneId then
        return false
    end
    runtime.phase = runtime.seating == true
        and "SEATED" or definition.activityLabel or "WORKING"
    if PNC.FacilityReservations and runtime.reservationId ~= ""
        and now >= (tonumber(runtime.nextReservationRenewAt) or 0)
    then
        PNC.FacilityReservations.Start(runtime.reservationId, 30000)
        runtime.nextReservationRenewAt = now + 10000
    end
    if runtime.taskLeaseId ~= "" and PNC.Tasking
        and PNC.Tasking.Commands and PNC.Tasking.Commands.SetPhase
    then PNC.Tasking.Commands.SetPhase(record.id, "WORKING") end
    if definition.domain == "farming" and PNC.FarmingService
        and PNC.FarmingService.TickLive
    then
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or zombie
        local keepScene = PNC.FarmingService.TickLive(
            record, live, runtime, now)
        if runtime.completionRequested == true then return false end
        if keepScene == false then return false end
    end
    if definition.needEffect and PNC.NeedFacilityEffects
        and PNC.NeedsUtils
    then
        local worldNow = PNC.NeedsUtils.WorldAgeHours()
        local previous = tonumber(runtime.lastEffectWorldHour) or worldNow
        local elapsed = math.max(0, math.min(0.25, worldNow - previous))
        runtime.lastEffectWorldHour = worldNow
        local ok, complete, effectReason, value =
            PNC.NeedFacilityEffects.Tick(
                record, runtime, definition, elapsed, now)
        runtime.effectValue = value
        if not ok then
            runtime.failedReason = effectReason or "NEED_EFFECT_FAILED"
            runtime.completionRequested = true
            return false
        end
        if effectReason and Jobs.RecordProgress then
            Jobs.RecordProgress(record, now, effectReason)
        end
        if runtime.debugHold ~= true and complete then
            runtime.completionRequested = true
            -- Food and drink apply their gameplay effect during the primary
            -- action, but retain the task lease until the ordered wipe steps
            -- finish. Other needs keep their existing immediate completion.
            return definition.completeWithScene == true
        end
    end
    return true
end

function Jobs.OnSceneStopped(record, zombie, scene, reason)
    local runtime = state(record)
    if not runtime then return end
    clearFurnitureSeat(record, zombie, runtime)
    restorePosition(record, zombie, runtime)
    runtime.arrivalSettled = false
    if runtime.stopRequested == true then return end
    if runtime.failedReason then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return
    end
    if runtime.completionRequested == true or reason == "callback_complete" then
        local leaseId = runtime.taskLeaseId
        finish(record, zombie, "complete")
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.Complete(leaseId, "NEED_COMPLETE")
        end
        return
    end
    runtime.phase = "INTERRUPTED"
    runtime.interruptReason = tostring(reason or "interrupted")
end

function Jobs.Tick(record, zombie)
    local order = record.orderSpec or {}
    local runtime = state(record)
    local definition = Definitions.Get(order.capability)
    local distance
    local arrivalDistance
    local moveStopDistance
    local refreshed
    local seatReason
    local targetChanged
    local positioned
    local positionReason
    local scene
    local sceneId
    local started
    local startReason
    local startupNow
    if order.kind ~= KIND or not runtime or not definition then return false end
    if not refreshCampActivity(record, zombie) then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return true
    end
    if runtime.resourceKind == "nearby_water" and not runtime.resource
        and PNC.NearbyWaterService and PNC.NearbyWaterService.Resolve
    then
        local resolved, resolveReason = PNC.NearbyWaterService.Resolve(record,
            runtime.resourceKey)
        runtime.resource = resolved
        if not resolved then
            local leaseId = runtime.taskLeaseId
            local failure = resolveReason or "WATER_SOURCE_UNAVAILABLE"
            runtime.failedReason = failure
            if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands
                and PNC.Tasking.Commands.CancelForNPC
            then
                PNC.Tasking.Commands.CancelForNPC(record.id, failure)
            else
                finish(record, zombie, failure)
            end
            return true
        end
    end
    local campSafe, campFailure = campActivityIsSafe(
        record, zombie, runtime, order)
    if not campSafe then
        local leaseId = runtime.taskLeaseId
        resetPath(record, zombie, "camp_activity_safety")
        runtime.failedReason = campFailure
        finish(record, zombie, campFailure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, campFailure)
        end
        return true
    end
    record.activeJob = definition.activeJob or JOB
    record.activeBehavior = "Facility:" .. tostring(order.capability)
    if not retryWaterApproach(record, zombie, order, runtime) then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return true
    end
    if runtime.seating == true and zombie then
        refreshed, seatReason, targetChanged = refreshLiveSeatTarget(
            record, zombie, runtime, order)
        if not refreshed then
            runtime.failedReason = seatReason or "SEAT_TARGET_UNAVAILABLE"
            finish(record, zombie, runtime.failedReason)
            return true
        end
        if targetChanged then
            if runtime.seatEntered == true then
                clearFurnitureSeat(record, zombie, runtime)
            end
            resetPath(record, zombie, "seat_anchor_refreshed")
            runtime.arrivalSettled = false
            runtime.positioned = false
            runtime.facingApplied = false
            runtime.seatEntered = false
        end
    end
    if not retrySeatApproach(record, zombie, order, runtime) then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return true
    end
    sceneId = order.sceneId ~= "" and order.sceneId or definition.sceneId
    runtime.sceneId = sceneId
    runtime.sleepSurface = order.sleepSurface
    distance = bodyDistance(zombie, order.x, order.y)
        or PNC.Core.Distance(record.x, record.y, order.x, order.y)
    runtime.target = { x = order.x, y = order.y, z = order.z }
    runtime.distance = distance
    arrivalDistance = runtime.seating == true
        and (tonumber(runtime.seatArrivalDistance)
            or tonumber(order.arrivalDistance)
            or SEAT_ARRIVAL_TOLERANCE)
        or (tonumber(definition.arrivalDistance) or 0.85)
    moveStopDistance = runtime.seating == true
        and (tonumber(runtime.seatStopDistance)
            or tonumber(order.stopDistance)
            or SEAT_STOP_DISTANCE)
        or 0.7
    if distance > arrivalDistance
        or math.abs((tonumber(record.z) or 0) - order.z) >= 0.5
    then
        runtime.phase = "TRAVELLING"
        if runtime.taskLeaseId ~= "" and PNC.Tasking
            and PNC.Tasking.Commands
        then PNC.Tasking.Commands.SetPhase(record.id, "TRAVEL") end
        PNC.BehaviorCommon.ClearCombatTarget(record, "facility_travel", zombie)
        PNC.BehaviorCommon.MoveRecord(record, zombie, order.x, order.y, order.z,
            "walk", moveStopDistance, "facility_activity")
        return true
    end
    PNC.BehaviorCommon.ClearCombatTarget(record, "facility_working", zombie)
    if runtime.arrivalSettled ~= true then
        -- Arrival transfers movement ownership to a stationary interaction.
        -- A queued Behavior2 route otherwise remains visible to the scene
        -- safety arbiter and repeatedly interrupts/restarts the sleep bump.
        resetPath(record, zombie, "facility_arrival")
        runtime.arrivalSettled = true
    end
    PNC.BehaviorCommon.HaltMovement(record, zombie, "facility_working")
    if runtime.seating == true and runtime.positioned ~= true then
        positioned, positionReason = positionAtSeatAnchor(
            record, zombie, runtime, order)
        if not positioned then
            runtime.failedReason = positionReason or "SEAT_POSITION_FAILED"
            finish(record, zombie, runtime.failedReason)
            return true
        end
    end
    if runtime.seating == true and runtime.seatEntered ~= true then
        local seated, seatReason = enterFurnitureSeat(
            record, zombie, runtime, order)
        if not seated then
            runtime.failedReason = seatReason or "SEAT_UNAVAILABLE"
            finish(record, zombie, runtime.failedReason)
            return true
        end
    end
    if runtime.seating ~= true and runtime.positioned ~= true and zombie
        and order.interactionX and order.interactionY
        and PNC.LiveBodyControl and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        runtime.approachPosition = {
            x = zombie:getX(), y = zombie:getY(), z = zombie:getZ(),
        }
        PNC.LiveBodyControl.SetAuthoritativePosition(zombie,
            order.interactionX, order.interactionY,
            order.interactionZ or order.z)
        record.x, record.y, record.z = order.interactionX,
            order.interactionY, order.interactionZ or order.z
        runtime.positioned = true
    end
    if runtime.facingApplied ~= true and zombie then
        local directionName = tostring(order.interactionFacing or "")
        if order.interactionAxis == "x" then directionName = "E"
        elseif order.interactionAxis == "y" then directionName = "S" end
        if directionName ~= "" and IsoDirections
            and zombie.setForwardIsoDirection
        then
            local direction = IsoDirections[directionName]
            if direction then zombie:setForwardIsoDirection(direction) end
        end
        runtime.facingApplied = true
    end
    scene = record.runtime.animationScene
    if not scene or scene.id ~= sceneId then
        startupNow = currentTime(runtime)
        if tostring(runtime.startupSceneId or "") ~= tostring(sceneId)
            or runtime.startupStartedAt == nil
        then
            runtime.startupSceneId = sceneId
            runtime.startupStartedAt = startupNow
            runtime.startupAttempts = 0
        end
        runtime.startupAttempts = (tonumber(runtime.startupAttempts) or 0) + 1
        runtime.startupLastAttemptAt = startupNow
        runtime.phase = "STARTING"
        runtime.lastProgressAt = startupNow
        runtime.lastProgressReason = "facility_scene_starting"
        runtime.lastEffectWorldHour = PNC.NeedsUtils
            and PNC.NeedsUtils.WorldAgeHours() or nil
        started, startReason = PNC.AnimationScenes.Request(record, zombie, sceneId, {
            reason = "facility_" .. tostring(order.capability),
            repeatMode = definition.completeWithScene == true
                and "once" or "loop",
        })
        if started ~= true then
            -- Do not leave the nameplate in STARTING when scene setup fails.
            -- The next decision may retry the activity, but the failure is
            -- now observable and cannot masquerade as a stuck preparation.
            runtime.phase = "INTERRUPTED"
            runtime.interruptReason = tostring(
                startReason or "scene_request_failed"
            )
            if runtime.startupAttempts >= MAX_SCENE_START_ATTEMPTS then
                local leaseId = runtime.taskLeaseId
                local failure = "FACILITY_SCENE_START_FAILED"
                runtime.failedReason = failure
                finish(record, zombie, failure)
                if leaseId ~= "" and PNC.Tasking
                    and PNC.Tasking.Commands
                    and PNC.Tasking.Commands.CancelForNPC
                then
                    PNC.Tasking.Commands.CancelForNPC(record.id, failure)
                end
                return true
            end
        else
            runtime.startupAttempts = 0
            runtime.startupStartedAt = nil
            runtime.lastProgressAt = startupNow
            runtime.lastProgressReason = "facility_scene_started"
        end
    end
    return true
end

PNC.OrderSystem.RegisterNormalizer(KIND, normalize)
PNC.JobSystem.RegisterOrder(KIND, JOB)
PNC.BehaviorRegistry.Register(JOB, Jobs.Tick)

return Jobs
