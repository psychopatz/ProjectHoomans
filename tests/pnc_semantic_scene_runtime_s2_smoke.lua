local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Runtime = require "PNC/Semantics/PNC_SemanticInteractionSceneRuntime"

local function projection(id, facts, sociability, empathy)
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
                empathy = empathy or 0.5,
                riskTolerance = 0.5,
            },
            condition = {
                panic = 0,
                stress = 0,
            },
            activity = {
                currentTask = "idle",
                idle = true,
            },
        }, "scene.runtime.test"),
        relationship = Providers.NormalizeRelationship({
            state = "neutral",
            familiarity = 2,
            approval = 0,
            respect = 0,
        }, "scene.runtime.test"),
        knowledge = Providers.NormalizeKnowledge({
            available = true,
            factRefs = facts or {},
        }, "scene.runtime.test"),
        evidence = {
            schemaVersion = 1,
            rows = {},
            providers = {},
            truncated = false,
            matched = 0,
        },
        provenance = {
            actor = "scene.runtime.test",
            relationship = "scene.runtime.test",
            knowledge = "scene.runtime.test",
        },
    }
end

local factID = "fact.scene.runtime.s2"
local clock = 1000
local runtime = Runtime.New({
    maxActiveScenes = 2,
    maxParticipants = 4,
    maxTurns = 8,
    clock = function() return clock end,
})

local first, firstID = runtime:Open({
    participants = {
        { id = "npc-a", projection = projection("npc-a", { factID }, 0.6, 0.4) },
        { id = "npc-b", projection = projection("npc-b", {}, 0.8, 0.2) },
    },
    perceived = true,
    distance = 8,
    maxTurns = 2,
    ttlMs = 2000,
    topic = "FORMER_JOB",
    providerID = "test.first",
})
T.truthy(first, firstID or "first runtime scene opens")
T.equal(firstID, "scene:runtime:1",
    "runtime-generated scene IDs are deterministic")
T.falsy(first.ownsScheduler,
    "runtime-owned scene uses injected shared scheduler")

local second, secondID = runtime:Open({
    id = "scene:explicit:second",
    participants = {
        { id = "npc-c", projection = projection("npc-c", { factID }, 0.4, 0.8) },
        { id = "npc-d", projection = projection("npc-d", {}, 0.4, 0.8) },
    },
    perceived = false,
    distance = 100,
    maxTurns = 1,
    ttlMs = 8000,
    providerID = "test.second",
})
T.truthy(second, secondID or "second runtime scene opens")
T.equal(secondID, "scene:explicit:second",
    "explicit valid scene ID is preserved")

local rejected, rejectedReason = runtime:Open({
    id = "scene:third",
    participants = {
        { id = "npc-e", projection = projection("npc-e", {}) },
        { id = "npc-f", projection = projection("npc-f", {}) },
    },
})
T.equal(rejected, nil, "global scene cap rejects third active scene")
T.equal(rejectedReason, "scene_active_limit",
    "shared Scheduler owns the global cap")

local snapshot = runtime:Snapshot()
T.equal(snapshot.activeSceneCount, 2,
    "runtime reports both active scenes")
T.equal(snapshot.scheduler.activeSceneCount, 2,
    "one scheduler owns both active scenes")
T.equal(snapshot.metrics.maxActiveScenes, 2,
    "runtime metrics retain max active scenes")
T.equal(snapshot.limits.maxActiveScenes, 2,
    "runtime snapshot exposes configured global cap")
T.equal(snapshot.scenes[1].runtime.providerID, "test.first",
    "runtime retains bounded provider provenance")

local visible = runtime:UpdateVisibility(secondID, {
    perceived = true,
    distance = 10,
})
T.truthy(visible, "visibility update succeeds explicitly")
T.equal(visible.lod, "nearby_perceived",
    "visibility update changes scheduler LOD without polling")

local turn, turnReason = second:EmitSemanticAct({
    sourceID = "npc-c",
    responderID = "npc-d",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    topic = "FORMER_JOB",
    factID = factID,
})
T.truthy(turn, turnReason or "first per-scene turn is accepted")
local over, overReason = second:EmitSemanticAct({
    sourceID = "npc-c",
    responderID = "npc-d",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    topic = "FORMER_JOB",
    factID = factID,
})
T.equal(over, nil, "per-scene turn limit rejects another turn")
T.equal(overReason, "scene_turn_limit",
    "per-scene maxTurns survives shared scheduler injection")
T.equal(runtime:Get(secondID), nil,
    "runtime prunes scene closed internally by Scheduler")

local replacement, replacementID = runtime:Open({
    id = "scene:replacement",
    participants = {
        { id = "npc-e", projection = projection("npc-e", { factID }) },
        { id = "npc-f", projection = projection("npc-f", {}) },
    },
    ttlMs = 9000,
    providerID = "test.replacement",
})
T.truthy(replacement, replacementID or "closed slot admits replacement")

clock = 3001
T.equal(runtime:Sweep(), 1,
    "explicit sweep expires exactly the elapsed TTL scene")
T.equal(runtime:Get(firstID), nil,
    "expired first scene is removed")
T.truthy(runtime:Get(replacementID),
    "longer-lived replacement remains active")

local affected = runtime:ActorUnavailable("npc-e", "actor_dead")
T.equal(affected, 1,
    "actor-unavailable notification closes containing scene")
T.equal(runtime:Get(replacementID), nil,
    "actor-unavailable scene is removed")

local final = runtime:Snapshot()
T.equal(final.activeSceneCount, 0,
    "runtime ends with no active scenes")
T.equal(final.metrics.ttlExpired, 1,
    "TTL expiry is observable")
T.equal(final.metrics.actorUnavailableClosed, 1,
    "actor-unavailable closure is observable")
T.equal(final.metrics.admissionRejected, 1,
    "global-cap rejection is observable")

local runtimeSource = T.read(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticInteractionSceneRuntime.lua"
)
T.falsy(string.find(runtimeSource, "Events.OnTick", 1, true),
    "global Scene Runtime has no tick hook")
T.falsy(string.find(runtimeSource, "ModData", 1, true),
    "global Scene Runtime owns no persistent ModData")
T.falsy(string.find(runtimeSource, "getZombieList", 1, true),
    "global Scene Runtime owns no world/zombie scan")

T.finish("pnc_semantic_scene_runtime_s2_smoke")
