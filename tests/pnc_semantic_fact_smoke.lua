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
local Facts = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueFacts.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueFactSources.lua"
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

PNC.Network = {
    ClientState = {
        snapshots = {
            john = {
                id = "john",
                displayName = "John",
                presenceState = "live",
                x = 108,
                y = 106,
                z = 0,
            },
        },
    },
}

local index = EntityResolver.BuildIndex({
    {
        id = "john",
        entityType = "npc",
        name = "John",
        aliases = { "John" },
    },
    {
        id = "sarah",
        entityType = "npc",
        name = "Sarah",
        aliases = { "Sarah" },
    },
})

local function resolve(ir, state, context, options)
    local output = ReferenceResolver.Resolve(ir, state, context, options)
    return Facts.Annotate(output, state, context, options)
end

local router = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = resolve,
    policy = Policy,
    context = {
        llmEnabled = false,
        semanticEntityIndex = index,
        worldContext = {
            environment = { position = { x = 100, y = 100, z = 0 } },
        },
    },
})

local strictLocation = router:Preview("Where is John?")
T.equal(strictLocation.ir.extensions.facts.LOCATION.status, "unknown",
    "player roster visibility does not become NPC knowledge by default")
T.equal(strictLocation.decision.response.fallback,
    "I don't know where John is.",
    "unknown NPC location receives an honest local response")

local ambientRouter = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = resolve,
    policy = Policy,
    context = {
        llmEnabled = false,
        allowAmbientRosterFacts = true,
        semanticEntityIndex = index,
        worldContext = {
            environment = { position = { x = 100, y = 100, z = 0 } },
        },
    },
})

local location = ambientRouter:Preview("Where is John?")
T.equal(location.ir.extensions.facts.LOCATION.status, "known",
    "known roster position becomes a semantic fact")
T.equal(location.ir.extensions.facts.LOCATION.provider,
    "client_roster_projection",
    "location fact records its read-only provider")
T.equal(location.ir.extensions.facts.LOCATION.location.distanceBand,
    "nearby",
    "location fact is reduced to a presentation-safe distance band")
T.equal(location.decision.route, "deterministic",
    "known fact stays on the local route")
T.equal(location.decision.response.fallback, "John is nearby.",
    "local response renders the known location fact")
T.equal(router:Snapshot().sequence, 0,
    "fact preview does not mutate dialogue state")

local missing = router:Preview("Where is Sarah?")
T.equal(missing.ir.extensions.facts.LOCATION.status, "unknown",
    "missing roster position remains unknown")
T.equal(missing.decision.response.fallback, "I don't know where Sarah is.",
    "unknown location receives an honest deterministic response")
T.equal(missing.decision.route, "deterministic",
    "a recognized question does not wait on the LLM for missing facts")

local seenRouter = Semantic.DialogueRouter.New({
    stateSpec = { maxEvents = 4 },
    parser = Semantic.Parser.Parse,
    contextResolver = resolve,
    policy = Policy,
    context = {
        llmEnabled = false,
        semanticEntityIndex = index,
        semanticFactValues = {
            SEEN = {
                status = "known",
                value = true,
                targetID = "sarah",
            },
        },
    },
})
local seen = seenRouter:Preview("Did you see Sarah?")
T.equal(seen.ir.extensions.facts.SEEN.status, "known",
    "NPC cognition can provide a compact seen fact")
T.equal(seen.ir.extensions.facts.SEEN.value, true,
    "fact provider preserves a boolean semantic value")
T.equal(seen.decision.response.fallback, "Yes, I saw Sarah.",
    "seen fact uses the deterministic response layer")

T.truthy(Facts.GetProvider("context_projection"),
    "future cognition providers have a registered extension seam")

T.finish("pnc_semantic_fact_smoke")
