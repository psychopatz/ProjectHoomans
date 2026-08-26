local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

IsoDirections = {
    N = "N",
    S = "S",
    E = "E",
    W = "W",
}

local fenceTall = false
local zombieX = 0.5
local actionState = "pathfind"
local climbDirection

local fromSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getObjects = function()
        return { size = function() return 0 end }
    end,
}
local toSquare = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getObjects = function()
        return { size = function() return 0 end }
    end,
}
local fence = { getSquare = function() return fromSquare end }
local cell = {
    getGridSquare = function(_, x)
        if x == 0 then return fromSquare end
        if x == 1 then return toSquare end
        return nil
    end,
}

getCell = function() return cell end
instanceof = function() return false end

local capturedSpec
local notedKind
PNC = {
    TraversalQuery = {
        GetPassageBetween = function() return fence end,
        FindPassageToward = function() return nil end,
        IsDoor = function() return false end,
        GetFenceBetween = function() return fence, fenceTall end,
        IsFenceApproachReady = function() return true end,
        GetFenceTransferPoint = function(_, _, x, y)
            return x + 1, y
        end,
    },
    TraversalProfiles = {
        Resolve = function()
            return {
                anim = "FenceLow",
                startAnim = "FenceStart",
                endAnim = "FenceEnd",
                upDurationMs = 420,
                crossingDurationMs = 560,
                finishHoldMs = 320,
                travelDurationMs = 600,
            }
        end,
    },
    PathService = { Internal = {} },
    LiveBodyControl = {
        IsMultiplayer = function() return false end,
        SetManagedBodyUseless = function() return false end,
    },
}

local Internal = PNC.PathService.Internal
Internal.Core = {
    Now = function() return 1000 end,
    Distance = function(x1, y1, x2, y2)
        local dx = x2 - x1
        local dy = y2 - y1
        return math.sqrt((dx * dx) + (dy * dy))
    end,
}
Internal.SPECIAL_ACTION_COOLDOWN_MS = 500
Internal.describeSquare = function(square)
    return tostring(square:getX()) .. "," .. tostring(square:getY())
end
Internal.describePoint = function(x, y, z)
    return tostring(x) .. "," .. tostring(y) .. "," .. tostring(z)
end
Internal.logMoveDebug = function() end
Internal.roundHalf = function(value)
    if value > 0.25 then return 1 end
    if value < -0.25 then return -1 end
    return 0
end
Internal.isRepeatedTraversalAttempt = function() return false end
Internal.beginTraversalAction = function(_, _, _, spec)
    capturedSpec = spec
    return true
end
Internal.noteTraversalAttempt = function(_, kind)
    notedKind = kind
end

local zombie = {
    getX = function() return zombieX end,
    getY = function() return 0.5 end,
    getZ = function() return 0 end,
    getSquare = function()
        return zombieX < 1 and fromSquare or toSquare
    end,
    getActionStateName = function() return actionState end,
    climbOverFence = function(_, direction)
        climbDirection = direction
        actionState = "climbfence"
    end,
    getForwardDirection = function()
        return { getX = function() return 1 end,
            getY = function() return 0 end }
    end,
    isCollidedWithDoor = function() return false end,
}
local lane = {
    blockedStepFromX = 0.5,
    blockedStepFromY = 0.5,
    blockedStepFromZ = 0,
    blockedStepToX = 1.5,
    blockedStepToY = 0.5,
    blockedStepToZ = 0,
    goalRevision = 4,
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions.lua")

local handled, reason = Internal.tryDoorOrWindowInteraction(
    zombie, { id = "fence-test" }, lane, 3.5, 0.5, 0
)
T.truthy(handled, "blocked fence interaction was not handled")
T.equal(reason, "fence_climb", "blocked fence interaction reason")
T.equal(capturedSpec.kind, "fence_climb", "small fence action kind")
T.equal(capturedSpec.anim, "FenceLow", "small fence profile animation")
T.equal(capturedSpec.startAnim, "FenceStart",
    "small fence start animation")
T.equal(capturedSpec.endAnim, "FenceEnd",
    "small fence end animation")
T.equal(capturedSpec.transitionSettleMs, 0,
    "small fence added an artificial transition pause")
T.equal(capturedSpec.toX, 1.5, "small fence landing x")
T.equal(capturedSpec.toY, 0.5, "small fence landing y")
T.equal(notedKind, "fence_climb", "fence attempt tracking")

-- Tall fences retain the same custom transfer action.
fenceTall = true
zombieX = 0.5
actionState = "pathfind"
capturedSpec = nil
local tallLane = {
    blockedStepFromX = 0.5,
    blockedStepFromY = 0.5,
    blockedStepFromZ = 0,
    blockedStepToX = 1.5,
    blockedStepToY = 0.5,
    blockedStepToZ = 0,
    goalRevision = 5,
}
handled, reason = Internal.tryDoorOrWindowInteraction(
    zombie, { id = "tall-fence-test" }, tallLane, 3.5, 0.5, 0
)
T.truthy(handled, "tall fence interaction was not handled")
T.equal(reason, "fence_climb", "tall fence interaction reason")
T.equal(capturedSpec.kind, "fence_climb", "tall fence action kind")
T.equal(capturedSpec.toX, 1.5, "tall fence landing x")
T.equal(capturedSpec.toSquare, toSquare, "tall fence landing square")

T.truthy(Internal.shouldSuppressSpecialAction(
    lane, lane.lastSpecialActionKey, 1499
), "special-action cooldown ended early")
T.falsy(Internal.shouldSuppressSpecialAction(
    lane, lane.lastSpecialActionKey, 1500
), "special-action cooldown exceeded its boundary")

T.finish("pnc_fence_interaction_smoke")
