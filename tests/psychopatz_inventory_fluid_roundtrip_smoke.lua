local T = require "tests/support/test"

T.addPackagePaths()

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local fluids = {}
local fluidByName = {}
local function makeFluid(name)
    local fluid = {}
    function fluid:getFluidTypeString() return name end
    function fluid:getFluidType() return name end
    fluids[#fluids + 1] = fluid
    fluidByName[name] = fluid
    return fluid
end

makeFluid("Water")
makeFluid("Coffee")

Fluid = {
    getAllFluids = function() return javaList(fluids) end,
    Get = function(name)
        if type(name) == "table" then return name end
        return fluidByName[tostring(name)]
    end,
}

local function makeContainer(values, capacity, canEmpty, locked)
    local container = {
        values = {}, capacity = capacity or 1,
        canEmpty = canEmpty ~= false, locked = locked == true,
        rainCatcher = 0,
    }
    for name, amount in pairs(values or {}) do
        container.values[name] = amount
    end
    function container:getAmount()
        local total = 0
        for _, amount in pairs(self.values) do total = total + amount end
        return total
    end
    function container:getCapacity() return self.capacity end
    function container:setCapacity(value) self.capacity = value end
    function container:isInputLocked() return self.locked end
    function container:setInputLocked(value) self.locked = value end
    function container:canPlayerEmpty() return self.canEmpty end
    function container:setCanPlayerEmpty(value) self.canEmpty = value end
    function container:getRainCatcher() return self.rainCatcher end
    function container:setRainCatcher(value) self.rainCatcher = value end
    function container:getPrimaryFluid()
        local selected
        local selectedAmount = -1
        for name, amount in pairs(self.values) do
            if amount > selectedAmount then
                selected = fluidByName[name]
                selectedAmount = amount
            end
        end
        return selected
    end
    function container:getSpecificFluidAmount(fluid)
        return self.values[fluid:getFluidTypeString()] or 0
    end
    function container:Empty() self.values = {} end
    function container:addFluid(fluid, amount)
        local name = fluid:getFluidTypeString()
        local free = self.capacity - self:getAmount()
        self.values[name] = (self.values[name] or 0)
            + math.max(0, math.min(amount, free))
    end
    function container:adjustAmount(value)
        local current = self:getAmount()
        if current <= 0 then return end
        local ratio = value / current
        for name, amount in pairs(self.values) do
            self.values[name] = amount * ratio
        end
    end
    function container:removeFluid(amount)
        local current = self:getAmount()
        if current <= 0 then return end
        local ratio = math.max(0, (current - amount) / current)
        for name, value in pairs(self.values) do
            self.values[name] = value * ratio
        end
    end
    return container
end

local function makeFluidItem(values, options)
    options = options or {}
    local item = {
        fullType = options.fullType or "Base.WaterBottle",
        condition = options.condition or 10,
        weight = options.weight or 1,
        container = makeContainer(values, options.capacity or 1,
            options.canEmpty, options.locked),
        modData = {},
    }
    function item:getFullType() return self.fullType end
    function item:getCondition() return self.condition end
    function item:getConditionMax() return 10 end
    function item:setCondition(value) self.condition = value end
    function item:getActualWeight() return self.weight end
    function item:getWeight() return self.weight end
    function item:getFluidContainer() return self.container end
    function item:getModData() return self.modData end
    return item
end

local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Portable = Inventory.PortableItemState
local Types = Inventory.ItemTypeRegistry
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Tester = require "PsychopatzCore/Inventory/Debug/PsychopatzInventoryRoundTripTester"

Types.load(nil)
Types.scan({ "Base.WaterBottle" })

local source = makeFluidItem({ Water = 0.6, Coffee = 0.4 }, {
    capacity = 2, canEmpty = false, locked = true,
})
source.container.rainCatcher = 0.25
local record, reason = Inventory.encodeItem(source, 1)
T.truthy(record, reason or "fluid record missing")
T.equal(record[C.CODEC_ID], C.CODEC_FLUID, "fluid codec selected")
T.truthy(C.FLAG_FLUID and record[C.FLAGS] % (C.FLAG_FLUID * 2)
    >= C.FLAG_FLUID, "fluid flag selected")
T.equal(#record[C.STATE][#record[C.STATE]].fluids, 2,
    "mixture components captured")
T.equal(record[C.STATE][#record[C.STATE]].fluidCanPlayerEmpty, false,
    "sealed state captured")

local decoded
decoded, reason = Inventory.decodeItem(record, function()
    return makeFluidItem(nil, { capacity = 1 })
end)
T.truthy(decoded, reason or "fluid record failed to decode")
local decodedContainer = decoded:getFluidContainer()
T.near(decodedContainer:getAmount(), 1, 0.0001, "fluid total restored")
T.near(decodedContainer:getSpecificFluidAmount(fluidByName.Water), 0.6,
    0.0001, "water component restored")
T.near(decodedContainer:getSpecificFluidAmount(fluidByName.Coffee), 0.4,
    0.0001, "coffee component restored")
T.equal(decodedContainer.capacity, 2, "fluid capacity restored")
T.equal(decodedContainer.canEmpty, false, "sealed state restored")
T.equal(decodedContainer.locked, true, "input lock restored")
T.near(decodedContainer.rainCatcher, 0.25, 0.0001,
    "rain catcher state restored")

local sparseTarget = makeFluidItem({ Water = 1 }, { capacity = 1 })
local applied, applyReason = Portable.ApplyFluid(
    sparseTarget, { fluidAmount = 0.5 }
)
T.equal(applied, true, applyReason or "sparse fluid delta failed")
T.near(sparseTarget:getFluidContainer():getAmount(), 0.5, 0.0001,
    "amount-only fluid delta restored against native default")
T.near(sparseTarget:getFluidContainer():getSpecificFluidAmount(
    fluidByName.Water), 0.5, 0.0001,
    "amount-only fluid delta preserved native mixture type")

local emptyTarget = makeFluidItem({ Water = 1 }, { capacity = 1 })
applied, applyReason = Portable.ApplyFluid(emptyTarget, { fluidAmount = 0 })
T.equal(applied, true, applyReason or "empty fluid delta failed")
T.near(emptyTarget:getFluidContainer():getAmount(), 0, 0.0001,
    "explicit empty fluid delta did not clear native default")

local Transfer = T.load("PsychopatzCore", "server",
    "PsychopatzCore/Inventory/PsychopatzItemTransfer.lua")
local transferState = Transfer.CaptureState(source)
local transferred = makeFluidItem(nil, { capacity = 1 })
Transfer.ApplyState(transferred, transferState)
T.near(transferred:getFluidContainer():getAmount(), 1, 0.0001,
    "item transfer restored fluid amount")
T.equal(transferred:getFluidContainer().canEmpty, false,
    "item transfer restored sealed state")
T.equal(#transferState.fluids, 2, "item transfer captured mixture")

local roundTripped, checks = Tester.test(source, function()
    return makeFluidItem(nil, { capacity = 1 })
end)
T.truthy(roundTripped, checks and "fluid record changed during round trip")

local food = {
    fullType = "Base.FractionalApple", isFood = true,
    hungChange = -0.15, thirstChange = -0.1, age = 2,
}
function food:getFullType() return self.fullType end
function food:getCondition() return 10 end
function food:getConditionMax() return 10 end
function food:getActualWeight() return 0.2 end
function food:getWeight() return 0.2 end
function food:getAge() return self.age end
function food:setAge(value) self.age = value end
function food:isCooked() return false end
function food:setCooked(value) self.cooked = value end
function food:isBurnt() return false end
function food:setBurnt(value) self.burnt = value end
function food:isFrozen() return false end
function food:setFrozen(value) self.frozen = value end
function food:getHungChange() return self.hungChange end
function food:setHungChange(value) self.hungChange = value end
function food:getThirstChange() return self.thirstChange end
function food:setThirstChange(value) self.thirstChange = value end
function food:getModData() return {} end

local foodRoundTrip = Tester.test(food, function()
    local copy = {
        fullType = "Base.FractionalApple", isFood = true,
        hungChange = 0, thirstChange = 0, age = 0,
    }
    function copy:getFullType() return self.fullType end
    function copy:getCondition() return 10 end
    function copy:getConditionMax() return 10 end
    function copy:getActualWeight() return 0.2 end
    function copy:getWeight() return 0.2 end
    function copy:getAge() return self.age end
    function copy:setAge(value) self.age = value end
    function copy:isCooked() return self.cooked == true end
    function copy:setCooked(value) self.cooked = value end
    function copy:isBurnt() return self.burnt == true end
    function copy:setBurnt(value) self.burnt = value end
    function copy:isFrozen() return self.frozen == true end
    function copy:setFrozen(value) self.frozen = value end
    function copy:getHungChange() return self.hungChange end
    function copy:setHungChange(value) self.hungChange = value end
    function copy:getThirstChange() return self.thirstChange end
    function copy:setThirstChange(value) self.thirstChange = value end
    function copy:getModData() return {} end
    return copy
end)
T.truthy(foodRoundTrip, "mutable food state did not round trip")

T.finish("psychopatz_inventory_fluid_roundtrip_smoke")
