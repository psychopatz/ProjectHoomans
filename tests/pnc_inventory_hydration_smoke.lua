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
        LogWarn = function() end,
    },
    Equipment = {
        CreateItem = function(fullType)
            if fullType == "Base.WaterBottle" then
                local primary = {
                    getFluidTypeString = function() return "Water" end,
                    getFluidType = function() return "Water" end,
                }
                local fluidContainer = {
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
                    getFluidContainer = function() return fluidContainer end,
                }
            end
            return {}
        end,
    },
}

T.load("ProjectHoomans", "shared",
    "PNC/Core/Inventory/PNC_Inventory.lua")
local Inventory = PNC.Inventory
T.equal(type(Inventory.Internal.normalizeHydrationItems), "function",
    "per-item hydration normalizer loads before record hydration")
local lifecycleCalls = {}
local dirtyReasons = {}

PNC.Registry = {
    MarkDirty = function(_, reason)
        dirtyReasons[#dirtyReasons + 1] = reason
    end,
}
Inventory.SyncEquipmentFromInventory = function()
    lifecycleCalls[#lifecycleCalls + 1] = "sync_equipment"
end
Inventory.RebuildCaches = function()
    lifecycleCalls[#lifecycleCalls + 1] = "rebuild_caches"
end
Inventory.ReconcileWaterContainer = function()
    lifecycleCalls[#lifecycleCalls + 1] = "reconcile_water"
end

local function makeRecord(id, items, containers)
    return {
        id = id,
        inventory = {
            revision = 4, cachedWeight = 1, maxWeight = 12,
            rootMaxWeight = 12, equipped = {}, worn = {}, attached = {},
            items = items, containers = containers,
            template = { generatorVersion = 3 },
        },
        runtime = { inventory = { nextItemSerial = 0, opLog = {} } },
    }
end
local record = makeRecord("npc_inventory_hydration", {
    bottle_root = {
        id = "bottle_root", type = "Base.WaterBottle",
        stack = 1, container = "root",
    },
    bottle_crate = {
        id = "bottle_crate", type = "Base.WaterBottle",
        stack = 1, container = "crate",
    },
    invalid_value = "not-an-item",
    invalid_type = { id = "invalid_type", type = "", stack = 1, container = "root" },
}, {
    root = { maxWeight = 12, items = { "ghost", "bottle_root", "bottle_root", "bottle_crate" } },
    crate = { maxWeight = 3, items = { "ghost", "bottle_crate", "bottle_crate" } },
    malformed = false,
    malformed_items = { maxWeight = "bad", items = "not-an-array" },
})

local hydrated = Inventory.EnsureRecordInventory(record, {
    reconcileWaterContainer = false,
})
T.equal(hydrated, record.inventory, "hydration returned the record inventory")
T.equal(Inventory.Internal.countMapEntries(record.inventory.items), 2,
    "invalid item entries were removed")
T.equal(record.inventory.items.invalid_type, nil,
    "unsupported item type was removed")
T.equal(#record.inventory.containers.root.items, 1,
    "root membership discarded stale and duplicate IDs")
T.equal(record.inventory.containers.root.items[1], "bottle_root",
    "root item retained its correct container")
T.equal(#record.inventory.containers.crate.items, 1,
    "crate membership discarded stale and duplicate IDs")
T.equal(record.inventory.containers.crate.items[1], "bottle_crate",
    "crate item retained its correct container")
T.equal(type(record.inventory.containers.malformed), "table",
    "malformed container record was repaired")
T.equal(type(record.inventory.containers.malformed.items), "table",
    "malformed container membership was initialized")
T.equal(type(record.inventory.containers.malformed_items.items), "table",
    "malformed membership list was repaired")
T.equal(record.inventory.containers.crate.maxWeight, 3,
    "valid container capacity was preserved")
T.equal(lifecycleCalls[1], "sync_equipment",
    "equipment synchronization follows item normalization")
T.equal(lifecycleCalls[2], "rebuild_caches",
    "cache rebuild follows equipment synchronization")
T.equal(lifecycleCalls[3], nil,
    "water reconciliation can be disabled")
T.equal(dirtyReasons[1], "inventory_structure_normalized",
    "repaired inventory structure marks its record dirty")

local dirtyCount = #dirtyReasons
Inventory.EnsureRecordInventory(record, { reconcileWaterContainer = false })
T.equal(#dirtyReasons, dirtyCount,
    "a normalized inventory does not repeatedly mark the record dirty")

local orderedRecord = makeRecord("npc_inventory_order", {
    first = { id = "first", type = "Base.Apple", container = "root" },
    second = { id = "second", type = "Base.Apple", container = "root" },
}, { root = { items = { "second", "first" } } })
Inventory.EnsureRecordInventory(orderedRecord, {
    reconcileWaterContainer = false,
})
T.equal(orderedRecord.inventory.containers.root.items[1], "second",
    "hydration preserves existing valid container order")
T.equal(orderedRecord.inventory.containers.root.items[2], "first",
    "hydration retains all valid ordered memberships")

local auditEvents = {}
PNC.PerformanceScalingDiagnostics = {
    InventoryAuditEnabled = true,
    LogInventoryAudit = function(eventName, fields)
        auditEvents[#auditEvents + 1] = {
            eventName = eventName,
            fields = fields,
        }
    end,
}
local auditRecord = makeRecord("npc_diag_smoke", {
    SENTINEL_ITEM_ID_DO_NOT_LOG = {
        id = "SENTINEL_ITEM_ID_DO_NOT_LOG", type = "Base.Apple",
        stack = 1, container = "root",
    },
}, {
    root = { maxWeight = 12, items = { "stale_membership" } },
})
Inventory.EnsureRecordInventory(auditRecord, {
    reconcileWaterContainer = false,
})
T.equal(#auditEvents, 1,
    "enabled audit logs a repaired record")
T.equal(auditEvents[1].eventName, "record_hydrated",
    "hydration audit uses its bounded event name")
local auditFields = table.concat(auditEvents[1].fields, " ")
T.contains(auditFields, "npc=npc_diag_smoke",
    "hydration audit identifies the NPC")
T.contains(auditFields, "items_before=1",
    "hydration audit reports item count before normalization")
T.contains(auditFields, "membership_changed=true",
    "hydration audit reports repaired membership")
T.equal(string.find(auditFields, "SENTINEL_ITEM_ID_DO_NOT_LOG", 1, true), nil,
    "hydration audit omits raw item IDs")
PNC.PerformanceScalingDiagnostics.InventoryAuditEnabled = false
local disabledAuditRecord = makeRecord("npc_diag_disabled", {}, {
    root = { maxWeight = 12, items = { "stale_membership" } },
})
Inventory.EnsureRecordInventory(disabledAuditRecord, {
    reconcileWaterContainer = false,
})
T.equal(#auditEvents, 1,
    "disabled inventory audit does not emit repair events")

local malformedContainers = { containers = { broken = false } }
Inventory.Internal.removeItemFromAllContainers(malformedContainers, "missing")
local repairedContainer = Inventory.Internal.ensureContainer(
    malformedContainers,
    "broken",
    2
)
T.equal(type(repairedContainer), "table",
    "container helpers repair malformed entries")
T.equal(type(repairedContainer.items), "table",
    "repaired container has a membership list")

T.finish("pnc_inventory_hydration_smoke")
