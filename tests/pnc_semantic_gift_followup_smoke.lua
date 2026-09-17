local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = { Semantics = {} }

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueContextState.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticContextConstraints.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticContextResolver.lua"
)
local ReferenceResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueReferenceResolver.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticConsumptionCatalog.lua"
)
local TaskRequest = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTaskRequest.lua"
)

PNC.Gifts = {
    Foundation = {
        MarketSenseAdapter = {
            BuildFacts = function(fullType)
                return {
                    fullType = fullType,
                    primary = "food",
                    category = "food",
                    subcategory = "fruit",
                    leaf = "apple",
                    capabilities = {
                        edible = true,
                        consumable = true,
                    },
                    marketSenseTags = { "food", "fruit" },
                }
            end,
        },
    },
}

local store = PNC.Semantics.DialogueContextState.New({
    maxTurns = 4,
    maxMentions = 8,
    maxFocus = 4,
})
local view = { session = { semanticDialogueContext = store } }
PNC.Semantics.DialogueInput = {
    Internal = {
        RecordContextTurn = function(currentView, ir, options)
            return currentView.session.semanticDialogueContext:RecordTurn(
                ir,
                options
            )
        end,
    },
}

local GiftContext = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticGiftContext.lua"
)
T.equal(GiftContext.RecordTransfer(view, {
    npcId = "npc-alice",
    itemTypes = { "Base.Apple" },
    itemIDs = { "npc-item-42" },
}, {
    mode = "auto",
    selection = {
        fullType = "Base.Apple",
        displayName = "Apple",
        facts = PNC.Gifts.Foundation.MarketSenseAdapter.BuildFacts(
            "Base.Apple"
        ),
    },
}), true, "gift result records the authoritative item mention")

local parsed = Semantic.Parser.Parse("well, eat it")
local resolved = ReferenceResolver.Resolve(
    parsed,
    nil,
    { semanticContextState = store },
    {}
)
T.equal(resolved.action, "EAT", "follow-up keeps the compositional action")
T.equal(resolved.object.itemID, "npc-item-42",
    "follow-up resolves to the authoritative gifted item")
T.equal(resolved.object.fullType, "Base.Apple",
    "follow-up keeps the stable full type")
T.equal(resolved.object.unresolved, false,
    "resolved follow-up is no longer unresolved")

local request = TaskRequest.FromIR(resolved, {
    requestID = "eat-followup-1",
    rawText = resolved.rawText,
    npcID = "npc-alice",
})
T.truthy(request, "resolved follow-up crosses the task contract")
T.equal(request.object.itemID, "npc-item-42",
    "task contract preserves the exact gifted item ID")

PNC.Semantics.ConsumptionTaskHandler = {}
PNC.Semantics.ActionPlanService = {}
local Handler = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/SemanticConsumptionTaskHandler/PNC_SemanticConsumptionTaskHandler_Contract.lua"
)
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/SemanticConsumptionTaskHandler/PNC_SemanticConsumptionTaskHandler_Plan.lua"
)
local plan = Handler.BuildPlan(request, { npcID = "npc-alice" })
T.truthy(plan, "resolved follow-up builds a consumption plan")
T.equal(plan.steps[1].parameters.object.itemID, "npc-item-42",
    "selection step is pinned to the gifted item")
T.equal(plan.steps[2].parameters.object.itemID, "npc-item-42",
    "commit step keeps the same item identity")

local unresolvedRequest = TaskRequest.FromIR(
    Semantic.IR.New({
        rawText = "eat it",
        normalizedText = "eat it",
        intent = "REQUEST",
        speechAct = "REQUEST",
        action = "EAT",
        object = { reference = "IT", unresolved = true },
        confidence = 0.90,
    }),
    { requestID = "eat-unresolved-1", npcID = "npc-alice" }
)
local noPlan, noPlanReason = Handler.BuildPlan(
    unresolvedRequest,
    { npcID = "npc-alice" }
)
T.falsy(noPlan, "unresolved explicit references fail closed")
T.equal(noPlanReason, "item_reference_unresolved",
    "unresolved reference reason remains explicit")

T.finish("pnc_semantic_gift_followup_smoke")
