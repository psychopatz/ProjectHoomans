local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/"
local COMMON_ROOT = "Contents/mods/ProjectHoomans/common/media/lua/shared/"

package.path = SHARED_ROOT .. "?.lua;" .. COMMON_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function deepCopy(value)
    local output
    local key
    if type(value) ~= "table" then return value end
    output = {}
    for key, value in pairs(value) do output[key] = deepCopy(value) end
    return output
end

local rangedTypes = {
    ["Base.Pistol"] = true,
    ["Base.Revolver"] = true,
    ["Base.DoubleBarrelShotgun"] = true,
}

SandboxVars = {
    ProjectHoomans = {
        NPCMeleeWeaponSpawnChance = 70,
        NPCRangedWeaponSpawnChance = 20,
    },
}

PNC = {
    Const = {
        INVENTORY_OPLOG_MAX = 32,
        GENERATOR_VERSION = 2,
    },
    Core = {
        DeepCopy = deepCopy,
        LogWarn = function() end,
    },
    Sandbox = {},
    Identity = {
        NormalizeSeed = function(seed) return tonumber(seed) or 1 end,
        MixSeed = function(seed, salt)
            local value = tonumber(seed) or 1
            local text = tostring(salt)
            local i
            for i = 1, #text do
                value = (value * 33 + string.byte(text, i)) % 2147483646
            end
            return math.max(1, value)
        end,
        Index = function(seed, salt, count)
            return (PNC.Identity.MixSeed(seed, salt) % count) + 1
        end,
        Float = function(seed, salt)
            return PNC.Identity.MixSeed(seed, salt) / 2147483646
        end,
        RollAppearance = function()
            return { outfitItems = {} }
        end,
    },
    Archetypes = {
        Get = function(id)
            return {
                id = id or "General",
                loadout = {
                    bagChoices = {},
                    supplies = {},
                },
            }
        end,
    },
    Equipment = {
        CreateItem = function(fullType)
            return {
                IsWeapon = function() return true end,
                getActualWeight = function() return 1 end,
                fullType = fullType,
            }
        end,
        ResolveWeaponMode = function(fullType)
            return rangedTypes[fullType] and "ranged" or "melee"
        end,
        NormalizeLoadoutSpec = function(value)
            value = value or {}
            value.worn = value.worn or {}
            value.attached = value.attached or {}
            return value
        end,
    },
}

dofile(ROOT .. "Base/PNC_Sandbox.lua")
dofile(ROOT .. "Inventory/PNC_Inventory.lua")

assertEqual(PNC.Inventory.GetDebugEquipmentSpawnMode("hostile_melee"), "melee",
    "debug melee override")
assertEqual(PNC.Inventory.GetDebugEquipmentSpawnMode("hostile_ranged"), "ranged",
    "debug ranged override")
assertEqual(PNC.Inventory.GetDebugEquipmentSpawnMode("hostile"), nil,
    "generic debug hostile uses chances")
assertEqual(PNC.Inventory.GetDebugEquipmentSpawnMode("colonist"), nil,
    "generic debug colonist uses chances")

local function makeRecord(id, seed, archetypeID, override)
    return {
        id = id,
        identitySeed = seed,
        archetypeID = archetypeID or "General",
        faction = "hostile",
        weaponMode = "mixed",
        equipmentSpawnMode = override,
        equipmentPoolID = "Default",
        equipment = { worn = {}, attached = {} },
        runtime = {},
    }
end

local function itemByTemplateKey(inventory, templateKey)
    for _, item in pairs(inventory.items) do
        if item.templateKey == templateKey then return item end
    end
    return nil
end

SandboxVars.ProjectHoomans.NPCMeleeWeaponSpawnChance = 100
SandboxVars.ProjectHoomans.NPCRangedWeaponSpawnChance = 100
local bothRecord = makeRecord("natural_both_1", 8142, "Scavenger")
local bothInventory = PNC.Inventory.CreateFromTemplate(bothRecord)
local primary = bothInventory.items[bothInventory.equipped.primary]
local reserve = itemByTemplateKey(bothInventory, "tmpl:weapon:reserve")
assert(primary, "both-weapon spawn has no primary")
assert(reserve, "both-weapon spawn has no reserve")
assertEqual(rangedTypes[primary.type], true, "ranged weapon is active when both spawn")
assertEqual(rangedTypes[reserve.type] == true, false, "melee weapon is reserve when both spawn")
assertEqual(bothRecord.weaponMode, "mixed", "both-weapon combat mode")
assertEqual(bothRecord.runtime.spawnEquipmentPool, "Default", "equipment pool runtime state")

