local SHARED = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local SERVER = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
local CLIENT = "Contents/mods/ProjectHoomans/42.20/media/lua/client/"
local CORE = "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/"
package.path = SHARED .. "?.lua;" .. SERVER .. "?.lua;" .. CLIENT
    .. "?.lua;" .. CORE .. "?.lua;" .. package.path

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function truthy(value, label)
    if not value then error(label or "expected truthy value") end
end

local modData = {}
ModData = {
    getOrCreate = function(key)
        modData[key] = modData[key] or {}
        return modData[key]
    end,
}
isServer = function() return false end
isClient = function() return false end
isDebugEnabled = function() return true end

PNC = {
    Const = {
        INVENTORY_TRANSFER_MAX_ITEMS = 64,
        INVENTORY_TRANSFER_MAX_QUANTITY = 1024,
    },
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, child in pairs(value) do
                output[key] = PNC.Core.DeepCopy(child)
            end
            return output
        end,
        LogWarn = function() end,
    },
    Inventory = { Internal = {} },
    Registry = { Get = function() return nil end },
    Equipment = {},
}
local provisionWakeups = {}
PNC.ProvisionScheduler = {
    MarkFactionDirty = function(factionID)
        provisionWakeups[#provisionWakeups + 1] = factionID
        return 0
    end,
}

local factions = {
    A = { id = "faction_a" },
    B = { id = "faction_b" },
}
PNC.Factions = {
    GetPlayerFaction = function(player) return factions[player.factionKey] end,
}
PNC.Communities = {
    GetForFaction = function(factionID)
        return {{ id = "colony_" .. factionID, status = "active" }}
    end,
}

local function list(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local nextID = 0
local function item(fullType, weight)
    nextID = nextID + 1
    local value = { fullType = fullType, weight = weight, id = nextID, modData = {} }
    function value:getID() return self.id end
    function value:getFullType() return self.fullType end
    function value:getActualWeight() return self.weight end
    function value:getWeight() return self.weight end
    function value:getModData() return self.modData end
    function value:isFavorite() return false end
    function value:getAge() return 0 end
    function value:getCurrentAmmoCount() return 0 end
    function value:getWetness() return 0 end
    return value
end

local function container(items)
    local value = { values = items }
    function value:getItems() return list(self.values) end
    function value:DoRemoveItem(target)
        for index = #self.values, 1, -1 do
            if self.values[index] == target then
                table.remove(self.values, index)
                return true
            end
        end
        return false
    end
    function value:AddItem(target)
        self.values[#self.values + 1] = target
        target.owner = self
        return target
    end
    for index = 1, #items do
        items[index].owner = value
        items[index].getContainer = function(self) return self.owner end
    end
    return value
end

local Definitions = require "PNC/Core/Colony/Storage/PNC_ColonyStorageDefinitions"
require "PNC/Journals/PNC_JournalRoutes"
local Repository = require "PNC/Colony/Storage/PNC_ColonyStorageRepository"
local Service = require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService"
local Journal = require "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local function activity(storage) return Journal.Snapshot(storage) end

equal(Definitions.GetCapacity(1), 200, "tier one capacity")
equal(Definitions.GetCapacity(2), 250, "tier two capacity")

local playerItem = item("Base.Bandage", 0.1)
local playerContainer = container({ playerItem })
local playerA = {
    factionKey = "A",
    getUsername = function() return "player_a" end,
    getInventory = function() return playerContainer end,
    getAccessLevel = function() return "" end,
    isEquipped = function() return false end,
}
local playerB = {
    factionKey = "B",
    getUsername = function() return "player_b" end,
    getInventory = function() return container({}) end,
    getAccessLevel = function() return "" end,
    isEquipped = function() return false end,
}

local storageA = Repository.GetPrimary("faction_a", "colony_faction_a")
local storageB = Repository.GetPrimary("faction_b", "colony_faction_b")
truthy(storageA and storageB and storageA ~= storageB, "faction isolation")
equal(storageA.tier, 1, "initial tier")
equal(storageA.inventory:getLogicalItemCount(), 0, "initial empty storage")

PNC.ResearchService = { Queries = { HasTechnology = function() return false end } }
local upgraded, upgradeReason = Service.Upgrade(playerB, {
    storageId = storageB.id,
})
equal(upgraded, false, "storage upgrade is research gated")
equal(upgradeReason, "TECHNOLOGY_REQUIRED", "storage research gate reason")
PNC.ResearchService.Queries.HasTechnology = function(_, technologyId)
    return technologyId == "storage:2"
end
upgraded = Service.Upgrade(playerB, { storageId = storageB.id })
equal(upgraded, true, "researched storage capability permits Base upgrade")
equal(storageB.tier, 2, "Base storage action applies researched tier")

local ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:1",
    itemIDs = { tostring(playerItem:getID()) },
})
equal(ok, true, "player deposit")
equal(reason, "deposited", "player deposit reason")
equal(#playerContainer.values, 0, "player source removal")
equal(storageA.inventory:getLogicalItemCount(), 1, "storage destination add")
equal(storageB.inventory:getLogicalItemCount(), 0, "other faction unchanged")
equal(provisionWakeups[#provisionWakeups], "faction_a",
    "storage deposit immediately wakes provision scheduler")
equal(#activity(storageA), 1, "successful deposit journal entry")
equal(activity(storageA)[1][Journal.FIELD.OPERATION],
    Journal.OPERATION.STORE, "deposit journal operation")
equal(activity(storageA)[1][Journal.FIELD.ACTOR], "player_a",
    "deposit journal actor")

ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:1",
    itemIDs = { tostring(playerItem:getID()) },
})
equal(ok, false, "duplicate request rejected")
equal(reason, "duplicate_request", "duplicate request reason")
equal(#activity(storageA), 1,
    "rejected transaction entered activity journal")

local foreignItem = item("Base.Hammer", 1)
playerContainer:AddItem(foreignItem)
ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:foreign",
    storageId = storageB.id,
    itemIDs = { tostring(foreignItem:getID()) },
})
equal(ok, false, "foreign storage rejected")
equal(reason, "storage_not_owned", "foreign storage reason")
equal(#playerContainer.values, 1, "foreign rejection preserved source")

storageA.inventory:clear()
local heavy = item("Base.HeavyTest", 201)
playerContainer:AddItem(heavy)
ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:heavy",
    itemIDs = { tostring(heavy:getID()) },
})
equal(ok, false, "capacity rejection")
equal(reason, "storage_full", "capacity rejection reason")
equal(#playerContainer.values, 2, "capacity rollback preserved source")
equal(storageA.inventory:getLogicalItemCount(), 0, "capacity rollback preserved destination")

local nails = item("Base.Nails", 0.01)
truthy(Inventory.deposit(storageA.inventory, nails, 100), "nails batch deposit")
equal(storageA.inventory:getLogicalItemCount(), 100, "nails logical quantity")
equal(storageA.inventory:getRecordCount(), 1, "nails batched record")
local beforeWeight = storageA.inventory:getWeight()
local beforeRecords = storageA.inventory:getRecordCount()
ok = Service.DebugUpgrade(playerA, { storageId = storageA.id })
equal(ok, true, "debug tier upgrade")
equal(storageA.tier, 2, "upgraded tier")
equal(storageA.inventory.maxWeight, 250, "upgraded capacity")
equal(storageA.inventory:getWeight(), beforeWeight, "upgrade retained contents")
equal(storageA.inventory:getRecordCount(), beforeRecords, "upgrade retained records")

Repository.MarkDirty()
truthy(Repository.Save(), "storage save")
Repository.ByID = {}
Repository.PrimaryByFaction = {}
Repository.Loaded = false
truthy(Repository.Load(), "storage load")
local loaded = Repository.Get(storageA.id)
truthy(loaded, "storage persisted")
equal(loaded.tier, 2, "persisted tier")
equal(loaded.inventory:getLogicalItemCount(), 100, "persisted contents")
equal(loaded.inventory.maxWeight, 250, "capacity rederived from tier")
equal(#activity(loaded), 1, "activity journal persisted")

local snapshot = Service.BuildSnapshot(playerA)
equal(snapshot.logicalItemCount, 100, "snapshot logical quantity")
equal(#snapshot.rows, 1, "snapshot batched row")
equal(snapshot.rows[1].quantity, 100, "snapshot row quantity")

InventoryItemFactory = {
    CreateItem = function(fullType)
        return item(fullType, fullType == "Base.Nails" and 0.01 or 1)
    end,
}
ok, reason = Service.RequestPlayerWithdrawal(playerA, {
    requestId = "withdraw:1",
    storageId = loaded.id,
    inventoryRevision = loaded.inventory.revision,
    playerContainer = "root",
    records = {{ recordIndex = 1, quantity = 5 }},
})
equal(ok, true, "player withdrawal: " .. tostring(reason))
equal(reason, "withdrawn", "player withdrawal reason")
equal(loaded.inventory:getLogicalItemCount(), 95,
    "withdrawal removes storage quantity once")
equal(#playerContainer.values, 7,
    "withdrawal materializes items in player inventory")
equal(#activity(loaded), 2, "withdrawal journal entry")
equal(activity(loaded)[2][Journal.FIELD.OPERATION],
    Journal.OPERATION.TAKE, "withdrawal journal operation")
equal(activity(loaded)[2][Journal.FIELD.QUANTITY], 5,
    "withdrawal journal quantity")

ok, reason = Service.RequestPlayerWithdrawal(playerA, {
    requestId = "withdraw:stale",
    storageId = loaded.id,
    inventoryRevision = loaded.inventory.revision - 1,
    records = {{ recordIndex = 1, quantity = 1 }},
})
equal(ok, false, "stale withdrawal rejected")
equal(reason, "revision_conflict", "stale withdrawal reason")

local failingContainer = container({})
failingContainer.AddItem = function() return nil end
local failingPlayer = {
    factionKey = "A",
    getUsername = function() return "player_failure" end,
    getInventory = function() return failingContainer end,
    getAccessLevel = function() return "" end,
}
local beforeRollback = loaded.inventory:getLogicalItemCount()
local workingFactory = InventoryItemFactory.CreateItem
InventoryItemFactory.CreateItem = function() return nil end
ok, reason = Service.RequestPlayerWithdrawal(failingPlayer, {
    requestId = "withdraw:rollback",
    storageId = loaded.id,
    inventoryRevision = loaded.inventory.revision,
    records = {{ recordIndex = 1, quantity = 2 }},
})
InventoryItemFactory.CreateItem = workingFactory
equal(ok, false, "failed player destination rejects withdrawal")
equal(loaded.inventory:getLogicalItemCount(), beforeRollback,
    "failed withdrawal restores storage")
equal(next(loaded.inventory.reservations), nil,
    "failed withdrawal releases reservations")

PNC.Equipment.CreateItem = function(fullType)
    return item(fullType, fullType == "Base.Nails" and 0.01 or 1)
end
ok, reason = Service.DebugAction(playerA, {
    storageId = loaded.id,
    debugAction = "add",
    fullType = "Base.Nails",
    quantity = 5,
})
equal(ok, true, "debug add test item")
equal(loaded.inventory:count("Base.Nails"), 100,
    "debug add item did not reach storage")

for index = 1, 12 do
    truthy(Service.RecordActivity(loaded, {
        operation = "STORE",
        actor = "worker_" .. tostring(index),
        fullType = "Base.Nails",
        quantity = index,
        reason = index == 12 and "fishing" or nil,
    }), "public journal API")
end
equal(#activity(loaded), 10, "journal hard cap")
equal(activity(loaded)[1][Journal.FIELD.ACTOR], "worker_3",
    "journal discarded oldest entry")
equal(activity(loaded)[10][Journal.FIELD.REASON], "fishing",
    "optional extensible reason token")
local serialized = Repository.SerializeStorage(loaded)
equal(serialized.activityJournal[1], Journal.VERSION,
    "journal serialization version")
equal(#serialized.activityJournal[2].entries, 10,
    "serialized journal hard cap")
equal(#serialized.activityJournal[2].entries[1], 6,
    "compact semantic journal entry")
local legacyID = "legacy_storage"
truthy(Journal.Deserialize({ 1, {{
    Journal.OPERATION.STORE, 123, "legacy_actor",
    serialized.activityJournal[2].entries[1][4], 2, "scavenging",
}} }, legacyID), "legacy journal migration")
equal(Journal.Snapshot(legacyID)[1][Journal.FIELD.ACTOR], "legacy_actor",
    "legacy journal actor retained")
snapshot = Service.BuildSnapshot(playerA)
equal(#snapshot.activity, 10, "snapshot activity cap")
getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.Nails" and "Nails" or fullType
end
local ActivityPresentation = require
    "PNC/UI/Communities/PNC_ColonyStorageActivityPresentation"
local activityRows = ActivityPresentation.Rows(snapshot.activity)
equal(#activityRows, 10, "activity presentation row count")
truthy(string.find(activityRows[1].message,
    "worker_12 stored 12 x Nails", 1, true),
    "structured activity translated at render time")
truthy(string.find(activityRows[1].message, "(fishing)", 1, true),
    "activity reason presentation")

ok, reason = Service.DebugAction(playerA, {
    storageId = loaded.id,
    debugAction = "add",
    fullType = "Base.Money",
    quantity = 2,
})
equal(ok, true, "production activity test money")
PNC.SupplyInventory = { Commands = {
    AddCoreRecords = function(_, records)
        local ids = {}
        for index = 1, #records do ids[index] = "carried:" .. tostring(index) end
        return true, nil, { itemIDs = ids }
    end,
} }
local productionReservation = assert(Service.ReserveProductionMaterials(
    loaded.id, {{ itemTypes = { "Base.Money" }, amount = 2 }},
    "construction:test"))
local collected, collection = Service.CollectProductionReservation(
    productionReservation.id, "work:test", "construction_materials",
    loaded.id, { id = "npc:builder", name = "Ahmad Stahl" })
equal(collected, true, "NPC collected construction money")
equal(#collection.itemIds, 1, "collected stack projected to NPC inventory")
local productionActivity = activity(loaded)
local latestProductionActivity = productionActivity[#productionActivity]
equal(latestProductionActivity[Journal.FIELD.OPERATION],
    Journal.OPERATION.TAKE, "production collection journal operation")
equal(latestProductionActivity[Journal.FIELD.ACTOR], "Ahmad Stahl",
    "production collection journal actor")
equal(latestProductionActivity[Journal.FIELD.QUANTITY], 2,
    "production collection journal quantity")
equal(latestProductionActivity[Journal.FIELD.REASON], "construction",
    "production collection journal reason")

print("pnc_colony_storage_smoke: ok")
