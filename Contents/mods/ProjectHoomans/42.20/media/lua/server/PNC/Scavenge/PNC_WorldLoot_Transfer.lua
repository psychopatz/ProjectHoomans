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
        type = ft,
        fullType = ft,
        count = 1,
        category = category,
        weight = math.max(0.05, weight),
        calories = calories ~= 0 and calories or nil,
        hungerChange = hungerChange ~= 0 and hungerChange or nil,
        thirstChange = thirstChange ~= 0 and thirstChange or nil,
        state = {
            calories = calories ~= 0 and calories or nil,
            hungerChange = hungerChange ~= 0 and hungerChange or nil,
            thirstChange = thirstChange ~= 0 and thirstChange or nil,
        },
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

local THEFT_WITNESS_RADIUS_SQ = 144 -- 12 tiles

local function playPickupCue(record, nowMs)
    local perf = PNC.Semantics and PNC.Semantics.SpeechPerformance or nil
    if perf and type(perf.Perform) == "function" then
        pcall(perf.Perform, record, {
            anim = "PNC_Anim_Loot",
            durationMs = 900,
            reason = "world_loot_pickup",
        }, nowMs)
    end
end

local function emitSafeZoneTheftAlert(thief, target, desc, nowMs)
    local protected, zoneKind, zoneId = WorldLoot.IsInProtectedSafeZone(target.x, target.y, target.z)
    if not protected then return false, 0 end

    local payload = {
        thiefId = tostring(thief.id or ""),
        zoneKind = tostring(zoneKind or ""),
        zoneId = tostring(zoneId or ""),
        x = target.x,
        y = target.y,
        z = target.z,
        fullType = desc and desc.fullType or target.fullType,
        at = nowMs,
    }
    local bus = PsychopatzCore and PsychopatzCore.Events or nil
    if bus and type(bus.emit) == "function" then
        pcall(bus.emit, "WORLD_LOOT_PROTECTED_THEFT", payload)
    end

    local witnesses = 0
    local registry = PNC.Registry
    if registry and type(registry.ForEach) == "function" then
        registry.ForEach(function(obs)
            if type(obs) == "table" and obs.alive ~= false
                and tostring(obs.id or "") ~= payload.thiefId
            then
                local dx = (tonumber(obs.x) or 0) - (tonumber(target.x) or 0)
                local dy = (tonumber(obs.y) or 0) - (tonumber(target.y) or 0)
                local dz = math.abs((tonumber(obs.z) or 0) - (tonumber(target.z) or 0))
                local sameSide = (zoneKind == "player_settlement" and obs.recruited == true)
                    or (zoneKind == "npc_settlement" and tostring(obs.communityID or obs.homeCommunityId or "") == payload.zoneId)
                if sameSide and dz < 1 and (dx * dx + dy * dy) <= THEFT_WITNESS_RADIUS_SQ then
                    witnesses = witnesses + 1
                    obs.runtime = type(obs.runtime) == "table" and obs.runtime or {}
                    obs.runtime.theftAlertTargetId = payload.thiefId
                    obs.runtime.theftAlertAt = nowMs
                    if PNC.Relationships and type(PNC.Relationships.ApplyConversationEffect) == "function" then
                        pcall(PNC.Relationships.ApplyConversationEffect, obs.id, "npc:" .. payload.thiefId, {
                            trustDelta = -12,
                            affectionDelta = -8,
                            reason = "protected_zone_theft",
                        })
                    end
                    if witnesses == 1 then
                        local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
                        if beats and type(beats.EmitWorldLootTheft) == "function" then
                            pcall(beats.EmitWorldLootTheft, obs, thief, payload.fullType, nowMs, target)
                        end
                    end
                end
            end
        end)
    end
    return true, witnesses
end

-- Executes the physical pickup -> unified PNC.Inventory transfer.
function WorldLoot.CollectTarget(record, target, nowMs, policy)
    if type(record) ~= "table" or type(target) ~= "table" or not target.item then
        return false, "invalid_target"
    end
    local okZone, zoneKind = WorldLoot.CanLootAt(record, target.x, target.y, target.z, policy)
    if not okZone then
        WorldLoot.ReleaseClaim(target.targetKey, record.id)
        if WorldLoot.IsAuditEnabled() then
            WorldLoot.Audit("blocked_zone", {
                "npc=" .. tostring(record.id),
                "reason=" .. tostring(zoneKind),
                "item=" .. tostring(target.fullType),
                string.format("pos=%d,%d,%d", tonumber(target.x) or 0, tonumber(target.y) or 0, tonumber(target.z) or 0),
            })
        end
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

    playPickupCue(record, nowMs)
    local isProtectedTheft, witnessCount = emitSafeZoneTheftAlert(record, target, desc, nowMs)
    if WorldLoot.IsAuditEnabled() then
        WorldLoot.Audit(isProtectedTheft and "theft_collected" or "collected", {
            "npc=" .. tostring(record.id),
            "item=" .. tostring(desc.fullType),
            "cat=" .. tostring(desc.category),
            "stolen=" .. tostring(isProtectedTheft == true),
            "witnesses=" .. tostring(witnessCount or 0),
            string.format("pos=%d,%d,%d", tonumber(target.x) or 0, tonumber(target.y) or 0, tonumber(target.z) or 0),
        })
    end
    local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
    if isProtectedTheft then
        if (witnessCount or 0) == 0 and beats and type(beats.EmitWorldLootStealSolo) == "function" then
            pcall(beats.EmitWorldLootStealSolo, record, desc, nowMs, target)
        end
    elseif beats and type(beats.EmitWorldLootPickup) == "function" then
        pcall(beats.EmitWorldLootPickup, record, desc, nowMs, target)
    end

    -- If this NPC is hungry/thirsty right now and just looted food/water, allow immediate consumption
    local wn = PNC.WorldHourNeeds
    if wn and type(wn.ConsumePersonalSustenance) == "function" then
        if desc.category == "food" and wn.GetPseudoNeed(record, "hunger") >= 0.70 then
            local ate, ateType = wn.ConsumePersonalSustenance(record, "hunger")
            if ate then
                local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
                if beats and type(beats.EmitWorldLootSustenance) == "function" then
                    pcall(beats.EmitWorldLootSustenance, record, "hunger", ateType, nowMs)
                end
            end
        elseif desc.category == "water" and wn.GetPseudoNeed(record, "thirst") >= 0.70 then
            local drank, drankType = wn.ConsumePersonalSustenance(record, "thirst")
            if drank then
                local beats = PNC.Semantics and PNC.Semantics.DialogueBeats or nil
                if beats and type(beats.EmitWorldLootSustenance) == "function" then
                    pcall(beats.EmitWorldLootSustenance, record, "thirst", drankType, nowMs)
                end
            end
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
