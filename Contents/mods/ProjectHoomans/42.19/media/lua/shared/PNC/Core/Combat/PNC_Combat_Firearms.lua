--[[
    PNC Combat Firearms
    Server-authoritative magazine and reload rules. Every NPC empties and
    reloads the equipped firearm's real magazine. Autonomous NPCs and
    companions with realism disabled refill from an unlimited reserve; when
    companion ammo realism is enabled, recruited NPCs consume matching loose
    rounds from their persistent inventory.
]]

PNC = PNC or {}
PNC.Firearms = PNC.Firearms or {}
PNC.Combat = PNC.Combat or {}
PNC.Combat.Internal = PNC.Combat.Internal or {}

local Firearms = PNC.Firearms
local Internal = PNC.Combat.Internal
local Inventory = PNC.Inventory
local Settings = PNC.Sandbox
local Skills = PNC.Skills
local Animation = PNC.Animation

local RELOAD_ANIMS = {
    pistol = "LoadPistol",
    rifle = "LoadRifle",
    shotgun = "LoadShotgun",
    revolver = "LoadRevolver",
    dbshotgun = "LoadDBShotgun",
}

local RELOAD_DURATIONS_MS = {
    pistol = 1650,
    rifle = 2050,
    shotgun = 2350,
    revolver = 1850,
    dbshotgun = 2550,
}

local CAPACITY_FALLBACKS = {
    pistol = 8,
    rifle = 10,
    shotgun = 6,
    revolver = 6,
    dbshotgun = 2,
}

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function safeMethod(target, methodName)
    local method
    local ok
    local value
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, target)
    return ok and value or nil
end

local function fullTypeOf(record, weaponItem)
    local fullType = safeMethod(weaponItem, "getFullType")
    if fullType and tostring(fullType) ~= "" then
        return tostring(fullType)
    end
    return record and record.equipment and record.equipment.primaryFullType or nil
end

local function scriptItemFor(fullType)
    local manager
    local ok
    local item
    if not fullType or not getScriptManager then return nil end
    ok, manager = pcall(getScriptManager)
    if not ok or not manager or not manager.getItem then return nil end
    ok, item = pcall(manager.getItem, manager, fullType)
    return ok and item or nil
end

local function resolveFamily(fullType, scriptItem)
    local value = lower(fullType)
    local category = lower(safeMethod(scriptItem, "getDisplayCategory"))
    if string.find(value, "revolver", 1, true)
        or string.find(category, "revolver", 1, true)
    then
        return "handgun", "revolver"
    end
    if string.find(value, "doublebarrel", 1, true)
        or string.find(value, "dblshotgun", 1, true)
    then
        return "rifle", "dbshotgun"
    end
    if string.find(value, "shotgun", 1, true)
        or string.find(category, "shotgun", 1, true)
    then
        return "rifle", "shotgun"
    end
    if string.find(value, "rifle", 1, true)
        or string.find(value, "smg", 1, true)
        or string.find(value, "carbine", 1, true)
    then
        return "rifle", "rifle"
    end
    return "handgun", "pistol"
end

local function positiveInteger(value)
    value = tonumber(value)
    if not value or value <= 0 then return nil end
    return math.max(1, math.floor(value))
end

local function resolveCapacity(weaponItem, scriptItem, reloadFamily)
    return positiveInteger(safeMethod(scriptItem, "getClipSize"))
        or positiveInteger(safeMethod(scriptItem, "getMaxAmmo"))
        or positiveInteger(safeMethod(weaponItem, "getMaxAmmo"))
        or positiveInteger(safeMethod(weaponItem, "getClipSize"))
        or CAPACITY_FALLBACKS[reloadFamily]
        or 8
end

local function resolveReloadDuration(record, scriptItem, reloadFamily)
    local reloadMs = tonumber(safeMethod(scriptItem, "getReloadTime"))
    local reloadLevel = Skills and Skills.GetLevel
        and math.max(0, math.min(10, tonumber(Skills.GetLevel(record, "Reloading")) or 0))
        or 0
    if reloadMs and reloadMs > 0 and reloadMs < 100 then
        reloadMs = reloadMs * 100
    end
    if not reloadMs or reloadMs <= 0 then
        reloadMs = RELOAD_DURATIONS_MS[reloadFamily] or 1850
    end
    return math.max(800, math.floor(reloadMs * (1.0 - (reloadLevel * 0.03))))