local ammoFound = false
for _, item in pairs(bothInventory.items) do
    if item.templateKey
        and string.find(item.templateKey, "tmpl:equipment_grant:primary:", 1, true) == 1
    then
        ammoFound = true
    end
end
assertEqual(ammoFound, true, "ranged equipment grant ammunition")

local saved = PNC.Inventory.Serialize(bothRecord)
assertEqual(saved.template.equipmentPoolID, "Default", "persisted equipment pool")
assertEqual(saved.template.weaponMode, "mixed", "persisted generated weapon mode")

local repeated = makeRecord("natural_both_2", 8142, "Doctor")
local repeatedInventory = PNC.Inventory.CreateFromTemplate(repeated)
local repeatedPrimary = repeatedInventory.items[repeatedInventory.equipped.primary]
local repeatedReserve = itemByTemplateKey(repeatedInventory, "tmpl:weapon:reserve")
assertEqual(repeatedPrimary.type, primary.type, "same seed primary ignores NPC archetype")
assertEqual(repeatedReserve.type, reserve.type, "same seed reserve ignores NPC archetype")

SandboxVars.ProjectHoomans.NPCMeleeWeaponSpawnChance = 0
SandboxVars.ProjectHoomans.NPCRangedWeaponSpawnChance = 0
local unarmedRecord = makeRecord("natural_unarmed", 42)
local unarmedInventory = PNC.Inventory.CreateFromTemplate(unarmedRecord)
assertEqual(unarmedInventory.equipped.primary, nil, "zero chances remain unarmed")
assertEqual(itemByTemplateKey(unarmedInventory, "tmpl:weapon:reserve"), nil, "unarmed reserve")

SandboxVars.ProjectHoomans.NPCMeleeWeaponSpawnChance = 0
SandboxVars.ProjectHoomans.NPCRangedWeaponSpawnChance = 100
local forcedMelee = makeRecord("debug_melee", 42, "Scavenger", "melee")
local forcedMeleeInventory = PNC.Inventory.CreateFromTemplate(forcedMelee)
local forcedMeleePrimary = forcedMeleeInventory.items[forcedMeleeInventory.equipped.primary]
assert(forcedMeleePrimary, "forced debug melee weapon")
assertEqual(rangedTypes[forcedMeleePrimary.type] == true, false, "forced debug melee bypass")
assertEqual(forcedMelee.weaponMode, "melee", "forced debug melee mode")

SandboxVars.ProjectHoomans.NPCMeleeWeaponSpawnChance = 100
SandboxVars.ProjectHoomans.NPCRangedWeaponSpawnChance = 0
local forcedRanged = makeRecord("debug_ranged", 42, "Scavenger", "ranged")
local forcedRangedInventory = PNC.Inventory.CreateFromTemplate(forcedRanged)
local forcedRangedPrimary = forcedRangedInventory.items[forcedRangedInventory.equipped.primary]
assert(forcedRangedPrimary, "forced debug ranged weapon")
assertEqual(rangedTypes[forcedRangedPrimary.type], true, "forced debug ranged bypass")
assertEqual(forcedRanged.weaponMode, "ranged", "forced debug ranged mode")

assert(PNC.Inventory.RegisterEquipmentSpawnPool("MedicalTest", {
    categories = {
        medical = { "Base.Bandage" },
    },
}), "generic equipment pool registration")
assert(PNC.Inventory.AddEquipmentSpawnEntry("MedicalTest", "medical", {
    type = "Base.AlcoholBandage",
    weight = 2,
}), "generic equipment pool extension")
local medical = PNC.Inventory.ChooseEquipmentSpawnEntry(
    "MedicalTest",
    "medical",
    99,
    "test:medical"
)
assert(medical and (
    medical.type == "Base.Bandage"
    or medical.type == "Base.AlcoholBandage"
), "generic equipment category selection")

print("pnc_equipment_generation_smoke: ok")
