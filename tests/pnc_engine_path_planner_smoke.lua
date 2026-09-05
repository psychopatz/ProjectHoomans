local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_EnginePathPlanner.lua"
local PLANNER_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_EnginePathPlanner/"
local CONTEXT_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_EnginePathPlanner_Context.lua"
local CONTEXT_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_EnginePathPlanner_Context/"
local MOTION_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/PNC_PathService_Motion.lua"
local MOTION_PUMP_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/Motion/PNC_PathService_MotionPump.lua"
local MOTION_NATIVE_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/Motion/PNC_PathService_MotionNative.lua"
local MOTION_NATIVE_PROGRESS_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/Motion/PNC_PathService_MotionNativeProgress.lua"
local BODY_CONTROL_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_LiveBodyControl.lua"
local BODY_CONTROL_EVENTS_FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Events.lua"
local SERVER_FILE =
    T.path("ProjectHoomans", "server", "PNC/")
    .. "Server/PNC_Server.lua"

local now = 5000
local outside = {}
local inside = {}
local outsideSquare = {
    getBuilding = function() return nil end,
    getRoom = function() return nil end,
}
local insideSquare = {
    getBuilding = function() return inside end,
    getRoom = function() return inside end,
}
local squares = {
    ["0:0"] = outsideSquare,
    ["5:0"] = insideSquare,
}

getCell = function()
    return {
        getGridSquare = function(_, x, y)
            return squares[tostring(x) .. ":" .. tostring(y)]
        end,
    }
end

getNumClassFields = function()
    error("debug-only reflection must not be used")
end
getClassField = getNumClassFields
getClassFieldVal = getNumClassFields

PNC = {
    Core = {
        Now = function() return now end,
    },
    Const = {
        ENGINE_PATH_REQUEST_BUDGET_WINDOW_MS = 100,
        ENGINE_PATH_REQUEST_BUDGET_PER_WINDOW = 1,
        ENGINE_PATH_REQUEST_TIMEOUT_MS = 2500,
        ENGINE_PATH_ROUTE_TIMEOUT_MS = 15000,
        ENGINE_PATH_REPLAN_MS = 1000,
        ENGINE_PATH_TARGET_REPLAN_DISTANCE = 1.5,
        ENGINE_PATH_MIN_ROUTE_DISTANCE = 1.0,
    },
}
BehaviorResult = {
    Working = "Working",
    Failed = "Failed",
    Succeeded = "Succeeded",
}

T.load(CONTEXT_FILE)
T.load(FILE)

local requestCount = 0
local wrapperRequestCount = 0
local cancelCount = 0
local resetCount = 0
local updateCount = 0
local nextResult = BehaviorResult.Working
local nextActionState = nil
local body
local selectedPath = {}
local publishPath = false
local serverMode = false
isServer = function() return serverMode end
ZombieIdleState = {
    instance = function()
        return { name = "idle" }
    end,
}
local behavior = {
    pathToLocation = function(self, x, y, z)
        self.target = { x = x, y = y, z = z }
        -- The real Behavior2 request can leave the legacy WalkTowardState
        -- active while it publishes path2. The planner must reclaim it in
        -- the same request frame, but not before path2 exists.
        if publishPath then body.path2 = selectedPath end
        body.actionState = "walktoward"
        requestCount = requestCount + 1
    end,
    update = function()
        updateCount = updateCount + 1
        if nextActionState then
            body.actionState = nextActionState
            nextActionState = nil
        end
        return nextResult
    end,
    cancel = function() cancelCount = cancelCount + 1 end,
    reset = function() resetCount = resetCount + 1 end,
}
local forwardDirection = {
    getX = function() return 1 end,
    getY = function() return 0 end,
}
body = {
    x = 0.5,
    y = 0.5,
    z = 0,
    square = outsideSquare,
    path2 = nil,
    useless = true,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getSquare = function(self) return self.square end,
    getForwardDirection = function() return forwardDirection end,
    getPathFindBehavior2 = function() return behavior end,
    getPath2 = function(self) return self.path2 end,
    setPath2 = function(self, path) self.path2 = path end,
    pathToLocationF = function(self, x, y, z)
        wrapperRequestCount = wrapperRequestCount + 1
        self.actionState = "pathfind"
    end,
    getActionStateName = function(self)
        return self.actionState or "idle"
    end,
    changeState = function(self, state)
        self.actionState = state and state.name or "idle"
    end,
    isUseless = function(self) return self.useless end,
    setUseless = function(self, value) self.useless = value == true end,
    isCollidedWithDoor = function(self)
        return self.collidedWithDoor == true
    end,
    isCollidedThisFrame = function(self)
        return self.collidedThisFrame == true
    end,
    isCollided = function(self) return self.collided == true end,
}
local record = {
    runtime = {
        pathing = { phase = "requested" },
    },
}
local target = {
    x = 5.5,
    y = 0.5,
    z = 0,
    mode = "walk",
    stopDistance = 0.65,
}

