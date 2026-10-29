local T = require "tests/support/test"
T.addPackagePaths()

PNC = {
    Semantics = {
        CombatReactionProfile = {
            Build = function(record)
                return {
                    combatReactionStyle = record and record.style
                        or "practical",
                    combatReactionMood = "steady",
                }
            end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Speech = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCompanionSpeech.lua"
)

local eager = T.truthy(Speech.ResolveNPCCommand(
    "combat_engage",
    "valid",
    { npcID = "npc-eager", npcRecord = { style = "brave" } }
), "eager combat acknowledgement resolves")
T.equal(eager.realizationID, "semantic.combat.horde.ack.engage_eager",
    "brave/aggressive engage uses eager acknowledgement")
T.equal(eager.fallback, "Fuck yeah. Let's go.",
    "eager engage has active combat wording")

local hesitant = T.truthy(Speech.ResolveNPCCommand(
    "combat_engage",
    "valid",
    { npcID = "npc-shaken", npcRecord = { style = "shaken" } }
), "hesitant combat acknowledgement resolves")
T.equal(hesitant.realizationID,
    "semantic.combat.horde.ack.engage_hesitant",
    "shaken engage uses hesitant acknowledgement")
T.equal(hesitant.fallback, "Fuck... alright. I'm with you.",
    "hesitant engage uses reluctant profanity rather than enthusiasm")

local avoid = T.truthy(Speech.ResolveNPCCommand(
    "combat_avoid",
    "valid",
    { npcID = "npc-supportive", npcRecord = { style = "supportive" } }
), "avoid acknowledgement resolves")
T.equal(avoid.realizationID, "semantic.combat.horde.ack.avoid_relief",
    "supportive/shaken avoid can sound relieved")

local hold = T.truthy(Speech.ResolveNPCCommand(
    "combat_hold",
    "valid",
    { npcID = "npc-brave", npcRecord = { style = "brave" } }
), "hold acknowledgement resolves")
T.equal(hold.realizationID, "semantic.combat.horde.ack.hold_eager",
    "brave hold sounds ready rather than frightened")

local rejected = T.truthy(Speech.ResolveNPCCommand(
    "combat_engage",
    "invalid",
    { npcID = "npc-eager", npcRecord = { style = "brave" } }
), "rejected tactical command still resolves a safe reply")
T.equal(rejected.realizationID, "semantic.command.reply.generic_rejected",
    "rejected/stale tactical command never uses a success boast")

local ordinary = T.truthy(Speech.ResolveNPCCommand(
    "follow",
    "valid",
    { npcID = "npc-ordinary" }
), "ordinary companion acknowledgement still resolves")
T.equal(ordinary.realizationID, "semantic.command.reply.follow",
    "ordinary command reply path remains unchanged")

T.finish("pnc_semantic_horde_command_ack_smoke")
