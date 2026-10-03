if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Need profiling and deterministic zone assignment scoring.
local Service = PNC.CampZoneService
local Internal = Service.Internal
local CampSite = Internal.CampSite
local number = Internal.number
local text = Internal.text
local siteDistanceSq = Internal.siteDistanceSq
local NEED_ORDER = Service.Internal.NEED_ORDER
local NEED_KIND = Service.Internal.NEED_KIND

local function evaluateNeed(definitions, record, id)
    local definition
    local actionable
    local metadata
    if not definitions or type(definitions.Get) ~= "function"
        or type(definitions.Evaluate) ~= "function"
    then
        return nil
    end
    definition = definitions.Get(id)
    if not definition then return nil end
    actionable, metadata = definitions.Evaluate(definition, record, false)
    if actionable ~= true then return nil end
    metadata = type(metadata) == "table" and metadata or {}
    return {
        id = id,
        kind = NEED_KIND[id] or "social",
        value = number(metadata.value, 0),
        urgency = number(metadata.urgency, number(metadata.value, 0)),
        critical = tostring(metadata.precedence or "")
            == "CRITICAL_NEED",
        precedence = text(metadata.precedence, "NORMAL_NEED", 32),
    }
end

local function needProfile(record)
    local definitions = PNC.NeedFacilityTriggerDefinitions
    local candidates = {}
    local candidate
    local best
    for index = 1, #NEED_ORDER do
        candidate = evaluateNeed(definitions, record, NEED_ORDER[index])
        if candidate then candidates[#candidates + 1] = candidate end
    end
    table.sort(candidates, function(left, right)
        if left.critical ~= right.critical then return left.critical end
        if left.urgency ~= right.urgency then
            return left.urgency > right.urgency
        end
        if left.value ~= right.value then return left.value > right.value end
        return tostring(left.id) < tostring(right.id)
    end)
    best = candidates[1]
    if best then
        best.reason = "need_" .. tostring(best.kind)
        return best
    end
    return {
        id = "social",
        kind = "social",
        value = 0,
        urgency = 0,
        critical = false,
        precedence = "NORMAL_NEED",
        reason = "social_rotation",
    }
end

local function matches(profile, zone)
    local capabilities = zone and zone.capabilities or {}
    if profile.kind == "sleep" then return capabilities.sleep == true end
    if profile.kind == "water" then return capabilities.water == true end
    if profile.kind == "food" then return capabilities.food == true end
    return capabilities.social == true
end

local function preferredRoomBonus(profile, zone)
    local roomType = tostring(zone and zone.roomType or "")
    if profile.kind == "sleep" then
        if roomType == "BEDROOM" then return 700 end
        if zone.capabilities and zone.capabilities.sleep then return 500 end
    elseif profile.kind == "water" then
        if zone.capabilities and zone.capabilities.water then return 900 end
    elseif profile.kind == "food" then
        if roomType == "KITCHEN" then return 700 end
        if roomType == "DINING_ROOM" then return 500 end
    else
        if roomType == "LIVING_ROOM" then return 700 end
        if roomType == "KITCHEN" or roomType == "DINING_ROOM" then
            return 450
        end
        if zone.capabilities and zone.capabilities.seating then return 180 end
    end
    return 0
end

local function assignmentScore(profile, zone, occupancy, rootSite)
    local score = 0
    if matches(profile, zone) then score = score + 2000 end
    score = score + preferredRoomBonus(profile, zone)
    if (tonumber(occupancy) or 0) == 0 then score = score + 350 end
    score = score - (tonumber(occupancy) or 0) * 400
    score = score - math.sqrt(siteDistanceSq(zone, rootSite))
    return score
end

local function bestZone(profile, directory, occupancy, rootSite)
    local best
    local bestScore
    local zone
    local score
    local hasMatch = false
    for index = 1, #directory.zones do
        if matches(profile, directory.zones[index]) then
            hasMatch = true
            break
        end
    end
    for index = 1, #directory.zones do
        zone = directory.zones[index]
        if not hasMatch or matches(profile, zone) then
            score = assignmentScore(profile, zone,
                occupancy[tostring(zone.siteID or "")] or 0, rootSite)
            if not best or score > bestScore
                or (score == bestScore
                    and tostring(zone.siteID or "")
                        < tostring(best.siteID or ""))
            then
                best = zone
                bestScore = score
            end
        end
    end
    return best, bestScore, hasMatch
end

local function sortRecords(records, profiles)
    table.sort(records, function(left, right)
        local leftProfile = profiles[tostring(left.id or "")]
        local rightProfile = profiles[tostring(right.id or "")]
        if leftProfile.critical ~= rightProfile.critical then
            return leftProfile.critical
        end
        if leftProfile.urgency ~= rightProfile.urgency then
            return leftProfile.urgency > rightProfile.urgency
        end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
end

Internal.evaluateNeed = evaluateNeed
Internal.needProfile = needProfile
Internal.matches = matches
Internal.preferredRoomBonus = preferredRoomBonus
Internal.assignmentScore = assignmentScore
Internal.bestZone = bestZone
Internal.sortRecords = sortRecords

return Service
