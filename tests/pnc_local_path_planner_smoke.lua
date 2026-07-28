local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_LocalPathPlanner.lua"

local now = 0
local squares = {}
local moved

local function square(x, y)
    local id = tostring(x) .. ":" .. tostring(y)
    if not squares[id] then
        local building = x == 3 and y >= 1 and y <= 7
        squares[id] = {
            x = x,
            y = y,
            getBuilding = function()
                return building and {} or nil
            end,
            getRoom = function()
                return building and {} or nil
            end,
        }
    end
    return squares[id]
end

local cell = {
    getGridSquare = function(_, x, y)
        if x < 0 or y < 0 or x > 12 or y > 12 then return nil end
        return square(x, y)
    end,
}
getCell = function() return cell end

PNC = {
    Const = {
        LOCAL_PATH_LOOKAHEAD_TILES = 14,
        LOCAL_PATH_SEARCH_RADIUS = 10,
        LOCAL_PATH_MAX_NODES = 500,
        LOCAL_PATH_INTERIOR_PENALTY = 10,
        LOCAL_PATH_LAST_RESORT_DELAY_MS = 15000,
        LOCAL_PATH_LAST_RESORT_COOLDOWN_MS = 20000,
        LOCAL_PATH_LAST_RESORT_RADIUS = 4,
    },
    Core = {
        Now = function() return now end,
        LogWarn = function() end,
    },
    TraversalQuery = {
        CanStep = function(_, _, _, toX, toY)
            return cell:getGridSquare(math.floor(toX), math.floor(toY)) ~= nil
        end,
        CanOccupy = function(x, y)
            return cell:getGridSquare(math.floor(x), math.floor(y)) ~= nil
        end,
    },
    LiveBodyControl = {
        SetAuthoritativePosition = function(body, x, y, z)
            body.x = x
            body.y = y
            body.z = z
            moved = true
        end,
    },
}

dofile(FILE)

local path = assert(PNC.LocalPathPlanner.Plan(1.5, 4.5, 0, 7.5, 4.5, 0))
assert(#path > 0, "local planner returned an empty path")
for _, point in ipairs(path) do
    assert(not (math.floor(point.x) == 3
        and math.floor(point.y) >= 1
        and math.floor(point.y) <= 7),
        "local planner cut through the building")
end

local body = {
    x = 1.5,
    y = 4.5,
    z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    setX = function(self, value) self.x = value end,
    setY = function(self, value) self.y = value end,
    setZ = function(self, value) self.z = value end,
}
local originalPlan = PNC.LocalPathPlanner.Plan
local originalCanStep = PNC.TraversalQuery.CanStep
local planCalls = 0
PNC.TraversalQuery.CanStep = function()
    return false, "wall"
end
PNC.LocalPathPlanner.Plan = function(...)
    planCalls = planCalls + 1
    return originalPlan(...)
end
local throttledRecord = {
    id = "throttled",
    runtime = {},
    x = body.x,
    y = body.y,
    z = body.z,
}
now = 1000
PNC.LocalPathPlanner.GetSteeringTarget(
    throttledRecord,
    body,
    { x = 10.5, y = 4.5, z = 0 },
    { allowRecovery = false }
)
now = 1100
PNC.LocalPathPlanner.GetSteeringTarget(
    throttledRecord,
    body,
    { x = 10.5, y = 4.5, z = 0 },
    { allowRecovery = false }
)
assert(planCalls == 1, "failed route was replanned before its interval")
local nearBlockedRecord = {
    id = "near_blocked",
    runtime = {},
    x = body.x,
    y = body.y,
    z = body.z,
}
now = 1200
PNC.LocalPathPlanner.GetSteeringTarget(
    nearBlockedRecord,
    body,
    { x = 3.5, y = 4.5, z = 0 },
    { allowRecovery = false }
)
assert(
    planCalls == 2,
    "nearby blocked goal bypassed local route planning"
)
PNC.LocalPathPlanner.Plan = originalPlan
PNC.TraversalQuery.CanStep = originalCanStep

body.x = 1.5
body.y = 8.5
local smoothRecord = {
    id = "smooth_route",
    runtime = {
        localNavigation = {
            signature = "10:8:0",
            plannedAt = 1300,
            lastProgressAt = 1300,
            path = {
                { x = 2.5, y = 8.5, z = 0 },
                { x = 3.5, y = 8.5, z = 0 },
                { x = 4.5, y = 8.5, z = 0 },
                { x = 5.5, y = 8.5, z = 0 },
            },
            index = 1,
            planStartX = 1.5,
            planStartY = 8.5,
        },
    },
}
now = 1400
local smoothTarget = PNC.LocalPathPlanner.GetSteeringTarget(
    smoothRecord,
    body,
    { x = 10.5, y = 8.5, z = 0 },
    { allowRecovery = false }
)
assert(
    smoothTarget.steeringIndex == 2
        and smoothTarget.x == 3.5,
    "open route did not use a forward look-ahead waypoint"
)

body.x = 2.1
now = 1450
smoothTarget = PNC.LocalPathPlanner.GetSteeringTarget(
    smoothRecord,
    body,
    { x = 10.5, y = 8.5, z = 0 },
    { allowRecovery = false }
)
assert(
    smoothRecord.runtime.localNavigation.index == 2,
    "reached waypoint was not advanced continuously"
)
assert(
    smoothTarget.steeringIndex >= 3,
    "look-ahead did not move forward after waypoint advancement"
)

body.x = 1.5
body.y = 9.5
local traversalRecord = {
    id = "precise_traversal",
    runtime = {
        localNavigation = {
            signature = "10:9:0",
            plannedAt = 1400,
            lastProgressAt = 1400,
            path = {
                { x = 2.5, y = 9.5, z = 0 },
                {
                    x = 3.5,
                    y = 9.5,
                    z = 0,
                    traversalKind = "door_open",
                },
                { x = 4.5, y = 9.5, z = 0 },
            },
            index = 1,
            planStartX = 1.5,
            planStartY = 9.5,
        },
    },
}
now = 1500
local traversalTarget = PNC.LocalPathPlanner.GetSteeringTarget(
    traversalRecord,
    body,
    { x = 10.5, y = 9.5, z = 0 },
    { allowRecovery = false }
)
assert(
    traversalTarget.x == 3.5
        and traversalTarget.traversalKind == "door_open",
    "route look-ahead skipped a precision traversal waypoint"
)

local record = { id = "stuck", runtime = {}, x = 1.5, y = 4.5, z = 0 }
local navigation = { lastProgressAt = 0, lastRecoveryAt = 0 }
now = 14000
assert(not PNC.LocalPathPlanner.TryLastResortRecovery(
    record,
    body,
    { x = 10.5, y = 4.5, z = 0 },
    navigation,
    now
), "last-resort recovery ran before its delay")
now = 16000
assert(PNC.LocalPathPlanner.TryLastResortRecovery(
    record,
    body,
    { x = 10.5, y = 4.5, z = 0 },
    navigation,
    now
), "last-resort recovery did not run after a sustained stall")
assert(moved == true and record.runtime.positionRecovery.lastEvent
    == "travel_last_resort", "last-resort recovery was not recorded")

print("pnc_local_path_planner_smoke: ok")