local function pathSquare(x, y)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
    }
end
local pathSquare0 = pathSquare(0, 10)
local pathSquare1 = pathSquare(1, 10)
local pathSquare2 = pathSquare(2, 10)
squares["0:10"] = pathSquare0
squares["1:10"] = pathSquare1
squares["2:10"] = pathSquare2
local pathFence = {}
local pathBody = {
    getX = function() return 0.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
    getSquare = function() return pathSquare0 end,
    getForwardDirection = function() return forwardDirection end,
    getPath2 = function() return selectedPath end,
}
PNC.TraversalQuery = {
    GetPassageBetween = function() return nil end,
    GetFenceBetween = function(from, to)
        if from == pathSquare0 and to == pathSquare1 then
            return pathFence, false
        end
        return nil, false
    end,
}
local passageNavigation = { requestX = 3.5, requestY = 10.5 }
local upcomingPassage =
    PNC.EnginePathPlanner.Internal.GetUpcomingPathPassage(
        pathBody,
        passageNavigation
    )
T.truthy(upcomingPassage and upcomingPassage.object == pathFence,
    "native approach did not expose its immediate fence edge")
local passageRecord = { runtime = { pathing = {} } }
T.truthy(PNC.EnginePathPlanner.Internal.StageUpcomingPathPassage(
        passageRecord,
        pathBody,
        passageNavigation
    ),
    "nearby native fence edge did not transfer to scripted ownership")
T.truthy(passageRecord.runtime.pathing.blockedStepReason
        == "native_path_fence",
    "native fence handoff lost its exact blocked edge")
PNC.TraversalQuery = nil

-- A route can be available immediately after pathToLocation(). Intercept its
-- obstacle before the first Behavior2 update; otherwise Java may enter the
-- unsafe vanilla fence state before Lua regains control.
local preUpdateCount = 0
local preHandoffCount = 0
local preBody
local preBehavior = {
    pathToLocation = function()
        preBody.path2 = selectedPath
    end,
    update = function()
        preUpdateCount = preUpdateCount + 1
        return BehaviorResult.Working
    end,
    cancel = function() end,
    reset = function() end,
}
preBody = {
    x = 0.5,
    y = 10.5,
    z = 0,
    square = pathSquare0,
    useless = true,
    getX = body.getX,
    getY = body.getY,
    getZ = body.getZ,
    getSquare = body.getSquare,
    getForwardDirection = body.getForwardDirection,
    getPath2 = body.getPath2,
    setPath2 = body.setPath2,
    getPathFindBehavior2 = function() return preBehavior end,
    getActionStateName = function() return "idle" end,
    isUseless = body.isUseless,
    setUseless = body.setUseless,
}
local preRecord = {
    runtime = { pathing = { phase = "active" } },
}
PNC.TraversalQuery = {
    GetPassageBetween = function() return nil end,
    GetFenceBetween = function(from, to)
        if from == pathSquare0 and to == pathSquare1 then
            return pathFence, false
        end
        return nil, false
    end,
}
PNC.PathService = {
    AdvanceScriptedPassage = function()
        preHandoffCount = preHandoffCount + 1
        return true, "fence_climb"
    end,
}
now = now + 200
PNC.EnginePathPlanner.GetSteeringTarget(preRecord, preBody, {
    x = 3.5,
    y = 10.5,
    z = 0,
    stopDistance = 0.5,
})
T.truthy(preHandoffCount == 1,
    "upcoming native fence was not handed off before Behavior2 update")
