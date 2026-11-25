-- Unified automatic loadout adoption: best bags (with content migration),
-- best armor/clothing by defense stats, and best weapon by item stats + NPC skill.
-- Shared by colonists, neutrals, and DynamicTrading caravans (event-driven only).
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local Appearance = require "PNC/Core/Identity/PNC_Identity_Appearance"

local function safeNum(value, fallback)
    local n = tonumber(value)
    if n == nil or n ~= n or n == math.huge or n == -math.huge then
        return fallback or 0
    end
    return n
end

local function scriptItemFor(item)
    if type(item) ~= "table" or type(item.type) ~= "string" then return nil end
    local sm = type(getScriptManager) == "function" and getScriptManager() or nil
    if sm and type(sm.getItem) == "function" then
        return sm:getItem(item.type)
    end
    return nil
end

local function readItemStat(item, scriptItem, field, method, fallback)
    if type(item) == "table" and item[field] ~= nil then
        return safeNum(item[field], fallback)
    end
    if scriptItem and method and type(scriptItem[method]) == "function" then
        return safeNum(scriptItem[method](scriptItem), fallback)
    end
    return fallback or 0
end

local function readSkillLevel(record, skillKey)
    if type(record) ~= "table" or not skillKey then return 0 end
    local key = tostring(skillKey)
    local lower = string.lower(key)
    local sources = { record.skills, record.perks, record.stats and record.stats.skills }
    for i = 1, #sources do
        local src = sources[i]
        if type(src) == "table" then
            if src[key] ~= nil then return math.max(0, safeNum(src[key], 0)) end
            if src[lower] ~= nil then return math.max(0, safeNum(src[lower], 0)) end
        end
    end
    return 0
end

function Internal.scoreWearableBag(item)
    if type(item) ~= "table" or not item.bagContainer then return 0 end
    local capacity = math.max(0, safeNum(item.maxWeight, 0))
    local reduction = Internal.normalizeItemWeightReduction
        and Internal.normalizeItemWeightReduction(item.weightReduction)
        or math.max(0, math.min(1, safeNum(item.weightReduction, 0) / 100))
    if capacity <= 0 then return 0 end
    return (capacity * (1 + reduction)) + (reduction * 2)
end

function Internal.scoreArmorItem(item)
    if type(item) ~= "table" or item.bagContainer ~= nil then return 0 end
    local scriptItem = scriptItemFor(item)
    local bite = readItemStat(item, scriptItem, "biteDefense", "getBiteDefense", 0)
    local scratch = readItemStat(item, scriptItem, "scratchDefense", "getScratchDefense", 0)
    local bullet = readItemStat(item, scriptItem, "bulletDefense", "getBulletDefense", 0)
    if bite <= 0 and scratch <= 0 and bullet <= 0 then return 0 end
    local cond = safeNum(item.condition, 10)
    local condMax = math.max(1, safeNum(item.conditionMax, 10))
    local condFactor = math.max(0.25, math.min(1.0, cond / condMax))
    return ((bite * 1.4) + (scratch * 1.0) + (bullet * 0.9)) * condFactor
end

function Internal.scoreWeaponItem(item, record)
    if type(item) ~= "table" or item.bagContainer ~= nil then return 0 end
    local isWeapon = item.isWeapon == true
        or item.category == "Weapon"
        or item.weaponCategory ~= nil
        or item.maxDamage ~= nil
    local scriptItem = scriptItemFor(item)
    if not isWeapon and scriptItem and type(scriptItem.getTypeString) == "function" then
        isWeapon = scriptItem:getTypeString() == "Weapon"
    end
    if not isWeapon then return 0 end

    local minDmg = readItemStat(item, scriptItem, "minDamage", "getMinDamage", 0)
    local maxDmg = readItemStat(item, scriptItem, "maxDamage", "getMaxDamage", 0)
    if maxDmg <= 0 then return 0 end
    local range = readItemStat(item, scriptItem, "maxRange", "getMaxRange", 1.0)
    local crit = readItemStat(item, scriptItem, "critChance", "getCriticalChance", 0)
    local isRanged = item.isRanged == true
        or (scriptItem and type(scriptItem.isRanged) == "function" and scriptItem:isRanged() == true)
    if isRanged and item.hasAmmo == false then
        return 0
    end
    local cond = safeNum(item.condition, 10)
    local condMax = math.max(1, safeNum(item.conditionMax, 10))
    if cond <= 0 then return 0 end
    local condFactor = math.max(0.25, math.min(1.0, cond / condMax))

    local skillKey = isRanged and "Aiming"
        or tostring(item.weaponSkill or item.weaponCategory or "Blunt")
    local skillLevel = readSkillLevel(record, skillKey)
    local baseScore = ((minDmg + maxDmg) * 5.0) + (range * 1.5) + (crit * 0.1)
    return baseScore * condFactor * (1.0 + (skillLevel * 0.12))
end

