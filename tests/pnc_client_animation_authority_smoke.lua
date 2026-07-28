local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/PresenceSync/"
    .. "PNC_ClientPresenceVisuals.lua"

local calls = {
    apply = 0,
    clear = 0,
    finish = 0,
    nativeStyle = 0,
    play = 0,
    pump = 0,
    sync = 0,
}
local now = 1000

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
        PumpBumpRelease = function() calls.pump = calls.pump + 1 end,
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
}

dofile(FILE)

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
assert(calls.play == 1, "single-player client did not render its attack snapshot")
assert(calls.pump == 0, "fresh local attack pumped before entering bump state")

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
assert(calls.play == 2, "local attack snapshot replayed more than once")
assert(calls.pump == 1, "local client did not maintain its attack bump")

PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    attackSnapshot,
    body(),
    true
)
assert(calls.play == 3, "remote replica did not replay the attack snapshot")
assert(calls.pump == 2, "remote replica did not maintain bump release")

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
assert(calls.play == 5,
    "MP attack bump was not retried after packet/state loss")
assert(clearedBeforeRetry,
    "same-value MP bump retry did not create a variable edge")

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
assert(calls.finish == 1, "single-player client did not finish its attack bump")
PNC.ClientPresenceSync.Internal.ApplySnapshotToBody(
    finishedLocalSnapshot,
    sustainedLocalBody,
    false
)
assert(calls.pump == pumpsBeforeFinish + 2,
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
assert(calls.apply == 0, "local authority gained a second locomotion owner")
assert(calls.sync == 0, "local authority resynchronized locomotion twice")

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
assert(calls.nativeStyle == 1,
    "native MP route did not receive presentation-only locomotion style")
assert(calls.apply == appliesBeforeNative and calls.sync == syncsBeforeNative,
    "native MP route invoked fake locomotion")
assert(calls.clear == clearsBeforeNative,
    "healthy native MP route was reset through ClearDowned")

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
assert(
    calls.finish == finishesBeforeSpecial,
    "local authority finished its server-owned special bump"
)

print("pnc_client_animation_authority_smoke: ok")
