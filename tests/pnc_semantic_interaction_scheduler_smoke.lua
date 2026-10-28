local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Scheduler = require "PNC/Semantics/PNC_SemanticInteractionScheduler"

local humanBefore = Catalog.IndexSnapshot("HUMAN_UTTERANCE")
local worldBefore = Catalog.IndexSnapshot("WORLD_EVENT")
T.equal(humanBefore.beatCount, 3,
    "human stimulus initially indexes only the three social beats")
T.equal(humanBefore.oneShotBehaviorCount, 1,
    "human stimulus indexes the thanks one-shot behavior")

for index = 1, 10 do
    local id = string.format("behavior.world_probe_%02d", index)
    local ok, reason = Catalog.Behaviors.RegisterDraft({
        id = id,
        version = 1,
        owner = "SchedulerSmoke",
        act = "WORLD_PROBE",
        mode = "one_shot",
        stimuli = { "WORLD_EVENT" },
        requiredCapabilities = {},
        outputs = {},
        when = {
            path = "stimulus.type",
            op = "eq",
            value = "WORLD_EVENT",
        },
        baseRelevance = 0.1,
        modifiers = {},
    })
    T.truthy(ok, reason or ("register " .. id))
end

for index = 1, 20 do
    local id = string.format("beat.world_probe_%02d", index)
    local ok, reason = Catalog.Beats.RegisterDraft({
        id = id,
        version = 1,
        owner = "SchedulerSmoke",
        stimuli = { "WORLD_EVENT" },
        entry = {
            path = "stimulus.type",
            op = "eq",
            value = "WORLD_EVENT",
        },
        maintain = {
            path = "scene.ended",
            op = "falsy",
        },
        exit = {
            path = "scene.ended",
            op = "truthy",
        },
        candidates = {
            {
                behavior = "behavior.warn",
                relevance = 0.2,
            },
        },
        baseRelevance = 0.1,
        maxTurns = 1,
        cooldownTurns = 0,
    })
    T.truthy(ok, reason or ("register " .. id))
end

local humanAfter = Catalog.IndexSnapshot("HUMAN_UTTERANCE")
local worldAfter = Catalog.IndexSnapshot("WORLD_EVENT")
T.equal(humanAfter.beatCount, 3,
    "WORLD_EVENT draft beats do not enter HUMAN_UTTERANCE index")
T.equal(humanAfter.oneShotBehaviorCount, 1,
    "WORLD_EVENT one-shots do not enter HUMAN_UTTERANCE index")
T.equal(worldAfter.beatCount, worldBefore.beatCount + 20,
    "WORLD_EVENT index adds its twenty draft beats to the canonical baseline")
T.equal(
    worldAfter.oneShotBehaviorCount,
    worldBefore.oneShotBehaviorCount + 10,
    "WORLD_EVENT index adds its ten one-shot drafts to the canonical baseline"
)
T.truthy(worldAfter.canonicalBeatCount + 20 > humanAfter.beatCount,
    "indexed candidate count is smaller than total effective beat count")

local participantRuntime = Scheduler.New({
    maxActiveScenes = 4,
    maxParticipants = 3,
    maxTurns = 3,
})
local tooMany, participantReason = participantRuntime:OpenScene({
    id = "scene.too_many",
    participants = { "a", "b", "c", "d" },
    perceived = true,
})
T.falsy(tooMany, "scene participant cap rejects oversized scenes")
T.equal(participantReason, "scene_participant_limit",
    "oversized scene exposes bounded participant failure")

local runtime = Scheduler.New({
    maxActiveScenes = 4,
    maxParticipants = 3,
    maxTurns = 3,
})
for index = 1, 4 do
    local scene, reason = runtime:OpenScene({
        id = "scene." .. tostring(index),
        participants = { "npc-a-" .. index, "npc-b-" .. index },
        perceived = index == 1,
        distance = index == 2 and 999 or 20,
        playerParticipant = index == 1,
    })
    T.truthy(scene, reason or "scene opens")
end
local fifth, fifthReason = runtime:OpenScene({
    id = "scene.5",
    participants = { "a", "b" },
    perceived = true,
})
T.falsy(fifth, "active scene cap rejects a fifth scene")
T.equal(fifthReason, "scene_active_limit",
    "active scene cap reports a stable reason")