local function migrateBagContents(record, inv, fromContainerID, toContainerID)
    local source = inv.containers and inv.containers[fromContainerID] or nil
    local target = inv.containers and inv.containers[toContainerID] or nil
    if not source or not target or #(source.items or {}) < 1 then return end
    local targetMax = math.max(0, safeNum(target.maxWeight, 0))
    local targetUsed = Internal.getContainerRawWeight
        and Internal.getContainerRawWeight(inv, toContainerID) or 0
    local itemIDs = Internal.shallowArrayCopy
        and Internal.shallowArrayCopy(source.items) or source.items
    local ops = {}
    for i = 1, #itemIDs do
        local item = inv.items and inv.items[itemIDs[i]] or nil
        if item and not item.wornSlot and not item.equipSlot
            and not item.attachedSlot
        then
            local weight = (Internal.getItemWeight and Internal.getItemWeight(item.type) or 0.5)
                * math.max(1, math.floor(safeNum(item.stack, 1)))
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

local function buildFilterSet(options)
    if type(options) ~= "table" or type(options.candidateIDs) ~= "table" then
        return nil
    end
    local set = {}
    for i = 1, #options.candidateIDs do
        set[tostring(options.candidateIDs[i])] = true
    end
    return set
end

local function reconcileWearables(record, inv, reason, filterSet, mode)
    local isBagMode = mode == "bags"
    local candidates = {}
    for itemID, item in pairs(inv.items) do
        if type(item) == "table"
            and item.interactionLocked ~= true
            and item.wornSlot == nil
            and item.equipSlot == nil
            and (not filterSet or filterSet[tostring(itemID)] == true)
        then
            local matchesKind = isBagMode and (item.bagContainer ~= nil)
                or (not isBagMode and item.bagContainer == nil)
            if matchesKind then
                local slot = (Internal.normalizeString and Internal.normalizeString(item.wearableSlot))
                    or item.wearableSlot
                    or (isBagMode and Internal.getContainerProfile
                        and Internal.getContainerProfile(item.type).wearableSlot)
                    or nil
                local score = isBagMode
                    and Internal.scoreWearableBag(item)
                    or Internal.scoreArmorItem(item)
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
                    local wornScore = isBagMode
                        and (wornItem and Internal.scoreWearableBag(wornItem) or 0)
                        or (wornItem and Internal.scoreArmorItem(wornItem) or 0)
                    if not wornItem
                        or wornItem.interactionLocked == true
                        or (isBagMode and wornItem.bagContainer == nil)
                        or wornScore >= cand.score
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
                        record, conflicts[c].id,
                        reason or (isBagMode and "bag_upgrade_unwear" or "armor_upgrade_unwear")
                    )
                end
                local wornOK = Inventory.SetWorn(
                    record, cand.id, cand.slot,
                    reason or (isBagMode and "bag_auto_equip" or "armor_auto_equip")
                )
                if wornOK then
                    equippedCount = equippedCount + 1
                    if isBagMode then
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
    end
    return equippedCount
end

local function reconcileBestWeapon(record, inv, reason, filterSet)
    if type(Inventory.SetEquipped) ~= "function" then return 0 end
    local currentID = inv.equipped and inv.equipped.primary or nil
    local currentItem = currentID and inv.items[currentID] or nil
    if currentItem and currentItem.interactionLocked == true then return 0 end
    local bestScore = currentItem and Internal.scoreWeaponItem(currentItem, record) or 0
    local bestID = nil

    for itemID, item in pairs(inv.items) do
        if type(item) == "table"
            and item.id ~= currentID
            and item.interactionLocked ~= true
            and item.wornSlot == nil
            and (not filterSet or filterSet[tostring(itemID)] == true)
        then
            local score = Internal.scoreWeaponItem(item, record)
            if score > bestScore then
                bestScore = score
                bestID = item.id
            end
        end
    end
    if not bestID then return 0 end
    local ok = Inventory.SetEquipped(record, "primary", bestID, reason or "weapon_auto_equip")
    return ok and 1 or 0
end

function Inventory.ReconcileBestLoadout(record, reason, options)
    options = type(options) == "table" and options or {}
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    if not inv or type(inv.items) ~= "table" then
        return false, { bags = 0, armor = 0, weapons = 0, total = 0 }
    end
    local filterSet = buildFilterSet(options)
    local bags = options.bags ~= false
        and reconcileWearables(record, inv, reason, filterSet, "bags") or 0
    local armor = options.armor ~= false
        and reconcileWearables(record, inv, reason, filterSet, "armor") or 0
    local weapons = options.weapons ~= false
        and reconcileBestWeapon(record, inv, reason, filterSet) or 0
    local total = bags + armor + weapons
    return total > 0, {
        bags = bags,
        armor = armor,
        weapons = weapons,
        total = total,
    }
end

function Inventory.ReconcileBestBags(record, reason, options)
    options = type(options) == "table" and options or {}
    local changed, summary = Inventory.ReconcileBestLoadout(record, reason, {
        bags = true,
        armor = false,
        weapons = false,
        candidateIDs = options.candidateIDs,
    })
    return changed, summary and summary.bags or 0
end

return Inventory
