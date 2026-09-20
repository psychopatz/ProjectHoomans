local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
MarketSense = {
    GetPriceDetails = function(fullType)
        if fullType == "Base.Sardines" then
            return {
                primary = "FoodSeafoodPerishable",
                category = "Food",
                tags = { "FoodSeafoodPerishable" },
                expandedTags = { "FoodSeafoodPerishable", "FoodSeafood", "Food" },
                priceHeuristic = { role = "edible" },
            }
        end
        if fullType == "Base.Rifle" then
            return {
                primary = "FirearmRifle",
                category = "Weapon",
                tags = { "FirearmRifle" },
                expandedTags = {
                    "FirearmRifle", "Firearm", "WeaponRanged", "Weapon",
                },
            }
        end
        if fullType == "Base.WaterBottle" then
            return {
                primary = "LiquidWater",
                category = "Liquid",
                tags = { "LiquidWater" },
                expandedTags = { "LiquidWater", "LiquidBeverage", "Liquid" },
                priceHeuristic = { role = "edible" },
            }
        end
        if fullType == "Base.Seed" then
            return {
                primary = "FoodSeed",
                category = "Food",
                tags = { "FoodSeed" },
                expandedTags = { "FoodSeed", "Food" },
                priceHeuristic = { role = "seed" },
            }
        end
        if fullType == "Base.BeverageWater" then
            return {
                primary = "BeverageWater",
                category = "Food",
                tags = { "BeverageWater" },
                expandedTags = { "BeverageWater", "Beverage", "Food" },
            }
        end
        if fullType == "Base.CoffeeBeans" then
            return {
                primary = "FoodCoffee",
                category = "Food",
                tags = { "FoodCoffee" },
                expandedTags = { "FoodCoffee", "FoodNonPerishable", "Food" },
            }
        end
        if fullType == "Base.LiquidCoffee" then
            return {
                primary = "LiquidCoffee",
                category = "Liquid",
                tags = { "LiquidCoffee" },
                expandedTags = { "LiquidCoffee", "LiquidBeverage", "Liquid" },
            }
        end
        if fullType == "Base.ResourceFuel" then
            return {
                primary = "ResourceFuel",
                category = "Resource",
                tags = { "ResourceFuel" },
                expandedTags = { "ResourceFuel", "Resource" },
            }
        end
        if fullType == "Base.LiquidFuel" then
            return {
                primary = "LiquidFuel",
                category = "Liquid",
                tags = { "LiquidFuel" },
                expandedTags = { "LiquidFuel", "LiquidIndustrial", "Liquid" },
            }
        end
        if fullType == "Base.GardenSeed" then
            return {
                primary = "GardeningSeed",
                category = "Building",
                tags = { "GardeningSeed" },
                expandedTags = { "GardeningSeed", "Gardening", "Building" },
            }
        end
        if fullType == "Base.Axe" then
            return {
                primary = "WeaponAxe",
                category = "Weapon",
                tags = { "WeaponAxe" },
                expandedTags = { "WeaponAxe", "WeaponMelee", "Weapon" },
            }
        end
        if fullType == "Base.Radio" then
            return {
                primary = "ElectronicsRadio",
                category = "Electronics",
                tags = { "ElectronicsRadio" },
                expandedTags = { "ElectronicsRadio", "Electronics" },
            }
        end
        if fullType == "Base.CannedFood" then
            return {
                primary = "FoodNonPerishableCanned",
                category = "Food",
                tags = { "FoodNonPerishableCanned" },
                expandedTags = { "FoodNonPerishableCanned", "FoodNonPerishable", "Food" },
            }
        end
        return {
            primary = "FoodStaple",
            category = "Food",
            tags = { "FoodStaple" },
            expandedTags = { "FoodStaple", "Food" },
            priceHeuristic = { role = "edible" },
        }
    end,
    GetTags = function(fullType)
        local details = MarketSense.GetPriceDetails(fullType)
        return {
            primary = details.primary,
            category = details.category,
            tags = details.tags,
            expandedTags = details.expandedTags,
        }
    end,
    GetItemCapabilities = function(fullType)
        return { fullType = fullType, capabilities = {} }
    end,
}
PNC = {
    Semantics = {},
    Core = { IsAuthority = function() return true end },
}

local Service = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Semantics/Inventory/PNC_SemanticInventoryQueryService.lua"
)

