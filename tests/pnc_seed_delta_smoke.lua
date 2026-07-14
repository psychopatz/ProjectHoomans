local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"
local SHARED_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/"

package.path = SHARED_ROOT .. "?.lua;" .. package.path

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

local skillBias = { Strength = { min = 2, max = 2 } }
local loadout = {
    bagChoices = {},
    primaryChoices = {},
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
assertEqual(inventory.deltaMode, "template_plus_delta", "recruited inventory mode")
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
assertEqual(firstDelta.summary.itemCount, 1, "first delta summary item count")

assert(PNC.Inventory.ApplyDelta(record, {
    { op = "update", itemID = "loot_1", stack = 3, cond = 0.75 },
}, "test_update"), "inventory update failed")

local secondDelta = PNC.Inventory.BuildDeltaPayload(record, 1)
assertEqual(secondDelta.inventoryRevision, 2, "second delta revision")
assertEqual(#secondDelta.ops, 1, "second delta operation count")
local fullPayload = PNC.Inventory.BuildFullPayload(record)
assertEqual(fullPayload.items.loot_1.stack, 3, "full payload stack")
assertEqual(fullPayload.items.loot_1.cond, 0.75, "full payload condition")
local weightState = PNC.Inventory.GetWeightState(record)
assert(weightState.usedWeight > 0, "weight cache was not rebuilt")
assert(weightState.remainingWeight >= 0, "remaining weight is invalid")

local saved = PNC.Inventory.Serialize(record)
assertEqual(saved.deltaMode, "template_plus_delta", "serialized delta mode")
assertEqual(saved.template.generatorVersion, 1, "generator version")

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
assertEqual(hasNewTemplate, true, "new template item did not appear")
assertEqual(reloaded.inventory.items.loot_1.stack, 3, "updated stack lost on rebase")

print("pnc_seed_delta_smoke: ok")
