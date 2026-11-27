-- Physical-to-logical item transfer for unified opportunistic looting.
-- Physically removes the looted item from the PZ world/container and inserts it
-- into the NPC's unified PNC.Inventory (`record.inventory`), so:
--   * Eating/drinking consumes the actual looted item.
--   * Killing the NPC drops the looted item via PNC_BodyLifecycle_CorpseItems_Materialize.
--   * Off-screen compaction can fold excess generic food/water into mobile group provisions.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Scavenge/PNC_WorldLoot_Scanner"

PNC = PNC or {}
PNC.WorldLoot = PNC.WorldLoot or {}

local WorldLoot = PNC.WorldLoot
local nextLootSeq = 0

local function readMethod(obj, method)
    if type(obj) ~= "table" and type(obj) ~= "userdata" then return nil end
    local fn = obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, val = pcall(fn, obj)
    return ok and val or nil
end

local function buildCompactDescriptor(item, category)
    nextLootSeq = nextLootSeq + 1
    local ft = tostring(readMethod(item, "getFullType")
        or (type(item) == "table" and item.fullType) or "")
    local weight = tonumber(readMethod(item, "getActualWeight")
        or readMethod(item, "getWeight")
        or (type(item) == "table" and (item.actualWeight or item.weight))) or 0.5
    local calories = tonumber(readMethod(item, "getCalories")
        or (type(item) == "table" and item.calories)) or 0
    local hungerChange = tonumber(readMethod(item, "getHungerChange")
        or (type(item) == "table" and item.hungerChange)) or 0
    local thirstChange = tonumber(readMethod(item, "getThirstChange")
        or (type(item) == "table" and item.thirstChange)) or 0
    return {
        id = "loot_" .. tostring(nextLootSeq) .. "_" .. ft,
        fullType = ft,
        category = category,
        weight = math.max(0.05, weight),
        calories = calories ~= 0 and calories or nil,
        hungerChange = hungerChange ~= 0 and hungerChange or nil,
        thirstChange = thirstChange ~= 0 and thirstChange or nil,
        container = "root",
        looted = true,
    }
end

local function removePhysicalTarget(target)
    if type(target) ~= "table" then return false end
    if target.kind == "floor" and target.worldObject then
        local wObj = target.worldObject
        if type(wObj.removeFromWorld) == "function" then
            pcall(wObj.removeFromWorld, wObj)
        end
        if type(wObj.removeFromSquare) == "function" then
            pcall(wObj.removeFromSquare, wObj)
            return true
        end
        if target.square and type(target.square.RemoveTileObject) == "function" then
            pcall(target.square.RemoveTileObject, target.square, wObj)
            return true
        end
        -- Headless mock support
        if type(target.square) == "table" and type(target.square._worldObjects) == "table" then
            for i = #target.square._worldObjects, 1, -1 do
                if target.square._worldObjects[i] == wObj then
                    table.remove(target.square._worldObjects, i)
                    return true
                end
            end
        end
        return false
    end

    if target.container and target.item then
        local cont = target.container
        if type(cont.Remove) == "function" then
            pcall(cont.Remove, cont, target.item)
            if type(cont.setDrawDirty) == "function" then
                pcall(cont.setDrawDirty, cont, true)
            end
            return true
        end
        if type(cont.DoRemoveItem) == "function" then
            pcall(cont.DoRemoveItem, cont, target.item)
            return true
        end
        -- Headless mock support
        if type(cont) == "table" and type(cont._items) == "table" then
            for i = #cont._items, 1, -1 do
                if cont._items[i] == target.item then
                    table.remove(cont._items, i)
                    return true
                end
            end
        end
    end
    return false
end

