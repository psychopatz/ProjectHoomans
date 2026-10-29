local T = require "tests/support/test"
T.addPackagePaths()

local sent = {}
PNC = {
    Const = {
        CMD_SEMANTIC_SCENE_SPEECH = "SemanticSceneSpeech",
    },
    Network = {
        Internal = {
            SendToPlayer = function(player, command, payload)
                sent[#sent + 1] = {
                    player = player,
                    command = command,
                    payload = payload,
                }
                return true
            end,
        },
    },
}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Transport = require "PNC/Semantics/PNC_SemanticInteractionSceneTransport"
local Affordances = require
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticDialogueSuggestions_GeneratedAffordanceProvider"

Catalog.ResetDraftOverlay()

local function projection(id, sociability)
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
        }, "s4.test"),
        relationship = Providers.NormalizeRelationship({
            state = "neutral",
            familiarity = 3,
            approval = 0,
            respect = 0,
        }, "s4.test"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "s4.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "s4.test",
            relationship = "s4.test",
            knowledge = "s4.test",
        },
    }
end

local function register(spec)
    local ok, value = Catalog.Behaviors.RegisterDraft(spec)
    T.truthy(ok, value or ("register " .. tostring(spec.id)))
end

register({
    id = "behavior.s4.player_prompt",
    owner = "S4Test",
    act = "INFORM",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "INFORM",
            contentTemplateID = "semantic.social.acknowledged",
        },
    },
    continuation = {
        mode = "emit",
        target = "source",
        expectedResponse = "ACK_OR_FOLLOWUP",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S4_PLAYER_PROMPT",
    },
    baseRelevance = 1,
    modifiers = {},
})

register({
    id = "behavior.s4.player_ack",
    owner = "S4Test",
    act = "ACKNOWLEDGE",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "ACKNOWLEDGE",
            contentTemplateID = "semantic.social.acknowledged",
        },
    },
    continuation = {
        mode = "terminate",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "ACKNOWLEDGE",
    },
    baseRelevance = 1,
    modifiers = {},
})

local runtime = Runtime.New({
    maxActiveScenes = 4,
    maxParticipants = 4,
    maxTurns = 6,
    clock = function() return 1000 end,
})

local scene, sceneID = runtime:Open({
    id = "scene:s4:player",
    participants = {
        {
            id = "player-one",
            kind = "player",
            isPlayer = true,
            projection = projection("player-one", 0.5),
        },
        {
            id = "npc-a",
            kind = "npc",
            projection = projection("npc-a", 0.8),
        },
    },
    playerParticipant = true,
    perceived = true,
    distance = 4,
    ttlMs = 10000,
    topic = "SCENE_TEST",
})
T.truthy(scene, sceneID or "player scene opens")

local first, firstReason = scene:EmitSemanticAct({
    sourceID = "player-one",
    responderID = "npc-a",
    intent = "S4_PLAYER_PROMPT",
    speechAct = "QUESTION",
    topic = "SCENE_TEST",
})
T.truthy(first, firstReason or "NPC response resolves once")
T.truthy(first.presentation and first.presentation.speech,
    "resolved scene turn has already-selected NPC speech")
T.equal(first.continuation.mode, "wait",
    "continuation aimed at player becomes an external wait")
T.equal(first.continuation.reason, "player_input_required",
    "player is never auto-answered")

local recipient = T.truthy(Transport.BuildPacket(scene, first, {
    actorID = "player-one",
    role = "recipient",
}))
T.equal(recipient.audienceRole, "recipient",
    "addressed player is semantic recipient")
T.falsy(recipient.observerOnly,
    "addressed player is not observer-only")
T.truthy(recipient.interaction,
    "addressed player receives existing lifecycle envelope")
T.truthy(recipient.sceneHandoff,
    "addressed player receives bounded Scene resume token")
T.equal(recipient.sceneHandoff.expectedSceneSequence,
    first.semanticHistoryEvent.sequence,
    "resume token is tied to exact semantic turn")
T.truthy(recipient.responsePlan,
    "addressed player receives selected semantic response plan")

local observer = T.truthy(Transport.BuildPacket(scene, first, {
    actorID = "player-observer",
    role = "observer",
}))
T.equal(observer.audienceRole, "observer",
    "nearby nonparticipant remains observer")
T.truthy(observer.observerOnly,
    "observer packet is explicitly presentation-only")
T.equal(observer.text, recipient.text,
    "observer sees same already-selected line")
T.equal(observer.eventID, recipient.eventID,
    "fanout reuses one semantic turn/event identity")
T.equal(observer.interaction, nil,
    "observer receives no player lifecycle envelope")
T.equal(observer.sceneHandoff, nil,
    "observer receives no Scene resume token")
