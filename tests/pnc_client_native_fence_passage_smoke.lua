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
local window = {}
local passageKind = "fence"
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
local bumpOptions
local climbDirection
local leases = 0
local holdRequests = 0
local pathClears = 0
local movementResetCalls = 0
local zombieStateSuppressions = 0
local localController = true
local approachReady = true
local landingReady = true

PNC = {
    TraversalQuery = {
        FindPassageToward = function()
            if passageKind == "window" then
                return {
                    object = window,
                    fromSquare = fromSquare,
                    toSquare = toSquare,
                }
            end
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
        IsWindow = function(object)
            return object == window
        end,
        IsFenceApproachReady = function() return approachReady end,
        CanTraverseAt = function() return landingReady end,
    },
    PathService = { Internal = {} },
    Animation = {
        PlayBump = function(_, _, value, options)
            bumpType = value
            bumpOptions = options
            return true
        end,
        FinishBump = function() return true end,
    },
    LiveBodyControl = {
        ResetNativeMovementState = function()
            movementResetCalls = movementResetCalls + 1
        end,
        SuppressZombieState = function()
            zombieStateSuppressions = zombieStateSuppressions + 1
        end,
        SetManagedBodyUseless = function(_, requestedUseless)
            if requestedUseless == true then
                holdRequests = holdRequests + 1
            end
            return false
        end,
        SetAuthoritativePosition = function(_, x, y, z)
            position.x, position.y, position.z = x, y, z
            return true
        end,
    },
    ClientPresenceSync = { Internal = {
        IsLocalZombieController = function() return localController end,
        NativePathController = {
            ClearOwnedPath = function()
                pathClears = pathClears + 1
                return true
            end,
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
    changeState = function()
        error("managed window traversal entered a vanilla state")
    end,
}

window.IsOpen = function() return true end
window.canClimbThrough = function() return true end
window.getSquare = function() return fromSquare end
window.getOppositeSquare = function() return toSquare end

T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Internal.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/TraversalQuery/PNC_TraversalQuery_Fences.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Pathing/PNC_TraversalAction.lua")
T.load("ProjectHoomans", "client",
    "PNC/PresenceSync/ClientNativePathController/"
        .. "PNC_ClientNativePathController_Passage.lua")

PNC.TraversalQuery.IsFenceApproachReady = function()
    return approachReady
end
PNC.TraversalQuery.CanTraverseAt = function()
    return landingReady
end

local Controller = PNC.ClientPresenceSync.Internal.NativePathController
T.equal(
    Controller.UpdatePassageAction,
    Controller.UpdateWindowSmash,
    "legacy passage update entry lost its compatibility alias"
)
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

-- Preflight failures through the passage router must not take path or
-- movement ownership or start an animation.
local rejectedState = { marker = "untouched" }
approachReady = false
local rejected, rejectReason = Controller.TryNativePassage(
    { id = "fence-approach-not-ready" }, body, rejectedState,
    { x = 3.5, y = 0.5, z = 0 }, 900)
T.falsy(rejected, "fence approach failure was reported as handled")
T.equal(rejectReason, "native_fence_not_ready",
    "fence approach failure reason changed")
T.equal(rejectedState.passageAction, nil,
    "fence approach failure created a passage action")
T.equal(rejectedState.marker, "untouched",
    "fence approach failure changed unrelated state")
T.equal(pathClears, 0, "fence approach failure cleared the path")
T.equal(movementResetCalls, 0,
    "fence approach failure reset native movement")
T.equal(zombieStateSuppressions, 0,
    "fence approach failure suppressed zombie state")
T.equal(bumpType, nil, "fence approach failure started an animation")
T.equal(holdRequests, 0, "fence approach failure held the body")

approachReady = true
landingReady = false
rejectedState = { marker = "untouched" }
rejected, rejectReason = Controller.TryNativePassage(
    { id = "fence-landing-blocked" }, body, rejectedState,
    { x = 3.5, y = 0.5, z = 0 }, 950)
T.falsy(rejected, "blocked fence landing was reported as handled")
T.equal(rejectReason, "native_fence_landing_blocked",
    "blocked fence landing reason changed")
T.equal(rejectedState.passageAction, nil,
    "blocked fence landing created a passage action")
T.equal(rejectedState.marker, "untouched",
    "blocked fence landing changed unrelated state")
T.equal(pathClears, 0, "blocked fence landing cleared the path")
T.equal(movementResetCalls, 0,
    "blocked fence landing reset native movement")
T.equal(zombieStateSuppressions, 0,
    "blocked fence landing suppressed zombie state")
T.equal(bumpType, nil, "blocked fence landing started an animation")
T.equal(holdRequests, 0, "blocked fence landing held the body")
landingReady = true

-- Both fence types use the same transfer-point traversal. Low fences retain
-- their existing two-phase raise/cross animation sequence.
local state = {}
local handled, reason = Controller.TryNativePassage(
    { id = "small-fence-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 1000)
T.truthy(handled, "small fence was not intercepted")
T.equal(reason, "native_fence_climb", "small fence traversal reason")
T.equal(pathClears, 1, "small fence did not clear its owned path")
T.equal(movementResetCalls, 1,
    "small fence did not reset native movement")
T.equal(zombieStateSuppressions, 1,
    "small fence did not suppress a stale zombie state")
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
T.equal(state.passageAction.transitionSettleMs, 0,
    "small fence added an artificial transition pause")

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
T.truthy(holdRequests >= 2,
    "small fence manual movement ownership was not refreshed")

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
bumpOptions = nil
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

-- Open-window traversal must use the PNC-owned action/position contract. The
-- vanilla ClimbThroughWindowState assumes player BodyDamage and is invalid for
-- an IsoZombie carrier.
passageKind = "window"
position.x, position.y, position.z = 0.5, 0.23, 0
actionState = "pathfind"
state = {}
bumpType = nil
handled, reason = Controller.TryNativePassage(
    { id = "window-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 5000)
T.truthy(handled, "open window was not intercepted")
T.equal(reason, "native_window_climb", "window traversal reason")
T.equal(bumpType, "PNC_ClimbWindow", "window did not select the PNC clip")
T.equal(
    bumpOptions.keepManagedUseless,
    false,
    "native window climb incorrectly selected fake-body usefulness"
)
T.equal(state.passageAction.kind, "window_climb",
    "window traversal did not create a PNC action")
T.equal(state.passageAction.toX, 1.5,
    "window traversal did not target the opposite square")

handled, reason = Controller.UpdateWindowSmash(body, state, 5750)
T.truthy(handled, "window climb released before its animation tail")
T.equal(reason, "native_window_climb", "window climb midpoint reason")
T.equal(position.x, 1.5, "window climb did not reach its landing point")

handled, reason = Controller.UpdateWindowSmash(body, state, 6101)
T.truthy(handled, "window climb did not complete")
T.equal(reason, "native_window_crossed", "window climb completion reason")
T.equal(state.passageAction, nil, "window climb action did not clear")
handled, reason = Controller.TryNativePassage(
    { id = "window-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 6200)
T.truthy(handled, "window repeat was not suppressed")
T.equal(reason, "native_window_cooldown",
    "window repeat cooldown reason")

-- A nearest-client ownership change must release the active passage before
-- the local replica applies another native movement step.
position.x, position.y, position.z = 0.5, 0.23, 0
actionState = "pathfind"
state = {}
handled, reason = Controller.TryNativePassage(
    { id = "owner-change-window" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 6300)
T.truthy(handled, "owner-change window was not started")
localController = false
handled, reason = Controller.UpdatePassageAction(body, state, 6400)
T.falsy(handled, "non-owner client continued the passage action")
T.equal(reason, "native_passage_owner_changed",
    "ownership transfer reason changed")
T.equal(state.passageAction, nil,
    "ownership transfer did not clear the active passage")
localController = true

-- A landing may be known to be occupied before the climb, but it can also
-- become blocked during the animation. Keep the latter completion-path
-- repair assertion below.
PNC.TraversalQuery.CanTraverseAt = function() return true end
position.x, position.y, position.z = 0.5, 0.23, 0
state = {}
handled, reason = Controller.TryNativePassage(
    { id = "blocked-window-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 7000)
T.truthy(handled, "blocked window was not attempted")
PNC.TraversalQuery.CanTraverseAt = function() return false end
handled, reason = Controller.UpdateWindowSmash(body, state, 8050)
T.truthy(handled, "blocked window was not repaired")
T.equal(reason, "native_window_landing_repaired",
    "blocked window did not report a repaired landing")
T.equal(state.passageAction, nil,
    "blocked window repair did not clear the passage action")
T.equal(state.windowRetryObject, window,
    "blocked window repair did not defer the same edge")
handled, reason = Controller.TryNativePassage(
    { id = "blocked-window-npc" }, body, state,
    { x = 3.5, y = 0.5, z = 0 }, 8100)
T.falsy(handled, "blocked window was retried during its repair backoff")
PNC.TraversalQuery.CanTraverseAt = function() return true end

T.finish("pnc_client_native_fence_passage_smoke")
