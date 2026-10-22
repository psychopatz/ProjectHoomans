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
T.equal(death.payload.cause, "player", "player cause attribution")
T.truthy(death.payload.causeKnown, "player cause is authoritative")
T.truthy(WKG.ActorKnowledge.Get(WKG.KnowledgeState, bob.coreActorID,
    death.factID), "faction dissemination")
local explanation = Adapter.Explain(bob, death.factID, 12)
T.truthy(explanation, "explainability")
T.equal(explanation.provenance, "faction", "faction provenance")

local zombieDeath = Adapter.PublishDeath(alice, {
    attackerKind = "zombie", attackerZombieID = "zombie:one",
}, "combat", 12)
T.equal(zombieDeath.payload.cause, "zombie", "zombie cause attribution")
T.truthy(zombieDeath.payload.causeKnown, "zombie cause is authoritative")
local hostileDeath = Adapter.PublishDeath(alice, {
    attackerKind = "foreign_npc", attackerID = "npc:hostile",
}, "combat", 13)
T.equal(hostileDeath.payload.cause, "hostile_npc",
    "hostile NPC cause attribution")
T.truthy(hostileDeath.payload.causeKnown,
    "hostile NPC cause is authoritative")
local unknownDeath = Adapter.PublishDeath(alice, {
    attackerKind = "environment", attackerID = "unknown",
}, "combat", 14)
T.equal(unknownDeath.payload.cause, "unknown",
    "unknown cause remains unknown")
T.falsy(unknownDeath.payload.causeKnown,
    "unknown cause is not fabricated")

local treatyKinds = {
    "war_declared", "peace_made", "truce_started",
    "alliance_formed", "alliance_broken",
}
for index, treatyKind in ipairs(treatyKinds) do
    local treaty = Adapter.PublishIncident(
        "faction:one", "faction:two", treatyKind,
        { incident = { id = "incident:" .. treatyKind, severity = 0.6 } },
        20 + index
    )
    T.truthy(treaty, treatyKind .. " fact")
    T.equal(treaty.payload.incidentType, treatyKind,
        treatyKind .. " fact kind")
end
local destroyed = Adapter.PublishFactionStatus(
    "faction:one", "destroyed", "members_lost", 30)
T.truthy(destroyed, "faction destruction fact")
T.equal(destroyed.payload.status, "destroyed",
    "faction destruction status")

local publicFact = Adapter.Publish({
    producer = "hoomans:public", kind = "world.state",
    subject = { id = "world:bell", kind = "world_state" },
    eventID = "public:bell", retention = "historical", occurredAt = 31,
    observedAt = 31,
})
T.truthy(publicFact, "public fact")
T.truthy(Adapter.AcquirePublicFact(bob, publicFact.factID, {
    authorized = true, source = "public_broadcast", acquisitionPath = "public",
    learnedAt = 31,
}), "public acquisition")

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

-- The adopter owns only the ModData placement; Core still filters runtime
-- observations and actor references by retention policy.
local modData = {}
ModData = {
    getOrCreate = function(key)
        modData[key] = modData[key] or {}
        return modData[key]
    end,
    get = function(key) return modData[key] end,
}
WKG.Reset({ maxFacts = 8, maxRefs = 8 })
local historical = Adapter.Publish({
    producer = "hoomans:faction", kind = "faction.status",
    subject = { id = "faction:one", kind = "faction" },
    eventID = "faction:one:active:40", retention = "historical",
    occurredAt = 40, observedAt = 40,
})
local runtime = Adapter.Publish({
    producer = "hoomans:zombie", kind = "zombie.pressure",
    subject = { id = "npc:alice", kind = "npc" },
    eventID = "runtime:40", retention = "ephemeral",
    occurredAt = 40, observedAt = 40,
})
T.truthy(historical and runtime, "persistence fixture facts")
T.truthy(WKG.Acquire(alice.coreActorID, historical.factID, {
    authorized = true, provenance = "faction", confidence = 0.9,
    source = "faction", acquisitionPath = "faction", learnedAt = 40,
}), "historical knowledge")
T.truthy(WKG.Acquire(alice.coreActorID, runtime.factID, {
    authorized = true, provenance = "experienced", confidence = 0.9,
    source = "runtime", acquisitionPath = "runtime", learnedAt = 40,
}), "runtime knowledge")
T.truthy(Adapter.Save(), "Hoomans WKG save")
T.equal(#modData["PNC.WorldKnowledge"].ledger.facts, 1,
    "Hoomans save excludes ephemeral fact")
WKG.Reset({ maxFacts = 8, maxRefs = 8 })
T.truthy(Adapter.Load(), "Hoomans WKG load")
T.truthy(WKG.Ledger.Get(WKG.LedgerState, historical.factID),
    "historical fact reload")
T.truthy(WKG.ActorKnowledge.Get(WKG.KnowledgeState, alice.coreActorID,
    historical.factID), "historical actor reference reload")
T.falsy(WKG.Ledger.Get(WKG.LedgerState, runtime.factID),
    "ephemeral fact does not reload")
T.falsy(WKG.ActorKnowledge.Get(WKG.KnowledgeState, alice.coreActorID,
    runtime.factID), "ephemeral actor reference does not reload")

print("pnc_world_knowledge_smoke: PASS")
