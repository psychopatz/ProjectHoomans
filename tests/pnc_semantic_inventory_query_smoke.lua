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

local casualGot = Parser.Parse("you got seafood stuffs?")
T.equal(casualGot.subject, "INVENTORY",
    "casual got question reaches inventory semantics")
T.equal(casualGot.inventoryQuery.concept, "SEAFOOD",
    "seafood stuff wording preserves the MarketSense category")

local haveYouGot = Parser.Parse("have you got any seafood?")
T.equal(haveYouGot.inventoryQuery.concept, "SEAFOOD",
    "have-you-got wording resolves the same category")

local genericGot = Parser.Parse("you got an item?")
T.equal(genericGot.inventoryQuery.concept, "ANY_ITEM",
    "generic item questions request a bounded list of carried items")

local beveragePhrase = Parser.Parse("do you have something to drink?")
T.equal(beveragePhrase.inventoryQuery.concept, "BEVERAGE",
    "drink phrases resolve to the broad beverage category")

local foodPhrase = Parser.Parse("do you have something to eat?")
T.equal(foodPhrase.inventoryQuery.concept, "FOOD",
    "eat phrases resolve to the edible food category")

local rifle = Parser.Parse("you got a rifle?")
T.equal(rifle.inventoryQuery.concept, "RIFLE",
    "specific firearm words remain specific inventory concepts")

local coffee = Parser.Parse("you got coffee?")
T.equal(coffee.inventoryQuery.concept, "COFFEE",
    "food and liquid taxonomy branches share the coffee query concept")

local fuel = Parser.Parse("you got fuel?")
T.equal(fuel.inventoryQuery.concept, "FUEL",
    "resource and liquid taxonomy branches share the fuel query concept")

local batteries = Parser.Parse("have you got any batteries?")
T.equal(batteries.inventoryQuery.concept, "BATTERY",
    "electronics leaf tags are reachable through ordinary item wording")

local melee = Parser.Parse("you got any melee weapons?")
T.equal(melee.inventoryQuery.concept, "MELEE_WEAPON",
    "weapon hierarchy branches are exposed as player-facing concepts")

local garden = Parser.Parse("do you have gardening supplies?")
T.equal(garden.inventoryQuery.concept, "GARDENING",
    "building-root gardening tags have a direct query concept")

local anyItems = Parser.Parse("do you have any items?")
T.equal(anyItems.inventoryQuery.concept, "ANY_ITEM",
    "indefinite item questions select the inventory-list concept")

local whatHave = Parser.Parse("what do you have?")
T.equal(whatHave.subject, "INVENTORY",
    "an open inventory question remains a deterministic local query")
T.equal(whatHave.inventoryQuery.concept, "ANY_ITEM",
    "open inventory questions request the bounded item list")

local whatGot = Parser.Parse("what have you got?")
T.equal(whatGot.inventoryQuery.concept, "ANY_ITEM",
    "what-have-you-got wording requests the same item list")

local giveToMe = Parser.Parse("give it to me")
T.equal(giveToMe.action, "GIVE",
    "give-it-to-me uses the existing transfer action")
T.equal(giveToMe.object.reference, "IT",
    "give-it-to-me leaves the item bound to conversation context")
T.equal(giveToMe.object.unresolved, true,
    "the transfer stays blocked until its discourse reference resolves")

T.finish("pnc_semantic_inventory_query_smoke")
