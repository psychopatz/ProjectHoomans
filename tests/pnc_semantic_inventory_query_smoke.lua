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

local Parser = Semantic.Parser

local target = Parser.Parse("stay at the recycle bin")
T.equal(target.action, "WAIT_AT", "stay at object is a wait-at command")
T.equal(target.target.text, "recycle bin", "object phrase is captured intact")
T.equal(target.target.unresolved, true,
    "world-object names remain resolver-owned")
T.truthy(target.confidence >= 0.85,
    "a bounded object phrase remains actionable")

local seafood = Parser.Parse("do you have seafoods?")
T.equal(seafood.intent, "QUESTION", "inventory query is a question")
T.equal(seafood.subject, "INVENTORY", "inventory query subject")
T.equal(seafood.inventoryQuery.concept, "SEAFOOD",
    "seafood maps to a compositional item concept")
T.equal(seafood.inventoryQuery.mode, "LIST", "query asks for a list")
T.equal(seafood.diagnostics.recommendedRoute, "deterministic",
    "known inventory categories stay local")

local typo = Parser.Parse("do you have seefoods?")
T.equal(typo.subject, "INVENTORY", "small item typo remains understandable")
T.equal(typo.inventoryQuery.concept, "SEAFOOD",
    "fuzzy item vocabulary maps to the same concept")
T.truthy(typo.diagnostics.fuzzyMatch, "typo is observable as fuzzy")

local optionalKind = Parser.Parse("do you have any kind of seafood?")
T.equal(optionalKind.subject, "INVENTORY",
    "optional inventory wording remains semantic")
T.equal(optionalKind.inventoryQuery.concept, "SEAFOOD",
    "optional inventory wording preserves seafood category")

T.finish("pnc_semantic_inventory_query_smoke")