local function addDescriptorToUnifiedInventory(record, desc)
    if PNC.Inventory and type(PNC.Inventory.EnsureRecordInventory) == "function" then
        PNC.Inventory.EnsureRecordInventory(record)
    end
    record.inventory = type(record.inventory) == "table" and record.inventory or {}
    record.inventory.items = type(record.inventory.items) == "table" and record.inventory.items or {}
    record.inventory.containers = type(record.inventory.containers) == "table" and record.inventory.containers or {}

    -- Prefer backpack container if it has headroom, otherwise root
    local targetContainer = "root"
    if record.inventory.containers.back then
        targetContainer = "back"
    end
    desc.container = targetContainer

    if PNC.Inventory and type(PNC.Inventory.AddItemDescriptor) == "function" then
        local ok, added = pcall(PNC.Inventory.AddItemDescriptor, record, desc)
        if ok and added then return true, desc end
    end

    record.inventory.items[desc.id] = desc
    local cont = record.inventory.containers[targetContainer]
    if type(cont) == "table" and type(cont.items) == "table" then
        cont.items[#cont.items + 1] = desc.id
    end
    if PNC.Registry and type(PNC.Registry.MarkDirty) == "function" then
        pcall(PNC.Registry.MarkDirty, record.id, "world_loot")
    end
    return true, desc
end

-- Executes the physical pickup -> unified PNC.Inventory transfer.
function WorldLoot.CollectTarget(record, target, nowMs, policy)
    if type(record) ~= "table" or type(target) ~= "table" or not target.item then
        return false, "invalid_target"
    end
    local okZone, zoneKind = WorldLoot.CanLootAt(record, target.x, target.y, target.z, policy)
    if not okZone then
        WorldLoot.ReleaseClaim(target.targetKey, record.id)
        return false, "protected_zone:" .. tostring(zoneKind)
    end
    local remCap = WorldLoot.GetRemainingCapacity(record)
    if (tonumber(target.weight) or 0.5) > remCap then
        WorldLoot.ReleaseClaim(target.targetKey, record.id)
        return false, "inventory_full"
    end

    local removed = removePhysicalTarget(target)
    WorldLoot.ReleaseClaim(target.targetKey, record.id)
    if not removed then
        return false, "remove_failed"
    end

    local desc = buildCompactDescriptor(target.item, target.category)
    local okAdd = addDescriptorToUnifiedInventory(record, desc)
    if not okAdd then
        return false, "inventory_add_failed"
    end

    -- If this NPC is hungry/thirsty right now and just looted food/water, allow immediate consumption
    local wn = PNC.WorldHourNeeds
    if wn and type(wn.ConsumePersonalSustenance) == "function" then
        if desc.category == "food" and wn.GetPseudoNeed(record, "hunger") >= 0.70 then
            wn.ConsumePersonalSustenance(record, "hunger")
        elseif desc.category == "water" and wn.GetPseudoNeed(record, "thirst") >= 0.70 then
            wn.ConsumePersonalSustenance(record, "thirst")
        end
    end

    return true, desc
end

-- Optional ModData hygiene when a mobile AI NPC goes off-screen (abstract):
-- folds excess generic looted food/water descriptors into compact group.resources
-- provision points while keeping key items in inventory for corpse drops.
function WorldLoot.CompactGroupLootOnAbstract(record, group, keepLimit)
    if type(record) ~= "table" or type(group) ~= "table" then return 0, 0 end
    local inv = type(record.inventory) == "table" and record.inventory or nil
    if not inv or type(inv.items) ~= "table" then return 0, 0 end

    local limit = math.max(0, math.floor(tonumber(keepLimit) or 4))
    local lootedFood, lootedWater = {}, {}
    for itemID, item in pairs(inv.items) do
        if type(item) == "table" and item.looted == true then
            if item.category == "food" then
                lootedFood[#lootedFood + 1] = itemID
            elseif item.category == "water" then
                lootedWater[#lootedWater + 1] = itemID
            end
        end
    end

    local foodPts, waterPts = 0, 0
    while #lootedFood > limit do
        local id = table.remove(lootedFood)
        inv.items[id] = nil
        foodPts = foodPts + 1
    end
    while #lootedWater > limit do
        local id = table.remove(lootedWater)
        inv.items[id] = nil
        waterPts = waterPts + 1
    end

    if (foodPts > 0 or waterPts > 0) and PNC.WorldHourNeeds
        and type(PNC.WorldHourNeeds.ReplenishGroupProvisions) == "function"
    then
        PNC.WorldHourNeeds.ReplenishGroupProvisions(group, foodPts, waterPts)
    end
    return foodPts, waterPts
end

return WorldLoot
