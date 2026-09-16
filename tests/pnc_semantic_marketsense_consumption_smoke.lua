local T = require "tests/support/test"
T.addPackagePaths()

MarketSense = {
    GetPriceDetails = function(fullType)
        if fullType == "Base.Apple" then
            return {
                primary = "Food",
                tags = { "Food", "FoodFruits" },
                expandedTags = { "Food.Fruits" },
                priceHeuristic = { role = "edible" },
            }
        end
        if fullType == "Base.WaterBottle" then
            return {
                primary = "Food",
                tags = { "Beverage", "BeverageWater", "LiquidWater" },
                expandedTags = { "Food.Beverage", "Liquid.Water" },
                priceHeuristic = { role = "edible" },
            }
        end
        if fullType == "Base.EmptyBottle" then
            return {
                primary = "Container",
                tags = { "Container", "ContainerLiquid" },
                priceHeuristic = { role = "container" },
            }
        end
        if fullType == "Base.Seed" then
            return {
                primary = "Food",
                tags = { "Food", "FoodSeed" },
                priceHeuristic = { role = "seed" },
            }
        end
        return { primary = "Misc", tags = { "Misc" } }
    end,
    GetTags = function(fullType)
        local details = MarketSense.GetPriceDetails(fullType)
        return {
            primary = details.primary,
            category = details.primary,
            tags = details.tags,
            expandedTags = details.expandedTags,
        }
    end,
}

PNC = { Semantics = {} }
local Adapter = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticMarketSenseAdapter.lua"
)

local apple = Adapter.EnrichClassification("Base.Apple", {
    primary = "food",
    tags = { food = true },
}, {})
T.equal(apple.semanticCapabilities.edible, true,
    "MarketSense food role derives edible capability")
T.equal(apple.capabilities.edible, true,
    "derived edible capability is exposed to selectors")
T.equal(apple.marketRole, "edible",
    "MarketSense role is retained for diagnostics")

local water = Adapter.EnrichClassification("Base.WaterBottle", {
    primary = "food",
}, {})
T.equal(water.semanticCapabilities.drinkable, true,
    "beverage taxonomy derives drinkable capability")
T.equal(water.semanticCapabilities.edible, false,
    "beverage taxonomy prevents water from becoming an eat target")
T.equal(water.semanticCapabilities.consumable, true,
    "drinkable items are consumable")

local emptyBottle = Adapter.EnrichClassification("Base.EmptyBottle", {
    primary = "container",
}, {})
T.equal(emptyBottle.semanticCapabilities.refillable, true,
    "empty liquid containers derive refillable capability")
T.equal(emptyBottle.semanticCapabilities.drinkable, false,
    "empty liquid containers are explicitly blocked as drinkable")

local seed = Adapter.EnrichClassification("Base.Seed", {
    primary = "food",
}, {})
T.equal(seed.semanticCapabilities.edible, false,
    "MarketSense seed role blocks edible inference")

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
    "PNC/Semantics/PNC_SemanticConsumptionCatalog.lua"
)
local Policy = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Semantics/PNC_SemanticDialoguePolicy.lua"
)

local Parser = Semantic.Parser
local eat = Parser.Parse("well, eat it")
T.equal(eat.intent, "REQUEST", "eat is a request")
T.equal(eat.action, "EAT", "eat is compositional action semantics")
T.equal(eat.object.reference, "IT", "eat captures a pronoun object")
T.equal(eat.object.unresolved, true,
    "pronoun resolution remains a context concern")

local drink = Parser.Parse("could you drink your water")
T.equal(drink.action, "DRINK", "drink parses with polite prefix")
T.equal(drink.object.concept, "WATER",
    "known water concept is retained in the object slot")

local refill = Parser.Parse("refill the bottle")
T.equal(refill.action, "REFILL", "refill parses compositionally")
T.equal(refill.object.text, "bottle",
    "unknown world item names remain bounded captures")

local locallyHandled = Policy.Decide(Parser.Parse("eat apple"), nil, {
    llmEnabled = false,
})
T.equal(locallyHandled.branch, "COMMAND_ACCEPTED",
    "recognized consumption enters the local task path")
T.equal(locallyHandled.route, "deterministic",
    "local consumption does not invoke the LLM")

local implicit = Parser.Parse("eat")
T.equal(implicit.action, "EAT", "bare eat is recognized")
T.equal(implicit.object.reference, "IT",
    "bare eat creates an implicit discourse reference")
T.equal(implicit.object.implicit, true,
    "implicit object provenance is visible")

local Selector = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/Inventory/PNC_SemanticItemSelector.lua"
)
local record = {
    inventory = {
        items = {
            apple = { id = "apple", type = "Base.Apple", stack = 1 },
            water = { id = "water", type = "Base.WaterBottle", stack = 1 },
        },
    },
}
local selectedApple, appleReason = Selector.Find(record, {
    capabilities = { "edible" },
})
T.equal(appleReason, "matched",
    "semantic edible capability selects through MarketSense")
T.equal(selectedApple.itemID, "apple",
    "semantic edible selection rejects the water bottle")
local selectedWater, waterReason = Selector.Find(record, {
    capabilities = { "drinkable" },
})
T.equal(waterReason, "matched",
    "semantic drinkable capability selects through MarketSense")
T.equal(selectedWater.itemID, "water",
    "semantic drinkable selection finds the beverage")
local selectedAppleMap, appleMapReason = Selector.Find(record, {
    capabilities = { edible = true },
})
T.equal(appleMapReason, "matched",
    "boolean capability maps are accepted at the selector boundary")
T.equal(selectedAppleMap.itemID, "apple",
    "contextual capability maps select the compatible item")

T.finish("pnc_semantic_marketsense_consumption_smoke")
