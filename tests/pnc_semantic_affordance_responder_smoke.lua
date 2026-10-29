local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = { Semantics = {} }

local Responder = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticAffordanceResponder.lua"
)

local legacy = Responder.Project({
    playerName = "Patrick Patz",
    playerTraits = { Brave = true },
})
T.truthy(legacy.legacyPlayer, "legacy player projection stays explicit")
T.equal(legacy.turnSpeaker, "player", "legacy player speaker stays stable")
T.equal(legacy.name, "Patrick Patz", "legacy player name stays stable")
T.equal(legacy.visibility, "player", "legacy player visibility stays stable")
T.equal(legacy.recipient.ref, "npc", "legacy player target stays stable")
T.truthy(Responder.HasTrait({
    playerTraits = { Brave = true },
}, "Brave"), "legacy player trait lookup stays compatible")
T.equal(
    Responder.TraitReason({ playerTraits = { Brave = true } }, "Brave"),
    "player_trait:Brave",
    "legacy player trait provenance stays stable"
)

local npcContext = {
    affordanceResponder = {
        actorID = "npc-aaron",
        turnSpeaker = "npc-aaron",
        name = "Aaron Hitchcock",
        traits = { Brave = true, Kind = true },
        visibility = "semantic",
    },
    affordanceRecipientRef = "npc-percy",
}
local npc = Responder.Project(npcContext)
T.falsy(npc.legacyPlayer, "explicit responder is actor-neutral")
T.equal(npc.actorID, "npc-aaron", "NPC actor id is projected")
T.equal(npc.turnSpeaker, "npc-aaron", "NPC turn speaker is projected")
T.equal(npc.name, "Aaron Hitchcock", "NPC display name is projected")
T.equal(npc.visibility, "semantic", "NPC frontier is not player UI visibility")
T.equal(npc.recipient.ref, "npc-percy", "NPC recipient is explicit")
T.equal(
    Responder.HasAnyTrait(npcContext, { "Desensitized", "Brave" }),
    "Brave",
    "NPC traits use the same affordance gate"
)
T.equal(
    Responder.TraitReason(npcContext, "Brave"),
    "responder_trait:Brave",
    "NPC trait provenance is responder-neutral"
)
T.truthy(
    Responder.MatchesTurnSpeaker(npcContext, "npc-aaron"),
    "NPC recurrence matches its own semantic turns"
)
T.falsy(
    Responder.MatchesTurnSpeaker(npcContext, "player"),
    "NPC recurrence ignores unrelated player turns"
)

local Context = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueContextState.lua"
)
local semanticState = Context.New({ maxTurns = 5 })
semanticState:RecordTurn({
    intent = "HOSTILE_REMARK",
    speechAct = "HOSTILE_REMARK",
    extensions = {
        dynamicAffordance = {
            strategy = "DOUBLE_DOWN",
            stance = "NEGATIVE",
        },
    },
}, {
    speaker = "npc-aaron",
    source = "semantic_choice",
})

local Policy = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticAffordanceContinuationPolicy.lua"
)
local allowed, reason = Policy.Allowed("DOUBLE_DOWN", {
    semanticContextState = semanticState,
    affordanceResponder = npcContext.affordanceResponder,
})
T.falsy(allowed, "NPC cannot immediately repeat its generated strategy")
T.equal(reason, "recent_generated_strategy", "NPC recurrence uses shared reason")

semanticState:RecordTurn({
    intent = "QUESTION", speechAct = "QUESTION",
}, { speaker = "npc-aaron" })
semanticState:RecordTurn({
    intent = "ACKNOWLEDGE", speechAct = "ACKNOWLEDGE",
}, { speaker = "npc-aaron" })
allowed = Policy.Allowed("DOUBLE_DOWN", {
    semanticContextState = semanticState,
    affordanceResponder = npcContext.affordanceResponder,
})
T.truthy(allowed, "NPC strategy becomes eligible after responder turns")

T.finish("pnc_semantic_affordance_responder_smoke")
