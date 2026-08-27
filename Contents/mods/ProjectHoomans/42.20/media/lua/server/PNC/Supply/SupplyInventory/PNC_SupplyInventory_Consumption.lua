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

local function removePhysicalUnit(adapter, nativeItem)
    local count
    local readOK
    if nativeItem and type(nativeItem.getCount) == "function" then
        readOK, count = pcall(nativeItem.getCount, nativeItem)
        count = readOK and tonumber(count) or nil
    end
    if count and count > 1 then
        if type(nativeItem.setCount) ~= "function" then
            return false, "physical_stack_update_unavailable"
        end
        local updated = pcall(nativeItem.setCount, nativeItem, count - 1)
        if not updated then return false, "physical_stack_update_failed" end
        return true, function()
            pcall(nativeItem.setCount, nativeItem, count)
        end
    end
    if not adapter:_nativeRemove(nativeItem) then
        return false, "physical_remove_failed"
    end
    return true, function() adapter:_nativeAdd(nativeItem) end
end

function H.CanonicalConsumptionOps(item, descriptor)
    local stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    if descriptor.hydration and descriptor.useDelta > 0 then
        local current = tonumber(item.uses) or 1
        local remaining = math.max(0, current - descriptor.useDelta)
        if remaining > 0.0001 then
            if stack > 1 then
                local split = {}
                for key, value in pairs(item) do
                    if key ~= "id" and key ~= "stack" then
                        split[key] = type(value) == "table"
                            and PNC.Core.DeepCopy(value) or value
                    end
                end
                split.stack = 1
                split.uses = remaining
                return {
                    { op = "update", itemID = item.id, stack = stack - 1 },
                    { op = "add", item = split },
                }, remaining
            end
            return {{ op = "update", itemID = item.id, uses = remaining }},
                remaining
        end
    end
    if stack > 1 then
        return {{ op = "update", itemID = item.id, stack = stack - 1 }}, 0
    end
    return {{ op = "remove", itemID = item.id }}, 0
end

function SupplyInventory.Consume(record, itemID, request)
    local inv = InventoryCommands.EnsureRecordInventory(record)
    local item = inv and inv.items and inv.items[tostring(itemID or "")] or nil
    if not item then return false, "item_not_found" end
    local descriptor = Utility.DescribeNPCItem(item)
    if not Utility.Supports(descriptor, request) then
        return false, "item_not_suitable"
    end
    local modeBefore = PNC.Inventory.GetPersistenceMode(record)
    local inventoryUndo = PNC.Core.DeepCopy(inv)
    local ops, remainingUses = H.CanonicalConsumptionOps(item, descriptor)
    local body = H.LiveBody(record)
    local physicalUndo
    if body then
        local candidates = H.NativeCandidates(body, item)
        local selected = candidates[1]
        if not selected and PNC.Inventory
            and PNC.Inventory.MaterializeItem
        then
            -- Existing saves can contain a compact item that was added while
            -- the NPC was live but never projected to its native inventory.
            -- Repair only this selected item; a full snapshot would duplicate
            -- unrelated native items. The compact record remains authoritative
            -- if the repair cannot be completed.
            local repaired, _, repairUndo =
                PNC.Inventory.MaterializeItem(record, body, item.id)
            if repaired then
                candidates = H.NativeCandidates(body, item)
                selected = candidates[1]
            end
            if not selected and repairUndo then pcall(repairUndo) end
        end
        if selected then
            local adapter = CoreInventory.wrapPhysicalInventory(
                selected.container
            )
            if descriptor.hydration and descriptor.useDelta > 0
                and remainingUses > 0.0001
            then
                local before = selected.item.getUsedDelta
                    and selected.item:getUsedDelta()
                    or tonumber(item.uses) or 1
                if not selected.item.setUsedDelta then
                    return false, "physical_drainable_unavailable"
                end
                selected.item:setUsedDelta(remainingUses)
                physicalUndo = function()
                    selected.item:setUsedDelta(before)
                end
            else
                local removed, removeReason, undo = removePhysicalUnit(
                    adapter, selected.item)
                if not removed then return false, removeReason end
                physicalUndo = undo
            end
        else
            -- A visible NPC may only consume an item that is present in its
            -- physical inventory. Keep compact state untouched so projection
            -- reconciliation can repair the mismatch without phantom eating.
            return false, "physical_item_missing"
        end
    end
    local applied = InventoryCommands.ApplyDelta(
        record, ops, "supply_item_use_" .. string.lower(request.resourceKind)
    )
    if not applied then
        if physicalUndo then physicalUndo() end
        return false, "compact_consumption_failed"
    end
    Metrics.Increment("deltaInventoryMutations")
    if modeBefore == "BASELINE_DELTA"
        and PNC.Inventory.GetPersistenceMode(record) == "SEED_ONLY"
    then
        Metrics.Increment("deltaInventoryCompactions")
    end
    local effect = {
        hunger = descriptor.hunger,
        thirst = descriptor.thirst,
        calories = descriptor.calories,
        fullType = descriptor.fullType,
        typeId = descriptor.typeId,
        remainingUses = remainingUses,
        physicalProjectionMissing = false,
    }
    effect.undo = function()
        record.inventory = inventoryUndo
        InventoryCommands.RebuildCaches(record)
        if physicalUndo then physicalUndo() end
        return true
    end
    local eventType = request.resourceKind == "FOOD"
        and EventTypes.NPC_FOOD_CONSUMED
        or request.resourceKind == "HYDRATION"
            and EventTypes.NPC_DRINK_CONSUMED or nil
    if eventType then
        Events.emit(eventType, record, effect.fullType,
            request.resourceKind == "FOOD" and effect.hunger or effect.thirst)
    end
    return true, "consumed", effect
end

return SupplyInventory
