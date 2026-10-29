local T = require "tests/support/test"
T.addPackagePaths()

local packets = {}
PNC = {
    Const = {
        CMD_SEMANTIC_SCENE_SPEECH = "SemanticSceneSpeech",
    },
    Network = {
        Internal = {
            SendToPlayer = function(player, command, payload)
                packets[#packets + 1] = {
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
local Opportunity = require "PNC/Semantics/PNC_SemanticInteractionOpportunity"

Catalog.ResetDraftOverlay()
Opportunity.ResetProvidersForTests()

local function projection(id)
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
                sociability = 0.6,
                empathy = 0.5,
                riskTolerance = 0.5,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "idle", idle = true },
        }, "s5.test"),
        relationship = Providers.NormalizeRelationship({
            state = "neutral",
            familiarity = 2,
            approval = 0,
            respect = 0,
        }, "s5.test"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "s5.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "s5.test",
            relationship = "s5.test",
            knowledge = "s5.test",
        },
    }
end

local actors = {
    a = { id = "npc-a", projection = projection("npc-a") },
    b = { id = "npc-b", projection = projection("npc-b") },
    c = { id = "npc-c", projection = projection("npc-c") },
    d = { id = "npc-d", projection = projection("npc-d") },
}

local function registerBehavior(id, intent)
    local ok, reason = Catalog.Behaviors.RegisterDraft({
        id = id,
        owner = "S5Test",
        act = "ACKNOWLEDGE",
        mode = "one_shot",
        stimuli = { "FACTION_EVENT", "TASK_EVENT" },
        requiredCapabilities = { "speech" },
        outputs = {
            speech = {
                dialogueAct = "ACKNOWLEDGE",
                contentTemplateID = "semantic.social.acknowledged",
            },
        },
        when = {
            path = "stimulus.semantic.intent",
            op = "eq",
            value = intent,
        },
        baseRelevance = 1,
        modifiers = {},
    })
    T.truthy(ok, reason or ("register " .. id))
end

registerBehavior("behavior.s5.faction", "S5_FACTION_REPORT")
registerBehavior("behavior.s5.task", "S5_TASK_REPORT")

local ok, reason = Opportunity.RegisterProvider({
    id = "s5.faction",
    order = 20,
    stimuli = { "FACTION_EVENT" },
    propose = function(event)
        return {
            id = "faction:" .. tostring(event.id),
            dedupeKey = "faction:" .. tostring(event.id),
            priority = 5,
            cooldownMs = 5000,
            participants = { actors.a, actors.b },
            topic = "FACTION",
            ttlMs = 10000,
            maxTurns = 3,
            perceived = true,
            distance = 8,
            audience = {
                { player = { id = "watcher-1" }, actorID = "watcher-1" },
            },
            stimulus = {
                type = "FACTION_EVENT",
                sourceID = "npc-a",
                responderID = "npc-b",
                intent = "S5_FACTION_REPORT",
                speechAct = "INFORM",
                topic = "FACTION",
                eventRefs = { tostring(event.id) },
            },
        }
    end,
})
T.truthy(ok, reason or "register faction opportunity provider")

ok, reason = Opportunity.RegisterProvider({
    id = "s5.task",
    order = 10,
    stimuli = { "TASK_EVENT" },
    propose = function(event)
        local audience = {}
        for index = 1, 12 do
            audience[#audience + 1] = {
                player = { id = "task-watcher-" .. tostring(index) },
                actorID = "task-watcher-" .. tostring(index),
            }
        end
        return {
            id = "task:" .. tostring(event.id),
            dedupeKey = "task:" .. tostring(event.id),
            priority = 7,
            cooldownMs = 1000,
            participants = { actors.c, actors.d },
            topic = "TASK",
            ttlMs = 9000,
            maxTurns = 2,
            perceived = true,
            audience = audience,
            stimulus = {
                type = "TASK_EVENT",
                sourceID = "npc-c",
                responderID = "npc-d",
                intent = "S5_TASK_REPORT",
                speechAct = "INFORM",
                topic = "TASK",
                eventRefs = { tostring(event.id) },
            },
        }
    end,
})
T.truthy(ok, reason or "register task opportunity provider")

local listed = Opportunity.ListProviders()
T.equal(listed[1].id, "s5.task",
    "providers sort deterministically by order then id")
T.equal(listed[2].id, "s5.faction",
    "second provider preserves deterministic ordering")

local current = 1000
local runtime = Runtime.New({
    maxActiveScenes = 4,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return current end,
})
local manager = Opportunity.New(runtime)

