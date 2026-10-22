local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})

PNC = { Registry = {}, Factions = {} }
local Adapter = require "PNC/WorldKnowledge/PNC_WorldKnowledge"
local WKG = Adapter.Core
T.truthy(WKG, "Core WorldKnowledge loaded")
WKG.Reset({ maxFacts = 8, maxRefs = 8 })

local alice = { id = "npc:alice", coreActorID = "actor:alice", alive = true,
    name = "Alice", affiliation = { factionID = "faction:one" } }
local bob = { id = "npc:bob", coreActorID = "actor:bob", alive = true,
    name = "Bob", affiliation = { factionID = "faction:one" } }
PNC.Registry.Get = function(id)
    return tostring(id) == alice.id and alice or tostring(id) == bob.id and bob or nil
end
PNC.Factions.Get = function(id)
    return tostring(id) == "faction:one" and {
        id = "faction:one", name = "One", memberIDs = {
            [alice.id] = true, [bob.id] = true,
        },
    } or nil
end

local pressure = Adapter.PublishZombiePressure(alice, 12, "follow", 10)
T.truthy(pressure, "pressure fact")
T.truthy(WKG.ActorKnowledge.Get(WKG.KnowledgeState, alice.coreActorID,
    pressure.factID), "experienced actor reference")
local context = Adapter.BuildConversationContext(alice, { language = "EN" })
T.equal(#context.npcGossip.statements, 1, "grounded statement")
T.equal(context.npcGossip.factRefs[1], pressure.factID, "statement reference")

local death = Adapter.PublishDeath(alice, { attackerKind = "player",
    attackerID = "player:one" }, "combat", 11)
T.truthy(death, "death fact")
T.truthy(WKG.ActorKnowledge.Get(WKG.KnowledgeState, bob.coreActorID,
    death.factID), "faction dissemination")
local explanation = Adapter.Explain(bob, death.factID, 12)
T.truthy(explanation, "explainability")
T.equal(explanation.provenance, "faction", "faction provenance")

print("pnc_world_knowledge_smoke: PASS")
