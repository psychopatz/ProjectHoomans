PNC = PNC or {}
PNC.SupplyInventory = PNC.SupplyInventory or {}

local SupplyInventory = PNC.SupplyInventory
local Utility = PNC.ItemUtility
local Selector = PNC.SupplySelector
local Metrics = PNC.SupplyMetrics
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local ItemRecord = require "PsychopatzCore/Inventory/PsychopatzItemRecord"
local StateCodec = require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util = require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

local function cloneSpec(record)
    local spec = StateCodec.readState(record)
    spec.type = CoreInventory.getItemFullType(record[C.TYPE_ID])
    spec.stack = record[C.QUANTITY]
    spec.container = "root"
    return spec
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

local function removeNativeList(adapter, items)
    for index = #(items or {}), 1, -1 do adapter:_nativeRemove(items[index]) end
end

function SupplyInventory.AddCoreRecords(record, records, reason)
    local specs = {}
    for index = 1, #(records or {}) do
        local spec = cloneSpec(records[index])
        if not spec.type then return false, "unknown_type_id" end
        specs[#specs + 1] = spec
    end
    local accepted, why = PNC.Inventory.CanAccept(record, specs, "root")
    if not accepted then return false, why end
    local body = liveBody(record)
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
                    removeNativeList(physical, physicalItems)
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
    local added, addReason, itemIDs = PNC.Inventory.AddItems(
        record, specs, "root", reason or "supply_acquisition"
    )
    if not added then
        if physical then removeNativeList(physical, physicalItems) end
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
            PNC.Inventory.EnsureRecordInventory(record)
        ),
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
        self.physicalProjectionMissing = details.physicalProjectionMissing
            or self.physicalProjectionMissing
        return true, details
    end
    function destination:remove()
        if self.rolledBack then return true, {} end
        local body = liveBody(record)
        local physical = body and CoreInventory.wrapPhysicalInventory(
            body:getInventory()
        ) or nil
        if physical then removeNativeList(physical, self.physicalItems) end
        record.inventory = self.inventoryUndo
        PNC.Inventory.RebuildCaches(record)
        self.rolledBack = true
        return true, {}
    end
    return destination
end

local function exactRecord(item)
    return CoreInventory.encodeItem(StateCodec.pseudoItem(item), 1)
end

local function sameState(expected, candidate)
    local encoded = CoreInventory.encodeItem(candidate, 1)
    if not encoded or not expected then return false end
    local expectedKey = ItemRecord.stackKey(expected)
    local candidateKey = ItemRecord.stackKey(encoded)
    if expectedKey or candidateKey then return expectedKey == candidateKey end
    return Util.canonical(expected) == Util.canonical(encoded)
end

local function nativeCandidates(body, item)
    local output = {}
    local compatible = {}
    local visited = {}
    local expected = exactRecord(item)
    local function visit(container)
        if not container or visited[container] then return end
        visited[container] = true
        local items = container.getItems and container:getItems() or nil
        if not items or not items.size or not items.get then return end
        for index = 0, items:size() - 1 do
            local nativeItem = items:get(index)
            local fullType = nativeItem and nativeItem.getFullType
                and nativeItem:getFullType() or nil
            if tostring(fullType or "") == tostring(item.type or "") then
                local entry = {
                    item = nativeItem,
                    container = container,
                }
                if sameState(expected, nativeItem) then
                    output[#output + 1] = entry
                else
                    compatible[#compatible + 1] = entry
                end
            end
            local nested = nativeItem and nativeItem.getItemContainer
                and nativeItem:getItemContainer() or nil
            if nested then visit(nested) end
        end
    end
    visit(body and body.getInventory and body:getInventory() or nil)
    for index = 1, #compatible do
        output[#output + 1] = compatible[index]
    end
    return output
end

local function canonicalConsumptionOps(item, descriptor)
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
    local inv = PNC.Inventory.EnsureRecordInventory(record)
    local item = inv and inv.items and inv.items[tostring(itemID or "")] or nil
    if not item then return false, "item_not_found" end
    local descriptor = Utility.DescribeNPCItem(item)
    if not Utility.Supports(descriptor, request) then
        return false, "item_not_suitable"
    end
    local modeBefore = PNC.Inventory.GetPersistenceMode(record)
    local inventoryUndo = PNC.Core.DeepCopy(inv)
    local ops, remainingUses = canonicalConsumptionOps(item, descriptor)
    local body = liveBody(record)
    local physicalUndo
    local physicalProjectionMissing = false
    if body then
        local candidates = nativeCandidates(body, item)
        local selected = candidates[1]
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
                if not adapter:_nativeRemove(selected.item) then
                    return false, "physical_remove_failed"
                end
                physicalUndo = function()
                    adapter:_nativeAdd(selected.item)
                end
            end
        else
            -- Compact inventory is the authoritative persisted state. A live
            -- body can briefly lack its projected native item after spawning
            -- or reconciliation; rejecting here permanently blocks needs on
            -- the same otherwise-valid personal candidate.
            physicalProjectionMissing = true
        end
    end
    local applied = PNC.Inventory.ApplyDelta(
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
        fullType = descriptor.fullType,
        typeId = descriptor.typeId,
        remainingUses = remainingUses,
        physicalProjectionMissing = physicalProjectionMissing,
    }
    effect.undo = function()
        record.inventory = inventoryUndo
        PNC.Inventory.RebuildCaches(record)
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

function SupplyInventory.FindPersonal(record, request, required)
    local inv = PNC.Inventory.EnsureRecordInventory(record)
    local candidates = {}
    for _, item in pairs(inv and inv.items or {}) do
        if item.interactionLocked ~= true then
            local descriptor = Utility.DescribeNPCItem(item)
            local score = Selector.Score(descriptor, request, required)
            if score then
                candidates[#candidates + 1] = {
                    item = item,
                    descriptor = descriptor,
                    score = score,
                }
            end
        end
    end
    table.sort(candidates, function(left, right)
        if left.score ~= right.score then return left.score > right.score end
        if left.descriptor.expiry ~= right.descriptor.expiry then
            return left.descriptor.expiry > right.descriptor.expiry
        end
        return tostring(left.item.id) < tostring(right.item.id)
    end)
    return candidates
end

return SupplyInventory