local result, reason = Service.Query({
    id = "npc-test",
    inventory = {
        revision = 4,
        items = {
            fish = { id = "fish", type = "Base.Sardines", stack = 2 },
            soup = { id = "soup", type = "Base.Soup", stack = 1 },
        },
    },
}, {
    concept = "SEAFOOD",
    text = "seafoods",
})
T.equal(reason, "found", "MarketSense seafood query resolves")
T.equal(result.status, "found", "query reports found")
T.equal(result.totalCount, 2, "query aggregates matching stack quantity")
T.equal(result.distinctItems, 1, "query returns matching item count")
T.equal(result.items[1].fullType, "Base.Sardines",
    "query returns the concrete matching inventory item")
T.equal(result.items[1].classification.category, "food",
    "query preserves normalized MarketSense classification")

local empty, emptyReason = Service.Query({
    inventory = {
        revision = 5,
        items = { soup = { id = "soup", type = "Base.Soup", stack = 1 } },
    },
}, { concept = "SEAFOOD", text = "seafood" })
T.equal(emptyReason, "empty", "query distinguishes an empty category")
T.equal(empty.status, "empty", "empty query is safe and deterministic")

local categorizedRecord = {
    inventory = {
        revision = 6,
        items = {
            fish = { id = "fish", type = "Base.Sardines", stack = 2 },
            soup = { id = "soup", type = "Base.Soup", stack = 1 },
            rifle = { id = "rifle", type = "Base.Rifle", stack = 1 },
            water = { id = "water", type = "Base.WaterBottle", stack = 1 },
            seed = { id = "seed", type = "Base.Seed", stack = 1 },
        },
    },
}
local food, foodReason = Service.Query(categorizedRecord, {
    concept = "FOOD",
})
T.equal(foodReason, "found",
    "food questions use MarketSense edible capabilities")
T.equal(food.totalCount, 3,
    "food category includes edible stacks but excludes drink and seed")
local beverage, beverageReason = Service.Query(categorizedRecord, {
    concept = "BEVERAGE",
})
T.equal(beverageReason, "found",
    "beverage questions use MarketSense drinkable capabilities")
T.equal(beverage.items[1].fullType, "Base.WaterBottle",
    "beverage query finds a liquid classified through MarketSense")
local rifleResult, rifleReason = Service.Query(categorizedRecord, {
    concept = "RIFLE",
})
T.equal(rifleReason, "found",
    "specific firearm queries use expanded MarketSense tags")
T.equal(rifleResult.items[1].fullType, "Base.Rifle",
    "rifle queries preserve the concrete subtype")

local taxonomyRecord = {
    inventory = {
        revision = 7,
        items = {
            liquidWater = {
                id = "liquidWater", type = "Base.WaterBottle", stack = 1,
            },
            beverageWater = {
                id = "beverageWater", type = "Base.BeverageWater", stack = 2,
            },
            foodCoffee = {
                id = "foodCoffee", type = "Base.CoffeeBeans", stack = 1,
            },
            liquidCoffee = {
                id = "liquidCoffee", type = "Base.LiquidCoffee", stack = 1,
            },
            resourceFuel = {
                id = "resourceFuel", type = "Base.ResourceFuel", stack = 1,
            },
            liquidFuel = {
                id = "liquidFuel", type = "Base.LiquidFuel", stack = 1,
            },
            gardenSeed = {
                id = "gardenSeed", type = "Base.GardenSeed", stack = 4,
            },
            foodSeed = {
                id = "foodSeed", type = "Base.Seed", stack = 1,
            },
            axe = { id = "axe", type = "Base.Axe", stack = 1 },
            radio = { id = "radio", type = "Base.Radio", stack = 1 },
            cannedFood = {
                id = "cannedFood", type = "Base.CannedFood", stack = 2,
            },
        },
    },
}
local water, waterReason = Service.Query(taxonomyRecord, { concept = "WATER" })
T.equal(waterReason, "found",
    "water spans both MarketSense beverage and liquid tag branches")
T.equal(water.distinctItems, 2,
    "water alternatives match both classified item families")
T.equal(water.totalCount, 3, "water alternatives preserve stack counts")
local coffee, coffeeReason = Service.Query(taxonomyRecord, {
    concept = "COFFEE",
})
T.equal(coffeeReason, "found",
    "coffee spans MarketSense food and liquid tag branches")
