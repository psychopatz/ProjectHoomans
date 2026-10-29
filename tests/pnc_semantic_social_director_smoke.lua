local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"
local SocialDirector = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialDirector"

Catalog.ResetDraftOverlay()
Opportunity.ResetProvidersForTests()

local function projection(id)
    return {
        actor = Providers.NormalizeActor({
            id = id,
            capabilities = { speech = true, emote = true, movement = true },
            disposition = {
                aggression = 0.4,
                confidence = 0.5,
                forgiveness = 0.5,
                sociability = 0.6,
                empathy = 0.5,
                riskTolerance = 0.5,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "idle", idle = true },
        }, "social.director.test"),
        relationship = Providers.NormalizeRelationship({
            state = "neutral",
            familiarity = 2,
            approval = 0,
            respect = 0,
        }, "social.director.test"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "social.director.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "social.director.test",
            relationship = "social.director.test",
            knowledge = "social.director.test",
        },
    }
end

local actors = {
    { id = "npc-a", projection = projection("npc-a") },
    { id = "npc-b", projection = projection("npc-b") },
    { id = "npc-c", projection = projection("npc-c") },
}

local function registerBehavior(id, stimulus, intent)
    local ok, reason = Catalog.Behaviors.RegisterDraft({
        id = id,
        owner = "SocialDirectorTest",
        act = "ACKNOWLEDGE",
        mode = "one_shot",
        stimuli = { stimulus },
        requiredCapabilities = {},
        outputs = {},
        continuation = { mode = "terminate" },
        when = {
            path = "stimulus.semantic.intent",
            op = "eq",
            value = intent,
        },
        baseRelevance = 1,
        modifiers = {},
    })
    T.truthy(ok, reason or id)
end

registerBehavior(
    "behavior.social_director.ambient",
    "AMBIENT_SOCIAL_OPPORTUNITY",
    "SOCIAL_TEST_AMBIENT"
)
registerBehavior(
    "behavior.social_director.task",
    "TASK_EVENT",
    "SOCIAL_TEST_TASK"
)

local now = 1000
local runtime = Runtime.New({
    maxActiveScenes = 4,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return now end,
})
local manager = Opportunity.New(runtime)
local director, directorReason = SocialDirector.New(manager, {
    clock = function() return now end,
})
T.truthy(director, directorReason or "social director opens")
T.equal(
    SocialDirector.RegisterProvider(),
    true,
    "social provider registration is idempotent"
)

local ambient = director:Submit({
    id = "social:ambient:1",
    motive = "SOCIALIZE",
    relevance = 0.8,
    eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
    intent = "SOCIAL_TEST_AMBIENT",
    speechAct = "INFORM",
    topic = "NEWS",
    speakerID = "npc-b",
    recipientID = "npc-a",
    participants = { actors[1], actors[2], actors[3] },
    areaKey = "camp-one",
    perceived = false,
    maxTurns = 3,
})
T.truthy(ambient.accepted, ambient.reason or "ambient social scene admitted")
T.equal(ambient.proposal.providerID, SocialDirector.PROVIDER_ID,
    "ambient scene uses the one generic social provider")
T.equal(ambient.proposal.participants[1].id, "npc-b",
    "selected opening speaker is first participant")
T.equal(ambient.proposal.participants[2].id, "npc-a",
    "selected opening recipient is second participant")
T.equal(ambient.initialResult.interactionPlan.behaviorID,
    "behavior.social_director.ambient",
    "existing InteractionDirector resolves ambient semantic meaning")
T.equal(runtime:Snapshot().activeSceneCount, 1,
    "three participants create one Scene")
T.equal(ambient.scene:Snapshot().participantCount, 3,
    "one Scene owns all bounded participants")

local duplicate = director:Submit({
    id = "social:ambient:duplicate",
    motive = "SOCIALIZE",
    relevance = 0.8,
    eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
    intent = "SOCIAL_TEST_AMBIENT",
    speechAct = "INFORM",
    topic = "NEWS",
    speakerID = "npc-b",
    recipientID = "npc-a",
    participants = { actors[1], actors[2] },
    areaKey = "camp-one",
    perceived = false,
})
T.falsy(duplicate.accepted,
    "ambient repeat is rejected before a new Scene is opened")
T.equal(duplicate.reason, "social_actor_cooldown",
    "shared chatter budget suppresses repeated speaker")

local silence = director:Submit({
    id = "social:silence",
    motive = "SOCIALIZE",
    relevance = 0.05,
    eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
    intent = "SOCIAL_TEST_AMBIENT",
    speechAct = "INFORM",
    speakerID = "npc-c",
    recipientID = "npc-a",
    participants = { actors[1], actors[3] },
})
T.falsy(silence.accepted, "low relevance chooses no scene")
T.equal(silence.reason, "social_relevance_low",
    "low-value silence is an explicit director decision")

now = now + 15000
local task = director:Submit({
    id = "social:task:1",
    motive = "COORDINATE",
    relevance = 0.9,
    eventType = "TASK_EVENT",
    eventID = "task-event-1",
    intent = "SOCIAL_TEST_TASK",
    speechAct = "REQUEST",
    subject = "WORK",
    topic = "WORK",
    speakerID = "npc-c",
    recipientID = "npc-a",
    participants = { actors[3], actors[1] },
    areaKey = "camp-one",
    priority = 55,
    perceived = false,
    maxTurns = 2,
})
T.truthy(task.accepted, task.reason or "task social scene admitted")
T.equal(task.proposal.providerID, SocialDirector.PROVIDER_ID,
    "task family reuses the same generic provider")
T.equal(task.initialResult.interactionPlan.behaviorID,
    "behavior.social_director.task",
    "task semantic meaning still resolves through InteractionDirector")
T.equal(runtime:Snapshot().activeSceneCount, 2,
    "unrelated social event opens through same runtime budget")

local snapshot = director:Snapshot()
T.equal(snapshot.metrics.submitted, 4, "director counts bounded submissions")
T.equal(snapshot.metrics.admitted, 2, "director counts admitted scenes")
T.equal(snapshot.metrics.silent, 1, "director counts deliberate silence")
T.equal(snapshot.metrics.budgetRejected, 1,
    "director counts chatter-budget rejection")
T.truthy(snapshot.budget.metrics.reserved >= 2,
    "successful scenes reserve transient chatter budget")

local normalized, invalid = SocialDirector.Normalize({
    motive = "SOCIALIZE",
    relevance = 1,
    eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
    intent = "SOCIAL_TEST_AMBIENT",
    speechAct = "INFORM",
    speakerID = "npc-a",
    recipientID = "npc-a",
    participants = { actors[1], actors[2] },
})
T.equal(normalized, nil, "self-recipient social opening fails closed")
T.equal(invalid, "social_self_recipient",
    "invalid opening has stable reason")

Catalog.ResetDraftOverlay()
Opportunity.ResetProvidersForTests()
T.finish("pnc_semantic_social_director_smoke")
