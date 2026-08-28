local T = require "tests/support/test"

local calls = {
    localCount = 0,
    worldCount = 0,
    localSuffix = nil,
    worldSuffix = nil,
}
local animationChanceRoll = 20

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
    },
    Core = {
        Now = function() return 1000 end,
    },
    Identity = {
        Index = function() return animationChanceRoll end,
    },
    NPCVoice = {
        MODE_LOCAL = "local",
        MODE_WORLD = "world",
    },
}

T.load("ProjectHoomans", "client", "PNC/Audio/PNC_NPCVoiceCatalog.lua")

PNC.NPCVoice.PlayLocal = function(_, suffix)
    calls.localCount = calls.localCount + 1
    calls.localSuffix = suffix
    return 101
end

PNC.NPCVoice.PlayWorld = function(_, suffix)
    calls.worldCount = calls.worldCount + 1
    calls.worldSuffix = suffix
    return 202
end

local triggers = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Audio/PNC_NPCVoiceTriggers.lua"
)

local body = {}
local snapshot = {
    id = "voice-npc",
    interestDetailed = true,
    presenceState = "live",
    alive = true,
    healthState = "normal",
    recentDamageUntil = 0,
    staminaState = "fresh",
    visualState = { moving = false },
}

T.falsy(
    triggers.Observe(snapshot, body, false, 1000),
    "initial snapshot emitted a voice event"
)
T.equal(calls.localCount, 0, "initial snapshot played local voice")
T.equal(calls.worldCount, 0, "initial snapshot played world voice")

snapshot = {
    id = "voice-npc",
    interestDetailed = true,
    presenceState = "live",
    alive = true,
    healthState = "normal",
    recentDamageUntil = 1900,
    bodyHealth = {
        wounds = {
            Hand_L = {
                type = "bite",
                createdAt = 1100,
                damage = 8,
            },
        },
    },
    staminaState = "fresh",
    visualState = { moving = false },
}

triggers.Observe(snapshot, body, false, 1100)
T.equal(calls.localCount, 1, "new damage did not play local voice")
T.equal(calls.localSuffix, "PainFromBite", "damage type was not resolved")
T.equal(calls.worldCount, 0, "hurt voice unexpectedly emitted world sound")

triggers.Observe(snapshot, body, false, 1200)
T.equal(calls.localCount, 1, "same damage snapshot replayed voice")

snapshot.recentDamageUntil = 0
snapshot.staminaState = "exhausted"
snapshot.visualState = { moving = true, isRunning = true }
triggers.Observe(snapshot, body, false, 2000)
T.equal(calls.localCount, 2, "exhaustion did not play local effort voice")
T.equal(calls.localSuffix, "Exercise", "wrong exhaustion voice suffix")

triggers.Observe(snapshot, body, false, 2100)
T.equal(calls.localCount, 2, "exhaustion snapshot replayed effort voice")

snapshot.healthState = "incapacitated"
snapshot.visualState = { moving = false, anim = "Downed" }
triggers.Observe(snapshot, body, false, 2500)
T.equal(calls.worldCount, 1, "incapacitation did not emit world voice")
T.equal(calls.worldSuffix, "DeathAlone", "wrong downed voice suffix")

triggers.Observe(snapshot, body, false, 2600)
T.equal(calls.worldCount, 1, "incapacitation snapshot replayed world voice")

T.truthy(
    triggers.Emit(body, "social.come_on", snapshot, { now = 3000 }),
    "semantic social voice event did not emit"
)
T.equal(calls.localSuffix, "LureCmon", "come-on event resolved incorrectly")

T.truthy(
    triggers.Emit(body, "action.bandage", snapshot, { now = 3500 }),
    "bandage voice event did not emit"
)
T.equal(calls.localSuffix, "ApplyBandage", "bandage event resolved incorrectly")
animationChanceRoll = 81
T.falsy(
    triggers.Emit(
        body,
        "action.bandage",
        snapshot,
        { now = 3501, occurrenceKey = "bandage-chance-check" }
    ),
    "bandage voice ignored its 80 percent chance"
)
animationChanceRoll = 20

T.truthy(
    triggers.ObserveDeath({
        id = "voice-npc",
        identitySeed = 4,
        isFemale = true,
        alive = false,
        deathMarker = true,
    }, body, 4000),
    "terminal death did not emit world voice"
)
T.equal(calls.worldCount, 2, "terminal death did not use world lane")
T.equal(calls.worldSuffix, "DeathAlone", "wrong terminal death suffix")
T.falsy(
    triggers.ObserveDeath({ id = "voice-npc", alive = false }, body, 4100),
    "terminal death replayed after it was consumed"
)
T.equal(calls.worldCount, 2, "terminal death replayed world voice")

triggers.Reset()
local initialDownedBody = {}
T.falsy(
    triggers.Observe({
        id = "initial-downed",
        interestDetailed = true,
        presenceState = "live",
        alive = true,
        healthState = "incapacitated",
        staminaState = "fresh",
        visualState = { anim = "Downed" },
    }, initialDownedBody, false, 5000),
    "initial incapacitated snapshot returned an edge result"
)
T.equal(calls.worldCount, 3, "initial incapacitation did not emit world voice")
T.equal(calls.worldSuffix, "DeathAlone", "initial incapacitation used wrong voice")

