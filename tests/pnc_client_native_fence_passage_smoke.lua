local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
})

IsoDirections = {
    N = "N",
    S = "S",
    E = "E",
    W = "W",
}

local fence = {}
local fenceTall = false
local fromSquare = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local toSquare = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local position = { x = 0.5, y = 0.23, z = 0 }
local actionState = "pathfind"
local bumpType
local climbDirection
local leases = 0

PNC = {
    TraversalQuery = {
        FindPassageToward = function()
            return {
                object = fence,
                fromSquare = fromSquare,
                toSquare = toSquare,
                dirX = 1,
                dirY = 0,
            }
        end,
        IsFence = function(object)
            return object == fence, fenceTall
        end,
        IsFenceApproachReady = function() return true end,
        CanTraverseAt = function() return true end,
    },
    PathService = { Internal = {} },
    Animation = {
        PlayBump = function(_, _, value)
            bumpType = value
            return true
        end,
        FinishBump = function() return true end,
    },
    LiveBodyControl = {
        SetManagedBodyUseless = function() return false end,
        SetAuthoritativePosition = function(_, x, y, z)
            position.x, position.y, position.z = x, y, z
            return true
        end,
    },
    ClientPresenceSync = { Internal = {
        IsLocalZombieController = function() return true end,
        NativePathController = {
            ClearOwnedPath = function() return true end,
            BeginMovementLease = function()
                leases = leases + 1
                return true
            end,
            LogState = function() end,
            DescribeBody = function() return "body" end,
            STALL_TIMEOUT_MS = 2200,
            RETRY_BASE_MS = 180,
            WINDOW_SMASH_IMPACT_MS = 350,
            WINDOW_SMASH_FINISH_MS = 900,
        },
    } },
}

local body = {
    getX = function() return position.x end,
    getY = function() return position.y end,
    getZ = function() return position.z end,
    getSquare = function()
        return math.floor(position.x) == 0
            and fromSquare or toSquare
    end,
    getActionStateName = function() return actionState end,
    climbOverFence = function(_, direction)
        climbDirection = direction
        actionState = "climbfence"
    end,
    setLx = function() end,
    setLy = function() end,
    faceThisObject = function() end,
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Internal.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Fences.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_TraversalAction.lua")
T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/ClientNativePathController/"
        .. "PNC_ClientNativePathController_Passage.lua")

local Controller = PNC.ClientPresenceSync.Internal.NativePathController
local verticalFrom = {
    getX = function() return 4 end,
    getY = function() return 7 end,
    getZ = function() return 0 end,
}
local verticalTo = {
    getX = function() return 4 end,
    getY = function() return 8 end,
    getZ = function() return 0 end,
}
local verticalX, verticalY = PNC.TraversalQuery.GetFenceTransferPoint(
    verticalFrom, verticalTo, 4.27, 7.41
)
T.equal(verticalX, 4.27, "vertical fence transfer changed its lane")
T.equal(verticalY, 8.41, "vertical fence transfer did not cross one tile")

-- Both fence types use the same transfer-point traversal. Low fences retain
-- their existing two-phase raise/cross animation sequence.
local state = {}
local handled, reason = Controller.TryNativePassage(
    { id = "small-fence-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 1000)
T.truthy(handled, "small fence was not intercepted")
T.equal(reason, "native_fence_climb", "small fence traversal reason")
T.equal(bumpType, "PNC_LegacyClimbFenceStart",
    "small fence did not select the raise clip")
T.equal(state.passageAction.kind, "fence_climb",
    "small fence did not create a transfer action")
T.equal(state.passageAction.phase, "up",
    "small fence did not start in the raise phase")
T.equal(state.passageAction.toX, 1.5,
    "small fence did not cross exactly one tile")
T.equal(state.passageAction.toY, 0.23,
    "small fence transfer changed its lateral coordinate")

handled, reason = Controller.UpdateWindowSmash(body, state, 1200)
T.truthy(handled, "small fence was not held during the raise phase")
T.equal(reason, "native_fence_climb", "small fence midpoint reason")
T.equal(position.x, 0.5, "small fence moved before the crossing phase")

handled, reason = Controller.UpdateWindowSmash(body, state, 1700)
T.truthy(handled, "small fence crossing phase did not become pending")
handled, reason = Controller.UpdateWindowSmash(body, state, 1760)
T.truthy(handled, "small fence crossing phase did not start")
handled, reason = Controller.UpdateWindowSmash(body, state, 2000)
T.truthy(handled, "small fence crossing phase did not remain active")
T.truthy(position.x > 0.5 and position.x < 1.5,
    "small fence did not interpolate toward its landing point")

handled, reason = Controller.UpdateWindowSmash(body, state, 2601)
T.truthy(handled, "small fence landing was not completed")
T.equal(reason, "native_fence_crossed", "small fence landing reason")
T.equal(state.passageAction, nil, "small fence action did not clear")
T.equal(position.x, 1.5, "small fence did not reach the landing point")
T.truthy(leases >= 2, "small fence movement ownership was not refreshed")

handled, reason = Controller.TryNativePassage(
    { id = "small-fence-npc" }, body, state,
    { x = -3.5, y = 0.5, z = 0 }, 1400)
T.truthy(handled, "small fence cooldown was not honored")
T.equal(reason, "native_fence_cooldown", "small fence cooldown reason")

-- Tall fences retain the same lane-preserving transfer point with their
-- single-phase animation.
fenceTall = true
position.x, position.y, position.z = 0.5, 0.23, 0
actionState = "pathfind"
state = {}
bumpType = nil
handled, reason = Controller.TryNativePassage(
    { id = "tall-fence-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 3000)
T.truthy(handled, "tall fence was not intercepted")
T.equal(reason, "native_fence_climb", "tall fence reason")
T.equal(bumpType, "PNC_ClimbFenceTall", "tall fence scene changed")
T.equal(state.passageAction.phase, "single",
    "tall fence stopped using its scripted crossing")
T.equal(state.passageAction.toX, 1.5,
    "tall fence did not cross one tile")
T.equal(state.passageAction.toY, 0.23,
    "tall fence transfer changed its lane")

handled, reason = Controller.UpdateWindowSmash(body, state, 3901)
T.truthy(handled, "tall fence did not complete")
T.equal(reason, "native_fence_crossed", "tall fence completion reason")
T.equal(state.passageAction, nil, "tall fence action did not clear")
T.equal(position.x, 1.5, "tall fence did not reach the landing point")

T.finish("pnc_client_native_fence_passage_smoke")
