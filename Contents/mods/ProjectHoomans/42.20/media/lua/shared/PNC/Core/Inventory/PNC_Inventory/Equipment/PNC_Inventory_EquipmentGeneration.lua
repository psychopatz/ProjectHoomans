--[[
    PNC Inventory Starting Equipment Generation
    Applies seeded weapon policy over the generic equipment spawn pools.
]]

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Inventory = PNC.Inventory
local Identity = PNC.Identity
local Settings = PNC.Sandbox

local function normalizeString(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

function Inventory.GetDebugEquipmentSpawnMode(variant, requestedMode)
    variant = tostring(variant or "")
    requestedMode = tostring(requestedMode or "")
    if requestedMode == "melee" or requestedMode == "ranged"
        or requestedMode == "both"
    then
        return requestedMode
    end
    if variant == "hostile_melee" then return "melee" end
    if variant == "hostile_ranged" then return "ranged" end
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
    if override == "none" then return false, false end
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
