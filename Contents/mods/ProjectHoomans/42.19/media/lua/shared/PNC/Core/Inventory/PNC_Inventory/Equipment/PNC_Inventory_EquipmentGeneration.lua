--[[
    PNC Inventory Equipment Generation
    Generic identity-seeded equipment pools plus the current starting-weapon
    policy. Pool categories are intentionally open-ended so medical supplies,
    ammunition, tools, and other equipment can use the same service later.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Identity = PNC.Identity
local Settings = PNC.Sandbox

Inventory.EquipmentSpawnPools = Inventory.EquipmentSpawnPools or {}

local function normalizeString(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

local function copyGrant(source)
    if type(source) ~= "table" or not normalizeString(source.type) then return nil end
    return {
        key = normalizeString(source.key),
        type = tostring(source.type),
        stack = math.max(1, math.floor(tonumber(source.stack) or 1)),
        uses = tonumber(source.uses),
        cond = tonumber(source.cond),
        preferredContainer = normalizeString(source.preferredContainer),
    }
end

local function normalizeEntry(source)
    local entry
    local grant
    local grants
    local i
    if type(source) == "string" then source = { type = source } end
    if type(source) ~= "table" or not normalizeString(source.type) then return nil end
    entry = {
        type = tostring(source.type),
        weight = math.max(1, math.floor(tonumber(source.weight) or 1)),
        cond = tonumber(source.cond),
        grants = {},
    }
    grants = source.grants or source.supplies or {}
    for i = 1, #grants do
        grant = copyGrant(grants[i])
        if grant then entry.grants[#entry.grants + 1] = grant end
    end
    return entry
end

local function normalizeCategory(source)
    local output = {}
    local entry
    local i
    if type(source) ~= "table" then return output end
    for i = 1, #source do
        entry = normalizeEntry(source[i])
        if entry then output[#output + 1] = entry end
    end
    return output
end

function Inventory.RegisterEquipmentSpawnPool(poolID, specification)
    local categories = {}
    local category
    local entries
    poolID = normalizeString(poolID)
    if not poolID or type(specification) ~= "table" then return false end
    for category, entries in pairs(specification.categories or specification) do
        category = normalizeString(category)
        if category then categories[category] = normalizeCategory(entries) end
    end
    Inventory.EquipmentSpawnPools[poolID] = { categories = categories }
    return true
end

function Inventory.AddEquipmentSpawnEntry(poolID, category, entry)
    local pool
    local normalized
    poolID = normalizeString(poolID)
    category = normalizeString(category)
    if not poolID or not category then return false end
    normalized = normalizeEntry(entry)
    if not normalized then return false end
    pool = Inventory.EquipmentSpawnPools[poolID]
    if not pool then
        pool = { categories = {} }
        Inventory.EquipmentSpawnPools[poolID] = pool
    end
    pool.categories = type(pool.categories) == "table" and pool.categories or {}
    pool.categories[category] = type(pool.categories[category]) == "table"
        and pool.categories[category]
        or {}
    pool.categories[category][#pool.categories[category] + 1] = normalized
    return true
end

function Inventory.GetEquipmentSpawnPool(poolID)
    return Inventory.EquipmentSpawnPools[normalizeString(poolID) or "Default"]
end

function Inventory.GetDebugEquipmentSpawnMode(variant)
    variant = tostring(variant or "")
    if variant == "hostile_melee" then return "melee" end
    if variant == "hostile_ranged" then return "ranged" end
    return nil
end

local function weightedStartIndex(entries, seed, salt)
    local total = 0
    local ticket
    local i
    for i = 1, #entries do
        total = total + math.max(1, tonumber(entries[i].weight) or 1)
    end
    if total <= 0 then return nil end
    ticket = Identity.MixSeed(seed, salt) % total
    for i = 1, #entries do
        ticket = ticket - math.max(1, tonumber(entries[i].weight) or 1)
        if ticket < 0 then return i end
    end
    return 1
end

function Inventory.ChooseEquipmentSpawnEntry(poolID, category, seed, salt, validator)
    local pool = Inventory.GetEquipmentSpawnPool(poolID)
    local entries = pool and pool.categories and pool.categories[category] or {}
    local start = weightedStartIndex(entries, seed, salt)
    local index
    local offset
    if not start then return nil end
    for offset = 0, #entries - 1 do
        index = ((start - 1 + offset) % #entries) + 1
        if not validator or validator(entries[index]) then
            return normalizeEntry(entries[index])
        end
    end
    return nil
end

local function weaponEntryCompatible(entry, ranged)
    local equipment = PNC.Equipment
    local item
    if not equipment or not equipment.CreateItem then return true end
    item = equipment.CreateItem(entry.type)
    if type(item) == "table" and item[1] and not item.IsWeapon then item = item[1] end
    if not item or not item.IsWeapon or not item:IsWeapon() then return false end
    return not ranged
        or not equipment.ResolveWeaponMode
        or equipment.ResolveWeaponMode(entry.type) == "ranged"
end

local function chancePassed(seed, salt, chance)
    local roll
    chance = math.max(0, math.min(100, tonumber(chance) or 0))
    roll = Identity.Float and Identity.Float(seed, salt)
        or (Identity.MixSeed(seed, salt) / (tonumber(Identity.SEED_MAX) or 2147483646))
    return (roll * 100) < chance
end

local function resolveWeaponRolls(record, seed)
    local override = tostring(record and record.equipmentSpawnMode or "")
    if override == "melee" then return true, false end
    if override == "ranged" then return false, true end
    if override == "both" then return true, true end
    local meleeChance = Settings and Settings.NPCMeleeWeaponSpawnChance
        and Settings.NPCMeleeWeaponSpawnChance()
        or 70
    local rangedChance = Settings and Settings.NPCRangedWeaponSpawnChance
        and Settings.NPCRangedWeaponSpawnChance()
        or 20
    return chancePassed(seed, "equipment:weapon:melee:roll", meleeChance),
        chancePassed(seed, "equipment:weapon:ranged:roll", rangedChance)
end

function Inventory.ResolveStartingEquipment(record)
    local seed = Identity.NormalizeSeed(
        record and record.identitySeed or nil,
        record and record.id or "npc"
    )
    local poolID = normalizeString(record and record.equipmentPoolID) or "Default"
    local wantsMelee
    local wantsRanged
    local melee
    local ranged
    local mode
    local primary
    local reserve
    wantsMelee, wantsRanged = resolveWeaponRolls(record, seed)
    if wantsMelee then
        melee = Inventory.ChooseEquipmentSpawnEntry(
            poolID,
            "meleeWeapon",
            seed,
            "equipment:" .. poolID .. ":meleeWeapon",
            function(entry) return weaponEntryCompatible(entry, false) end
        )
    end
    if wantsRanged then
        ranged = Inventory.ChooseEquipmentSpawnEntry(
            poolID,
            "rangedWeapon",
            seed,
            "equipment:" .. poolID .. ":rangedWeapon",
            function(entry) return weaponEntryCompatible(entry, true) end
        )
    end
    if melee and ranged then
        mode = "mixed"
        primary = ranged
        reserve = melee
    elseif ranged then
        mode = "ranged"
        primary = ranged
    elseif melee then
        mode = "melee"
        primary = melee
    else
        mode = "melee"
    end
    return {
        poolID = poolID,
        weaponMode = mode,
        primaryWeapon = primary,
        reserveWeapon = reserve,
        meleeWeapon = melee,
        rangedWeapon = ranged,
    }
end

require "PNC/EquipmentDefinitions/PNC_EquipmentPools"
