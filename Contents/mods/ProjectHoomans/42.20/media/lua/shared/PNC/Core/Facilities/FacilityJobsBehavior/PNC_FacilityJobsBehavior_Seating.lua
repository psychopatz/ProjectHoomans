PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local SEAT_STOP_DISTANCE = Internal.SEAT_STOP_DISTANCE
local SEAT_ARRIVAL_TOLERANCE = Internal.SEAT_ARRIVAL_TOLERANCE

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
function Internal.RefreshLiveSeatTarget(record, zombie, runtime, order)
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
    object = Internal.LiveSeatObject(record, runtime)
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

function Internal.ApplySeatFacing(zombie, direction, side)
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

function Internal.PositionAtSeatAnchor(record, zombie, runtime, order)
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

function Internal.SeatSpotUsable(spot, failedApproaches, index)
    return seatSpotUsable(spot, failedApproaches, index)
end

return Internal
