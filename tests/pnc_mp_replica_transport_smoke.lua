local BODY_CONTROL =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_LiveBodyControl.lua"
local CLIENT_TICK =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "PresenceSync/PNC_ClientPresenceTick.lua"
local CLIENT_INIT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "00_PNC_Client_Init.lua"
local CLIENT_CONTROLLER =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "PresenceSync/PNC_ClientNativePathController.lua"
local CLIENT_VISUALS =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
    .. "PresenceSync/PNC_ClientPresenceVisuals.lua"
local ANIMATION =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Visuals/PNC_Animation.lua"
local PATH_CONTEXT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_PathService/PNC_PathService_Context.lua"
local TRAVERSAL_RUNTIME =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua"

local function readAll(path)
    local handle = assert(io.open(path, "rb"))
    local value = handle:read("*a")
    handle:close()
    return value
end

local useless = true
local clientNow = 1000
local requestCount = 0
local updateCount = 0
local cancelCount = 0
local resetCount = 0
local bodyModData = {
    PNC_NPC = true,
    PNC_UUID = "remote_replica",
}
local behavior = {
    update = function()
        updateCount = updateCount + 1
        return "Working"
    end,
    cancel = function()
        cancelCount = cancelCount + 1
    end,
    reset = function()
        resetCount = resetCount + 1
    end,
}
local body = {
    x = 1,
    y = 1,
    z = 0,
    actionState = "idle",
    getModData = function()
        return bodyModData
    end,
    isUseless = function() return useless end,
    setUseless = function(_, value)
        useless = value == true
    end,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getPathFindBehavior2 = function()
        return behavior
    end,
    pathToLocationF = function(self, x, y, z)
        requestCount = requestCount + 1
        assert(x == 8 and y == 4 and z == 0,
            "delegated goal was altered")
        self.actionState = "pathfind"
    end,
    getActionStateName = function(self)
        return self.actionState
    end,
    setPath2 = function() end,
    setTarget = function(self, value)
        self.target = value
    end,
    setTargetSeenTime = function(self, value)
        self.targetSeenTime = value
    end,
    setEatBodyTarget = function(self, value)
        self.eatBodyTarget = value
    end,
    clearAggroList = function(self)
        self.aggroCleared = true
    end,
}

PNC = {
    Core = {
        IsAuthority = function() return false end,
        IsClientOnly = function() return true end,
        IsManagedNPCBody = function(candidate)
            return candidate == body
        end,
        Now = function() return clientNow end,
    },
}

isClient = function() return true end
isServer = function() return false end
getWorld = function()
    return {
        getGameMode = function()
            return "Multiplayer"
        end,
    }
end

local zombieUpdateHandlers = {}
local function runZombieUpdates(candidate)
    local index
    for index = 1, #zombieUpdateHandlers do
        zombieUpdateHandlers[index](candidate)
    end
end
Events = {
    OnZombieUpdate = {
        Add = function(handler)
            zombieUpdateHandlers[#zombieUpdateHandlers + 1] = handler
        end,
        Remove = function(handler)
            local index
            for index = #zombieUpdateHandlers, 1, -1 do
                if zombieUpdateHandlers[index] == handler then
                    table.remove(zombieUpdateHandlers, index)
                end
            end
        end,
    },
    OnGameStart = {
        Add = function() end,
        Remove = function() end,
    },
    OnServerStarted = {
        Add = function() end,
        Remove = function() end,
    },
}

dofile(BODY_CONTROL)

assert(
    PNC.LiveBodyControl.EnforceManagedSafety(
        body,
        "mp_replica_test"
    ) == true,
    "managed MP replica was not maintained"
)
assert(
    useless == true,
    "idle MP replica did not retain scripted/manual body mode"
)

PNC.ClientPresenceSync = {
    Internal = {
        LogClientMotionDebug = function() end,
    },
    NativePathStateByBody = {},
}
local localPlayer = {
    x = 0,
    y = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getOnlineID = function() return 1 end,
}
local remotePlayer = {
    x = 100,
    y = 100,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getOnlineID = function() return 2 end,
}
local players = {
    localPlayer,
    remotePlayer,
}
getSpecificPlayer = function() return localPlayer end
getOnlinePlayers = function()
    return {
        size = function() return #players end,
        get = function(_, index)
            return players[index + 1]
        end,
    }
end
BehaviorResult = {
    Working = "Working",
    Failed = "Failed",
    Succeeded = "Succeeded",
}

dofile(CLIENT_CONTROLLER)

local snapshot = {
    id = "remote_replica",
    liveBodyLease = 7,
    debugState = { debugEnabled = true },
    visualState = {
        moving = true,
        nativeMoveActive = true,
        nativeMoveX = 8,
        nativeMoveY = 4,
        nativeMoveZ = 0,
        nativeMoveRevision = 3,
    },
}
local handled
local state
assert(
    PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
        snapshot,
        body,
        clientNow
    ),
    "presence tick did not bind the delegated native goal"
)
assert(#zombieUpdateHandlers == 2,
    "native path controller was not registered on OnZombieUpdate")