T.truthy(preUpdateCount == 0,
    "Behavior2 entered an obstacle before scripted traversal handoff")
PNC.PathService = nil
PNC.TraversalQuery = nil
now = now + 200

local steering = PNC.EnginePathPlanner.GetSteeringTarget(
    record,
    body,
    target
)
T.truthy(steering == target, "waiting move lane changed the target")
T.truthy(requestCount == 0, "path was requested before move lane startup")

record.runtime.pathing.phase = "active"
steering = PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
T.truthy(steering == target, "pending native request changed the target")
T.truthy(requestCount == 1, "building transition did not request native path")
T.equal(body.actionState, "walktoward",
    "native request changed follow before a native route was published")
T.truthy(updateCount == 0,
    "Bandits-style request advanced PathFindBehavior2 during startup")
T.truthy(wrapperRequestCount == 0,
    "single-player request entered the character PathFindState wrapper")

PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
T.truthy(requestCount == 1, "pending request was submitted twice")
local handled
local state
local cancelsAfterStart = cancelCount
local resetsAfterStart = resetCount
handled, state = PNC.EnginePathPlanner.Pump(
    record,
    body
)
T.truthy(not handled and state == "native_waiting_for_zombie_update",
    "scheduled observer advanced the single-player native lane")
T.truthy(updateCount == 0,
    "scheduled observer double-pumped PathFindBehavior2")
T.truthy(body.useless == true,
    "single-player Behavior2 route exposed the body to IsoZombie.update")
T.truthy(cancelCount == cancelsAfterStart
    and resetCount == resetsAfterStart,
    "working native path was cancelled or reset")

body.actionState = "turnalerted"
T.equal(
    PNC.EnginePathPlanner.Internal.EnsureNativeMovementOwner(body),
    false,
    "native owner claimed the removed turn-alerted action"
)
T.equal(body.actionState, "turnalerted",
    "native owner changed the vanilla turn-alerted state")
body.actionState = "idle"

body.actionState = "walktoward"
body.path2 = nil
T.equal(
    PNC.EnginePathPlanner.Internal.EnsureNativeMovementOwner(body),
    false,
    "native owner cleared follow before a native route was published"
)
T.equal(body.actionState, "walktoward",
    "native owner changed follow while path2 was unavailable")
body.path2 = selectedPath
T.equal(
    PNC.EnginePathPlanner.Internal.EnsureNativeMovementOwner(body),
    true,
    "native owner did not release stale WalkTowardState after path2 publish"
)
T.equal(body.actionState, "idle",
    "native owner did not release the published native route state")

local suppressedCount = 0
PNC.LiveBodyControl = {
    IsSuppressedActionState = function(actionState)
        return actionState == "turnalerted" or actionState == "pathfind"
    end,
    SuppressZombieState = function(suppressedBody)
        suppressedCount = suppressedCount + 1
        suppressedBody.actionState = "idle"
        suppressedBody:setUseless(true)
    end,
}
body.path2 = nil
body.actionState = "pathfind"
nextActionState = "pathfind"
now = now + 16
handled, state = PNC.EnginePathPlanner.Pump(
    record,
    body,
    "zombie_update"
)
T.truthy(handled, "native route did not survive path startup")
T.equal(suppressedCount, 0,
    "native planner reset path startup before a route was published")
T.equal(body.actionState, "pathfind",
    "native planner changed the vanilla startup state without path2")

body.path2 = selectedPath
body.actionState = "pathfind"
now = now + 16
handled, state = PNC.EnginePathPlanner.Pump(
    record,
    body,
    "zombie_update"
)
T.truthy(handled, "native route did not survive a published path")
T.equal(suppressedCount, 1,
    "native planner did not repair the published pathfind conflict")
