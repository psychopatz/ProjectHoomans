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

local ACTIVITY_REASON = {
    construction_materials = "construction",
    craft_inputs = "crafting",
    disassembly_specimen = "disassembly",
    research_resource = "research",
    provision = "provision",
}

function H.ActivityItems(records)
    local output = {}
    for index = 1, #(records or {}) do
        output[#output + 1] = {
            typeId = records[index][C.TYPE_ID],
            quantity = records[index][C.QUANTITY],
        }
    end
    return output
end

function H.RecordProductionActivity(storage, operation, actor, records,
    stage, fallbackReason)
    if not Internal or not Internal.RecordActivity then return end
    Internal.RecordActivity(storage, operation, tostring(actor or ""),
        H.ActivityItems(records), ACTIVITY_REASON[tostring(stage or "")]
            or fallbackReason or "production")
end

Service.ProductionReservations = Service.ProductionReservations or {}
Service.NextProductionReservationId = Service.NextProductionReservationId or 1

function H.StorageFor(id)
    local storage = Repository.Get(id)
    return storage and storage.inventory and storage or nil
end

function H.ReleaseTokens(reservation)
    local storage = reservation and H.StorageFor(reservation.storageId)
    for index = 1, #(reservation and reservation.tokens or {}) do
        if storage then storage.inventory:releaseReservation(reservation.tokens[index]) end
    end
    for index = 1, #(reservation and reservation.retainedTokens or {}) do
        if storage then
            storage.inventory:releaseReservation(reservation.retainedTokens[index])
        end
    end
end