body.target = localPlayer
body.targetSeenTime = 12
body.eatBodyTarget = localPlayer
body.aggroCleared = false
runZombieUpdates(body)
assert(requestCount == 1 and updateCount == 0,
    "nearest MP client did not start movement in zombie update context")
PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
    snapshot,
    body,
    clientNow + 16
)
runZombieUpdates(body)
assert(requestCount == 1,
    "unchanged delegated goal was submitted more than once")
assert(updateCount == 0,
    "client manually advanced engine-owned PathFindBehavior2")
assert(useless == false,
    "client controller disabled the body during movement")
assert(body.target == nil,
    "zombie target was not suppressed in the movement-owner frame")
assert(body.targetSeenTime == 0,
    "zombie target memory was not reset in the movement-owner frame")
assert(body.eatBodyTarget == nil,
    "zombie eating target was not suppressed in the movement-owner frame")
assert(body.aggroCleared == true,
    "zombie aggro was not suppressed in the movement-owner frame")

localPlayer.x = 200
localPlayer.y = 200
remotePlayer.x = 1
remotePlayer.y = 1
clientNow = 1300
runZombieUpdates(body)
assert(cancelCount == 1 and resetCount == 1,
    "controller handoff did not release the previous local path")

useless = true
bodyModData.PNC_BumpActionLease = true
bodyModData.PNC_BumpActionLeaseUntil = clientNow + 1000
PNC.ClientPresenceSync.NativePathStateByBody[body].owned = true
body.actionState = "pathfind"
local attackSnapshot = {
    id = snapshot.id,
    liveBodyLease = snapshot.liveBodyLease,
    visualState = {
        nativeMoveActive = true,
        attackActive = true,
        nativeMoveX = 8,
        nativeMoveY = 4,
        nativeMoveZ = 0,
        nativeMoveRevision = 3,
    },
}
assert(
    not PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
        attackSnapshot,
        body,
        clientNow + 16
    ),
    "attack snapshot retained a native path goal"
)
assert(cancelCount == 2 and resetCount == 2,
    "attack snapshot did not release delegated movement before PlayBump")
assert(useless == false,
    "attack action lease did not keep the MP action context active")
local requestsBeforeAttackUpdate = requestCount
runZombieUpdates(body)
assert(requestCount == requestsBeforeAttackUpdate,
    "MP zombie update started movement during the attack action lease")
assert(useless == false,
    "MP zombie update disabled the body during the attack action lease")

local postAttackMoveSnapshot = {
    id = snapshot.id,
    liveBodyLease = snapshot.liveBodyLease,
    visualState = {
        nativeMoveActive = true,
        attackActive = false,
        nativeMoveX = 8,
        nativeMoveY = 4,
        nativeMoveZ = 0,
        nativeMoveRevision = 4,
    },
}
assert(
    not PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
        postAttackMoveSnapshot,
        body,
        clientNow + 32
    ),
    "post-attack movement bypassed the body-local bump tail"
)
runZombieUpdates(body)
assert(requestCount == requestsBeforeAttackUpdate,
    "native path started before the local bump lifecycle exited")

bodyModData.PNC_BumpActionLease = nil
bodyModData.PNC_BumpActionLeaseUntil = nil
localPlayer.x = 0
localPlayer.y = 0
remotePlayer.x = 100
remotePlayer.y = 100
clientNow = 2000
local retrySnapshot = {
    id = snapshot.id,
    liveBodyLease = snapshot.liveBodyLease,
    visualState = {
        nativeMoveActive = true,
        attackActive = false,
        nativeMoveX = 8,
        nativeMoveY = 4,
        nativeMoveZ = 0,
        nativeMoveRevision = 5,
    },
}
assert(PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
    retrySnapshot,
    body,
    clientNow
), "retry path did not bind")
runZombieUpdates(body)
local requestsBeforeRetries = requestCount
local attempt
for attempt = 1, 5 do
    body.actionState = "idle"
    clientNow = clientNow + 1000
    runZombieUpdates(body)
    clientNow = clientNow + 5000
    runZombieUpdates(body)
