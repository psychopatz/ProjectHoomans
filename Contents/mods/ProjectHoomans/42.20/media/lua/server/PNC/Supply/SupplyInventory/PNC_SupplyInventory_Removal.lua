if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SupplyInventory = PNC.SupplyInventory or {}
PNC.SupplyInventoryInternal = PNC.SupplyInventoryInternal or {}

local SupplyInventory = PNC.SupplyInventory
local H = PNC.SupplyInventoryInternal
local Utility = PNC.ItemUtility
local Selector = PNC.SupplySelector
local Metrics = PNC.SupplyMetrics
local InventoryCommands = PNC.Inventory.Commands or PNC.Inventory
local CoreInventory =
    require "PsychopatzCore/Inventory/PsychopatzInventory"
local ItemRecord =
    require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local StateCodec = require
    "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"
local C = require
    "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require
    "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes =
    require "PNC/Core/Events/PNC_EventDefinitions"

function SupplyInventory.RemoveCoreItemIds(record, itemIDs, reason)
    if not record then return false, "npc_missing" end
    local inv = InventoryCommands.EnsureRecordInventory(record)
    local body = H.LiveBody(record)
    local physicalRemoved = {}
    for index = 1, #(itemIDs or {}) do
        local item = inv and inv.items and inv.items[tostring(itemIDs[index])] or nil
        if not item then return false, "item_not_found" end
        if body then
            local candidate = H.NativeCandidates(body, item)[1]
            if candidate then
                local adapter = CoreInventory.wrapPhysicalInventory(candidate.container)
                if not adapter or not adapter:_nativeRemove(candidate.item) then
                    for undo = #physicalRemoved, 1, -1 do
                        physicalRemoved[undo].adapter:_nativeAdd(
                            physicalRemoved[undo].item)
                    end
                    return false, "physical_remove_failed"
                end
                physicalRemoved[#physicalRemoved + 1] = {
                    adapter = adapter, item = candidate.item,
                }
            end
        end
    end
    local removed, removeReason = InventoryCommands.RemoveItems(
        record, itemIDs, reason or "production_input_consumption")
    if not removed then
        for index = #physicalRemoved, 1, -1 do
            physicalRemoved[index].adapter:_nativeAdd(physicalRemoved[index].item)
        end
        return false, removeReason
    end
    Metrics.Increment("deltaInventoryMutations")
    return true
end

return SupplyInventory

