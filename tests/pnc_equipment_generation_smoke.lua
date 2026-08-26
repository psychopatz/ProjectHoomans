local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SHARED_ROOT = T.path("ProjectHoomans", "shared", "")
local COMMON_ROOT = T.path("ProjectHoomans", "common_lua", "")
local CORE_ROOT = T.path("PsychopatzCore", "common", "")

T.addPackagePaths()

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

T.load(ROOT .. "Base/PNC_Sandbox.lua")
T.load(ROOT .. "Inventory/PNC_Inventory.lua")

T.equal(PNC.Inventory.GetDebugEquipmentSpawnMode("hostile_melee"), "melee",
    "debug melee override")
T.equal(PNC.Inventory.GetDebugEquipmentSpawnMode("hostile_ranged"), "ranged",
    "debug ranged override")
T.equal(PNC.Inventory.GetDebugEquipmentSpawnMode("neutral", "melee"), "melee",
    "neutral debug melee override")
T.equal(PNC.Inventory.GetDebugEquipmentSpawnMode("colonist", "ranged"), "ranged",
    "companion debug ranged override")
T.equal(PNC.Inventory.GetDebugEquipmentSpawnMode("neutral", "both"), "both",
    "neutral debug both override")
T.equal(PNC.Inventory.GetDebugEquipmentSpawnMode("hostile"), nil,
    "generic debug hostile uses chances")
T.equal(PNC.Inventory.GetDebugEquipmentSpawnMode("colonist"), nil,
    "generic debug colonist uses chances")

