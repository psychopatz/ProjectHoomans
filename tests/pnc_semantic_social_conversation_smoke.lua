local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Scene = require "PNC/Semantics/PNC_SemanticInteractionScene"
local Conversation = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialConversation"

Catalog.ResetDraftOverlay()

local function projection(id, disposition, relationship)
    return {
        actor = Providers.NormalizeActor({
            id = id,
            capabilities = { speech = true, emote = true, movement = true },
            disposition = disposition or {
                aggression = 0.3, confidence = 0.5, forgiveness = 0.6,
                sociability = 0.6, empathy = 0.6, riskTolerance = 0.4,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "idle", idle = true },
            traits = {},
        }, "social.conversation.test"),
        relationship = Providers.NormalizeRelationship(
            relationship or {
                state = "friendly",
                familiarity = 5,
                approval = 0.5,
                respect = 0.4,
            },
            "social.conversation.test"
        ),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "social.conversation.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "social.conversation.test",
            relationship = "social.conversation.test",
            knowledge = "social.conversation.test",
        },
    }
end

local function behavior(id, stimulus, sourceIntent, act, dialogueAct)
    local ok, reason = Catalog.Behaviors.RegisterDraft({
        id = id,
        owner = "SocialConversationTest",
        act = act,
        mode = "one_shot",
        stimuli = { stimulus },
        requiredCapabilities = { "speech" },
        outputs = {
            speech = {
                dialogueAct = dialogueAct,
                contentTemplateID = "semantic.social.acknowledged",
            },
        },
        continuation = { mode = "terminate" },
        when = {
            path = "stimulus.semantic.intent",
            op = "eq",
            value = sourceIntent,
        },
        baseRelevance = 1,
        modifiers = {},
    })
    T.truthy(ok, reason or id)
end

behavior(
    "behavior.social_conversation.open",
    "AMBIENT_SOCIAL_OPPORTUNITY",
    "SOCIAL_CONVERSATION_OPEN",
    "SOCIAL_CONVERSATION_OPEN",
    "INFORM"
)
behavior(
    "behavior.social_conversation.ack",
    "NPC_SEMANTIC_ACT",
    "ACKNOWLEDGE",
    "ACKNOWLEDGE_REPLY",
    "ACKNOWLEDGE"
)
behavior(
    "behavior.social_conversation.followup",
    "NPC_SEMANTIC_ACT",
    "QUESTION",
    "ANSWER",
    "ANSWER"
)
behavior(
    "behavior.social_conversation.agree",
    "NPC_SEMANTIC_ACT",
    "AGREE",
    "ACKNOWLEDGE_REPLY",
    "ACKNOWLEDGE"
)
behavior(
    "behavior.social_conversation.disagree",
    "NPC_SEMANTIC_ACT",
    "DISAGREE",
    "ACKNOWLEDGE_REPLY",
    "ACKNOWLEDGE"
)

local scene, sceneReason = Scene.New({
    id = "scene:social:conversation",
    participants = {
        {
            id = "npc-a",
            projection = projection("npc-a", {
                aggression = 0.2, confidence = 0.5, forgiveness = 0.7,
                sociability = 0.7, empathy = 0.7, riskTolerance = 0.3,
            }),
        },
        {
            id = "npc-b",
            projection = projection("npc-b", {
                aggression = 0.2, confidence = 0.5, forgiveness = 0.7,
                sociability = 0.6, empathy = 0.6, riskTolerance = 0.3,
            }),
        },
        {
            id = "npc-c",
            projection = projection("npc-c", {
                aggression = 0.8, confidence = 0.8, forgiveness = 0.2,
                sociability = 0.8, empathy = 0.2, riskTolerance = 0.8,
            }, {
                state = "tense",
                familiarity = 3,
                approval = -0.5,
                respect = 0.1,
            }),
        },
    },
    perceived = false,
    maxTurns = 8,
    topic = "NEWS",
})
T.truthy(scene, sceneReason or "social conversation scene opens")

local opening, openingReason = scene:EmitStimulus({
    type = "AMBIENT_SOCIAL_OPPORTUNITY",
    responderID = "npc-a",
    intent = "SOCIAL_CONVERSATION_OPEN",
    speechAct = "INFORM",
    topic = "NEWS",
})
T.truthy(opening, openingReason or "opening semantic response resolves")
T.equal(opening.semanticHistoryEvent.targetActorID, "npc-a",
    "opening line belongs to selected speaker")

