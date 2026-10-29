local T = require "tests/support/test"
T.addPackagePaths()

local registryScanCalls = 0
local delivered = 0
PNC = {
    Registry = {
        ForEachLive = function()
            registryScanCalls = registryScanCalls + 1
            error("S8 must not scan the live registry")
        end,
    },
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
                sociability = 0.5,
                empathy = 0.5,
                riskTolerance = 0.5,
            },
            condition = { panic = 0, stress = 0 },
            activity = { currentTask = "s8_fixture", idle = false },
        }, "s8.synthetic"),
        relationship = Providers.NormalizeRelationship({
            state = "neutral",
            familiarity = 1,
            approval = 0,
            respect = 0,
        }, "s8.synthetic"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = {},
        }, "s8.synthetic"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "s8.synthetic",
            relationship = "s8.synthetic",
            knowledge = "s8.synthetic",
        },
    }
end

local actors = {}
for index = 1, 6 do
    local id = "npc-s8-" .. tostring(index)
    actors[index] = {
        id = id,
        projection = projection(id),
    }
end

local function registerBehavior(spec)
    local ok, reason = Catalog.Behaviors.RegisterDraft(spec)
    T.truthy(ok, reason or tostring(spec.id))
end

registerBehavior({
    id = "behavior.s8.synthetic_prompt",
    owner = "S8SyntheticFutureDomain",
    act = "S8_SYNTHETIC_PROMPT",
    mode = "one_shot",
    stimuli = { "TASK_EVENT" },
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
        intent = "S8_SYNTHETIC_ACK",
        speechAct = "ACKNOWLEDGE",
    },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S8_SYNTHETIC_SIGNAL",
    },
    baseRelevance = 1,
    modifiers = {},
})

registerBehavior({
    id = "behavior.s8.synthetic_ack",
    owner = "S8SyntheticFutureDomain",
    act = "S8_SYNTHETIC_ACK",
    mode = "one_shot",
    stimuli = { "NPC_SEMANTIC_ACT" },
    requiredCapabilities = { "speech" },
    outputs = {
        speech = {
            dialogueAct = "ACKNOWLEDGE",
            contentTemplateID = "semantic.social.acknowledged",
        },
    },
    continuation = { mode = "terminate" },
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S8_SYNTHETIC_ACK",
    },
    baseRelevance = 1,
    modifiers = {},
})

registerBehavior({
    id = "behavior.s8.priority",
    owner = "S8SyntheticFutureDomain",
    act = "S8_PRIORITY_ACK",
    mode = "one_shot",
    stimuli = { "FACTION_EVENT" },
    requiredCapabilities = {},
    outputs = {},
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S8_PRIORITY_EVENT",
    },
    baseRelevance = 1,
    modifiers = {},
})

registerBehavior({
    id = "behavior.s8.burst",
    owner = "S8SyntheticFutureDomain",
    act = "S8_BURST_ACK",
    mode = "one_shot",
    stimuli = { "TASK_EVENT", "NPC_SEMANTIC_ACT" },
    requiredCapabilities = {},
    outputs = {},
    when = {
        path = "stimulus.semantic.intent",
        op = "eq",
        value = "S8_BURST_EVENT",
    },
    baseRelevance = 1,
    modifiers = {},
})

-- Synthetic fourth-domain adopter: public Catalog + Opportunity only.
local syntheticOK, syntheticReason = Opportunity.RegisterProvider({
    id = "synthetic.future.signal",
    order = 50,
    stimuli = { "TASK_EVENT" },
    propose = function(event, context)
        local audience = {}
        for index = 1, 12 do
            audience[#audience + 1] = {
                player = { id = "observer-" .. tostring(index) },
                actorID = "observer-" .. tostring(index),
                role = "observer",
            }
        end
        return {
            id = "synthetic:" .. tostring(event.id),
            dedupeKey = "synthetic:" .. tostring(event.id),
            priority = 40,
            cooldownMs = 0,
            participants = context.participants,
            audience = audience,
            topic = "S8_FUTURE_DOMAIN",
            ttlMs = 5000,
            maxTurns = 4,
            perceived = true,
            autoContinue = context.autoContinue == true,
            maxContinuationSteps = 2,
            stimulus = {
                type = "TASK_EVENT",
                responderID = context.participants[1].id,
                intent = "S8_SYNTHETIC_SIGNAL",
                speechAct = "INFORM",
                subject = "S8_FUTURE_SIGNAL",
                topic = "S8_FUTURE_DOMAIN",
                eventRefs = { tostring(event.id) },
            },
        }
    end,
})
T.truthy(syntheticOK, syntheticReason or "synthetic provider registers")

