local T = require "tests/support/test"
T.addPackagePaths()

local now = 240
PNC = { Core = { Now = function() return now end } }
PsychopatzCore = nil

T.load("ProjectHoomans", "shared",
    "PNC/WorldKnowledge/PNC_WorldKnowledge.lua")

local worldKnowledge = PNC.WorldKnowledge
worldKnowledge.Core.Reset({ maxFacts = 8, maxActors = 8, maxRefs = 4 })
local fact = worldKnowledge.Publish({
    producer = "test:faction",
    kind = "faction.status",
    subject = { id = "faction-a", kind = "faction" },
    eventID = "collapse-1",
    occurredAt = 220,
    observedAt = 221,
    severity = 1,
    retention = "historical",
    payload = { status = "destroyed", reason = "test" },
})
T.truthy(fact, "test fact was not published")
local aliceRef = worldKnowledge.Core.Acquire("alice", fact.factID, {
    authorized = true,
    provenance = "faction",
    source = "faction_commit",
    acquisitionPath = "faction",
    confidence = 0.95,
    learnedAt = 222,
})
T.truthy(aliceRef, "Alice did not acquire the fact")
local transferred = worldKnowledge.Core.Share("alice", "bob", {
    authorized = true,
    provenance = "told",
    source = "conversation",
    acquisitionPath = "conversation",
    confidence = 0.85,
    now = now,
    max = 1,
})
T.equal(#transferred, 1, "authorized share did not transfer one fact")

T.load("ProjectHoomans", "server",
    "PNC/WorldKnowledge/PNC_WorldKnowledge_Debug.lua")
local service = PNC.WorldKnowledgeDebug

local alice = service.BuildSnapshotForPlayer(nil, {
    actorID = "alice", factID = fact.factID, factLimit = 999,
    referenceLimit = 999, candidateLimit = 999, traceLimit = 999,
})
T.equal(alice.schema, "PNC.WorldKnowledgeDebug", "debug schema")
T.equal(alice.limits.facts, 64, "fact limit contract")
T.equal(alice.metrics.factCount, 1, "ledger metric fact count")
T.equal(alice.metrics.knownActorCount, 2, "knowledge metric actor count")
T.truthy(alice.metrics.consumerEvidenceCount > 0,
    "consumer evidence was not projected")
T.equal(alice.persistence.modDataKey, "PNC.WorldKnowledge",
    "persistence contract key")
T.falsy(alice.worldState.observed, "unobserved world state was reported")
T.equal(alice.facts[1].factID, fact.factID, "fact projection")
T.truthy(alice.actor.known, "Alice knowledge was not reported")
T.equal(alice.actor.references[1].provenance, "faction",
    "Alice provenance changed")
T.equal(alice.explanation.provenance, "faction",
    "Alice explanation provenance changed")
T.equal(alice.context.npcGossip.factRefs[1], fact.factID,
    "Alice gossip fact reference")
T.truthy(alice.context.npcGossip.statements[1],
    "Alice gossip projection was empty")
local producerEvidence
local acquiredEvidence
for _, evidence in ipairs(alice.consumerEvidence or {}) do
    if evidence.factID == fact.factID
        and evidence.role == "producer"
    then
        producerEvidence = evidence
    elseif evidence.factID == fact.factID
        and evidence.role == "actor_knowledge"
    then
        acquiredEvidence = evidence
    end
end
T.equal(producerEvidence.status, "published",
    "producer evidence status")
T.equal(acquiredEvidence.status, "acquired",
    "actor knowledge consumer evidence status")
T.equal(#alice.trace, 1, "propagation trace was not bounded and returned")

local bob = service.BuildSnapshotForPlayer(nil, { actorID = "bob" })
T.truthy(bob.actor.known, "Bob knowledge was not reported after sharing")
T.equal(bob.actor.references[1].provenance, "told",
    "Bob was made to appear as a witness")
T.equal(bob.context.npcGossip.factRefs[1], fact.factID,
    "Bob gossip did not retain the same fact")
T.equal(bob.explanation, nil,
    "Bob explanation was unexpectedly selected without a fact request")

local unknown = service.BuildSnapshotForPlayer(nil, { actorID = "charlie" })
T.falsy(unknown.actor.known, "unknown actor became omniscient")
T.equal(#unknown.context.npcGossip.statements, 0,
    "unknown actor received baseless gossip")

T.finish("pnc_world_knowledge_debug_snapshot_smoke")
