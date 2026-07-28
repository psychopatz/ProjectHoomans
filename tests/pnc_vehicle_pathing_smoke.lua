local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Pathing/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PNC = {
    Const = {
        VEHICLE_AVOIDANCE_CACHE_MS = 250,
        VEHICLE_AVOIDANCE_CLEARANCE_TILES = 1,
    },
    Core = {
        Now = function() return 1000 end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        LogWarn = function(message)
            PNC._lastWarning = message
            PNC._warningCount = (PNC._warningCount or 0) + 1
        end,
        LogRecordDebug = function() end,
    },
}

dofile(ROOT .. "PNC_LiveBodyControl.lua")
dofile(ROOT .. "PNC_VehicleAvoidance.lua")
dofile(ROOT .. "PNC_TraversalQuery.lua")

local position = {}
local lastPosition = {}
local body = {
    setX = function(_, value) position.x = value end,
    setY = function(_, value) position.y = value end,
    setZ = function(_, value) position.z = value end,
    setLastX = function(_, value) lastPosition.x = value end,
    setLastY = function(_, value) lastPosition.y = value end,
    setLastZ = function(_, value) lastPosition.z = value end,
}

assertEqual(
    PNC.LiveBodyControl.SetAuthoritativePosition(body, 10.25, 11.5, 0),
    true,
    "authoritative position accepted"
)
assertEqual(position.x, 10.25, "body x")
assertEqual(position.y, 11.5, "body y")
assertEqual(position.z, 0, "body z")
assertEqual(lastPosition.x, position.x, "last x synchronized")
assertEqual(lastPosition.y, position.y, "last y synchronized")
assertEqual(lastPosition.z, position.z, "last z synchronized")

local function makeSquare(vehicleIntersecting)
    return {
        isFree = function() return true end,
        isSolid = function() return false end,
        isSolidTrans = function() return false end,
        isVehicleIntersecting = function() return vehicleIntersecting == true end,
    }
end

local clearSquare = makeSquare(false)
local vehicleBlocking = true
local vehicleSquare = makeSquare(true)
vehicleSquare.isVehicleIntersecting = function()
    return vehicleBlocking
end
local cachedVehicleBlocking = true
local cachedVehicle = {
    getPolyPlusRadius = function()
        return {
            x1 = 4,
            y1 = 0,
            x2 = 5,
            y2 = 0,
            x3 = 5,
            y3 = 1,
            x4 = 4,
            y4 = 1,
            z = 0,
        }
    end,
    isIntersectingSquare = function(_, x, y, z)
        return cachedVehicleBlocking and x == 4 and y == 0 and z == 0
    end,
    isRemovedFromWorld = function() return false end,
}
local vehicles = {
    iterator = function()
        local consumed = false
        return {
            hasNext = function() return not consumed end,
            next = function()
                consumed = true
                return cachedVehicle
            end,
        }
    end,
}
local cell = {
    getGridSquare = function(_, x)
        return x == 1 and vehicleSquare or clearSquare
    end,
    getVehicles = function() return vehicles end,
}
getCell = function() return cell end

assertEqual(
    PNC.TraversalQuery.CanOccupy(0.5, 0.5, 0, cell),
    true,
    "clear square remains walkable"
)
assertEqual(
    PNC.TraversalQuery.CanOccupy(1.5, 0.5, 0, cell),
    false,
    "vehicle footprint blocks NPC occupancy"
)
assertEqual(
    PNC.TraversalQuery.GetOccupancyReason(1.5, 0.5, 0, cell),
    "vehicle",
    "vehicle occupancy reason"
)
local safeX, safeY, safeZ, recoveryReason =
    PNC.TraversalQuery.FindNearestOccupable(1.5, 0.5, 0, 4, cell)