local function makeRecord(id, seed, archetypeID, override)
    return {
        id = id,
        identitySeed = seed,
        archetypeID = archetypeID or "General",
        tacticalClass = "hostile",
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
T.truthy(primary, "both-weapon spawn has no primary")
T.truthy(reserve, "both-weapon spawn has no reserve")
T.truthy(identityCard, "NPC identity card was not generated")
T.equal(identityCard.type, "Base.IDcard", "NPC identity card type")
T.equal(identityCard.customName, "ID Card: Unknown NPC", "NPC identity card name")
T.equal(identityCard.identityNPCId, bothRecord.id, "NPC identity card UUID")
T.equal(identityCard.interactionLocked, true,
    "NPC identity card is interaction locked")
T.equal(identityCard.interactionLockReason, "identity_card",
    "NPC identity card lock reason")
T.equal(rangedTypes[primary.type], true, "ranged weapon is active when both spawn")
T.equal(rangedTypes[reserve.type] == true, false, "melee weapon is reserve when both spawn")
T.equal(bothRecord.weaponMode, "mixed", "both-weapon combat mode")
T.equal(bothRecord.runtime.spawnEquipmentPool, "Default", "equipment pool runtime state")

local ammoFound = false
for _, item in pairs(bothInventory.items) do
    if item.templateKey
        and string.find(item.templateKey, "tmpl:equipment_grant:primary:", 1, true) == 1
    then
        ammoFound = true
    end
end
T.equal(ammoFound, true, "ranged equipment grant ammunition")

local saved = PNC.Inventory.Serialize(bothRecord)
T.equal(saved[4].equipmentPoolID, "Default", "persisted equipment pool")
T.equal(saved[4].weaponMode, "mixed", "persisted generated weapon mode")

local repeated = makeRecord("natural_both_2", 8142, "Doctor")
local repeatedInventory = PNC.Inventory.CreateFromTemplate(repeated)
local repeatedPrimary = repeatedInventory.items[repeatedInventory.equipped.primary]
local repeatedReserve = itemByTemplateKey(repeatedInventory, "tmpl:weapon:reserve")
T.equal(repeatedPrimary.type, primary.type, "same seed primary ignores NPC archetype")
T.equal(repeatedReserve.type, reserve.type, "same seed reserve ignores NPC archetype")

SandboxVars.ProjectHoomans.NPCMeleeWeaponSpawnChance = 0
SandboxVars.ProjectHoomans.NPCRangedWeaponSpawnChance = 0
local unarmedRecord = makeRecord("natural_unarmed", 42)
local unarmedInventory = PNC.Inventory.CreateFromTemplate(unarmedRecord)
T.equal(unarmedInventory.equipped.primary, nil, "zero chances remain unarmed")
T.equal(itemByTemplateKey(unarmedInventory, "tmpl:weapon:reserve"), nil, "unarmed reserve")

SandboxVars.ProjectHoomans.NPCMeleeWeaponSpawnChance = 0
SandboxVars.ProjectHoomans.NPCRangedWeaponSpawnChance = 100
local forcedMelee = makeRecord("debug_melee", 42, "Scavenger", "melee")
local forcedMeleeInventory = PNC.Inventory.CreateFromTemplate(forcedMelee)
local forcedMeleePrimary = forcedMeleeInventory.items[forcedMeleeInventory.equipped.primary]
T.truthy(forcedMeleePrimary, "forced debug melee weapon")
T.equal(rangedTypes[forcedMeleePrimary.type] == true, false, "forced debug melee bypass")
T.equal(forcedMelee.weaponMode, "melee", "forced debug melee mode")

SandboxVars.ProjectHoomans.NPCMeleeWeaponSpawnChance = 100
SandboxVars.ProjectHoomans.NPCRangedWeaponSpawnChance = 0
local forcedRanged = makeRecord("debug_ranged", 42, "Scavenger", "ranged")
local forcedRangedInventory = PNC.Inventory.CreateFromTemplate(forcedRanged)
local forcedRangedPrimary = forcedRangedInventory.items[forcedRangedInventory.equipped.primary]
T.truthy(forcedRangedPrimary, "forced debug ranged weapon")
T.equal(rangedTypes[forcedRangedPrimary.type], true, "forced debug ranged bypass")
T.equal(forcedRanged.weaponMode, "ranged", "forced debug ranged mode")

T.truthy(PNC.Inventory.RegisterEquipmentSpawnPool("MedicalTest", {
    categories = {
        medical = { "Base.Bandage" },
    },
}), "generic equipment pool registration")
T.truthy(PNC.Inventory.AddEquipmentSpawnEntry("MedicalTest", "medical", {
    type = "Base.AlcoholBandage",
    weight = 2,
}), "generic equipment pool extension")
local medical = PNC.Inventory.ChooseEquipmentSpawnEntry(
    "MedicalTest",
    "medical",
    99,
    "test:medical"
)
T.truthy(medical and (
    medical.type == "Base.Bandage"
    or medical.type == "Base.AlcoholBandage"
), "generic equipment category selection")

T.load(ROOT .. "Inventory/PNC_Inventory_Actions.lua")
local interactionRecord = makeRecord("inventory_interaction", 5150)
interactionRecord.tacticalClass = "colonist"
local interactionInventory = PNC.Inventory.CreateFromTemplate(interactionRecord)
local added, addReason, addedIDs = PNC.Inventory.AddItems(interactionRecord, {
    {
        type = "Base.Tshirt_DefaultTEXTURE_TINT",
        stack = 1,
        itemState = { condition = 8, customName = "Travel Shirt" },
    },
}, "root", "smoke_add")
T.equal(added, true, "public inventory add")
T.equal(addReason, "added", "public inventory add reason")
T.equal(#addedIDs, 1, "public inventory add ID")
local addedItem = interactionInventory.items[addedIDs[1]]
T.equal(addedItem.itemState.condition, 8, "portable state retained")

local worn, wornReason = PNC.InventoryActions.Execute(
    "wear", nil, interactionRecord, addedItem.id, {}
)
T.equal(worn, true, "modular wear action")
T.equal(wornReason, "worn", "modular wear reason")
T.equal(addedItem.wornSlot, "Torso1", "worn slot applied")

local removedWorn = PNC.InventoryActions.Execute(
    "remove_worn", nil, interactionRecord, addedItem.id, {}
)
T.equal(removedWorn, true, "modular remove-worn action")
T.equal(addedItem.wornSlot, nil, "worn slot cleared")

local equipped = PNC.InventoryActions.Execute(
    "equip_primary", nil, interactionRecord, addedItem.id, {}
)
T.equal(equipped, true, "modular equip action")
T.equal(interactionInventory.equipped.primary, addedItem.id, "primary equipped")
T.equal(PNC.Inventory.SetEquipped(
    interactionRecord, "secondary", addedItem.id, "smoke_secondary"
), true, "move item to secondary")
T.equal(interactionInventory.equipped.primary, nil, "old equip slot cleared")
T.equal(interactionInventory.equipped.secondary, addedItem.id, "secondary equipped")
T.equal(PNC.Inventory.SetEquipped(
    interactionRecord, "primary", addedItem.id, "smoke_primary"
), true, "move item back to primary")
T.equal(interactionInventory.equipped.secondary, nil, "secondary slot cleared")
T.equal(interactionInventory.equipped.primary, addedItem.id, "primary restored")
T.equal(PNC.InventoryActions.Execute(
    "unequip", nil, interactionRecord, addedItem.id, {}
), true, "modular unequip action")
T.equal(interactionInventory.equipped.primary, nil, "primary cleared")

local favorited, favoriteReason = PNC.InventoryActions.Execute(
    "favorite", nil, interactionRecord, addedItem.id, {}
)
T.equal(favorited, true, "modular favorite action")
T.equal(favoriteReason, "favorited", "modular favorite reason")
T.equal(addedItem.fav, true, "favorite state applied")
local payload = PNC.Inventory.BuildFullPayload(interactionRecord)
T.equal(payload.items[addedItem.id].itemState.customName, "Travel Shirt",
    "portable state replicated")
T.equal(payload.items[addedItem.id].fav, true, "favorite state replicated")
T.equal(PNC.InventoryActions.Execute(
    "unfavorite", nil, interactionRecord, addedItem.id, {}
), true, "modular unfavorite action")
T.equal(addedItem.fav, false, "favorite state cleared")
T.equal(PNC.Inventory.RemoveItems(
    interactionRecord, { addedItem.id }, "smoke_remove"
), true, "public inventory remove")
T.equal(interactionInventory.items[addedItem.id], nil, "item removed")

local bagAdded, _, bagIDs = PNC.Inventory.AddItems(interactionRecord, {
    { type = "Base.Bag_Test", stack = 1 },
}, "root", "smoke_bag_add")
T.equal(bagAdded, true, "wearable container add")
local bagItem = interactionInventory.items[bagIDs[1]]
T.equal(bagItem.wearableSlot, "base:back", "container equipment slot")
T.equal(bagItem.weightReduction, 0.8, "container weight reduction")
T.equal(bagItem.maxWeight, 10, "container capacity")

T.equal(PNC.Inventory.AddItems(interactionRecord, {
    { type = "Base.Bandage", stack = 5 },
}, bagItem.bagContainer, "smoke_bag_contents"), true, "bag contents add")
local weightBeforeBagEquip = interactionInventory.cachedWeight
T.equal(PNC.InventoryActions.Execute(
    "equip_container", nil, interactionRecord, bagItem.id, {}
), true, "modular bag equip action")
T.equal(bagItem.wornSlot, "base:back", "bag worn slot")
T.equal(interactionInventory.worn["base:back"], bagItem.id, "bag worn reference")
local reducedContentsWeight =
    PNC.Inventory.Internal.getItemWeight("Base.Bandage") * 5 * 0.8
T.near(interactionInventory.cachedWeight, weightBeforeBagEquip - reducedContentsWeight, 0.0001, "equipped bag reduces contents weight")
local bagPayload = PNC.Inventory.BuildFullPayload(interactionRecord)
T.equal(bagPayload.items[bagItem.id].weightReduction, 0.8,
    "bag reduction replicated")
T.equal(bagPayload.items[bagItem.id].wearableSlot, "base:back",
    "bag equipment slot replicated")

local baseCarry = interactionInventory.maxWeight
local heavyUnitWeight = PNC.Inventory.Internal.getItemWeight("Base.HeavyLoad")
local severeStack = math.ceil(
    ((baseCarry * 1.8) - interactionInventory.cachedWeight) / heavyUnitWeight
)
T.equal(PNC.Inventory.AddItems(interactionRecord, {
    { type = "Base.HeavyLoad", stack = severeStack },
}, "root", "smoke_severe_load"), true, "severe load accepted below hard cap")
local encumbrance = PNC.Inventory.GetEncumbranceState(interactionRecord)
T.equal(encumbrance.level, "severe", "severe encumbrance threshold")

local strainDamageCalls = 0
PNC.Health = {
    ApplyStrainDamage = function(_, _, amount, floorRatio, reason)
        strainDamageCalls = strainDamageCalls + 1
        T.equal(amount, 1, "strain damage amount")
        T.equal(floorRatio, 0.75, "strain damage floor")
        T.equal(reason, "severe_encumbrance", "strain damage reason")
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
T.load(ROOT .. "Stamina/PNC_Stamina.lua")
local staminaSnapshot = PNC.Stamina.BuildSnapshot(interactionRecord)
T.truthy(staminaSnapshot.max < staminaSnapshot.baseMax,
    "encumbrance lowers maximum stamina")
T.equal(staminaSnapshot.encumbranceLevel, "severe",
    "stamina snapshot carries encumbrance")
local snapshotAverageReads = staminaAverageReads
local snapshotLevelReads = staminaLevelReads
local snapshotEncumbranceReads = staminaEncumbranceReads
PNC.Stamina.BuildSnapshot(interactionRecord)
T.equal(staminaAverageReads, snapshotAverageReads,
    "stamina replication recalculated skills")
T.equal(staminaLevelReads, snapshotLevelReads,
    "stamina replication recalculated skill levels")
T.equal(staminaEncumbranceReads, snapshotEncumbranceReads,
    "stamina replication recalculated encumbrance")
local averagesBeforeUpdate = staminaAverageReads
local encumbranceBeforeUpdate = staminaEncumbranceReads
PNC.Stamina.Update(interactionRecord, nil, 10000)
T.equal(staminaAverageReads - averagesBeforeUpdate, 1,
    "stamina update recalculated its skill average more than once")
T.equal(staminaEncumbranceReads - encumbranceBeforeUpdate, 1,
    "stamina update recalculated encumbrance more than once")
PNC.Stamina.Update(interactionRecord, nil, 16000)
T.equal(strainDamageCalls, 1, "severe load periodic strain damage")

T.equal(PNC.InventoryActions.Execute(
    "unequip_container", nil, interactionRecord, bagItem.id, {}
), true, "modular bag unequip action")
T.equal(bagItem.wornSlot, nil, "bag worn slot cleared")
T.finish("pnc_equipment_generation_smoke")

T.finish("pnc_equipment_generation_smoke")
