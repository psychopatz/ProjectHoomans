local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local Plan = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan.lua"
)

local ok, single = Plan.Build({
    dialogueAct = "WELLBEING_ACKNOWLEDGE",
    sourcePoolID = "semantic.question.wellbeing",
    segments = {
        {
            kind = "translation",
            templateID = "semantic.wellbeing.greeting",
            fallback = "I'm glad to hear it.",
            args = { npcName = "Mara" },
        },
        { kind = "literal", text = "Thanks for telling me." },
    },
})
T.equal(ok, true, "response plan accepts typed translation and literal segments")
T.equal(single.kind, "dialogue_act_plan",
    "response plan exposes a stable typed schema")
T.equal(single.sourcePoolID, "semantic.question.wellbeing",
    "response plan retains the contextual response pool owner")
T.equal(#single.turns[1].segments, 2,
    "response plan keeps bounded multi-part composition")

local firstText = Plan.Render(single, function(templateID, fallback, args)
    return fallback .. " " .. tostring(args.npcName or templateID)
end)
T.equal(firstText, "I'm glad to hear it. Mara Thanks for telling me.",
    "response plan renders localized and literal segments in order")
local detailed = Plan.RenderDetailed(single, function(templateID, fallback, args)
    return fallback .. " " .. tostring(args.npcName or templateID),
        "UI_Test_ResponsePlan"
end, 1)
T.equal(detailed.text, firstText,
    "response plan detailed rendering preserves composed text")
T.equal(#detailed.segments, 2,
    "response plan detailed rendering exposes every segment")
T.equal(detailed.translationKeys[1], "UI_Test_ResponsePlan",
    "response plan detailed rendering preserves translation provenance")

local secondOK, second = Plan.Build({
    dialogueAct = "WELLBEING_FOLLOWUP",
    turns = {
        {
            continuation = "await_player",
            segments = {
                {
                    kind = "translation",
                    templateID = "semantic.wellbeing.followup",
                    fallback = "How are you holding up?",
                },
            },
        },
    },
})
T.equal(secondOK, true, "response plan accepts a bounded continuation turn")

local composedOK, composed = Plan.Compose(single, second)
T.equal(composedOK, true, "response plans compose without branch-specific logic")
T.equal(#composed.turns, 2,
    "composed response plan retains both conversational turns")
T.equal(composed.turns[2].continuation, "await_player",
    "composed plan preserves the next-turn contract")

local renderedTurns = Plan.RenderTurns(composed)
T.equal(#renderedTurns, 2,
    "composed plans render every bounded turn")
T.equal(renderedTurns[2], "How are you holding up?",
    "fallback rendering remains available without a translation provider")

local response = {
    templateID = "semantic.greet.acknowledged",
    fallback = "Hey there.",
}
T.equal(Plan.Attach(response, "GREET_ACKNOWLEDGED"), response,
    "response plan attaches at the shared response boundary")
T.truthy(response.plan, "response carries its composable plan")
T.equal(response.plan.turns[1].segments[1].templateID,
    response.templateID,
    "attached plan preserves the stable response ID")

local invalid, invalidReason = Plan.Build({
    dialogueAct = "BROKEN",
    segments = {
        { kind = "unsupported", text = "no" },
    },
})
T.falsy(invalid, "response plan rejects unsupported segment kinds")
T.equal(invalidReason, "response_plan_segment_kind_unsupported:unsupported",
    "response plan reports the unsupported segment kind")

T.finish("pnc_semantic_dialogue_response_plan_smoke")