assertEqual(safeX, 0.5, "nearest safe recovery x")
assertEqual(safeY, 0.5, "nearest safe recovery y")
assertEqual(safeZ, 0, "nearest safe recovery z")
assertEqual(recoveryReason, "vehicle", "nearest safe recovery reason")
assertEqual(
    PNC.TraversalQuery.GetOccupancyReason(4.5, 0.5, 0, cell),
    "vehicle",
    "vehicle registry supplements stale square cache"
)
local canStep, stepReason = PNC.TraversalQuery.CanStep(
    2.5,
    0.5,
    0,
    3.5,
    0.5,
    0,
    cell
)
assertEqual(canStep, false, "route does not enter vehicle clearance")
assertEqual(stepReason, "vehicle_clearance", "vehicle clearance reason")
canStep = PNC.TraversalQuery.CanStep(
    3.5,
    0.5,
    0,
    2.5,
    0.5,
    0,
    cell
)
assertEqual(canStep, true, "route may escape vehicle clearance")

local windowObject = {
    isDestroyed = function() return false end,
    IsOpen = function() return false end,
}
local windowFromSquare = makeSquare(false)
local windowVehicleSquare = makeSquare(false)
windowFromSquare.getWindowTo = function() return windowObject end
local windowCell = {
    getGridSquare = function(_, x)
        return x == 4 and windowVehicleSquare or windowFromSquare
    end,
    getVehicles = function() return vehicles end,
}
PNC.VehicleAvoidance.Invalidate()
canStep, stepReason = PNC.TraversalQuery.CanStep(
    3.5,
    0.5,
    0,
    4.5,
    0.5,
    0,
    windowCell
)
assertEqual(canStep, false, "vehicle landing blocks window traversal")
assertEqual(stepReason, "vehicle", "vehicle wins over window interaction")

local nonTablePoly = coroutine.create(function() end)
local javaLikeVehicle = {
    getPolyPlusRadius = function()
        return nonTablePoly
    end,
    getX = function() return 7.5 end,
    getY = function() return 8.5 end,
    getZ = function() return 0 end,
    getScript = function()
        return {
            getExtents = function()
                return {
                    x = function() return 0.9 end,
                    z = function() return 2.4 end,
                }
            end,
        }
    end,
    isRemovedFromWorld = function() return false end,
    isIntersectingSquare = function(_, x, y, z)
        return x == 7 and y == 8 and z == 0
    end,
}
local javaLikeVehicles = {
    iterator = function()
        local consumed = false
        return {
            hasNext = function() return not consumed end,
            next = function()
                consumed = true
                return javaLikeVehicle
            end,
        }
    end,
}
local javaLikeCell = {
    getGridSquare = function() return clearSquare end,
    getVehicles = function() return javaLikeVehicles end,
}
PNC.VehicleAvoidance.Invalidate()
assertEqual(
    PNC.VehicleAvoidance.GetReason(
        7.5,
        8.5,
        0,
        javaLikeCell,
        false
    ),
    "vehicle",
    "non-table Build 42 VehiclePoly footprint"
)

PNC.LocomotionProfiles = {
    GetBaseProfile = function()
        return { speed = 1, moveAnim = "Walk" }
    end,
}
dofile(ROOT .. "PNC_FakeLocomotion.lua")

local authoritativeWrites = 0
local setAuthoritativePosition = PNC.LiveBodyControl.SetAuthoritativePosition
PNC.LiveBodyControl.SetAuthoritativePosition = function(...)
    authoritativeWrites = authoritativeWrites + 1
    return setAuthoritativePosition(...)
end
body.getX = function() return position.x end
body.getY = function() return position.y end
body.getZ = function() return position.z end
body.faceLocation = function() end
position.x = 0.5
position.y = 0.5
position.z = 0
local record = { x = 0.5, y = 0.5, z = 0 }
local lane = {
    resolvedMode = "walk",
    mode = "walk",
    lastStepAt = 950,
}
local moved = PNC.FakeLocomotion.StepTowardGoal(
    body,
    record,
    lane,
    { x = 0.8, y = 0.5, z = 0, mode = "walk" },
    1000
)
assertEqual(moved, true, "clear fake-locomotion step")
assertEqual(authoritativeWrites, 1, "fake locomotion uses safe authoritative writer")
assertEqual(lastPosition.x, position.x, "fake locomotion synchronizes last x")

