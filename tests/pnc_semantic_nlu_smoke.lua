local T = require "tests/support/test"
T.addPackagePaths()

-- The semantic parser must boot without a bridge, LLM provider, game actor,
-- or gameplay service. This test deliberately supplies only the Core table.
PsychopatzCore = {}
PNC = {}

local Semantic = T.load(
    "PsychopatzCore",
    "common",
    "PsychopatzCore/Semantics/PsychopatzSemantic.lua"
)
local Catalog = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticCatalog.lua"
)
local Parser = Semantic.Parser
local IR = Semantic.IR

local follow = Parser.Parse("Follow me.")
T.equal(follow.intent, "REQUEST", "follow intent")
T.equal(follow.action, "FOLLOW", "follow action")
T.equal(follow.diagnostics.recommendedRoute, "deterministic",
    "high-confidence commands stay in Lua")
T.truthy(follow.confidence >= 0.90, "follow confidence")

local synonym = Parser.Parse("Come with me!")
T.equal(synonym.action, "FOLLOW", "follow synonym")
T.equal(synonym.diagnostics.matchedPattern, "pnc.command.follow",
    "synonyms use the same semantic pattern")

local greeting = Parser.Parse("hello there")
T.equal(greeting.intent, "GREET", "greeting intent")
T.equal(greeting.speechAct, "GREET", "greeting speech act")
T.equal(greeting.diagnostics.matchedPattern, "pnc.social.greet",
    "greeting uses the local social pattern")
T.equal(greeting.diagnostics.recommendedRoute, "deterministic",
    "greetings never require the optional LLM")

local waitHere = Parser.Parse("Wait here.")
T.equal(waitHere.action, "STAY", "wait maps to existing stay semantics")

local goHome = Parser.Parse("Go home.")
T.equal(goHome.action, "GO", "go home action")
T.equal(goHome.destination.category, "HOME", "go home destination")

local water = Parser.Parse("Can you bring me some water?")
T.equal(water.intent, "REQUEST", "water request intent")
T.equal(water.action, "FETCH", "water request action")
T.equal(water.object.category, "WATER", "water request object")
T.equal(water.object.quantity, "SOME", "water request quantity")
T.equal(water.diagnostics.recommendedRoute, "deterministic",
    "common fetch request stays in Lua")

local food = Parser.Parse("Get some food")
T.equal(food.object.category, "FOOD", "food synonym object")

local medicine = Parser.Parse("Bring me meds")
T.equal(medicine.object.category, "MEDICINE",
    "new concepts are vocabulary registrations")

local inventoryWhat = Parser.Parse("What kind of seafood do you have?")
T.equal(inventoryWhat.subject, "INVENTORY",
    "what-kind inventory questions are semantic questions")
T.equal(inventoryWhat.inventoryQuery.concept, "SEAFOOD",
    "what-kind inventory questions preserve the concept")

local unknownItem = Parser.Parse("Bring me an apple")
T.equal(unknownItem.action, "FETCH",
    "fetch accepts an item name outside the core vocabulary")
T.equal(unknownItem.object.text, "apple",
    "unknown item text remains available to the item selector")
T.equal(unknownItem.object.unresolved, true,
    "unknown fetch objects remain explicitly unresolved")

local compoundItem = Parser.Parse("Bring me some medical supplies")
T.equal(compoundItem.action, "FETCH",
    "fetch accepts bounded compound item names")
T.equal(compoundItem.object.text, "medical supplies",
    "compound item text remains intact for MarketSense selection")

local negated = Parser.Parse("Don't go")
T.equal(negated.action, "GO", "negated command action")
T.equal(negated.modifiers.negated, true, "negation is semantic metadata")

local question = Parser.Parse("Where is John?")
T.equal(question.intent, "QUESTION", "question intent")
T.equal(question.subject, "LOCATION", "question subject")
T.equal(question.target.text, "john", "unresolved target is preserved")
T.equal(question.target.unresolved, true, "world resolution stays downstream")

local unknown = Parser.Parse("Can you do something about this?")
T.falsy(unknown.intent, "unknown language has no invented intent")
T.truthy(unknown.confidence < 0.60, "unknown language is low confidence")
T.equal(unknown.diagnostics.recommendedRoute, "llm_fallback",
    "low confidence recommends optional LLM fallback")
T.equal(unknown.diagnostics.noMatch, true, "unknown language is diagnosable")

local valid, reason = IR.Validate(water)
T.equal(valid, true, "semantic IR validates")
T.equal(reason, nil, "valid IR has no validation reason")
T.equal(Catalog.registered, true, "domain catalog loaded")
T.truthy(Semantic.Registry.GetSpeechAct("GOSSIP"),
    "speech acts are extensible registry metadata")

T.finish("pnc_semantic_nlu_smoke")
