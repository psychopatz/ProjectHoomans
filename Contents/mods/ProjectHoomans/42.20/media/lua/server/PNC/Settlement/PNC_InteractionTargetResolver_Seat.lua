if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Seating furniture targets and live SeatingManager validation.
local Targets = PNC.FacilityInteractionTargets
local Internal = Targets.Internal
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"
local Resources = PNC.FacilityResources
local isApproachSquare = Internal.isApproachSquare
local sleepSpotTargets = Internal.sleepSpotTargets
local resourceSleepTargets = Internal.resourceSleepTargets

local function fallbackSeatSpots(resource)
    local originX = math.floor(tonumber(resource.originX)
        or tonumber(resource.x) or 0)
    local originY = math.floor(tonumber(resource.originY)
        or tonumber(resource.y) or 0)
    local originZ = math.floor(tonumber(resource.originZ)
        or tonumber(resource.z) or 0)
    local offsets = {
        { 0, 1, "N" }, { 1, 0, "E" },
        { 0, -1, "S" }, { -1, 0, "W" },
    }
    local spots = {}
    -- Without an IsoGameCharacter, SeatingManager cannot validate the full
    -- animation-side approach. Keep these as rematerialization hints only;
    -- live resolution must use BuildSeatSpots instead.
    for index = 1, #offsets do
        local offset = offsets[index]
        local x = originX + offset[1]
        local y = originY + offset[2]
        local square = SquareRules.GetSquare(x, y, originZ)
        if isApproachSquare(square) then
            spots[#spots + 1] = {
                x = x + 0.5, y = y + 0.5, z = originZ,
                seatAnchorX = x + 0.5, seatAnchorY = y + 0.5,
                seatAnchorZ = originZ,
                direction = offset[3], side = "Front",
                approachKey = offset[3] .. ":Front", valid = false,
                approachValid = false, validationState = "DEFERRED",
                routeStatus = "DEFERRED",
            }
        end
    end
    if #spots == 0 then
        spots[1] = {
            x = originX + 0.5, y = originY + 0.5, z = originZ,
            seatAnchorX = originX + 0.5, seatAnchorY = originY + 0.5,
            seatAnchorZ = originZ,
            direction = "S", side = "Front",
            approachKey = "S:Front", valid = false,
            approachValid = false, validationState = "DEFERRED",
            routeStatus = "DEFERRED",
        }
    end
    return spots
end

local function resourceSeatTargets(resource, context)
    context = type(context) == "table" and context or {}
    local object = resource.object
    if not object and Resources and Resources.ResolveLiveObject
        and context.abstract ~= true
    then
        object = Resources.ResolveLiveObject(resource)
    end
    local spots = resource.seatSpots
    if object and context.character and Resources
        and Resources.BuildSeatSpots
    then
        local liveSpots = Resources.BuildSeatSpots(context.character, object)
        -- A live object with no SeatingManager approach position is not a
        -- usable live target. Abstract records may still use their captured
        -- primitive spot list or a conservative fallback for rematerializing.
        if #liveSpots > 0 then
            spots = liveSpots
        elseif context.abstract ~= true then
            return {}
        end
    elseif context.character and not object then
        -- A live body must never use an abstract or stale seat coordinate
        -- without resolving the current world object first.
        return {}
    end
    if type(spots) ~= "table" or #spots == 0 then
        if object and context.abstract ~= true then return {} end
        spots = fallbackSeatSpots(resource)
    end
    local character = context.character
    local requestedApproachKey = tostring(context.approachKey or "")
    local includeInvalid = context.includeInvalid == true
    local allowDeferred = context.abstract == true
    if character and character.getX and character.getY then
        table.sort(spots, function(left, right)
            local leftRequested = requestedApproachKey ~= ""
                and tostring(left.approachKey or "") == requestedApproachKey
            local rightRequested = requestedApproachKey ~= ""
                and tostring(right.approachKey or "") == requestedApproachKey
            if leftRequested ~= rightRequested then
                return leftRequested
            end
            local leftDistance = (left.x - character:getX())
                * (left.x - character:getX())
                + (left.y - character:getY())
                * (left.y - character:getY())
            local rightDistance = (right.x - character:getX())
                * (right.x - character:getX())
                + (right.y - character:getY())
                * (right.y - character:getY())
            return leftDistance < rightDistance
        end)
    elseif requestedApproachKey ~= "" then
        table.sort(spots, function(left, right)
            local leftRequested = tostring(left.approachKey or "")
                == requestedApproachKey
            local rightRequested = tostring(right.approachKey or "")
                == requestedApproachKey
            if leftRequested ~= rightRequested then
                return leftRequested
            end
            return tostring(left.approachKey or "")
                < tostring(right.approachKey or "")
        end)
    end
    local targets = {}
    for index = 1, #spots do
        local spot = spots[index]
        local validSpot = type(spot) == "table"
            and spot.valid ~= false and spot.approachValid ~= false
        if type(spot) == "table" and tonumber(spot.x)
            and tonumber(spot.y) and tonumber(spot.z)
            and (validSpot or includeInvalid or allowDeferred)
        then
            targets[#targets + 1] = {
                x = tonumber(spot.x), y = tonumber(spot.y),
                z = tonumber(spot.z), sceneId = "facility.living.sitFurniture",
                seatAnchorX = tonumber(spot.seatAnchorX or spot.x),
                seatAnchorY = tonumber(spot.seatAnchorY or spot.y),
                seatAnchorZ = tonumber(spot.seatAnchorZ or spot.z),
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
                seating = true, seatDirection = spot.direction,
                seatSide = spot.side, approachKey = spot.approachKey,
                validSpot = validSpot,
                validationState = spot.validationState
                    or (validSpot and "VALID" or allowDeferred
                        and "DEFERRED" or "BLOCKED"),
                rejectionReason = spot.rejectionReason,
                routeStatus = spot.routeStatus
                    or (allowDeferred and "DEFERRED" or "UNTESTED"),
                -- SeatingManager returns the exact furniture animation anchor.
                -- Movement uses the corrected approach point above; the
                -- behavior performs a final authoritative snap to the
                -- separate animation anchor.
                stopDistance = 0.10,
                arrivalDistance = 0.14,
                object = object,
            }
        end
    end
    return targets
end

Targets.Register("sleepSpot", sleepSpotTargets)
-- Compatibility for components saved before sleep spots became furniture-optional.
Targets.Register("bed", sleepSpotTargets)
Targets.RegisterResource("bed", resourceSleepTargets)
Targets.RegisterResource("sofa", resourceSleepTargets)
Targets.RegisterResource("seat", resourceSeatTargets)

return Targets
