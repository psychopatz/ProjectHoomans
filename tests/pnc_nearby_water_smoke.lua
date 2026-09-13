local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function square(x, y, objects)
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        getObjects = function() return list(objects or {}) end,
        getWorldObjects = function() return list({}) end,
    }
end

local function waterItem(id, amount, tainted)
    local fluid = {
        getFluidTypeString = function() return tainted and "TaintedWater"
            or "Water" end,
    }
    local container = {
        amount = amount,
        getItems = function() return list({}) end,
        isEmpty = function(self) return self.amount <= 0 end,
        getPrimaryFluid = function() return fluid end,
        getAmount = function(self) return self.amount end,
        contains = function() return tainted == true end,
        removeFluid = function(self, value)
            self.amount = math.max(0, self.amount - value)
            return { amount = value }
        end,
    }
    local item = {
        amount = amount,
        getID = function() return id end,
        getFullType = function() return "Base.WaterBottle" end,
        getFluidContainer = function() return container end,
        isTaintedWater = function() return tainted == true end,
        syncItemFields = function() end,
    }
    return item, container
end

local cleanItem, cleanContainer = waterItem(2, 1.0, false)
local taintedItem = waterItem(1, 1.0, true)
local cupboard = {
    getContainer = function()
        return { getItems = function() return list({ taintedItem, cleanItem }) end }
    end,
}
local originSquare = square(10, 10, { cupboard })
local cell = {
    getGridSquare = function(_, x, y)
        if x == 10 and y == 10 then return originSquare end
        return nil
    end,
}
local body = {
    getX = function() return 10.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
}
local faucetAmount = 10
local faucet = {
    getID = function() return 7 end,
    hasFluid = function() return true end,
    getFluidAmount = function() return faucetAmount end,
    getFluidContainer = function() return {
        isEmpty = function() return false end,
        isWaterOnlySource = function() return true end,
    } end,
    isTaintedWater = function() return false end,
    -- Build 42.20's finite IsoObject source-consumption API.
    useFluid = function(_, amount)
        local consumed = math.min(faucetAmount, amount)
        faucetAmount = faucetAmount - consumed
        return consumed
    end,
    moveFluidToTemporaryContainer = function(_, amount)
        faucetAmount = faucetAmount - amount
        return { amount = amount }
    end,
}
local faucetSquare = square(9, 10, { faucet })
local faucetBody = {
    getX = function() return 8.5 end,
    getY = function() return 10.5 end,
    getZ = function() return 0 end,
}
getCell = function() return cell end
getTimestampMs = function() return 1000 end
Fluid = { TaintedWater = "TaintedWater" }
FluidContainer = { DisposeContainer = function() end }

PNC = {}
local Locator = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_NearbyResourceLocator.lua")
PNC.NearbyResourceLocator = Locator
local Service = T.load("ProjectHoomans", "server",
    "PNC/World/PNC_NearbyWaterService.lua")

local located = Locator.Find(body, {
    cell = cell, radius = 1,
    accept = function(entry) return entry.item == cleanItem end,
})
T.equal(located.item, cleanItem, "locator selects the nearest accepted item")

local record = { id = "npc:water" }
PNC.Registry = { GetLiveZombie = function() return body end }
PNC.IndividualNeeds = { Get = function() return 0.40 end }
local source = Service.Find(record)
T.equal(source.item, cleanItem, "water service rejects tainted containers")
T.equal(Service.DesiredLiters(record, 1.0), 0.80,
    "water amount follows the NPC thirst requirement")
local ok, consumed, remaining = Service.Consume(record, source, 0.80)
T.truthy(ok, "clean water is consumed server-side")
T.equal(consumed, 0.80, "only the required liters are removed")
T.near(remaining, 0.20, 0.000001, "remaining liters are reported")
T.near(cleanContainer.amount, 0.20, 0.000001,
    "the original water container is preserved and partially drained")

cell.getGridSquare = function(_, x, y)
    if x == 9 and y == 10 then return faucetSquare end
    if x == 10 and y == 10 then return originSquare end
    return nil
end
PNC.Registry.GetLiveZombie = function() return faucetBody end
local faucetSource = Service.Find({ id = "npc:faucet" })
T.equal(faucetSource.kind, "faucet", "nearby faucet is a water source")
T.truthy(Service.IsFillableFaucet(faucet),
    "a source with a supported transfer mutation is refillable")
local exactFaucet = Service.FindAt({ id = "npc:faucet" }, 9, 10, 0)
T.equal(exactFaucet.object, faucet,
    "an explicitly clicked faucet resolves on the server")
local approach, approaches = Service.BuildApproach(
    { id = "npc:faucet" }, exactFaucet)
