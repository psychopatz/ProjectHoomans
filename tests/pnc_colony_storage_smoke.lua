local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
local SERVER = T.path("ProjectHoomans", "server", "")
local CLIENT = T.path("ProjectHoomans", "client", "")
local CORE = T.path("PsychopatzCore", "common", "")
T.addPackagePaths()

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
package.preload["PsychopatzCore/World/PC_ZoneRegistry"] = function()
    return { get = function(id)
        if id == "zone_a" then
            return { geometry = { minX = 0, maxX = 20,
                minY = 0, maxY = 20 } }
        end
    end }
end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return { containsXY = function(region, x, y)
        return x >= region.minX and x <= region.maxX
            and y >= region.minY and y <= region.maxY
    end }
end

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
        Now = function() return 1000 end,
        GenerateID = function(prefix) return prefix .. ":test" end,
        ResolvePlayerByUsername = function() return nil end,
    },
    Inventory = { Internal = {} },
    Registry = { Get = function() return nil end },
    Equipment = {},
    BaseService = { GetForColony = function(id)
        if id == "colony_faction_a" or id == "colony_faction_b" then
            return { id = "base_" .. id, baseZoneId = "zone_a" }
        end
    end },
}
local stockpileBuilt = true
PNC.FacilityValidationService = {
    GetStockpile = function(_, builtOnly)
        return stockpileBuilt and builtOnly == true and {
            id = "facility:stockpile", constructionState = "BUILT",
        } or nil
    end,
}
PNC.Inventory.Internal.getItemWeight = function() return 0.1 end
PNC.Inventory.Internal.countMapEntries = function(value)
    local count = 0
    for _, _ in pairs(value or {}) do count = count + 1 end
    return count
end
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

T.equal(Definitions.GetCapacity(1), 200, "tier one capacity")
T.equal(Definitions.GetCapacity(2), 250, "tier two capacity")

local playerItem = item("Base.Bandage", 0.1)
local playerContainer = container({ playerItem })
local playerA = {
    factionKey = "A",
    getUsername = function() return "player_a" end,
    getInventory = function() return playerContainer end,
    getAccessLevel = function() return "" end,
    isEquipped = function() return false end,
    getX = function() return 10 end,
    getY = function() return 10 end,
}
local playerB = {
    factionKey = "B",
    getUsername = function() return "player_b" end,
    getInventory = function() return container({}) end,
    getAccessLevel = function() return "" end,
    isEquipped = function() return false end,
    getX = function() return 10 end,
    getY = function() return 10 end,
}

local storageA = Repository.GetPrimary("faction_a", "colony_faction_a")
local storageB = Repository.GetPrimary("faction_b", "colony_faction_b")
T.truthy(storageA and storageB and storageA ~= storageB, "faction isolation")
T.equal(storageA.tier, 1, "initial tier")
T.equal(storageA.inventory:getLogicalItemCount(), 0, "initial empty storage")
local access = Service.BuildPlayerAccess(playerA, storageA)
T.equal(access.hasStockpile, true,
    "built stockpile facility grants storage access")
stockpileBuilt = false
access = Service.BuildPlayerAccess(playerA, storageA)
T.equal(access.hasStockpile, false,
    "reconstructing stockpile disables storage access")
stockpileBuilt = true

