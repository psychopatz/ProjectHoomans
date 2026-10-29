local T = require "tests/support/test"
T.addPackagePaths()

local delivered = 0
PNC = {
    Const = {
        CMD_SEMANTIC_SCENE_SPEECH = "SemanticSceneSpeech",
    },
    Network = {
        Internal = {
            SendToPlayer = function()
                delivered = delivered + 1
                return true
            end,
        },
    },
}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"
local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"
local Observatory = require
    "PNC/Semantics/PNC_SemanticInteractionSceneObservatory"

local function projection(id, confidence)
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
                confidence = confidence or 0.5,
                forgiveness = 0.5,
                sociability = 0.5,
                empathy = 0.5,
                riskTolerance = confidence or 0.5,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "idle", idle = true },
        }, "scene.observatory.test"),
        relationship = Providers.NormalizeRelationship({
            state = "neutral",
            familiarity = 2,
            approval = 0,
            respect = 0,
        }, "scene.observatory.test"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "scene.observatory.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "scene.observatory.test",
            relationship = "scene.observatory.test",
            knowledge = "scene.observatory.test",
        },
    }
end

Opportunity.ResetProvidersForTests()
local registered, registerReason = Opportunity.RegisterProvider({
    id = "scene.observatory.fixture",
    order = 1,
    stimuli = { "DANGER_CHANGED" },
    propose = function(event, context)
        return {
            id = "observatory:" .. tostring(event.id),
            dedupeKey = "observatory:" .. tostring(event.id),
            priority = 10,
            participants = context.participants,
            audience = context.audience,
            topic = "COMBAT",
            ttlMs = 10000,
            maxTurns = 4,
            perceived = true,
            autoContinue = false,
            worldEvents = { event.id },
            stimulus = {
                type = "DANGER_CHANGED",
                responderID = "npc-a",
                intent = "COMBAT_HORDE_ALERT",
                speechAct = "WARN",
                subject = "ZOMBIE_HORDE",
                topic = "COMBAT",
                eventID = event.id,
                eventRefs = { event.id },
                worldPatch = {
                    danger = {
                        kind = "zombie_horde",
                        pressureBand = "horde",
                        nearbyCount = 8,
                        phase = "started",
                    },
                },
            },
        }
    end,
})
T.truthy(registered, registerReason or "fixture provider registers")

local runtime = Runtime.New({
    maxActiveScenes = 4,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return 1000 end,
})
local manager = Opportunity.New(runtime)
local admitted = manager:Admit({
    type = "DANGER_CHANGED",
    id = "event:observatory:horde",
}, {
    participants = {
        { id = "npc-a", projection = projection("npc-a", 0.5) },
        { id = "npc-b", projection = projection("npc-b", 0.9) },
    },
    audience = {
        {
            player = { id = "observer" },
            actorID = "observer:one",
            role = "observer",
        },
    },
})
T.truthy(admitted.accepted, admitted.reason or "scene admitted")
T.equal(delivered, 1,
    "active scene delivered one already-selected line to observer")

local view = Observatory.Inspect({
    runtime = runtime,
    opportunityManager = manager,
    sceneID = admitted.sceneID,
    sceneLimit = 2,
    historyLimit = 4,
})
T.equal(view.schema, "semantic.interaction.scene.observatory.v1",
    "Scene Observatory exposes stable schema")
T.truthy(view.readOnly, "Scene Observatory declares read-only contract")
T.falsy(view.transcriptStored, "Scene Observatory stores no transcript")
T.equal(view.sceneCount, 1, "focused active scene is projected")
T.equal(view.scenes[1].id, admitted.sceneID,
    "focused scene identity is stable")
T.equal(view.scenes[1].lod, "nearby_perceived",
    "current Scheduler LOD is inspectable")
T.equal(view.scenes[1].participantCount, 2,
    "participant count is inspectable")
T.equal(view.scenes[1].participants[1].kind, "npc",
    "participant roles are projected without actor records")
T.equal(view.scenes[1].currentTurn.speakerID, "npc-a",
    "selected response speaker is inspectable")
T.equal(view.scenes[1].currentTurn.recipientID, "npc-b",
    "event-originated recipient comes from semantic continuation target")
T.equal(view.scenes[1].currentTurn.behaviorID,
    "behavior.scene_horde_prompt",
    "selected behavior is inspectable")
T.equal(view.scenes[1].continuation.mode, "emit",
    "continuation decision is inspectable")
T.equal(view.scenes[1].continuation.targetID, "npc-b",
    "continuation target is inspectable")
T.equal(view.scenes[1].grounding.eventRefs[1],
    "event:observatory:horde",
    "grounded event identity is inspectable")
T.equal(view.opportunity.lastAdmission.providerID,
    "scene.observatory.fixture",
    "admission provider provenance is inspectable")
T.equal(view.opportunity.lastAdmission.audienceCount, 1,
    "audience admission count is inspectable")
T.equal(view.opportunity.lastAdmission.delivered, 1,
    "presentation fanout count is inspectable")
T.equal(view.explanation.outcome, "active",
    "active scene explanation is explicit")
T.equal(view.explanation.playerChoices,
    "observer_or_non_player_recipient",
    "observer correctly receives no response authority")
T.truthy(
    (view.runtime.scheduler.metrics.directorEvaluations or 0) >= 1,
    "Director evaluation counter is exposed")
T.truthy(
    (view.opportunity.metrics.providerEvaluations or 0) >= 1,
    "Opportunity provider evaluation counter is exposed")

local closed, closeReason = runtime:Close(
    admitted.sceneID, "observatory_test_complete"
)
T.truthy(closed, closeReason or "scene closes")

local closedView = Observatory.Inspect({
    runtime = runtime,
    opportunityManager = manager,
    sceneID = admitted.sceneID,
})
T.equal(closedView.sceneCount, 0,
    "closed scene is not retained as active scene state")
T.equal(closedView.explanation.outcome, "closed",
    "recent closure remains explainable")
T.equal(closedView.explanation.terminationReason,
    "observatory_test_complete",
    "bounded closure ledger exposes termination reason")
T.equal(
    closedView.recentClosures[#closedView.recentClosures].id,
    admitted.sceneID,
    "recent closure ledger retains only compact scene identity"
)

local source = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionSceneObservatory.lua"
)
T.falsy(string.find(source, "rawText", 1, true),
    "Observatory never projects raw dialogue text")
T.falsy(string.find(source, "resolvedText", 1, true),
    "Observatory never projects realized dialogue text")
T.falsy(string.find(source, "ModData", 1, true),
    "Observatory owns no persistent storage")
T.falsy(string.find(source, "Events.OnTick", 1, true),
    "Observatory has no polling hook")

Opportunity.ResetProvidersForTests()
T.finish("pnc_semantic_scene_observatory_smoke")
