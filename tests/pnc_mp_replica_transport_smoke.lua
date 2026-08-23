local T = require "tests/support/test"

local BODY_CONTROL =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_LiveBodyControl.lua"
local CLIENT_TICK =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "PresenceSync/PNC_ClientPresenceTick.lua"
local CLIENT_INIT =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "00_PNC_Client_Init.lua"
local CLIENT_LUA_ROOT =
    T.path("ProjectHoomans", "client", "")
local CLIENT_CONTROLLER_ROOT = CLIENT_LUA_ROOT
    .. "PNC/PresenceSync/ClientNativePathController/"
local CLIENT_CONTROLLER = CLIENT_CONTROLLER_ROOT
    .. "PNC_ClientNativePathController.lua"

T.addPackagePaths()
local CLIENT_VISUALS =
    T.path("ProjectHoomans", "client", "PNC/")
    .. "PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Locomotion.lua"
local ANIMATION =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Visuals/PNC_Animation.lua"
local ANIMATION_PROVIDERS =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Visuals/PNC_Animation/"
local PATH_CONTEXT =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/Context/"
    .. "PNC_PathService_Context_Animation.lua"
local TRAVERSAL_RUNTIME =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua"
local TRAVERSAL_PROGRESS =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/TraversalRuntime/"
    .. "PNC_PathService_TraversalRuntime_Progress.lua"

local useless = true
local clientNow = 1000
local requestCount = 0
local updateCount = 0
local cancelCount = 0
local resetCount = 0
local nativePassageObject
local windowSmashStarted = 0
local windowSmashFinished = 0
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
        T.truthy(x == 8 and y == 4 and z == 0,
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
    faceThisObject = function(self, object)
        self.facedObject = object
    end,
    setBumpType = function(self, value)
        self.bumpType = value
    end,
    changeState = function(self, value)
        self.actionState = value and value.name or "idle"
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

T.load(BODY_CONTROL)

T.truthy(
    PNC.LiveBodyControl.EnforceManagedSafety(
        body,
        "mp_replica_test"
    ) == true,
    "managed MP replica was not maintained"
)
T.truthy(
    useless == true,
    "idle MP replica did not retain scripted/manual body mode"
)

PNC.ClientPresenceSync = {
    Internal = {
        LogClientMotionDebug = function() end,
    },
    NativePathStateByBody = {},
}
PNC.TraversalQuery = {
    FindPassageToward = function()
        return nativePassageObject
            and { object = nativePassageObject }
            or nil
    end,
    IsDoor = function(object)
        return object and object.kind == "door"
    end,
    IsWindow = function(object)
        return object and object.kind == "window"
    end,
}
PNC.PathService = {
    Internal = {
        openDoorForNPC = function(_, object)
            object.open = true
            return true
        end,
        openWindowForNPC = function(_, object)
            if object.locked then return false end
            object.open = true
            return true
        end,
        smashWindowForNPC = function(_, object)
            object.smashed = true
            return true
        end,
    },
}
PNC.Animation = {
    PlayBump = function(_, _, bumpType)
        T.truthy(bumpType == "PNC_WindowSmash",
            "native breach selected the wrong animation")
        windowSmashStarted = windowSmashStarted + 1
        return true
    end,
    FinishBump = function()
        windowSmashFinished = windowSmashFinished + 1
    end,
}
ClimbThroughWindowState = {
    instance = function()
        return {
            name = "climbwindow",
            setParams = function(self, candidate, object)
                self.body = candidate
                self.object = object
            end,
        }
    end,
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

T.load(CLIENT_CONTROLLER)

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
T.truthy(
    PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
        snapshot,
        body,
        clientNow
    ),
    "presence tick did not bind the delegated native goal"
)
T.truthy(#zombieUpdateHandlers == 2,
    "native path controller was not registered on OnZombieUpdate")
body.target = localPlayer
body.targetSeenTime = 12
body.eatBodyTarget = localPlayer
body.aggroCleared = false
runZombieUpdates(body)
T.truthy(requestCount == 1 and updateCount == 0,
    "nearest MP client did not start movement in zombie update context")
PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
    snapshot,
    body,
    clientNow + 16
)
runZombieUpdates(body)
T.truthy(requestCount == 1,
    "unchanged delegated goal was submitted more than once")
