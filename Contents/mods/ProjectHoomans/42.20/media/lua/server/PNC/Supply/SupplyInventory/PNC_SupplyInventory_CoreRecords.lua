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

function H.CloneSpec(record)
    local spec = StateCodec.readState(record)
    spec.type = CoreInventory.getItemFullType(record[C.TYPE_ID])
    spec.stack = record[C.QUANTITY]
    spec.container = "root"
    return spec
end

function H.LiveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

function H.RemoveNativeList(adapter, items)
    for index = #(items or {}), 1, -1 do adapter:_nativeRemove(items[index]) end
end

function SupplyInventory.AddCoreRecords(record, records, reason)
    local specs = {}
    for index = 1, #(records or {}) do
        local spec = H.CloneSpec(records[index])
        if not spec.type then return false, "unknown_type_id" end
        specs[#specs + 1] = spec
    end
    local accepted, why = PNC.Inventory.CanAccept(record, specs, "root")
    if not accepted then return false, why end
    local body = H.LiveBody(record)
    local physical
    local physicalItems = {}
    local physicalProjectionMissing = false
    if body then
        physical, why = CoreInventory.wrapPhysicalInventory(body:getInventory())
        if not physical then
            physicalProjectionMissing = true
        else
            for index = 1, #records do
                local ok, added = physical:add(records[index])
                if not ok then
                    H.RemoveNativeList(physical, physicalItems)
                    physicalItems = {}
                    physicalProjectionMissing = true
                    break
                end
                for itemIndex = 1, #added do
                    physicalItems[#physicalItems + 1] = added[itemIndex]
                end
            end
        end
    end
    local added, addReason, itemIDs = InventoryCommands.AddItems(
        record, specs, "root", reason or "supply_acquisition"
    )
    if not added then
        if physical then H.RemoveNativeList(physical, physicalItems) end
        return false, addReason
    end
    Metrics.Increment("deltaInventoryMutations")
    return true, "added", {
        itemIDs = itemIDs,
        physicalItems = physicalItems,
        physicalProjectionMissing = physicalProjectionMissing,
        records = records,
    }
end

function SupplyInventory.CreateDestination(record, reason)
    local destination = {
        revision = record.inventory and record.inventory.revision or 0,
        inventoryUndo = PNC.Core.DeepCopy(
            InventoryCommands.EnsureRecordInventory(record)
        ),
        itemIDs = {},
        physicalItems = {},
        physicalProjectionMissing = false,
        rolledBack = false,
    }
    function destination:add(coreRecord)
        local ok, why, details = SupplyInventory.AddCoreRecords(
            record, { coreRecord }, reason or "colony_supply_instant"
        )
        if not ok then return false, why end
        for index = 1, #(details.physicalItems or {}) do
            self.physicalItems[#self.physicalItems + 1] =
                details.physicalItems[index]
        end
        for index = 1, #(details.itemIDs or {}) do
            self.itemIDs[#self.itemIDs + 1] = details.itemIDs[index]
        end
        self.physicalProjectionMissing = details.physicalProjectionMissing
            or self.physicalProjectionMissing
        return true, details
    end
    function destination:remove()
        if self.rolledBack then return true, {} end
        local body = H.LiveBody(record)
        local physical = body and CoreInventory.wrapPhysicalInventory(
            body:getInventory()
        ) or nil
        if physical then H.RemoveNativeList(physical, self.physicalItems) end
        record.inventory = self.inventoryUndo
        InventoryCommands.RebuildCaches(record)
        self.rolledBack = true
        return true, {}
    end
    return destination
end

return SupplyInventory
