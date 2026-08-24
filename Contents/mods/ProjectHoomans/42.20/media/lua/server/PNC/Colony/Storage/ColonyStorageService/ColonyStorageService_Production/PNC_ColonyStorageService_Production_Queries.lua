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

function Service.HasProductionTransactionStage(storageId, transactionId, stage)
    return H.TransactionStage(H.StorageFor(storageId), transactionId, stage)
end

function Service.ForgetProductionTransaction(storageId, transactionId)
    local storage = H.StorageFor(storageId)
    local id = tostring(transactionId or "")
    if not storage or id == "" or not storage.productionTransactions
        or not storage.productionTransactions[id]
    then return false end
    storage.productionTransactions[id] = nil
    Repository.MarkDirty()
    return true
end

function Service.ReadProductionRecord(storageId, recordIndex)
    local storage = H.StorageFor(storageId)
    local record = storage and storage.inventory.records[
        math.floor(tonumber(recordIndex) or 0)] or nil
    if not record then return nil, "record_not_found" end
    local item, reason = Inventory.decodeItem(record)
    local metadata
    if item and item.getModData then metadata = item:getModData() end
    return { record = record,
        fullType = Inventory.getItemFullType(record[C.TYPE_ID]),
        quantity = record[C.QUANTITY], metadata = metadata }, reason
end

function Service.GetProductionReservation(id)
    return Service.ProductionReservations[tostring(id or "")]
end

function Service.GetProductionDiagnostics(storageId)
    local output = { total = 0, material = 0, blueprint = 0, specimen = 0,
        reservations = {} }
    for id, reservation in pairs(Service.ProductionReservations) do
        if not storageId or tostring(reservation.storageId) == tostring(storageId) then
            local owner = tostring(reservation.owner or "")
            local kind = string.find(owner, "blueprint", 1, true) and "blueprint"
                or string.find(owner, "specimen", 1, true) and "specimen"
                or "material"
            output.total, output[kind] = output.total + 1, output[kind] + 1
            output.reservations[#output.reservations + 1] = {
                id = id, owner = owner, kind = kind,
            }
        end
    end
    table.sort(output.reservations, function(a, b) return a.id < b.id end)
    return output
end

function Service.CountProductionAvailable(storageId, itemTypes)
    local storage = H.StorageFor(storageId)
    if not storage then return 0 end
    local total = 0
    for index = 1, #(itemTypes or {}) do
        total = total + storage.inventory:count({ fullType = itemTypes[index] })
    end
    return total
end

return Service

