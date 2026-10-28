local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Providers = require "PNC/Semantics/PNC_SemanticInteractionProviders"
local Scene = require "PNC/Semantics/PNC_SemanticInteractionScene"

local registered, reason = Providers.RegisterActorAdapter({
    id = "synthetic.scene_actor",
    priority = 50,
    CanAdapt = function(actor)
        return type(actor) == "table" and actor.system == "scene-test"
    end,
    ProjectActor = function(actor)
        return {
            id = actor.id,
            capabilities = {
                speech = actor.canSpeak,
                emote = actor.canEmote,
            },
            disposition = {
                aggression = actor.aggression,
                confidence = actor.confidence,
                forgiveness = actor.forgiveness,
                sociability = actor.sociability,
                empathy = actor.empathy,
            },
            condition = {
                panic = actor.panic,
            },
            activity = {
                currentTask = actor.task or "idle",
                idle = (actor.task or "idle") == "idle",
            },
            traits = actor.tags,
        }
    end,
    ProjectRelationship = function(actor, other)
        other = type(other) == "table" and other or {}
        return {
            familiarity = actor.familiarityByID
                and actor.familiarityByID[other.id],
            approval = actor.approvalByID
                and actor.approvalByID[other.id],
            trust = actor.trustByID
                and actor.trustByID[other.id],
        }
    end,
    ProjectKnowledge = function(actor)
        return {
            available = true,
            factRefs = actor.factRefs or {},
        }
    end,
})
T.truthy(registered, reason or "scene adapter registers")

local function actor(id, spec)
    spec = spec or {}
    return {
        system = "scene-test",
        id = id,
        canSpeak = spec.canSpeak ~= false,
        canEmote = spec.canEmote ~= false,
        aggression = spec.aggression or 0.3,
        confidence = spec.confidence or 0.5,
        forgiveness = spec.forgiveness or 0.5,
        sociability = spec.sociability or 0.5,
        empathy = spec.empathy or 0.5,
        panic = spec.panic or 0,
        task = spec.task or "idle",
        familiarityByID = spec.familiarityByID or {},
        approvalByID = spec.approvalByID or {},
        trustByID = spec.trustByID or {},
        factRefs = spec.factRefs or {},
        tags = spec.tags or {},
    }
end

local memoryFact = "fact.former_job.mechanic"
local newsFact = "fact.world.helicopter.recent"
local dangerEvent = "event.zombie_breach.1"

local source = actor("npc-a", {
    factRefs = { memoryFact, newsFact },
    sociability = 0.6,
    empathy = 0.5,
    familiarityByID = { ["npc-b"] = 3, ["npc-c"] = 2 },
})
local curious = actor("npc-b", {
    sociability = 0.9,
    empathy = 0.1,
    familiarityByID = { ["npc-a"] = 3, ["npc-c"] = 2 },
    approvalByID = { ["npc-a"] = 10 },
})
local empathic = actor("npc-c", {
    sociability = 0.2,
    empathy = 0.9,
    familiarityByID = { ["npc-a"] = 3, ["npc-b"] = 2 },
})

-- Two-NPC scene: semantic memory disclosure goes directly to the responder.
local scene, sceneReason = Scene.New({
    id = "scene.memory.followup",
    participants = {
        { id = "npc-a", actor = source },
        { id = "npc-b", actor = curious },
    },
    perceived = true,
    distance = 8,
    topic = "FORMER_JOB",
    world = { immediateDanger = false },
    worldEvents = { dangerEvent },
})
T.truthy(scene, sceneReason or "memory scene opens")

local followup, followupReason = scene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-b",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    topic = "FORMER_JOB",
    factID = memoryFact,
})
T.truthy(followup, followupReason or "memory disclosure handled")
T.equal(followup.stimulus.type, "NPC_SEMANTIC_ACT",
    "NPC-to-NPC scene uses direct semantic stimulus")
T.truthy(followup.stimulus.text == nil,
    "NPC semantic acts carry no generated text for reparsing")
T.equal(followup.interactionPlan.behaviorID,
    "behavior.ask_memory_followup",
    "sociable responder asks a grounded follow-up")
T.equal(followup.interactionPlan.groundedFactRefs[1], memoryFact,
    "interaction plan retains grounded fact identity")
T.truthy(type(followup.presentation.speech) == "table",
    "perceived scene realizes the selected speech output")
T.equal(followup.presentation.speech.phraseSemanticTemplateID,
    "semantic.interaction.memory.followup",
    "speech uses ordinary Dialogue Content")
T.truthy(followup.presentation.speech.fallback ~= nil,
    "speech realization produced visible wording")
T.truthy(followup.semanticHistoryEvent.text == nil,
    "scene history event contains no rendered transcript text")

