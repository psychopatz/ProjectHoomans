local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})

PNC = { Registry = {}, Factions = {} }
local Adapter = require "PNC/WorldKnowledge/PNC_WorldKnowledge"
require "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ"
local WKG = Adapter.Core
T.truthy(WKG, "Core WorldKnowledge loaded")
WKG.Reset({ maxFacts = 8, maxRefs = 8 })
Adapter.ResetWorldStateRuntime()

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

WKG.Reset({ maxFacts = 16, maxRefs = 8 })
Adapter.ResetWorldStateRuntime()
local firstState, firstFacts = Adapter.ObserveAuthoritativeWorldState({
    helicopter = function() return true, "pz_authority" end,
    power = function() return true, "pz_authority" end,
    water = function() return nil, "unverified_water" end,
    season = function() return "Summer", "climate_authority" end,
}, { at = 20 })
T.equal(firstState.helicopter.status, "on", "helicopter authority")
T.equal(firstState.water.status, "unknown", "water remains unknown")
T.equal(#firstFacts, 3, "known initial world states only")
local _, repeatFacts = Adapter.ObserveAuthoritativeWorldState({
    helicopter = function() return true end,
    power = function() return true end,
    water = function() return nil end,
    season = function() return "Summer" end,
}, { at = 21 })
T.equal(#repeatFacts, 0, "same world state deduped")
local changedState, changedFacts = Adapter.ObserveAuthoritativeWorldState({
    helicopter = function() return false, "pz_authority" end,
    power = function() return false, "pz_authority" end,
    water = function() return false, "pz_authority" end,
    season = function() return "Autumn", "climate_authority" end,
}, { at = 22 })
T.equal(changedState.power.status, "off", "power transition")
T.equal(changedState.water.status, "off", "water transition")
T.equal(#changedFacts, 4, "meaningful world transitions")

WKG.Reset({ maxFacts = 16, maxRefs = 8 })
Adapter.ResetWorldStateRuntime()
local alicePressure = Adapter.PublishZombiePressure(alice, 12, "follow", 30)
local aliceBefore = Adapter.BuildConversationContext(alice, { language = "EN" })
local bobBefore = Adapter.BuildConversationContext(bob, { language = "EN" })
T.equal(#aliceBefore.npcGossip.statements, 1, "Alice knows the pressure")
T.equal(#bobBefore.npcGossip.statements, 0, "Bob has truthful no-news")
local transferred = Adapter.PropagateConversation(alice, bob, {
    authorized = true, channel = "conversation", now = 31,
})
T.truthy(transferred and #transferred == 1, "opportunistic transfer")
local bobAfter = Adapter.BuildConversationContext(bob, { language = "EN" })
T.equal(#bobAfter.npcGossip.statements, 1, "Bob receives one grounded fact")
T.equal(bobAfter.npcGossip.factRefs[1], alicePressure.factID,
    "Bob receives the same fact")
local told = Adapter.Explain(bob, alicePressure.factID, 32)
T.equal(told.provenance, "told", "propagation provenance")
T.equal(told.sourceActorID, alice.coreActorID, "propagation source")

print("pnc_world_knowledge_smoke: PASS")