local awayItem = item("Base.Bandage", 0.1)
local awayContainer = container({ awayItem })
local awayPlayer = {
    factionKey = "A",
    getUsername = function() return "player_away" end,
    getInventory = function() return awayContainer end,
    getAccessLevel = function() return "" end,
    isEquipped = function() return false end,
    getX = function() return 30 end,
    getY = function() return 30 end,
}
local awayOK, awayReason = Service.RequestPlayerDeposit(awayPlayer, {
    requestId = "deposit:away",
    itemIDs = { tostring(awayItem:getID()) },
})
T.equal(awayOK, false, "away player storage remains read only")
T.equal(awayReason, "outside_base", "away player rejection reason")
T.equal(#awayContainer.values, 1, "read-only rejection preserves inventory")

PNC.ResearchService = { Queries = { HasTechnology = function() return false end } }
local upgraded, upgradeReason = Service.Upgrade(playerB, {
    storageId = storageB.id,
})
T.equal(upgraded, false, "storage upgrade is research gated")
T.equal(upgradeReason, "TECHNOLOGY_REQUIRED", "storage research gate reason")
PNC.ResearchService.Queries.HasTechnology = function(_, technologyId)
    return technologyId == "storage:2"
end
upgraded = Service.Upgrade(playerB, { storageId = storageB.id })
T.equal(upgraded, true, "researched storage capability permits Base upgrade")
T.equal(storageB.tier, 2, "Base storage action applies researched tier")

local ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:1",
    itemIDs = { tostring(playerItem:getID()) },
})
T.equal(ok, true, "player deposit")
T.equal(reason, "deposited", "player deposit reason")
T.equal(#playerContainer.values, 0, "player source removal")
T.equal(storageA.inventory:getLogicalItemCount(), 1, "storage destination add")
T.equal(storageB.inventory:getLogicalItemCount(), 0, "other faction unchanged")
T.equal(provisionWakeups[#provisionWakeups], "faction_a",
    "storage deposit immediately wakes provision scheduler")
T.equal(#activity(storageA), 1, "successful deposit journal entry")
T.equal(activity(storageA)[1][Journal.FIELD.OPERATION],
    Journal.OPERATION.STORE, "deposit journal operation")
T.equal(activity(storageA)[1][Journal.FIELD.ACTOR], "player_a",
    "deposit journal actor")

ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:1",
    itemIDs = { tostring(playerItem:getID()) },
})
T.equal(ok, false, "duplicate request rejected")
T.equal(reason, "duplicate_request", "duplicate request reason")
T.equal(#activity(storageA), 1,
    "rejected transaction entered activity journal")

local foreignItem = item("Base.Hammer", 1)
playerContainer:AddItem(foreignItem)
ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:foreign",
    storageId = storageB.id,
    itemIDs = { tostring(foreignItem:getID()) },
})
T.equal(ok, false, "foreign storage rejected")
T.equal(reason, "storage_not_owned", "foreign storage reason")
T.equal(#playerContainer.values, 1, "foreign rejection preserved source")

storageA.inventory:clear()
local heavy = item("Base.HeavyTest", 201)
playerContainer:AddItem(heavy)
ok, reason = Service.RequestPlayerDeposit(playerA, {
    requestId = "deposit:heavy",
    itemIDs = { tostring(heavy:getID()) },
})
T.equal(ok, false, "capacity rejection")
T.equal(reason, "storage_full", "capacity rejection reason")
T.equal(#playerContainer.values, 2, "capacity rollback preserved source")
T.equal(storageA.inventory:getLogicalItemCount(), 0, "capacity rollback preserved destination")

local nails = item("Base.Nails", 0.01)
T.truthy(Inventory.deposit(storageA.inventory, nails, 100), "nails batch deposit")
T.equal(storageA.inventory:getLogicalItemCount(), 100, "nails logical quantity")
T.equal(storageA.inventory:getRecordCount(), 1, "nails batched record")
local beforeWeight = storageA.inventory:getWeight()
local beforeRecords = storageA.inventory:getRecordCount()
ok = Service.DebugUpgrade(playerA, { storageId = storageA.id })
T.equal(ok, true, "debug tier upgrade")
T.equal(storageA.tier, 2, "upgraded tier")
T.equal(storageA.inventory.maxWeight, 250, "upgraded capacity")
T.equal(storageA.inventory:getWeight(), beforeWeight, "upgrade retained contents")
T.equal(storageA.inventory:getRecordCount(), beforeRecords, "upgrade retained records")

Repository.MarkDirty()
T.truthy(Repository.Save(), "storage save")
Repository.ByID = {}
Repository.PrimaryByFaction = {}
Repository.Loaded = false
T.truthy(Repository.Load(), "storage load")
local loaded = Repository.Get(storageA.id)
T.truthy(loaded, "storage persisted")
T.equal(loaded.tier, 2, "persisted tier")
T.equal(loaded.inventory:getLogicalItemCount(), 100, "persisted contents")
T.equal(loaded.inventory.maxWeight, 250, "capacity rederived from tier")
T.equal(#activity(loaded), 1, "activity journal persisted")

local snapshot = Service.BuildSnapshot(playerA)
T.equal(snapshot.logicalItemCount, 100, "snapshot logical quantity")
T.equal(#snapshot.rows, 1, "snapshot batched row")
T.equal(snapshot.rows[1].quantity, 100, "snapshot row quantity")

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
T.equal(ok, true, "player withdrawal: " .. tostring(reason))
T.equal(reason, "withdrawn", "player withdrawal reason")
T.equal(loaded.inventory:getLogicalItemCount(), 95,
    "withdrawal removes storage quantity once")
T.equal(#playerContainer.values, 7,
    "withdrawal materializes items in player inventory")
T.equal(#activity(loaded), 2, "withdrawal journal entry")
T.equal(activity(loaded)[2][Journal.FIELD.OPERATION],
    Journal.OPERATION.TAKE, "withdrawal journal operation")
T.equal(activity(loaded)[2][Journal.FIELD.QUANTITY], 5,
    "withdrawal journal quantity")

ok, reason = Service.RequestPlayerWithdrawal(playerA, {
    requestId = "withdraw:stale",
    storageId = loaded.id,
    inventoryRevision = loaded.inventory.revision - 1,
    records = {{ recordIndex = 1, quantity = 1 }},
})
T.equal(ok, false, "stale withdrawal rejected")
T.equal(reason, "revision_conflict", "stale withdrawal reason")

local failingContainer = container({})
failingContainer.AddItem = function() return nil end
local failingPlayer = {
    factionKey = "A",
    getUsername = function() return "player_failure" end,
    getInventory = function() return failingContainer end,
    getAccessLevel = function() return "" end,
    getX = function() return 10 end,
    getY = function() return 10 end,
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
T.equal(ok, false, "failed player destination rejects withdrawal")
T.equal(loaded.inventory:getLogicalItemCount(), beforeRollback,
    "failed withdrawal restores storage")
T.equal(next(loaded.inventory.reservations), nil,
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
T.equal(ok, true, "debug add test item")
T.equal(loaded.inventory:count("Base.Nails"), 100,
    "debug add item did not reach storage")

for index = 1, 12 do
    T.truthy(Service.RecordActivity(loaded, {
        operation = "STORE",
        actor = "worker_" .. tostring(index),
        fullType = "Base.Nails",
        quantity = index,
        reason = index == 12 and "fishing" or nil,
    }), "public journal API")
end
T.equal(#activity(loaded), 10, "journal hard cap")
T.equal(activity(loaded)[1][Journal.FIELD.ACTOR], "worker_3",
    "journal discarded oldest entry")
T.equal(activity(loaded)[10][Journal.FIELD.REASON], "fishing",
    "optional extensible reason token")
local serialized = Repository.SerializeStorage(loaded)
T.equal(serialized.activityJournal[1], Journal.VERSION,
    "journal serialization version")
T.equal(#serialized.activityJournal[2].entries, 10,
    "serialized journal hard cap")
T.equal(#serialized.activityJournal[2].entries[1], 6,
    "compact semantic journal entry")
local legacyID = "legacy_storage"
T.truthy(Journal.Deserialize({ 1, {{
    Journal.OPERATION.STORE, 123, "legacy_actor",
    serialized.activityJournal[2].entries[1][4], 2, "scavenging",
}} }, legacyID), "legacy journal migration")
T.equal(Journal.Snapshot(legacyID)[1][Journal.FIELD.ACTOR], "legacy_actor",
    "legacy journal actor retained")
snapshot = Service.BuildSnapshot(playerA)
T.equal(#snapshot.activity, 10, "snapshot activity cap")
T.equal(snapshot.access.writable, true, "snapshot exposes writable base access")
getText = function(key) return key end
getItemNameFromFullType = function(fullType)
    return fullType == "Base.Nails" and "Nails" or fullType
end
local ActivityPresentation = require
    "PNC/UI/Communities/PNC_ColonyStorageActivityPresentation"
local activityRows = ActivityPresentation.Rows(snapshot.activity)
T.equal(#activityRows, 10, "activity presentation row count")
T.truthy(string.find(activityRows[1].message,
    "worker_12 stored 12 x Nails", 1, true),
    "structured activity translated at render time")
T.truthy(string.find(activityRows[1].message, "(fishing)", 1, true),
    "activity reason presentation")

PNC.Inventory.EnsureRecordInventory = function(record)
    return record.inventory
end
PNC.Inventory.RemoveItems = function(record, ids)
    for _, id in ipairs(ids or {}) do
        if not record.inventory.items[id] then return false end
    end
    for _, id in ipairs(ids or {}) do
        record.inventory.items[id] = nil
    end
    record.inventory.revision = record.inventory.revision + 1
    return true
end
PNC.Inventory.ApplyDelta = function(record, operations)
    for _, operation in ipairs(operations or {}) do
        local compact = record.inventory.items[operation.itemID]
        if not compact then return false end
        if operation.stack then compact.stack = operation.stack end
    end
    record.inventory.revision = record.inventory.revision + 1
    return true
end
PNC.Inventory.RebuildCaches = function() return true end
local courierNPC = {
    id = "npc:courier", name = "Courier", alive = true,
    runtime = {}, inventory = {
        revision = 0, cachedWeight = 0, maxWeight = 20,
        equipped = {}, worn = {}, attached = {},
        items = {
            cargo = { id = "cargo", type = "Base.Bandage",
                container = "root", stack = 2 },
            favorite = { id = "favorite", type = "Base.Hammer",
                container = "root", stack = 1, fav = true },
        },
        containers = { root = {
            id = "root", items = { "cargo", "favorite" },
            maxWeight = 20,
        } },
    },
}
PNC.Registry.Get = function(id)
    return id == courierNPC.id and courierNPC or nil
end
PNC.Registry.GetLiveZombie = function() return nil end
PNC.Registry.MarkDirty = function() end
PNC.CompanionCommands = {
    IsOwnedByPlayer = function(record)
        return record == courierNPC
    end,
}
local courierAtHome = false
PNC.HomeDutyService = {
    IsAtHome = function() return courierAtHome end,
    SendHome = function()
        return true, "RETURNING_HOME", { journeyId = "courier:journey" }
    end,
}
local courierOK, courierReason = Service.RequestNPCCourierDeposit(playerA, {
    requestId = "courier:1", npcId = courierNPC.id,
    storageId = loaded.id,
})
T.equal(courierOK, true, "courier job accepted away from home")
T.equal(courierReason, "courier_returning_home", "courier return status")
T.equal(courierNPC.runtime.storageCourier.state, "RETURNING_HOME",
    "courier exposes in-progress state")
courierAtHome = true
local completed, completionReason = Service.CompleteNPCCourier(courierNPC)
T.equal(completed, true, "courier deposits after reaching home")
T.equal(completionReason, "deposited", "courier completion reason")
T.equal(courierNPC.runtime.storageCourier.state, "COMPLETED",
    "courier exposes completion state")
T.equal(courierNPC.inventory.items.cargo, nil,
    "courier removes deposited compact cargo")
T.truthy(courierNPC.inventory.items.favorite,
    "courier preserves favorite items")

ok, reason = Service.DebugAction(playerA, {
    storageId = loaded.id,
    debugAction = "add",
    fullType = "Base.Money",
    quantity = 2,
})
T.equal(ok, true, "production activity test money")
PNC.SupplyInventory = { Commands = {
    AddCoreRecords = function(_, records)
        local ids = {}
        for index = 1, #records do ids[index] = "carried:" .. tostring(index) end
        return true, nil, { itemIDs = ids }
    end,
} }
local productionReservation = T.truthy(Service.ReserveProductionMaterials(
    loaded.id, {{ itemTypes = { "Base.Money" }, amount = 2 }},
    "construction:test"))
local collected, collection = Service.CollectProductionReservation(
    productionReservation.id, "work:test", "construction_materials",
    loaded.id, { id = "npc:builder", name = "Ahmad Stahl" })
T.equal(collected, true, "NPC collected construction money")
T.equal(#collection.itemIds, 1, "collected stack projected to NPC inventory")
local productionActivity = activity(loaded)
local latestProductionActivity = productionActivity[#productionActivity]
T.equal(latestProductionActivity[Journal.FIELD.OPERATION],
    Journal.OPERATION.TAKE, "production collection journal operation")
T.equal(latestProductionActivity[Journal.FIELD.ACTOR], "Ahmad Stahl",
    "production collection journal actor")
T.equal(latestProductionActivity[Journal.FIELD.QUANTITY], 2,
    "production collection journal quantity")
T.equal(latestProductionActivity[Journal.FIELD.REASON], "construction",
    "production collection journal reason")
T.finish("pnc_colony_storage_smoke")

T.finish("pnc_colony_storage_smoke")
