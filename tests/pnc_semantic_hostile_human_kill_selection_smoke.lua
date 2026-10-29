local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Reactions = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticSocialReaction.lua"
)

local function resolve(style, salt)
    local eventRef = "event:human-kill:" .. style .. ":" .. salt
    return T.truthy(Reactions.Resolve({
        eventType = "hostile_npc_kill_self",
        eventID = eventRef,
        npcID = "npc-killer",
        act = "REACT",
        topic = "combat",
        context = {
            eventType = "hostile_npc_kill_self",
            eventRef = eventRef,
            combatReactionRole = "killer",
            combatReactionStyle = style,
            combatReactionMood = style == "shaken" and "shaken" or "steady",
            combatWeaponFamily = "long_blade",
            combatHitZone = "head_neck",
            factRefs = { eventRef },
            semanticEventFacts = {
                [eventRef] = {
                    eventRef = eventRef,
                    authoritative = true,
                    disclosure = "player",
                    summary = "the NPC killed a hostile survivor nearby",
                    happened = "the NPC killed a hostile survivor nearby",
                    health = "I'm okay.",
                    nextAction = "Check the area.",
                },
            },
        },
    }), "human kill semantic family resolves")
end

for _, style in ipairs({
    "aggressive", "supportive", "shaken", "brave",
    "reserved", "cold", "practical",
}) do
    local result = resolve(style, "one")
    T.equal(result.responsePlanID, "semantic.combat.human_kill." .. style,
        style .. " human kill uses distinct human pool")
    T.contains(result.realizationID,
        "semantic.combat.human_kill." .. style .. ".line_",
        style .. " human kill uses human-only realization")
    T.equal(#(result.offerIDs or {}), 3,
        "human kill exposes happened/health/next only")
    local lower = string.lower(result.fallback)
    T.falsy(string.find(lower, "zombie", 1, true),
        "human kill wording never calls the victim a zombie")
    T.falsy(string.find(lower, "molar", 1, true),
        "human kill wording cannot reuse zombie molar gore")
    T.falsy(string.find(lower, "teeth", 1, true),
        "human kill wording cannot reuse zombie teeth gore")
end

local zombieRef = "event:zombie-kill:distinct"
local zombie = T.truthy(Reactions.Resolve({
    eventType = "zombie_kill_self",
    eventID = zombieRef,
    npcID = "npc-killer",
    act = "REACT",
    topic = "combat",
    context = {
        eventType = "zombie_kill_self",
        eventRef = zombieRef,
        combatReactionRole = "killer",
        combatReactionStyle = "aggressive",
        combatWeaponFamily = "long_blade",
        combatHitZone = "head_neck",
        factRefs = { zombieRef },
        semanticEventFacts = {
            [zombieRef] = {
                eventRef = zombieRef,
                authoritative = true,
                disclosure = "player",
                summary = "the NPC killed a zombie nearby",
            },
        },
    },
}), "zombie kill still resolves")
T.equal(zombie.responsePlanID, "semantic.combat.kill.killer.aggressive",
    "zombie kill remains in zombie-specific semantic pool")
T.truthy(zombie.responsePlanID
    ~= "semantic.combat.human_kill.aggressive",
    "zombie and hostile-human kill families cannot alias")

T.finish("pnc_semantic_hostile_human_kill_selection_smoke")
