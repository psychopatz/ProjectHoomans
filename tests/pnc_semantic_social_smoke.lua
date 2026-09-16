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
local ResponseCatalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)
local Parser = Semantic.Parser

T.truthy(Semantic.Registry.GetSpeechAct("INSULT"),
    "insult speech act is registered by the social catalog")
T.truthy(Semantic.Registry.GetSpeechAct("HOSTILE_REMARK"),
    "hostile remark speech act is registered by the social catalog")

local insult = Parser.Parse("fuck you")
T.equal(insult.intent, "INSULT", "directed profanity becomes an insult")
T.equal(insult.speechAct, "INSULT", "insult preserves its speech act")
T.equal(insult.subject, "RECIPIENT", "insult is directed at the recipient")
T.equal(insult.diagnostics.matchedPattern, "pnc.social.insult",
    "exact insult uses the exact social pattern")
T.equal(insult.diagnostics.recommendedRoute, "deterministic",
    "known insult stays on the local route")
T.equal(insult.emotionalState.intensity, "high",
    "insult intensity remains semantic metadata")

local censored = Parser.Parse("f*** you")
T.equal(censored.intent, "INSULT", "censored profanity is recognized locally")
T.equal(censored.diagnostics.recommendedRoute, "deterministic",
    "censored insult does not need the LLM")

local prefixed = Parser.Parse("hey, fuck you")
T.equal(prefixed.intent, "INSULT", "a short conversational prefix is allowed")
T.equal(prefixed.diagnostics.matchedPattern, "pnc.social.insult_prefixed",
    "prefixed insult uses its bounded prefix pattern")
T.truthy(prefixed.confidence >= 0.80,
    "prefixed insult remains sufficiently confident")

local profanity = Parser.Parse("shit")
T.equal(profanity.intent, "HOSTILE_REMARK",
    "standalone profanity becomes a hostile social remark")
T.equal(profanity.diagnostics.matchedPattern, "pnc.social.profanity",
    "standalone profanity uses the local profanity pattern")

local threat = Parser.Parse("I'll kill you")
T.equal(threat.intent, "THREATEN", "explicit threat remains distinct from insult")
T.equal(threat.diagnostics.matchedPattern, "pnc.social.threaten",
    "explicit threat uses the threat pattern")

local wait = Parser.Parse("stay right here")
T.equal(wait.action, "STAY", "common wait wording is vocabulary data")

local state = Semantic.DialogueState.New({ participants = { "npc:mara" } })
local decision = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara",
})
T.equal(decision.route, "deterministic",
    "local social recognition never waits for the provider")
T.equal(decision.branch, "HOSTILE_REMARK_RECEIVED",
    "insult selects a dedicated social response branch")
T.truthy(decision.response.fallback ~= "I'm not sure what you mean.",
    "recognized insult does not use generic clarification")

local withdrawn = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara-withdrawn",
    dialogueSituation = {
        social = { style = "withdrawn" },
    },
})
T.equal(withdrawn.response.templateID, "semantic.social.hostile_withdrawn",
    "hostile response can use NPC social style")

state:Record(insult, { timestamp = 100 })
local firstHostile = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara-escalation",
})
T.falsy(firstHostile.response.templateID == "semantic.social.hostile_escalated",
    "the first hostile remark does not start at the escalation branch")
state:Record(insult, { timestamp = 200 })
local escalated = Policy.Decide(insult, state, {
    llmEnabled = false,
    npcID = "mara-escalation",
})
T.equal(escalated.response.templateID, "semantic.social.hostile_escalated",
    "recent hostile remarks produce a bounded escalation response")

local first = ResponseCatalog.Select(
    "semantic.hostile_remark", { npcID = "repeat-check" }, "same-salt"
)
local second = ResponseCatalog.Select(
    "semantic.hostile_remark", { npcID = "repeat-check" }, "same-salt"
)
T.truthy(first and second, "hostile response pool remains available")
T.falsy(first.id == second.id,
    "response selection rotates instead of repeating the same variant")

local unknown = Parser.Parse("Can you do something about this?")
T.falsy(unknown.intent, "unrelated language does not become a hostile act")

T.finish("pnc_semantic_social_smoke")