local syntheticRuntime = Runtime.New({
    maxActiveScenes = 4,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return 1000 end,
})
local syntheticManager = Opportunity.New(syntheticRuntime)
delivered = 0
local synthetic = syntheticManager:Admit({
    type = "TASK_EVENT",
    id = "future-domain-1",
}, {
    participants = { actors[1], actors[2] },
    autoContinue = true,
})
T.truthy(synthetic.accepted, synthetic.reason or "future domain admitted")
T.equal(synthetic.initialResult.interactionPlan.behaviorID,
    "behavior.s8.synthetic_prompt",
    "future domain resolves through public draft behavior")
T.equal(synthetic.finalResult.interactionPlan.behaviorID,
    "behavior.s8.synthetic_ack",
    "future domain uses generic semantic continuation unchanged")
T.equal(synthetic.continuationReason, "continuation_terminate",
    "future domain terminates through generic continuation policy")
T.equal(#synthetic.proposal.audience, 8,
    "future domain audience is bounded by public Opportunity contract")
T.equal(delivered, 16,
    "two selected semantic turns fan out to at most eight observers each")
T.equal(registryScanCalls, 0,
    "explicit future-domain participants require no live-registry scan")

-- Generic algorithms must not contain synthetic-domain branches.
for _, relative in ipairs({
    "PNC/Semantics/PNC_SemanticInteractionSceneRuntime.lua",
    "PNC/Semantics/PNC_SemanticInteractionDirector.lua",
    "PNC/Semantics/PNC_SemanticInteractionScheduler.lua",
    "PNC/Semantics/PNC_SemanticInteractionContinuation.lua",
}) do
    local source = T.read("ProjectHoomans", "shared", relative)
    T.falsy(string.find(source, "S8_SYNTHETIC", 1, true),
        relative .. " has no synthetic-domain conditional")
    T.falsy(string.find(source, "synthetic.future.signal", 1, true),
        relative .. " has no synthetic-provider conditional")
end

-- Priority scale: later urgent provider cannot be starved by eight early lows.
Opportunity.ResetProvidersForTests()
for index = 1, 9 do
    local id = "s8.low." .. string.format("%02d", index)
    local ok, reason = Opportunity.RegisterProvider({
        id = id,
        order = index,
        stimuli = { "FACTION_EVENT" },
        propose = function(event)
            return {
                id = id .. ":" .. tostring(event.id),
                dedupeKey = id .. ":" .. tostring(event.id),
                priority = 1,
                cooldownMs = 0,
                participants = { actors[1], actors[2] },
                maxTurns = 2,
                perceived = true,
                autoContinue = false,
                stimulus = {
                    type = "FACTION_EVENT",
                    sourceID = actors[1].id,
                    responderID = actors[2].id,
                    intent = "S8_PRIORITY_EVENT",
                    speechAct = "INFORM",
                },
            }
        end,
    })
    T.truthy(ok, reason or id)
end
local urgentOK, urgentReason = Opportunity.RegisterProvider({
    id = "s8.urgent.late",
    order = 99,
    stimuli = { "FACTION_EVENT" },
    propose = function(event)
        return {
            id = "urgent:" .. tostring(event.id),
            dedupeKey = "urgent:" .. tostring(event.id),
            priority = 100,
            cooldownMs = 0,
            participants = { actors[1], actors[2] },
            maxTurns = 2,
            perceived = true,
            autoContinue = false,
            stimulus = {
                type = "FACTION_EVENT",
                sourceID = actors[1].id,
                responderID = actors[2].id,
                intent = "S8_PRIORITY_EVENT",
                speechAct = "INFORM",
            },
        }
    end,
})
T.truthy(urgentOK, urgentReason or "urgent provider registers")
local ranked = Opportunity.Evaluate({
    type = "FACTION_EVENT",
    id = "priority-event",
}, {})
T.equal(#ranked, Opportunity.MAX_PROPOSALS,
    "proposal output remains hard-capped")
T.equal(ranked[1].providerID, "s8.urgent.late",
    "later urgent provider survives bounded top-K ranking")
local priorityRuntime = Runtime.New({ maxActiveScenes = 2 })
local priorityManager = Opportunity.New(priorityRuntime)
local priorityAdmission = priorityManager:Admit({
    type = "FACTION_EVENT",
    id = "priority-admit",
}, {})
T.truthy(priorityAdmission.accepted, "urgent opportunity admits")
T.equal(priorityAdmission.proposal.providerID, "s8.urgent.late",
    "admission consumes highest-priority proposal first")

