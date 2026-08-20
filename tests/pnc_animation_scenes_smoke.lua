local FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Visuals/PNC_AnimationScenes.lua"
local DEFINITIONS =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Visuals/PNC_AnimationSceneDefinitions.lua"
local WORK_SCENES =
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Production/PNC_WorkAnimationScenes.lua"

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
dofile(WORK_SCENES)

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
assert(PNC.AnimationScenes.Get("idle.ambient").repeatMode == "loop",
    "idle scene repeat policy is not explicit")
assert(PNC.AnimationScenes.Get("facility.sleep.floor").steps[1].loop == true,
    "floor sleep must remain in one persistent XML playback")
assert(PNC.AnimationScenes.Get("facility.sleep.bed").steps[1].loop == true,
    "bed sleep must remain in one persistent XML playback")
assert(PNC.AnimationScenes.Get("facility.sleep.bed").steps[1].durationMs == 0,
    "bed sleep must not be force-finished on a timer")
local livingScene = PNC.AnimationScenes.Get("facility.living.sit")
assert(livingScene and livingScene.repeatMode == "loop"
        and #livingScene.steps == 4,
    "living-room sitting scene must compose all supplied sit primitives")
assert(livingScene.steps[1].bump == "Sit"
        and livingScene.steps[4].bump == "SitRubHands",
    "living-room scene uses the supplied sitting bumps")
local drinkScene = PNC.AnimationScenes.Get("facility.water.drink")
assert(drinkScene and drinkScene.bump == "Drink"
        and drinkScene.repeatMode == "once",
    "spigot drinking scene must be a one-shot drink")
assert(PNC.AnimationScenes.Get("production.craft").blocking == false,
    "production animation must not block work progress ticks")
local researchDefinition =
    PNC.AnimationScenes.Get("production.research")
assert(researchDefinition.repeatMode == "loop"
        and researchDefinition.blocking == false
        and #researchDefinition.steps == 5,
    "research must repeat its nonblocking animation scene")
assert(researchDefinition.steps[1].bump == "ReadBook"
        and researchDefinition.steps[2].bump == "WipeBrow"
        and researchDefinition.steps[4].bump == "WipeHead"
        and researchDefinition.steps[5].bump == "Yes",
    "research scene does not use the supplied XML nodes")
local constructionDefinition =
    PNC.AnimationScenes.Get("production.construct")
assert(constructionDefinition.repeatMode == "loop"
        and #constructionDefinition.steps == 2,
    "construction must repeat its two-step animation scene")
assert(constructionDefinition.steps[1].bump == "Hammer"
        and constructionDefinition.steps[2].bump == "HammerLow",
    "construction scene does not use the hammer XML nodes")

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
assert(custom.repeatMode == "once",
    "one-off scene did not default to once")

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
        == "idle.shift_weight:1:1",
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
            == "idle.ambient",
    "idle pool did not inject the composite scene")
local idleSequence = record.runtime.animationScene
assert(idleSequence.sequenceLength == 4
        and idleSequence.playbackRevision == 1,
    "composite idle did not expose its primitive queue")
local firstBump = idleSequence.bump
local firstFinish = idleSequence.finishAt
now = firstFinish
PNC.AnimationScenes.Tick(record, body, now)
assert(record.runtime.animationScene == idleSequence
        and idleSequence.bump == nil
        and idleSequence.nextStepAt > now,
    "composite idle did not enter its inter-step gap")
now = idleSequence.nextStepAt
PNC.AnimationScenes.Tick(record, body, now)
assert(idleSequence.bump ~= nil
        and idleSequence.bump ~= firstBump
        and idleSequence.playbackRevision == 2,
    "composite idle did not advance to another primitive")
assert(PNC.AnimationScenes.Interrupt(
    record,
    body,
    "combat"
), "combat did not short-circuit the idle queue")

started = PNC.AnimationScenes.Request(
    record,
    body,
    "idle.ambient",
    { now = now }
)
record.runtime.followState = { ownerMoving = true }
assert(started
        and PNC.AnimationScenes.InterruptForSafety(
            record,
            body,
            now
        )
        and record.runtime.animationScene == nil,
    "moving owner did not snap a follower out of its idle queue")
record.runtime.followState = nil

started = PNC.AnimationScenes.Request(
    record,
    body,
    "idle.ambient",
    { now = now }
)
record.runtime.moveIntent = {
    kind = "move",
    updatedAt = now - 5000,
}
assert(started
        and PNC.AnimationScenes.InterruptForSafety(
            record,
            body,
            now
        ) == false
        and record.runtime.animationScene ~= nil,
    "stale movement intent cancelled an otherwise idle scene")
record.runtime.pathing = { phase = "active" }
assert(PNC.AnimationScenes.InterruptForSafety(
    record,
    body,
    now
), "active movement path did not cancel an idle scene")
record.runtime.pathing = nil
record.runtime.moveIntent = nil

record.runtime.nextIdleAnimationSceneAt = now
record.runtime.target = { id = "zombie" }
assert(PNC.AnimationScenes.Tick(record, body, now) == false
        and record.runtime.animationScene == nil,
    "combat state allowed a fresh idle queue")
record.runtime.target = nil

local callbackTicks = 0
local callbackStopReason
PNC.AnimationScenes.Register("test.lifecycle", {
    bump = "Sneeze",
    durationMs = 1000,
    blocking = true,
    onTick = function()
        callbackTicks = callbackTicks + 1
        return false
    end,
    onStop = function(_, _, _, reason)
        callbackStopReason = reason
    end,
})
started = PNC.AnimationScenes.Request(record, body, "test.lifecycle", {
    now = now,
})
assert(started and PNC.AnimationScenes.Tick(record, body, now + 1) == false,
    "scene lifecycle callback did not complete the scene")
assert(callbackTicks == 1 and callbackStopReason == "callback_complete",
    "scene lifecycle callbacks were not dispatched")
assert(record.runtime.animationScene == nil,
    "callback-completed scene remained active")

local constructionStarted, constructionScene =
    PNC.AnimationScenes.Request(record, body, "production.construct", {
        now = now,
    })
assert(constructionStarted and played[#played].bump == "Hammer",
    "construction did not start with the hammer animation")
now = constructionScene.finishAt
PNC.AnimationScenes.Tick(record, body, now)
now = constructionScene.nextStepAt
PNC.AnimationScenes.Tick(record, body, now)
assert(played[#played].bump == "HammerLow"
        and constructionScene.repeatMode == "loop",
    "construction did not advance to the low hammer animation")
assert(PNC.AnimationScenes.Interrupt(record, body, "combat"),
    "construction scene did not release for combat")

local holdAnimationCalls = 0
local holdMotionClears = 0
PNC.Animation.Apply = function()
    holdAnimationCalls = holdAnimationCalls + 1
end
PNC.MotionHints = { Clear = function()
    holdMotionClears = holdMotionClears + 1
end }
PNC.PathService = {}
dofile("Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
    .. "Pathing/PNC_PathService/PNC_PathService_Context.lua")
record.runtime.animationScene = { id = "production.construct", bump = "Hammer" }
PNC.PathService.Internal.applyHoldAnimation(body, record, {
    visualMovingUntil = now + 1000,
})
assert(holdAnimationCalls == 0,
    "path hold overwrote the active construction scene with Idle")
assert(holdMotionClears == 1,
    "path hold did not clear stale movement presentation for work")

print("pnc_animation_scenes_smoke: ok")
