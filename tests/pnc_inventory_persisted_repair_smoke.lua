local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
    { "PsychopatzCore", "shared" },
})

local inventory = { Internal = {} }
local repairCalls = 0
local dirtyReasons = {}

inventory.Internal.normalizeLegacyBagSlot = function() end
inventory.Internal.getRuntimeState = function() return {} end
inventory.Internal.refreshNextItemSerial = function() end
inventory.Internal.buildBaseCarryWeight = function() return 8 end
inventory.Internal.normalizeString = function(value)
    if value == nil or tostring(value) == "" then return nil end
    return tostring(value)
end
inventory.Internal.ensureIdentityCard = function()
    return {}, false
end
inventory.Internal.ensureFactionDogTag = function(record, inv)
    repairCalls = repairCalls + 1
    local item = inv.items.dogtag
    if item then return item, false end
    item = {
        id = "dogtag",
        type = "Base.Necklace_DogTag",
        templateKey = "tmpl:faction_dogtag:0",
        customName = "Dog Tags: patz Coalition",
    }
    inv.items.dogtag = item
    return item, true
end
inventory.Internal.normalizeHydrationItems = function()
    return false, false, 0
end
inventory.Internal.rebuildContainerMembership = function() return false end
inventory.Internal.countMapEntries = function(value)
    local count = 0
    for _ in pairs(type(value) == "table" and value or {}) do
        count = count + 1
    end
    return count
end

PNC = {
    Inventory = inventory,
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local copy = {}
            for key, entry in pairs(value) do
                copy[key] = PNC.Core.DeepCopy(entry)
            end
            return copy
        end,
    },
    Const = { GENERATOR_VERSION = 4 },
    Registry = {
        MarkDirty = function(_, reason)
            dirtyReasons[#dirtyReasons + 1] = reason
        end,
    },
    Factions = {
        Get = function(id)
            return id == "faction_1"
                and { id = id, name = "patz Coalition" }
                or nil
        end,
    },
}

inventory.ApplyDelta = function(record, operations)
    for _, operation in ipairs(operations) do
        if operation.op == "remove" then
            record.inventory.items[operation.itemID] = nil
        elseif operation.op == "add" then
            local item = PNC.Core.DeepCopy(operation.item)
            record.inventory.items[item.id] = item
        end
    end
    dirtyReasons[#dirtyReasons + 1] = "inventory"
    return true, operations
end

local persistedInventory = {
    items = {},
    containers = { root = { items = {} } },
    template = { generatorVersion = 4 },
}
inventory.Deserialize = function(record)
    record.inventory = persistedInventory
    return persistedInventory
end
inventory.SyncEquipmentFromInventory = function() end
inventory.RebuildCaches = function() end
inventory.ReconcileWaterContainer = function() end
inventory.CreateFromTemplate = function(record)
    record.inventory = { items = {}, containers = {} }
    return record.inventory
end

T.load(T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/Equipment/PNC_Inventory_Hydration.lua"
))

local record = {
    id = "npc_jaime",
    name = "Jaime patz",
    affiliation = { factionID = "faction_1" },
    persistedInventory = {
        2,
        "BASELINE_DELTA",
        17,
        { generatorVersion = 4 },
        { 1, { "tmpl:faction_dogtag:0" }, {} },
    },
}

local inv = inventory.EnsureRecordInventory(record)
T.truthy(inv.items.dogtag,
    "persisted baseline delta removal is repaired on hydration")
T.equal(repairCalls, 1,
    "persisted hydration performs the canonical identity repair")
T.truthy(#dirtyReasons > 0,
    "persisted identity repair marks the authoritative record dirty")
T.equal(record.persistedInventory, nil,
    "persisted payload is consumed after hydration")

local secondRecord = {
    id = "npc_jaime_live",
    name = "Jaime patz",
    affiliation = { factionID = "faction_1" },
    inventory = {
        items = {},
        containers = { root = { items = {} } },
        template = { generatorVersion = 4 },
    },
}
inventory.EnsureRecordInventory(secondRecord)
T.truthy(secondRecord.inventory.items.dogtag,
    "current generator inventories also repair a missing current dogtag")

T.finish("pnc_inventory_persisted_repair_smoke")
