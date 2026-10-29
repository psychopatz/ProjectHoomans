local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)

local function fact(eventRef, phase)
    return {
        [eventRef] = {
            eventRef = eventRef,
            authoritative = true,
            disclosure = "player",
            summary = "a zombie horde was detected",
            location = { x = 10, y = 20, z = 0 },
            count = 6,
            countBand = "several",
            quantity = "6 zombies are close enough to matter.",
            hordePhase = phase,
        },
    }
end

local eventRef = "social:zombie_horde_encounter:npc-b1:1000:1"
local horde = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_encounter",
    eventID = eventRef,
    npcID = "npc-b1",
    act = "REACT",
    topic = "combat",
    context = {
        eventType = "zombie_horde_encounter",
        eventRef = eventRef,
        hordePhase = "started",
        factRefs = { eventRef },
        semanticEventFacts = fact(eventRef, "started"),
    },
}), "runtime horde event resolves")

T.equal(
    horde.responsePlanID,
    "semantic.combat.horde",
    "runtime horde event uses its dedicated semantic pool"
)
T.equal(
    horde.realizationID,
    "semantic.combat.horde.started",
    "runtime horde start selects the dedicated start realization"
)
T.equal(
    horde.fallback,
    "That's a lot of them. Stay sharp.",
    "runtime horde no longer uses the generic good-work fallback"
)
T.equal(
    #(horde.offerIDs or {}),
    3,
    "horde start carries the bounded grounded horde follow-ups"
)

local escalationRef = "social:zombie_horde_encounter:npc-b1:2000:2"
local escalation = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_encounter",
    eventID = escalationRef,
    npcID = "npc-b1",
    act = "REACT",
    topic = "combat",
    context = {
        eventType = "zombie_horde_encounter",
        eventRef = escalationRef,
        hordePhase = "escalated",
        factRefs = { escalationRef },
        semanticEventFacts = fact(escalationRef, "escalated"),
    },
}), "horde escalation resolves")
T.equal(
    escalation.realizationID,
    "semantic.combat.horde.escalated",
    "material horde escalation has dedicated wording"
)

local legacyRef = "event:b1:legacy-horde"
local legacy = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_detected",
    eventID = legacyRef,
    npcID = "npc-b1",
    act = "REACT",
    topic = "combat",
    context = {
        eventType = "zombie_horde_detected",
        eventRef = legacyRef,
        factRefs = { legacyRef },
        semanticEventFacts = fact(legacyRef),
    },
}), "legacy horde event resolves")
T.equal(
    legacy.responsePlanID,
    "semantic.combat.horde",
    "legacy horde event routes through the same dedicated horde authority"
)
T.equal(
    #(legacy.offerIDs or {}),
    3,
    "legacy horde compatibility retains grounded follow-ups"
)

T.finish("pnc_semantic_combat_banter_b0_routing_smoke")
