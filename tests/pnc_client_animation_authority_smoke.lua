local T = require "tests/support/test"

local LUA_ROOT =
    T.path("ProjectHoomans", "client", "")
local FILE = LUA_ROOT .. "PNC/PresenceSync/PresenceVisuals/"
    .. "PNC_ClientPresenceVisuals.lua"

T.addPackagePaths()

local calls = {
    apply = 0,
    clear = 0,
    finish = 0,
    maintain = 0,
    nativeStyle = 0,
    play = 0,
    pump = 0,
    sync = 0,
}
local now = 1000
local engineMovementActive
local pumpReturnsActive = false

PNC = {
    Const = {
        BODY_SHELL_VERSION = 1,
        BODY_TAG_VERSION = 1,
        PRESENCE_ABSTRACT = "abstract",
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return now end,
    },
    LiveBodyControl = {
        MaintainHumanizedBody = function(_, _, active)
            engineMovementActive = active
        end,
    },
    Animation = {
        Apply = function() calls.apply = calls.apply + 1 end,
        ClearDowned = function() calls.clear = calls.clear + 1 end,
        FinishBump = function(zombie)
            calls.finish = calls.finish + 1
            zombie:getModData().PNC_BumpReleasePending = true
        end,
        PlayBump = function(zombie, _, anim)
            calls.play = calls.play + 1
            if zombie and zombie.setBumpType then
                zombie:setBumpType(anim)
            end
        end,
        MaintainBump = function(zombie, _, anim)
            calls.maintain = calls.maintain + 1
            if zombie and zombie.setBumpType then
                zombie:setBumpType(anim)
            end
        end,
        PumpBumpRelease = function()
            calls.pump = calls.pump + 1
            return pumpReturnsActive
        end,
        SyncNativeLocomotionStyle = function()
            calls.nativeStyle = calls.nativeStyle + 1
        end,
        SyncLocomotion = function() calls.sync = calls.sync + 1 end,
    },
    ClientPresenceSync = {
        Internal = {
            LogClientMotionDebug = function() end,
        },
    },
    BehaviorTreatment = {
        ResolveBandageAnimation = function(partId)
            return partId == "Hand_L"
                and "BandageLeftArm"
                or "BandageUpperBody"
        end,
    },
}

T.load(FILE)

local function body()
    local modData = {}
    return {
        getModData = function() return modData end,
        isDead = function() return false end,
        setFemaleEtc = function() end,
        setVariable = function() end,
    }
end

local attackSnapshot = {
    id = "authority",
    alive = true,
    attackMode = true,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    visualState = {
        anim = "PNC_Attack1H1",
        attackActive = true,
        attackAnim = "PNC_Attack1H1",
        attackFinishAt = 1700,
        moving = false,
    },
}

PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    body(),
    false
)
T.truthy(calls.play == 1, "single-player client did not render its attack snapshot")
T.truthy(calls.pump == 0, "fresh local attack pumped before entering bump state")

local sustainedLocalBody = body()
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    sustainedLocalBody,
    false
)
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    sustainedLocalBody,
    false
)
T.truthy(calls.play == 2, "local attack snapshot replayed more than once")
T.truthy(calls.pump == 1, "local client did not maintain its attack bump")

PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    body(),
    true
)
T.truthy(calls.play == 3, "remote replica did not replay the attack snapshot")
T.truthy(calls.pump == 2, "remote replica did not maintain bump release")
T.truthy(engineMovementActive == true,
    "remote attack did not retain its action-context update lease")

local traversalAttackSnapshot = {
    id = "traversal_attack_authority",
    alive = true,
    attackMode = true,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    visualState = {
        anim = "PNC_Attack1H1",
        attackActive = true,
        attackAnim = "PNC_Attack1H1",
        attackFinishAt = 1700,
        nativeTraversalActive = true,
        nativeTraversalState = "ClimbWindow",
        moving = false,
    },
}
local playsBeforeTraversal = calls.play
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    traversalAttackSnapshot,
    body(),
    true
)
T.truthy(calls.play == playsBeforeTraversal,
    "remote attack overwrote native traversal")

