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
local EntityResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticEntityResolver.lua"
)
local ReferenceResolver = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueReferenceResolver.lua"
)

local index = EntityResolver.BuildIndex({
    {
        id = "npc:sarah",
        entityType = "npc",
        name = "Sarah Connor",
        aliases = { "Sarah", "Sarah Connor" },
    },
    {
        id = "npc:alex-one",
        entityType = "npc",
        name = "Alex One",
        aliases = { "Alex" },
    },
    {
        id = "npc:alex-two",
        entityType = "npc",
        name = "Alex Two",
        aliases = { "Alex" },
    },
    {
        id = "npc:hidden",
        entityType = "npc",
        name = "Hidden Survivor",
        aliases = { "Hidden" },
        known = false,
    },
})

local router = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = ReferenceResolver.Resolve,
    policy = Policy,
    context = {
        llmEnabled = false,
        semanticEntityIndex = index,
    },
})

local named = router:Preview("Help Sarah")
T.equal(named.ir.target.id, "npc:sarah",
    "known name binds to a stable NPC identity")
T.equal(named.ir.target.unresolved, false,
    "known name is no longer unresolved")
T.equal(named.ir.diagnostics.entityResolutionCount, 1,
    "entity resolver reports one resolved target")
T.equal(named.decision.branch, "COMMAND_ACCEPTED",
    "known entity reaches deterministic policy")

local ambiguous = router:Preview("Help Alex")
T.equal(ambiguous.ir.target.unresolved, true,
    "ambiguous name is not guessed")
T.equal(ambiguous.ir.diagnostics.entityResolutionFailures[1].reason,
    "ambiguous_entity", "ambiguity is diagnosable")
T.equal(ambiguous.decision.branch, "ASK_CLARIFICATION",
    "ambiguous name asks for clarification")

local unknown = router:Preview("Help Jordan")
T.equal(unknown.ir.target.unresolved, true,
    "unknown name remains unresolved")
T.equal(unknown.ir.diagnostics.entityResolutionFailures[1].reason,
    "unknown_entity", "unknown name is diagnosable")

local hidden = router:Preview("Help Hidden")
T.equal(hidden.ir.target.unresolved, true,
    "unauthorized identity is not exposed by the index")

local stateful = router:Process(
    "Bring water to Sarah.",
    nil,
    { timestamp = 100 }
)
T.equal(stateful.ir.target.id, "npc:sarah",
    "resolved target is retained in bounded event state")

local followUp = router:Preview(
    "Bring it to him.",
    nil,
    { timestamp = 200 }
)
T.equal(followUp.ir.object.category, "WATER",
    "context resolves the follow-up object")
T.equal(followUp.ir.target.id, "npc:sarah",
    "context resolves the follow-up person")
T.equal(followUp.ir.diagnostics.unresolvedEntity, false,
    "fully resolved follow-up has no unresolved entities")
T.equal(followUp.ir.confidenceBand, "high",
    "context resolution restores confidence lost to pronouns")

T.finish("pnc_semantic_entity_resolution_smoke")