T.equal(body.actionState, "idle",
    "published pathfind conflict was not released")

suppressedCount = 0
body.actionState = "turnalerted"
nextActionState = "turnalerted"
now = now + 16
handled, state = PNC.EnginePathPlanner.Pump(
    record,
    body,
    "zombie_update"
)
T.truthy(handled, "native route did not survive a suppressed state")
T.equal(body.actionState, "turnalerted",
    "native planner changed the removed turn-alerted state")
T.equal(suppressedCount, 0,
    "native planner still suppressed the removed turn-alerted state")

now = now + 1000
local movedTarget = {
    x = 7.1,
    y = target.y,
    z = target.z,
    mode = target.mode,
    stopDistance = target.stopDistance,
}
-- Replanning can encounter a stale vanilla WalkTowardState after a previous
-- task or animation update. The native owner must release it before Behavior2
-- can publish path2 again.
body.actionState = "walktoward"
publishPath = true
local requestsBeforeMovingReplan = requestCount
PNC.EnginePathPlanner.GetSteeringTarget(
    record,
    body,
    movedTarget
)
T.truthy(requestCount == requestsBeforeMovingReplan + 1,
    "moving target did not trigger a bounded native replan")
T.equal(body.actionState, "idle",
    "native replan left the vanilla WalkTowardState active")

body.x = movedTarget.x
body.y = movedTarget.y
handled, state = PNC.EnginePathPlanner.Pump(
    record,
    body,
    "zombie_update"
)
T.truthy(handled and state == "engine_path_succeeded",
    "native path success was not consumed")
T.truthy(cancelCount >= 2 and resetCount >= 2,
    "native behavior was not released after success")
T.truthy(not record.runtime.localNavigation.nativeActive,
    "native movement ownership was not released")
publishPath = false
body.x = 0.5
body.y = 0.5
body.actionState = "idle"

now = now + 2000
nextResult = BehaviorResult.Working
PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
body.actionState = "idle"
now = now + 2500
handled, state = PNC.EnginePathPlanner.Pump(
    record,
    body,
    "zombie_update"
)
T.truthy(handled and state == "engine_path_timeout",
    "engine path-state exit did not release movement ownership")

now = now + 2000
nextResult = BehaviorResult.Working
PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
local updatesBeforeTimeout = updateCount
now = now + 15000
record.runtime.localNavigation.lastBehaviorUpdateAt = now
handled, state = PNC.EnginePathPlanner.Pump(
    record,
    body,
    "zombie_update"
)
T.truthy(handled and state == "engine_path_timeout",
    "non-progressing native route did not time out")
T.truthy(updateCount == updatesBeforeTimeout,
    "timed-out native path was updated again")

local directRecord = { runtime = {} }
local directBody = {
    x = 0.5,
    y = 0.5,
    z = 0,
    square = outsideSquare,
    getX = body.getX,
    getY = body.getY,
    getZ = body.getZ,
    getSquare = body.getSquare,
    getPathFindBehavior2 = body.getPathFindBehavior2,
    pathToLocationF = body.pathToLocationF,
    getPath2 = function() return nil end,
    setPath2 = function() end,
}
squares["3:0"] = outsideSquare
now = now + 200
local directTarget = { x = 3.5, y = 0.5, z = 0 }
steering = PNC.EnginePathPlanner.GetSteeringTarget(
    directRecord,
    directBody,
    directTarget
)
T.truthy(steering == directTarget, "open-ground target changed")
T.truthy(
    directRecord.runtime.localNavigation.lastPlanReason
        == "native_waiting_for_move_lane",
    "open-ground native route did not wait for lane startup"
)
directRecord.runtime.pathing = { phase = "active" }
local requestsBeforeOpenRoute = requestCount
PNC.EnginePathPlanner.GetSteeringTarget(
    directRecord,
    directBody,
    directTarget
)
T.truthy(requestCount == requestsBeforeOpenRoute + 1,
    "meaningful open-ground movement did not use native pathing")