local retryModData = {}
local retryBumpType = ""
local clearedBeforeRetry = false
local retryBody = {
    getModData = function() return retryModData end,
    isDead = function() return false end,
    setFemaleEtc = function() end,
    setVariable = function() end,
    getActionStateName = function() return "idle" end,
    getBumpType = function() return retryBumpType end,
    setBumpType = function(_, value)
        if value == "" then
            clearedBeforeRetry = true
        end
        retryBumpType = value
    end,
}
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    retryBody,
    true
)
now = now + 100
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    retryBody,
    true
)
T.truthy(calls.play == 5,
    "dropped MP attack bump was not re-armed once")
T.truthy(clearedBeforeRetry,
    "idle MP selector did not receive a fresh transition edge")
T.truthy(retryModData.PNC_ClientAttackRetries == 1,
    "MP attack bump re-arm was not bounded")
now = now + 100
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    retryBody,
    true
)
T.truthy(calls.play == 5,
    "dropped MP attack bump re-armed more than once")

local finishedLocalSnapshot = {
    id = attackSnapshot.id,
    alive = true,
    attackMode = false,
    healthState = "normal",
    presenceRevision = 2,
    presenceState = "live",
    visualState = {
        anim = "Idle",
        attackActive = false,
        moving = false,
    },
}
local pumpsBeforeFinish = calls.pump
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    finishedLocalSnapshot,
    sustainedLocalBody,
    false
)
T.truthy(calls.finish == 1, "single-player client did not finish its attack bump")
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    finishedLocalSnapshot,
    sustainedLocalBody,
    false
)
T.truthy(calls.pump == pumpsBeforeFinish + 2,
    "single-player client did not pump pending bump release")

local movingSnapshot = {
    id = "moving_authority",
    alive = true,
    attackMode = false,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    visualState = {
        anim = "Walk",
        moveAnim = "Walk",
        moving = true,
        mode = "walk",
    },
}
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    movingSnapshot,
    body(),
    false
)
T.truthy(calls.apply == 0, "local authority gained a second locomotion owner")
T.truthy(calls.sync == 0, "local authority resynchronized locomotion twice")

local nativeReplica = body()
local nativeSnapshot = {
    id = "native_replica",
    alive = true,
    attackMode = false,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    visualState = {
        anim = "Run",
        moveAnim = "Run",
        moving = true,
        mode = "run",
        nativeMoveActive = true,
        nativeMoveRevision = 3,
    },
}
local appliesBeforeNative = calls.apply
local syncsBeforeNative = calls.sync
local clearsBeforeNative = calls.clear
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    nativeSnapshot,
    nativeReplica,
    true
)
T.truthy(engineMovementActive == true,
    "native MP movement did not retain engine body mode")
T.truthy(calls.nativeStyle == 1,
    "native MP route did not receive presentation-only locomotion style")
T.truthy(calls.apply == appliesBeforeNative and calls.sync == syncsBeforeNative,
    "native MP route invoked fake locomotion")
T.truthy(calls.clear == clearsBeforeNative,
    "healthy native MP route was reset through ClearDowned")

local releaseBody = body()
releaseBody:getModData().PNC_BumpReleasePending = true
local nativeStylesBeforeRelease = calls.nativeStyle
pumpReturnsActive = true
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    nativeSnapshot,
    releaseBody,
    true
)
pumpReturnsActive = false
T.truthy(calls.nativeStyle == nativeStylesBeforeRelease,
    "new MP locomotion snapshot overwrote the pending bump exit")

local specialBody = body()
local finishesBeforeSpecial = calls.finish
local specialSnapshot = {
    id = "special_authority",
    alive = true,
    attackMode = false,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    visualState = {
        anim = "PNC_ClimbFence",
        moving = false,
        specialActive = true,
        specialAnim = "PNC_ClimbFence",
        specialFinishAt = 1600,
    },
}
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    specialSnapshot,
    specialBody,
    false
)
specialSnapshot.visualState = {
    anim = "Idle",
    moving = false,
    specialActive = false,
}
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    specialSnapshot,
    specialBody,
    false
)
T.truthy(
    calls.finish == finishesBeforeSpecial,
    "local authority finished its server-owned special bump"
)