local snap = scene:Snapshot()
T.equal(snap.semanticHistoryCount, 1,
    "scene stores one bounded semantic history row")
T.equal(snap.semanticHistory[1].factID, memoryFact,
    "semantic history stores fact identity")
T.truthy(snap.semanticHistory[1].text == nil,
    "snapshot does not persist generated prose")
T.falsy(snap.transcriptStored,
    "scene explicitly reports no transcript persistence")

-- Same SHARE_MEMORY stimulus, different responder state: acknowledge instead.
local empathicScene, empathicReason = Scene.New({
    id = "scene.memory.ack",
    participants = {
        { id = "npc-a", actor = source },
        { id = "npc-c", actor = empathic },
    },
    perceived = true,
    distance = 8,
    topic = "FORMER_JOB",
    world = { immediateDanger = false },
})
T.truthy(empathicScene, empathicReason or "empathic scene opens")
local acknowledgement, ackReason = empathicScene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-c",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    topic = "FORMER_JOB",
    factID = memoryFact,
})
T.truthy(acknowledgement, ackReason or "empathic response handled")
T.equal(acknowledgement.interactionPlan.behaviorID,
    "behavior.acknowledge_memory",
    "empathic low-sociability responder acknowledges instead of interrogating")
T.truthy(type(acknowledgement.presentation.speech) == "table",
    "one semantic behavior can realize speech")
T.equal(acknowledgement.presentation.emote.id, "emote.nod",
    "same semantic behavior can realize an emote")
T.truthy(type(acknowledgement.presentation.flavor) == "table",
    "same semantic behavior can realize ambient flavor")
T.equal(acknowledgement.presentation.flavor.phraseSemanticTemplateID,
    "semantic.interaction.memory.acknowledge_flavor",
    "ambient flavor uses ordinary Dialogue Content")
T.equal(acknowledgement.presentation.behaviorID,
    "behavior.acknowledge_memory",
    "speech/emote/flavor share one behavior decision")

-- Speech-disabled actor still participates via non-speech presentation.
local silent = actor("npc-silent", {
    canSpeak = false,
    canEmote = true,
    sociability = 0.2,
    empathy = 0.9,
    familiarityByID = { ["npc-a"] = 3 },
})
local silentScene, silentReason = Scene.New({
    id = "scene.memory.silent",
    participants = {
        { id = "npc-a", actor = source },
        { id = "npc-silent", actor = silent },
    },
    perceived = true,
    distance = 8,
    world = { immediateDanger = false },
})
T.truthy(silentScene, silentReason or "silent actor scene opens")
local silentResult, silentResultReason = silentScene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-silent",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    factID = memoryFact,
})
T.truthy(silentResult, silentResultReason or "silent actor reacts")
T.equal(silentResult.interactionPlan.behaviorID,
    "behavior.acknowledge_memory",
    "speech capability is not required by acknowledge-memory behavior")
T.truthy(silentResult.presentation.speech == nil,
    "speech-disabled actor does not realize speech")
T.equal(silentResult.presentation.emote.id, "emote.nod",
    "speech-disabled actor can still realize emote")
T.truthy(type(silentResult.presentation.flavor) == "table",
    "observer flavor remains available for the same behavior")

-- Source may not disclose a fact it does not know.
local unknown, unknownReason = scene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-b",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    factID = "fact.unknown.fabricated",
})
T.falsy(unknown, "unknown source fact is rejected")
T.equal(unknownReason, "source_fact_unknown:fact.unknown.fabricated",
    "unknown fact failure is grounded and explicit")

-- Grounded news uses the same knowledge gate.
local news, newsReason = scene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-b",
    intent = "SHARE_NEWS",
    speechAct = "DISCLOSE",
    topic = "HELICOPTER",
    factID = newsFact,
})
T.truthy(news, newsReason or "grounded news handled")
T.equal(news.interactionPlan.behaviorID,
    "behavior.acknowledge_news",
    "grounded news selects reusable acknowledgement behavior")
T.equal(news.interactionPlan.groundedFactRefs[1], newsFact,
    "news retains its grounded fact identity")

-- Three participants do not imply broadcast or pairwise explosion.
local multi, multiReason = Scene.New({
    id = "scene.multi",
    participants = {
        { id = "npc-a", actor = source },
        { id = "npc-b", actor = curious },
        { id = "npc-c", actor = empathic },
    },
    perceived = true,
    distance = 6,
    world = { immediateDanger = false },
})
T.truthy(multi, multiReason or "three participant scene opens")
local firstMulti = multi:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-b",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    factID = memoryFact,
})
T.truthy(firstMulti, "first targeted multi-NPC turn succeeds")
local secondMulti = multi:EmitSemanticAct({
    sourceID = "npc-b",
    responderID = "npc-c",
    intent = "THANK",
    speechAct = "THANK",
    topic = "social",
})
T.truthy(secondMulti, "second targeted multi-NPC turn succeeds")
local multiSnap = multi:Snapshot()
T.equal(multiSnap.participantCount, 3,
    "multi-NPC scene retains exactly three explicit participants")
