local T = require "tests/support/test"

T.addPackagePaths()

PNC = {
    Const = {
        GENERATOR_VERSION = 3,
        INVENTORY_ITEM_STATE_MAX_STRING_LENGTH = 1024,
        INVENTORY_ITEM_STATE_MAX_MODDATA_KEYS = 64,
    },
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, entry in pairs(value) do
                output[key] = PNC.Core.DeepCopy(entry)
            end
            return output
        end,
    },
    Equipment = {
        CreateItem = function(fullType)
            if fullType == "Base.WaterBottle" then
                local primary = {
                    getFluidTypeString = function() return "Water" end,
                    getFluidType = function() return "Water" end,
                }
                local container = {
                    getAmount = function() return 1 end,
                    getCapacity = function() return 1 end,
                    isInputLocked = function() return false end,
                    canPlayerEmpty = function() return true end,
                    getRainCatcher = function() return 0 end,
                    getPrimaryFluid = function() return primary end,
                    getSpecificFluidAmount = function() return 1 end,
                }
                return {
                    getConditionMax = function() return 10 end,
                    getUsedDelta = function() return 1 end,
                    getFluidContainer = function() return container end,
                }
            end
            return {
                getMaxCapacity = function() return 1 end,
            }
        end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/PNC_Inventory_Model.lua")
T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_Hydration.lua")

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local dirtyReason

PNC.Registry = {
    MarkDirty = function(_, reason) dirtyReason = reason end,
}
Inventory.SyncEquipmentFromInventory = function() end
Inventory.RebuildCaches = function() end
Internal.ItemContainerProfileCache = {}

local legacyFull = {
    id = "water_full", type = "Base.WaterBottle", stack = 1,
}
T.equal(Inventory.NormalizeItemState(legacyFull), false,
    "default water bottle was treated as a mutation")
T.equal(legacyFull.itemState, nil,
    "default water bottle stored redundant fluid metadata")
local effectiveFull = Inventory.ResolveItemState(legacyFull)
T.equal(effectiveFull.fluidAmount, 1,
    "metadata-free water bottle did not resolve to its definition amount")
T.equal(effectiveFull.fluidPrimaryType, "Water",
    "metadata-free water bottle did not resolve its definition fluid")

local explicitDefault = {
    id = "water_explicit_default", type = "Base.WaterBottle", stack = 1,
    uses = 1, itemState = {
        fluidAmount = 1, fluidCapacity = 1,
        fluidPrimaryType = "Water",
        fluids = { { type = "Water", amount = 1 } },
    },
}
T.equal(Inventory.NormalizeItemState(explicitDefault), true,
    "redundant default water state was not compacted")
T.equal(explicitDefault.uses, nil,
    "redundant default drainable uses remained in memory")
T.equal(explicitDefault.itemState, nil,
    "redundant default fluid state remained in memory")

local explicitEmpty = {
    id = "water_empty", type = "Base.WaterBottle", stack = 1, uses = 0,
}
T.equal(Inventory.NormalizeItemState(explicitEmpty), true,
    "explicit empty water bottle was not normalized")
T.equal(explicitEmpty.itemState.fluidAmount, 0,
    "explicit empty water bottle did not preserve emptiness")
T.equal(explicitEmpty.itemState.fluidPrimaryType, nil,
    "explicit empty water bottle retained a primary fluid")
local effectiveEmpty = Inventory.ResolveItemState(explicitEmpty)
T.equal(effectiveEmpty.fluidAmount, 0,
    "explicit empty water bottle resolved as full")
T.equal(effectiveEmpty.fluidPrimaryType, nil,
    "explicit empty water bottle resolved an inherited fluid")

local record = {
    id = "npc_fluid_seed",
    inventory = {
        revision = 1, cachedWeight = 0, maxWeight = 8,
        rootMaxWeight = 8, equipped = { primary = nil, secondary = nil,
            bag = nil }, worn = {}, attached = {},
        items = {
            water = { id = "water", type = "Base.WaterBottle", stack = 1,
                container = "root" },
        },
        containers = { root = { maxWeight = 8, items = { "water" } } },
        template = { generatorVersion = 3 },
    },
    runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
}
Inventory.EnsureRecordInventory(record)
T.equal(record.inventory.items.water.itemState, nil,
    "default water bottle stored redundant record state")
T.equal(dirtyReason, nil,
    "default water bottle unexpectedly marked the record dirty")

T.finish("pnc_inventory_fluid_seed_smoke")
