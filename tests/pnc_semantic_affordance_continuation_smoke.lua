local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

PNC = { Semantics = {} }
local Context = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueContextState.lua"
)
local context = Context.New({ maxTurns = 3 })
local ok = context:RecordTurn({
    intent = "HOSTILE_REMARK",
    speechAct = "HOSTILE_REMARK",
    extensions = {
        dynamicAffordance = {
            strategy = "DOUBLE_DOWN",
            stance = "NEGATIVE",
        },
    },
}, {
    speaker = "player",
    source = "semantic_click",
})
T.truthy(ok, "generated semantic turn recorded")
local turns = context:RecentTurns(3, true)
T.equal(turns[1].strategy, "DOUBLE_DOWN", "strategy stays in session turn")
T.equal(turns[1].stance, "NEGATIVE", "stance stays in session turn")

local Policy = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/SemanticDialogueSuggestions/PNC_SemanticAffordanceContinuationPolicy.lua"
)
local allowed, reason = Policy.Allowed("DOUBLE_DOWN", {
    semanticContextState = context,
})
T.falsy(allowed, "immediate double-down button is suppressed")
T.equal(reason, "recent_generated_strategy", "suppression reason")

context:RecordTurn({
    intent = "QUESTION", speechAct = "QUESTION",
}, { speaker = "player" })
context:RecordTurn({
    intent = "ACKNOWLEDGE", speechAct = "ACKNOWLEDGE",
}, { speaker = "player" })
allowed = Policy.Allowed("DOUBLE_DOWN", {
    semanticContextState = context,
})
T.truthy(allowed, "strategy becomes eligible after bounded player turns")
T.equal(#context:RecentTurns(10, true), 3, "session history remains bounded")

T.finish("pnc_semantic_affordance_continuation_smoke")
