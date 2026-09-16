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
local Topics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticTopicCatalog.lua"
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

local text = "Did you hear that Sarah got bitten?"
local parsed = Semantic.Parser.Parse(text)
T.equal(parsed.intent, "GOSSIP", "gossip is a first-class speech act")
T.equal(parsed.speechAct, "GOSSIP", "gossip keeps its speech-act identity")
T.equal(parsed.target.unresolved, true,
    "gossip names remain unresolved until the entity gateway authorizes them")
T.equal(parsed.slots.information.event, "BITTEN",
    "gossip preserves the compositional event payload")
Topics.Annotate(parsed, text)
T.equal(parsed.extensions.topic.id, "gossip",
    "gossip receives its own current-topic classification")

local entityIndex = EntityResolver.BuildIndex({
    { id = "sarah", entityType = "npc", name = "Sarah" },
})
local router = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = function(ir, state, context, options)
        local output = ReferenceResolver.Resolve(ir, state, context, options)
        Topics.Annotate(output, text)
        return output
    end,
    policy = Policy,
    context = {
        llmEnabled = false,
        semanticEntityIndex = entityIndex,
    },
})

local preview = router:Preview(text)
T.equal(preview.ir.target.id, "sarah",
    "known gossip subjects resolve through the shared entity resolver")
T.equal(preview.ir.diagnostics.unresolvedEntity, false,
    "resolved gossip is safe for deterministic handling")
T.equal(preview.decision.route, "deterministic",
    "known gossip does not require the LLM")
T.equal(preview.decision.branch, "GOSSIP_RECEIVED",
    "gossip selects a semantic response branch")
T.equal(preview.decision.response.fallback,
    "I haven't heard anything about Sarah yet.",
    "local gossip response remains honest when private knowledge is absent")

T.finish("pnc_semantic_gossip_smoke")