local unsafeRequestCount = requestCount
local unsafeBody = {
    x = 0.5,
    y = 0.5,
    z = 0,
    square = outsideSquare,
    getX = body.getX,
    getY = body.getY,
    getZ = body.getZ,
    getSquare = body.getSquare,
    getPathFindBehavior2 = body.getPathFindBehavior2,
    getPath2 = body.getPath2,
    setPath2 = body.setPath2,
    pathToLocationF = body.pathToLocationF,
    getActionStateName = body.getActionStateName,
    getBodyDamage = function() return nil end,
}
local unsafeRecord = {
    runtime = { pathing = { phase = "active" } },
}
now = now + 200
PNC.EnginePathPlanner.GetSteeringTarget(
    unsafeRecord,
    unsafeBody,
    directTarget
)
T.truthy(requestCount == unsafeRequestCount + 1,
    "body without BodyDamage did not enter native pathing")
T.truthy(unsafeRecord.runtime.localNavigation.controllerMode
        == "behavior2_move",
    "single-player body did not select Bandits Move ownership")

local closeRecord = {
    runtime = {
        pathing = { phase = "active" },
    },
}
local closeTarget = {
    x = 1.2,
    y = 0.5,
    z = 0,
    stopDistance = 0.3,
}
local requestsBeforeCloseAdjustment = requestCount
now = now + 200
PNC.EnginePathPlanner.GetSteeringTarget(
    closeRecord,
    directBody,
    closeTarget
)
T.truthy(requestCount == requestsBeforeCloseAdjustment + 1,
    "sub-tile adjustment did not stay on native movement")

local plannerSource = T.read(FILE)
    .. T.read(CONTEXT_FILE)
    .. T.read(CONTEXT_ROOT .. "PNC_EnginePathPlanner_Context_State.lua")
    .. T.read(CONTEXT_ROOT .. "PNC_EnginePathPlanner_Context_Passage.lua")
    .. T.read(CONTEXT_ROOT .. "PNC_EnginePathPlanner_Context_NativeState.lua")
    .. T.read(CONTEXT_ROOT .. "PNC_EnginePathPlanner_Context_AuthorityLease.lua")
    .. T.read(CONTEXT_ROOT .. "PNC_EnginePathPlanner_Context_RequestCleanup.lua")
    .. T.read(CONTEXT_ROOT .. "PNC_EnginePathPlanner_Context_RoutePolicy.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_Passage.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_Request.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_Steering.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_PumpTraversal.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_PumpProgress.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_Pump.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_Frames.lua")
    .. T.read(PLANNER_ROOT .. "PNC_EnginePathPlanner_Lifecycle.lua")
T.truthy(not string.find(plannerSource, "pcall", 1, true),
    "native planner must not hide path errors with pcall")
T.truthy(not string.find(plannerSource, "getClassField", 1, true),
    "native planner depends on debug-only Java reflection")
T.truthy(not string.find(plannerSource, "not path.size", 1, true)
        and not string.find(plannerSource, "not path.getNode", 1, true),
    "native planner probes Java Path methods as Lua table fields")
T.truthy(not string.find(plannerSource, "path:size", 1, true)
        and not string.find(plannerSource, "path:crossesSquare", 1, true)
        and not string.find(plannerSource, "path:getNode", 1, true),
    "native planner calls opaque zombie.pathfind.Path userdata")
T.truthy(string.find(plannerSource, "behavior:update(", 1, true),
    "single-player planner does not use Bandits PathFindBehavior2 Move")
local pumpSource = T.read(MOTION_PUMP_FILE)
local nativeSource = T.read(MOTION_NATIVE_FILE)
local nativeProgressSource = T.read(MOTION_NATIVE_PROGRESS_FILE)
local motionSource = T.read(MOTION_FILE)
    .. pumpSource .. nativeSource .. nativeProgressSource
T.truthy(string.find(motionSource, "combat_attack_lease", 1, true),
    "combat attack lease does not cancel native movement")
