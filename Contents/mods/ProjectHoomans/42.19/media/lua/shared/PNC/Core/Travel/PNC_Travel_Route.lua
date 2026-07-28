--[[
    Immutable route geometry for persistent NPC journeys.

    This module knows nothing about records, presence, networking, or jobs.
    Keeping geometry pure makes route providers and future threat-aware
    planners replaceable without changing the journey state machine.
]]

PNC = PNC or {}
PNC.Travel = PNC.Travel or {}
PNC.Travel.Route = PNC.Travel.Route or {}

local Route = PNC.Travel.Route
local Const = PNC.Const

local function number(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return fallback
    end
    return value
end

local function point(source, fallback)
    source = type(source) == "table" and source or {}
    fallback = type(fallback) == "table" and fallback or {}
    return {
        x = number(source.x, number(fallback.x, 0)),
        y = number(source.y, number(fallback.y, 0)),
        z = number(source.z, number(fallback.z, 0)),
        waitWorldHours = math.max(
            0,
            number(
                source.waitWorldHours or source.waitHours,
                number(fallback.waitWorldHours, 0)
            )
        ),
        tag = source.tag ~= nil and tostring(source.tag) or nil,
    }
end

local function samePoint(left, right)
    return math.abs(left.x - right.x) <= 0.001
        and math.abs(left.y - right.y) <= 0.001
        and math.abs(left.z - right.z) <= 0.001
end

function Route.NormalizePoint(source, fallback)
    return point(source, fallback)
end

function Route.Build(points, origin, destination)
    local normalized = {}
    local segments = {}
    local maximum = math.max(
        2,
        math.floor(tonumber(Const.TRAVEL_ROUTE_MAX_POINTS) or 128)
    )
    local startPoint = point(origin)
    local endPoint = point(destination, startPoint)
    local i
    local candidate
    local from
    local to
    local dx
    local dy
    local dz
    local length
    local total = 0

    normalized[1] = startPoint
    for i = 1, math.min(type(points) == "table" and #points or 0, maximum) do
        candidate = point(points[i], normalized[#normalized])
        if not samePoint(candidate, normalized[#normalized])
            and #normalized < maximum
        then
            normalized[#normalized + 1] = candidate
        elseif #normalized > 0 and points[i]
            and number(points[i].waitWorldHours or points[i].waitHours, 0) > 0
        then
            normalized[#normalized].waitWorldHours = math.max(
                normalized[#normalized].waitWorldHours or 0,
                number(points[i].waitWorldHours or points[i].waitHours, 0)
            )
            normalized[#normalized].tag = points[i].tag
                and tostring(points[i].tag)
                or normalized[#normalized].tag
        end
    end
    if not samePoint(normalized[#normalized], endPoint) then
        if #normalized >= maximum then
            normalized[#normalized] = endPoint
        else
            normalized[#normalized + 1] = endPoint
        end
    else
        normalized[#normalized].waitWorldHours = endPoint.waitWorldHours
        normalized[#normalized].tag = endPoint.tag
            or normalized[#normalized].tag
    end
    if #normalized < 2 then
        normalized[2] = point(endPoint, startPoint)
    end

    for i = 1, #normalized - 1 do
        from = normalized[i]
        to = normalized[i + 1]
        dx = to.x - from.x
        dy = to.y - from.y
        dz = to.z - from.z
        length = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
        segments[i] = {
            index = i,
            fromX = from.x,
            fromY = from.y,
            fromZ = from.z,
            toX = to.x,
            toY = to.y,
            toZ = to.z,
            length = length,
            distanceStart = total,
            distanceEnd = total + length,
            waitWorldHours = math.max(0, tonumber(to.waitWorldHours) or 0),
            tag = to.tag,
        }
        total = total + length
    end

    return {
        schemaVersion = tonumber(Const.TRAVEL_SCHEMA_VERSION) or 1,
        points = normalized,
        segments = segments,
        totalDistance = total,
    }
end

function Route.BuildDirect(origin, destination)
    return Route.Build(nil, origin, destination)
end

function Route.Project(route, distance, hint)
    local segments = route and route.segments or {}
    local total = math.max(0, tonumber(route and route.totalDistance) or 0)
    local clamped = math.max(0, math.min(total, tonumber(distance) or 0))
    local index = math.max(
        1,
        math.min(#segments, math.floor(tonumber(hint) or 1))
    )
    local segment
    local progress

    if #segments <= 0 then
        local first = route and route.points and route.points[1] or {}
        return {
            x = tonumber(first.x) or 0,
            y = tonumber(first.y) or 0,
            z = tonumber(first.z) or 0,
            segmentIndex = 1,
            segmentProgress = 1,
            distance = 0,
        }
    end
    while index > 1 and clamped < segments[index].distanceStart do
        index = index - 1
    end
    while index < #segments and clamped > segments[index].distanceEnd do
        index = index + 1
    end
    segment = segments[index]
    progress = segment.length <= 0 and 1
        or math.max(
            0,
            math.min(
                1,
                (clamped - segment.distanceStart) / segment.length
            )
        )
    return {
        x = segment.fromX + (segment.toX - segment.fromX) * progress,
        y = segment.fromY + (segment.toY - segment.fromY) * progress,
        z = segment.fromZ + (segment.toZ - segment.fromZ) * progress,
        segmentIndex = index,
        segmentProgress = progress,
        distance = clamped,
    }
end

function Route.ProjectWorldPosition(route, x, y, z, minimumDistance)
    local segments = route and route.segments or {}
    local bestDistanceSq = math.huge
    local bestRouteDistance = math.max(0, tonumber(minimumDistance) or 0)
    local i
    local segment
    local dx
    local dy
    local dz
    local lengthSq
    local along
    local px
    local py
    local pz
    local ex
    local ey
    local ez
    local distanceSq

    x = tonumber(x) or 0
    y = tonumber(y) or 0
    z = tonumber(z) or 0
    for i = 1, #segments do
        segment = segments[i]
        if segment.distanceEnd + 0.001 >= bestRouteDistance then
            dx = segment.toX - segment.fromX
            dy = segment.toY - segment.fromY
            dz = segment.toZ - segment.fromZ
            lengthSq = (dx * dx) + (dy * dy) + (dz * dz)
            along = lengthSq <= 0 and 0 or (
                ((x - segment.fromX) * dx)
                    + ((y - segment.fromY) * dy)
                    + ((z - segment.fromZ) * dz)
            ) / lengthSq
            along = math.max(0, math.min(1, along))
            px = segment.fromX + dx * along
            py = segment.fromY + dy * along
            pz = segment.fromZ + dz * along
            ex = x - px
            ey = y - py
            ez = z - pz
            distanceSq = (ex * ex) + (ey * ey) + (ez * ez)
            if distanceSq < bestDistanceSq then
                bestDistanceSq = distanceSq
                bestRouteDistance = math.max(
                    tonumber(minimumDistance) or 0,
                    segment.distanceStart + segment.length * along
                )
            end
        end
    end
    return bestRouteDistance, bestDistanceSq
end

function Route.RemainingWaitHours(route, segmentIndex)
    local total = 0
    local segments = route and route.segments or {}
    local i
    for i = math.max(1, math.floor(tonumber(segmentIndex) or 1)), #segments - 1 do
        total = total + math.max(
            0,
            tonumber(segments[i].waitWorldHours) or 0
        )
    end
    return total
end

return Route
