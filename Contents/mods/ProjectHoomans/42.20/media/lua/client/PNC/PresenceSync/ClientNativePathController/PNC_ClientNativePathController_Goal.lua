--[[
    PNC Client Native Path Controller: goal construction, progress, and diagnostics
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
Internal.NativePathController =
    Internal.NativePathController or {}
local Controller = Internal.NativePathController
local Network = PNC.Network
local PROGRESS_EPSILON_SQ = Controller.PROGRESS_EPSILON_SQ

local function hasBodyActionLock(body)
    local modData = body
        and body.getModData
        and body:getModData()
        or nil
    return modData ~= nil
        and (
            modData.PNC_BumpActionLease == true
            or modData.PNC_BumpReleasePending == true
        )
end

local function buildGoal(snapshot, body)
    local visualState = snapshot
        and snapshot.visualState or nil
    if not visualState
        or visualState.nativeMoveActive ~= true
        or visualState.attackActive == true
        or hasBodyActionLock(body)
    then
        return nil
    end
    local x = tonumber(visualState.nativeMoveX)
    local y = tonumber(visualState.nativeMoveY)
    local z = tonumber(visualState.nativeMoveZ)
    if x == nil or y == nil or z == nil then
        return nil
    end
    return {
        x = x,
        y = y,
        z = z,
        stopDistance = math.max(
            0.1,
            tonumber(visualState.nativeMoveStopDistance)
                or 0.7
        ),
        revision = tonumber(
            visualState.nativeMoveRevision
        ) or 0,
    }
end

local function distanceToGoalSquared(body, goal)
    local dx = goal.x - body:getX()
    local dy = goal.y - body:getY()
    local dz = math.abs(goal.z - body:getZ())
    if dz >= 0.5 then
        return math.huge
    end
    return (dx * dx) + (dy * dy)
end

local function rememberProgress(body, state, now)
    local x = body:getX()
    local y = body:getY()
    local z = body:getZ()
    local dx = x - (tonumber(state.lastX) or x)
    local dy = y - (tonumber(state.lastY) or y)
    local dz = z - (tonumber(state.lastZ) or z)
    if (dx * dx) + (dy * dy) + (dz * dz)
        >= PROGRESS_EPSILON_SQ
    then
        state.lastProgressAt = now
    end
    state.lastX = x
    state.lastY = y
    state.lastZ = z
end

local function requestKey(snapshot, goal)
    return table.concat({
        tostring(snapshot and snapshot.liveBodyLease or ""),
        tostring(goal.revision),
        tostring(goal.x),
        tostring(goal.y),
        tostring(goal.z),
    }, ":")
end

local function logState(snapshot, eventName, extra)
    if Internal.LogClientMotionDebug then
        Internal.LogClientMotionDebug(
            snapshot,
            snapshot and snapshot.id or nil,
            eventName,
            extra
        )
    end
end

local function describeBody(body)
    local onlineID = Network
        and Network.GetZombieOnlineID
        and Network.GetZombieOnlineID(body)
        or nil
    local actionState = body
        and body.getActionStateName
        and body:getActionStateName()
        or "unknown"
    local useless = body
        and body.isUseless
        and body:isUseless()
        or false
    local hasPath = body
        and body.getPath2
        and body:getPath2() ~= nil
        or false
    return " bodyOnlineID=" .. tostring(onlineID or "nil")
        .. " pos=" .. tostring(body and body:getX() or "nil")
        .. "," .. tostring(body and body:getY() or "nil")
        .. "," .. tostring(body and body:getZ() or "nil")
        .. " action=" .. tostring(actionState)
        .. " useless=" .. tostring(useless)
        .. " path2=" .. tostring(hasPath)
end


Controller.HasBodyActionLock = hasBodyActionLock
Controller.BuildGoal = buildGoal
Controller.DistanceToGoalSquared = distanceToGoalSquared
Controller.RememberProgress = rememberProgress
Controller.RequestKey = requestKey
Controller.LogState = logState
Controller.DescribeBody = describeBody

