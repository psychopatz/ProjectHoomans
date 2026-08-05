local SHARED_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local CLIENT_ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
local SCENES = SHARED_ROOT
    .. "PNC/Core/Visuals/PNC_AnimationScenes.lua"
local DEFINITIONS = SHARED_ROOT
    .. "PNC/Core/Visuals/PNC_AnimationSceneDefinitions.lua"
local DEBUG_CONTROLLER = SHARED_ROOT
    .. "PNC/Core/Debug/PNC_AnimationSceneDebug.lua"
local DEBUG_MODEL = CLIENT_ROOT
    .. "PNC/Debug/PNC_AnimationSceneDebugModel.lua"

local now = 1000
local played = {}
local finished = 0

ZombRand = function()
    return 0
end

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ANIMATION_IDLE_SCENE_MIN_MS = 8000,
        ANIMATION_IDLE_SCENE_JITTER_MS = 12000,
    },
    Core = {
        Now = function() return now end,
    },
    Animation = {
        PlayBump = function(_, _, bump, options)
            played[#played + 1] = {
                bump = bump,
                options = options,
            }
        end,
        MaintainBump = function() end,
        FinishBump = function()
            finished = finished + 1
        end,
    },
    BehaviorMoveIntent = {
        Hold = function() end,
    },
    Network = {
        ClientState = {
            snapshots = {},
        },
    },
}

dofile(SCENES)
dofile(DEFINITIONS)
dofile(DEBUG_CONTROLLER)
dofile(DEBUG_MODEL)

local body = {
    getModData = function()
        return {}
    end,
}
local record = {
    id = "scene_debug_npc",
    alive = true,
    presenceState = "live",
    health = { state = "normal" },
    runtime = {},
}

local started, state =
    PNC.AnimationSceneDebug.StartPoolCycle(
        record,
        body,
        "idle",
        {
            now = now,
            gapMs = 500,
        }
    )
assert(started == true, "idle debug cycle did not start")
assert(state.pool == "idle", "debug cycle lost pool")
assert(record.runtime.animationScene
        and record.runtime.animationScene.id
            == "idle.ambient",
    "debug cycle did not immediately play the composite idle scene")
local idleSequence = record.runtime.animationScene
local firstPlaybackRevision = idleSequence.playbackRevision
now = idleSequence.finishAt
PNC.AnimationScenes.Tick(record, body, now)
assert(record.runtime.animationScene == idleSequence
        and idleSequence.bump == nil,
    "scene lab cycle did not preserve the sequence during its gap")
now = idleSequence.nextStepAt
PNC.AnimationScenes.Tick(record, body, now)
assert(idleSequence.playbackRevision
        == firstPlaybackRevision + 1,
    "scene lab cycle did not advance the primitive queue")

local snapshot =
    PNC.AnimationSceneDebug.BuildSnapshot(record)
assert(snapshot.active == true
        and snapshot.completedCount == 0,
    "debug controller snapshot omitted live cycle state")

local stopped = PNC.AnimationSceneDebug.Stop(
    record,
    body,
    "smoke_stop"
)
assert(stopped == true, "debug cycle did not stop")
assert(record.runtime.animationSceneDebug == nil,
    "debug cycle state survived stop")
assert(record.runtime.animationScene == nil,
    "debug scene survived stop")
assert(finished >= 2,
    "debug stop did not release active animation")

started = PNC.AnimationSceneDebug.Play(
    record,
    body,
    "social.surrender",
    { now = now }
)
assert(started == true, "manual surrender test did not start")
assert(record.runtime.animationScene.id
        == "social.surrender",
    "manual scene debug selected wrong scene")

PNC.AnimationScenes.Register("addon.wave", {
    label = "Addon Wave",
    description = "Registered after the debug UI loaded.",
    category = "social",
    pool = "greeting",
    weight = 4,
    bump = "WaveHi",
    durationMs = 1200,
})

local groups =
    PNC.AnimationSceneDebugModel.GetGroups()
local greetingPool = false
for _, group in ipairs(groups) do
    if group.key == "pool:greeting" then
        greetingPool = true
    end
end
assert(greetingPool,
    "debug model did not discover a newly registered pool")

local addonScenes =
    PNC.AnimationSceneDebugModel.GetScenes(
        "addon wave",
        {
            kind = "pool",
            value = "greeting",
        }
    )
assert(#addonScenes == 1
        and addonScenes[1].id == "addon.wave",
    "registry-driven scene filtering failed")

PNC.Network.ClientState.snapshots.scene_debug_npc = {
    visualState = {
        sceneActive = true,
        sceneId = "social.surrender",
        sceneBump = "Surrender",
        sceneRevision = 7,
        sceneRepeatMode = "loop",
        sceneDebug = {
            active = true,
            pool = "idle",
            completedCount = 3,
        },
    },
}
local clientRuntime =
    PNC.AnimationSceneDebugModel.GetRuntime(
        "scene_debug_npc"
    )
assert(clientRuntime.sceneId == "social.surrender"
        and clientRuntime.sceneRevision == 7,
    "scene lab did not prefer replicated authority state")
assert(clientRuntime.sceneRepeatMode == "loop",
    "scene lab omitted replicated repeat policy")
assert(clientRuntime.cycleActive == true
        and clientRuntime.cycleCompletedCount == 3,
    "scene lab omitted replicated cycle diagnostics")

local nestedActionContextRead = false
local bodyRuntime =
    PNC.AnimationSceneDebugModel.GetBodyRuntime({
        getActionContext = function()
            nestedActionContextRead = true
            error("nested ActionContext must not be inspected")
        end,
        getCurrentActionContextStateName = function()
            return "bumped"
        end,
        getPreviousActionContextStateName = function()
            return "idle"
        end,
        getAnimationStateName = function()
            return "bumped"
        end,
        getBumpType = function()
            return "PNC_Surrender"
        end,
        dbgGetAnimTrackName = function()
            return "Bob_EmoteSurrender"
        end,
        dbgGetAnimTrackTime = function()
            return 0.5
        end,
    })
assert(nestedActionContextRead == false,
    "scene lab touched unsupported ActionContext userdata")
assert(bodyRuntime.actionState == "bumped"
        and bodyRuntime.animationState == "bumped",
    "scene lab did not use exposed body state methods")
assert(bodyRuntime.bumpType == "PNC_Surrender"
        and bodyRuntime.trackFrame == 15,
    "scene lab body diagnostics were incomplete")

print("pnc_animation_scene_debug_smoke: ok")
