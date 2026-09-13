local T = require "tests/support/test"

T.addPackagePaths()

local function copy(value)
    if type(value) ~= "table" then return value end
    local output = {}
    for key, entry in pairs(value) do output[key] = copy(entry) end
    return output
end

PNC = {
    Const = {
        GENERATOR_VERSION = 3,
        INVENTORY_OPLOG_MAX = 32,
        INVENTORY_ITEM_STATE_MAX_STRING_LENGTH = 1024,
        INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS = 64,
    },
    Core = { DeepCopy = copy },
    Equipment = {},
}

Fluid = {
    Get = function(name) return { getFluidTypeString = function() return name end } end,
}

local function native(fullType)
    if fullType == "Base.Axe" then
        return {
            getConditionMax = function() return 10 end,
            getUsedDelta = function() return 0 end,
        }
    end
    local amount = fullType == "Base.FullMug" and 0.25 or 0
    local primary = amount > 0 and {
        getFluidTypeString = function() return "Water" end,
        getFluidType = function() return "Water" end,
    } or nil
    local container = {
        getAmount = function() return amount end,
        getCapacity = function() return 1 end,
        isInputLocked = function() return false end,
        canPlayerEmpty = function() return true end,
        getPrimaryFluid = function() return primary end,
        getSpecificFluidAmount = function() return amount end,
        canAddFluid = function() return true end,
    }
    return {
        getFluidContainer = function() return container end,
        getConditionMax = function() return 10 end,
        getUsedDelta = function() return 0 end,
    }
end

PNC.Equipment.CreateItem = native
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Model.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_Hydration.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Mutations.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_WaterContainers.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Inventory/PNC_Inventory_Actions.lua")

local Inventory = PNC.Inventory
Inventory.SyncEquipmentFromInventory = function() end
Inventory.RebuildCaches = function() end
PNC.Registry = { MarkDirty = function() end }

local record = {
    id = "npc_water_container",
    archetypeID = "General",
    identitySeed = 1,
    runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
    inventory = {
        revision = 0, cachedWeight = 0, maxWeight = 10, rootMaxWeight = 10,
        equipped = { primary = "axe", secondary = nil, bag = nil },
        worn = {}, attached = {},
        items = {
            axe = { id = "axe", type = "Base.Axe", stack = 1,
                container = "root", equipSlot = "primary" },
            can = { id = "can", type = "Base.EmptyCan", stack = 1,
                container = "root" },
        },
        containers = { root = { maxWeight = 10, items = { "axe", "can" } } },
        template = { generatorVersion = 3 },
    },
}

Inventory.EnsureRecordInventory(record)
T.equal(record.inventory.equipped.primary, "axe",
    "auto-equipping a water container preserves the primary weapon")
T.equal(record.inventory.equipped.waterContainer, "can",
    "the only liquid-capable container is auto-equipped")
T.equal(record.inventory.items.can.equipSlot, "waterContainer",
    "auto-equipped container receives the logical water slot")
T.truthy(Inventory.IsLiquidContainer(record.inventory.items.can),
    "generic liquid-capable items are detected without a name whitelist")
T.truthy(Inventory.IsRefillableWaterContainer(record.inventory.items.can),
    "an empty liquid container is refillable")
local mug = { id = "mug", type = "Base.FullMug", stack = 1,
    container = "root" }
local mugDescription = Inventory.DescribeLiquidContainer(mug)
T.truthy(Inventory.IsWaterContainer(mug),
    "a different filled native liquid container is detected without a name whitelist")
T.truthy(mugDescription and mugDescription.canDrink,
    "a filled native liquid container is drinkable")

local equip = PNC.InventoryActions.Get("equip_water_container")
local unequip = PNC.InventoryActions.Get("unequip_water_container")
T.falsy(PNC.InventoryActions.IsAvailable(
    PNC.InventoryActions.Get("equip_primary"), record,
    record.inventory.items.can),
    "water container cannot overwrite the primary equipment slot")
T.falsy(PNC.InventoryActions.IsAvailable(equip, record,
    record.inventory.items.can), "already equipped container has no duplicate equip")
T.truthy(PNC.InventoryActions.IsAvailable(unequip, record,
    record.inventory.items.can), "equipped container exposes unequip")

Inventory.ClearWaterContainer(record, "test_clear")
T.equal(record.inventory.equipped.primary, "axe",
    "clearing the water slot leaves primary equipment unchanged")
T.equal(record.inventory.equipped.waterContainer, nil,
    "water slot clears independently")
local revisionAfterClear = record.inventory.revision
Inventory.EnsureRecordInventory(record, { reconcileWaterContainer = false })
T.equal(record.inventory.equipped.waterContainer, nil,
    "command validation unexpectedly re-equipped the water container")
T.equal(record.inventory.revision, revisionAfterClear,
    "read-only inventory validation changed the revision")
Inventory.ReconcileWaterContainer(record)
T.equal(record.inventory.equipped.waterContainer, "can",
    "explicit water reconciliation did not restore the container slot")

T.finish("pnc_water_container_smoke")
