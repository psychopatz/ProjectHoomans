local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

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
    getFullType = function() return "Base.WateringCan" end,
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
    Core = { Now = function() return 1000 end },
    FarmingService = { Internal = {
        BaseFor = function()
            return { factionId = "f1", colonyId = "c1" }
        end,
    } },
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
PNC.ColonyStorageRepository = {
    GetPrimary = function() return { id = "storage-1" } end,
}
PNC.ColonyStorageService = {
    ReserveProductionMaterials = function(storageId, requirements)
        T.equal(storageId, "storage-1", "farming material storage")
        T.equal(requirements[1].itemTypes[1], "Base.TomatoSeed",
            "farming material request")
        return {
            id = "reservation-1",
            requirements = {{ selectedType = "Base.TomatoSeed" }},
        }
    end,
    CollectProductionReservation = function()
        return true, { records = {}, itemIds = {} }
    end,
    ReleaseProductionReservation = function() return true end,
}
local farmingMaterials = T.load("ProjectHoomans", "server",
    "PNC/Farming/FarmingService/PNC_FarmingService_Materials.lua")
local seedRuntime = {}
T.truthy(farmingMaterials.EnsureSeed(record, nil, {
    seedTypes = { "Base.CabbageSeed" },
}, seedRuntime), "existing seed is selected")
T.equal(seedRuntime.activityItemFullType, "Base.CabbageSeed",
    "existing seed exposes its full type")
local waterRuntime = {}
T.truthy(farmingMaterials.EnsureWater(record, nil, waterRuntime, body),
    "existing water container is selected")
T.equal(waterRuntime.activityItemFullType, "Base.WateringCan",
    "existing water container exposes its full type")
local retrievedRuntime = {}
T.truthy(farmingMaterials.RetrieveMaterial(record, { id = "farm-1" }, {
    "Base.TomatoSeed",
}, retrievedRuntime), "reserved farming material is collected")
T.equal(retrievedRuntime.activityItemFullType, "Base.TomatoSeed",
    "collected farming material keeps the reserved full type")
local component = { region = {} }
local tile = { x = 10, y = 20, z = 0 }

local planted, plantReason = Adapter.Plant(record, body, component, tile, "cabbages")
T.equal(planted, true, "planting succeeds")
T.equal(plantReason, "PLANTED", "planting reason")
T.equal(plant.seededType, "Cabbages", "vanilla receives crop key")
T.equal(record.inventory.items.seed_1.stack, 0, "seed item is consumed")

local watered, waterReason = Adapter.Water(record, body, tile)
T.equal(watered, true, "watering succeeds")
T.equal(waterReason, "WATERED", "watering reason")
T.equal(plant.waterLvl, 10, "plant receives one water use")
T.equal(fluid.amount, 0.75, "fluid amount is reduced")
T.equal(waterItem.synced, true, "fluid item is synchronized")

local growth, growthReason = Adapter.ApplyResearchEffect(
    component, "fast_growth", body)
T.equal(growth, true, "fast growth succeeds")
T.equal(growthReason, "PLOT_GROWN", "fast growth uses vanilla grow result")
T.truthy(plant.nbOfGrow > 5, "fast growth reaches harvest level")

local boosted, boostReason = Adapter.ApplyResearchEffect(
    component, "boost_yield", body)
T.equal(boosted, true, "yield boost succeeds")
T.equal(boostReason, "YIELD_BOOSTED", "yield boost reason")
T.equal(plant.bonusYield, true, "vanilla bonus-yield flag is enabled")

local fertilized, fertilizerReason = Adapter.ApplyResearchEffect(
    component, "fertilize", body)
T.equal(fertilized, true, "fertilizer effect succeeds")
T.equal(fertilizerReason, "FERTILIZER_APPLIED", "fertilizer reason")
T.equal(plant.compost, true, "vanilla compost path is used")

local gmo, gmoReason = Adapter.ApplyResearchEffect(
    component, "gmo_upgrade", body)
T.equal(gmo, true, "GMO effect succeeds")
T.equal(gmoReason, "GMO_UPGRADE_APPLIED", "GMO reason")
T.equal(plant.health, 100, "GMO raises plant health")
T.equal(plant.cursed, false, "GMO clears cursed state")

local harvested, harvestReason = Adapter.Harvest(record, body, tile)
T.equal(harvested, true, "harvesting succeeds")
T.equal(harvestReason, "HARVESTED", "harvesting reason")
T.equal(plant.harvestedBy, body, "vanilla receives the live farmer body")

T.finish("pnc_farming_mechanics_smoke")
