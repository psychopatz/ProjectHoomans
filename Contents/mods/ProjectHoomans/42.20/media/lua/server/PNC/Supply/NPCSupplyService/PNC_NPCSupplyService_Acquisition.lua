-- Instant colony-storage reservation and transfer acquisition.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCSupplyService = PNC.NPCSupplyService or {}
local Service = PNC.NPCSupplyService
local Internal = Service.Internal
local Metrics = PNC.SupplyMetrics
local SupplyInventory = PNC.SupplyInventory
local SupplyCommands = SupplyInventory.Commands or SupplyInventory
local Index = PNC.SupplyIndex
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local Repository = require "PNC/Colony/Storage/PNC_ColonyStorageRepository"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local function restoreStorage(storage, records)
    local restored = true
    for index = 1, #(records or {}) do
        local ok = storage.inventory:add(records[index])
        if not ok then restored = false end
    end
    Index.Invalidate(storage)
    return restored
end

local function releaseAll(storage, tokens, first)
    for index = first or 1, #tokens do
        storage.inventory:releaseReservation(tokens[index])
    end
end

local function acquireInstant(record, storage, request, selected, state)
    local tokens = {}
    state.phase = "RESERVE"
    for index = 1, #selected do
        local token, reason = storage.inventory:reserve(
            selected[index].query,
            selected[index].quantity,
            "npc_supply:" .. record.id
        )
        if not token then
            releaseAll(storage, tokens)
            Metrics.Increment("reservationFailures")
            return false, reason
        end
        tokens[#tokens + 1] = token
        Metrics.Increment("reservationsCreated")
    end
    state.reservationState = "reserved"
    state.phase = "ACQUIRE"
    local source = { revision = storage.inventory.revision }
    function source:remove()
        local removed = {}
        for index = 1, #tokens do
            local ok, records = storage.inventory:commitReservation(tokens[index])
            if not ok then
                releaseAll(storage, tokens, index)
                restoreStorage(storage, removed)
                return false, records
            end
            for itemIndex = 1, #records do
                removed[#removed + 1] = records[itemIndex]
            end
        end
        return true, removed
    end
    function source:restoreRemoved(records)
        return restoreStorage(storage, records)
    end
    local destination = SupplyCommands.CreateDestination(
        record, "colony_supply_instant"
    )
    local quantity = 0
    for index = 1, #selected do
        quantity = quantity + selected[index].quantity
    end
    local added, reason = CoreInventory.transfer(
        source, destination, nil, quantity
    )
    if not added then return false, reason end
    storage.revision = math.max(0, tonumber(storage.revision) or 0) + 1
    Repository.MarkDirty()
    local activityItems = {}
    for index = 1, #selected do
        activityItems[#activityItems + 1] = {
            typeId = selected[index].descriptor.typeId,
            quantity = selected[index].quantity,
        }
    end
    for index = 1, #activityItems do
        Events.emit(EventTypes.STORAGE_ITEM_WITHDRAWN, storage.id,
            tostring(record.name or record.id), activityItems[index].typeId,
            activityItems[index].quantity, "provision")
    end
    Index.AfterRemoval(storage)
    if PNC.ColonyStorageService and PNC.ColonyStorageService.Metrics then
        PNC.ColonyStorageService.Metrics.withdrawals =
            (PNC.ColonyStorageService.Metrics.withdrawals or 0) + 1
    end
    state.reservationState = "committed"
    Metrics.Increment("instantAcquisitions")
    return true, "acquired", {
        physicalItems = destination.physicalItems,
        physicalProjectionMissing =
            destination.physicalProjectionMissing == true,
    }
end

Internal.RestoreStorage = restoreStorage
Internal.ReleaseAll = releaseAll
Internal.AcquireInstant = acquireInstant

return Internal