end

local function normalizeItemType(value)
    value = tostring(value or "")
    return string.match(value, "^[^%.]+%.(.+)$") or value
end

local function sameItemType(left, right)
    if left == nil or right == nil then return false end
    return tostring(left) == tostring(right)
        or normalizeItemType(left) == normalizeItemType(right)
end

local function primaryInventoryState(record, fullType)
    local inv = Inventory and Inventory.EnsureRecordInventory
        and Inventory.EnsureRecordInventory(record)
        or nil
    local itemID = inv and inv.equipped and inv.equipped.primary or nil
    local item = itemID and inv.items and inv.items[itemID] or nil
    local candidateID
    local candidate
    if item and sameItemType(item.type, fullType) then
        return inv, itemID, item
    end
    for candidateID, candidate in pairs(inv and inv.items or {}) do
        if candidate and sameItemType(candidate.type, fullType)
            and (candidate.equipSlot == "primary" or item == nil)
        then
            return inv, candidateID, candidate
        end
    end
    return inv, nil, nil
end

local function mirrorMagazine(weaponItem, count)
    if weaponItem and weaponItem.setCurrentAmmoCount then
        pcall(weaponItem.setCurrentAmmoCount, weaponItem, math.max(0, math.floor(tonumber(count) or 0)))
    end
end

local function updateMagazine(record, itemID, count, reason, weaponItem)
    local inv = record and record.inventory or nil
    local state = inv and inv.items and inv.items[itemID] or nil
    count = math.max(0, math.floor(tonumber(count) or 0))
    if state and tonumber(state.ammoCount) == count then
        mirrorMagazine(weaponItem, count)
        return true
    end
    if not Inventory or not Inventory.ApplyDelta
        or not Inventory.ApplyDelta(record, {
            { op = "update", itemID = itemID, ammoCount = count },
        }, reason or "combat_magazine")
    then
        return false
    end
    mirrorMagazine(weaponItem, count)
    return true
end

local function ensureMagazine(record, descriptor, weaponItem)
    local inv
    local itemID
    local state
    local count
    inv, itemID, state = primaryInventoryState(record, descriptor.fullType)
    if not inv or not itemID or not state then
        return nil, "equipped_weapon_inventory_missing"
    end
    count = state.ammoCount
    if count == nil then
        count = descriptor.capacity
        if not updateMagazine(record, itemID, count, "combat_magazine_init", weaponItem) then
            return nil, "magazine_init_failed"
        end
    else
        count = math.max(0, math.min(descriptor.capacity, math.floor(tonumber(count) or 0)))
        if tonumber(state.ammoCount) ~= count then
            if not updateMagazine(record, itemID, count, "combat_magazine_clamp", weaponItem) then
                return nil, "magazine_clamp_failed"
            end
        else
            mirrorMagazine(weaponItem, count)
        end
    end
    return {
        inventory = inv,
        itemID = itemID,
        item = state,
        count = count,
    }
end

