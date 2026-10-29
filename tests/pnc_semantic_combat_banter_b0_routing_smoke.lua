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

local function fact(eventRef)
    return {
        [eventRef] = {
            eventRef = eventRef,
            authoritative = true,
            disclosure = "player",
            summary = "a zombie horde was detected",
            location = { x = 10, y = 20, z = 0 },
            countBand = "several",
        },
    }
end

local eventRef = "social:zombie_horde_encounter:npc-b0:1000:1"
local horde = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_encounter",
    eventID = eventRef,
    npcID = "npc-b0",
    act = "REACT",
    topic = "combat",
    context = {
        eventType = "zombie_horde_encounter",
        eventRef = eventRef,
        factRefs = { eventRef },
        semanticEventFacts = fact(eventRef),
    },
}), "production horde event resolves")

T.equal(
    horde.responsePlanID,
    "semantic.combat.reaction",
    "horde event reaches the generic combat pool"
)
T.equal(
    horde.realizationID,
    "semantic.combat.reaction.default",
    "B0 regression: runtime horde event falls through to generic default"
)
T.equal(
    horde.fallback,
    "Good work. Keep watching the area.",
    "B0 regression reproduces the live wrong horde line"
)
T.equal(
    #(horde.offerIDs or {}),
    1,
    "generic fallback exposes only the generic combat follow-up"
)

local legacy = T.truthy(Reactions.Resolve({
    eventType = "zombie_horde_detected",
    eventID = "event:b0:legacy-horde",
    npcID = "npc-b0",
    act = "REACT",
    topic = "combat",
    context = {
        eventType = "zombie_horde_detected",
        eventRef = "event:b0:legacy-horde",
        factRefs = { "event:b0:legacy-horde" },
        semanticEventFacts = fact("event:b0:legacy-horde"),
    },
}), "legacy horde event resolves")
T.equal(
    legacy.realizationID,
    "semantic.combat.reaction.threat",
    "dedicated horde branch currently recognizes the older event name"
)
T.equal(
    #(legacy.offerIDs or {}),
    3,
    "dedicated horde branch carries the intended grounded follow-ups"
)

T.finish("pnc_semantic_combat_banter_b0_routing_smoke")