T.equal(approach.x, 10.5, "faucet approach uses an adjacent square")
T.equal(approach.y, 10.5, "faucet approach never targets its occupied tile")
T.equal(approach.interactionFacing, "W", "NPC faces the faucet after arrival")
T.truthy(#approaches >= 1, "faucet exposes retryable approach candidates")
local faucetOK, faucetConsumed = Service.Consume(
    { id = "npc:faucet" }, faucetSource, 0.8)
T.truthy(faucetOK, "clean faucet water is consumable")
T.equal(faucetConsumed, 0.8, "faucet supplies the requested liters")
T.near(faucetAmount, 9.2, 0.000001,
    "faucet consumption mutates the live source amount")

local infiniteFaucet = {
    hasFluid = function() return true end,
    getFluidAmount = function() return 10000 end,
    getFluidCapacity = function() return 10000 end,
    getFluidContainer = function() return {
        isEmpty = function() return true end,
        getAmount = function() return 0 end,
        isWaterOnlySource = function() return true end,
    } end,
    transferFluidTo = function(_, _, amount) return amount end,
}
local infiniteAmount = infiniteFaucet.getFluidAmount()
T.truthy(Service.IsCleanFaucet(infiniteFaucet),
    "a Build 42 infinite sink remains valid with an empty exposed container")
T.truthy(Service.IsInfiniteFaucet(infiniteFaucet),
    "the Build 42 10000-unit source sentinel is recognized as infinite")
T.truthy(Service.IsFillableFaucet(infiniteFaucet),
    "the real transferFluidTo API marks an infinite sink refillable")
local infiniteOK, infiniteConsumed = Service.Consume(
    { id = "npc:infinite-faucet" }, {
        kind = "faucet", object = infiniteFaucet,
        x = 9, y = 10, z = 0,
    }, 0.8)
T.truthy(infiniteOK, "an infinite sink supplies water without a finite amount")
T.equal(infiniteConsumed, 0.8,
    "infinite sink consumption reports the requested liters")
T.equal(infiniteFaucet.getFluidAmount(), infiniteAmount,
    "infinite sink consumption does not debit the engine source sentinel")

cell.getGridSquare = function() return nil end
PNC.Registry.GetLiveZombie = function()
    return { getX = function() return 50 end,
        getY = function() return 50 end,
        getZ = function() return 0 end }
end
local unloaded, unloadedReason = Service.Resolve(
    { id = "npc:unloaded" }, "missing-water")
T.falsy(unloaded, "unloaded water does not produce a stale source")
T.equal(unloadedReason, "WATER_WORLD_UNLOADED",
    "unloaded water reports a retryable world state")

-- Hydration planning reuses one decision boundary for container drinking,
-- refilling, and direct world drinking. The live source is selected only for
-- the refill plan and remains the same source key for the activity.
cell.getGridSquare = function(_, x, y)
    if x == 9 and y == 10 then return faucetSquare end
    if x == 10 and y == 10 then return originSquare end
    return nil
end
PNC.Registry.GetLiveZombie = function() return faucetBody end
local planRecord = { id = "npc:hydration-plan", alive = true }
local planBottle = { id = "plan-bottle", type = "Base.WaterBottle" }
local planDescription = {
    amount = 0, capacity = 1, freeCapacity = 1,
    canDrink = false, canFill = true,
}
local planBottleRef = planBottle
PNC.Inventory = {
    GetWaterContainer = function() return planBottleRef end,
    FindWaterContainer = function() return planBottleRef end,
    DescribeLiquidContainer = function() return planDescription end,
    ReconcileWaterContainer = function() end,
}
PNC.NPCSupplyService = {
    HasPersonalSupply = function() return false end,
}
local refillPlan = Service.ResolveHydrationPlan(planRecord)
T.equal(refillPlan.action, "fill_container",
    "an empty liquid container prefers refill")
T.equal(refillPlan.containerID, "plan-bottle",
    "the refill plan carries the selected container")
T.equal(refillPlan.source.object, faucet,
    "the refill plan carries the selected clean source")
local selectedSourceKey = refillPlan.sourceKey
local manualRefillPlan = Service.ResolveHydrationPlan(planRecord, "refill")
T.equal(manualRefillPlan.action, "fill_container",
    "manual refill uses the dedicated refill planning mode")
T.equal(manualRefillPlan.sourceKey, selectedSourceKey,
    "manual refill reuses the hydration source identity")
planDescription.canDrink = true
planDescription.canFill = true
planDescription.amount = 1
planDescription.freeCapacity = 0
Service.InvalidateHydrationPlan(planRecord)
local drinkPlan = Service.ResolveHydrationPlan(planRecord)
T.equal(drinkPlan.action, "drink_container",
    "a container with water is preferred before world drinking")
T.equal(drinkPlan.containerID, "plan-bottle",
    "container drinking keeps the planned container identity")
Service.InvalidateHydrationPlan(planRecord)
local fullRefillPlan, fullRefillReason = Service.ResolveHydrationPlan(
    planRecord, "refill")
T.falsy(fullRefillPlan, "manual refill rejects a full container")
T.equal(fullRefillReason, "WATER_CONTAINER_FULL",
    "manual refill reports a full container instead of generic hydration failure")
planBottleRef = nil
planDescription.canDrink = false
planDescription.canFill = false
Service.InvalidateHydrationPlan(planRecord)
local worldPlan = Service.ResolveHydrationPlan(planRecord)
T.equal(worldPlan.action, "drink_source",
    "direct world drinking is the final fallback without a container")
T.equal(worldPlan.sourceKey, selectedSourceKey,
    "the shared source identity remains stable across hydration decisions")

T.finish("pnc_nearby_water_smoke")
