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

local function itemKeyString(value)
    local key
    if value == nil then return nil end
    key = safeMethod(value, "getItemKey")
    if key ~= nil and tostring(key) ~= "" then
        return tostring(key)
    end
    value = tostring(value)
    return value ~= "" and value or nil
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

local function nonNegativeInteger(value)
    value = tonumber(value)
    if value == nil or value < 0 then return nil end
    return math.floor(value)
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

Internal.Lower = lower
Internal.SafeMethod = safeMethod
Internal.ItemKeyString = itemKeyString
Internal.FullTypeOf = fullTypeOf
Internal.ScriptItemFor = scriptItemFor
Internal.ResolveFamily = resolveFamily
Internal.PositiveInteger = positiveInteger
Internal.NonNegativeInteger = nonNegativeInteger
Internal.ResolveCapacity = resolveCapacity
Internal.ResolveReloadDuration = resolveReloadDuration
Internal.NormalizeItemType = normalizeItemType
Internal.SameItemType = sameItemType
Internal.PrimaryInventoryState = primaryInventoryState
Internal.ReloadAnims = RELOAD_ANIMS
Internal.ReloadDurationsMs = RELOAD_DURATIONS_MS
Internal.CapacityFallbacks = CAPACITY_FALLBACKS