T.equal(observer.responsePlan, nil,
    "observer receives no response plan")
T.equal(#observer.offerIDs, 0,
    "observer receives zero player response offers")

local candidates = Affordances.collect({
    sceneResponsePlan = recipient.responsePlan,
})
T.truthy(#candidates > 0,
    "addressed Scene response plan drives existing generated affordances")
local strategies = {}
for _, row in ipairs(candidates) do
    strategies[row.strategy] = true
end
T.truthy(strategies.ACKNOWLEDGE or strategies.ASK_FOLLOWUP,
    "scene INFORM response produces ordinary player continuation choices")

sent = {}
local audience = {
    { player = { id = "p1" }, actorID = "player-one", role = "recipient" },
}
for index = 2, 12 do
    audience[#audience + 1] = {
        player = { id = "p" .. tostring(index) },
        actorID = "observer-" .. tostring(index),
        role = "observer",
    }
end
local delivered, deliveryReason = Transport.Deliver(
    scene, first, audience
)
T.equal(delivered, 8,
    "multiplayer/local Scene audience fanout is hard-capped at eight")
T.equal(deliveryReason, "delivered", "bounded fanout reports delivery")
T.equal(#sent, 8, "transport performs exactly one send per admitted listener")
for index = 1, #sent do
    T.equal(sent[index].command, "SemanticSceneSpeech",
        "all audience packets use one bounded Scene speech command")
    T.equal(sent[index].payload.eventID, recipient.eventID,
        "fanout never reruns semantic selection per observer")
end

local wrong, wrongReason = runtime:ResumePlayer(
    sceneID, "observer-2", first.semanticHistoryEvent.sequence, {
        intent = "ACKNOWLEDGE",
        speechAct = "ACKNOWLEDGE",
    }
)
T.equal(wrong, nil, "observer cannot resume addressed Scene")
T.equal(wrongReason, "scene_player_not_participant",
    "observer rejection reason is explicit")

local stale, staleReason = runtime:ResumePlayer(
    sceneID, "player-one", first.semanticHistoryEvent.sequence - 1, {
        intent = "ACKNOWLEDGE",
        speechAct = "ACKNOWLEDGE",
    }
)
T.equal(stale, nil, "stale player response cannot resume Scene")
T.equal(staleReason, "scene_player_response_stale",
    "stale response rejection reason is explicit")

local action, actionReason = runtime:ResumePlayer(
    sceneID, "player-one", first.semanticHistoryEvent.sequence, {
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = "FOLLOW",
    }
)
T.equal(action, nil, "Scene response lane cannot execute gameplay action")
T.equal(actionReason, "scene_player_action_unsupported",
    "gameplay action rejection is explicit")

local resumed, resumedReason = runtime:ResumePlayer(
    sceneID, "player-one", first.semanticHistoryEvent.sequence, {
        intent = "ACKNOWLEDGE",
        speechAct = "ACKNOWLEDGE",
        topic = "SCENE_TEST",
    }
)
T.truthy(resumed, resumedReason or "canonical player semantic response resumes")
T.equal(resumed.stimulus.source.actorID, "player-one",
    "resumed Scene preserves player semantic source")
T.equal(resumed.stimulus.targets[1], "npc-a",
    "resumed Scene preserves NPC semantic recipient")
T.equal(resumed.interactionPlan.behaviorID, "behavior.s4.player_ack",
    "waiting Scene uses shared Director for player response")
T.equal(resumed.continuation.mode, "terminate",
    "NPC acknowledgement can semantically terminate Scene")

local transportSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionSceneTransport.lua"
)
local clientSource = T.read(
    "ProjectHoomans", "client",
    "PNC/Conversation/PNC_SemanticInteractionScenePresentation.lua"
)
local handoffSource = T.read(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_SceneHandoff.lua"
)
local ambientSource = T.read(
    "ProjectHoomans", "client",
    "PNC/Commands/PNC_CompanionCommandPresentation.lua"
)
T.falsy(string.find(transportSource, "InteractionDirector", 1, true),
    "audience transport never reruns InteractionDirector")
T.falsy(string.find(transportSource, "PsychopatzSemantic.Parse", 1, true),
    "audience transport never reparses speech")
T.contains(clientSource, "PNC_SemanticSpeechPresentation",
    "client Scene speech reuses canonical semantic speech presentation")
T.contains(handoffSource, "Suggestions.FrameToIR",
    "player Scene choice reuses canonical semantic-click IR conversion")
T.contains(ambientSource, "context.observerOnly ~= true",
    "observer-only Scene speech cannot synthesize player interaction")

Catalog.ResetDraftOverlay()
T.finish("pnc_semantic_scene_runtime_s4_audience_smoke")
