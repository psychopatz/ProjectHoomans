if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageProductionInternal =
    PNC.ColonyStorageProductionInternal or {}

local Service = PNC.ColonyStorageService
local H = PNC.ColonyStorageProductionInternal
local Repository = PNC.ColonyStorageRepository
local Internal = Service.Internal
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

function Service.ReturnCollectedProductionRecords(storageId, worker,
    itemIds, records)
    local storage = H.StorageFor(storageId)
    if not storage or not worker then return false, "storage_not_found" end
    local commands = PNC.SupplyInventory and PNC.SupplyInventory.Commands
    if not commands or not commands.RemoveCoreItemIds then
        return false, "worker_inventory_unavailable"
    end
    local requiredWeight = 0
    for index = 1, #(records or {}) do
        requiredWeight = requiredWeight
            + (tonumber(records[index][C.UNIT_WEIGHT]) or 0)
                * (tonumber(records[index][C.QUANTITY]) or 1)
    end
    if storage.inventory:getWeight() + requiredWeight > storage.inventory.maxWeight then
        return false, "storage_full"
    end
    local removed, reason = commands.RemoveCoreItemIds(worker, itemIds,
        "production_input_return")
    if not removed then return false, reason end
    for index = 1, #(records or {}) do
        local ok, addReason = storage.inventory:add(records[index])
        if not ok then return false, addReason end
    end
    storage.revision = storage.revision + 1
    H.RecordProductionActivity(storage, "STORE",
        tostring(worker.name or worker.id), records, nil, "production_return")
    Repository.MarkDirty()
    return true
end

function Service.DepositProductionItems(storageId, products, provenance,
    transactionId, stage)
    local storage = H.StorageFor(storageId)
    if not storage then return false, "storage_not_found" end
    if H.TransactionStage(storage, transactionId, stage) then
        return true, "already_committed"
    end
    local records = {}
    for index = 1, #(products or {}) do
        local product = products[index]
        local item
        if InventoryItemFactory and InventoryItemFactory.CreateItem then
            local ok
            ok, item = pcall(InventoryItemFactory.CreateItem, product.fullType)
            if not ok then item = nil end
        end
        if not item then return false, "item_type_unavailable" end
        if provenance and item.getModData then
            local data = item:getModData()
            data.PNC = data.PNC or {}
            data.PNC.production = { v = 1, rid = provenance.recipeId }
        end
        if type(product.modData) == "table" and item.getModData then
            local target = item:getModData()
            for key, value in pairs(product.modData) do target[key] = value end
        end
        local record, reason = Inventory.encodeItem(item,
            math.max(1, math.floor(tonumber(product.quantity) or 1)))
        if not record then return false, reason end
        records[#records + 1] = record
    end
    local requiredWeight = 0
    for index = 1, #records do
        requiredWeight = requiredWeight + (tonumber(records[index][C.UNIT_WEIGHT]) or 0)
            * (tonumber(records[index][C.QUANTITY]) or 1)
    end
    if storage.inventory:getWeight() + requiredWeight > storage.inventory.maxWeight then
        return false, "storage_full"
    end
    local backup = Inventory.Serializer.serialize(storage.inventory)
    for index = 1, #records do
        local ok, reason = storage.inventory:add(records[index])
        if not ok then
            storage.inventory = Inventory.Serializer.deserialize(backup)
            return false, reason
        end
    end
    storage.revision = storage.revision + 1
    H.MarkTransactionStage(storage, transactionId, stage)
    Repository.MarkDirty()
    return true, records
end

