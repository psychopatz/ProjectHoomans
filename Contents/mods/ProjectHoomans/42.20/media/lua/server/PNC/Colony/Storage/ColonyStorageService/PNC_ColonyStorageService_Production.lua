if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Repository = PNC.ColonyStorageRepository
local Internal = Service.Internal
local Inventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

local ACTIVITY_REASON = {
    construction_materials = "construction",
    craft_inputs = "crafting",
    disassembly_specimen = "disassembly",
    research_resource = "research",
}

local function activityItems(records)
    local output = {}
    for index = 1, #(records or {}) do
        output[#output + 1] = {
            typeId = records[index][C.TYPE_ID],
            quantity = records[index][C.QUANTITY],
        }
    end
    return output
end

local function recordProductionActivity(storage, operation, actor, records,
    stage, fallbackReason)
    if not Internal or not Internal.RecordActivity then return end
    Internal.RecordActivity(storage, operation, tostring(actor or ""),
        activityItems(records), ACTIVITY_REASON[tostring(stage or "")]
            or fallbackReason or "production")
end

Service.ProductionReservations = Service.ProductionReservations or {}
Service.NextProductionReservationId = Service.NextProductionReservationId or 1

local function storageFor(id)
    local storage = Repository.Get(id)
    return storage and storage.inventory and storage or nil
end

local function releaseTokens(reservation)
    local storage = reservation and storageFor(reservation.storageId)
    for index = 1, #(reservation and reservation.tokens or {}) do
        if storage then storage.inventory:releaseReservation(reservation.tokens[index]) end
    end
    for index = 1, #(reservation and reservation.retainedTokens or {}) do
        if storage then
            storage.inventory:releaseReservation(reservation.retainedTokens[index])
        end
    end
end

