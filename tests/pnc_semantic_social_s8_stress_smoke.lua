local T = require "tests/support/test"
T.addPackagePaths()

local registryScans = 0
PNC = {
    Registry = {
        ForEachLive = function()
            registryScans = registryScans + 1
            error("Social Director must never scan the live registry")
        end,
    },
}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Catalog = require "PNC/Semantics/PNC_SemanticInteractionCatalog"
local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"
local SocialDirector = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialDirector"
local SocialConversation = require
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialConversation"
local Observatory = require
    "PNC/Semantics/PNC_SemanticInteractionSceneObservatory"

Catalog.ResetDraftOverlay()
Opportunity.ResetProvidersForTests()

local function projection(id)
    return {
        actor = Providers.NormalizeActor({
            id = id,
            capabilities = { speech = true, emote = true, movement = true },
            disposition = {
                aggression = 0.4,
                confidence = 0.6,
                forgiveness = 0.5,
                sociability = 0.8,
                empathy = 0.7,
                riskTolerance = 0.5,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "social_stress", idle = false },
        }, "social.s8"),
        relationship = Providers.NormalizeRelationship({
            state = "friendly",
            familiarity = 4,
            approval = 0.4,
            respect = 0.3,
        }, "social.s8"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "social.s8"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "social.s8",
            relationship = "social.s8",
            knowledge = "social.s8",
        },
    }
end

local actors = {}
for index = 1, 4 do
    actors[index] = {
        id = "npc-social-s8-" .. tostring(index),
        projection = projection("npc-social-s8-" .. tostring(index)),
    }
end

