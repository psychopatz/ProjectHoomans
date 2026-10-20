local T = require "tests/support/test"

T.load("tests/pnc_npc_foundation_parity_baseline_smoke.lua")
local Actors = require "PsychopatzCore/Actors/PsychopatzActors"
local CoreKnowledge = PNC.Persistence.CoreKnowledge
T.truthy(CoreKnowledge, "Core Knowledge adapter was not loaded")

local notes = {
    ["char:alice"] = {
        revision = 4,
        discovered = {
            ["history.backstory.hometown"] = {
                status = "confirmed",
                value = "backstory.shared.hometown.rosewood",
                confidence = 1,
                discoveredAt = 10,
                lastUpdatedAt = 12,
                primarySource = "direct_disclosure",
                revision = 2,
            },
        },
        evidence = {
            {
                id = "evidence:alice:hometown",
                descriptorID = "history.backstory.hometown",
                sourceType = "direct_disclosure",
                direction = 1,
                strength = 1,
                reliability = 1,
                createdAt = 12,
                sourceEventID = "conversation:alice:one",
                payload = { observedValue = "backstory.shared.hometown.rosewood" },
                tags = { disclosure = true },
            },
        },
    },
    ["char:bob"] = {
        revision = 2,
        discovered = {
            ["history.backstory.hometown"] = {
                status = "suspected",
                value = "backstory.shared.hometown.muldraugh",
                confidence = 0.3,
                discoveredAt = 13,
                lastUpdatedAt = 13,
                primarySource = "rumor",
                revision = 1,
            },
        },
        evidence = {
            {
                id = "evidence:bob:hometown",
                descriptorID = "history.backstory.hometown",
                sourceType = "rumor",
                direction = -1,
                strength = 0.3,
                reliability = 0.3,
                createdAt = 13,
                payload = { observedValue = "backstory.shared.hometown.muldraugh" },
            },
        },
    },
}

PNC.NPCKnowledge = {
    Registry = {
        revision = 8,
        byCharacter = {
            ["char:alice"] = { byNPC = { ["npc:portable:one"] = true } },
            ["char:bob"] = { byNPC = { ["npc:portable:one"] = true } },
        },
    },
    EnsureLoaded = function() return true end,
    Get = function(characterUUID, npcID)
        if npcID ~= "npc:portable:one" then return nil end
        return notes[characterUUID]
    end,
}

local all, allReason = CoreKnowledge.BuildForNPC(
    PsychopatzCore, "npc:portable:one")
T.truthy(all, allReason)
T.equal(all.byPlayer["player:char:alice"].facts
    ["history.backstory.hometown"].status,
    "confirmed", "Alice status imported")
T.equal(all.byPlayer["player:char:bob"].facts
    ["history.backstory.hometown"].status,
    "suspected", "Bob status imported")
T.equal(all.byPlayer["player:char:alice"].facts
    ["history.backstory.hometown"].evidence[1].sourceEventID,
    "conversation:alice:one", "evidence identity imported")
T.equal(all.byPlayer["player:char:alice"].facts
    ["history.backstory.hometown"].evidence[1].tags.disclosure,
    true, "evidence tags imported")

local one, oneReason = CoreKnowledge.BuildForPlayer(
    PsychopatzCore, "char:alice", "npc:portable:one")
T.truthy(one, oneReason)
T.falsy(one.byPlayer["player:char:bob"],
    "player-scoped bridge leaked another character's facts")

local registry = Actors.NewRegistry()
local actor, actorReason = registry:Create({
    actorId = "npc:portable:one",
    identitySeed = "portable-hoomans-seed",
    starterItems = {},
    knowledge = all,
})
T.truthy(actor, actorReason)
T.equal(actor.knowledge.byPlayer["player:char:alice"].facts
    ["history.backstory.hometown"].value,
    "backstory.shared.hometown.rosewood", "Core actor Knowledge value")
T.falsy(actor.knowledge.biography,
    "portable bridge stored a biography paragraph")

local unauthorized, unauthorizedReason = CoreKnowledge.CommitForPlayer(
    PsychopatzCore, registry, actor.actorId, "char:alice",
    "npc:portable:one", "client", actor.revision)
T.equal(unauthorized, nil, "client Core Knowledge import rejected")
T.equal(unauthorizedReason, "server_authority_required",
    "Core Knowledge import authority")

local imported, importReason = CoreKnowledge.CommitForPlayer(
    PsychopatzCore, registry, actor.actorId, "char:alice",
    "npc:portable:one", "server", actor.revision)
T.truthy(imported, importReason)
T.truthy(imported.knowledge.byPlayer["player:char:alice"],
    "server Core Knowledge import missing player")
T.falsy(imported.knowledge.byPlayer["player:char:bob"],
    "single-player Core Knowledge import leaked another player")

local saved = registry:Save()
T.truthy(saved, "Core Knowledge import save")
local fresh = Actors.NewRegistry()
T.truthy(fresh:Load(saved), "Core Knowledge import reload")
local restored = fresh:Get(actor.actorId)
T.equal(restored.knowledge.byPlayer["player:char:alice"].facts
    ["history.backstory.hometown"].value,
    "backstory.shared.hometown.rosewood",
    "server-imported Core Knowledge value did not reload")

local valid, validReason = Actors.Knowledge.Validate(actor.knowledge)
T.truthy(valid, validReason)
T.finish("pnc_npc_foundation_core_knowledge_adapter_smoke")
