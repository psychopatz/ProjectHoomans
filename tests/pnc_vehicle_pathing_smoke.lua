local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Pathing/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

PNC = {
    Core = {
        Now = function() return 1000 end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        LogWarn = function(message)
            PNC._lastWarning = message
        end,
        LogRecordDebug = function() end,
    },
}

dofile(ROOT .. "PNC_LiveBodyControl.lua")
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
local vehicleSquare = makeSquare(true)
local cell = {
    getGridSquare = function(_, x)
        return x == 1 and vehicleSquare or clearSquare
    end,
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
    runtime = {},
}
lane = {}
local repaired, repairedReason =
    PNC.PathService.Internal.repairInvalidBodyPosition(record, body, lane, 2000)
assertEqual(repaired, true, "live vehicle position repaired")
assertEqual(repairedReason, "vehicle", "live repair reason")
assertEqual(position.x, 0.5, "live repair destination x")
assertEqual(record.x, position.x, "live repair record x")
assertEqual(record.runtime.forceSyncEvent, "position_recovery", "live repair multiplayer sync")
assertEqual(record.runtime.positionRecovery.lastEvent, "live_unstuck", "live repair metadata")
assertEqual(PNC._dirtyDomain, "position_recovery", "live repair persisted")
assert(
    string.find(PNC._lastWarning or "", "event=live_unstuck", 1, true),
    "live repair warning was not logged"
)

print("pnc_vehicle_pathing_smoke: ok")
