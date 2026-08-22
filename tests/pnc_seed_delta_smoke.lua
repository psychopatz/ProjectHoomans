local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SHARED_ROOT = T.path("ProjectHoomans", "shared", "")
local COMMON_ROOT = T.path("ProjectHoomans", "common_lua", "")
local SERVER_ROOT = T.path("ProjectHoomans", "server", "")
local CORE_ROOT = T.path("PsychopatzCore", "common", "")

T.addPackagePaths()

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

T.load(ROOT .. "Skills/PNC_Skills.lua")
T.load(ROOT .. "Inventory/PNC_Inventory.lua")

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
T.equal(sanitizedKeyCount, 64, "portable modData key bound")
T.equal(#sanitizedState.customName, 1024, "portable string bound")
T.equal(sanitizedState.unsupported, nil, "unsupported item state survived")
T.equal(sanitizedState.modData.nested, nil, "nested modData survived")

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
T.equal(PNC.Skills.GetLevel(record, "Strength"), math.min(10, oldBase + 2), "skill delta")
T.equal(PNC.Skills.GetLevel(record.id, "Strength"), 0, "skill lookup accepted record id")

local malformedProgress = {
    identitySeed = 42,
    archetypeID = "Test",
    faction = "colonist",
    weaponMode = "melee",
    progression = "legacy-invalid",
}
PNC.Skills.GetLevel(malformedProgress, "Strength")
T.equal(type(malformedProgress.progression), "table", "invalid progression was not normalized")
malformedProgress.progression.skillXP = 12
malformedProgress.progression.skillLevelDeltas = "invalid"
PNC.Skills.GetLevel(malformedProgress, "Strength")
T.equal(type(malformedProgress.progression.skillXP), "table", "invalid skill XP map was not normalized")
T.equal(type(malformedProgress.progression.skillLevelDeltas), "table", "invalid skill delta map was not normalized")

skillBias.Strength = { min = 5, max = 5 }
local newBase = PNC.Skills.GetBaseLevel(record, "Strength")
T.equal(PNC.Skills.GetLevel(record, "Strength"), math.min(10, newBase + 2), "skill automatic rebase")

local inventory = PNC.Inventory.CreateFromTemplate(record)
local seedOnly = PNC.Inventory.Serialize(record)
T.equal(seedOnly[2], "SEED_ONLY", "unchanged baseline persistence mode")
T.equal(seedOnly[5], nil, "seed-only inventory persisted a delta")
local bandageID
for id, item in pairs(inventory.items) do
    if item.templateKey == "tmpl:supply:medical_bandage" then bandageID = id end
end
T.truthy(bandageID, "stable template key missing")
T.truthy(PNC.Inventory.ApplyDelta(record, {
    { op = "remove", itemID = bandageID },
    { op = "add", item = { id = "loot_1", type = "Base.CustomLoot", container = "root" } },
}, "test"), "inventory delta failed")

local firstDelta = PNC.Inventory.BuildDeltaPayload(record, 0)
T.equal(firstDelta.inventoryRevision, 1, "first delta revision")
T.equal(#firstDelta.ops, 2, "first delta operation count")
T.equal(firstDelta.summary.itemCount, 2, "first delta summary item count")

T.truthy(PNC.Inventory.ApplyDelta(record, {
    { op = "update", itemID = "loot_1", stack = 3, cond = 0.75, ammoCount = 0 },
}, "test_update"), "inventory update failed")

local secondDelta = PNC.Inventory.BuildDeltaPayload(record, 1)
T.equal(secondDelta.inventoryRevision, 2, "second delta revision")
T.equal(#secondDelta.ops, 1, "second delta operation count")
local fullPayload = PNC.Inventory.BuildFullPayload(record)
T.equal(fullPayload.items.loot_1.stack, 3, "full payload stack")
T.equal(fullPayload.items.loot_1.cond, 0.75, "full payload condition")
T.equal(fullPayload.items.loot_1.ammoCount, 0, "full payload magazine state")
T.truthy(PNC.Inventory.ApplyDelta(record, {
    { op = "add", item = { id = "fallback_1", type = "Base.HuntingKnife", container = "root" } },
}, "test_fallback_add"), "fallback weapon add failed")
local equipped, equipReason = PNC.Inventory.EquipPrimary(record, "fallback_1", "test_equip")
T.equal(equipped, true, "primary equipment mutation")
T.equal(equipReason, "equipped_primary", "primary equipment mutation reason")
T.equal(record.inventory.equipped.primary, "fallback_1", "primary equipment slot")
T.equal(record.inventory.items.fallback_1.equipSlot, "primary", "primary item slot")
T.equal(PNC.Inventory.SetFavorite(
    record, "fallback_1", true, "test_favorite"
), true, "favorite mutation")
T.equal(record.inventory.items.fallback_1.fav, true, "favorite item state")
local equipDelta = PNC.Inventory.BuildDeltaPayload(record, 3)
T.equal(equipDelta.inventoryRevision, 5, "equipment delta revision")
T.equal(equipDelta.ops[1].op, "equip", "equipment delta operation")
T.equal(equipDelta.ops[1].itemID, "fallback_1", "equipment delta item")
T.equal(equipDelta.ops[2].op, "update", "favorite delta operation")
T.equal(equipDelta.ops[2].fav, true, "favorite delta value")
T.equal(equipDelta.equipment.primaryFullType, "Base.HuntingKnife",
    "delta carries authoritative equipment summary")
local locked, lockReason = PNC.Inventory.SetInteractionLocked(
    record,
    "loot_1",
    true,
    "quest_item",
    "test_interaction_lock"
)
T.equal(locked, true, "interaction lock mutation")
T.equal(lockReason, "interaction_locked", "interaction lock reason")
local lockDelta = PNC.Inventory.BuildDeltaPayload(record, 5)
T.equal(lockDelta.inventoryRevision, 6, "interaction lock delta revision")
T.equal(lockDelta.ops[1].op, "update", "interaction lock delta operation")
T.equal(lockDelta.ops[1].interactionLocked, true,
    "interaction lock delta state")
T.equal(lockDelta.ops[1].interactionLockReason, "quest_item",
    "interaction lock delta reason")
local weightState = PNC.Inventory.GetWeightState(record)
T.truthy(weightState.usedWeight > 0, "weight cache was not rebuilt")
T.truthy(weightState.remainingWeight >= 0, "remaining weight is invalid")

local identityCardID
for itemID, item in pairs(record.inventory.items) do
    if item.templateKey == "tmpl:identity_card:0" then
        identityCardID = itemID
        break
    end
end
T.truthy(identityCardID, "identity-card template item missing")
T.truthy(PNC.Inventory.ApplyDelta(record, {
    {
        op = "update",
        itemID = identityCardID,
        cond = 0,
        ammoCount = 0,
    },
}, "test_zero_state"), "zero-valued template state update failed")

local saved = PNC.Inventory.Serialize(record)
T.equal(saved[1], 2, "NPC inventory schema")
T.equal(saved[2], "BASELINE_DELTA", "NPC persistence mode")
T.equal(saved[4].generatorVersion, 1, "generator version")
T.equal(saved[5][1], 1, "core delta schema")

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
T.equal(hasBandage, false, "removed template item returned")
T.equal(hasLoot, true, "added item lost on rebase")
T.equal(hasNewTemplate, true, "new baseline item did not appear")
T.equal(reloaded.inventory.items.loot_1.stack, 3, "updated stack lost on rebase")
T.equal(reloaded.inventory.items.loot_1.ammoCount, 0, "magazine state lost on rebase")
T.equal(reloaded.inventory.equipped.primary, "fallback_1", "equipped primary lost on rebase")
T.equal(reloaded.inventory.items.fallback_1.equipSlot, "primary", "equipped item slot lost on rebase")
T.equal(reloaded.inventory.items.fallback_1.fav, true, "favorite item lost on rebase")
T.equal(reloaded.inventory.items.loot_1.interactionLocked, true,
    "interaction lock lost on rebase")
T.equal(reloaded.inventory.items.loot_1.interactionLockReason, "quest_item",
    "interaction lock reason lost on rebase")
local reloadedCard = PNC.Inventory.Internal.findItemByTemplateKey(
    reloaded.inventory,
    "tmpl:identity_card:0"
)
T.equal(reloadedCard.cond, 0, "zero condition lost on rebase")
T.equal(reloadedCard.ammoCount, 0, "zero ammo state lost on rebase")

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
T.equal(deposited, true, "abstract NPC storage deposit")
T.equal(depositReason, "deposited", "abstract NPC deposit reason")
T.equal(depositRecord.inventory.items[depositBandageID].stack, 1,
    "baseline NPC sparse removal")
T.equal(depositRecord.inventory.persistenceMode, "BASELINE_DELTA",
    "baseline NPC persistence mode after deposit")
local depositedPersistence = PNC.Inventory.Serialize(depositRecord)
T.equal(depositedPersistence[2], "BASELINE_DELTA",
    "storage deposit forced full NPC persistence")
local factionStorage = PNC.ColonyStorageRepository.GetPrimary("faction_a")
T.equal(factionStorage.inventory:getLogicalItemCount(), 1,
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
    local water = fullType == "Base.WaterBottle"
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
T.truthy(PNC.Inventory.MaterializeLooseInventory(reloaded, body),
    "abstract inventory did not materialize")
local physicalLoot = false
for i = 1, #liveItems do physicalLoot = physicalLoot or liveItems[i].fullType == "Base.CustomLoot" end
T.equal(physicalLoot, true, "loose item missing from live physical inventory")
local revisionBeforeCapture = reloaded.inventory.revision
T.truthy(PNC.Inventory.CaptureLooseInventory(reloaded, body),
    "live inventory did not abstract")
T.truthy(reloaded.inventory.revision > revisionBeforeCapture,
    "physical capture did not create a durable inventory revision")
local capturedLoot = false
for _, item in pairs(reloaded.inventory.items) do
    capturedLoot = capturedLoot or item.type == "Base.CustomLoot"
end
T.equal(capturedLoot, true, "physical item missing after abstraction")
T.equal(reloaded.inventory.equipped.primary, "fallback_1",
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
T.truthy(PNC.Inventory.MaterializeLooseInventory(liveRecord, transferBody),
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
T.equal(liveDeposited, true, "live NPC storage deposit")
T.equal(liveReason, "deposited", "live NPC deposit reason")
T.equal(#transferItems, physicalBefore - 1,
    "live physical adapter did not remove item")
T.equal(liveRecord.inventory.items[liveBandageID].stack, 1,
    "live compact overlay did not track removal")
T.equal(PNC.Inventory.Serialize(liveRecord)[2], "BASELINE_DELTA",
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
T.equal(repairedDeposit, true, "missing live mirror storage deposit")
T.equal(repairedReason, "deposited", "missing live mirror deposit reason")
T.equal(#repairItems, 0, "live mirror repair leaked a physical item")
T.equal(#transactionLogs, 1, "committed transaction was not logged once")
T.truthy(string.find(transactionLogs[1], "outcome=commit", 1, true),
    "transaction log omitted commit outcome")
T.truthy(string.find(transactionLogs[1], "mirror_shortfall=1", 1, true),
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
T.equal(rejectedDeposit, false, "missing item transaction was not rejected")
T.equal(#transactionLogs, 2, "rejected transaction was not logged once")
T.truthy(string.find(transactionLogs[2], "outcome=reject", 1, true),
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
T.equal(#transactionLogs, 2,
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
T.load(SHARED_ROOT .. "PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load(SHARED_ROOT .. "PNC/Core/Needs/PNC_NeedsStateCodec.lua")
T.load(SHARED_ROOT .. "PNC/Core/Needs/PNC_PlayerNeedsModel.lua")
T.load(SHARED_ROOT .. "PNC/Core/Needs/PNC_NeedsUtils.lua")
T.load(SERVER_ROOT .. "PNC/Needs/PNC_NeedsRepository.lua")
T.load(SERVER_ROOT .. "PNC/PNC_IndividualNeeds.lua")
require "PNC/Supply/PNC_SupplyRequest"
require "PNC/Supply/PNC_SupplyMetrics"
require "PNC/Supply/PNC_ItemUtility"
local fractionalTypeID = PsychopatzCore.Inventory.getItemTypeId(
    "Base.FractionalApple", true
)
local fractionalProfile = PNC.ItemUtility.GetStatic(
    fractionalTypeID, "Base.FractionalApple"
)
T.equal(fractionalProfile.hunger, 0.15,
    "native fractional hunger utility preservation")
local savedCreateItem = InventoryItemFactory.CreateItem
local savedScriptManager = getScriptManager
InventoryItemFactory.CreateItem = function() return nil end
getScriptManager = function()
    return { getItem = function(_, fullType)
        if fullType ~= "Base.ScriptScaleFood" then return nil end
        return {
            getHungerChange = function() return -15 end,
            getThirstChange = function() return 5 end,
            getCalories = function() return 720 end,
            getTypeString = function() return "Food" end,
        }
    end }
end
local scriptScaleTypeID = PsychopatzCore.Inventory.getItemTypeId(
    "Base.ScriptScaleFood", true
)
local scriptScaleProfile = PNC.ItemUtility.GetStatic(
    scriptScaleTypeID, "Base.ScriptScaleFood"
)
T.truthy(math.abs(scriptScaleProfile.hunger - 0.15) < 0.000001,
    "script hunger percentage was not normalized")
T.truthy(math.abs(scriptScaleProfile.negativeThirst - 0.05) < 0.000001,
    "script thirst percentage was not normalized")
T.equal(scriptScaleProfile.calories, 720,
    "script calories were incorrectly normalized")
InventoryItemFactory.CreateItem = savedCreateItem
getScriptManager = savedScriptManager
require "PNC/Supply/PNC_SupplyIndex"
require "PNC/Supply/PNC_SupplySelector"
require "PNC/Supply/PNC_StorageAccessPolicy"
require "PNC/Supply/PNC_SupplyInventory"
require "PNC/Journals/PNC_JournalRoutes"
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
T.load(SHARED_ROOT .. "PNC/Core/Health/PNC_Treatment.lua")

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
        name = id,
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
        thirst = options.thirst or 0.30,
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

-- Build 42 uses Base.WaterBottle; the old Full/Empty names are model names.
-- Existing compact records are migrated when their inventory is hydrated.
local legacyWaterNPC = supplyNPC(
    "supply_legacy_water", { emptyBaseline = true }
)
T.truthy(PNC.Inventory.AddItems(legacyWaterNPC, {
    { type = "Base.WaterBottleFull", stack = 1 },
}, "root", "test_legacy_water_alias"))
local migratedWater
for _, compact in pairs(legacyWaterNPC.inventory.items) do
    if compact.type == "Base.WaterBottle" then migratedWater = compact end
end
T.truthy(migratedWater, "legacy water alias was not normalized on creation")
migratedWater.type = "Base.WaterBottleEmpty"
PNC.Inventory.EnsureRecordInventory(legacyWaterNPC)
T.equal(migratedWater.type, "Base.WaterBottle",
    "legacy water alias was not normalized during hydration")

-- Storage is virtual while colony bases have no physical implementation. The
-- same centralized policy can later enable the already-supported home check.
local remoteNPC = supplyNPC("supply_remote", { emptyBaseline = true })
remoteNPC.x, remoteNPC.y = 1000, 1000
local remoteStorage, remoteReason =
    PNC.StorageAccessPolicy.Resolve(remoteNPC)
T.equal(remoteStorage, supplyStorage,
    "virtual colony access rejected a remote member")
T.equal(remoteReason, nil, "virtual colony access returned a failure")
T.equal(PNC.StorageAccessPolicy.SetAccessMode(
    PNC.StorageAccessPolicy.MODE.PHYSICAL_HOME), true,
    "physical storage access mode was rejected")
remoteStorage, remoteReason = PNC.StorageAccessPolicy.Resolve(remoteNPC)
T.equal(remoteStorage, nil,
    "physical colony access admitted a remote member")
T.equal(remoteReason, "storage_not_at_base",
    "physical colony access did not enforce the home area")
T.equal(PNC.StorageAccessPolicy.SetAccessMode(
    PNC.StorageAccessPolicy.MODE.VIRTUAL_COLONY), true,
    "virtual storage access mode could not be restored")

-- Personal inventory is consumed before storage is queried.
local personalNPC = supplyNPC("supply_personal", { emptyBaseline = true })
T.truthy(PNC.Inventory.AddItems(personalNPC, {
    { type = "Base.Apple", stack = 1, itemState = { age = 1 } },
}, "root", "test_personal_food"))
local storageBeforePersonal = supplyStorage.inventory:getLogicalItemCount()
local personalOK = SupplyService.Process({
    requesterId = personalNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 70,
})
T.equal(personalOK, true, "personal food request")
T.equal(supplyStorage.inventory:getLogicalItemCount(), storageBeforePersonal,
    "personal food withdrew storage")
T.truthy(PNC.IndividualNeeds.Get(personalNPC, "hunger") < 0.30,
    "personal food did not change hunger")
T.equal(PNC.Inventory.Serialize(personalNPC)[2], "SEED_ONLY",
    "temporary personal food delta did not compact")

-- Instant storage food acquisition enters inventory, then is consumed once.
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 2))
local foodNPC = supplyNPC("supply_food", { emptyBaseline = true })
local applesBefore = supplyStorage.inventory:count("Base.Apple")
local foodOK = SupplyService.Process({
    requesterId = foodNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
})
T.equal(foodOK, true, "storage food request")
T.equal(supplyStorage.inventory:count("Base.Apple"), applesBefore - 1,
    "storage food count did not decrease exactly once")
T.truthy(PNC.IndividualNeeds.Get(foodNPC, "hunger") < 0.30,
    "storage food was not used from NPC inventory")
local Journal = PNC.ColonyStorageJournal
local provisionActivity = Journal.Snapshot(supplyStorage)
local provisionEntry = provisionActivity[#provisionActivity]
T.equal(provisionEntry[Journal.FIELD.OPERATION], Journal.OPERATION.TAKE,
    "provision storage journal operation")
T.equal(provisionEntry[Journal.FIELD.ACTOR], foodNPC.name,
    "provision storage journal actor")
T.equal(provisionEntry[Journal.FIELD.REASON], "provision",
    "provision storage journal reason")
T.equal(PNC.Inventory.Serialize(foodNPC)[2], "SEED_ONLY",
    "acquired and consumed apple left sparse history")

T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 2))
PNC.SupplyIndex.Invalidate(supplyStorage)
local multiFoodNPC = supplyNPC("supply_multi_food", { emptyBaseline = true })
local multiBefore = supplyStorage.inventory:count("Base.Apple")
local multiFoodOK = SupplyService.Process({
    requesterId = multiFoodNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.40 }, priority = 85,
})
T.equal(multiFoodOK, true, "multiple food request")
T.equal(supplyStorage.inventory:count("Base.Apple"), multiBefore - 2,
    "multiple food request did not acquire bounded quantity")
T.truthy(PNC.IndividualNeeds.Get(multiFoodNPC, "hunger") <= 0.001,
    "multiple acquired foods did not reach target")
T.equal(PNC.Inventory.Serialize(multiFoodNPC)[2], "SEED_ONLY",
    "multiple temporary foods did not compact")

-- FEFO chooses earlier-expiring safe food, never the rotten candidate.
supplyStorage.inventory:clear()
local freshApple = nativeItem("Base.Apple")
freshApple.age = 1
local oldApple = nativeItem("Base.Apple")
oldApple.age = 8
local rottenApple = nativeItem("Base.Apple")
rottenApple.age = 12
T.truthy(CoreInventory.deposit(supplyStorage.inventory, freshApple, 1))
T.truthy(CoreInventory.deposit(supplyStorage.inventory, oldApple, 1))
T.truthy(CoreInventory.deposit(supplyStorage.inventory, rottenApple, 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local fefoNPC = supplyNPC("supply_fefo", { emptyBaseline = true })
T.equal(SupplyService.Process({
    requesterId = fefoNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
}), true, "FEFO food request")
local remainingExpiry = {}
for _, coreRecord in ipairs(supplyStorage.inventory.records) do
    local descriptor = PNC.ItemUtility.DescribeCoreRecord(coreRecord)
    remainingExpiry[#remainingExpiry + 1] = descriptor.expiry
end
table.sort(remainingExpiry)
T.equal(#remainingExpiry, 2, "FEFO removed wrong quantity")
T.truthy(remainingExpiry[1] < 0.2 and remainingExpiry[2] >= 1,
    "FEFO did not remove earlier-expiring safe food")

-- Hydration retains the drainable with its remaining state.
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.WaterBottle"), 1))
local waterNPC = supplyNPC("supply_water", { emptyBaseline = true })
local waterOK = SupplyService.Process({
    requesterId = waterNPC.id, resourceKind = "HYDRATION",
    required = { thirst = 0.15 }, priority = 90,
})
T.equal(waterOK, true, "storage hydration request")
local retainedWater
for _, compact in pairs(waterNPC.inventory.items) do
    if compact.type == "Base.WaterBottle" then retainedWater = compact end
end
T.truthy(retainedWater and math.abs((retainedWater.uses or 0) - 0.75) < 0.001,
    "hydration remaining-use state was not retained")
T.truthy(PNC.IndividualNeeds.Get(waterNPC, "thirst") < 0.30,
    "hydration use did not change need")

-- Medical acquisition precedes the existing treatment use path.
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Bandage"), 1))
local medicalNPC = supplyNPC("supply_medical", { emptyBaseline = true })
local medicalAcquire = PNC.NeedSupplyBridge.EnsureMedical(
    medicalNPC, "BANDAGE", "ForeArm_L", true
)
T.equal(medicalAcquire, true, "medical acquisition")
T.truthy(PNC.Treatment.HasNPCBandage(medicalNPC),
    "bandage did not enter NPC inventory")
T.equal(PNC.Treatment.TryNPCBandage(medicalNPC, "ForeArm_L"), true,
    "existing treatment did not use acquired bandage")
T.equal(medicalNPC.bandagedPart, "ForeArm_L",
    "medical condition was not changed by treatment")
T.equal(PNC.Treatment.HasNPCBandage(medicalNPC), false,
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
T.equal(scarceOK, false, "scarcity request unexpectedly succeeded")
T.equal(scarceReason, "no_supply", "scarcity reason")
local queriesAfter = PNC.SupplyMetrics.candidateQueries
local retryOK, retryReason = SupplyService.Process({
    requesterId = scarceNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 60,
})
T.equal(retryOK, false, "scarcity retry unexpectedly succeeded")
T.equal(retryReason, "retry_suppressed", "scarcity retry cooldown")
T.equal(PNC.SupplyMetrics.candidateQueries, queriesAfter,
    "retry cooldown still queried storage")
T.truthy(queriesAfter > queriesBefore, "initial scarcity did not query candidates")

-- Hunger consumes only an already-carried provision.  It must not turn into
-- an implicit trip to colony storage; the independent provision request
-- allocates the food first, and a later need request consumes it.
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 2))
PNC.SupplyIndex.Invalidate(supplyStorage)
local provisionedNPC = supplyNPC(
    "supply_personal_boundary", { emptyBaseline = true }
)
local storageBeforeNeed = supplyStorage.inventory:count("Base.Apple")
local missingProvision, missingReason = SupplyService.Process({
    requesterId = provisionedNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
}, { personalOnly = true, force = true })
T.equal(missingProvision, false,
    "empty carried provision unexpectedly satisfied hunger")
T.equal(missingReason, "personal_missing",
    "empty carried provision failure reason")
T.equal(supplyStorage.inventory:count("Base.Apple"), storageBeforeNeed,
    "hunger response fetched food directly from colony storage")
local provisionAcquire = SupplyService.Process({
    requesterId = provisionedNPC.id, purpose = "PROVISION",
    resourceKind = "FOOD", required = { hunger = 0.20 }, priority = 80,
}, { acquireOnly = true, ignorePersonal = true, force = true })
T.equal(provisionAcquire, true,
    "reserve provision could not bypass need retry cooldown")
T.equal(supplyStorage.inventory:count("Base.Apple"),
    storageBeforeNeed - 1, "provision did not allocate carried food")
local carriedUse = SupplyService.Process({
    requesterId = provisionedNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
}, { personalOnly = true, force = true })
T.equal(carriedUse, true, "carried provision was not consumed")
T.equal(supplyStorage.inventory:count("Base.Apple"),
    storageBeforeNeed - 1, "carried consumption touched colony storage")

-- One item cannot be duplicated across two NPC requests.
supplyStorage.inventory:clear()
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local firstNPC = supplyNPC("supply_first", { emptyBaseline = true })
local secondNPC = supplyNPC("supply_second", { emptyBaseline = true })
local firstOK = SupplyService.Process({ requesterId = firstNPC.id,
    resourceKind = "FOOD", required = { hunger = 0.20 }, priority = 80 })
local secondOK = SupplyService.Process({ requesterId = secondNPC.id,
    resourceKind = "FOOD", required = { hunger = 0.20 }, priority = 80 })
T.equal(firstOK, true, "first reservation claimant")
T.equal(secondOK, false, "second claimant duplicated single food")
T.equal(supplyStorage.inventory:count("Base.Apple"), 0,
    "single reserved food remained in storage")

-- A live NPC receives a native InventoryItem before personal use removes it.
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
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
T.equal(liveAcquire, true, "live instant acquisition")
T.equal(#liveSupplyItems, 1,
    "live acquisition did not enter physical inventory")
local liveUse, liveUseReason = SupplyService.Process({
    requesterId = liveSupplyNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
})
local liveSupplyState = PNC.NPCSupplyService.GetDebugState(liveSupplyNPC)
T.equal(liveUse, true, "live personal use " .. tostring(liveUseReason)
    .. " / " .. tostring(liveSupplyState.byKind.FOOD.lastUseFailure))
T.equal(#liveSupplyItems, 0,
    "live food use did not mutate physical inventory")
supplyBodies[liveSupplyNPC.id] = nil

-- A temporary native projection failure must not roll back authoritative
-- compact provisioning. The missing projection can reconcile on a later spawn.
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local projectionNPC = supplyNPC(
    "supply_projection_fallback", { emptyBaseline = true }
)
liveSupplyItems = {}
supplyBodies[projectionNPC.id] = liveSupplyBody
local projectionFactory = InventoryItemFactory.CreateItem
InventoryItemFactory.CreateItem = function() return nil end
instanceItem = nil
local projectionOK, projectionReason, projectionDetails =
    SupplyService.Process({
        requesterId = projectionNPC.id, resourceKind = "FOOD",
        required = { hunger = 0.20 }, priority = 80,
    }, { acquireOnly = true })
InventoryItemFactory.CreateItem = projectionFactory
T.equal(projectionOK, true,
    "native projection failure blocked compact provision: "
        .. tostring(projectionReason))
T.equal(projectionDetails.physicalProjectionMissing, true,
    "native projection failure was not reported")
T.equal(#liveSupplyItems, 0,
    "failed physical projection left partial native items")
local compactProjectionApple = false
for _, compactItem in pairs(
    PNC.Inventory.EnsureRecordInventory(projectionNPC).items or {}
) do
    if compactItem.type == "Base.Apple" then
        compactProjectionApple = true
        break
    end
end
T.equal(compactProjectionApple, true,
    "compact provision was not retained")
supplyBodies[projectionNPC.id] = nil

-- Live consumption is transactional: compact metadata cannot stand in for a
-- missing physical item while the NPC is visible.
local staleProjectionNPC = supplyNPC(
    "supply_stale_projection", { emptyBaseline = true }
)
T.truthy(PNC.Inventory.AddItems(staleProjectionNPC, {
    { type = "Base.Apple", stack = 1, itemState = { age = 1 } },
}, "root", "test_stale_projection_food"))
local staleItems = {}
local staleContainer = {}
function staleContainer:getItems() return javaList(staleItems) end
local staleBody = { getInventory = function() return staleContainer end }
supplyBodies[staleProjectionNPC.id] = staleBody
local staleOK, staleReason = SupplyService.Process({
    requesterId = staleProjectionNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
})
T.equal(staleOK, false,
    "stale physical projection allowed phantom eating: "
        .. tostring(staleReason))
T.equal(staleReason, "personal_use_failed",
    "stale physical projection reported the wrong transaction failure")
T.equal(PNC.IndividualNeeds.Get(staleProjectionNPC, "hunger"), 0.30,
    "failed phantom eating changed hunger")
local staleCompactCount = 0
for _, compact in pairs(staleProjectionNPC.inventory.items) do
    if compact.type == "Base.Apple" then staleCompactCount = staleCompactCount + 1 end
end
T.equal(staleCompactCount, 1,
    "failed phantom eating removed compact food")
supplyBodies[staleProjectionNPC.id] = nil

-- Acquired compact state survives save/load without FULL promotion.
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.WaterBottle"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local saveNPC = supplyNPC("supply_save", { emptyBaseline = true })
local saveAcquire = SupplyService.Process({
    requesterId = saveNPC.id, resourceKind = "HYDRATION",
    required = { thirst = 0.15 }, priority = 80,
}, { acquireOnly = true })
T.equal(saveAcquire, true, "save/load acquisition")
local supplySaved = PNC.Inventory.Serialize(saveNPC)
T.equal(supplySaved[2], "BASELINE_DELTA",
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
    if compact.type == "Base.WaterBottle" then reloadedWater = compact end
end
T.truthy(reloadedWater and math.abs((reloadedWater.uses or 0) - 1) < 0.001,
    "acquired drainable state did not survive save/load")

-- Consuming one baseline bandage records one missing template item.
loadout.supplies = {{ key = "baseline_bandage", type = "Base.Bandage",
    stack = 2, preferredContainer = "root" }}
local baselineMedicalNPC = supplyNPC("supply_baseline_medical")
T.equal(PNC.Treatment.TryNPCBandage(
    baselineMedicalNPC, "ForeArm_L"), true,
    "baseline bandage use")
local baselineMedicalSaved = PNC.Inventory.Serialize(baselineMedicalNPC)
T.equal(baselineMedicalSaved[2], "BASELINE_DELTA",
    "baseline bandage use promoted FULL")
T.equal(#(baselineMedicalSaved[5][3] or {}), 1,
    "baseline bandage decrement was not a sparse upsert")
loadout.supplies = {}

-- Unknown items fail conservatively instead of becoming food.
supplyStorage.inventory:clear()
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Mod.UnknownWidget"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local unknownNPC = supplyNPC("supply_unknown", { emptyBaseline = true })
local unknownOK, unknownReason = SupplyService.Process({
    requesterId = unknownNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 70,
})
T.equal(unknownOK, false, "unknown item selected as food")
T.equal(unknownReason, "no_supply", "unknown item failure reason")

local modWaterRecord = CoreInventory.encodeItem(
    nativeItem("Mod.WaterCanteen"), 1
)
local modWaterUtility = PNC.ItemUtility.DescribeCoreRecord(modWaterRecord)
T.equal(modWaterUtility.hydration, true,
    "compatible modded drink was not recognized")
T.equal(CoreInventory.getItemFullType(modWaterRecord[1]),
    "Mod.WaterCanteen", "modded ItemTypeId identity round trip")

-- Destination failure rolls the InventoryTransaction back and releases stock.
supplyStorage.inventory:clear()
T.truthy(CoreInventory.deposit(supplyStorage.inventory,
    nativeItem("Base.Apple"), 1))
PNC.SupplyIndex.Invalidate(supplyStorage)
local fullNPC = supplyNPC("supply_full", { emptyBaseline = true })
fullNPC.inventory.maxWeight = 0
PNC.Const.INVENTORY_HARD_CAPACITY = 0
local acceptsFull, acceptsFullReason = PNC.Inventory.CanAccept(fullNPC, {
    { type = "Base.Apple", stack = 1 },
}, "root")
T.equal(acceptsFull, false,
    "test full inventory preflight " .. tostring(acceptsFullReason))
local rollbackOK, rollbackReason = SupplyService.Process({
    requesterId = fullNPC.id, resourceKind = "FOOD",
    required = { hunger = 0.20 }, priority = 80,
})
T.equal(rollbackOK, false, "full inventory acquisition succeeded")
T.equal(rollbackReason, "no_capacity", "full inventory rejection reason")
T.equal(supplyStorage.inventory:count("Base.Apple"), 1,
    "failed transaction lost storage item")
T.equal(next(supplyStorage.inventory.reservations), nil,
    "failed transaction leaked reservation")
local fullHasApple = false
for _, compact in pairs(fullNPC.inventory.items) do
    fullHasApple = fullHasApple or compact.type == "Base.Apple"
end
T.equal(fullHasApple, false, "failed transaction changed NPC inventory")
PNC.Const.INVENTORY_HARD_CAPACITY = nil

-- Candidate evaluation is bounded by records, never logical quantities.
supplyStorage.inventory:clear()
supplyStorage.inventory.maxWeight = 100000000
for index = 1, 60 do
    T.truthy(CoreInventory.deposit(supplyStorage.inventory,
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
T.truthy(evaluatedDelta <= PNC.NeedsDefinitions.SUPPLY_MAX_CANDIDATES,
    "candidate evaluation exceeded bound")

-- Stable Needs evaluation performs zero stockpile queries.
local stableNPC = supplyNPC("supply_stable", {
    emptyBaseline = true, hunger = 0.10, thirst = 0.10,
})
local stableQueries = PNC.SupplyMetrics.candidateQueries
PNC.NeedSupplyBridge.Evaluate(stableNPC)
T.equal(PNC.SupplyMetrics.candidateQueries, stableQueries,
    "stable NPC searched stockpile")
loadout.supplies = supplyTestOriginalSupplies
T.finish("pnc_seed_delta_smoke")

T.finish("pnc_seed_delta_smoke")