-- Burst/scale: 20 explicit events cannot exceed 16 simultaneous scenes.
Opportunity.ResetProvidersForTests()
local burstOK, burstReason = Opportunity.RegisterProvider({
    id = "s8.burst.provider",
    order = 1,
    stimuli = { "TASK_EVENT" },
    propose = function(event, context)
        return {
            id = "burst:" .. tostring(event.id),
            dedupeKey = "burst:" .. tostring(event.id),
            priority = 1,
            cooldownMs = 0,
            participants = context.participants,
            topic = "S8_BURST",
            ttlMs = 10000,
            maxTurns = 2,
            perceived = context.perceived == true,
            distance = context.distance,
            autoContinue = false,
            stimulus = {
                type = "TASK_EVENT",
                sourceID = context.participants[1].id,
                responderID = context.participants[2].id,
                intent = "S8_BURST_EVENT",
                speechAct = "INFORM",
                topic = "S8_BURST",
            },
        }
    end,
})
T.truthy(burstOK, burstReason or "burst provider registers")

local burstRuntime = Runtime.New({
    maxActiveScenes = 16,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return 1000 end,
})
local burstManager = Opportunity.New(burstRuntime)
local accepted = 0
local rejected = 0
local fakeLargeRegistry = {}
for index = 1, 1000 do
    fakeLargeRegistry[index] = { id = "unused-" .. tostring(index) }
end
for index = 1, 20 do
    local result = burstManager:Admit({
        type = "TASK_EVENT",
        id = "burst-event-" .. tostring(index),
    }, {
        participants = { actors[1], actors[2] },
        registrySize = #fakeLargeRegistry,
        perceived = true,
    })
    if result.accepted then accepted = accepted + 1
    else rejected = rejected + 1 end
end
local burstSnapshot = burstRuntime:Snapshot()
T.equal(accepted, 16,
    "global Scheduler admits only sixteen simultaneous scenes")
T.equal(rejected, 4,
    "burst overflow is rejected rather than creating hidden scenes")
T.equal(burstSnapshot.activeSceneCount, 16,
    "runtime active scene count stays at hard ceiling")
T.equal(burstSnapshot.metrics.maxActiveScenes, 16,
    "runtime records bounded max active scene pressure")
T.equal(registryScanCalls, 0,
    "large unrelated registry remains untouched by explicit admission")

-- Four participants remain one scene, not six pairwise sub-scenes.
local pairRuntime = Runtime.New({ maxActiveScenes = 4 })
local group, groupID = pairRuntime:Open({
    id = "scene:s8:group4",
    participants = { actors[1], actors[2], actors[3], actors[4] },
    perceived = true,
    maxTurns = 2,
})
T.truthy(group, groupID or "four-person scene opens")
T.equal(pairRuntime:Snapshot().activeSceneCount, 1,
    "four participants create one scene, not pairwise scene explosion")
T.equal(group:Snapshot().participantCount, 4,
    "scene participant cap supports one explicit four-actor scene")

-- TTL expiry leaves only compact closure semantics.
local now = 1000
local ttlRuntime = Runtime.New({
    maxActiveScenes = 4,
    clock = function() return now end,
})
local ttlScene, ttlID = ttlRuntime:Open({
    id = "scene:s8:ttl",
    participants = { actors[1], actors[2] },
    perceived = true,
    ttlMs = 1000,
})
T.truthy(ttlScene, ttlID or "TTL scene opens")
now = 2001
T.equal(ttlRuntime:Sweep(), 1, "TTL sweep closes elapsed scene")
T.equal(ttlRuntime:Snapshot().metrics.ttlExpired, 1,
    "TTL closure is counted")
