if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local SupplyInventory = PNC.SupplyInventory
local H = PNC.SupplyInventoryInternal
local Utility = PNC.ItemUtility
local Metrics = PNC.SupplyMetrics
local InventoryCommands = PNC.Inventory.Commands or PNC.Inventory
local CoreInventory =
    require "PsychopatzCore/Inventory/PsychopatzInventory"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes =
    require "PNC/Core/Events/PNC_EventDefinitions"
local Ops = H.Consumption or {}
local syncPhysicalItem = Ops.SyncPhysicalItem
local removePhysicalUnit = H.Consumption.RemovePhysicalUnit
local foodReplacement = H.Consumption.FoodReplacement
local drainPhysicalFluid = Ops.DrainPhysicalFluid
local consumePhysicalFood = Ops.ConsumePhysicalFood

function SupplyInventory.Consume(record, itemID, request)
    if InventoryCommands.AdvanceFoodLifecycle then
        InventoryCommands.AdvanceFoodLifecycle(record)
    end
    local inv = InventoryCommands.EnsureRecordInventory(record)
    local item = inv and inv.items and inv.items[tostring(itemID or "")] or nil
    if not item then return false, "item_not_found" end
    local descriptor = Utility.DescribeNPCItem(item)
    if not Utility.Supports(descriptor, request) then
        return false, "item_not_suitable"
    end
    local modeBefore = PNC.Inventory.GetPersistenceMode(record)
    local inventoryUndo = PNC.Core.DeepCopy(inv)
    local consumptionRequest = request
    if descriptor.fluidHydration == true
        and tonumber(request.consumeAmount) == nil
    then
        consumptionRequest = {}
        for key, value in pairs(request) do consumptionRequest[key] = value end
        consumptionRequest.consumeAmount = descriptor.fluidAmount
    end
    local ops, remainingUses, drainedAmount, consumedFraction =
        H.CanonicalConsumptionOps(
        item, descriptor, consumptionRequest)
    if not ops then return false, "fluid_volume_unavailable" end
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
            if descriptor.fluidHydration == true and drainedAmount
                and drainedAmount > 0.000001
            then
                local drained, drainReason, undo = drainPhysicalFluid(
                    selected.item, drainedAmount)
                if not drained then return false, drainReason end
                physicalUndo = function()
                    local restored = undo and undo() ~= false
                    syncPhysicalItem(selected.item)
                    return restored
                end
                syncPhysicalItem(selected.item)
            elseif descriptor.food and request.resourceKind == "FOOD"
            then
                local consumed, consumeReason, undo = consumePhysicalFood(
                    adapter, selected.item, foodReplacement(item, descriptor))
                if not consumed then return false, consumeReason end
                physicalUndo = undo
            elseif descriptor.hydration
                and descriptor.useDelta > 0
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
    local effect = H.BuildConsumptionEffect(descriptor, consumedFraction)
    effect.remainingUses = remainingUses
    effect.physicalProjectionMissing = false
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
            request.resourceKind == "FOOD" and effect.hunger or effect.thirst,
            request.resourceKind == "FOOD" and effect.thirst or effect.hunger)
    end
    return true, "consumed", effect
end
return SupplyInventory
