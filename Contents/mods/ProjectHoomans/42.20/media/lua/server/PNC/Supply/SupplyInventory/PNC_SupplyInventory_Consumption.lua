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
local Portable = require
    "PsychopatzCore/Inventory/PsychopatzPortableItemState"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes =
    require "PNC/Core/Events/PNC_EventDefinitions"
local FLUID_EPSILON = 0.0001

local function syncPhysicalItem(nativeItem)
    if nativeItem and type(nativeItem.syncItemFields) == "function" then
        pcall(nativeItem.syncItemFields, nativeItem)
    end
    if sendItemStats and nativeItem then
        pcall(sendItemStats, nativeItem)
    end
end

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

local function fluidStateAfterUse(item, current, remaining)
    local source = item and item.itemState
    local effective = PNC.Inventory.ResolveItemState
        and PNC.Inventory.ResolveItemState(item) or source
    local amount
    local ratio
    local state
    if type(effective) ~= "table" then return nil end
    amount = tonumber(effective.fluidAmount)
    if amount == nil then return nil end
    state = PNC.Core.DeepCopy(type(source) == "table" and source or {})
    ratio = current > 0 and remaining / current or 0
    state.fluidAmount = math.max(0, amount * ratio)
    if type(source) == "table" and type(source.fluids) == "table" then
        state.fluids = {}
        for index = 1, #source.fluids do
            local entry = source.fluids[index]
            if type(entry) == "table" and tonumber(entry.amount) then
                state.fluids[#state.fluids + 1] = {
                    type = entry.type,
                    amount = math.max(0, tonumber(entry.amount) * ratio),
                }
            end
        end
    end
    if state.fluidAmount <= 0.0001 then
        state.fluidType = nil
        state.fluidPrimaryType = nil
        state.fluids = nil
    end
    return state
end

local function currentUseDelta(item)
    local current = tonumber(item and item.uses)
    local resolved
    if current == nil and PNC.Inventory.ResolveItemState then
        resolved = PNC.Inventory.ResolveItemState(item)
        current = resolved and tonumber(resolved.usedDelta) or nil
    end
    return current or 1
end

local function fluidStateAfterDrain(item, amount)
    local source = item and item.itemState
    local effective = PNC.Inventory.ResolveItemState
        and PNC.Inventory.ResolveItemState(item) or source
    local current = effective and tonumber(effective.fluidAmount) or nil
    local drained = math.max(0, tonumber(amount) or 0)
    local state
    local ratio
    if not current or current <= 0.000001 or drained <= 0 then
        return nil, 0
    end
    drained = math.min(current, drained)
    state = PNC.Core.DeepCopy(type(source) == "table" and source or {})
    state.fluidAmount = math.max(0, current - drained)
    ratio = current > 0 and state.fluidAmount / current or 0
    if type(source) == "table" and type(source.fluids) == "table" then
        state.fluids = {}
        for index = 1, #source.fluids do
            local entry = source.fluids[index]
            if type(entry) == "table" and tonumber(entry.amount) then
                state.fluids[#state.fluids + 1] = {
                    type = entry.type,
                    amount = math.max(0, tonumber(entry.amount) * ratio),
                }
            end
        end
    end
    if state.fluidAmount <= 0.0001 then
        state.fluidType = nil
        state.fluidPrimaryType = nil
        state.fluids = nil
    end
    return state, drained
end

local function splitItem(item, state)
    local split = {}
    for key, value in pairs(item) do
        if key ~= "id" and key ~= "stack" and key ~= "uses" then
            split[key] = type(value) == "table"
                and PNC.Core.DeepCopy(value) or value
        end
    end
    split.stack = 1
    split.itemState = state
    return split
end

function H.CanonicalConsumptionOps(item, descriptor, request)
    local stack = math.max(1, math.floor(tonumber(item.stack) or 1))
    -- Build 42 fluid containers do not expose a dependable thirstChange or
    -- useDelta in their script definition. Drain the requested volume while
    -- keeping the bottle as an empty container after its last sip.
    if descriptor.fluidHydration == true
        and request and tonumber(request.consumeAmount) ~= nil
    then
        local fluidState, drained = fluidStateAfterDrain(
            item, request.consumeAmount)
        local currentUses = currentUseDelta(item)
        local currentAmount = tonumber(
            PNC.Inventory.ResolveItemState(item).fluidAmount) or 0
        local remainingUses = currentAmount > 0
            and currentUses * math.max(0,
                (currentAmount - drained) / currentAmount) or 0
        if not fluidState or drained <= 0.000001 then return nil, 0, 0 end
        if stack > 1 then
            return {
                { op = "update", itemID = item.id, stack = stack - 1 },
                { op = "add", item = (function()
                    local split = splitItem(item, fluidState)
                    split.uses = remainingUses
                    return split
                end)() },
            }, remainingUses, drained
        end
        return {{ op = "update", itemID = item.id, uses = remainingUses,
            itemState = fluidState }}, remainingUses, drained
    end
    if descriptor.hydration and descriptor.useDelta > 0 then
        local current = currentUseDelta(item)
        local remaining = math.max(0, current - descriptor.useDelta)
        if remaining > 0.0001 then
            local fluidState = fluidStateAfterUse(item, current, remaining)
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
                if fluidState then split.itemState = fluidState end
                return {
                    { op = "update", itemID = item.id, stack = stack - 1 },
                    { op = "add", item = split },
                }, remaining, nil
            end
            local update = {
                op = "update", itemID = item.id, uses = remaining,
            }
            if fluidState then update.itemState = fluidState end
            return { update }, remaining, nil
        end
    end
    if stack > 1 then
        return {{ op = "update", itemID = item.id, stack = stack - 1 }}, 0, nil
    end
    return {{ op = "remove", itemID = item.id }}, 0, nil
end

local function drainPhysicalFluid(nativeItem, amount)
    local container = nativeItem and nativeItem.getFluidContainer
        and nativeItem:getFluidContainer() or nil
    local before = container and container.getAmount
        and tonumber(container:getAmount()) or nil
    local beforeState
    local ok
    local removed
    local after
    if not container or not container.removeFluid or not before then
        return false, "physical_fluid_container_unavailable"
    end
    beforeState = Portable.CaptureFluid(nativeItem)
    -- Match the vanilla drink path: the second argument is the non-utensil
    -- flag. Passing true can invoke a different container treatment in B42.
    ok, removed = pcall(container.removeFluid, container, amount, false)
    if not ok then
        ok, removed = pcall(container.removeFluid, container, amount)
    end
    if ok and removed and type(removed.release) == "function" then
        pcall(removed.release, removed)
    end
    after = tonumber(container:getAmount())
    local expected = math.max(0, before - math.max(0, tonumber(amount) or 0))
    if not ok or not after or after >= before - 0.000001
        or math.abs(after - expected) > FLUID_EPSILON
    then
        if beforeState then Portable.ApplyFluid(nativeItem, beforeState) end
        syncPhysicalItem(nativeItem)
        return false, "physical_fluid_drain_failed"
    end
    return true, function()
        if beforeState then
            return Portable.ApplyFluid(nativeItem, beforeState)
        end
        return false
    end
end

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
    local ops, remainingUses, drainedAmount = H.CanonicalConsumptionOps(
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
            elseif descriptor.hydration and descriptor.useDelta > 0
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
    if descriptor.fluidHydration == true and drainedAmount
        and descriptor.fluidAmount and descriptor.fluidAmount > 0.000001
    then
        effect.thirst = descriptor.thirst
            * math.min(1, drainedAmount / descriptor.fluidAmount)
    end
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