local faction = manager:Admit({
    type = "FACTION_EVENT",
    id = "event-faction-1",
}, {
    authority = "faction_service",
})
T.truthy(faction.accepted, faction.reason or "faction event admitted")
T.equal(faction.proposal.providerID, "s5.faction",
    "faction event routes only through matching provider")
T.equal(faction.initialResult.stimulus.type, "FACTION_EVENT",
    "faction proposal dispatches canonical FACTION_EVENT")
T.equal(faction.initialResult.stimulus.source.actorID, "npc-a",
    "faction event preserves explicit source")
T.equal(faction.initialResult.stimulus.targets[1], "npc-b",
    "faction event preserves explicit responder")
T.equal(faction.initialResult.interactionPlan.behaviorID,
    "behavior.s5.faction",
    "faction event reaches shared Director/catalog")
T.equal(runtime:Snapshot().activeSceneCount, 1,
    "accepted opportunity occupies one global runtime slot")

local duplicate = manager:Admit({
    type = "FACTION_EVENT",
    id = "event-faction-1",
}, {})
T.falsy(duplicate.accepted,
    "repeated active opportunity does not scene-spam")
T.equal(duplicate.rejections[1].reason, "opportunity_active",
    "active dedupe reason is explicit")

runtime:Close(faction.sceneID, "test_close")
current = 2000
local cooldown = manager:Admit({
    type = "FACTION_EVENT",
    id = "event-faction-1",
}, {})
T.falsy(cooldown.accepted,
    "closed scene still observes provider cooldown")
T.equal(cooldown.rejections[1].reason, "opportunity_cooldown",
    "cooldown suppression reason is explicit")

current = 7000
local factionAgain = manager:Admit({
    type = "FACTION_EVENT",
    id = "event-faction-1",
}, {})
T.truthy(factionAgain.accepted,
    "opportunity is reusable after cooldown expires")

packets = {}
local task = manager:Admit({
    type = "TASK_EVENT",
    id = "event-task-1",
}, {
    authority = "tasking",
})
T.truthy(task.accepted, task.reason or "task event admitted")
T.equal(task.proposal.providerID, "s5.task",
    "task event routes through unrelated provider")
T.equal(task.initialResult.stimulus.type, "TASK_EVENT",
    "task proposal dispatches canonical TASK_EVENT")
T.equal(task.initialResult.interactionPlan.behaviorID,
    "behavior.s5.task",
    "task event reaches same shared Director/catalog")
T.equal(#task.proposal.audience, 8,
    "proposal audience is capped before transport")
T.equal(#packets, 8,
    "admission transports one selected turn to at most eight listeners")

local snapshot = manager:Snapshot()
T.equal(snapshot.metrics.accepted, 3,
    "manager records accepted opportunities")
T.equal(snapshot.metrics.activeSuppressed, 1,
    "manager records active dedupe suppression")
T.equal(snapshot.metrics.cooldownSuppressed, 1,
    "manager records cooldown suppression")
T.truthy(snapshot.metrics.transported >= 9,
    "manager counts bounded presentation fanout")
T.equal(snapshot.limits.maxParticipants, 4,
    "opportunity participant cap matches Scene scheduler")
T.equal(snapshot.limits.maxAudience, 8,
    "opportunity audience cap is explicit")

local invalid, invalidReason = Opportunity.NormalizeProposal({
    participants = { actors.a },
    stimulus = {
        type = "TASK_EVENT",
        responderID = "npc-a",
        intent = "S5_TASK_REPORT",
    },
}, "s5.test", 0)
T.equal(invalid, nil,
    "single-actor proposal fails generic participant minimum")
T.equal(invalidReason, "participant_minimum",
    "invalid proposal has stable reason")

local source = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionOpportunity.lua"
)
T.falsy(string.find(source, "Events.OnTick", 1, true),
    "opportunity manager has no polling tick")
T.falsy(string.find(source, "getCell", 1, true),
    "opportunity manager performs no world scan")
T.falsy(string.find(source, "ForEachLive", 1, true),
    "opportunity manager performs no NPC registry scan")
T.falsy(string.find(source, "ForEachPlayer", 1, true),
    "opportunity manager performs no player scan")
T.falsy(string.find(source, "ModData", 1, true),
    "opportunity manager owns no persistent ModData")

Opportunity.ResetProvidersForTests()
Catalog.ResetDraftOverlay()
T.finish("pnc_semantic_scene_runtime_s5_opportunity_smoke")
