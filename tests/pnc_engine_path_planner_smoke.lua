local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_EnginePathPlanner.lua"
local CONTEXT_FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_EnginePathPlanner_Context.lua"
local MOTION_FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_PathService/PNC_PathService_Motion.lua"
local BODY_CONTROL_FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_LiveBodyControl.lua"
local SERVER_FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/server/PNC/"
    .. "PNC_Server.lua"

local function readAll(path)
    local handle = assert(io.open(path, "rb"))
    local value = handle:read("*a")
    handle:close()
    return value
end

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

dofile(CONTEXT_FILE)
dofile(FILE)

local requestCount = 0
local cancelCount = 0
local resetCount = 0
local updateCount = 0
local nextResult = BehaviorResult.Working
local updateSawUsefulBody = false
local body
local serverMode = false
isServer = function() return serverMode end
local behavior = {
    pathToLocationF = function(self, x, y, z)
        self.target = { x = x, y = y, z = z }
        requestCount = requestCount + 1
    end,
    update = function()
        updateCount = updateCount + 1
        updateSawUsefulBody = body and body.useless == false
        return nextResult
    end,
    cancel = function() cancelCount = cancelCount + 1 end,
    reset = function() resetCount = resetCount + 1 end,
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
    getPathFindBehavior2 = function() return behavior end,
    getPath2 = function(self) return self.path2 end,
    setPath2 = function(self, path) self.path2 = path end,
    getActionStateName = function(self)
        return self.actionState or "idle"
    end,
    isUseless = function(self) return self.useless end,
    setUseless = function(self, value) self.useless = value == true end,
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

local steering = PNC.EnginePathPlanner.GetSteeringTarget(
    record,
    body,
    target
)
assert(steering == target, "waiting move lane changed the target")
assert(requestCount == 0, "path was requested before move lane startup")

record.runtime.pathing.phase = "active"
steering = PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
assert(steering == target, "pending native request changed the target")
assert(requestCount == 1, "building transition did not request native path")
assert(updateCount == 0,
    "native request bypassed the single native update pump")

PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
assert(requestCount == 1, "pending request was submitted twice")
local handled
local state
local cancelsAfterStart = cancelCount
local resetsAfterStart = resetCount
handled, state = PNC.EnginePathPlanner.Pump(record, body)
assert(handled and state == "native_path_pending",
    "native path did not remain active while working")
assert(updateSawUsefulBody,
    "native path update ran while the managed body was useless")
assert(updateCount == 1, "native path request was not started")
assert(body.useless == true,
    "native path update did not restore the managed-body safety flag")
assert(cancelCount == cancelsAfterStart
    and resetCount == resetsAfterStart,
    "working native path was cancelled or reset")

now = now + 1000
local movedTarget = {
    x = 7.1,
    y = target.y,
    z = target.z,
    mode = target.mode,
    stopDistance = target.stopDistance,
}
local requestsBeforeMovingReplan = requestCount
PNC.EnginePathPlanner.GetSteeringTarget(
    record,
    body,
    movedTarget
)
assert(requestCount == requestsBeforeMovingReplan + 1,
    "moving target did not trigger a bounded native replan")

nextResult = BehaviorResult.Succeeded
handled, state = PNC.EnginePathPlanner.Pump(record, body)
assert(handled and state == "engine_path_succeeded",
    "native path success was not consumed")
assert(cancelCount >= 2 and resetCount >= 2,
    "native behavior was not released after success")
assert(not record.runtime.localNavigation.nativeActive,
    "native movement ownership was not released")

now = now + 2000
nextResult = BehaviorResult.Working
PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
nextResult = BehaviorResult.Failed
handled, state = PNC.EnginePathPlanner.Pump(record, body)
assert(handled and state == "engine_path_failed",
    "native path failure did not release movement ownership")

now = now + 2000
nextResult = BehaviorResult.Working
PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
local updatesBeforeTimeout = updateCount
now = now + 2500
handled, state = PNC.EnginePathPlanner.Pump(record, body)
assert(handled and state == "engine_path_timeout",
    "native path timeout did not release movement ownership")
assert(updateCount == updatesBeforeTimeout,
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
assert(steering == directTarget, "open-ground target changed")
assert(
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
assert(requestCount == requestsBeforeOpenRoute + 1,
    "meaningful open-ground movement did not use native pathing")

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
PNC.EnginePathPlanner.GetSteeringTarget(
    closeRecord,
    directBody,
    closeTarget
)
assert(requestCount == requestsBeforeCloseAdjustment,
    "sub-tile adjustment launched a native path request")

local plannerSource = readAll(FILE) .. readAll(CONTEXT_FILE)
assert(not string.find(plannerSource, "pcall", 1, true),
    "native planner must not hide path errors with pcall")
assert(not string.find(plannerSource, "getClassField", 1, true),
    "native planner depends on debug-only Java reflection")
local motionSource = readAll(MOTION_FILE)
assert(string.find(motionSource, "combat_attack_lease", 1, true),
    "combat attack lease does not cancel native movement")
local pumpSource = assert(string.match(
    motionSource,
    "function PathService%.Pump.-\nend\n\nfunction PathService%.AdvanceAbstract"
))
local nativePumpAt = assert(string.find(
    pumpSource,
    "enginePlanner.Pump",
    1,
    true
))
local fakePumpAt = assert(string.find(
    pumpSource,
    "Internal.updateActiveMove",
    1,
    true
))
assert(nativePumpAt < fakePumpAt,
    "fake locomotion runs before native path ownership")
assert(string.find(pumpSource, "Internal.MotionHints.Remember", 1, true),
    "native movement does not publish interpolation hints")
assert(string.find(pumpSource, "Internal.refreshResolvedLocomotion", 1, true),
    "native movement does not refresh locomotion animation")
local bodyControlSource = readAll(BODY_CONTROL_FILE)
assert(string.find(
        bodyControlSource,
        "PNC.EnginePathPlanner.PumpFrame(record, zombie)",
        1,
        true
    ),
    "native route following is not coupled to OnZombieUpdate")

PNC.Core.IsAuthority = function() return false end
local updatesBeforeClientFrame = updateCount
handled, state = PNC.EnginePathPlanner.PumpFrame(record, body)
assert(not handled and state == "client_replica",
    "client replica was allowed to own native path movement")
assert(updateCount == updatesBeforeClientFrame,
    "client replica advanced the authoritative native path")

PNC.Core.IsAuthority = function() return true end
now = now + 2000
record.runtime.pathing.phase = "active"
nextResult = BehaviorResult.Working
PNC.EnginePathPlanner.GetSteeringTarget(record, body, target)
handled, state = PNC.EnginePathPlanner.PumpFrame(record, body)
assert(handled and state == "native_path_pending",
    "authoritative zombie-frame pump did not advance native movement")
local updatesAfterFrame = updateCount
handled, state = PNC.EnginePathPlanner.Pump(record, body)
assert(handled and state == "native_path_pending",
    "scheduled fallback lost native ownership after frame pump")
assert(updateCount == updatesAfterFrame,
    "scheduled fallback double-pumped a zombie-frame native route")

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
assert(characterRequestCount == 0,
    "dedicated server started a competing native path controller")
assert(serverBody.useless == false,
    "multiplayer native route did not retain its movement lease")
assert(serverRecord.runtime.localNavigation.serverMovementLease == true,
    "multiplayer native movement lease was not recorded")
assert(serverRecord.runtime.localNavigation.clientDelegated == true,
    "multiplayer path goal was deferred by the SP request budget")
assert(serverRecord.runtime.localNavigation.requestX == target.x
        and serverRecord.runtime.localNavigation.requestY == target.y,
    "delegated multiplayer path lost its target")
local updatesBeforeServerFrame = updateCount
assert(PNC.EnginePathPlanner.PumpServerFrame() == 1,
    "server tick did not find the active native route")
assert(updateCount == updatesBeforeServerFrame,
    "server tick advanced the client-owned PathFindBehavior2")
PNC.EnginePathPlanner.PumpFrame(serverRecord, serverBody)
assert(serverBody.useless == false,
    "multiplayer frame pump dropped the active movement lease")
now = now + 16
nextResult = BehaviorResult.Succeeded
handled, state =
    PNC.EnginePathPlanner.PumpFrame(serverRecord, serverBody)
assert(handled and state == "client_native_moving",
    "server did not remain an observer of delegated movement")
assert(serverBody.useless == false,
    "multiplayer body became useless during delegated movement")
PNC.EnginePathPlanner.Clear(serverRecord, serverBody)
assert(
    serverRecord.runtime.localNavigation == nil,
    "cleared multiplayer route retained navigation state"
)
assert(PNC.EnginePathPlanner.PumpServerFrame() == 0,
    "cleared delegated route remained in the active server set")
serverMode = false

local serverSource = readAll(SERVER_FILE)
assert(string.find(
        serverSource,
        "PNC.EnginePathPlanner.PumpServerFrame()",
        1,
        true
    ),
    "server tick does not advance native routes when OnZombieUpdate is absent")

print("pnc_engine_path_planner_smoke: ok")
