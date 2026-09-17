local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Identity/PNC_Identity.lua"
)
local Identity = PNC.Identity
T.truthy(Identity and Identity.Float, "identity seed API is available")

local Contract = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Gifts/PNC_GiftContract.lua"
)
local Adapter = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Gifts/PNC_GiftMarketSenseAdapter.lua"
)
local Profile = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Gifts/PNC_GiftPreferenceProfile.lua"
)
local Evaluator = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Gifts/PNC_GiftEvaluator.lua"
)
local Runtime = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Gifts/PNC_GiftRuntimeEvaluator.lua"
)

local instanceCalls = 0
local definitionCalls = 0
local api = {
    GetPriceDetailsForInstance = function(fullType, item)
        instanceCalls = instanceCalls + 1
        return {
            primary = "Food",
            category = "Food",
            subcategory = "Fruit",
            leaf = "Apple",
            tags = { "Food", "FoodFruit" },
            expandedTags = { "Food.Fruit", "Food.Fruit.Apple" },
            price = item and item.instancePrice or 12,
            priceHeuristic = { role = "edible" },
        }
    end,
    GetPriceDetails = function(fullType)
        definitionCalls = definitionCalls + 1
        return {
            primary = "Food",
            category = "Food",
            subcategory = "Fruit",
            leaf = "Apple",
            tags = { "Food", "FoodFruit" },
            expandedTags = { "Food.Fruit", "Food.Fruit.Apple" },
            price = 10,
            priceHeuristic = { role = "edible" },
        }
    end,
    GetTags = function(fullType)
        return {
            primary = "Food",
            category = "Food",
            tags = { "Food", "FoodFruit" },
            expandedTags = { "Food.Fruit", "Food.Fruit.Apple" },
        }
    end,
}

local apple = Adapter.BuildFacts("Base.Apple", {
    instancePrice = 14,
}, { api = api })
T.equal(instanceCalls, 1,
    "concrete inventory gifts use MarketSense instance pricing")
T.equal(definitionCalls, 0,
    "instance pricing does not fall back to definition pricing")
T.equal(apple.subcategoryKey, "fruit",
    "MarketSense subcategory is retained as a preference key")
T.equal(apple.leafKey, "apple",
    "MarketSense leaf is retained as a preference key")
T.equal(apple.price, 14,
    "instance price is retained in gift facts")
T.truthy(apple.tagSet.foodfruit,
    "MarketSense taxonomy tags are indexed in gift facts")
T.equal(apple.capabilities.edible, true,
    "gift facts reuse the MarketSense semantic edible capability")

local definitionApple = Adapter.BuildFacts("Base.Apple", nil, { api = api })
T.equal(definitionCalls, 1,
    "definition gift facts use the MarketSense definition path")
T.equal(definitionApple.priceSource, "definition",
    "definition facts retain their pricing source")

MarketSense = api
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Conversation/PNC_ConversationGifts.lua"
)
T.equal(PNC.Gifts.IsValidItemType("Base.Apple"), true,
    "MarketSense-backed items are valid gifts even without item-name substrings")
T.equal(PNC.Gifts.GetItemScore("Base.Apple").marketSense, true,
    "legacy gift entry points can consume MarketSense facts")

local runtimeEvaluation = Runtime.Evaluate({
    id = "npc-1",
    identitySeed = 4242,
    archetypeID = "General",
}, { "Base.Apple" })
local runtimeRepeat = Runtime.Evaluate({
    id = "npc-1",
    identitySeed = 4242,
    archetypeID = "General",
}, { "Base.Apple" })
T.truthy(runtimeEvaluation,
    "authoritative gift bridge evaluates MarketSense-backed gifts")
T.equal(runtimeEvaluation.disposition, runtimeRepeat.disposition,
    "authoritative bridge remains deterministic for one identity seed")
T.truthy(runtimeEvaluation.diagnostics[1],
    "authoritative bridge retains bounded evaluation diagnostics")

local seafood = Adapter.BuildFactsFromDetails("Base.Sardine", {
    primary = "Food",
    category = "Food",
    subcategory = "Seafood",
    leaf = "Sardine",
    tags = { "Food", "FoodSeafood" },
    expandedTags = { "Food.Seafood", "Food.Seafood.Fish" },
    price = 22,
}, { priceSource = "provided" })
T.equal(seafood.subcategoryKey, "seafood",
    "rich MarketSense subcategories are not collapsed to generic food")

local authored = Profile.New(12345, "General", {
    favoriteSubcategories = { "fruit" },
    hatedSubcategories = { "seafood" },
})
local favorite = Profile.Resolve(authored, apple)
local hated = Profile.Resolve(authored, seafood)
T.equal(favorite.disposition, "favorite",
    "authored favorite subcategories override generated preference")
T.equal(hated.disposition, "hated",
    "authored hated tags override generated preference")
T.equal(favorite.reason, "authored_override",
    "preference diagnostics identify authored overrides")

local generatedA = Profile.New(777, "General")
local generatedB = Profile.New(777, "General")
local first = Profile.Resolve(generatedA, apple)
local second = Profile.Resolve(generatedB, apple)
T.equal(first.disposition, second.disposition,
    "same identity seed produces stable gift disposition")
T.equal(first.matchKey, second.matchKey,
    "same identity seed produces stable taxonomy match")
T.falsy(generatedA.itemPreferences,
    "generated preferences do not allocate an item preference map")
T.falsy(generatedA.preferences,
    "generated preferences are not stored as a persistent preference table")
T.equal(generatedA.identitySeed, Identity.NormalizeSeed(777, "General"),
    "runtime preference profile reuses the existing identity seed")

local bundle = Evaluator.Evaluate({
    { itemID = "apple-1", quantity = 4, facts = apple },
    { itemID = "fish-1", quantity = 1, facts = seafood },
}, authored, {
    personality = { materialism = 0.75 },
    needMultipliers = { fruit = 1.2 },
})
T.equal(bundle.accepted, true, "non-empty gift bundle is evaluable")
T.equal(bundle.totalQuantity, 5, "bundle quantity is aggregated")
T.near(bundle.totalPrice, 78, 0.0001,
    "bundle price uses MarketSense value times quantity")
T.equal(#bundle.breakdown, 2, "bundle retains an explainable breakdown")
T.truthy(bundle.relationshipEffect,
    "evaluator returns a relationship effect without applying it")
T.contains(bundle.diagnostics[1].detail, "identity seed",
    "evaluation explains that preference state is seed-derived")

local oneApple = Evaluator.Evaluate({
    { quantity = 1, facts = apple },
}, authored)
local fourApples = Evaluator.Evaluate({
    { quantity = 4, facts = apple },
}, authored)
T.truthy(fourApples.score < oneApple.score * 4,
    "bundle quantity uses diminishing returns")

local empty = Evaluator.Evaluate({}, authored)
T.equal(empty.accepted, false, "empty gift bundle is rejected by evaluation")
T.equal(empty.totalQuantity, 0, "empty bundle keeps a zero quantity")
T.equal(empty.status, "empty", "empty bundle exposes a safe status")

T.finish("pnc_gift_foundation_smoke")
