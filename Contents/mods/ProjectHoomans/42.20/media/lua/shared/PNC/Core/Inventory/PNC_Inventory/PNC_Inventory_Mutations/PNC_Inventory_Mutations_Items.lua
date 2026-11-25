local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function addedWeight(spec)
    if type(spec) ~= "table" or not Internal.normalizeString(spec.type) then
        return nil
    end
    return Internal.getItemWeight(spec.type)
        * math.max(1,
            math.floor(tonumber(spec.stack) or 1))
end

local function resolveHardCapacity(record, weightState)
    local hardMultiplier = tonumber(PNC.Const
        and PNC.Const.INVENTORY_HARD_CAPACITY_MULTIPLIER) or 3
    local baseHardCap = tonumber(PNC.Const
        and PNC.Const.INVENTORY_HARD_CAPACITY)
    local multiplier = Internal.resolveCapacityMultiplier
        and Internal.resolveCapacityMultiplier() or 1.0
    local bonus = Internal.resolveCapacityBonus
        and Internal.resolveCapacityBonus(record) or 0
    local scaledMax = (tonumber(weightState and weightState.maxWeight) or 0)
        * hardMultiplier
    if baseHardCap then
        local scaledHardCap = (baseHardCap + bonus) * multiplier
        return math.max(scaledHardCap, scaledMax)
    end
    return scaledMax
end

function Inventory.CanAccept(record, specs, containerID, options)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local weightState = Inventory.GetWeightState(record)
    if not inv or type(specs) ~= "table" or #specs < 1 then
        return false, "items_missing"
    end
    local plan, planReason = Internal.planContainerPlacement(
        inv, specs, containerID, options
    )
    if not plan then return false, planReason end
    local hardLimit = resolveHardCapacity(record, weightState)
    if (tonumber(weightState.usedWeight) or 0)
        + (tonumber(plan.effectiveAddedWeight) or 0)
        > hardLimit
    then
        return false, "no_capacity"
    end
    return true, "accepted", plan.rawAddedWeight, plan
end

function Inventory.AddItems(record, specs, containerID, reason, options)
    options = type(options) == "table" and options or {}
    local canAccept, acceptReason, _, plan = Inventory.CanAccept(
        record,
        specs,
        containerID,
        options
    )
    local ops = {}
    local index
    local spec
    if not canAccept then return false, acceptReason, {} end
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    for index = 1, #specs do
        local destID = plan and plan.assignments and plan.assignments[index]
            or Internal.normalizeString(containerID) or "root"
        if not inv.containers[destID] then
            return false, "container_not_found", {}
        end
        spec = {}
        for key, value in pairs(specs[index]) do spec[key] = value end
        spec.container = destID
        ops[#ops + 1] = { op = "add", item = spec }
    end
    local applied, appliedOps = Inventory.ApplyDelta(
        record,
        ops,
        reason or "inventory_add"
    )
    if not applied then return false, "add_failed", {} end
    if Inventory.ReconcileWaterContainer then
        Inventory.ReconcileWaterContainer(record)
    end
    local itemIDs = {}
    local hasWearableBag = false
    for index = 1, #appliedOps do
        local added = appliedOps[index].item
        if added and added.id then
            itemIDs[#itemIDs + 1] = added.id
            if added.bagContainer and added.wearableSlot then
                hasWearableBag = true
            end
        end
    end
    if hasWearableBag
        and options.autoEquipBags ~= false
        and Inventory.ReconcileBestBags
    then
        Inventory.ReconcileBestBags(
            record,
            (reason or "inventory_add") .. "_auto_equip_bag",
            { candidateIDs = itemIDs }
        )
    end
    return true, "added", itemIDs
end

function Inventory.RemoveItems(record, itemIDs, reason)
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local ops = {}
    local seen = {}
    local index
    local itemID
    if not inv or type(itemIDs) ~= "table" or #itemIDs < 1 then
        return false, "items_missing"
    end
    for index = 1, #itemIDs do
        itemID = Internal.normalizeString(itemIDs[index])
        if not itemID or seen[itemID] or not inv.items[itemID] then
            return false, "item_not_found"
        end
        seen[itemID] = true
        ops[#ops + 1] = { op = "remove", itemID = itemID }
    end
    if not Inventory.ApplyDelta(record, ops, reason or "inventory_remove") then
        return false, "remove_failed"
    end
    if Inventory.ReconcileWaterContainer then
        Inventory.ReconcileWaterContainer(record)
    end
    return true, "removed"
end

-- Canonical item-spec encoder for live PZ InventoryItem instances.
-- Preserves durability, uses, fluid, and custom state when CoreInventory +
-- StateCodec are available; falls back safely to { type = fullType, stack = 1 }.
function Inventory.EncodeLiveItemSpec(item)
    if not item then return nil end
    local fullType = nil
    if type(item.getFullType) == "function" then
        local ok, v = pcall(item.getFullType, item)
        if ok and type(v) == "string" and v ~= "" then fullType = v end
    end
    if not fullType and type(item.getType) == "function" then
        local ok, v = pcall(item.getType, item)
        if ok and type(v) == "string" and v ~= "" then fullType = v end
    end
    if not fullType then return nil end
    local fallback = { type = fullType, stack = 1 }
    local coreInv = PsychopatzCore and PsychopatzCore.Inventory or nil
    if not coreInv or type(coreInv.encodeItem) ~= "function" then
        return fallback
    end
    local ok, encoded = pcall(coreInv.encodeItem, item, 1)
    if not ok or type(encoded) ~= "table" then return fallback end
    local bridge = Inventory.CoreBridge
    local stateCodec = bridge and bridge.StateCodec or nil
    if stateCodec and type(stateCodec.readValidatedState) == "function" then
        local decoded = stateCodec.readValidatedState(encoded)
        if type(decoded) == "table" then
            decoded.type = fullType
            decoded.stack = 1
            return decoded
        end
    end
    return fallback
end

-- Unified persistence + live-body sync entry point for adding item specs to
-- an NPC: validates capacity, commits to record.inventory (marking ModData
-- dirty), and materializes onto the live body so items never vanish on reload.
function Inventory.AddItemsAndSync(record, body, specs, containerID, reason, options)
    local ok, addReason, itemIDs = Inventory.AddItems(
        record,
        specs,
        containerID or "root",
        reason,
        options
    )
    if not ok then
        return false, addReason, {}
    end
    local liveBody = body
    if not liveBody and record and record.id ~= nil
        and PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function"
    then
        liveBody = PNC.Registry.GetLiveZombie(record.id)
    end
    if liveBody and type(itemIDs) == "table" and type(Inventory.MaterializeItem) == "function" then
        for i = 1, #itemIDs do
            pcall(Inventory.MaterializeItem, record, liveBody, itemIDs[i])
        end
    end
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        pcall(PNC.Registry.MarkDirty, record, "inventory")
    end
    return true, addReason or "added", itemIDs
end

-- Unified single-call helper for committing a live world InventoryItem onto an
-- NPC with full state encoding, capacity check, persistence, and body sync.
function Inventory.CommitLiveItem(record, body, item, reason, options)
    local spec = Inventory.EncodeLiveItemSpec(item)
    if not spec then return false, "invalid_item", {} end
    local containerID = type(options) == "table" and options.containerID or "root"
    return Inventory.AddItemsAndSync(
        record,
        body,
        { spec },
        containerID,
        reason or "commit_live_item",
        options
    )
end

return Inventory
