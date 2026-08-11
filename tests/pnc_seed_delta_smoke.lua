local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/"
local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/"
local COMMON_ROOT = "Contents/mods/ProjectHoomans/common/media/lua/shared/"
local SERVER_ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/server/"
local CORE_ROOT = "../psychopatzCore/Contents/mods/PsychopatzCore/common/media/lua/shared/"

package.path = SHARED_ROOT .. "?.lua;" .. COMMON_ROOT .. "?.lua;"
    .. SERVER_ROOT .. "?.lua;"
    .. CORE_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local skillBias = { Strength = { min = 2, max = 2 } }
local loadout = {
    bagChoices = {},
    supplies = {
        { key = "medical_bandage", type = "Base.Bandage", stack = 2, preferredContainer = "root" },
    },
}

PNC = {
    Const = { INVENTORY_OPLOG_MAX = 32, GENERATOR_VERSION = 1 },
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do output[key] = PNC.Core.DeepCopy(item) end
            return output
        end,
        LogWarn = function() end,
    },
    Sandbox = {
        NPCMeleeWeaponSpawnChance = function() return 0 end,
        NPCRangedWeaponSpawnChance = function() return 0 end,
    },
    Identity = {
        NormalizeSeed = function(seed) return tonumber(seed) or 1 end,
        MixSeed = function(seed, salt)
            local value = tonumber(seed) or 1
            for i = 1, #tostring(salt) do value = (value * 33 + string.byte(tostring(salt), i)) % 2147483646 end
            return math.max(1, value)
        end,
        Index = function(seed, salt, count)
            if count <= 0 then return 1 end
            return (PNC.Identity.MixSeed(seed, salt) % count) + 1
        end,
        Range = function(seed, salt, low, high)
            return low + (PNC.Identity.MixSeed(seed, salt) % ((high - low) + 1))
        end,
        RollAppearance = function() return { outfitItems = {} } end,
    },
    Archetypes = {
        Get = function()
            return { id = "Test", skillBias = skillBias, loadout = loadout }
        end,
    },
    SkillCatalog = { GetAllSkillIDs = function() return { "Strength" } end },
    Equipment = {
        NormalizeLoadoutSpec = function(value)
            value = value or {}
            value.worn = value.worn or {}
            value.attached = value.attached or {}
            return value
        end,
    },
}

dofile(ROOT .. "Skills/PNC_Skills.lua")
dofile(ROOT .. "Inventory/PNC_Inventory.lua")

local oversizedState = {
    customName = string.rep("x", 1100),
    unsupported = { nested = true },
    modData = {},
}
for stateIndex = 1, 70 do
    oversizedState.modData["key_" .. tostring(stateIndex)] = stateIndex
end
oversizedState.modData.nested = { rejected = true }
local sanitizedState = PNC.Inventory.SanitizeItemState(oversizedState)
local sanitizedKeyCount = 0
for _, _ in pairs(sanitizedState.modData or {}) do
    sanitizedKeyCount = sanitizedKeyCount + 1