function Service.ReserveProductionMaterials(storageId, requirements, owner)
    local storage = storageFor(storageId)
    if not storage then return nil, "storage_not_found" end
    local reservation = { id = "production:"
        .. tostring(Service.NextProductionReservationId), storageId = storage.id,
        owner = tostring(owner or "production"), tokens = {}, retainedTokens = {},
        requirements = {} }
    Service.NextProductionReservationId = Service.NextProductionReservationId + 1
    for index = 1, #(requirements or {}) do
        local requirement = requirements[index]
        local amount = math.max(1, math.floor(tonumber(requirement.amount) or 1))
        local token, reason
        local selectedType
        for typeIndex = 1, #(requirement.itemTypes or {}) do
            selectedType = requirement.itemTypes[typeIndex]
            token, reason = storage.inventory:reserve(
                { fullType = selectedType }, amount, reservation.owner)
            if token then break end
        end
        if not token then
            releaseTokens(reservation)
            return nil, reason or "MISSING_MATERIALS"
        end
        local bucket = requirement.consumed == false
            and reservation.retainedTokens or reservation.tokens
        bucket[#bucket + 1] = token
        reservation.requirements[#reservation.requirements + 1] = {
            itemTypes = requirement.itemTypes, amount = amount,
            selectedType = selectedType,
            consumed = requirement.consumed ~= false,
        }
    end
    Service.ProductionReservations[reservation.id] = reservation
    return reservation
end

function Service.ReserveProductionRecord(storageId, recordIndex, quantity, owner)
    local storage = storageFor(storageId)
    local record = storage and storage.inventory.records[
        math.floor(tonumber(recordIndex) or 0)] or nil
    if not record then return nil, "record_not_found" end
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    local token, reason = storage.inventory:reserve({
        typeId = record[C.TYPE_ID], predicate = function(candidate)
            return candidate == record
        end,
    }, quantity, owner)
    if not token then return nil, reason end
    local reservation = { id = "production:"
        .. tostring(Service.NextProductionReservationId), storageId = storage.id,
        owner = tostring(owner or "production"), tokens = { token },
        recordIndex = recordIndex, quantity = quantity,
        fullType = Inventory.getItemFullType(record[C.TYPE_ID]) }
    Service.NextProductionReservationId = Service.NextProductionReservationId + 1
    Service.ProductionReservations[reservation.id] = reservation
    return reservation, record
end

function Service.ReserveProductionMatchingRecord(storageId, match, quantity, owner)
    local storage = storageFor(storageId)
    if not storage then return nil, "storage_not_found" end
    match = type(match) == "table" and match or {}
    for recordIndex = 1, #(storage.inventory.records or {}) do
        local record = storage.inventory.records[recordIndex]
        local fullType = Inventory.getItemFullType(record[C.TYPE_ID])
        if not match.fullType or fullType == match.fullType then
            local matches = true
            if match.recipeId then
                local item = Inventory.decodeItem(record)
                local data = item and item.getModData and item:getModData() or nil
                local recipeId = data and data.PNC and data.PNC.blueprint
                    and tonumber(data.PNC.blueprint.rid) or nil
                matches = recipeId == tonumber(match.recipeId)
            end
            if matches then
                local reservation, reason = Service.ReserveProductionRecord(
                    storageId, recordIndex, quantity, owner)
                if reservation then return reservation end
                if reason ~= "insufficient_quantity" then return nil, reason end
            end
        end
    end
    return nil, "matching_record_not_found"
end

function Service.ReleaseProductionReservation(id)
    local reservation = Service.ProductionReservations[tostring(id or "")]
    if not reservation then return false, "reservation_not_found" end
    releaseTokens(reservation)
    Service.ProductionReservations[reservation.id] = nil
    return true
end

local function transactionStage(storage, transactionId, stage)
    if not storage or not transactionId or not stage then return false end
    local transaction = storage.productionTransactions
        and storage.productionTransactions[tostring(transactionId)] or nil
    return transaction and transaction[tostring(stage)] == true or false
end

local function markTransactionStage(storage, transactionId, stage)
    if not transactionId or not stage then return end
    storage.productionTransactions = storage.productionTransactions or {}
    local transaction = storage.productionTransactions[tostring(transactionId)] or {}
    storage.productionTransactions[tostring(transactionId)] = transaction
    transaction[tostring(stage)] = true
end

function Service.CommitProductionReservation(id, transactionId, stage,
    storageId, actor, reason)
    local reservation = Service.ProductionReservations[tostring(id or "")]
    local storage = reservation and storageFor(reservation.storageId)
        or storageFor(storageId)
    if not reservation and transactionId then
        if transactionStage(storage, transactionId, stage) then
            return true, "already_committed"
        end
    end
    if not reservation or not storage then return false, "reservation_not_found" end
    if transactionStage(storage, transactionId, stage) then return true, "already_committed" end
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
    markTransactionStage(storage, transactionId, stage)
    storage.revision = storage.revision + 1
    recordProductionActivity(storage, "TAKE", actor, removed, stage, reason)
    Repository.MarkDirty()
    return true, removed
end

-- Live workers physically collect reserved production inputs.  This performs
-- the stockpile removal and compact/native NPC inventory projection as one
-- operation, restoring the stockpile if the worker cannot carry the records.
function Service.CollectProductionReservation(id, transactionId, stage,
    storageId, worker)
    local reservation = Service.ProductionReservations[tostring(id or "")]
    local storage = reservation and storageFor(reservation.storageId)
        or storageFor(storageId)
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
        releaseTokens(reservation)
        Service.ProductionReservations[reservation.id] = nil
        return false, reason
    end
    for index = 1, #(reservation.retainedTokens or {}) do
        storage.inventory:releaseReservation(reservation.retainedTokens[index])
    end
    Service.ProductionReservations[reservation.id] = nil
    markTransactionStage(storage, transactionId, stage)
    storage.revision = storage.revision + 1
    recordProductionActivity(storage, "TAKE",
        tostring(worker.name or worker.id), removed, stage)
    Repository.MarkDirty()
    return true, { itemIds = details and details.itemIDs or {}, records = removed }
end

function Service.ReturnCollectedProductionRecords(storageId, worker,
    itemIds, records)
    local storage = storageFor(storageId)
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
    recordProductionActivity(storage, "STORE",
        tostring(worker.name or worker.id), records, nil, "production_return")
    Repository.MarkDirty()
    return true
end

function Service.DepositProductionItems(storageId, products, provenance,
    transactionId, stage)
    local storage = storageFor(storageId)
    if not storage then return false, "storage_not_found" end
    if transactionStage(storage, transactionId, stage) then
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
    markTransactionStage(storage, transactionId, stage)
    Repository.MarkDirty()
    return true, records
end


function Service.HasProductionTransactionStage(storageId, transactionId, stage)
    return transactionStage(storageFor(storageId), transactionId, stage)
end

function Service.ForgetProductionTransaction(storageId, transactionId)
    local storage = storageFor(storageId)
    local id = tostring(transactionId or "")
    if not storage or id == "" or not storage.productionTransactions
        or not storage.productionTransactions[id]
    then return false end
    storage.productionTransactions[id] = nil
    Repository.MarkDirty()
    return true
end

function Service.ReadProductionRecord(storageId, recordIndex)
    local storage = storageFor(storageId)
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
    local storage = storageFor(storageId)
    if not storage then return 0 end
    local total = 0
    for index = 1, #(itemTypes or {}) do
        total = total + storage.inventory:count({ fullType = itemTypes[index] })
    end
    return total
end

return Service