T.truthy(updateCount == 0,
    "client manually advanced engine-owned PathFindBehavior2")
T.truthy(useless == false,
    "client controller disabled the body during movement")
T.truthy(body.target == nil,
    "zombie target was not suppressed in the movement-owner frame")
T.truthy(body.targetSeenTime == 0,
    "zombie target memory was not reset in the movement-owner frame")
T.truthy(body.eatBodyTarget == nil,
    "zombie eating target was not suppressed in the movement-owner frame")
T.truthy(body.aggroCleared == true,
    "zombie aggro was not suppressed in the movement-owner frame")

localPlayer.x = 200
localPlayer.y = 200
remotePlayer.x = 1
remotePlayer.y = 1
clientNow = 1300
runZombieUpdates(body)
T.truthy(cancelCount == 1 and resetCount == 1,
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
T.truthy(
    not PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
        attackSnapshot,
        body,
        clientNow + 16
    ),
    "attack snapshot retained a native path goal"
)
T.truthy(cancelCount == 2 and resetCount == 2,
    "attack snapshot did not release delegated movement before PlayBump")
T.truthy(useless == false,
    "attack action lease did not keep the MP action context active")
local requestsBeforeAttackUpdate = requestCount
runZombieUpdates(body)
T.truthy(requestCount == requestsBeforeAttackUpdate,
    "MP zombie update started movement during the attack action lease")
T.truthy(useless == false,
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
T.truthy(
    not PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
        postAttackMoveSnapshot,
        body,
        clientNow + 32
    ),
    "post-attack movement bypassed the body-local bump tail"
)
runZombieUpdates(body)
T.truthy(requestCount == requestsBeforeAttackUpdate,
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
T.truthy(PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
    retrySnapshot,
    body,
    clientNow
), "retry path did not bind")
runZombieUpdates(body)
local requestsBeforeRetries = requestCount
local attempt
for attempt = 1, 5 do
    body.actionState = attempt == 1
        and "climbfence" or "idle"
    clientNow = clientNow + (attempt == 1 and 3100 or 1000)
    runZombieUpdates(body)
    clientNow = clientNow + 5000
    runZombieUpdates(body)
end
T.truthy(requestCount == requestsBeforeRetries + 5,
    "same native goal stopped retrying after repeated engine drops")
T.truthy(useless == false,
    "retrying native movement lost its multiplayer movement lease")

PNC.ClientPresenceSync.Internal.ClearNativePathControllers()
local breachWindow = {
    kind = "window",
    locked = true,
    open = false,
    smashed = false,
    IsOpen = function(self) return self.open end,
    isSmashed = function(self) return self.smashed end,
    canClimbThrough = function(self) return self.smashed end,
}
nativePassageObject = breachWindow
body.actionState = "idle"
clientNow = clientNow + 100
local breachSnapshot = {
    id = snapshot.id,
    liveBodyLease = snapshot.liveBodyLease,
    visualState = {
        nativeMoveActive = true,
        attackActive = false,
        nativeMoveX = 8,
        nativeMoveY = 4,
        nativeMoveZ = 0,
        nativeMoveRevision = 6,
    },
}
PNC.ClientPresenceSync.Internal.BindNativePathSnapshot(
    breachSnapshot,
    body,
    clientNow
)
runZombieUpdates(body)
T.truthy(windowSmashStarted == 1,
    "locked native-route window did not start a breach")
clientNow = clientNow + 700
runZombieUpdates(body)
T.truthy(breachWindow.smashed == true,
    "native-route window was not broken at impact")
clientNow = clientNow + 400
runZombieUpdates(body)
T.truthy(windowSmashFinished == 1,
    "window breach animation did not release")
-- A climbable window must be intercepted immediately. Waiting for the normal
-- stall-recovery interval lets PathFindBehavior2 call
-- IsoGameCharacter.climbThroughWindow(), which emits player-only equipment
-- packets for this managed IsoZombie in multiplayer.
clientNow = clientNow + 100
body.actionState = "idle"
runZombieUpdates(body)
T.truthy(body.actionState == "climbwindow",
    "smashed native-route window was returned to unsafe engine pathing")
T.truthy(body.bumpType == "ClimbWindow",
    "forced window climb did not use the engine traversal selector")

local tickSource = T.read(CLIENT_TICK)
T.truthy(not string.find(
        tickSource,
        "UpdateNativePathController",
        1,
        true
    ),
    "generic client tick still pumps PathFindBehavior2")