end
assertEqual(sanitizedKeyCount, 64, "portable modData key bound")
assertEqual(#sanitizedState.customName, 1024, "portable string bound")
assertEqual(sanitizedState.unsupported, nil, "unsupported item state survived")
assertEqual(sanitizedState.modData.nested, nil, "nested modData survived")

local record = {
    id = "npc_delta",
    identitySeed = 42,
    archetypeID = "Test",
    faction = "colonist",
    weaponMode = "melee",
    recruited = true,
    progression = { skillLevelDeltas = { Strength = 2 }, skillXP = {} },
    equipment = { worn = {}, attached = {} },
    runtime = {},
}

local oldBase = PNC.Skills.GetBaseLevel(record, "Strength")
assertEqual(PNC.Skills.GetLevel(record, "Strength"), math.min(10, oldBase + 2), "skill delta")
assertEqual(PNC.Skills.GetLevel(record.id, "Strength"), 0, "skill lookup accepted record id")

local malformedProgress = {
    identitySeed = 42,
    archetypeID = "Test",
    faction = "colonist",
    weaponMode = "melee",
    progression = "legacy-invalid",
}
PNC.Skills.GetLevel(malformedProgress, "Strength")
assertEqual(type(malformedProgress.progression), "table", "invalid progression was not normalized")
malformedProgress.progression.skillXP = 12
malformedProgress.progression.skillLevelDeltas = "invalid"
PNC.Skills.GetLevel(malformedProgress, "Strength")
assertEqual(type(malformedProgress.progression.skillXP), "table", "invalid skill XP map was not normalized")
assertEqual(type(malformedProgress.progression.skillLevelDeltas), "table", "invalid skill delta map was not normalized")

skillBias.Strength = { min = 5, max = 5 }
local newBase = PNC.Skills.GetBaseLevel(record, "Strength")
assertEqual(PNC.Skills.GetLevel(record, "Strength"), math.min(10, newBase + 2), "skill automatic rebase")

local inventory = PNC.Inventory.CreateFromTemplate(record)
local seedOnly = PNC.Inventory.Serialize(record)
assertEqual(seedOnly[2], "SEED_ONLY", "unchanged baseline persistence mode")
assertEqual(seedOnly[5], nil, "seed-only inventory persisted a delta")
local bandageID
for id, item in pairs(inventory.items) do
    if item.templateKey == "tmpl:supply:medical_bandage" then bandageID = id end
end
assert(bandageID, "stable template key missing")
assert(PNC.Inventory.ApplyDelta(record, {
    { op = "remove", itemID = bandageID },
    { op = "add", item = { id = "loot_1", type = "Base.CustomLoot", container = "root" } },
}, "test"), "inventory delta failed")

local firstDelta = PNC.Inventory.BuildDeltaPayload(record, 0)
assertEqual(firstDelta.inventoryRevision, 1, "first delta revision")
assertEqual(#firstDelta.ops, 2, "first delta operation count")
assertEqual(firstDelta.summary.itemCount, 2, "first delta summary item count")

assert(PNC.Inventory.ApplyDelta(record, {
    { op = "update", itemID = "loot_1", stack = 3, cond = 0.75, ammoCount = 0 },
}, "test_update"), "inventory update failed")

local secondDelta = PNC.Inventory.BuildDeltaPayload(record, 1)
assertEqual(secondDelta.inventoryRevision, 2, "second delta revision")
assertEqual(#secondDelta.ops, 1, "second delta operation count")
local fullPayload = PNC.Inventory.BuildFullPayload(record)
assertEqual(fullPayload.items.loot_1.stack, 3, "full payload stack")
assertEqual(fullPayload.items.loot_1.cond, 0.75, "full payload condition")
assertEqual(fullPayload.items.loot_1.ammoCount, 0, "full payload magazine state")
assert(PNC.Inventory.ApplyDelta(record, {
    { op = "add", item = { id = "fallback_1", type = "Base.HuntingKnife", container = "root" } },
}, "test_fallback_add"), "fallback weapon add failed")
local equipped, equipReason = PNC.Inventory.EquipPrimary(record, "fallback_1", "test_equip")
assertEqual(equipped, true, "primary equipment mutation")
assertEqual(equipReason, "equipped_primary", "primary equipment mutation reason")
assertEqual(record.inventory.equipped.primary, "fallback_1", "primary equipment slot")
assertEqual(record.inventory.items.fallback_1.equipSlot, "primary", "primary item slot")
assertEqual(PNC.Inventory.SetFavorite(
    record, "fallback_1", true, "test_favorite"
), true, "favorite mutation")
assertEqual(record.inventory.items.fallback_1.fav, true, "favorite item state")
local equipDelta = PNC.Inventory.BuildDeltaPayload(record, 3)
assertEqual(equipDelta.inventoryRevision, 5, "equipment delta revision")
assertEqual(equipDelta.ops[1].op, "equip", "equipment delta operation")
assertEqual(equipDelta.ops[1].itemID, "fallback_1", "equipment delta item")
assertEqual(equipDelta.ops[2].op, "update", "favorite delta operation")
assertEqual(equipDelta.ops[2].fav, true, "favorite delta value")
assertEqual(equipDelta.equipment.primaryFullType, "Base.HuntingKnife",
    "delta carries authoritative equipment summary")
local locked, lockReason = PNC.Inventory.SetInteractionLocked(
    record,
    "loot_1",
    true,
    "quest_item",
    "test_interaction_lock"
)
assertEqual(locked, true, "interaction lock mutation")
assertEqual(lockReason, "interaction_locked", "interaction lock reason")
local lockDelta = PNC.Inventory.BuildDeltaPayload(record, 5)
assertEqual(lockDelta.inventoryRevision, 6, "interaction lock delta revision")
assertEqual(lockDelta.ops[1].op, "update", "interaction lock delta operation")
assertEqual(lockDelta.ops[1].interactionLocked, true,
    "interaction lock delta state")
assertEqual(lockDelta.ops[1].interactionLockReason, "quest_item",
    "interaction lock delta reason")
local weightState = PNC.Inventory.GetWeightState(record)
assert(weightState.usedWeight > 0, "weight cache was not rebuilt")
assert(weightState.remainingWeight >= 0, "remaining weight is invalid")

local identityCardID
for itemID, item in pairs(record.inventory.items) do
    if item.templateKey == "tmpl:identity_card:0" then
        identityCardID = itemID
        break
    end
end
assert(identityCardID, "identity-card template item missing")
assert(PNC.Inventory.ApplyDelta(record, {
    {
        op = "update",
        itemID = identityCardID,
        cond = 0,
        ammoCount = 0,
    },
}, "test_zero_state"), "zero-valued template state update failed")

local saved = PNC.Inventory.Serialize(record)
assertEqual(saved[1], 2, "NPC inventory schema")
assertEqual(saved[2], "BASELINE_DELTA", "NPC persistence mode")
assertEqual(saved[4].generatorVersion, 1, "generator version")
assertEqual(saved[5][1], 1, "core delta schema")

loadout.supplies[#loadout.supplies + 1] = {
    key = "new_template_item",
    type = "Base.NewTemplateItem",
    stack = 1,
    preferredContainer = "root",
}
local reloaded = {
    id = record.id,
    identitySeed = record.identitySeed,
    archetypeID = "Test",
    faction = "colonist",
    weaponMode = "melee",
    recruited = true,
    progression = record.progression,
    equipment = { worn = {}, attached = {} },
    runtime = {},
}
PNC.Inventory.Deserialize(reloaded, saved)
local hasBandage = false
local hasLoot = false
local hasNewTemplate = false
for _, item in pairs(reloaded.inventory.items) do
    hasBandage = hasBandage or item.type == "Base.Bandage"
    hasLoot = hasLoot or item.type == "Base.CustomLoot"
    hasNewTemplate = hasNewTemplate or item.type == "Base.NewTemplateItem"
end
assertEqual(hasBandage, false, "removed template item returned")
assertEqual(hasLoot, true, "added item lost on rebase")
assertEqual(hasNewTemplate, true, "new baseline item did not appear")
assertEqual(reloaded.inventory.items.loot_1.stack, 3, "updated stack lost on rebase")
assertEqual(reloaded.inventory.items.loot_1.ammoCount, 0, "magazine state lost on rebase")
assertEqual(reloaded.inventory.equipped.primary, "fallback_1", "equipped primary lost on rebase")
assertEqual(reloaded.inventory.items.fallback_1.equipSlot, "primary", "equipped item slot lost on rebase")
assertEqual(reloaded.inventory.items.fallback_1.fav, true, "favorite item lost on rebase")
assertEqual(reloaded.inventory.items.loot_1.interactionLocked, true,
    "interaction lock lost on rebase")
assertEqual(reloaded.inventory.items.loot_1.interactionLockReason, "quest_item",
    "interaction lock reason lost on rebase")
local reloadedCard = PNC.Inventory.Internal.findItemByTemplateKey(
    reloaded.inventory,
    "tmpl:identity_card:0"
)
assertEqual(reloadedCard.cond, 0, "zero condition lost on rebase")
assertEqual(reloadedCard.ammoCount, 0, "zero ammo state lost on rebase")

isServer = function() return false end
isClient = function() return false end
isDebugEnabled = function() return true end
local modData = {}
ModData = { getOrCreate = function(key)
    modData[key] = modData[key] or {}
    return modData[key]
end }
local depositRecord = {
    id = "npc_storage_delta",
    identitySeed = 99,
    archetypeID = "Test",
    faction = "neutral",
    weaponMode = "melee",
    progression = { skillLevelDeltas = {}, skillXP = {} },
    equipment = { worn = {}, attached = {} },
    runtime = {},
}
PNC.Inventory.CreateFromTemplate(depositRecord)
local depositBandageID
for itemID, compact in pairs(depositRecord.inventory.items) do
    if compact.templateKey == "tmpl:supply:medical_bandage" then
        depositBandageID = itemID
    end
end
PNC.Registry = {
    Get = function(id) return id == depositRecord.id and depositRecord or nil end,
    GetLiveZombie = function() return nil end,
    MarkDirty = function() end,
}
PNC.Factions = { GetPlayerFaction = function() return { id = "faction_a" } end }
PNC.Communities = { GetForFaction = function()
    return {{ id = "colony_a", status = "active" }}
end }
local StorageService = require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService"
local deposited, depositReason = StorageService.RequestNPCDeposit({
    getUsername = function() return "tester" end,
    getAccessLevel = function() return "" end,
}, {
    requestId = "npc-storage:1",
    npcId = depositRecord.id,
    itemID = depositBandageID,
    quantity = 1,
    inventoryRevision = depositRecord.inventory.revision,
})
assertEqual(deposited, true, "abstract NPC storage deposit")
assertEqual(depositReason, "deposited", "abstract NPC deposit reason")
assertEqual(depositRecord.inventory.items[depositBandageID].stack, 1,
    "baseline NPC sparse removal")
assertEqual(depositRecord.inventory.persistenceMode, "BASELINE_DELTA",
    "baseline NPC persistence mode after deposit")
local depositedPersistence = PNC.Inventory.Serialize(depositRecord)
assertEqual(depositedPersistence[2], "BASELINE_DELTA",
    "storage deposit forced full NPC persistence")
local factionStorage = PNC.ColonyStorageRepository.GetPrimary("faction_a")
assertEqual(factionStorage.inventory:getLogicalItemCount(), 1,
    "NPC deposit missing from faction storage")

local function javaList(values)
    return { size = function() return #values end,
        get = function(_, index) return values[index + 1] end }
end
local function nativeItem(fullType)
    local item = { fullType = fullType, modData = {}, weight = 0.1 }
    local food = fullType == "Base.Apple"
        or fullType == "Base.FractionalApple"
        or string.find(fullType, "Mod.Food", 1, true) == 1
    local water = fullType == "Base.WaterBottleFull"
        or string.find(fullType, "Mod.Water", 1, true) == 1
    item.isFood = food
    item.isDrainable = water
    item.usedDelta = water and 1 or nil
    function item:getFullType() return self.fullType end
    function item:getCondition() return self.condition end
    function item:getConditionMax() return 10 end
    function item:setCondition(value) self.condition = value end
    function item:getUsedDelta() return self.usedDelta end
    function item:setUsedDelta(value) self.usedDelta = value end
    function item:IsDrainable() return self.usedDelta ~= nil end
    function item:isFavorite() return self.favorite == true end
    function item:setFavorite(value) self.favorite = value end
    function item:isCustomName() return self.customName ~= nil end
    function item:getName() return self.customName end
    function item:setName(value) self.customName = value end
    function item:getModData() return self.modData end
    function item:getActualWeight() return self.weight end
    function item:getWeight() return self.weight end
    function item:setActualWeight(value) self.weight = value end
    function item:getCurrentAmmoCount() return self.ammoCount end
    function item:setCurrentAmmoCount(value) self.ammoCount = value end
    function item:getHungerChange()
        if fullType == "Base.FractionalApple" then return -0.15 end
        return food and -0.20 or 0
    end
    function item:getThirstChange() return water and -0.15 or 0 end
    function item:getUseDelta() return water and 0.25 or 0 end
    function item:isWaterSource() return water end
    function item:isBandage() return fullType == "Base.Bandage" end
    function item:getAge() return self.age or 0 end
    function item:getOffAge() return food and 5 or nil end
    function item:getOffAgeMax() return food and 10 or nil end
    function item:isCooked() return false end
    function item:isBurnt() return false end
    function item:isFrozen() return false end
    function item:getFreezingTime() return 0 end
    return item
end
InventoryItemFactory = { CreateItem = nativeItem }
local liveItems = {}
local liveContainer = {}
function liveContainer:getItems() return javaList(liveItems) end
function liveContainer:AddItem(item) liveItems[#liveItems + 1] = item return item end
function liveContainer:DoRemoveItem(item)
    for i = #liveItems, 1, -1 do if liveItems[i] == item then table.remove(liveItems, i) return end end
end
local body = { getInventory = function() return liveContainer end }
assert(PNC.Inventory.MaterializeLooseInventory(reloaded, body),
    "abstract inventory did not materialize")
local physicalLoot = false
for i = 1, #liveItems do physicalLoot = physicalLoot or liveItems[i].fullType == "Base.CustomLoot" end
assertEqual(physicalLoot, true, "loose item missing from live physical inventory")
assert(PNC.Inventory.CaptureLooseInventory(reloaded, body),
    "live inventory did not abstract")
local capturedLoot = false
for _, item in pairs(reloaded.inventory.items) do
    capturedLoot = capturedLoot or item.type == "Base.CustomLoot"
end
assertEqual(capturedLoot, true, "physical item missing after abstraction")
assertEqual(reloaded.inventory.equipped.primary, "fallback_1",
    "physical round trip lost equipped item")

local liveRecord = {
    id = "npc_storage_live",
    identitySeed = 123,
    archetypeID = "Test",
    faction = "neutral",
    weaponMode = "melee",
    progression = { skillLevelDeltas = {}, skillXP = {} },
    equipment = { worn = {}, attached = {} },
    runtime = {},
}
PNC.Inventory.CreateFromTemplate(liveRecord)
local liveBandageID
for itemID, compact in pairs(liveRecord.inventory.items) do
    if compact.templateKey == "tmpl:supply:medical_bandage" then
        liveBandageID = itemID
    end
end
local transferItems = {}
local transferContainer = {}
function transferContainer:getItems() return javaList(transferItems) end
function transferContainer:AddItem(item)
    transferItems[#transferItems + 1] = item
    return item
end
function transferContainer:DoRemoveItem(item)
    for index = #transferItems, 1, -1 do
        if transferItems[index] == item then
            table.remove(transferItems, index)
            return true
        end
    end
    return false
end
local transferBody = { getInventory = function() return transferContainer end }
assert(PNC.Inventory.MaterializeLooseInventory(liveRecord, transferBody),
    "live NPC inventory did not materialize")
local physicalBefore = #transferItems
PNC.Registry.Get = function(id)
    return id == liveRecord.id and liveRecord or nil
end
PNC.Registry.GetLiveZombie = function(id)
    return id == liveRecord.id and transferBody or nil
end
local liveDeposited, liveReason = StorageService.RequestNPCDeposit({
    getUsername = function() return "tester" end,
    getAccessLevel = function() return "" end,
}, {
    requestId = "npc-storage:live",
    npcId = liveRecord.id,
    itemID = liveBandageID,
    quantity = 1,
    inventoryRevision = liveRecord.inventory.revision,
})
assertEqual(liveDeposited, true, "live NPC storage deposit")
assertEqual(liveReason, "deposited", "live NPC deposit reason")
assertEqual(#transferItems, physicalBefore - 1,
    "live physical adapter did not remove item")
assertEqual(liveRecord.inventory.items[liveBandageID].stack, 1,
    "live compact overlay did not track removal")
assertEqual(PNC.Inventory.Serialize(liveRecord)[2], "BASELINE_DELTA",
    "live NPC deposit promoted persistence to FULL")

local repairRecord = {
    id = "npc_storage_live_repair",
    identitySeed = 456,
    archetypeID = "Test",
    faction = "neutral",
    weaponMode = "melee",
    progression = { skillLevelDeltas = {}, skillXP = {} },
    equipment = { worn = {}, attached = {} },
    runtime = {},
}
PNC.Inventory.CreateFromTemplate(repairRecord)
local repairBandageID
for itemID, compact in pairs(repairRecord.inventory.items) do
    if compact.templateKey == "tmpl:supply:medical_bandage" then
        repairBandageID = itemID
    end
end
local repairItems = {}
local repairContainer = {}
function repairContainer:getItems() return javaList(repairItems) end
function repairContainer:AddItem(value)
    repairItems[#repairItems + 1] = value
    return value
end
function repairContainer:DoRemoveItem(value)
    for index = #repairItems, 1, -1 do
        if repairItems[index] == value then
            table.remove(repairItems, index)
            return true
        end
    end
    return false
end
local repairBody = { getInventory = function() return repairContainer end }
PNC.Registry.Get = function(id)
    return id == repairRecord.id and repairRecord or nil
end
PNC.Registry.GetLiveZombie = function(id)
    return id == repairRecord.id and repairBody or nil
end
local transactionLogs = {}
PNC.Core.LogInfo = function(message)
    transactionLogs[#transactionLogs + 1] = message
end
local repairedDeposit, repairedReason = StorageService.RequestNPCDeposit({
    getUsername = function() return "tester" end,
    getAccessLevel = function() return "" end,
}, {
    requestId = "npc-storage:repair",
    npcId = repairRecord.id,
    itemID = repairBandageID,
    quantity = 1,
    inventoryRevision = repairRecord.inventory.revision,
    transactionLogging = true,
})
assertEqual(repairedDeposit, true, "missing live mirror storage deposit")
assertEqual(repairedReason, "deposited", "missing live mirror deposit reason")
assertEqual(#repairItems, 0, "live mirror repair leaked a physical item")
assertEqual(#transactionLogs, 1, "committed transaction was not logged once")
assert(string.find(transactionLogs[1], "outcome=commit", 1, true),
    "transaction log omitted commit outcome")
assert(string.find(transactionLogs[1], "mirror_shortfall=1", 1, true),
    "transaction log omitted live mirror shortfall")
local rejectedDeposit = StorageService.RequestNPCDeposit({
    getUsername = function() return "tester" end,
    getAccessLevel = function() return "" end,
}, {
    requestId = "npc-storage:missing",
    npcId = repairRecord.id,
    itemID = "missing",
    quantity = 1,
    inventoryRevision = repairRecord.inventory.revision,
    transactionLogging = true,
})
assertEqual(rejectedDeposit, false, "missing item transaction was not rejected")
assertEqual(#transactionLogs, 2, "rejected transaction was not logged once")
assert(string.find(transactionLogs[2], "outcome=reject", 1, true),
    "transaction log omitted rejection outcome")
StorageService.RequestNPCDeposit({
    getUsername = function() return "tester" end,
    getAccessLevel = function() return "" end,
}, {
    requestId = "npc-storage:logging-off",
    npcId = repairRecord.id,
    itemID = "missing",
    quantity = 1,
    inventoryRevision = repairRecord.inventory.revision,
})
assertEqual(#transactionLogs, 2,
    "disabled transaction logging still emitted output")

-- Needs -> supply -> inventory -> use vertical slice.
PNC.Core.Now = function() return 0 end
PNC.Core.IsAuthority = function() return true end
PNC.Core.LogRecordDebug = function() end
PNC.Const.BANDAGE_TYPE = "Base.Bandage"
PNC.Const.BANDAGE_TYPES = { "Base.Bandage" }
getGameTime = function()
    return { getWorldAgeHours = function() return 100 end }
end
dofile(SHARED_ROOT .. "PNC/Core/Needs/PNC_NeedsDefinitions.lua")
dofile(SHARED_ROOT .. "PNC/Core/Needs/PNC_NeedsUtils.lua")
dofile(SERVER_ROOT .. "PNC/PNC_IndividualNeeds.lua")
require "PNC/Supply/PNC_SupplyRequest"
require "PNC/Supply/PNC_SupplyMetrics"
require "PNC/Supply/PNC_ItemUtility"
local fractionalTypeID = PsychopatzCore.Inventory.getItemTypeId(
    "Base.FractionalApple", true
)
local fractionalProfile = PNC.ItemUtility.GetStatic(
    fractionalTypeID, "Base.FractionalApple"
)
assertEqual(fractionalProfile.hunger, 0.15,
    "native fractional hunger utility preservation")
require "PNC/Supply/PNC_SupplyIndex"
require "PNC/Supply/PNC_SupplySelector"
require "PNC/Supply/PNC_StorageAccessPolicy"
require "PNC/Supply/PNC_SupplyInventory"
require "PNC/Supply/PNC_NPCSupplyService"
require "PNC/Needs/PNC_NeedSupplyBridge"
PNC.Skills = PNC.Skills or {}
PNC.Skills.AddXP = function() end
PNC.NPCWounds = {
    Bandage = function(record, partID)
        record.bandagedPart = partID
        return true, "bandaged"
    end,
    FindTreatableWound = function() return "ForeArm_L", { damage = 5 } end,
}
dofile(SHARED_ROOT .. "PNC/Core/Health/PNC_Treatment.lua")

local supplyTestOriginalSupplies = loadout.supplies
loadout.supplies = {}
local supplyRecords = {}
local supplyBodies = {}
PNC.Registry.Get = function(id) return supplyRecords[id] end
PNC.Registry.GetLiveZombie = function(id) return supplyBodies[id] end
PNC.Registry.MarkDirty = function() end
local supplyFaction = { id = "supply_faction" }
local supplyCommunity = {
    id = "supply_colony", factionID = supplyFaction.id, status = "active",
    home = { x = 10, y = 10, z = 0, radius = 20 }, memberIDs = {},
}
PNC.Factions.GetNPCFaction = function(id)
    return supplyCommunity.memberIDs[id] and supplyFaction or nil
end
PNC.Communities.GetNPCCommunity = function(id)
    return supplyCommunity.memberIDs[id] and supplyCommunity or nil
end

local supplySerial = 0
local function supplyNPC(id, options)
    options = options or {}
    supplySerial = supplySerial + 1
    local savedSupplies = loadout.supplies
    if options.emptyBaseline then loadout.supplies = {} end
    local value = {
        id = id, identitySeed = 1000 + supplySerial, archetypeID = "Test",
        faction = "colonist", recruited = true, alive = true,
        x = 10, y = 10, z = 0,
        progression = { skillLevelDeltas = {}, skillXP = {} },
        equipment = { worn = {}, attached = {} }, runtime = {},
    }
    PNC.Inventory.CreateFromTemplate(value)
    loadout.supplies = savedSupplies
    supplyRecords[id] = value
    supplyCommunity.memberIDs[id] = true
    PNC.IndividualNeeds.Ensure(value, {
        hunger = options.hunger or 0.30,
        hydration = options.hydration or 0.30,
        fatigue = 0,
    })
    return value
end

local supplyStorage = PNC.ColonyStorageRepository.GetPrimary(
    supplyFaction.id, supplyCommunity.id
)
supplyStorage.inventory:clear()
local SupplyService = PNC.NPCSupplyService
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"

-- Personal inventory is consumed before storage is queried.
local personalNPC = supplyNPC("supply_personal", { emptyBaseline = true })
assert(PNC.Inventory.AddItems(personalNPC, {
    { type = "Base.Apple", stack = 1, itemState = { age = 1 } },
}, "root", "test_personal_food"))
local storageBeforePersonal = supplyStorage.inventory:getLogicalItemCount()
local personalOK = SupplyService.Process({
    requesterId = personalNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 70,
})
assertEqual(personalOK, true, "personal food request")
assertEqual(supplyStorage.inventory:getLogicalItemCount(), storageBeforePersonal,
    "personal food withdrew storage")
assert(PNC.IndividualNeeds.Get(personalNPC, "hunger") < 0.30,
    "personal food did not change hunger")
assertEqual(PNC.Inventory.Serialize(personalNPC)[2], "SEED_ONLY",
    "temporary personal food delta did not compact")

-- Instant storage food acquisition enters inventory, then is consumed once.
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 2))
local foodNPC = supplyNPC("supply_food", { emptyBaseline = true })
local applesBefore = supplyStorage.inventory:count("Base.Apple")
local foodOK = SupplyService.Process({
    requesterId = foodNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
})
assertEqual(foodOK, true, "storage food request")
assertEqual(supplyStorage.inventory:count("Base.Apple"), applesBefore - 1,
    "storage food count did not decrease exactly once")
assert(PNC.IndividualNeeds.Get(foodNPC, "hunger") < 0.30,
    "storage food was not used from NPC inventory")
assertEqual(PNC.Inventory.Serialize(foodNPC)[2], "SEED_ONLY",
    "acquired and consumed apple left sparse history")

assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 2))
PNC.SupplyIndex.Invalidate(supplyStorage)
local multiFoodNPC = supplyNPC("supply_multi_food", { emptyBaseline = true })
local multiBefore = supplyStorage.inventory:count("Base.Apple")
local multiFoodOK = SupplyService.Process({
    requesterId = multiFoodNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.40 }, priority = 85,
})
assertEqual(multiFoodOK, true, "multiple food request")
assertEqual(supplyStorage.inventory:count("Base.Apple"), multiBefore - 2,
    "multiple food request did not acquire bounded quantity")
assert(PNC.IndividualNeeds.Get(multiFoodNPC, "hunger") <= 0.001,
    "multiple acquired foods did not reach target")
assertEqual(PNC.Inventory.Serialize(multiFoodNPC)[2], "SEED_ONLY",
    "multiple temporary foods did not compact")

-- FEFO chooses earlier-expiring safe food, never the rotten candidate.
supplyStorage.inventory:clear()
local freshApple = nativeItem("Base.Apple")
freshApple.age = 1
local oldApple = nativeItem("Base.Apple")
oldApple.age = 8
local rottenApple = nativeItem("Base.Apple")
rottenApple.age = 12
assert(CoreInventory.deposit(supplyStorage.inventory, freshApple, 1))
assert(CoreInventory.deposit(supplyStorage.inventory, oldApple, 1))
assert(CoreInventory.deposit(supplyStorage.inventory, rottenApple, 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local fefoNPC = supplyNPC("supply_fefo", { emptyBaseline = true })
assertEqual(SupplyService.Process({
    requesterId = fefoNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
}), true, "FEFO food request")
local remainingExpiry = {}
for _, coreRecord in ipairs(supplyStorage.inventory.records) do
    local descriptor = PNC.ItemUtility.DescribeCoreRecord(coreRecord)
    remainingExpiry[#remainingExpiry + 1] = descriptor.expiry
end
table.sort(remainingExpiry)
assertEqual(#remainingExpiry, 2, "FEFO removed wrong quantity")
assert(remainingExpiry[1] < 0.2 and remainingExpiry[2] >= 1,
    "FEFO did not remove earlier-expiring safe food")

-- Hydration retains the drainable with its remaining state.
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.WaterBottleFull"), 1))
local waterNPC = supplyNPC("supply_water", { emptyBaseline = true })
local waterOK = SupplyService.Process({
    requesterId = waterNPC.id, resourceKind = "HYDRATION",
    required = { thirst = 0.15 }, priority = 90,
})
assertEqual(waterOK, true, "storage hydration request")
local retainedWater
for _, compact in pairs(waterNPC.inventory.items) do
    if compact.type == "Base.WaterBottleFull" then retainedWater = compact end
end
assert(retainedWater and math.abs((retainedWater.uses or 0) - 0.75) < 0.001,
    "hydration remaining-use state was not retained")
assert(PNC.IndividualNeeds.Get(waterNPC, "hydration") < 0.30,
    "hydration use did not change need")

-- Medical acquisition precedes the existing treatment use path.
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Bandage"), 1))
local medicalNPC = supplyNPC("supply_medical", { emptyBaseline = true })
local medicalAcquire = PNC.NeedSupplyBridge.EnsureMedical(
    medicalNPC, "BANDAGE", "ForeArm_L", true
)
assertEqual(medicalAcquire, true, "medical acquisition")
assert(PNC.Treatment.HasNPCBandage(medicalNPC),
    "bandage did not enter NPC inventory")
assertEqual(PNC.Treatment.TryNPCBandage(medicalNPC, "ForeArm_L"), true,
    "existing treatment did not use acquired bandage")
assertEqual(medicalNPC.bandagedPart, "ForeArm_L",
    "medical condition was not changed by treatment")
assertEqual(PNC.Treatment.HasNPCBandage(medicalNPC), false,
    "used bandage remained in NPC inventory")

-- Scarcity sets a cooldown and the retry performs no second candidate query.
supplyStorage.inventory:clear()
PNC.SupplyIndex.Invalidate(supplyStorage)
local scarceNPC = supplyNPC("supply_scarce", { emptyBaseline = true })
local queriesBefore = PNC.SupplyMetrics.candidateQueries
local scarceOK, scarceReason = SupplyService.Process({
    requesterId = scarceNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 60,
})
assertEqual(scarceOK, false, "scarcity request unexpectedly succeeded")
assertEqual(scarceReason, "no_supply", "scarcity reason")
local queriesAfter = PNC.SupplyMetrics.candidateQueries
local retryOK, retryReason = SupplyService.Process({
    requesterId = scarceNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 60,
})
assertEqual(retryOK, false, "scarcity retry unexpectedly succeeded")
assertEqual(retryReason, "retry_suppressed", "scarcity retry cooldown")
assertEqual(PNC.SupplyMetrics.candidateQueries, queriesAfter,
    "retry cooldown still queried storage")
assert(queriesAfter > queriesBefore, "initial scarcity did not query candidates")

-- One item cannot be duplicated across two NPC requests.
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local firstNPC = supplyNPC("supply_first", { emptyBaseline = true })
local secondNPC = supplyNPC("supply_second", { emptyBaseline = true })
local firstOK = SupplyService.Process({ requesterId = firstNPC.id,
    resourceKind = "FOOD", required = { hunger = 0.20 }, priority = 80 })
local secondOK = SupplyService.Process({ requesterId = secondNPC.id,
    resourceKind = "FOOD", required = { hunger = 0.20 }, priority = 80 })
assertEqual(firstOK, true, "first reservation claimant")
assertEqual(secondOK, false, "second claimant duplicated single food")
assertEqual(supplyStorage.inventory:count("Base.Apple"), 0,
    "single reserved food remained in storage")

-- A live NPC receives a native InventoryItem before personal use removes it.
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local liveSupplyNPC = supplyNPC("supply_live", { emptyBaseline = true })
local liveSupplyItems = {}
local liveSupplyContainer = {}
function liveSupplyContainer:getItems() return javaList(liveSupplyItems) end
function liveSupplyContainer:AddItem(value)
    liveSupplyItems[#liveSupplyItems + 1] = value
    value.owner = self
    value.getContainer = function(self) return self.owner end
    return value
end
function liveSupplyContainer:DoRemoveItem(value)
    for index = #liveSupplyItems, 1, -1 do
        if liveSupplyItems[index] == value then
            table.remove(liveSupplyItems, index)
            return true
        end
    end
    return false
end
local liveSupplyBody = {
    getInventory = function() return liveSupplyContainer end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
}
supplyBodies[liveSupplyNPC.id] = liveSupplyBody
local liveAcquire = SupplyService.Process({
    requesterId = liveSupplyNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
}, { acquireOnly = true })
assertEqual(liveAcquire, true, "live instant acquisition")
assertEqual(#liveSupplyItems, 1,
    "live acquisition did not enter physical inventory")
local liveUse, liveUseReason = SupplyService.Process({
    requesterId = liveSupplyNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
})
local liveSupplyState = PNC.NPCSupplyService.GetDebugState(liveSupplyNPC)
assertEqual(liveUse, true, "live personal use " .. tostring(liveUseReason)
    .. " / " .. tostring(liveSupplyState.byKind.FOOD.lastUseFailure))
assertEqual(#liveSupplyItems, 0,
    "live food use did not mutate physical inventory")
supplyBodies[liveSupplyNPC.id] = nil

-- Acquired compact state survives save/load without FULL promotion.
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.WaterBottleFull"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local saveNPC = supplyNPC("supply_save", { emptyBaseline = true })
local saveAcquire = SupplyService.Process({
    requesterId = saveNPC.id, resourceKind = "HYDRATION",
    required = { thirst = 0.15 }, priority = 80,
}, { acquireOnly = true })
assertEqual(saveAcquire, true, "save/load acquisition")
local supplySaved = PNC.Inventory.Serialize(saveNPC)
assertEqual(supplySaved[2], "BASELINE_DELTA",
    "single acquisition promoted NPC to FULL")
local saveReloaded = {
    id = saveNPC.id, identitySeed = saveNPC.identitySeed,
    archetypeID = saveNPC.archetypeID, faction = "colonist",
    recruited = true, alive = true, progression = saveNPC.progression,
    equipment = { worn = {}, attached = {} }, runtime = {},
}
PNC.Inventory.Deserialize(saveReloaded, supplySaved)
local reloadedWater
for _, compact in pairs(saveReloaded.inventory.items) do
    if compact.type == "Base.WaterBottleFull" then reloadedWater = compact end
end
assert(reloadedWater and math.abs((reloadedWater.uses or 0) - 1) < 0.001,
    "acquired drainable state did not survive save/load")

-- Consuming one baseline bandage records one missing template item.
loadout.supplies = {{ key = "baseline_bandage", type = "Base.Bandage",
    stack = 2, preferredContainer = "root" }}
local baselineMedicalNPC = supplyNPC("supply_baseline_medical")
assertEqual(PNC.Treatment.TryNPCBandage(
    baselineMedicalNPC, "ForeArm_L"), true,
    "baseline bandage use")
local baselineMedicalSaved = PNC.Inventory.Serialize(baselineMedicalNPC)
assertEqual(baselineMedicalSaved[2], "BASELINE_DELTA",
    "baseline bandage use promoted FULL")
assertEqual(#(baselineMedicalSaved[5][3] or {}), 1,
    "baseline bandage decrement was not a sparse upsert")
loadout.supplies = {}

-- Unknown items fail conservatively instead of becoming food.
supplyStorage.inventory:clear()
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Mod.UnknownWidget"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local unknownNPC = supplyNPC("supply_unknown", { emptyBaseline = true })
local unknownOK, unknownReason = SupplyService.Process({
    requesterId = unknownNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 70,
})
assertEqual(unknownOK, false, "unknown item selected as food")
assertEqual(unknownReason, "no_supply", "unknown item failure reason")

local modWaterRecord = CoreInventory.encodeItem(
    nativeItem("Mod.WaterCanteen"), 1
)
local modWaterUtility = PNC.ItemUtility.DescribeCoreRecord(modWaterRecord)
assertEqual(modWaterUtility.hydration, true,
    "compatible modded drink was not recognized")
assertEqual(CoreInventory.getItemFullType(modWaterRecord[1]),
    "Mod.WaterCanteen", "modded ItemTypeId identity round trip")

-- Destination failure rolls the InventoryTransaction back and releases stock.
supplyStorage.inventory:clear()
assert(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local fullNPC = supplyNPC("supply_full", { emptyBaseline = true })
fullNPC.inventory.maxWeight = 0
PNC.Const.INVENTORY_HARD_CAPACITY = 0
local acceptsFull, acceptsFullReason = PNC.Inventory.CanAccept(fullNPC, {
    { type = "Base.Apple", stack = 1 },
}, "root")
assertEqual(acceptsFull, false,
    "test full inventory preflight " .. tostring(acceptsFullReason))
local rollbackOK, rollbackReason = SupplyService.Process({
    requesterId = fullNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
})
assertEqual(rollbackOK, false, "full inventory acquisition succeeded")
assertEqual(rollbackReason, "no_capacity", "full inventory rejection reason")
assertEqual(supplyStorage.inventory:count("Base.Apple"), 1,
    "failed transaction lost storage item")
assertEqual(next(supplyStorage.inventory.reservations), nil,
    "failed transaction leaked reservation")
local fullHasApple = false
for _, compact in pairs(fullNPC.inventory.items) do
    fullHasApple = fullHasApple or compact.type == "Base.Apple"
end
assertEqual(fullHasApple, false, "failed transaction changed NPC inventory")
PNC.Const.INVENTORY_HARD_CAPACITY = nil

-- Candidate evaluation is bounded by records, never logical quantities.
supplyStorage.inventory:clear()
supplyStorage.inventory.maxWeight = 100000000
for index = 1, 60 do
    assert(CoreInventory.deposit(supplyStorage.inventory,
        nativeItem("Mod.Food" .. tostring(index)), 10000))
end
PNC.SupplyIndex.Invalidate(supplyStorage)
local boundedNPC = supplyNPC("supply_bounded", { emptyBaseline = true })
local evaluatedBefore = PNC.SupplyMetrics.candidateItemsEvaluated
SupplyService.Process({ requesterId = boundedNPC.id,
    resourceKind = "FOOD", required = { hunger = 0.20 }, priority = 80 },
    { acquireOnly = true })
local evaluatedDelta = PNC.SupplyMetrics.candidateItemsEvaluated
    - evaluatedBefore
assert(evaluatedDelta <= PNC.NeedsDefinitions.SUPPLY_MAX_CANDIDATES,
    "candidate evaluation exceeded bound")

-- Stable Needs evaluation performs zero stockpile queries.
local stableNPC = supplyNPC("supply_stable", {
    emptyBaseline = true, hunger = 0.10, hydration = 0.10,
})
local stableQueries = PNC.SupplyMetrics.candidateQueries
PNC.NeedSupplyBridge.Evaluate(stableNPC)
assertEqual(PNC.SupplyMetrics.candidateQueries, stableQueries,
    "stable NPC searched stockpile")
loadout.supplies = supplyTestOriginalSupplies

print("pnc_seed_delta_smoke: ok")
