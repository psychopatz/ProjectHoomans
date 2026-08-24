local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Visuals/PNC_AnimationScenes.lua"
local DEFINITIONS =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Visuals/PNC_AnimationSceneDefinitions.lua"
local WORK_SCENES =
    T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Production/PNC_WorkAnimationScenes.lua"

local now = 1000
local played = {}
local maintained = 0
local finished = 0
local held = 0
local pathResets = 0
local pathResetReasons = {}
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
            T.truthy(bump == "Surrender",
                "persistent scene maintained wrong bump")
            T.truthy(leaseUntil > now,
                "persistent scene lease was not extended")
            T.truthy(options and options.sceneId == "social.surrender",
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
    PathService = {
        Commands = {
            Reset = function(pathRecord, _, reason)
                pathResets = pathResets + 1
                pathResetReasons[#pathResetReasons + 1] = reason
                pathRecord.runtime.pathing = nil
                pathRecord.runtime.localNavigation = nil
            end,
        },
    },
}

T.load(FILE)
T.load(DEFINITIONS)
T.load(WORK_SCENES)

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

T.truthy(PNC.AnimationScenes.Get("idle.shift_weight").bump
        == "ShiftWeight",
    "default idle scene missing")
T.truthy(PNC.AnimationScenes.Get("social.surrender").blocking == true,
    "surrender scene is not blocking")
T.truthy(PNC.AnimationScenes.Get("idle.ambient").repeatMode == "loop",
    "idle scene repeat policy is not explicit")
T.truthy(PNC.AnimationScenes.Get("facility.sleep.floor").steps[1].loop == true,
    "floor sleep must remain in one persistent XML playback")
T.truthy(PNC.AnimationScenes.Get("facility.sleep.bed").steps[1].loop == true,
    "bed sleep must remain in one persistent XML playback")
T.truthy(PNC.AnimationScenes.Get("facility.sleep.bed").steps[1].durationMs == 0,
    "bed sleep must not be force-finished on a timer")
local livingScene = PNC.AnimationScenes.Get("facility.living.sit")
T.truthy(livingScene and livingScene.repeatMode == "loop"
        and #livingScene.steps == 4,
    "living-room sitting scene must compose all supplied sit primitives")
T.truthy(livingScene.steps[1].bump == "Sit"
        and livingScene.steps[4].bump == "SitRubHands",
    "living-room scene uses the supplied sitting bumps")
local drinkScene = PNC.AnimationScenes.Get("facility.water.drink")
T.truthy(drinkScene and drinkScene.bump == "Drink"
        and drinkScene.repeatMode == "once",
    "spigot drinking scene must be a one-shot drink")
T.truthy(PNC.AnimationScenes.Get("production.craft").blocking == false,
    "production animation must not block work progress ticks")
local researchDefinition =
    PNC.AnimationScenes.Get("production.research")
T.truthy(researchDefinition.repeatMode == "loop"
        and researchDefinition.blocking == false
        and #researchDefinition.steps == 5,
    "research must repeat its nonblocking animation scene")
T.truthy(researchDefinition.steps[1].bump == "ReadBook"
        and researchDefinition.steps[2].bump == "WipeBrow"
        and researchDefinition.steps[4].bump == "WipeHead"
        and researchDefinition.steps[5].bump == "Yes",
    "research scene does not use the supplied XML nodes")
local constructionDefinition =
    PNC.AnimationScenes.Get("production.construct")
T.truthy(constructionDefinition.repeatMode == "loop"
        and #constructionDefinition.steps == 2,
    "construction must repeat its two-step animation scene")
T.truthy(constructionDefinition.steps[1].bump == "Hammer"
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
T.truthy(registered and custom.bump == "WaveHi",
    "custom scene registration failed")
T.truthy(custom.repeatMode == "once",
    "one-off scene did not default to once")

local started, active = PNC.AnimationScenes.Request(
    record,
    body,
    "idle.shift_weight",
    { now = now }
)
T.truthy(started and active.id == "idle.shift_weight",
    "idle scene did not start")
T.truthy(played[#played].bump == "ShiftWeight",
    "idle scene did not select its registered bump")
T.truthy(played[#played].options.sceneId == "idle.shift_weight",
    "scene playback did not carry an ownership token")
T.truthy(bodyModData.PNC_ClientAnimationSceneKey
        == "idle.shift_weight:1:1",
    "local scene snapshot dedupe key missing")
T.truthy(PNC.AnimationScenes.Tick(record, body, now + 100) == false,
    "nonblocking idle scene consumed behavior")

T.truthy(PNC.AnimationScenes.Interrupt(
    record,
    body,
    "movement"
), "movement did not interrupt an idle scene")
T.truthy(record.runtime.animationScene == nil,
    "interrupted idle scene remained active")
T.truthy(finished == 1,
    "idle scene interruption did not release the bump")

now = 2000
record.runtime.pathing = { phase = "active" }
record.runtime.localNavigation = {
    provider = "engine_path",
    nativeActive = true,
}
record.runtime.followState = { ownerMoving = true }
started, active = PNC.AnimationScenes.StartSurrender(
    record,
    body,
    { now = now }
)
T.truthy(started and active.id == "social.surrender",
    "surrender scene did not start")
T.truthy(PNC.AnimationScenes.Tick(record, body, now + 100) == true,
    "surrender scene did not block behavior")
T.truthy(maintained == 1,
    "surrender loop was not maintained")
T.truthy(held >= 2,
    "surrender did not hold movement")
T.equal(pathResets, 1,
    "blocking scene did not synchronously reset movement")
T.equal(pathResetReasons[1], "animation_scene:social.surrender",
    "blocking scene reset used the wrong ownership reason")
T.falsy(record.runtime.pathing,
    "blocking scene retained the previous movement lane")
T.falsy(record.runtime.localNavigation,
    "blocking scene retained native navigation")
T.falsy(record.runtime.followState.ownerMoving,
    "blocking scene retained stale follow movement")
T.truthy(PNC.AnimationScenes.Interrupt(
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
T.truthy(lowerStarted == false and lowerReason == "lower_priority",
    "lower-priority idle replaced surrender")

T.truthy(PNC.AnimationScenes.OnExternalBump(
    record,
    body,
    "Attack1H1"
), "external combat bump did not cancel surrender")
T.truthy(record.runtime.animationScene == nil,
    "cancelled surrender remained active")
T.truthy(finished == 1,
    "external bump inserted a conflicting finish event")

record.runtime.nextIdleAnimationSceneAt = now
T.truthy(PNC.AnimationScenes.Tick(record, body, now) == false,
    "injected idle scene blocked behavior")
T.truthy(record.runtime.animationScene
        and record.runtime.animationScene.id
            == "idle.ambient",
    "idle pool did not inject the composite scene")
local idleSequence = record.runtime.animationScene
T.truthy(idleSequence.sequenceLength == 4
        and idleSequence.playbackRevision == 1,
    "composite idle did not expose its primitive queue")
local firstBump = idleSequence.bump
local firstFinish = idleSequence.finishAt
now = firstFinish
PNC.AnimationScenes.Tick(record, body, now)
T.truthy(record.runtime.animationScene == idleSequence
        and idleSequence.bump == nil
        and idleSequence.nextStepAt > now,
    "composite idle did not enter its inter-step gap")
now = idleSequence.nextStepAt
PNC.AnimationScenes.Tick(record, body, now)
T.truthy(idleSequence.bump ~= nil
        and idleSequence.bump ~= firstBump
        and idleSequence.playbackRevision == 2,
    "composite idle did not advance to another primitive")
T.truthy(PNC.AnimationScenes.Interrupt(
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
T.truthy(started
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
T.truthy(started
        and PNC.AnimationScenes.InterruptForSafety(
            record,
            body,
            now
        ) == false
        and record.runtime.animationScene ~= nil,
    "stale movement intent cancelled an otherwise idle scene")
record.runtime.pathing = { phase = "active" }
T.truthy(PNC.AnimationScenes.InterruptForSafety(
    record,
    body,
    now
), "active movement path did not cancel an idle scene")
record.runtime.pathing = nil
record.runtime.moveIntent = nil

record.runtime.nextIdleAnimationSceneAt = now
record.runtime.target = { id = "zombie" }
T.truthy(PNC.AnimationScenes.Tick(record, body, now) == false
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
T.truthy(started and PNC.AnimationScenes.Tick(record, body, now + 1) == false,
    "scene lifecycle callback did not complete the scene")
T.truthy(callbackTicks == 1 and callbackStopReason == "callback_complete",
    "scene lifecycle callbacks were not dispatched")
T.truthy(record.runtime.animationScene == nil,
    "callback-completed scene remained active")

local constructionStarted, constructionScene =
    PNC.AnimationScenes.Request(record, body, "production.construct", {
        now = now,
    })
T.truthy(constructionStarted and played[#played].bump == "Hammer",
    "construction did not start with the hammer animation")
now = constructionScene.finishAt
PNC.AnimationScenes.Tick(record, body, now)
now = constructionScene.nextStepAt
PNC.AnimationScenes.Tick(record, body, now)
T.truthy(played[#played].bump == "HammerLow"
        and constructionScene.repeatMode == "loop",
    "construction did not advance to the low hammer animation")
T.truthy(PNC.AnimationScenes.Interrupt(record, body, "combat"),
    "construction scene did not release for combat")

record.runtime.pathing = { phase = "active" }
record.runtime.localNavigation = {
    provider = "engine_path",
    nativeActive = true,
}
record.runtime.followState = { ownerMoving = true }
local eatStarted = PNC.AnimationScenes.Request(
    record,
    body,
    "survival.eat.inventory",
    { now = now }
)
T.truthy(eatStarted,
    "eating scene did not start")
T.falsy(record.runtime.pathing,
    "eating scene retained the previous movement lane")
T.falsy(record.runtime.localNavigation,
    "eating scene retained native navigation")
T.falsy(record.runtime.followState.ownerMoving,
    "eating scene retained stale follow movement")
T.truthy(PNC.AnimationScenes.Tick(record, body, now + 1),
    "eating scene was interrupted by pre-scene movement state")

local holdAnimationCalls = 0
local holdMotionClears = 0
PNC.Animation.Apply = function()
    holdAnimationCalls = holdAnimationCalls + 1
end
PNC.MotionHints = { Clear = function()
    holdMotionClears = holdMotionClears + 1
end }
PNC.PathService = {}
T.load(T.path("ProjectHoomans", "shared", "PNC/Core/")
    .. "Pathing/PNC_PathService/PNC_PathService_Context.lua")
record.runtime.animationScene = { id = "production.construct", bump = "Hammer" }
PNC.PathService.Internal.applyHoldAnimation(body, record, {
    visualMovingUntil = now + 1000,
})
T.truthy(holdAnimationCalls == 0,
    "path hold overwrote the active construction scene with Idle")
T.truthy(holdMotionClears == 1,
    "path hold did not clear stale movement presentation for work")
T.finish("pnc_animation_scenes_smoke")