T.truthy(
    not string.find(
        tickSource,
        "Interpolation.RecordSnapshot",
        1,
        true
    ),
    "roster snapshots still install a second MP position mover"
)
T.truthy(
    not string.find(
        tickSource,
        "Interpolation.ApplyToZombie",
        1,
        true
    ),
    "roster snapshots still overwrite engine-network positions"
)
local initSource = T.read(CLIENT_INIT)
T.truthy(
    not string.find(
        initSource,
        "PNC_ClientInterpolation",
        1,
        true
    ),
    "removed interpolation transport is still loaded"
)
local interpolationFile = io.open(
    T.path("ProjectHoomans", "client", "PNC/")
        .. "PNC_ClientInterpolation.lua",
    "rb"
)
T.truthy(interpolationFile == nil,
    "legacy position interpolation module still exists")

local controllerSource = ""
local controllerModules = {
    "PNC_ClientNativePathController.lua",
    "PNC_ClientNativePathController_Constants.lua",
    "PNC_ClientNativePathController_State.lua",
    "PNC_ClientNativePathController_Goal.lua",
    "PNC_ClientNativePathController_Passage.lua",
    "PNC_ClientNativePathController_Binding.lua",
    "PNC_ClientNativePathController_Request.lua",
    "PNC_ClientNativePathController_Update.lua",
    "PNC_ClientNativePathController_Lifecycle.lua",
}
local controllerModuleIndex
for controllerModuleIndex = 1, #controllerModules do
    controllerSource = controllerSource
        .. T.read(
            CLIENT_CONTROLLER_ROOT
                .. controllerModules[controllerModuleIndex]
        )
end
T.truthy(string.find(
        controllerSource,
        "Events.OnZombieUpdate.Add",
        1,
        true
    ),
    "client pathing does not use Bandits' zombie-update context")
T.truthy(not string.find(controllerSource, "setX(", 1, true)
        and not string.find(controllerSource, "setY(", 1, true)
        and not string.find(controllerSource, "setZ(", 1, true),
    "client native controller contains teleport movement")
T.truthy(not string.find(controllerSource, "pcall", 1, true),
    "client native controller hides failures with pcall")
T.truthy(not string.find(controllerSource, "behavior:update(", 1, true),
    "client manually pumps PathFindBehavior2 instead of PathFindState")
T.truthy(string.find(
    controllerSource,
    "body:pathToLocationF",
    1,
    true
), "client does not enter the engine PathFindState wrapper")

local visualSource = T.read(CLIENT_VISUALS)
T.truthy(string.find(
        visualSource,
        "visualState.nativeMoveActive == true",
        1,
        true
    ),
    "native replica visuals have no exclusive path-owner gate")

local animationSource = T.read(
    ANIMATION_PROVIDERS .. "PNC_Animation_NativeLocomotion.lua"
) .. T.read(
    ANIMATION_PROVIDERS .. "PNC_Animation_LiveSetup.lua"
)
local nativeStyleStart = T.truthy(string.find(
    animationSource,
    "function Animation.SyncNativeLocomotionStyle",
    1,
    true
))
local liveSetupStart = T.truthy(string.find(
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
T.truthy(
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

local pathContextSource = T.read(PATH_CONTEXT)
local walkAnimStart = T.truthy(string.find(
    pathContextSource,
    "function Internal.setWalkAnim",
    1,
    true
))
local walkAnimSource = string.sub(
    pathContextSource,
    walkAnimStart
)
local nativeGateAt = T.truthy(string.find(
    walkAnimSource,
    "lane.navigationProvider == \"engine_path\"",
    1,
    true
))
local fakeApplyAt = T.truthy(string.find(
    walkAnimSource,
    "Animation.Apply(zombie",
    1,
    true
))
T.truthy(nativeGateAt < fakeApplyAt,
    "engine-path locomotion reaches fake Animation.Apply before its gate")

local traversalSource = T.read(TRAVERSAL_RUNTIME)
    .. T.read(TRAVERSAL_PROGRESS)
T.truthy(string.find(
        traversalSource,
        "native_mp_owner",
        1,
        true
    ),
    "scripted setX/setY traversal has no multiplayer ownership gate")
T.finish("pnc_mp_replica_transport_smoke")
