local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"
local SocialDirector = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialDirector"
local SocialConversation = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialConversation"

Catalog.ResetDraftOverlay()
Opportunity.ResetProvidersForTests()

local function projection(id, sociability)
    return {
        actor = Providers.NormalizeActor({
            id = id,
            capabilities = { speech = true, emote = true, movement = true },
            disposition = {
                aggression = 0.3,
                confidence = 0.6,
                forgiveness = 0.6,
                sociability = sociability or 0.6,
                empathy = sociability or 0.6,
                riskTolerance = 0.4,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "idle", idle = true },
        }, "social.mixed.test"),
        relationship = Providers.NormalizeRelationship({
            state = "friendly",
            familiarity = 6,
            approval = 0.6,
            respect = 0.5,
        }, "social.mixed.test"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "social.mixed.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "social.mixed.test",
            relationship = "social.mixed.test",
            knowledge = "social.mixed.test",
        },
    }
end

local function addBehavior(definition)
    local ok, reason = Catalog.Behaviors.RegisterDraft(definition)
    T.truthy(ok, reason or definition.id)
end

addBehavior({
    id = "behavior.social_mixed.open",
    owner = "SocialMixedTest",
    act = "SOCIAL_MIXED_OPEN",
    mode = "one_shot",
    stimuli = { "AMBIENT_SOCIAL_OPPORTUNITY" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "INFORM",
            contentTemplateID = "semantic.social.acknowledged",
        },
    },
    continuation = {
        mode = "emit",
        target = "other",
        intent = "SOCIAL_MIXED_PLAYER_REPLY",
        speechAct = "REPLY",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "SOCIAL_MIXED_OPEN",
    },
    baseRelevance = 1,
    modifiers = {},
})
addBehavior({
    id = "behavior.social_mixed.player_ack",
    owner = "SocialMixedTest",
    act = "SOCIAL_MIXED_PLAYER_ACK",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "INFORM",
            contentTemplateID = "semantic.social.acknowledged",
        },
    },
    continuation = { mode = "terminate" },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "ACKNOWLEDGE",
    },
    baseRelevance = 1,
    modifiers = {},
})

local now = 1000
local runtime = Runtime.New({
    maxActiveScenes = 4,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return now end,
})
local manager = Opportunity.New(runtime)
local director = T.truthy(SocialDirector.New(manager, {
    clock = function() return now end,
}))
local controller = SocialConversation.New()

local participants = {
    {
        id = "npc-a",
        projection = projection("npc-a", 0.7),
    },
    {
        id = "player-one",
        kind = "player",
        isPlayer = true,
        projection = projection("player-one", 0.5),
    },
    {
        id = "npc-b",
        projection = projection("npc-b", 1.0),
    },
}

local admitted = director:Submit({
    id = "social:mixed:player",
    motive = "SOCIALIZE",
    relevance = 0.9,
    eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
    eventID = "mixed:event:1",
    intent = "SOCIAL_MIXED_OPEN",
    speechAct = "INFORM",
    topic = "SOCIAL",
    speakerID = "npc-a",
    recipientID = "player-one",
    participants = participants,
    perceived = false,
    maxTurns = 6,
    maxContinuationSteps = 2,
    allowNpcAfterPlayer = true,
})
T.truthy(admitted.accepted, admitted.reason or "mixed social scene admitted")
T.equal(admitted.proposal.providerID, SocialDirector.PROVIDER_ID,
    "mixed group uses generic Social Director provider")
T.equal(admitted.scene:Snapshot().participantCount, 3,
    "NPCs and player share one Scene")
T.equal(admitted.scene.lastContinuation.mode, "wait",
    "NPC address to player enters existing player wait contract")
T.equal(admitted.scene.lastContinuation.reason, "player_input_required",
    "player is never auto-answered")
T.equal(admitted.scene.lastContinuation.targetID, "player-one",
    "wait targets exact participating player")
T.equal(admitted.scene.semanticState.sequence, 1,
    "opening NPC response is exactly one semantic turn")

local social = admitted.socialOpportunity
controller:RegisterScene(admitted.scene, social, {})
local initialGroup = controller:Run(
    admitted.scene,
    admitted.initialResult,
    social,
    { maxSteps = 2 }
)
T.equal(initialGroup.mode, "wait_player",
    "autonomous group controller yields to addressed player")
T.equal(admitted.scene.semanticState.sequence, 1,
    "wait does not fabricate a player response")

local playerResult, playerReason = runtime:ResumePlayer(
    admitted.scene.id,
    "player-one",
    1,
    {
        intent = "ACKNOWLEDGE",
        speechAct = "ACKNOWLEDGE",
        topic = "SOCIAL",
    }
)
T.truthy(playerResult, playerReason or "existing player response resumes Scene")
T.equal(playerResult.semanticHistoryEvent.sourceActorID, "player-one",
    "player semantic input is canonical Scene source")
T.equal(playerResult.semanticHistoryEvent.targetActorID, "npc-a",
    "existing Scene authority chooses original NPC responder")
T.equal(playerResult.interactionPlan.behaviorID,
    "behavior.social_mixed.player_ack",
    "NPC response to player remains InteractionDirector-owned")
T.equal(admitted.scene.semanticState.sequence, 2,
    "player response plus NPC answer advances Scene once")

local resumed = controller:Run(
    admitted.scene,
    playerResult,
    social,
    { maxSteps = 2 }
)
T.truthy(#resumed.steps >= 1,
    "social group evaluates continuation after player reply")
local rejoin = resumed.steps[1]
T.equal(rejoin.mode, "emit",
    "eligible third NPC can rejoin after player has responded")
T.equal(rejoin.decision.actorID, "npc-b",
    "high-sociability third NPC wins explicit group interjection")
T.equal(rejoin.decision.targetID, "npc-a",
    "group interjection addresses the current NPC speaker")
T.equal(rejoin.decision.reason, "explicit_interjection",
    "post-player group re-entry is explicit and explainable")
T.equal(rejoin.request.sourceID, "npc-b",
    "third NPC move enters Scene as typed semantic source")
T.equal(rejoin.request.responderID, "npc-a",
    "third NPC semantic act uses existing responder authority")
T.equal(rejoin.selected.providerID, "projecthoomans.generated_affordances",
    "third NPC still reuses the same player affordance vocabulary")
T.truthy(admitted.scene.semanticState.sequence >= 3,
    "mixed scene continues without duplicate Scene state")

-- Without explicit post-player group policy, the same state yields to the
-- player instead of letting an NPC jump the queue.
local conservative = SocialConversation.New()
local waitAgain = conservative:EvaluateTurn(
    admitted.scene,
    playerResult,
    {
        motive = "SOCIALIZE",
        relevance = 0.9,
        recipientID = "player-one",
        allowNpcAfterPlayer = false,
    }
)
T.equal(waitAgain.mode, "wait_player",
    "ordinary player-addressed scenes preserve existing wait behavior")

Catalog.ResetDraftOverlay()
Opportunity.ResetProvidersForTests()
T.finish("pnc_semantic_social_mixed_player_smoke")
