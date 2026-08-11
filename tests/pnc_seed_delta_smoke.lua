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

print("pnc_seed_delta_smoke: ok")
