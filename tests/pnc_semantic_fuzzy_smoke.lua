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
T.load(
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

local fuzzyFollow = Parser.Parse("folow me")
T.equal(fuzzyFollow.action, "FOLLOW",
    "one missing character still recognizes a follow command")
T.equal(fuzzyFollow.diagnostics.fuzzyMatch, true,
    "fuzzy recognition is visible in diagnostics")
T.equal(fuzzyFollow.diagnostics.correctedTokens[1].matchedAlias,
    "follow me",
    "diagnostics expose the alias selected for a typo")
T.equal(fuzzyFollow.diagnostics.correctedTokens[1].editDistance, 1,
    "diagnostics expose bounded edit distance")
T.equal(fuzzyFollow.analysis.symbols[1].matchType, "fuzzy",
    "analysis identifies fuzzy concept symbols")
T.equal(fuzzyFollow.diagnostics.recommendedRoute, "deterministic",
    "a high-confidence safe typo remains local")

local transposedWait = Parser.Parse("stya here")
T.equal(transposedWait.action, "STAY",
    "adjacent transposition still recognizes a wait command")
T.equal(transposedWait.diagnostics.fuzzyMatch, true,
    "transposed wait records fuzzy recognition")

local typoGreeting = Parser.Parse("helllo there")
T.equal(typoGreeting.intent, "GREET",
    "a common greeting typo remains conversational")
T.equal(typoGreeting.diagnostics.recommendedRoute, "deterministic",
    "a greeting typo stays on the local route")

local typoWater = Parser.Parse("bring watre")
T.equal(typoWater.action, "FETCH",
    "a misspelled object is retained in the semantic request")
T.equal(typoWater.object.category, "WATER",
    "the fuzzy object resolves to the canonical concept")
T.equal(typoWater.diagnostics.fuzzyMatch, true,
    "fuzzy object recognition is diagnosable")

local state = Semantic.DialogueState.New({ participants = { "npc:mara" } })
local safeDecision = Policy.Decide(fuzzyFollow, state, {
    llmEnabled = false,
    npcID = "mara",
})
T.equal(safeDecision.branch, "COMMAND_ACCEPTED",
    "safe fuzzy movement commands can proceed locally")
T.equal(safeDecision.route, "deterministic",
    "safe fuzzy movement commands do not wait for the LLM")

local riskyDecision = Policy.Decide(typoWater, state, {
    llmEnabled = false,
    npcID = "mara",
})
T.equal(riskyDecision.branch, "ASK_CLARIFICATION",
    "fuzzy inventory requests require confirmation")
T.equal(riskyDecision.diagnostics.reason,
    "fuzzy_action_requires_confirmation",
    "fuzzy action safety policy is diagnosable")
T.equal(riskyDecision.route, "deterministic",
    "fuzzy action safety does not require an LLM")

local disabled = Parser.Parse("folow me", { enableFuzzy = false })
T.falsy(disabled.action,
    "callers can disable fuzzy matching for strict parsing")
T.equal(disabled.diagnostics.noMatch, true,
    "strict parsing retains the safe no-match result")

T.finish("pnc_semantic_fuzzy_smoke")
