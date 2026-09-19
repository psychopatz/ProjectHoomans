local T = require "tests/support/test"

T.addPackagePaths()

local dirtyReasons = {}
local auditEvents = {}
local warnings = {}
local bridgeCalls = 0
PNC = {
    Const = { GENERATOR_VERSION = 3 },
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, entry in pairs(value) do
                output[key] = PNC.Core.DeepCopy(entry)
            end
            return output
        end,
        LogWarn = function(message)
            warnings[#warnings + 1] = message
        end,
    },
    PerformanceScalingDiagnostics = {
        InventoryAuditEnabled = true,
        LogInventoryAudit = function(eventName, fields)
            auditEvents[#auditEvents + 1] = {
                eventName = eventName,
                fields = fields,
            }
        end,
    },
    Equipment = {
        CreateItem = function() return {} end,
        EnsureRecordEquipment = function(record) return record.equipment end,
        StoreVisualStateInItemState = function(item, visual)
            item.itemState = item.itemState or {}
            item.itemState.visualState = visual
        end,
    },
    Registry = {
        MarkDirty = function(_, reason)
            dirtyReasons[#dirtyReasons + 1] = reason
        end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Inventory/PNC_Inventory.lua")
local Inventory = PNC.Inventory
T.equal(type(Inventory.Internal.EquipmentImportAudit), "table",
    "equipment import diagnostics load before the sync service")
T.equal(type(Inventory.Internal.EquipmentImportAudit.LogEquipmentSync), "function",
    "equipment import diagnostics expose their bounded logger")
Inventory.CoreBridge = {
    refreshCanonical = function()
        bridgeCalls = bridgeCalls + 1
    end,
}
local getContainerProfile = Inventory.Internal.getContainerProfile
Inventory.Internal.getContainerProfile = function(fullType)
    if fullType == "Base.Bag" then
        return {
            capacity = 20,
            weightReduction = 0.5,
            wearableSlot = "Back",
        }
    end
    return getContainerProfile(fullType)
end

local record = {
    id = "npc_inventory_sync",
    equipment = {
        primaryFullType = "Base.HandAxe",
        primaryVisual = { fullType = "Base.HandAxe", marker = "visual" },
        secondaryFullType = "Base.HandTorch",
        worn = { Torso = "Base.Jacket" },
        attached = { Back = "Base.Bag", Belt = "Base.Wallet" },
    },
    inventory = {
        revision = 7,
        maxWeight = 12,
        items = {
            old_primary = {
                id = "old_primary", type = "Base.HandAxe",
                container = "root", equipSlot = "primary",
            },
            old_bag = {
                id = "old_bag", type = "Base.Bag", container = "root",
                wornSlot = "Back", bagContainer = "bag_old",
                maxWeight = 20,
            },
            keep_root = {
                id = "keep_root", type = "Base.WaterBottle",
                container = "root", itemState = { fluidAmount = 0.5 },
            },
            keep_bag = {
                id = "keep_bag", type = "Base.WaterBottle",
                container = "bag_old", preferredContainer = "bag",
            },
            selected_water = {
                id = "selected_water", type = "Base.WaterBottle",
                container = "bag_old", preferredContainer = "bag",
                equipSlot = "waterContainer",
                itemState = { fluidPrimaryType = "Water" },
            },
        },
        containers = {
            root = { maxWeight = 12, items = { "old_primary", "old_bag", "keep_root" } },
            bag_old = { maxWeight = 20, items = { "keep_bag", "selected_water" } },
        },
        equipped = { primary = "old_primary", bag = "old_bag", waterContainer = "selected_water" },
        worn = { Back = "old_bag" },
        attached = {},
    },
    runtime = { inventory = { nextItemSerial = 200, opLog = {} } },
}

local synced = Inventory.SyncFromEquipment(record, "smoke_test")
T.equal(synced, record.inventory, "sync returns the installed inventory")
T.equal(record.inventory.revision, 8,
    "sync advances the prior revision instead of resetting it")
T.equal(record.inventory.items.old_primary, nil,
    "equipment state replaces the previously equipped item")
T.equal(record.inventory.items.keep_root.itemState.fluidAmount, 0.5,
    "unequipped root item state is preserved")
local newBag = record.inventory.items[record.inventory.worn.Back]
T.equal(newBag.type, "Base.Bag", "attached back bag is projected into inventory")
T.equal(newBag.maxWeight, 20, "bag profile capacity is preserved")
T.equal(record.inventory.items.keep_bag.container, newBag.bagContainer,
    "unequipped bag item moves into the new equipped bag")
T.equal(record.inventory.items.selected_water.container, newBag.bagContainer,
    "selected water container follows the new equipped bag")
T.equal(record.inventory.equipped.waterContainer, "selected_water",
    "selected water container remains equipped")
T.equal(record.inventory.items[record.inventory.equipped.primary].type,
    "Base.HandAxe", "primary equipment is projected")
T.equal(record.inventory.items[record.inventory.equipped.primary]
    .itemState.visualState.marker, "visual",
    "primary visual state is stored with the logical item")
T.equal(record.inventory.items[record.inventory.equipped.secondary].type,
    "Base.HandTorch", "secondary equipment is projected")
T.equal(record.inventory.items[record.inventory.attached.Belt].type,
    "Base.Wallet", "attached equipment is projected")
T.equal(dirtyReasons[1], "inventory", "successful sync marks the registry record dirty")
T.equal(bridgeCalls, 1, "cache rebuild reaches the canonical inventory bridge")

local auditFields = table.concat(auditEvents[1].fields, " ")
T.equal(auditEvents[1].eventName, "equipment_sync",
    "sync emits the bounded diagnostic event")
T.contains(auditFields, "reason=smoke_test", "sync reason is diagnosed")
T.contains(auditFields, "revision_before=7", "prior revision is diagnosed")
T.contains(auditFields, "revision_after=8", "new revision is diagnosed")
T.equal(string.find(auditFields, "keep_bag", 1, true), nil,
    "diagnostic fields omit raw item IDs")

local invalidWater = {
    id = "npc_invalid_water",
    equipment = { worn = {}, attached = {} },
    inventory = {
        revision = 2,
        items = {
            broken_water = {
                id = "broken_water", container = "root",
                equipSlot = "waterContainer",
            },
        },
        containers = { root = { items = { "broken_water" } } },
        equipped = { waterContainer = "broken_water" },
        worn = {}, attached = {},
    },
    runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
}
local invalidWaterSync = Inventory.SyncFromEquipment(invalidWater, "invalid_water")
T.equal(invalidWaterSync, invalidWater.inventory,
    "invalid selected water payload is skipped without aborting sync")
T.equal(invalidWater.inventory.equipped.waterContainer, nil,
    "invalid selected water item is not retained as an equipment reference")

local unavailableInventory = {
    revision = 3,
    items = { keep = { id = "keep", type = "Base.WaterBottle", container = "root" } },
    containers = { root = { items = { "keep" } } },
    equipped = {}, worn = {}, attached = {},
}
local unavailableEquipment = {
    id = "npc_equipment_unavailable",
    inventory = unavailableInventory,
    runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
}
PNC.Equipment.EnsureRecordEquipment = function() return nil end
local unavailableResult, unavailableReason = Inventory.SyncFromEquipment(
    unavailableEquipment,
    "missing_equipment"
)
T.equal(unavailableResult, nil, "missing equipment adapter fails safely")
T.equal(unavailableReason, "equipment_unavailable",
    "missing equipment adapter returns an explicit reason")
T.equal(unavailableEquipment.inventory, unavailableInventory,
    "failed sync leaves the previous inventory installed")
T.equal(#warnings, 1, "missing equipment adapter is reported")

T.finish("pnc_inventory_equipment_sync_smoke")
