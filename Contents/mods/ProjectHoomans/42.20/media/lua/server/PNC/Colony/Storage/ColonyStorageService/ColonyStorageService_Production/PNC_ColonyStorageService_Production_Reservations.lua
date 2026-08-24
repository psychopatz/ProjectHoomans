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

function Service.ReserveProductionMaterials(storageId, requirements, owner)
    local storage = H.StorageFor(storageId)
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
            H.ReleaseTokens(reservation)
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
    local storage = H.StorageFor(storageId)
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
    local storage = H.StorageFor(storageId)
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
    H.ReleaseTokens(reservation)
    Service.ProductionReservations[reservation.id] = nil
    return true
end

