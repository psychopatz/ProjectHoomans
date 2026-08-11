local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local COMMON_ROOT = "Contents/mods/ProjectHoomans/common/media/lua/shared/"

package.path = SHARED_ROOT .. "?.lua;" .. COMMON_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function assertNear(actual, expected, tolerance, label)
    if math.abs((tonumber(actual) or 0) - (tonumber(expected) or 0))
        > (tonumber(tolerance) or 0.0001)
    then
        error((label or "assertNear") .. ": expected=" .. tostring(expected)
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
        INVENTORY_HARD_CAPACITY_MULTIPLIER = 3,
        STAMINA_MELEE_COST = 20,
        STAMINA_RANGED_COST = 10,
        STAMINA_DOWNED_SHOVE_COST = 8,
        STAMINA_ATTACK_MIN_RESERVE = 10,
        STAMINA_RECOVERY_IDLE = 7,
        STAMINA_RECOVERY_MOVING = 4.5,
        STAMINA_RECOVERY_COMBAT = 3,
        STAMINA_RECOVERY_DOWNED = 2.5,
        STAMINA_VISIBLE_MS = 4000,
        STAMINA_MOVE_DRAIN_WALK = 3,
        STAMINA_MOVE_DRAIN_RUN = 10,
        STAMINA_MOVE_DRAIN_SNEAK = 4,
        STAMINA_MOVE_DRAIN_CRAWL = 2.2,
        STAMINA_MOVE_DRAIN_RECOVERY_WALK = 1.4,
        STAMINA_MOVE_DRAIN_RECOVERY_SNEAK = 1.8,
        STAMINA_MOVE_EXHAUST_PAUSE = 0.25,
        STAMINA_MOVE_EXHAUST_RESUME = 0.4,
        STAMINA_MOVE_RECOVERY_PAUSE = 0.35,
        STAMINA_MOVE_RECOVERY_RESUME = 0.5,
        STAMINA_MOVE_CRAWL_PAUSE = 0.6,
        STAMINA_MOVE_CRAWL_RESUME = 0.75,
        STAMINA_SPRINT_BREATHER_MS = 900,
        ENCUMBRANCE_SEVERE_RATIO = 1.75,
        ENCUMBRANCE_DAMAGE_INTERVAL_MS = 5000,
        ENCUMBRANCE_DAMAGE_AMOUNT = 1,
        ENCUMBRANCE_DAMAGE_FLOOR_RATIO = 0.75,
    },
    Core = {
        DeepCopy = deepCopy,
        LogWarn = function() end,
        Now = function() return 0 end,
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
            local isBag = fullType == "Base.Bag_Test"
            return {
                IsWeapon = function() return not isBag end,
                getActualWeight = function()
                    return fullType == "Base.HeavyLoad" and 1
                        or isBag and 2
                        or 1
                end,
                getMaxCapacity = isBag and function() return 10 end or nil,
                getWeightReduction = isBag and function() return 80 end or nil,
                canBeEquipped = isBag and function() return "base:back" end or nil,
                getBodyLocation = function()
                    return fullType == "Base.Tshirt_DefaultTEXTURE_TINT"
                        and "Torso1" or nil
                end,
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
assertEqual(PNC.Inventory.GetDebugEquipmentSpawnMode("neutral", "melee"), "melee",
    "neutral debug melee override")
assertEqual(PNC.Inventory.GetDebugEquipmentSpawnMode("colonist", "ranged"), "ranged",
    "companion debug ranged override")
assertEqual(PNC.Inventory.GetDebugEquipmentSpawnMode("neutral", "both"), "both",
    "neutral debug both override")
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
local identityCard = itemByTemplateKey(bothInventory, "tmpl:identity_card:0")
assert(primary, "both-weapon spawn has no primary")
assert(reserve, "both-weapon spawn has no reserve")
assert(identityCard, "NPC identity card was not generated")
assertEqual(identityCard.type, "Base.IDcard", "NPC identity card type")
assertEqual(identityCard.customName, "ID Card: Unknown NPC", "NPC identity card name")
assertEqual(identityCard.identityNPCId, bothRecord.id, "NPC identity card UUID")
assertEqual(identityCard.interactionLocked, true,
    "NPC identity card is interaction locked")
assertEqual(identityCard.interactionLockReason, "identity_card",
    "NPC identity card lock reason")
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

dofile(ROOT .. "Inventory/PNC_Inventory_Actions.lua")
local interactionRecord = makeRecord("inventory_interaction", 5150)
interactionRecord.faction = "colonist"
local interactionInventory = PNC.Inventory.CreateFromTemplate(interactionRecord)
local added, addReason, addedIDs = PNC.Inventory.AddItems(interactionRecord, {
    {
        type = "Base.Tshirt_DefaultTEXTURE_TINT",
        stack = 1,
        itemState = { condition = 8, customName = "Travel Shirt" },
    },
}, "root", "smoke_add")
assertEqual(added, true, "public inventory add")
assertEqual(addReason, "added", "public inventory add reason")
assertEqual(#addedIDs, 1, "public inventory add ID")
local addedItem = interactionInventory.items[addedIDs[1]]
assertEqual(addedItem.itemState.condition, 8, "portable state retained")

local worn, wornReason = PNC.InventoryActions.Execute(
    "wear", nil, interactionRecord, addedItem.id, {}
)
assertEqual(worn, true, "modular wear action")
assertEqual(wornReason, "worn", "modular wear reason")
assertEqual(addedItem.wornSlot, "Torso1", "worn slot applied")

local removedWorn = PNC.InventoryActions.Execute(
    "remove_worn", nil, interactionRecord, addedItem.id, {}
)
assertEqual(removedWorn, true, "modular remove-worn action")
assertEqual(addedItem.wornSlot, nil, "worn slot cleared")

local equipped = PNC.InventoryActions.Execute(
    "equip_primary", nil, interactionRecord, addedItem.id, {}
)
assertEqual(equipped, true, "modular equip action")
assertEqual(interactionInventory.equipped.primary, addedItem.id, "primary equipped")
assertEqual(PNC.Inventory.SetEquipped(
    interactionRecord, "secondary", addedItem.id, "smoke_secondary"
), true, "move item to secondary")
assertEqual(interactionInventory.equipped.primary, nil, "old equip slot cleared")
assertEqual(interactionInventory.equipped.secondary, addedItem.id, "secondary equipped")
assertEqual(PNC.Inventory.SetEquipped(
    interactionRecord, "primary", addedItem.id, "smoke_primary"
), true, "move item back to primary")
assertEqual(interactionInventory.equipped.secondary, nil, "secondary slot cleared")
assertEqual(interactionInventory.equipped.primary, addedItem.id, "primary restored")
assertEqual(PNC.InventoryActions.Execute(
    "unequip", nil, interactionRecord, addedItem.id, {}
), true, "modular unequip action")
assertEqual(interactionInventory.equipped.primary, nil, "primary cleared")

local favorited, favoriteReason = PNC.InventoryActions.Execute(
    "favorite", nil, interactionRecord, addedItem.id, {}
)
assertEqual(favorited, true, "modular favorite action")
assertEqual(favoriteReason, "favorited", "modular favorite reason")
assertEqual(addedItem.fav, true, "favorite state applied")
local payload = PNC.Inventory.BuildFullPayload(interactionRecord)
assertEqual(payload.items[addedItem.id].itemState.customName, "Travel Shirt",
    "portable state replicated")
assertEqual(payload.items[addedItem.id].fav, true, "favorite state replicated")
assertEqual(PNC.InventoryActions.Execute(
    "unfavorite", nil, interactionRecord, addedItem.id, {}
), true, "modular unfavorite action")
assertEqual(addedItem.fav, false, "favorite state cleared")
assertEqual(PNC.Inventory.RemoveItems(
    interactionRecord, { addedItem.id }, "smoke_remove"
), true, "public inventory remove")
assertEqual(interactionInventory.items[addedItem.id], nil, "item removed")

local bagAdded, _, bagIDs = PNC.Inventory.AddItems(interactionRecord, {
    { type = "Base.Bag_Test", stack = 1 },
}, "root", "smoke_bag_add")
assertEqual(bagAdded, true, "wearable container add")
local bagItem = interactionInventory.items[bagIDs[1]]
assertEqual(bagItem.wearableSlot, "base:back", "container equipment slot")
assertEqual(bagItem.weightReduction, 0.8, "container weight reduction")
assertEqual(bagItem.maxWeight, 10, "container capacity")

assertEqual(PNC.Inventory.AddItems(interactionRecord, {
    { type = "Base.Bandage", stack = 5 },
}, bagItem.bagContainer, "smoke_bag_contents"), true, "bag contents add")
local weightBeforeBagEquip = interactionInventory.cachedWeight
assertEqual(PNC.InventoryActions.Execute(
    "equip_container", nil, interactionRecord, bagItem.id, {}
), true, "modular bag equip action")
assertEqual(bagItem.wornSlot, "base:back", "bag worn slot")
assertEqual(interactionInventory.worn["base:back"], bagItem.id, "bag worn reference")
local reducedContentsWeight =
    PNC.Inventory.Internal.getItemWeight("Base.Bandage") * 5 * 0.8
assertNear(interactionInventory.cachedWeight,
    weightBeforeBagEquip - reducedContentsWeight, 0.0001,
    "equipped bag reduces contents weight")
local bagPayload = PNC.Inventory.BuildFullPayload(interactionRecord)
assertEqual(bagPayload.items[bagItem.id].weightReduction, 0.8,
    "bag reduction replicated")
assertEqual(bagPayload.items[bagItem.id].wearableSlot, "base:back",
    "bag equipment slot replicated")

local baseCarry = interactionInventory.maxWeight
local heavyUnitWeight = PNC.Inventory.Internal.getItemWeight("Base.HeavyLoad")
local severeStack = math.ceil(
    ((baseCarry * 1.8) - interactionInventory.cachedWeight) / heavyUnitWeight
)
assertEqual(PNC.Inventory.AddItems(interactionRecord, {
    { type = "Base.HeavyLoad", stack = severeStack },
}, "root", "smoke_severe_load"), true, "severe load accepted below hard cap")
local encumbrance = PNC.Inventory.GetEncumbranceState(interactionRecord)
assertEqual(encumbrance.level, "severe", "severe encumbrance threshold")

local strainDamageCalls = 0
PNC.Health = {
    ApplyStrainDamage = function(_, _, amount, floorRatio, reason)
        strainDamageCalls = strainDamageCalls + 1
        assertEqual(amount, 1, "strain damage amount")
        assertEqual(floorRatio, 0.75, "strain damage floor")
        assertEqual(reason, "severe_encumbrance", "strain damage reason")
        return true
    end,
}
PNC.Registry = { MarkDirty = function() end }
local staminaAverageReads = 0
local staminaLevelReads = 0
local staminaEncumbranceReads = 0
local originalGetEncumbranceState = PNC.Inventory.GetEncumbranceState
PNC.Inventory.GetEncumbranceState = function(record)
    staminaEncumbranceReads = staminaEncumbranceReads + 1
    return originalGetEncumbranceState(record)
end
PNC.Skills = {
    GetAverage = function()
        staminaAverageReads = staminaAverageReads + 1
        return 2
    end,
    GetLevel = function()
        staminaLevelReads = staminaLevelReads + 1
        return 2
    end,
}
dofile(ROOT .. "Stamina/PNC_Stamina.lua")
local staminaSnapshot = PNC.Stamina.BuildSnapshot(interactionRecord)
assert(staminaSnapshot.max < staminaSnapshot.baseMax,
    "encumbrance lowers maximum stamina")
assertEqual(staminaSnapshot.encumbranceLevel, "severe",
    "stamina snapshot carries encumbrance")
local snapshotAverageReads = staminaAverageReads
local snapshotLevelReads = staminaLevelReads
local snapshotEncumbranceReads = staminaEncumbranceReads
PNC.Stamina.BuildSnapshot(interactionRecord)
assertEqual(staminaAverageReads, snapshotAverageReads,
    "stamina replication recalculated skills")
assertEqual(staminaLevelReads, snapshotLevelReads,
    "stamina replication recalculated skill levels")
assertEqual(staminaEncumbranceReads, snapshotEncumbranceReads,
    "stamina replication recalculated encumbrance")
local averagesBeforeUpdate = staminaAverageReads
local encumbranceBeforeUpdate = staminaEncumbranceReads
PNC.Stamina.Update(interactionRecord, nil, 10000)
assertEqual(staminaAverageReads - averagesBeforeUpdate, 1,
    "stamina update recalculated its skill average more than once")
assertEqual(staminaEncumbranceReads - encumbranceBeforeUpdate, 1,
    "stamina update recalculated encumbrance more than once")
PNC.Stamina.Update(interactionRecord, nil, 16000)
assertEqual(strainDamageCalls, 1, "severe load periodic strain damage")

assertEqual(PNC.InventoryActions.Execute(
    "unequip_container", nil, interactionRecord, bagItem.id, {}
), true, "modular bag unequip action")
assertEqual(bagItem.wornSlot, nil, "bag worn slot cleared")

print("pnc_equipment_generation_smoke: ok")
