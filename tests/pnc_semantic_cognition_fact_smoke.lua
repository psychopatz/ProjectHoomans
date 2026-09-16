local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {
    Network = { ClientState = {} },
}

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
local Facts = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueFacts.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCognitionProjection.lua"
)
local Cognition = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticCognitionClient.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueCognitionFactSource.lua"
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

Cognition.ApplyPayload({
    projection = {
        npcID = "observer",
        revision = 1,
        facts = {
            {
                subject = "SEEN",
                targetID = "sarah",
                targetName = "Sarah",
                status = "known",
                value = true,
                source = "witnessed",
                observedAt = 10,
            },
        },
    },
})

local entityIndex = EntityResolver.BuildIndex({
    { id = "sarah", entityType = "npc", name = "Sarah" },
})
local router = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = function(ir, state, context, options)
        local output = ReferenceResolver.Resolve(ir, state, context, options)
        return Facts.Annotate(output, state, context, options)
    end,
    policy = Policy,
    context = {
        npcID = "observer",
        llmEnabled = false,
        semanticEntityIndex = entityIndex,
    },
})

local preview = router:Preview("Did you see Sarah?")
T.equal(preview.ir.extensions.facts.SEEN.status, "known",
    "NPC cognition projection becomes a semantic fact")
T.equal(preview.ir.extensions.facts.SEEN.provider,
    "client_npc_cognition_projection",
    "cognition facts identify their authoritative projection provider")
T.equal(preview.decision.route, "deterministic",
    "known NPC cognition stays on the local route")
T.equal(preview.decision.response.fallback, "Yes, I saw Sarah.",
    "local dialogue uses the NPC cognition fact")

T.finish("pnc_semantic_cognition_fact_smoke")