triggers.Reset()
local animationBody = {}
local animationSnapshot = {
    id = "animation-npc",
    interestDetailed = true,
    presenceState = "live",
    alive = true,
    healthState = "normal",
    staminaState = "fresh",
    visualState = { anim = "Idle" },
}
triggers.Observe(animationSnapshot, animationBody, false, 7000)
animationSnapshot.visualState = {
    anim = "Sneeze",
    sceneBump = "Sneeze",
    sceneId = "idle.ambient",
    sceneRevision = 2,
    scenePlaybackRevision = 4,
    sceneStepId = "sneeze",
    sceneStepStartedAt = 7000,
}
triggers.Observe(animationSnapshot, animationBody, false, 7100)
T.equal(calls.localSuffix, "SneezeLight",
    "sneeze animation used wrong respiratory voice")
local animationVoiceCount = calls.localCount
triggers.Observe(animationSnapshot, animationBody, false, 7200)
T.equal(calls.localCount, animationVoiceCount,
    "sneeze animation replayed voice on the same snapshot")

animationSnapshot.visualState = { anim = "Idle" }
triggers.Observe(animationSnapshot, animationBody, false, 13000)
animationChanceRoll = 21
animationSnapshot.visualState = {
    anim = "Sneeze",
    sceneBump = "Sneeze",
    sceneId = "idle.ambient",
    sceneRevision = 2,
    scenePlaybackRevision = 5,
    sceneStepId = "sneeze",
    sceneStepStartedAt = 13000,
}
triggers.Observe(animationSnapshot, animationBody, false, 13100)
T.equal(calls.localCount, animationVoiceCount,
    "sneeze animation ignored the 20 percent chance")

triggers.Reset()
local treatmentBody = {}
local treatmentSnapshot = {
    id = "treatment-npc",
    interestDetailed = true,
    presenceState = "live",
    alive = true,
    healthState = "normal",
    staminaState = "fresh",
    visualState = { moving = false },
    treatmentState = { phase = "idle" },
}
triggers.Observe(treatmentSnapshot, treatmentBody, false, 6000)
treatmentSnapshot.treatmentState = {
    phase = "bandaging",
    partId = "Hand_L",
    startedAt = 6000,
}
animationChanceRoll = 20
triggers.Observe(treatmentSnapshot, treatmentBody, false, 6100)
T.equal(calls.localSuffix, "ApplyBandage", "treatment edge used wrong voice")
local treatmentVoiceCount = calls.localCount
triggers.Observe(treatmentSnapshot, treatmentBody, false, 6200)
T.equal(calls.localCount, treatmentVoiceCount,
    "treatment snapshot replayed bandage voice")

triggers.Reset()
local sleepBody = {}
local sleepSnapshot = {
    id = "sleep-npc",
    interestDetailed = true,
    presenceState = "live",
    alive = true,
    healthState = "normal",
    staminaState = "fresh",
    visualState = { anim = "Idle" },
}
animationChanceRoll = 81
triggers.Observe(sleepSnapshot, sleepBody, false, 14000)
sleepSnapshot.visualState = {
    anim = "Bob_Asleep",
    sceneBump = "SleepBed",
    sceneId = "facility.sleep.bed",
    sceneRevision = 1,
    scenePlaybackRevision = 1,
    sceneStepId = "sleep",
    sceneStepStartedAt = 14000,
}
triggers.Observe(sleepSnapshot, sleepBody, false, 14100)
T.equal(calls.localSuffix, "Sleep", "sleep animation used wrong voice")
local sleepVoiceCount = calls.localCount
triggers.Observe(sleepSnapshot, sleepBody, false, 14200)
T.equal(calls.localCount, sleepVoiceCount,
    "sleep animation replayed voice on the same occurrence")

local animationRules = PNC.NPCVoice.Catalog.AnimationTriggers
animationRules[#animationRules + 1] = {
    id = "animation.future_gesture",
    eventID = "social.tsk",
    match = {
        fields = { "anim" },
        values = { "FutureGesture" },
        mode = "equals",
    },
    chancePercent = 100,
    cooldown = 0,
}
local futureBody = {}
local futureSnapshot = {
    id = "future-animation-npc",
    interestDetailed = true,
    presenceState = "live",
    alive = true,
    healthState = "normal",
    staminaState = "fresh",
    visualState = { anim = "Idle" },
}
triggers.Observe(futureSnapshot, futureBody, false, 15000)
futureSnapshot.visualState = { anim = "FutureGesture" }
triggers.Observe(futureSnapshot, futureBody, false, 15100)
T.equal(calls.localSuffix, "LureTsk",
    "generic animation rule did not use its configured event")

T.truthy(
    PNC.NPCVoice.Catalog.Get("social.come_on").suffix == "LureCmon",
    "voice catalog lost future conversation event"
)

T.finish("pnc_npc_voice_triggers_smoke")