local consequenceCalls = {}
local controller = Conversation.New({
    effectSink = function(spec)
        consequenceCalls[#consequenceCalls + 1] = spec
        return {
            accepted = true,
            applied = true,
            reason = "test_consequence_applied",
            eventType = "npc_dialogue_test",
            eventID = "social:test:consequence",
        }
    end,
})
local social = {
    motive = "INFORM",
    relevance = 0.9,
    recipientID = "npc-b",
    topic = "NEWS",
}
local first = controller:Advance(scene, opening, social)
T.equal(first.mode, "emit",
    "NPC recipient selects one semantic affordance")
T.equal(first.decision.actorID, "npc-b",
    "current recipient gets first reply opportunity")
T.equal(first.decision.targetID, "npc-a",
    "NPC reply targets the previous speaker")
T.truthy(first.selected.strategy == "ACKNOWLEDGE"
    or first.selected.strategy == "ASK_FOLLOWUP",
    "NPC selects from existing semantic affordance vocabulary")
T.equal(first.request.sourceID, "npc-b",
    "selected NPC move becomes typed semantic source")
T.equal(first.request.responderID, "npc-a",
    "typed semantic source is sent to existing addressee")
T.equal(first.result.semanticHistoryEvent.sourceActorID, "npc-b",
    "Scene records NPC semantic move as the next source")
T.equal(first.result.semanticHistoryEvent.targetActorID, "npc-a",
    "existing InteractionDirector produces the addressee response")
T.equal(first.selected.providerID, "projecthoomans.generated_affordances",
    "autonomous NPC reuses the player affordance provider authority")
T.truthy(first.selectedPresentation.text,
    "selected NPC move already has reusable semantic realization")
T.equal(scene.semanticState.sequence, 2,
    "one selected NPC move advances Scene exactly once")
T.equal(#consequenceCalls, 1,
    "successful autonomous semantic emission invokes consequence sink once")
T.equal(consequenceCalls[1].sceneID, scene.id,
    "consequence handoff preserves Scene identity")
T.equal(consequenceCalls[1].request.sourceID, "npc-b",
    "consequence handoff preserves semantic actor")
T.equal(consequenceCalls[1].request.responderID, "npc-a",
    "consequence handoff preserves semantic target")
T.truthy(first.consequence and first.consequence.applied,
    "step exposes bounded consequence outcome without owning mutation")
T.equal(controller:Snapshot().metrics.consequencesApplied, 1,
    "applied consequence is observable in bounded metrics")

local history = controller:History(scene.id)
T.equal(#history, 1, "NPC affordance recurrence history is controller-local")
T.equal(history[1].speaker, "npc-b", "history attributes strategy to NPC")
T.equal(history[1].strategy, first.selected.strategy,
    "history remembers semantic strategy rather than rendered text")

-- Re-evaluate from the response without allowing C to interject. B remains the
-- intended recipient but its just-used strategy should not be immediately
-- repeated if another valid frontier choice exists.
local second = controller:Advance(scene, first.result, {
    motive = "INFORM",
    relevance = 0.9,
    recipientID = "npc-b",
    topic = "NEWS",
})
T.truthy(second.mode == "emit" or second.mode == "terminate",
    "bounded follow-up either emits one semantic move or chooses silence")
if second.mode == "emit" and second.decision.actorID == "npc-b" then
    T.falsy(
        second.selected.strategy == first.selected.strategy,
        "same NPC strategy is recurrence-suppressed on immediate follow-up"
    )
end
T.truthy(scene.semanticState.sequence <= 3,
    "controller never double-increments Scene semantic sequence")

local quietController = Conversation.New()
local quiet = quietController:Advance(scene, first.result, {
    motive = "SOCIALIZE",
    relevance = 0.05,
    recipientID = "npc-b",
    topic = "NEWS",
})
T.equal(quiet.mode, "terminate",
    "low-value continuation chooses silence")
T.equal(quietController:Snapshot().metrics.silence, 1,
    "silence is observable rather than fabricated chatter")

-- Player recipient must stop autonomous selection and leave the existing
-- player response lifecycle in control.
local playerScene = T.truthy(Scene.New({
    id = "scene:social:player",
    participants = {
        { id = "npc-a", projection = projection("npc-a") },
        {
            id = "player-one",
            kind = "player",
            isPlayer = true,
            projection = projection("player-one"),
        },
    },
    perceived = false,
    maxTurns = 4,
    topic = "NEWS",
}))
local playerOpening = T.truthy(playerScene:EmitStimulus({
    type = "AMBIENT_SOCIAL_OPPORTUNITY",
    responderID = "npc-a",
    intent = "SOCIAL_CONVERSATION_OPEN",
    speechAct = "INFORM",
    topic = "NEWS",
}))
local playerTurn = controller:Advance(playerScene, playerOpening, {
    motive = "INFORM",
    relevance = 0.9,
    recipientID = "player-one",
    topic = "NEWS",
})
T.equal(playerTurn.mode, "wait_player",
    "addressed player is handed to existing player-input authority")
T.equal(playerTurn.decision.actorID, "player-one",
    "player handoff preserves exact addressee")
T.equal(playerScene.semanticState.sequence, 1,
    "waiting for player does not fabricate an NPC turn")

Catalog.ResetDraftOverlay()
T.finish("pnc_semantic_social_conversation_smoke")