local function looseAmmoEntries(inv, ammoType, weaponItemID)
    local ids = {}
    local id
    local item
    for id, item in pairs(inv and inv.items or {}) do
        if id ~= weaponItemID and item and sameItemType(item.type, ammoType) then
            ids[#ids + 1] = id
        end
    end
    table.sort(ids, function(left, right) return tostring(left) < tostring(right) end)
    return ids
end

local function countLooseAmmo(inv, ammoType, weaponItemID)
    local total = 0
    local ids = looseAmmoEntries(inv, ammoType, weaponItemID)
    local i
    local item
    for i = 1, #ids do
        item = inv.items[ids[i]]
        total = total + math.max(1, math.floor(tonumber(item and item.stack) or 1))
    end
    return total
end

local function buildReloadOps(inv, ammoType, weaponItemID, amount, magazineCount)
    local ops = {}
    local ids = looseAmmoEntries(inv, ammoType, weaponItemID)
    local remaining = math.max(0, math.floor(tonumber(amount) or 0))
    local i
    local item
    local stack
    local consumed
    for i = 1, #ids do
        if remaining > 0 then
            item = inv.items[ids[i]]
            stack = math.max(1, math.floor(tonumber(item and item.stack) or 1))
            consumed = math.min(stack, remaining)
            if consumed >= stack then
                ops[#ops + 1] = { op = "remove", itemID = ids[i] }
            else
                ops[#ops + 1] = {
                    op = "update",
                    itemID = ids[i],
                    stack = stack - consumed,
                }
            end
            remaining = remaining - consumed
        end
    end
    if remaining > 0 then
        return nil
    end
    ops[#ops + 1] = {
        op = "update",
        itemID = weaponItemID,
        ammoCount = magazineCount,
    }
    return ops
end

function Firearms.IsPlayerOwned(record)
    if type(record) ~= "table" then return false end
    return record.recruited == true
        or record.ownerOnlineID ~= nil
        or (record.ownerUsername ~= nil and tostring(record.ownerUsername) ~= "")
end

function Firearms.UsesInventoryAmmo(record)
    local enabled = Settings and Settings.CompanionAmmoRealismEnabled
        and Settings.CompanionAmmoRealismEnabled()
        or (Settings and Settings.GetBoolean
            and Settings.GetBoolean("NPCAmmoConsumption", false)
            or false)
    return enabled == true and Firearms.IsPlayerOwned(record)
end

function Firearms.HasUnlimitedReserve(record)
    return not Firearms.UsesInventoryAmmo(record)
end

function Firearms.Describe(record, weaponItem)
    local fullType = fullTypeOf(record, weaponItem)
    local scriptItem = scriptItemFor(fullType)
    local weaponFamily
    local reloadFamily
    local ammoType
    if not fullType then return nil end
    weaponFamily, reloadFamily = resolveFamily(fullType, scriptItem)
    ammoType = safeMethod(weaponItem, "getAmmoType")
        or safeMethod(scriptItem, "getAmmoType")
    return {
        fullType = fullType,
        ammoType = ammoType and tostring(ammoType) or nil,
        capacity = resolveCapacity(weaponItem, scriptItem, reloadFamily),
        weaponFamily = weaponFamily,
        reloadFamily = reloadFamily,
        reloadAnim = RELOAD_ANIMS[reloadFamily] or RELOAD_ANIMS.pistol,
        reloadDurationMs = resolveReloadDuration(record, scriptItem, reloadFamily),
    }
end

function Firearms.GetMagazineState(record, weaponItem)
    local descriptor
    local state
    local reason
    descriptor = Firearms.Describe(record, weaponItem)
    if not descriptor or not descriptor.ammoType or descriptor.ammoType == "" then
        return {
            ammoNotRequired = true,
            unlimitedReserve = true,
            count = nil,
            capacity = descriptor and descriptor.capacity or nil,
        }, "ammo_not_required"
    end
    state, reason = ensureMagazine(record, descriptor, weaponItem)
    if not state then return nil, reason end
    return {
        ammoNotRequired = false,
        unlimitedReserve = Firearms.HasUnlimitedReserve(record),
        count = state.count,
        capacity = descriptor.capacity,
        ammoType = descriptor.ammoType,
        itemID = state.itemID,
        looseAmmo = countLooseAmmo(state.inventory, descriptor.ammoType, state.itemID),
        descriptor = descriptor,
    }, "magazine_ready"
end

function Firearms.PrepareShot(record, weaponItem)
    local magazine
    local reason
    magazine, reason = Firearms.GetMagazineState(record, weaponItem)
    if not magazine then return false, reason end
    if magazine.ammoNotRequired == true then
        return true, reason, magazine
    end
    if (tonumber(magazine.count) or 0) <= 0 then
        if magazine.unlimitedReserve == true
            or (tonumber(magazine.looseAmmo) or 0) > 0
        then
            return false, "reload_required", magazine
        end
        return false, "out_of_ammo", magazine
    end
    if not updateMagazine(
        record,
        magazine.itemID,
        magazine.count - 1,
        "combat_round_fired",
        weaponItem
    ) then
        return false, "ammo_update_failed", magazine
    end
    magazine.count = magazine.count - 1
    return true, "round_consumed", magazine
end

function Firearms.StartReload(record, zombie, target, weaponItem)
    local magazine
    local reason
    local descriptor
    local anim
    if record and record.runtime and record.runtime.attackAction then
        return false, "action_in_progress"
    end
    magazine, reason = Firearms.GetMagazineState(record, weaponItem)
    if not magazine then return false, reason end
    if magazine.ammoNotRequired == true then return false, "reload_not_required" end
    if magazine.count >= magazine.capacity then return false, "magazine_full" end
    if magazine.unlimitedReserve ~= true and magazine.looseAmmo <= 0 then
        return false, "out_of_ammo"
    end
    descriptor = magazine.descriptor
    anim = descriptor.reloadAnim
    if not Internal.buildAttackAction then
        return false, "action_service_unavailable"
    end
    if zombie and Animation and Animation.PlayBump then
        Animation.PlayBump(zombie, record, anim)
    end
    Internal.buildAttackAction(record, target, "reload", "reload", anim, 0, "Reloading", {
        durationMs = descriptor.reloadDurationMs,
        hitDelayMs = descriptor.reloadDurationMs,
        weaponFullType = descriptor.fullType,
        ammoType = descriptor.ammoType,
        magazineCapacity = descriptor.capacity,
        syncEvent = "reload_start",
    })
    return true, "reload_started"
end

function Firearms.CompleteReload(record, zombie, action)
    local weaponItem = Internal.resolveWeaponItem
        and Internal.resolveWeaponItem(record, zombie)
        or nil
    local descriptor = Firearms.Describe(record, weaponItem)
    local state
    local reason
    local available
    local needed
    local loadCount
    local ops
    if not descriptor or not sameItemType(descriptor.fullType, action and action.weaponFullType) then
        return false, "weapon_changed_during_reload"
    end
    state, reason = ensureMagazine(record, descriptor, weaponItem)
    if not state then return false, reason end
    needed = math.max(0, descriptor.capacity - state.count)
    if needed <= 0 then return true, "magazine_full" end
    if Firearms.HasUnlimitedReserve(record) then
        if not updateMagazine(
            record,
            state.itemID,
            descriptor.capacity,
            "combat_reload_unlimited_reserve",
            weaponItem
        ) then
            return false, "reload_magazine_update_failed"
        end
        if record and record.runtime then
            record.runtime.forceSyncEvent = "reload_finished"
        end
        if Skills and Skills.AddXP then
            Skills.AddXP(record, "Reloading", 2)
        end
        return true, "reload_complete_unlimited_reserve"
    end
    available = countLooseAmmo(state.inventory, descriptor.ammoType, state.itemID)
    loadCount = math.min(needed, available)
    if loadCount <= 0 then return false, "out_of_ammo" end
    ops = buildReloadOps(
        state.inventory,
        descriptor.ammoType,
        state.itemID,
        loadCount,
        state.count + loadCount
    )
    if not ops or not Inventory.ApplyDelta(record, ops, "combat_reload") then
        return false, "reload_inventory_update_failed"
    end
    mirrorMagazine(weaponItem, state.count + loadCount)
    if Skills and Skills.AddXP then
        Skills.AddXP(record, "Reloading", 2)
    end
    if record and record.runtime then
        record.runtime.forceSyncEvent = "reload_finished"
    end
    return true, loadCount < needed and "reload_partial" or "reload_complete"
end

function Firearms.BuildDebugState(record)
    local weaponItem = Internal.resolveWeaponItem
        and Internal.resolveWeaponItem(record)
        or nil
    local descriptor = Firearms.Describe(record, weaponItem)
    local inv
    local itemID
    local item
    local count
    if not descriptor or not descriptor.ammoType or descriptor.ammoType == "" then
        return nil
    end
    inv, itemID, item = primaryInventoryState(record, descriptor.fullType)
    if not inv or not itemID or not item then return nil end
    count = item.ammoCount
    if count == nil then count = descriptor.capacity end
    count = math.max(0, math.min(descriptor.capacity, math.floor(tonumber(count) or 0)))
    return {
        count = count,
        capacity = descriptor.capacity,
        ammoType = descriptor.ammoType,
        reloadFamily = descriptor.reloadFamily,
        reloadActive = record and record.runtime and record.runtime.attackAction
            and record.runtime.attackAction.attackType == "reload"
            or false,
        unlimitedReserve = Firearms.HasUnlimitedReserve(record),
        reserveCount = Firearms.HasUnlimitedReserve(record)
            and nil
            or countLooseAmmo(inv, descriptor.ammoType, itemID),
    }
end
