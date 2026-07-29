local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Visuals/PNC_AnimationScenes.lua"
local DEFINITIONS =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
    .. "Visuals/PNC_AnimationSceneDefinitions.lua"

local now = 1000
local played = {}
local maintained = 0
local finished = 0
local held = 0
local bodyModData = {}

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
        MaintainBump = function(_, _, bump, leaseUntil, options)
            maintained = maintained + 1
            assert(bump == "Surrender",
                "persistent scene maintained wrong bump")
            assert(leaseUntil > now,
                "persistent scene lease was not extended")
            assert(options and options.sceneId == "social.surrender",
                "scene ownership token was lost")
        end,
        FinishBump = function()
            finished = finished + 1
        end,
    },
    BehaviorMoveIntent = {
        Hold = function()
            held = held + 1
        end,
    },
}

dofile(FILE)
dofile(DEFINITIONS)

local body = {
    getModData = function()
        return bodyModData
    end,
}
local record = {
    id = "scene_npc",
    alive = true,
    presenceState = "live",
    health = { state = "normal" },
    runtime = {},
}

assert(PNC.AnimationScenes.Get("idle.shift_weight").bump
        == "ShiftWeight",
    "default idle scene missing")
assert(PNC.AnimationScenes.Get("social.surrender").blocking == true,
    "surrender scene is not blocking")

local registered, custom = PNC.AnimationScenes.Register(
    "example.wave",
    {
        bump = "WaveHi",
        durationMs = 2400,
        priority = 20,
        pool = "greeting",
        weight = 3,
    }
)
assert(registered and custom.bump == "WaveHi",
    "custom scene registration failed")

local started, active = PNC.AnimationScenes.Request(
    record,
    body,
    "idle.shift_weight",
    { now = now }
)
assert(started and active.id == "idle.shift_weight",
    "idle scene did not start")
assert(played[#played].bump == "ShiftWeight",
    "idle scene did not select its registered bump")
assert(played[#played].options.sceneId == "idle.shift_weight",
    "scene playback did not carry an ownership token")
assert(bodyModData.PNC_ClientAnimationSceneKey
        == "idle.shift_weight:1",
    "local scene snapshot dedupe key missing")
assert(PNC.AnimationScenes.Tick(record, body, now + 100) == false,
    "nonblocking idle scene consumed behavior")

assert(PNC.AnimationScenes.Interrupt(
    record,
    body,
    "movement"
), "movement did not interrupt an idle scene")
assert(record.runtime.animationScene == nil,
    "interrupted idle scene remained active")
assert(finished == 1,
    "idle scene interruption did not release the bump")

now = 2000
started, active = PNC.AnimationScenes.StartSurrender(
    record,
    body,
    { now = now }
)
assert(started and active.id == "social.surrender",
    "surrender scene did not start")
assert(PNC.AnimationScenes.Tick(record, body, now + 100) == true,
    "surrender scene did not block behavior")
assert(maintained == 1,
    "surrender loop was not maintained")
assert(held >= 2,
    "surrender did not hold movement")
assert(PNC.AnimationScenes.Interrupt(
    record,
    body,
    "movement"
) == false, "movement incorrectly interrupted surrender")

local lowerStarted, lowerReason =
    PNC.AnimationScenes.Request(
        record,
        body,
        "idle.sneeze",
        { now = now + 200 }
    )
assert(lowerStarted == false and lowerReason == "lower_priority",
    "lower-priority idle replaced surrender")

assert(PNC.AnimationScenes.OnExternalBump(
    record,
    body,
    "Attack1H1"
), "external combat bump did not cancel surrender")
assert(record.runtime.animationScene == nil,
    "cancelled surrender remained active")
assert(finished == 1,
    "external bump inserted a conflicting finish event")

record.runtime.nextIdleAnimationSceneAt = now
assert(PNC.AnimationScenes.Tick(record, body, now) == false,
    "injected idle scene blocked behavior")
assert(record.runtime.animationScene
        and record.runtime.animationScene.id
            == "idle.shift_weight",
    "weighted idle pool did not inject a scene")

print("pnc_animation_scenes_smoke: ok")