local nativePumpAt = T.truthy(string.find(
    pumpSource,
    "Internal.updateNativeMove",
    1,
    true
))
local scriptedPassageAt = T.truthy(string.find(
    pumpSource,
    "ownsScriptedPassage",
    1,
    true
))
local fakePumpAt = T.truthy(string.find(
    pumpSource,
    "Internal.updateActiveMove",
    nativePumpAt + 1,
    true
))
T.truthy(scriptedPassageAt < nativePumpAt,
    "native path can reacquire ownership before scripted traversal")
T.truthy(nativePumpAt < fakePumpAt,
    "ordinary fake locomotion runs before native path ownership")
T.truthy(string.find(pumpSource, "engine_path_waiting", 1, true),
    "deferred native lane can still fall through to fake locomotion")
T.truthy(string.find(nativeProgressSource,
        "Internal.MotionHints.Remember", 1, true),
    "native movement does not publish interpolation hints")
T.truthy(string.find(nativeSource,
        "Internal.refreshResolvedLocomotion", 1, true),
    "native movement does not refresh locomotion animation")
local bodyControlSource = T.read(BODY_CONTROL_FILE)
    .. T.read(BODY_CONTROL_EVENTS_FILE)
T.truthy(string.find(
        bodyControlSource,
        "PNC.EnginePathPlanner.PumpFrame(record, zombie)",
        1,
        true
    ),
    "native route following is not coupled to OnZombieUpdate")

PNC.Core.IsAuthority = function() return false end
local updatesBeforeClientFrame = updateCount
handled, state = PNC.EnginePathPlanner.PumpFrame(record, body)
T.truthy(not handled and state == "client_replica",
    "client replica was allowed to own native path movement")
T.truthy(updateCount == updatesBeforeClientFrame,
    "client replica advanced the authoritative native path")

PNC.Core.IsAuthority = function() return true end
now = now + 2000
record.runtime.pathing.phase = "active"
nextResult = BehaviorResult.Working
local nativeFrameProgressCalls = 0
PNC.PathService = {
    Internal = {
        recordNativeMove = function(_, _, _, _, _, _, nativeState)
            nativeFrameProgressCalls = nativeFrameProgressCalls + 1
            return true, nativeState
        end,
    },
}
PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
local updatesBeforeFrame = updateCount
now = now + 16
handled, state = PNC.EnginePathPlanner.PumpFrame(record, body)
T.truthy(handled and state == "native_behavior_pending",
    "authoritative frame lost Bandits-style native movement")
T.truthy(updateCount == updatesBeforeFrame + 1,
    "zombie frame did not advance PathFindBehavior2 exactly once")
T.equal(nativeFrameProgressCalls, 1,
    "authoritative frame did not record native progress after its single pump")
local collisionHandoffCount = 0
PNC.PathService = {
    AdvanceScriptedPassage = function()
        collisionHandoffCount = collisionHandoffCount + 1
        return true, "fence_climb"
    end,
}
body.collidedThisFrame = true
local updatesBeforeCollision = updateCount
now = now + 16
handled, state = PNC.EnginePathPlanner.PumpFrame(record, body)
T.truthy(handled and state == "fence_climb",
    "native collision was not handed to scripted traversal")
T.truthy(collisionHandoffCount == 1,
    "native collision did not pump the path service exactly once")
T.truthy(updateCount == updatesBeforeCollision,
    "Behavior2 advanced after collision instead of yielding traversal")
body.collidedThisFrame = false
PNC.PathService = nil
local updatesAfterFrame = updateCount
handled, state = PNC.EnginePathPlanner.Pump(record, body)
T.truthy(not handled and state == "native_waiting_for_zombie_update",
    "scheduled observer advanced the single-player native lane")
T.truthy(updateCount == updatesAfterFrame,
    "observer pump manually advanced PathFindBehavior2")

nextResult = BehaviorResult.Failed
now = now + 16
PNC.PathService = {
    Internal = {
        recordNativeMove = function(_, _, _, _, _, _, nativeState)
            nativeFrameProgressCalls = nativeFrameProgressCalls + 1
            return true, nativeState
        end,
    },
}
handled, state = PNC.EnginePathPlanner.PumpFrame(record, body)
T.truthy(handled and state == "engine_path_failed",
    "Bandits-style behavior failure did not release native ownership")