local treatmentBody = body()
local treatmentSnapshot = {
    id = "treatment_replica",
    alive = true,
    attackMode = false,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    treatmentState = {
        phase = "bandaging",
        partId = "Hand_L",
        startedAt = 2000,
        finishAt = 7000,
    },
    visualState = {
        anim = "Idle",
        moving = false,
    },
}
local playsBeforeTreatment = calls.play
local finishesBeforeTreatment = calls.finish
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    treatmentSnapshot,
    treatmentBody,
    true
)
T.truthy(calls.play == playsBeforeTreatment + 1,
    "MP treatment snapshot did not start its bandage animation")
T.truthy(treatmentBody:getModData().PNC_ClientTreatmentAnimKey
        == "Hand_L:2000",
    "MP treatment animation key was not retained")
T.truthy(engineMovementActive == true,
    "MP treatment animation did not retain engine action updates")

PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    treatmentSnapshot,
    treatmentBody,
    true
)
T.truthy(calls.play == playsBeforeTreatment + 1,
    "MP treatment animation was restarted on an unchanged snapshot")
T.truthy(calls.maintain == 1,
    "MP treatment animation lease was not maintained")

treatmentSnapshot.treatmentState = {
    phase = "idle",
}
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    treatmentSnapshot,
    treatmentBody,
    true
)
T.truthy(calls.finish == finishesBeforeTreatment + 1,
    "MP treatment completion did not release its bandage animation")

local sceneBody = body()
local sceneSnapshot = {
    id = "scene_replica",
    alive = true,
    attackMode = false,
    healthState = "normal",
    presenceRevision = 1,
    presenceState = "live",
    visualState = {
        anim = "Surrender",
        moving = false,
        sceneActive = true,
        sceneId = "social.surrender",
        sceneBump = "Surrender",
        sceneRevision = 4,
        scenePlaybackRevision = 1,
        sceneStartedAt = 3000,
        sceneFinishAt = 0,
        sceneLoop = true,
        sceneBlocking = true,
    },
}
local playsBeforeScene = calls.play
local maintainsBeforeScene = calls.maintain
local finishesBeforeScene = calls.finish
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    sceneSnapshot,
    sceneBody,
    true
)
T.truthy(calls.play == playsBeforeScene + 1,
    "MP animation scene did not start its registered bump")
T.truthy(sceneBody:getModData().PNC_ClientAnimationSceneKey
        == "social.surrender:4:1",
    "MP animation scene key was not retained")
T.truthy(engineMovementActive == true,
    "MP animation scene did not retain engine action updates")

PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    sceneSnapshot,
    sceneBody,
    true
)
T.truthy(calls.play == playsBeforeScene + 1,
    "unchanged MP animation scene restarted")
T.truthy(calls.maintain == maintainsBeforeScene + 1,
    "looping MP animation scene was not maintained")

sceneSnapshot.visualState.sceneBump = "Sneeze"
sceneSnapshot.visualState.scenePlaybackRevision = 2
sceneSnapshot.visualState.sceneLoop = false
sceneSnapshot.visualState.sceneFinishAt = 5000
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    sceneSnapshot,
    sceneBody,
    true
)
T.truthy(calls.play == playsBeforeScene + 2,
    "next primitive in an unchanged scene did not replay")
T.truthy(sceneBody:getModData().PNC_ClientAnimationSceneKey
        == "social.surrender:4:2",
    "primitive playback revision was not retained")

sceneSnapshot.visualState = {
    anim = "Idle",
    moving = false,
    sceneActive = false,
}
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    sceneSnapshot,
    sceneBody,
    true
)
T.truthy(calls.finish == finishesBeforeScene + 1,
    "MP animation scene did not release on stop")
T.finish("pnc_client_animation_authority_smoke")

T.finish("pnc_client_animation_authority_smoke")
