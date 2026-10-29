local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Scene = require "PNC/Semantics/PNC_SemanticInteractionScene"

Catalog.ResetDraftOverlay()

local function actorProjection(id, facts, sociability)
    return {
        actor = Providers.NormalizeActor({
            id = id,
            capabilities = {
                speech = true,
                emote = true,
                movement = true,
            },
            disposition = {
                aggression = 0.2,
                confidence = 0.5,
                forgiveness = 0.5,
                sociability = sociability or 0.5,
                empathy = 0.5,
                riskTolerance = 0.5,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "idle", idle = true },
        }, "s3.test"),
        relationship = Providers.NormalizeRelationship({
            state = "neutral",
            familiarity = 4,
            approval = 0,
            respect = 0,
        }, "s3.test"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = facts or {},
        }, "s3.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "s3.test",
            relationship = "s3.test",
            knowledge = "s3.test",
        },
    }
end

local function register(spec)
    local ok, result = Catalog.Behaviors.RegisterDraft(spec)
    T.truthy(ok, result or ("register " .. tostring(spec.id)))
end

local commonOutput = {
    speech = {
        dialogueAct = "ACKNOWLEDGE",
        contentTemplateID = "semantic.social.acknowledged",
    },
}

register({
    id = "behavior.s3.memory_followup",
    owner = "S3Test",
    act = "ASK_MEMORY_FOLLOWUP",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "ASK_FOLLOWUP",
            contentTemplateID = "semantic.interaction.memory.followup",
        },
    },
    continuation = {
        mode = "emit",
        target = "source",
        expectedResponse = "ANSWER_OR_ACK",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S3_SHARE_MEMORY",
    },
    baseRelevance = 1,
    modifiers = {},
})

register({
    id = "behavior.s3.memory_answer",
    owner = "S3Test",
    act = "ANSWER",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = commonOutput,
    continuation = { mode = "terminate" },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "ASK_MEMORY_FOLLOWUP",
    },
    baseRelevance = 1,
    modifiers = {},
})

register({
    id = "behavior.s3.news_detail",
    owner = "S3Test",
    act = "ASK_NEWS_DETAIL",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "ASK_FOLLOWUP",
            contentTemplateID = "semantic.interaction.memory.followup",
        },
    },
    continuation = {
        mode = "emit",
        target = "source",
        expectedResponse = "ANSWER_OR_ACK",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S3_SHARE_NEWS",
    },
    baseRelevance = 1,
    modifiers = {},
})

register({
    id = "behavior.s3.news_answer",
    owner = "S3Test",
    act = "ANSWER_NEWS",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = {},
    outputs = {
        speech = {
            dialogueAct = "ANSWER",
            contentTemplateID = "semantic.interaction.news.acknowledge",
        },
    },
    continuation = { mode = "terminate" },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "ASK_NEWS_DETAIL",
    },
    baseRelevance = 1,
    modifiers = {},
})

register({
    id = "behavior.s3.propose_hold",
    owner = "S3Test",
    act = "PROPOSE_HOLD",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "PROPOSE",
            contentTemplateID = "semantic.social.hostile_boundary",
        },
    },
    continuation = {
        mode = "emit",
        target = "source",
        expectedResponse = "ACCEPT_OR_DISAGREE",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S3_WARN_THREAT",
    },
    baseRelevance = 1,
    modifiers = {},
})

register({
    id = "behavior.s3.accept_hold",
    owner = "S3Test",
    act = "ACCEPT",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = {},
    outputs = commonOutput,
    continuation = {
        mode = "emit",
        target = "source",
        expectedResponse = "ACK",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "PROPOSE_HOLD",
    },
    baseRelevance = 1,
    modifiers = {},
})

register({
    id = "behavior.s3.ack_hold",
    owner = "S3Test",
    act = "ACKNOWLEDGE",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = {},
    outputs = commonOutput,
    continuation = { mode = "terminate" },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "ACCEPT",
    },
    baseRelevance = 1,
    modifiers = {},
})

local invalid, invalidReason = Catalog.Behaviors.RegisterDraft({
    id = "behavior.s3.invalid_continuation",
    owner = "S3Test",
    act = "ACKNOWLEDGE",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = {},
    outputs = commonOutput,
    continuation = { mode = "emit", target = "everyone" },
    baseRelevance = 0.5,
    modifiers = {},
})
T.falsy(invalid, "invalid continuation target fails catalog validation")
T.equal(invalidReason, "behavior_continuation_target_invalid",
    "invalid continuation has stable validation reason")

local memoryFact = "fact.s3.memory"
local scene, reason = Scene.New({
    id = "scene:s3:memory",
    participants = {
        { id = "npc-a", projection = actorProjection("npc-a", { memoryFact }) },
        { id = "npc-b", projection = actorProjection("npc-b", {}, 0.9) },
    },
    perceived = true,
    maxTurns = 4,
    topic = "MEMORY",
})
T.truthy(scene, reason or "memory scene opens")

local first, firstReason = scene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-b",
    intent = "S3_SHARE_MEMORY",
    speechAct = "DISCLOSE",
    topic = "MEMORY",
    factID = memoryFact,
})
T.truthy(first, firstReason or "memory disclosure resolves")
T.equal(first.interactionPlan.behaviorID, "behavior.s3.memory_followup",
    "behavior overlay selects semantic memory follow-up")
T.equal(first.continuation.mode, "emit",
    "follow-up behavior declares semantic continuation")
T.equal(first.continuation.sourceID, "npc-b",
    "responder becomes next semantic source")
T.equal(first.continuation.targetID, "npc-a",
    "continuation targets previous source")
T.equal(first.continuation.factRefs[1], memoryFact,
    "grounded memory fact is inherited")