PNC.PathService = { Internal = {} }
PNC.Registry = {
    MarkDirty = function(_, domain)
        PNC._dirtyDomain = domain
    end,
}
dofile(ROOT .. "PNC_PathService/PNC_PathService_Context.lua")
position.x = 1.5
position.y = 0.5
position.z = 0
record = {
    id = "vehicle_stuck",
    name = "Vehicle Stuck",
    x = position.x,
    y = position.y,
    z = position.z,
    runtime = {
        moveIntent = {
            kind = "move",
            x = 8.5,
            y = 0.5,
            z = 0,
            mode = "walk",
            stopDistance = 0.7,
            reason = "test_vehicle_goal",
        },
    },
}
lane = {
    phase = "active",
    goal = {
        x = 8.5,
        y = 0.5,
        z = 0,
        mode = "walk",
        stopDistance = 0.7,
    },
}
local repaired, repairedReason =
    PNC.PathService.Internal.repairInvalidBodyPosition(record, body, lane, 2000)
assertEqual(repaired, true, "live vehicle position repaired")
assertEqual(repairedReason, "vehicle", "live repair reason")
assertEqual(position.x, 0.5, "live repair destination x")
assertEqual(record.x, position.x, "live repair record x")
assertEqual(record.runtime.forceSyncEvent, "position_recovery", "live repair multiplayer sync")
assertEqual(record.runtime.positionRecovery.lastEvent, "live_unstuck", "live repair metadata")
assertEqual(PNC._dirtyDomain, "position_recovery", "live repair persisted")
assertEqual(lane.phase, "cancel_pending", "vehicle path lane invalidated")
assertEqual(lane.vehicleBlockedGoalX, 8.5, "vehicle-blocked goal quarantined")
assert(
    string.find(PNC._lastWarning or "", "event=live_unstuck", 1, true),
    "live repair warning was not logged"
)

position.x = 1.5
position.y = 0.5
repaired = PNC.PathService.Internal.repairInvalidBodyPosition(
    record,
    body,
    lane,
    2500
)
assertEqual(repaired, true, "repeated vehicle position repaired")
assertEqual(PNC._warningCount, 1, "repeated recovery warning throttled")
assertEqual(record.runtime.positionRecovery.suppressedLogs, 1,
    "suppressed recovery warning counted")

PNC.PathService.Internal.logMoveTransition = function() end
dofile(ROOT .. "PNC_PathService/PNC_PathService_Lane.lua")
lane.phase = "idle"
local intentState = PNC.PathService.Internal.consumeMoveIntent(
    record,
    lane,
    body
)
assertEqual(intentState, "vehicle_blocked",
    "same vehicle-blocked goal remains quarantined")
assertEqual(lane.phase, "idle", "quarantined goal does not restart lane")

vehicleBlocking = false
intentState = PNC.PathService.Internal.consumeMoveIntent(
    record,
    lane,
    body
)
assertEqual(intentState, "requested", "goal released after vehicle moved")
assertEqual(lane.phase, "requested", "released goal restarts lane")
assertEqual(lane.vehicleBlockedGoalX, nil, "vehicle quarantine cleared")

lane.phase = "active"
lane.lastStepAt = 777
record.runtime.moveIntent.x = 9.5
record.runtime.moveIntent.navigationPolicy = "travel"
record.runtime.moveIntent.navigationProvider = "local_path"
record.runtime.moveIntent.waypointIndex = 2
record.runtime.moveIntent.steeringIndex = 3
intentState = PNC.PathService.Internal.consumeMoveIntent(
    record,
    lane,
    body
)
assertEqual(
    intentState,
    "retargeted",
    "adjacent local waypoint retarget"
)
assertEqual(lane.goal.x, 9.5, "active lane adopted new waypoint")
assertEqual(
    lane.lastStepAt,
    777,
    "continuous retarget reset movement cadence"
)
assertEqual(lane.steeringIndex, 3, "look-ahead index captured")

print("pnc_vehicle_pathing_smoke: ok")
