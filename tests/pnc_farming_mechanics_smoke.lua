local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local function equal(actual, expected, label)
    T.equal(actual, expected, label)
end

local function list(items)
    return {
        size = function() return #items end,
        get = function(_, index) return items[index + 1] end,
    }
end

local record = {
    id = "farmer_1",
    inventory = {
        items = {
            seed_1 = { type = "Base.CabbageSeed", stack = 1 },
        },
    },
}

local fluid = {
    amount = 1,
    getAmount = function(self) return self.amount end,
    adjustAmount = function(self, value) self.amount = value end,
}

local waterItem = {
    isWaterSource = function() return true end,
    getFluidContainer = function() return fluid end,
    syncItemFields = function(self) self.synced = true end,
}

local nativeInventory = {
    getItems = function() return list({ waterItem }) end,
}

local body = {
    getInventory = function() return nativeInventory end,
    getPerkLevel = function() return 3 end,
}

local plant = {
    state = "plow",
    waterLvl = 0,
    nbOfGrow = 0,
    health = 50,
    fertilizer = 0,
    saveCount = 0,
    isAlive = function() return true end,
    canHarvest = function() return true end,
    seed = function(self, cropType, skill)
        self.seededType = cropType
        self.typeOfSeed = cropType
        self.seedSkill = skill
        self.state = "seeded"
    end,
    water = function(self, _, uses)
        self.waterLvl = math.min(100, self.waterLvl + uses * 10)
    end,
    fertilize = function(self, args)
        self.compost = args.compost == true
        self.fertilizer = self.fertilizer + 1
    end,
    saveData = function(self) self.saveCount = self.saveCount + 1 end,
}

local system = {
    hoursElapsed = 10,
    getLuaObjectAt = function(_, x, y, z)
        if x == 10 and y == 20 and z == 0 then return plant end
        return nil
    end,
    growPlant = function(_, target)
        target.nbOfGrow = target.nbOfGrow + 1
    end,
    harvest = function(_, target, player)
        target.harvestedBy = player
        target.state = "harvested"
    end,
}

SFarmingSystem = { instance = system }
ZomboidGlobals = { farmingFluidContainerMillilitresPerUse = 250 }
Perks = { Farming = "Farming" }
farming_vegetableconf = { props = { Cabbages = { fullGrown = 5 } } }
getCell = function()
    return { getGridSquare = function() return {} end }
end

PNC = {
    Farming = {
        RectangleInfo = function()
            return true, nil, {
                minX = 10, maxX = 10, minY = 20, maxY = 20,
                z = 0, width = 1, height = 1, tileCount = 1,
            }
        end,
    },
    FarmingCatalog = {
        Resolve = function()
            return {
                typeOfSeed = "Cabbages",
                seedTypes = { "Base.CabbageSeed" },
            }
        end,
    },
    FarmingResearch = T.load("ProjectHoomans", "shared",
        "PNC/Core/Farming/PNC_FarmingResearch.lua"),
    Inventory = {
        CaptureLooseInventory = function() end,
        EnsureRecordInventory = function(target) return target.inventory end,
    },
    SupplyInventory = {
        RemoveCoreItemIds = function(target, ids)
            target.inventory.items[ids[1]].stack = 0
            return true
        end,
    },
}

local source = T.read("ProjectHoomans", "server",
    "PNC/Farming/PNC_PZFarmingAdapter.lua")
T.falsy(string.find(source, "pcall", 1, true),
    "farming adapter does not hide engine failures with pcall")

local Adapter = T.load("ProjectHoomans", "server",
    "PNC/Farming/PNC_PZFarmingAdapter.lua")
local component = { region = {} }
local tile = { x = 10, y = 20, z = 0 }

local planted, plantReason = Adapter.Plant(record, body, component, tile, "cabbages")
equal(planted, true, "planting succeeds")
equal(plantReason, "PLANTED", "planting reason")
equal(plant.seededType, "Cabbages", "vanilla receives crop key")
equal(record.inventory.items.seed_1.stack, 0, "seed item is consumed")

local watered, waterReason = Adapter.Water(record, body, tile)
equal(watered, true, "watering succeeds")
equal(waterReason, "WATERED", "watering reason")
equal(plant.waterLvl, 10, "plant receives one water use")
equal(fluid.amount, 0.75, "fluid amount is reduced")
equal(waterItem.synced, true, "fluid item is synchronized")

local growth, growthReason = Adapter.ApplyResearchEffect(
    component, "fast_growth", body)
equal(growth, true, "fast growth succeeds")
equal(growthReason, "PLOT_GROWN", "fast growth uses vanilla grow result")
T.truthy(plant.nbOfGrow > 5, "fast growth reaches harvest level")

local boosted, boostReason = Adapter.ApplyResearchEffect(
    component, "boost_yield", body)
equal(boosted, true, "yield boost succeeds")
equal(boostReason, "YIELD_BOOSTED", "yield boost reason")
equal(plant.bonusYield, true, "vanilla bonus-yield flag is enabled")

local fertilized, fertilizerReason = Adapter.ApplyResearchEffect(
    component, "fertilize", body)
equal(fertilized, true, "fertilizer effect succeeds")
equal(fertilizerReason, "FERTILIZER_APPLIED", "fertilizer reason")
equal(plant.compost, true, "vanilla compost path is used")

local gmo, gmoReason = Adapter.ApplyResearchEffect(
    component, "gmo_upgrade", body)
equal(gmo, true, "GMO effect succeeds")
equal(gmoReason, "GMO_UPGRADE_APPLIED", "GMO reason")
equal(plant.health, 100, "GMO raises plant health")
equal(plant.cursed, false, "GMO clears cursed state")

local harvested, harvestReason = Adapter.Harvest(record, body, tile)
equal(harvested, true, "harvesting succeeds")
equal(harvestReason, "HARVESTED", "harvesting reason")
equal(plant.harvestedBy, body, "vanilla receives the live farmer body")

T.finish("pnc_farming_mechanics_smoke")