T.equal(multiSnap.semanticHistoryCount, 2,
    "two submitted semantic acts create two history events only")
T.equal(multiSnap.semanticHistory[1].targetActorID, "npc-b",
    "first event targets only B")
T.equal(multiSnap.semanticHistory[2].targetActorID, "npc-c",
    "second event targets only C")
T.equal(multiSnap.scheduler.activeSceneCount, 1,
    "multi-NPC scene does not spawn pairwise sub-scenes")

-- Active argument is interrupted by a grounded danger event.
local argumentScene, argumentReason = Scene.New({
    id = "scene.danger.interrupt",
    participants = {
        { id = "npc-a", actor = source },
        { id = "npc-b", actor = curious },
    },
    perceived = true,
    distance = 5,
    world = { immediateDanger = false },
    worldEvents = { dangerEvent },
})
T.truthy(argumentScene, argumentReason or "argument scene opens")
local hostile, hostileReason = argumentScene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-b",
    intent = "HOSTILE_REMARK",
    speechAct = "HOSTILE_REMARK",
})
T.truthy(hostile, hostileReason or "hostile semantic act handled")
T.equal(hostile.decision.selectedBeat.id, "beat.argument_escalation",
    "NPC semantic hostility can enter the argument beat")
T.equal(argumentScene:Snapshot().director.active.id,
    "beat.argument_escalation",
    "scene-local beat state commits after semantic turn")

local warning, warningReason = argumentScene:EmitWorldEvent({
    type = "DANGER_CHANGED",
    responderID = "npc-b",
    eventID = dangerEvent,
    topic = "danger",
    worldPatch = { immediateDanger = true },
    providerID = "projectzomboid.synthetic_world_event",
})
T.truthy(warning, warningReason or "grounded danger event handled")
T.equal(warning.decision.exited.id, "beat.argument_escalation",
    "danger stimulus exits the active argument")
T.equal(warning.interactionPlan.behaviorID,
    "behavior.world_event_warn",
    "danger selects reusable group-warning behavior")
T.equal(warning.interactionPlan.groundedEventRefs[1], dangerEvent,
    "world reaction retains grounded event identity")
T.truthy(type(warning.presentation.speech) == "table",
    "perceived danger warning can realize speech")
T.equal(warning.presentation.emote.id, "emote.alert",
    "same danger behavior emits alert emote")
T.truthy(type(warning.presentation.flavor) == "table",
    "same danger behavior emits flavor presentation")
T.truthy(argumentScene:Snapshot().director.active == nil,
    "argument remains retired after danger interruption")

-- Unknown world event cannot be invented.
local bogusEvent, bogusEventReason = argumentScene:EmitWorldEvent({
    responderID = "npc-b",
    eventID = "event.fabricated",
})
T.falsy(bogusEvent, "unregistered world event is rejected")
T.equal(bogusEventReason, "scene_world_event_unknown:event.fabricated",
    "world event grounding failure is explicit")

-- Nearby but unperceived scene runs semantics without presentation.
local quietScene, quietReason = Scene.New({
    id = "scene.unperceived",
    participants = {
        { id = "npc-a", actor = source },
        { id = "npc-c", actor = empathic },
    },
    perceived = false,
    distance = 10,
    world = { immediateDanger = false },
})
T.truthy(quietScene, quietReason or "unperceived scene opens")
local quiet, quietResultReason = quietScene:EmitSemanticAct({
    sourceID = "npc-a",
    responderID = "npc-c",
    intent = "SHARE_MEMORY",
    speechAct = "DISCLOSE",
    factID = memoryFact,
})
T.truthy(quiet, quietResultReason or "unperceived semantic event runs")
T.equal(quiet.interactionPlan.behaviorID,
    "behavior.acknowledge_memory",
    "unperceived scene still performs semantic arbitration")
T.truthy(quiet.presentation.speech == nil,
    "unperceived scene skips speech realization")
T.truthy(quiet.presentation.emote == nil,
    "unperceived scene skips emote realization")
T.truthy(quiet.presentation.flavor == nil,
    "unperceived scene skips flavor realization")
T.truthy(quiet.realizationPolicy.semanticOnly == true,
    "unperceived scene reports semantic-only LOD")

T.finish("pnc_semantic_interaction_scene_smoke")
