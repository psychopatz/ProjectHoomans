-- Automatic best-backpack and fanny-pack adoption with content migration.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Appearance = require "PNC/Core/Identity/PNC_Identity_Appearance"

function Internal.scoreWearableBag(item)
    if type(item) ~= "table" or not item.bagContainer then return 0 end
    local capacity = math.max(0, tonumber(item.maxWeight) or 0)
    local reduction = Internal.normalizeItemWeightReduction(item.weightReduction)
    if capacity <= 0 then return 0 end
    return (capacity * (1 + reduction)) + (reduction * 2)
end

local function migrateBagContents(record, inv, fromContainerID, toContainerID)
    local source = inv.containers and inv.containers[fromContainerID] or nil
    local target = inv.containers and inv.containers[toContainerID] or nil
    if not source or not target or #(source.items or {}) < 1 then return end
    local targetMax = math.max(0, tonumber(target.maxWeight) or 0)
    local targetUsed = Internal.getContainerRawWeight(inv, toContainerID) or 0
    local itemIDs = Internal.shallowArrayCopy(source.items)
    local ops = {}
    for i = 1, #itemIDs do
        local item = inv.items and inv.items[itemIDs[i]] or nil
        if item and not item.wornSlot and not item.equipSlot
            and not item.attachedSlot
        then
            local weight = Internal.getItemWeight(item.type)
                * math.max(1, math.floor(tonumber(item.stack) or 1))
            if targetUsed + weight <= targetMax + 0.0001 then
                targetUsed = targetUsed + weight
                ops[#ops + 1] = { op = "move", itemID = item.id, to = toContainerID }
            end
        end
    end
    if #ops > 0 and Inventory.ApplyDelta then
        Inventory.ApplyDelta(record, ops, "bag_upgrade_migrate", {
            skipCanonicalRepair = true,
        })
    end
end

function Inventory.ReconcileBestBags(record, reason, options)
    options = type(options) == "table" and options or {}
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    if not inv or type(inv.items) ~= "table" then return false, 0 end
    local filterSet = nil
    if type(options.candidateIDs) == "table" then
        filterSet = {}
        for i = 1, #options.candidateIDs do
            filterSet[tostring(options.candidateIDs[i])] = true
        end
    end
    local candidates = {}
    for itemID, item in pairs(inv.items) do
        if type(item) == "table"
            and item.bagContainer ~= nil
            and item.interactionLocked ~= true
            and item.wornSlot == nil
            and item.equipSlot == nil
            and (not filterSet or filterSet[tostring(itemID)] == true)
        then
            local slot = Internal.normalizeString(item.wearableSlot)
                or Internal.getContainerProfile(item.type).wearableSlot
            local score = Internal.scoreWearableBag(item)
            if slot and score > 0 then
                candidates[#candidates + 1] = {
                    id = item.id,
                    slot = slot,
                    score = score,
                    bagContainer = item.bagContainer,
                }
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return tostring(a.id) < tostring(b.id)
    end)
    local equippedCount = 0
    for i = 1, #candidates do
        local cand = candidates[i]
        local item = inv.items[cand.id]
        if item and item.wornSlot == nil and item.equipSlot == nil then
            local conflicts = {}
            local canReplace = true
            for wornSlot, wornID in pairs(inv.worn or {}) do
                if wornID ~= cand.id
                    and Appearance.WornSlotsConflict(cand.slot, wornSlot)
                then
                    local wornItem = inv.items[wornID]
                    if not wornItem or wornItem.bagContainer == nil
                        or wornItem.interactionLocked == true
                        or Internal.scoreWearableBag(wornItem) >= cand.score
                    then
                        canReplace = false
                        break
                    end
                    conflicts[#conflicts + 1] = wornItem
                end
            end
            if canReplace then
                for c = 1, #conflicts do
                    Inventory.ClearWorn(
                        record, conflicts[c].id, reason or "bag_upgrade_unwear"
                    )
                end
                local wornOK = Inventory.SetWorn(
                    record, cand.id, cand.slot, reason or "bag_auto_equip"
                )
                if wornOK then
                    equippedCount = equippedCount + 1
                    for c = 1, #conflicts do
                        if conflicts[c].bagContainer then
                            migrateBagContents(
                                record, inv, conflicts[c].bagContainer,
                                cand.bagContainer
                            )
                        end
                    end
                end
            end
        end
    end
    return equippedCount > 0, equippedCount
end

return Inventory
