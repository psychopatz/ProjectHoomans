local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")

PNC = {
    Const = {},
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

T.load(ROOT .. "PNC_LiveBodyControl.lua")
T.load(ROOT .. "PNC_VehicleAvoidance.lua")
T.load(ROOT .. "PNC_TraversalQuery.lua")

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

T.equal(
    PNC.LiveBodyControl.SetAuthoritativePosition(body, 10.25, 11.5, 0),
    true,
    "authoritative position accepted"
)
T.equal(position.x, 10.25, "body x")
T.equal(position.y, 11.5, "body y")
T.equal(position.z, 0, "body z")
T.equal(lastPosition.x, position.x, "last x synchronized")
T.equal(lastPosition.y, position.y, "last y synchronized")
T.equal(lastPosition.z, position.z, "last z synchronized")

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
local cell = {
    getGridSquare = function(_, x)
        return x == 1 and vehicleSquare or clearSquare
    end,
}
getCell = function() return cell end

T.equal(
    PNC.TraversalQuery.CanOccupy(0.5, 0.5, 0, cell),
    true,
    "clear square remains walkable"
)
T.equal(
    PNC.TraversalQuery.CanOccupy(1.5, 0.5, 0, cell),
    false,
    "vehicle footprint blocks NPC occupancy"
)
T.equal(
    PNC.TraversalQuery.GetOccupancyReason(1.5, 0.5, 0, cell),
    "vehicle",
    "vehicle occupancy reason"
)
local safeX, safeY, safeZ, recoveryReason =
    PNC.TraversalQuery.FindNearestOccupable(1.5, 0.5, 0, 4, cell)
T.equal(safeX, 0.5, "nearest safe recovery x")
T.equal(safeY, 0.5, "nearest safe recovery y")
T.equal(safeZ, 0, "nearest safe recovery z")
T.equal(recoveryReason, "vehicle", "nearest safe recovery reason")
local canStep, stepReason = PNC.TraversalQuery.CanStep(
    0.5,
    0.5,
    0,
    1.5,
    0.5,
    0,
    cell
)
T.equal(canStep, false, "route does not enter exact vehicle footprint")
T.equal(stepReason, "vehicle", "exact vehicle reason")
canStep, stepReason = PNC.TraversalQuery.CanStep(
    2.5,
    0.5,
    0,
    3.5,
    0.5,
    0,
    cell
)
T.equal(canStep, true, "route may pass near vehicle clearance")
T.equal(stepReason, "clear", "nearby vehicle is not a clearance block")

local windowObject = {
    isDestroyed = function() return false end,
    IsOpen = function() return false end,
}
local windowFromSquare = makeSquare(false)
local windowVehicleSquare = makeSquare(true)
windowFromSquare.getWindowTo = function() return windowObject end
local windowCell = {
    getGridSquare = function(_, x)
        return x == 4 and windowVehicleSquare or windowFromSquare
    end,
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
T.equal(canStep, false, "vehicle landing blocks window traversal")
T.equal(stepReason, "vehicle", "vehicle wins over window interaction")

PNC.LocomotionProfiles = {
    GetBaseProfile = function()
        return { speed = 1, moveAnim = "Walk" }
    end,
}
T.load(ROOT .. "PNC_FakeLocomotion.lua")

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
T.equal(moved, true, "clear fake-locomotion step")
T.equal(authoritativeWrites, 1, "fake locomotion uses safe authoritative writer")
T.equal(lastPosition.x, position.x, "fake locomotion synchronizes last x")

PNC.PathService = { Internal = {} }
PNC.Registry = {
    MarkDirty = function(_, domain)
        PNC._dirtyDomain = domain
    end,
}
T.load(ROOT .. "PNC_PathService/PNC_PathService_Context.lua")
PNC._dirtyDomain = nil
PNC._lastWarning = nil
PNC._warningCount = 0
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
T.equal(repaired, false, "vehicle contact is not forcibly relocated")
T.equal(repairedReason, "vehicle", "vehicle contact remains observable")
T.equal(position.x, 1.5, "vehicle position remains engine-owned")
T.equal(record.x, 1.5, "record is not rewritten by vehicle contact")
T.equal(record.runtime.positionRecovery, nil, "vehicle contact has no recovery metadata")
T.equal(PNC._dirtyDomain, nil, "vehicle contact is not persisted as recovery")
T.equal(lane.phase, "active", "vehicle contact does not cancel lane")

PNC.PathService.Internal.logMoveTransition = function() end
T.load(ROOT .. "PNC_PathService/PNC_PathService_Lane.lua")
lane.phase = "idle"
local intentState = PNC.PathService.Internal.consumeMoveIntent(
    record,
    lane,
    body
)
T.equal(intentState, "requested", "same goal remains restartable")
T.equal(lane.phase, "requested", "vehicle contact does not quarantine goal")

lane.phase = "active"
lane.lastStepAt = 777
record.runtime.moveIntent.x = 9.5
record.runtime.moveIntent.navigationPolicy = "travel"
record.runtime.moveIntent.navigationProvider = "engine_path"
record.runtime.moveIntent.waypointIndex = 2
record.runtime.moveIntent.steeringIndex = 3
intentState = PNC.PathService.Internal.consumeMoveIntent(
    record,
    lane,
    body
)
T.equal(
    intentState,
    "retargeted",
    "adjacent local waypoint retarget"
)
T.equal(lane.goal.x, 9.5, "active lane adopted new waypoint")
T.equal(
    lane.lastStepAt,
    777,
    "continuous retarget reset movement cadence"
)
T.equal(lane.steeringIndex, 3, "look-ahead index captured")
lane.lastGoalProgressAt = 100
lane.lastPhysicalMoveAt = 0
local stalledRetarget = PNC.PathService.Internal.retargetLaneGoal(
    record,
    lane,
    { x = 10.5, y = 10.5, z = 0, mode = "walk", stopDistance = 0.7 }
)
T.equal(stalledRetarget, true, "stalled route accepts a follow retarget")
T.equal(lane.lastGoalProgressAt, 100,
    "follow retarget does not hide a native physical stall")
T.finish("pnc_vehicle_pathing_smoke")

T.finish("pnc_vehicle_pathing_smoke")
