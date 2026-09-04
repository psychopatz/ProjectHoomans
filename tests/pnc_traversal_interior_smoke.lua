local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local queryFile = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_TraversalQuery.lua"
local policyFile = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/Interactions/"
    .. "PNC_PathService_PassagePolicy.lua"
local windowsFile = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/Interactions/"
    .. "PNC_PathService_PassageWindows.lua"
local campFile = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Behaviors/PNC_Behavior_AtCamp.lua"

local function square(x, y, indoor)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        isInARoom = function() return indoor end,
    }
end

local outside = square(0, 0, false)
local inside = square(1, 0, true)
local anchor = square(5, 0, true)
local outdoorGoal = square(5, 0, false)
local squares = {
    ["5:0:0"] = anchor,
    ["6:0:0"] = outdoorGoal,
}

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
        end,
    }
end

PNC = {
    TraversalQuery = {},
    PathService = { Internal = {} },
}
T.load(queryFile)
T.load(policyFile)

T.equal(PNC.TraversalQuery.GetInteriorState(inside), true,
    "indoor state")
T.equal(PNC.TraversalQuery.GetInteriorState(outside), false,
    "outdoor state")
T.equal(PNC.TraversalQuery.IsInteriorBoundary(inside, outside), true,
    "boundary state")
T.equal(PNC.TraversalQuery.IsInteriorBoundary({}, outside), nil,
    "unknown boundary state")
T.equal(PNC.TraversalQuery.AreSameInteriorContext(inside, outside), false,
    "indoor and outdoor squares are not the same context")

local playerRoomA = {}
local playerRoomB = {}
local playerInsideA = square(7, 0, true)
local playerInsideB = square(8, 0, true)
playerInsideA.getIsoWorldRegion = function() return playerRoomA end
playerInsideB.getIsoWorldRegion = function() return playerRoomB end
T.equal(PNC.TraversalQuery.AreSameInteriorContext(
    playerInsideA,
    playerInsideB
), false, "player-built room regions remain distinct")

local context = {
    record = {
        activeBehavior = "AtCamp:returning",
        orderSpec = { kind = "camp" },
    },
    lane = { intentReason = "camp_anchor" },
    goalX = 5.5,
    goalY = 0.5,
    goalZ = 0,
    cell = getCell(),
    actorSquare = inside,
}
local window = {
    getSquare = function() return inside end,
    getOppositeSquare = function() return outside end,
}

local blocked, reason = PNC.PathService.Internal.isCampIndoorBoundary(
    context,
    window
)
T.equal(blocked, true, "indoor camp exit blocked")
T.equal(reason, "camp_indoor_boundary", "indoor camp block reason")

context.actorSquare = outside
blocked = PNC.PathService.Internal.isCampIndoorBoundary(context, window)
T.equal(blocked, false, "indoor camp entry allowed")

context.actorSquare = inside
context.goalX = 6.5
blocked = PNC.PathService.Internal.isCampIndoorBoundary(context, window)
T.equal(blocked, false, "outdoor goal does not block")

local ownerSquareForFollow = anchor
local followOwner = {
    getSquare = function() return ownerSquareForFollow end,
}
PNC.BehaviorCommon = {
    GetOwner = function() return followOwner end,
}
context.record = {
    activeJob = "FollowOwner",
    activeBehavior = "FollowOwner:moving",
    orderSpec = { kind = "follow" },
}
context.lane = { intentReason = "follow_owner_walk" }
context.goalX = 5.5
blocked, reason = PNC.PathService.Internal.isInteriorBoundaryBlocked(
    context,
    window
)
T.equal(blocked, true, "follow-owner indoor exit blocked")
T.equal(reason, "follow_owner_indoor_boundary",
    "follow-owner indoor block reason")

context.actorSquare = outside
blocked = PNC.PathService.Internal.isInteriorBoundaryBlocked(context, window)
T.equal(blocked, false, "follow-owner indoor entry allowed")

ownerSquareForFollow = outdoorGoal
context.actorSquare = inside
blocked = PNC.PathService.Internal.isInteriorBoundaryBlocked(context, window)
T.equal(blocked, false, "follow-owner follows an owner leaving indoors")
ownerSquareForFollow = anchor

PNC.PathService.Internal.describeSquare = function(squareValue)
    return tostring(squareValue:getX()) .. ":"
        .. tostring(squareValue:getY()) .. ":"
        .. tostring(squareValue:getZ())
end
PNC.PathService.Internal.logMoveDebug = function() end
instanceof = function(_, className) return className == "IsoWindow" end
T.load(windowsFile)
context.actorSquare = inside
context.zombie = {
    getX = function() return 1.5 end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
    isFacingObject = function() return true end,
}
context.blockedPassage = window
local handled, _, decided = PNC.PathService.Internal.tryWindowPassageCandidate(
    context,
    window,
    { x = inside:getX(), y = inside:getY(), z = inside:getZ() }
)
T.equal(handled, false, "follow-owner window exit is not executed")
T.equal(decided, true, "follow-owner window exit is decisively rejected")

local moved = false
local held = false
PNC.BehaviorCommon = {
    ClearCombatTarget = function() end,
    MoveRecord = function() moved = true end,
    HaltMovement = function() held = true end,
}
PNC.Core = {
    Distance = function(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1
        return math.sqrt((dx * dx) + (dy * dy))
    end,
}
PNC.Const = {
    CAMP_RADIUS = 3,
    CAMP_STOP_DISTANCE = 0.45,
    CAMP_ENGAGE_RADIUS = 3,
}
T.load(campFile)

local campRecord = {
    x = 5.5,
    y = 0.5,
    z = 0,
    orderSpec = { kind = "camp", x = 5.5, y = 0.5, z = 0, radius = 3 },
}
local campBody = {
    getCurrentSquare = function() return outside end,
}
PNC.BehaviorAtCamp.Tick(campRecord, campBody)
T.equal(moved, true, "outdoor body keeps returning to indoor camp")
T.equal(held, false, "outdoor body is not settled at indoor camp")

T.finish("pnc_traversal_interior_smoke")