local function addBehavior(id, stimulus, intent, dialogueAct)
    local ok, reason = Catalog.Behaviors.RegisterDraft({
        id = id,
        owner = "SocialS8Synthetic",
        act = intent,
        mode = "one_shot",
        stimuli = { stimulus },
        requiredCapabilities = { "speech" },
        outputs = {
            speech = {
                dialogueAct = dialogueAct or "INFORM",
                contentTemplateID = "semantic.social.acknowledged",
            },
        },
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

addBehavior(
    "behavior.social_s8.ambient",
    "AMBIENT_SOCIAL_OPPORTUNITY",
    "SOCIAL_S8_AMBIENT",
    "INFORM"
)
addBehavior(
    "behavior.social_s8.future_faction",
    "FACTION_EVENT",
    "SOCIAL_S8_FUTURE_FACTION",
    "APOLOGIZE"
)
addBehavior(
    "behavior.social_s8.urgent",
    "DANGER_CHANGED",
    "SOCIAL_S8_URGENT",
    "WARN"
)

local now = 1000
local runtime = Runtime.New({
    maxActiveScenes = 16,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return now end,
})
local manager = Opportunity.New(runtime)
local director = T.truthy(SocialDirector.New(manager, {
    clock = function() return now end,
}))
local controller = SocialConversation.New()

-- Repeated low-value chatter from one pair is heavily suppressed instead of
-- opening twenty scenes.
local admitted = 0
local rejected = 0
for index = 1, 20 do
    local result = director:Submit({
        id = "social:stress:repeat:" .. tostring(index),
        motive = "SOCIALIZE",
        relevance = 0.7,
        eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
        eventID = "social-stress-repeat-" .. tostring(index),
        intent = "SOCIAL_S8_AMBIENT",
        speechAct = "INFORM",
        topic = "SMALL_TALK",
        speakerID = actors[1].id,
        recipientID = actors[2].id,
        participants = { actors[1], actors[2] },
        areaKey = "social-stress-camp",
        perceived = false,
    })
    if result.accepted then admitted = admitted + 1
    else rejected = rejected + 1 end
end
T.equal(admitted, 1,
    "twenty repeated low-value opportunities open only one social scene")
T.equal(rejected, 19,
    "nineteen repeated opportunities are suppressed by chatter budgets")
T.equal(director:Snapshot().metrics.budgetRejected, 19,
    "budget suppression remains observable")
T.equal(registryScans, 0,
    "repeated social admission never scans the live registry")

-- An urgent grounded event is not starved by the earlier chatter budget.
local urgent = director:Submit({
    id = "social:stress:urgent",
    motive = "WARN",
    relevance = 1,
    priority = 100,
    eventType = "DANGER_CHANGED",
    eventID = "social-stress-danger",
    intent = "SOCIAL_S8_URGENT",
    speechAct = "WARN",
    topic = "DANGER",
    speakerID = actors[1].id,
    recipientID = actors[2].id,
    participants = { actors[1], actors[2] },
    areaKey = "social-stress-camp",
    perceived = false,
})
T.truthy(urgent.accepted,
    urgent.reason or "urgent event bypasses ordinary chatter budget")
T.equal(director:Snapshot().budget.metrics.urgentBypass, 1,
    "urgent budget bypass is counted")

-- Generic capacity still wins when callers explicitly bypass ambient chatter
-- throttles (e.g. stress harness / independently urgent events).
local capacityRuntime = Runtime.New({
    maxActiveScenes = 16,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return now end,
})
Opportunity.ResetProvidersForTests()
local capacityManager = Opportunity.New(capacityRuntime)
local capacityDirector = T.truthy(SocialDirector.New(capacityManager, {
    clock = function() return now end,
}))
local capacityAccepted = 0
local capacityRejected = 0
for index = 1, 20 do
    local result = capacityDirector:Submit({
        id = "social:stress:capacity:" .. tostring(index),
        motive = "WARN",
        relevance = 1,
        priority = 100,
        bypassBudget = true,
        eventType = "DANGER_CHANGED",
        eventID = "social-capacity-" .. tostring(index),
        intent = "SOCIAL_S8_URGENT",
        speechAct = "WARN",
        topic = "DANGER_" .. tostring(index),
        speakerID = actors[1].id,
        recipientID = actors[2].id,
        participants = { actors[1], actors[2] },
        perceived = false,
    })
    if result.accepted then capacityAccepted = capacityAccepted + 1
    else capacityRejected = capacityRejected + 1 end
end
T.equal(capacityAccepted, 16,
    "Social Director cannot exceed the existing global Scene ceiling")
T.equal(capacityRejected, 4,
    "global Scene overflow is rejected instead of hidden")
T.equal(capacityRuntime:Snapshot().activeSceneCount, 16,
    "Social Director still owns no second capacity budget")

-- Four participants remain one scene.
Opportunity.ResetProvidersForTests()
local groupRuntime = Runtime.New({ maxActiveScenes = 4 })
local groupManager = Opportunity.New(groupRuntime)
local groupDirector = T.truthy(SocialDirector.New(groupManager))
local group = groupDirector:Submit({
    id = "social:s8:group4",
    motive = "SOCIALIZE",
    relevance = 0.9,
    eventType = "AMBIENT_SOCIAL_OPPORTUNITY",
    eventID = "social-group4",
    intent = "SOCIAL_S8_AMBIENT",
    speechAct = "INFORM",
    topic = "SOCIAL",
    speakerID = actors[1].id,
    recipientID = actors[2].id,
    participants = { actors[1], actors[2], actors[3], actors[4] },
    perceived = false,
})
T.truthy(group.accepted, group.reason or "four-person social scene admitted")
T.equal(groupRuntime:Snapshot().activeSceneCount, 1,
    "four social participants do not explode into six pairwise scenes")
T.equal(group.scene:Snapshot().participantCount, 4,
    "one scene carries all four explicit participants")

-- Synthetic fourth future social domain: FACTION_EVENT + REPAIR motive through
-- the same public Social Director seam, with no generic algorithm edit.
Opportunity.ResetProvidersForTests()
local futureRuntime = Runtime.New({ maxActiveScenes = 4 })
local futureManager = Opportunity.New(futureRuntime)
local futureDirector = T.truthy(SocialDirector.New(futureManager))
local future = futureDirector:Submit({
    id = "social:s8:future-faction",
    motive = "REPAIR",
    relevance = 0.95,
    eventType = "FACTION_EVENT",
    eventID = "future-faction-event",
    intent = "SOCIAL_S8_FUTURE_FACTION",
    speechAct = "APOLOGIZE",
    topic = "FACTION_RELATION",
    speakerID = actors[3].id,
    recipientID = actors[4].id,
    participants = { actors[3], actors[4] },
    perceived = false,
})
T.truthy(future.accepted,
    future.reason or "future faction social domain adopts public seam")
T.equal(future.proposal.providerID, SocialDirector.PROVIDER_ID,
    "future domain needs no feature-specific conversation provider")
T.equal(future.initialResult.interactionPlan.behaviorID,
    "behavior.social_s8.future_faction",
    "future domain uses existing InteractionDirector unchanged")

-- Produce one actor-neutral frontier decision for the read-only Observatory.
controller:RegisterScene(
    future.scene,
    future.socialOpportunity,
    future.proposal.audience
)
local choiceStep = controller:Advance(
    future.scene,
    future.initialResult,
    future.socialOpportunity
)
T.truthy(choiceStep.mode == "emit" or choiceStep.mode == "terminate",
    "future domain reaches bounded NPC choice or silence")

PNC.Semantics.InteractionSceneAdopters = {
    Manager = function() return futureManager end,
    Snapshot = function()
        return {
            metrics = {
                actorQueries = 0,
                hordeEvents = 0,
                postCombatEvents = 0,
                knowledgeEvents = 0,
                excursionEvents = 0,
                taskEvents = 0,
            },
            social = futureDirector:Snapshot(),
            socialConversation = controller:Snapshot(),
        }
    end,
}
local view = Observatory.Inspect({
    runtime = futureRuntime,
    opportunityManager = futureManager,
    sceneID = future.sceneID,
})
T.truthy(view.readOnly, "Social Observatory remains read-only")
T.falsy(view.transcriptStored, "Social Observatory exposes no transcript")
T.equal(view.adopter.social.providerID, SocialDirector.PROVIDER_ID,
    "Observatory identifies generic Social Director authority")
T.equal(view.adopter.social.admission.motive, "REPAIR",
    "Observatory exposes semantic social motive")
T.equal(view.adopter.social.admission.speakerID, actors[3].id,
    "Observatory exposes opening speaker")
T.equal(view.adopter.social.admission.recipientID, actors[4].id,
    "Observatory exposes opening recipient")
T.equal(#view.adopter.social.admission.participantIDs, 2,
    "Observatory exposes bounded participant IDs only")
T.truthy(view.adopter.social.budget.metrics.checks >= 1,
    "Observatory exposes chatter-budget decisions")
local observedChoices =
    view.adopter.social.conversation.lastDecision.choices
T.truthy(type(observedChoices) == "table",
    "Observatory exposes bounded actor choice rows")
if #observedChoices > 0 then
    T.truthy(observedChoices[1].frontierCount <= 8,
        "affordance frontier remains bounded in Observatory")
    for _, row in ipairs(observedChoices[1].frontier or {}) do
        T.equal(row.text, nil,
            "affordance diagnostic rows contain no rendered dialogue")
    end
end

-- Generic social algorithms must stay free of fixture/domain special cases,
-- scans, persistence and routine LLM/text-reparse side channels.
for _, relative in ipairs({
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialDirector.lua",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialChoicePolicy.lua",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialTurnPolicy.lua",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialBudget.lua",
    "PNC/Semantics/SemanticSocial/PNC_SemanticSocialConversation.lua",
}) do
    local source = T.read("ProjectHoomans", "shared", relative)
    T.falsy(string.find(source, "SOCIAL_S8_", 1, true),
        relative .. " contains no synthetic-domain conditional")
    T.falsy(string.find(source, "Events.OnTick", 1, true),
        relative .. " contains no recurring tick hook")
    T.falsy(string.find(source, "Registry.ForEachLive", 1, true),
        relative .. " contains no full-NPC scan")
    T.falsy(string.find(source, "getZombieList", 1, true),
        relative .. " contains no global-zombie scan")
    T.falsy(string.find(source, "PsychopatzSemantic.Parse", 1, true),
        relative .. " never reparses rendered dialogue")
    T.falsy(string.find(source, "ModData", 1, true),
        relative .. " owns no persistent social transcript/state root")
    T.falsy(string.find(source, "llmEligible = true", 1, true),
        relative .. " opts into no routine autonomous LLM")
    T.falsy(string.find(source, "transcriptText", 1, true),
        relative .. " stores no transcript text")
    T.falsy(string.find(source, "renderedText", 1, true),
        relative .. " stores no rendered dialogue")
end

T.equal(registryScans, 0, "all stress/extensibility work avoids registry scans")

Opportunity.ResetProvidersForTests()
Catalog.ResetDraftOverlay()
T.finish("pnc_semantic_social_s8_stress_smoke")