local memoryChain = scene:RunContinuations(first, { maxSteps = 3 })
T.equal(#memoryChain.steps, 2,
    "memory chain emits follow-up then terminates on answer")
T.equal(memoryChain.steps[1].result.stimulus.source.actorID, "npc-b",
    "memory follow-up is a real B to A semantic stimulus")
T.equal(memoryChain.steps[1].result.stimulus.semantic.intent,
    "ASK_MEMORY_FOLLOWUP",
    "next turn meaning comes from behavior act, not rendered text")
T.equal(memoryChain.steps[1].result.stimulus.payload.factRefs[1],
    memoryFact, "scene-local disclosed fact survives continuation")
T.equal(memoryChain.steps[1].result.interactionPlan.behaviorID,
    "behavior.s3.memory_answer",
    "recipient resolves the follow-up semantically")
T.equal(memoryChain.steps[2].decision.mode, "terminate",
    "answer behavior terminates the autonomous chain")
T.equal(scene.status, "closed",
    "explicit terminate continuation closes the scene")

local newsFact = "fact.s3.news"
local news = T.truthy(Scene.New({
    id = "scene:s3:news",
    participants = {
        { id = "npc-c", projection = actorProjection("npc-c", { newsFact }) },
        { id = "npc-d", projection = actorProjection("npc-d", {}, 0.8) },
    },
    perceived = true,
    maxTurns = 4,
    topic = "NEWS",
}))
local newsFirst = T.truthy(news:EmitSemanticAct({
    sourceID = "npc-c",
    responderID = "npc-d",
    intent = "S3_SHARE_NEWS",
    speechAct = "INFORM",
    factID = newsFact,
}))
local newsChain = news:RunContinuations(newsFirst, { maxSteps = 3 })
T.equal(#newsChain.steps, 2,
    "news chain asks for detail then terminates on answer")
T.equal(newsChain.steps[1].result.stimulus.semantic.intent,
    "ASK_NEWS_DETAIL", "news continuation uses semantic act metadata")
T.equal(newsChain.steps[1].result.stimulus.payload.factRefs[1],
    newsFact, "news fact remains grounded through follow-up")

local threatFact = "fact.s3.threat"
local tactical = T.truthy(Scene.New({
    id = "scene:s3:tactical",
    participants = {
        { id = "npc-e", projection = actorProjection("npc-e", { threatFact }) },
        { id = "npc-f", projection = actorProjection("npc-f", {}, 0.5) },
    },
    perceived = true,
    maxTurns = 5,
    topic = "COMBAT",
}))
local warning = T.truthy(tactical:EmitSemanticAct({
    sourceID = "npc-e",
    responderID = "npc-f",
    intent = "S3_WARN_THREAT",
    speechAct = "WARN",
    factID = threatFact,
}))
local tacticalChain = tactical:RunContinuations(warning, { maxSteps = 4 })
T.equal(#tacticalChain.steps, 3,
    "warning/proposal chain emits proposal, acceptance, then terminates")
T.equal(tacticalChain.steps[1].result.stimulus.semantic.intent,
    "PROPOSE_HOLD", "first tactical continuation is proposal")
T.equal(tacticalChain.steps[2].result.stimulus.semantic.intent,
    "ACCEPT", "second tactical continuation is acceptance")
T.equal(tacticalChain.steps[3].decision.mode, "terminate",
    "acknowledgement terminates tactical chain")

local playerFact = "fact.s3.player"
local playerScene = T.truthy(Scene.New({
    id = "scene:s3:player",
    participants = {
        {
            id = "player-one",
            kind = "player",
            isPlayer = true,
            projection = actorProjection("player-one", { playerFact }),
        },
        {
            id = "npc-g",
            projection = actorProjection("npc-g", {}, 0.9),
        },
    },
    playerParticipant = true,
    perceived = true,
    maxTurns = 4,
    topic = "MEMORY",
}))
local toNPC = T.truthy(playerScene:EmitSemanticAct({
    sourceID = "player-one",
    responderID = "npc-g",
    intent = "S3_SHARE_MEMORY",
    speechAct = "DISCLOSE",
    factID = playerFact,
}))
T.equal(toNPC.continuation.mode, "wait",
    "NPC question aimed back at player waits for external input")
T.equal(toNPC.continuation.reason, "player_input_required",
    "runtime never auto-answers on behalf of player")
local playerAdvance = T.truthy(playerScene:Continue(toNPC))
T.falsy(playerAdvance.emitted,
    "waiting player continuation emits no synthetic player turn")
T.equal(playerScene.semanticState.sequence, 1,
    "player wait does not consume another scene turn")

local stale, staleReason = playerScene:Continue({
    semanticHistoryEvent = { sequence = 0 },
})
T.equal(stale, nil, "stale continuation result is rejected")
T.equal(staleReason, "scene_continuation_stale",
    "stale continuation has stable reason")

local snapshot = playerScene:Snapshot()
T.truthy(snapshot.continuation,
    "scene snapshot exposes bounded semantic continuation state")
T.falsy(snapshot.transcriptStored,
    "continuation adds no transcript persistence")

local sceneSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionScene.lua"
)
local continuationSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionContinuation.lua"
)
T.falsy(string.find(sceneSource, "PsychopatzSemantic.Parse", 1, true),
    "Scene continuation never calls parser/NLU")
T.falsy(string.find(continuationSource, "PsychopatzSemantic.Parse", 1, true),
    "Continuation policy never calls parser/NLU")
T.falsy(string.find(continuationSource, "SpeechRealization", 1, true),
    "Continuation policy never derives meaning from rendered speech")
T.falsy(string.find(continuationSource, "ModData", 1, true),
    "Continuation owns no persistent store")

Catalog.ResetDraftOverlay()
T.finish("pnc_semantic_scene_runtime_s3_continuation_smoke")
