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

function H.TransactionStage(storage, transactionId, stage)
    if not storage or not transactionId or not stage then return false end
    local transaction = storage.productionTransactions
        and storage.productionTransactions[tostring(transactionId)] or nil
    return transaction and transaction[tostring(stage)] == true or false
end

function H.MarkTransactionStage(storage, transactionId, stage)
    if not transactionId or not stage then return end
    storage.productionTransactions = storage.productionTransactions or {}
    local transaction = storage.productionTransactions[tostring(transactionId)] or {}
    storage.productionTransactions[tostring(transactionId)] = transaction
    transaction[tostring(stage)] = true
end

function Service.CommitProductionReservation(id, transactionId, stage,
    storageId, actor, reason)
    local reservation = Service.ProductionReservations[tostring(id or "")]
    local storage = reservation and H.StorageFor(reservation.storageId)
        or H.StorageFor(storageId)
    if not reservation and transactionId then
        if H.TransactionStage(storage, transactionId, stage) then
            return true, "already_committed"
        end
    end
    if not reservation or not storage then return false, "reservation_not_found" end
    if H.TransactionStage(storage, transactionId, stage) then return true, "already_committed" end
    local removed = {}
    for index = 1, #reservation.tokens do
        local ok, records = storage.inventory:commitReservation(reservation.tokens[index])
        if not ok then return false, records end
        for recordIndex = 1, #records do removed[#removed + 1] = records[recordIndex] end
    end
    for index = 1, #(reservation.retainedTokens or {}) do
        storage.inventory:releaseReservation(reservation.retainedTokens[index])
    end
    Service.ProductionReservations[reservation.id] = nil
    H.MarkTransactionStage(storage, transactionId, stage)
    storage.revision = storage.revision + 1
    H.RecordProductionActivity(storage, "TAKE", actor, removed, stage, reason)
    Repository.MarkDirty()
    return true, removed
end

-- Live workers physically collect reserved production inputs.  This performs
-- the stockpile removal and compact/native NPC inventory projection as one
-- operation, restoring the stockpile if the worker cannot carry the records.
function Service.CollectProductionReservation(id, transactionId, stage,
    storageId, worker)
    local reservation = Service.ProductionReservations[tostring(id or "")]
    local storage = reservation and H.StorageFor(reservation.storageId)
        or H.StorageFor(storageId)
    if not reservation or not storage then return false, "reservation_not_found" end
    if not worker or not PNC.SupplyInventory
        or not PNC.SupplyInventory.Commands
        or not PNC.SupplyInventory.Commands.AddCoreRecords
    then return false, "worker_inventory_unavailable" end
    local removed = {}
    for index = 1, #reservation.tokens do
        local ok, records = storage.inventory:commitReservation(
            reservation.tokens[index])
        if not ok then
            for restoreIndex = 1, #removed do
                storage.inventory:add(removed[restoreIndex])
            end
            return false, records
        end
        for recordIndex = 1, #records do
            removed[#removed + 1] = records[recordIndex]
        end
    end
    local added, reason, details = PNC.SupplyInventory.Commands.AddCoreRecords(
        worker, removed, "production_input_collection")
    if not added then
        for index = 1, #removed do storage.inventory:add(removed[index]) end
        H.ReleaseTokens(reservation)
        Service.ProductionReservations[reservation.id] = nil
        return false, reason
    end
    for index = 1, #(reservation.retainedTokens or {}) do
        storage.inventory:releaseReservation(reservation.retainedTokens[index])
    end
    Service.ProductionReservations[reservation.id] = nil
    H.MarkTransactionStage(storage, transactionId, stage)
    storage.revision = storage.revision + 1
    H.RecordProductionActivity(storage, "TAKE",
        tostring(worker.name or worker.id), removed, stage)
    Repository.MarkDirty()
    return true, { itemIds = details and details.itemIDs or {}, records = removed }
end