local ttlClosures = ttlRuntime.scheduler:Snapshot().recentClosures
T.equal(ttlClosures[#ttlClosures].reason, "ttl_expired",
    "TTL termination reason remains compact and explainable")

-- Actor death/leave closes every containing scene without scan/pair explosion.
local leaveRuntime = Runtime.New({ maxActiveScenes = 4 })
local leaveScene, leaveID = leaveRuntime:Open({
    id = "scene:s8:leave",
    participants = { actors[1], actors[2], actors[3] },
    perceived = true,
})
T.truthy(leaveScene, leaveID or "leave scene opens")
T.equal(leaveRuntime:ActorUnavailable(actors[2].id, "actor_dead"), 1,
    "actor-unavailable signal closes containing scene")
T.equal(leaveRuntime:Snapshot().activeSceneCount, 0,
    "dead/left participant does not leave zombie scene state")

-- Turn/history cap remains bounded and records explicit closure reason.
local turnRuntime = Runtime.New({ maxActiveScenes = 2, maxTurns = 8 })
local turnScene, turnID = turnRuntime:Open({
    id = "scene:s8:turn-cap",
    participants = { actors[1], actors[2] },
    perceived = true,
    maxTurns = 1,
})
T.truthy(turnScene, turnID or "turn-cap scene opens")
local firstTurn, firstReason = turnScene:EmitSemanticAct({
    sourceID = actors[1].id,
    responderID = actors[2].id,
    intent = "S8_BURST_EVENT",
    speechAct = "INFORM",
})
T.truthy(firstTurn, firstReason or "first bounded turn succeeds")
local overTurn, overReason = turnScene:EmitSemanticAct({
    sourceID = actors[2].id,
    responderID = actors[1].id,
    intent = "S8_BURST_EVENT",
    speechAct = "INFORM",
})
T.equal(overTurn, nil, "turn cap rejects overflow")
T.equal(overReason, "scene_turn_limit", "turn cap reason is explicit")
local turnClosures = turnRuntime.scheduler:Snapshot().recentClosures
T.equal(turnClosures[#turnClosures].reason, "turn_limit",
    "turn-limit closure remains observable")

-- Distant/unperceived work is semantic-only: Director runs once, no rendering.
local distantRuntime = Runtime.New({ maxActiveScenes = 2 })
local distant, distantID = distantRuntime:Open({
    id = "scene:s8:distant",
    participants = { actors[1], actors[2] },
    perceived = false,
    distance = 200,
    maxTurns = 2,
})
T.truthy(distant, distantID or "distant scene opens")
local distantTurn, distantReason = distant:EmitSemanticAct({
    sourceID = actors[1].id,
    responderID = actors[2].id,
    intent = "S8_BURST_EVENT",
    speechAct = "INFORM",
})
T.truthy(distantTurn, distantReason or "distant semantic turn runs")
T.truthy(distantTurn.realizationPolicy.semanticOnly,
    "distant scene uses semantic-only realization policy")
T.equal(distantTurn.presentation.speech, nil,
    "semantic-only scene does not realize speech")
T.equal(distantTurn.presentation.emote, nil,
    "semantic-only scene does not realize emote")
T.equal(distantTurn.presentation.flavor, nil,
    "semantic-only scene does not realize observer flavor")
T.equal(distantRuntime.scheduler:Metrics().directorEvaluations, 1,
    "one semantic decision occurs independent of observer count")

-- Static guards for the generic substrate.
for _, relative in ipairs({
    "PNC/Semantics/PNC_SemanticInteractionOpportunity.lua",
    "PNC/Semantics/PNC_SemanticInteractionSceneRuntime.lua",
    "PNC/Semantics/PNC_SemanticInteractionScheduler.lua",
    "PNC/Semantics/PNC_SemanticInteractionContinuation.lua",
    "PNC/Semantics/PNC_SemanticInteractionSceneObservatory.lua",
}) do
    local source = T.read("ProjectHoomans", "shared", relative)
    T.falsy(string.find(source, "Events.OnTick", 1, true),
        relative .. " has no polling hook")
    T.falsy(string.find(source, "Registry.ForEachLive", 1, true),
        relative .. " has no full-NPC scan")
    T.falsy(string.find(source, "getZombieList", 1, true),
        relative .. " has no global-zombie scan")
    T.falsy(string.find(source, "PsychopatzSemantic.Parse", 1, true),
        relative .. " never reparses realized dialogue")
    T.falsy(string.find(source, "ModData", 1, true),
        relative .. " owns no autonomous-scene persistence root")
    T.falsy(string.find(source, "llmEligible = true", 1, true),
        relative .. " has no routine autonomous-scene LLM opt-in")
    T.falsy(string.find(source, "transcriptText", 1, true),
        relative .. " stores no rendered transcript text")
    T.falsy(string.find(source, "renderedText", 1, true),
        relative .. " stores no rendered dialogue payload")
end

Opportunity.ResetProvidersForTests()
Catalog.ResetDraftOverlay()
T.finish("pnc_semantic_scene_runtime_s8_extensibility_stress")