T.truthy(not record.runtime.localNavigation.nativeActive,
    "failed PathFindBehavior2 retained movement ownership")
T.truthy(body.useless == true,
    "failed native route did not restore managed-body safety")
T.equal(nativeFrameProgressCalls, 2,
    "terminal native result skipped the frame progress handoff")

serverMode = true
now = now + 2000
nextResult = BehaviorResult.Working
local characterRequestCount = 0
local serverBody = {
    x = 0.5,
    y = 0.5,
    z = 0,
    square = outsideSquare,
    path2 = nil,
    useless = true,
    getX = body.getX,
    getY = body.getY,
    getZ = body.getZ,
    getSquare = body.getSquare,
    getPathFindBehavior2 = body.getPathFindBehavior2,
    getPath2 = body.getPath2,
    setPath2 = body.setPath2,
    getActionStateName = body.getActionStateName,
    isUseless = body.isUseless,
    setUseless = body.setUseless,
    pathToLocationF = function(self, x, y, z)
        characterRequestCount = characterRequestCount + 1
        behavior:pathToLocationF(x, y, z)
    end,
}
local serverRecord = {
    runtime = {
        pathing = { phase = "active" },
    },
}
-- Exhaust the SP A* budget deliberately. MP authority only publishes a goal,
-- so this must not defer client-native ownership or expose fake locomotion.
PNC.EnginePathPlanner.RequestBudget.windowStartedAt = now
PNC.EnginePathPlanner.RequestBudget.used =
    PNC.Const.ENGINE_PATH_REQUEST_BUDGET_PER_WINDOW
PNC.EnginePathPlanner.GetSteeringTarget(
    serverRecord,
    serverBody,
    target
)
T.truthy(characterRequestCount == 0,
    "dedicated server started a competing native path controller")
T.truthy(serverBody.useless == false,
    "multiplayer native route did not retain its movement lease")
T.truthy(serverRecord.runtime.localNavigation.serverMovementLease == true,
    "multiplayer native movement lease was not recorded")
T.truthy(serverRecord.runtime.localNavigation.clientDelegated == true,
    "multiplayer path goal was deferred by the SP request budget")
T.truthy(serverRecord.runtime.localNavigation.requestX == target.x
        and serverRecord.runtime.localNavigation.requestY == target.y,
    "delegated multiplayer path lost its target")
local updatesBeforeServerFrame = updateCount
T.truthy(PNC.EnginePathPlanner.PumpServerFrame() == 1,
    "server tick did not find the active native route")
T.truthy(updateCount == updatesBeforeServerFrame,
    "server tick advanced the client-owned PathFindBehavior2")
PNC.EnginePathPlanner.PumpFrame(serverRecord, serverBody)
T.truthy(serverBody.useless == false,
    "multiplayer frame pump dropped the active movement lease")
now = now + 16
nextResult = BehaviorResult.Succeeded
handled, state =
    PNC.EnginePathPlanner.PumpFrame(serverRecord, serverBody)
T.truthy(handled and state == "client_native_moving",
    "server did not remain an observer of delegated movement")
T.truthy(serverBody.useless == false,
    "multiplayer body became useless during delegated movement")
PNC.EnginePathPlanner.Clear(serverRecord, serverBody)
T.truthy(
    serverRecord.runtime.localNavigation == nil,
    "cleared multiplayer route retained navigation state"
)
T.truthy(PNC.EnginePathPlanner.PumpServerFrame() == 0,
    "cleared delegated route remained in the active server set")
serverMode = false

local serverSource = T.read(SERVER_FILE)
    .. T.read(
        T.path("ProjectHoomans", "server", "PNC/")
            .. "Server/Server/PNC_Server_SubsystemPumps.lua"
    )
T.truthy(string.find(
        serverSource,
        "\"PumpServerFrame\"",
        1,
        true
    ),
    "server tick does not advance native routes when OnZombieUpdate is absent")
T.finish("pnc_engine_path_planner_smoke")

T.finish("pnc_engine_path_planner_smoke")