-- scene.2 is distant. Flavor-only opportunities must never enter the director.
local ambient = {
    type = "AMBIENT_SOCIAL_OPPORTUNITY",
    source = {
        kind = "engine",
        providerID = "scheduler.smoke",
    },
    targets = { "npc-a-2", "npc-b-2" },
    semantic = {
        topic = "ambient",
    },
}
for index = 1, 500 do
    local result, reason = runtime:HandleStimulus(
        "scene.2",
        ambient,
        nil,
        {},
        { meaningfulOutcome = false }
    )
    T.truthy(result, reason or "distant ambient event handled")
    T.truthy(result.skipped == true,
        "distant flavor-only event is suppressed")
    T.truthy(result.directorEvaluated == false,
        "distant flavor-only event does not run the director")
end

local dialogueContext = {
    npcID = "npc-a-1",
    relationship = {
        familiarity = 1,
        approval = 0,
    },
    npcPersonality = {
        aggression = 0.4,
        confidence = 0.5,
        forgiveness = 0.5,
    },
    dialogueSituation = {
        npc = {
            inCombat = false,
            emotion = {
                highest = "calm",
                urgency = "stable",
            },
        },
    },
    semanticDialogueContext = {
        flowSessions = {},
        agenda = {},
        recentTurns = {},
        currentTopic = "social",
    },
}
local state = {
    sequence = 0,
    currentTopic = "social",
    Recent = function()
        return {}
    end,
}
local hostile = {
    type = "HUMAN_UTTERANCE",
    source = {
        kind = "human",
        actorID = "player",
        providerID = "scheduler.smoke",
    },
    targets = { "npc-a-1" },
    semantic = {
        intent = "HOSTILE_REMARK",
        speechAct = "HOSTILE_REMARK",
        confidence = 1,
    },
    text = "semantic-only scheduler smoke",
}
local evaluated, evalReason = runtime:HandleStimulus(
    "scene.1",
    hostile,
    state,
    dialogueContext,
    { meaningfulOutcome = true }
)
T.truthy(evaluated, evalReason or "nearby event evaluates")
T.truthy(evaluated.directorEvaluated == true,
    "perceived/player event evaluates the director")
T.truthy(evaluated.realization.speech == true,
    "player/full LOD allows speech realization")
T.equal(evaluated.preview.metrics.indexedBeatCandidateCount, 3,
    "human event only considers the three human-indexed beats")
T.truthy(
    evaluated.preview.metrics.indexedBeatCandidateCount
        < evaluated.preview.metrics.catalogBeatCount,
    "human event does not scan twenty unrelated WORLD_EVENT beats"
)
T.equal(evaluated.preview.metrics.indexedOneShotBehaviorCount, 1,
    "human event does not scan ten unrelated WORLD_EVENT one-shots")
T.truthy(
    evaluated.preview.metrics.beatCandidatesEvaluated <= 16,
    "beat evaluation remains bounded"
)

local snapshot = runtime:Snapshot()
T.equal(snapshot.activeSceneCount, 4,
    "event handling never auto-creates pairwise scenes")
T.equal(snapshot.metrics.eventsSubmitted, 501,
    "scheduler records explicit submitted events only")
T.equal(snapshot.metrics.directorEvaluations, 1,
    "five hundred distant flavor events caused zero director evaluations")
T.equal(snapshot.metrics.distantFlavorSkipped, 500,
    "distant suppression count is observable")
T.equal(snapshot.metrics.maxActiveScenes, 4,
    "active scene instrumentation stays bounded")
T.equal(snapshot.metrics.maxParticipants, 2,
    "participant instrumentation records actual bounded cardinality")

local nearbyRuntime = Scheduler.New({ maxTurns = 2 })
local nearbyScene, nearbyReason = nearbyRuntime:OpenScene({
    id = "scene.nearby_unperceived",
    participants = { "a", "b" },
    perceived = false,
    distance = 10,
})
T.truthy(nearbyScene, nearbyReason or "nearby unperceived scene opens")
local nearbyResult = nearbyRuntime:HandleStimulus(
    "scene.nearby_unperceived",
    hostile,
    state,
    dialogueContext,
    { meaningfulOutcome = true }
)
T.truthy(nearbyResult and nearbyResult.directorEvaluated == true,
    "nearby unperceived meaningful event can run semantics")
T.truthy(nearbyResult.realization.semanticOnly == true,
    "nearby unperceived LOD skips presentation realization")
T.truthy(nearbyResult.realization.speech == false,
    "nearby unperceived LOD does not realize speech")

T.finish("pnc_semantic_interaction_scheduler_smoke")
