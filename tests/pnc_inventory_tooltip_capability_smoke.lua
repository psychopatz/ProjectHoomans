local T = require "tests/support/test"

T.addPackagePaths({
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "client" },
})

local Profiles = require
    "PsychopatzCore/Inventory/PsychopatzItemTypeProfile"
local DisplayState = require
    "PsychopatzCore/Inventory/PsychopatzInventoryDisplayState"
local Tooltip = require
    "PsychopatzCore/UI/Inventory/PsychopatzInventoryTooltipModel"

Profiles.Register("Base.WaterBottle", {
    fluid = true, condition = true, conditionWhenDamaged = true,
})
Profiles.Register("Base.Pistol", {
    weapon = true, ammo = true, condition = true, conditionAlways = true,
})
Profiles.Register("Base.Shirt", {
    clothing = true, condition = true, conditionAlways = true,
})
Profiles.Register("Base.Crisps", { food = true })

local function hasLine(model, label)
    for index = 1, #model.lines do
        if model.lines[index].label == label then return true end
    end
    return false
end

local function hasSection(model, label)
    for index = 1, #model.lines do
        if model.lines[index].section and model.lines[index].label == label then
            return true
        end
    end
    return false
end

local water = Tooltip.Build({
    fullType = "Base.WaterBottle", name = "Water Bottle", category = "Water",
    conditionMax = 10,
    compactItem = {
        type = "Base.WaterBottle",
        itemState = {
            condition = 10, ammoCount = 0, wetness = 0, bloodLevel = 0,
            dirtyness = 0, fluidAmount = 1, fluidCapacity = 1,
            fluidPrimaryType = "Water",
            fluids = { { type = "Water", amount = 1 } },
        },
    },
})
T.truthy(hasSection(water, "Liquids"),
    "fluid capability did not render the liquid section")
T.falsy(hasLine(water, "Ammo"), "fluid item leaked the ammo section")
T.falsy(hasSection(water, "Clothing"),
    "fluid item leaked the clothing section")
T.falsy(hasLine(water, "Condition"),
    "full generic condition should remain hidden")

local pistol = Tooltip.Build({
    fullType = "Base.Pistol", name = "Pistol", category = "Weapon",
    conditionMax = 10,
    compactItem = {
        type = "Base.Pistol",
        itemState = {
            condition = 8, ammoCount = 0, wetness = 0, bloodLevel = 0,
        },
    },
})
T.truthy(hasLine(pistol, "Ammo"), "weapon ammo section missing")
T.truthy(hasLine(pistol, "Condition"), "weapon condition missing")
T.falsy(hasSection(pistol, "Clothing"),
    "weapon leaked the clothing section")

local shirt = Tooltip.Build({
    fullType = "Base.Shirt", name = "Shirt", category = "Clothing",
    conditionMax = 10,
    compactItem = {
        type = "Base.Shirt",
        itemState = {
            condition = 10, ammoCount = 0, wetness = 0, bloodLevel = 0,
            dirtyness = 0,
        },
    },
})
T.truthy(hasSection(shirt, "Clothing"), "clothing section missing")
T.truthy(hasLine(shirt, "Condition"), "clothing condition missing")
T.falsy(hasLine(shirt, "Ammo"), "clothing leaked the ammo section")

local food = Tooltip.Build({
    fullType = "Base.Crisps", name = "Crisps", category = "Food",
    compactItem = {
        type = "Base.Crisps",
        itemState = { age = 1, hungChange = -0.2 },
    },
})
T.truthy(hasSection(food, "Food"), "food section missing")
T.falsy(hasLine(food, "Ammo"), "food leaked the ammo section")
T.falsy(hasSection(food, "Clothing"),
    "food leaked the clothing section")

instanceof = function(item, className)
    return item and item.className == className
end
local waterContainer = {
    getAmount = function() return 1 end,
    getCapacity = function() return 1 end,
}
local nativeWater = {
    className = "InventoryItem", fullType = "Base.WaterBottle",
    getFullType = function(self) return self.fullType end,
    getCondition = function() return 10 end,
    getConditionMax = function() return 10 end,
    getCurrentAmmoCount = function() return 0 end,
    isRoundChambered = function() return false end,
    isJammed = function() return false end,
    getWetness = function() return 0 end,
    getBloodlevel = function() return 0 end,
    getDirtiness = function() return 0 end,
    getFluidContainer = function() return waterContainer end,
}
local nativeState = DisplayState.StateForRow({ nativeItem = nativeWater }, nil, {
    fullFluid = false,
})
T.equal(nativeState.ammoCount, nil,
    "native neutral ammo getter leaked into fluid state")
T.equal(nativeState.wetness, nil,
    "native neutral clothing getter leaked into fluid state")
T.equal(nativeState.fluidCapacity, 1,
    "native fluid capability was not projected")
local nativeTooltip = Tooltip.Build({
    fullType = "Base.WaterBottle", name = "Water Bottle", weight = 0.1,
    conditionMax = 10, nativeItem = nativeWater,
})
T.truthy(hasSection(nativeTooltip, "Liquids"),
    "native fluid tooltip did not render liquids")
T.falsy(hasLine(nativeTooltip, "Ammo"),
    "native neutral ammo getter leaked into tooltip")
T.falsy(hasSection(nativeTooltip, "Clothing"),
    "native neutral clothing getter leaked into tooltip")
T.falsy(hasLine(nativeTooltip, "Condition"),
    "native full generic condition should remain hidden")

T.finish("pnc_inventory_tooltip_capability_smoke")
