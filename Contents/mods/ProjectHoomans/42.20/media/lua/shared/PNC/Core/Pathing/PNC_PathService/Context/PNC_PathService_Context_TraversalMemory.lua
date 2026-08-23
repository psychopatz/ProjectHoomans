-- Repeated passage-attempt memory and progress-based release.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Core = Internal.Core

local function buildTraversalPointKey(x, y, z)
    return tostring(math.floor(tonumber(x) or 0))
        .. ":"
        .. tostring(math.floor(tonumber(y) or 0))
        .. ":"
        .. tostring(math.floor(tonumber(z) or 0))
end

function Internal.clearTraversalMemory(lane)
    if not lane then
        return
    end
    lane.lastTraversalObstacleKey = nil
    lane.lastTraversalKind = nil
    lane.lastTraversalFromKey = nil
    lane.lastTraversalToKey = nil
    lane.lastTraversalFromX = nil
    lane.lastTraversalFromY = nil
    lane.lastTraversalFromZ = nil
    lane.lastTraversalToX = nil
    lane.lastTraversalToY = nil
    lane.lastTraversalToZ = nil
    lane.lastTraversalAttemptAt = 0
    lane.lastTraversalGoalRevision = 0
end

function Internal.noteTraversalAttempt(lane, kind, obstacleKey, fromX, fromY, fromZ, toX, toY, toZ, now, goalRevision)
    if not lane then
        return
    end
    lane.lastTraversalKind = kind and tostring(kind) or lane.lastTraversalKind
    lane.lastTraversalObstacleKey = obstacleKey and tostring(obstacleKey) or lane.lastTraversalObstacleKey
    lane.lastTraversalFromKey = buildTraversalPointKey(fromX, fromY, fromZ)
    lane.lastTraversalToKey = toX ~= nil and buildTraversalPointKey(toX, toY, toZ) or nil
    lane.lastTraversalFromX = tonumber(fromX)
    lane.lastTraversalFromY = tonumber(fromY)
    lane.lastTraversalFromZ = tonumber(fromZ)
    lane.lastTraversalToX = tonumber(toX)
    lane.lastTraversalToY = tonumber(toY)
    lane.lastTraversalToZ = tonumber(toZ)
    lane.lastTraversalAttemptAt = tonumber(now) or Core.Now()
    if goalRevision ~= nil then
        lane.lastTraversalGoalRevision = tonumber(goalRevision) or lane.lastTraversalGoalRevision
    end
end

function Internal.isRepeatedTraversalAttempt(lane, obstacleKey, fromX, fromY, fromZ, goalRevision, now)
    if not lane or not obstacleKey or not lane.lastTraversalObstacleKey or not lane.lastTraversalFromKey then
        return false
    end
    if tostring(lane.lastTraversalObstacleKey) ~= tostring(obstacleKey) then
        return false
    end
    if (tonumber(now) or Core.Now()) - (tonumber(lane.lastTraversalAttemptAt) or 0) > Internal.TRAVERSAL_REPEAT_COOLDOWN_MS then
        return false
    end
    -- A moving follow target increments goalRevision continuously. Letting a
    -- revision bypass this guard allowed injured followers to vault the same
    -- fence back and forth, starting another path immediately on each side.
    -- refreshTraversalMemory clears the guard once the NPC has made real
    -- progress away from the landing edge.
    return true
end

function Internal.refreshTraversalMemory(lane, zombie)
    local dx
    local dy
    if not lane or not zombie or lane.lastTraversalToX == nil or lane.lastTraversalToY == nil then
        return
    end
    dx = zombie:getX() - (tonumber(lane.lastTraversalToX) or zombie:getX())
    dy = zombie:getY() - (tonumber(lane.lastTraversalToY) or zombie:getY())
    if math.sqrt((dx * dx) + (dy * dy)) >= Internal.TRAVERSAL_PROGRESS_CLEAR_DISTANCE then
        Internal.clearTraversalMemory(lane)
    end
end