end
assert(requestCount == requestsBeforeRetries + 5,
    "same native goal stopped retrying after repeated engine drops")
assert(useless == false,
    "retrying native movement lost its multiplayer movement lease")

local tickSource = readAll(CLIENT_TICK)
assert(not string.find(
        tickSource,
        "UpdateNativePathController",
        1,
        true
    ),
    "generic client tick still pumps PathFindBehavior2")
assert(
    not string.find(
        tickSource,
        "Interpolation.RecordSnapshot",
        1,
        true
    ),
    "roster snapshots still install a second MP position mover"
)
assert(
    not string.find(
        tickSource,
        "Interpolation.ApplyToZombie",
        1,
        true
    ),
    "roster snapshots still overwrite engine-network positions"
)
local initSource = readAll(CLIENT_INIT)
assert(
    not string.find(
        initSource,
        "PNC_ClientInterpolation",
        1,
        true
    ),
    "removed interpolation transport is still loaded"
)
local interpolationFile = io.open(
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/"
        .. "PNC_ClientInterpolation.lua",
    "rb"
)
assert(interpolationFile == nil,
    "legacy position interpolation module still exists")

local controllerSource = readAll(CLIENT_CONTROLLER)
assert(string.find(
        controllerSource,
        "Events.OnZombieUpdate.Add",
        1,
        true
    ),
    "client pathing does not use Bandits' zombie-update context")
assert(not string.find(controllerSource, "setX(", 1, true)
        and not string.find(controllerSource, "setY(", 1, true)
        and not string.find(controllerSource, "setZ(", 1, true),
    "client native controller contains teleport movement")
assert(not string.find(controllerSource, "pcall", 1, true),
    "client native controller hides failures with pcall")
assert(not string.find(controllerSource, "behavior:update(", 1, true),
    "client manually pumps PathFindBehavior2 instead of PathFindState")
assert(string.find(
    controllerSource,
    "body:pathToLocationF",
    1,
    true
), "client does not enter the engine PathFindState wrapper")

local visualSource = readAll(CLIENT_VISUALS)
assert(string.find(
        visualSource,
        "visualState.nativeMoveActive == true",
        1,
        true
    ),
    "native replica visuals have no exclusive path-owner gate")

local animationSource = readAll(ANIMATION)
local nativeStyleStart = assert(string.find(
    animationSource,
    "function Animation.SyncNativeLocomotionStyle",
    1,
    true
))
local liveSetupStart = assert(string.find(
    animationSource,
    "function Animation.ApplyLiveSetup",
    nativeStyleStart,
    true
))
local nativeStyleSource = string.sub(
    animationSource,
    nativeStyleStart,
    liveSetupStart - 1
)
assert(
    not string.find(nativeStyleSource, "setMoving(", 1, true)
        and not string.find(nativeStyleSource, "\"bMoving\"", 1, true)
        and not string.find(nativeStyleSource, "\"isMoving\"", 1, true)
        and not string.find(
            nativeStyleSource,
            "SyncLocomotionState",
            1,
            true
        )
        and not string.find(nativeStyleSource, "changeState", 1, true),
    "native path style still mutates engine movement/action state"
)

local pathContextSource = readAll(PATH_CONTEXT)
local walkAnimStart = assert(string.find(
    pathContextSource,
    "function Internal.setWalkAnim",
    1,
    true
))
local resetControllerStart = assert(string.find(
    pathContextSource,
    "function Internal.resetPathController",
    walkAnimStart,
    true
))
local walkAnimSource = string.sub(
    pathContextSource,
    walkAnimStart,
    resetControllerStart - 1
)
local nativeGateAt = assert(string.find(
    walkAnimSource,
    "lane.navigationProvider == \"engine_path\"",
    1,
    true
))
local fakeApplyAt = assert(string.find(
    walkAnimSource,
    "Animation.Apply(zombie",
    1,
    true
))
assert(nativeGateAt < fakeApplyAt,
    "engine-path locomotion reaches fake Animation.Apply before its gate")

local traversalSource = readAll(TRAVERSAL_RUNTIME)
assert(string.find(
        traversalSource,
        "native_mp_owner",
        1,
        true
    ),
    "scripted setX/setY traversal has no multiplayer ownership gate")

print("pnc_mp_replica_transport_smoke: ok")
