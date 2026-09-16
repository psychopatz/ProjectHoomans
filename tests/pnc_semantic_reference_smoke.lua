local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local Resolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueReferenceResolver.lua"
)

local router = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = Resolver.Resolve,
    policy = Policy,
    context = { llmEnabled = false },
})

local first = router:Process(
    "Bring water to Sarah.",
    nil,
    { timestamp = 100 }
)
T.equal(first.accepted, true, "named fetch enters semantic state")
T.equal(first.ir.object.category, "WATER", "named fetch keeps its object")
T.equal(first.ir.target.value, "sarah", "named fetch keeps its target")
T.equal(router:Snapshot().sequence, 1, "first utterance records one event")

local followUp = router:Preview(
    "Bring it to him.",
    nil,
    { timestamp = 200 }
)
T.equal(followUp.accepted, true, "reference follow-up parses")
T.equal(followUp.ir.object.category, "WATER",
    "it resolves to the previous semantic object")
T.equal(followUp.ir.target.value, "sarah",
    "him resolves to the previous semantic target")
T.equal(followUp.ir.diagnostics.contextResolutionCount, 2,
    "both discourse references are resolved")
T.equal(followUp.ir.diagnostics.unresolvedEntity, true,
    "world entity binding remains explicit for named Sarah")
T.equal(router:Snapshot().sequence, 1,
    "preview resolves references without recording state")

local recordedFollowUp = router:Process(
    "Bring it to him.",
    nil,
    { timestamp = 300 }
)
T.equal(recordedFollowUp.accepted, true, "resolved follow-up records")
T.equal(recordedFollowUp.event.object.category, "WATER",
    "recorded follow-up stores resolved object")
T.equal(router:Snapshot().sequence, 2,
    "recorded follow-up advances state once")

local takePreview = router:Preview(
    "Take this.",
    nil,
    { timestamp = 400 }
)
T.equal(takePreview.accepted, true, "take reference parses")
T.equal(takePreview.ir.object.category, "WATER",
    "this resolves to the most recent object")
T.equal(takePreview.ir.diagnostics.unresolvedEntity, false,
    "resolved object no longer blocks deterministic handling")
T.equal(takePreview.decision.branch, "COMMAND_ACCEPTED",
    "resolved reference reaches the semantic policy")
T.equal(takePreview.decision.actionIntent.action, "TAKE",
    "resolved reference preserves the requested action")

local emptyRouter = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = Resolver.Resolve,
    policy = Policy,
    context = { llmEnabled = false },
})
local unresolved = emptyRouter:Preview(
    "Take this.",
    nil,
    { timestamp = 500 }
)
T.equal(unresolved.ir.object.reference, "THIS",
    "missing context preserves the pronoun")
T.equal(unresolved.ir.diagnostics.unresolvedEntity, true,
    "missing context remains unresolved")
T.equal(unresolved.decision.branch, "ASK_CLARIFICATION",
    "missing context asks for clarification")
T.equal(emptyRouter:Snapshot().sequence, 0,
    "unresolved preview does not mutate state")

T.finish("pnc_semantic_reference_smoke")