T.equal(coffee.distinctItems, 2,
    "coffee alternatives do not require disjoint tags simultaneously")
local fuel, fuelReason = Service.Query(taxonomyRecord, { concept = "FUEL" })
T.equal(fuelReason, "found",
    "fuel spans the resource and liquid tag branches")
T.equal(fuel.distinctItems, 2,
    "fuel alternatives match both MarketSense classifications")
local seeds, seedsReason = Service.Query(taxonomyRecord, { concept = "SEED" })
T.equal(seedsReason, "found",
    "seed questions span edible seed and gardening seed branches")
T.equal(seeds.distinctItems, 2,
    "seed alternatives preserve MarketSense root distinctions")
local melee, meleeReason = Service.Query(taxonomyRecord, {
    concept = "MELEE_WEAPON",
})
T.equal(meleeReason, "found",
    "melee questions use the expanded weapon hierarchy")
T.equal(melee.items[1].fullType, "Base.Axe",
    "melee hierarchy resolves a concrete axe item")
local radio, radioReason = Service.Query(taxonomyRecord, {
    concept = "RADIO",
})
T.equal(radioReason, "found",
    "electronics subtype queries use MarketSense leaf tags")
T.equal(radio.items[1].fullType, "Base.Radio",
    "radio query resolves the electronics subtype")
local canned, cannedReason = Service.Query(taxonomyRecord, {
    concept = "PRESERVED_FOOD",
})
T.equal(cannedReason, "found",
    "preserved food includes the dedicated MarketSense canned branch")
T.equal(canned.items[1].fullType, "Base.CannedFood",
    "canned goods query preserves its concrete item classification")
local allItems, allReason = Service.Query(categorizedRecord, {
    concept = "ANY_ITEM",
    text = "items",
})
T.equal(allReason, "found", "generic possession questions return items")
T.equal(allItems.totalCount, 6,
    "generic possession results aggregate all bounded inventory stacks")
T.equal(allItems.distinctItems, 5,
    "generic possession results preserve distinct inventory entries")

local authoritativeRecord = {
    id = "npc-authoritative",
    alive = true,
    inventory = {
        revision = 9,
        items = {
            fish = { id = "fish", type = "Base.Sardines", stack = 2 },
        },
    },
}
PNC.Registry = {
    Get = function(id)
        return tostring(id or "") == authoritativeRecord.id
            and authoritativeRecord or nil
    end,
}
local rejected = Service.HandleRequest({
    requestID = "inventory:unauthorized",
    npcID = authoritativeRecord.id,
    rawText = "Do you have seafood?",
    normalizedText = "do you have seafood",
    confidence = 0.93,
    query = { concept = "SEAFOOD", text = "seafood" },
}, { player = {}, npcID = authoritativeRecord.id })
T.equal(rejected.status, "failed",
    "network players cannot query without a conversation lease")
T.equal(rejected.reason, "conversation_token_required",
    "missing authorization stays explicit")

local payload = Service.HandleRequest({
    requestID = "inventory:1",
    npcID = authoritativeRecord.id,
    rawText = "Do you have seafood?",
    normalizedText = "do you have seafood",
    confidence = 0.93,
    query = { concept = "SEAFOOD", text = "seafood" },
}, { internal = true })
T.equal(payload.status, "found",
    "authoritative inventory ingress returns a bounded result")
T.equal(payload.requestID, "inventory:1",
    "authoritative ingress preserves request correlation")
T.equal(payload.npcID, authoritativeRecord.id,
    "authoritative ingress preserves the addressed NPC")
T.equal(payload.inventoryRevision, 9,
    "authoritative ingress includes the inventory revision")

local possessionPayload = Service.HandleRequest({
    requestID = "inventory:list-all",
    npcID = authoritativeRecord.id,
    rawText = "What do you have?",
    normalizedText = "what do you have",
    confidence = 0.96,
    query = { concept = "ANY_ITEM", text = "items" },
}, { internal = true })
T.equal(possessionPayload.status, "found",
    "the validated inventory transport preserves open-list queries")
T.equal(possessionPayload.totalCount, 2,
    "open-list transport uses the authoritative NPC inventory")

T.finish("pnc_semantic_inventory_service_smoke")
