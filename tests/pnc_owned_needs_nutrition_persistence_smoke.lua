local T = require "tests/support/test"

PNC = {
    Core = { Now = function() return 0 end },
    Registry = { Data = {}, MarkDirty = function() end },
    Identity = { MixSeed = function() return 1 end },
}
package.preload["PsychopatzCore/Events/PC_EventBus"] = function()
    return { emit = function() end }
end
local age = 20
getGameTime = function()
    return { getWorldAgeHours = function() return age end }
end
ModData = { values = {}, getOrCreate = function(key)
    ModData.values[key] = ModData.values[key] or {}
    return ModData.values[key]
end }
SandboxVars = { ProjectHoomans = { PlayerOwnedNPCNutritionMode = 2 } }

local root = T.path("ProjectHoomans", "root", "")
T.load(root .. "shared/PNC/Core/Events/PNC_EventDefinitions.lua")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsDefinitions.lua")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsStateCodec.lua")
T.load(root .. "shared/PNC/Core/Needs/PNC_PlayerNeedsModel.lua")
T.load(root .. "shared/PNC/Core/Needs/PNC_NeedsUtils.lua")
T.load(root .. "shared/PNC/Core/Base/PNC_Sandbox.lua")
T.load(root .. "server/PNC/Needs/PNC_NeedsRepository.lua")
T.load(root .. "server/PNC/Needs/PNC_IndividualNeeds.lua")
T.load(root .. "server/PNC/Needs/PNC_NeedHealthConsequences.lua")

local outsider = { id = "outsider", alive = true }
T.equal(PNC.IndividualNeeds.Ensure(outsider), nil,
    "non-owned NPC has no detailed needs")

local npc = { id = "owned", recruited = true, alive = true,
    vanillaTraits = {}, vanillaTraitsAuthored = true,
    health = { current = 100, max = 100, state = "normal" } }
PNC.Registry.Data[npc.id] = npc
local state = PNC.IndividualNeeds.Ensure(npc)
local modelNutrition = {
    calories = 800, carbohydrates = 0, proteins = 0, lipids = 0, weight = 80,
}
local modelOldCategory, modelNewCategory = PNC.NPCNutrition.Update(
    modelNutrition, 3600, "idle", false, false, 1, 1)
T.equal(modelOldCategory, "NORMAL", "realism starts at the normal weight band")
T.equal(modelNewCategory, "NORMAL", "one hour of idle metabolism keeps weight band")
T.near(modelNutrition.calories, 742.4, 0.000001,
    "realism uses the player idle calorie coefficient")
T.near(modelNutrition.carbohydrates, -12.6, 0.000001,
    "realism drains carbohydrates in world seconds")
T.near(modelNutrition.proteins, -3.096, 0.000001,
    "realism drains proteins in world seconds")
T.near(modelNutrition.lipids, -4.068, 0.000001,
    "realism drains lipids in world seconds")
T.equal(PNC.NPCNutrition.WeightCategory(50), "EMACIATED",
    "realism mirrors the player emaciated threshold")
T.equal(PNC.NPCNutrition.WeightCategory(85), "OVERWEIGHT",
    "realism mirrors the player overweight threshold")
PNC.IndividualNeeds.Set(npc, "hunger", 1, "test")
PNC.IndividualNeeds.Commands.ApplyFood(npc,
    { hunger = 0, calories = 600, carbohydrates = 120,
        proteins = 40, lipids = 20 }, "test_food")
T.equal(PNC.IndividualNeeds.Get(npc, "hunger"), 1,
    "nutrition is independent from fullness")
T.equal(PNC.IndividualNeeds.GetNutrition(npc).calories, 1400,
    "food calories are recorded")
T.equal(PNC.IndividualNeeds.GetNutrition(npc).carbohydrates, 120,
    "food carbohydrates are recorded")
T.equal(PNC.IndividualNeeds.GetNutrition(npc).proteins, 40,
    "food proteins are recorded")
T.equal(PNC.IndividualNeeds.GetNutrition(npc).lipids, 20,
    "food lipids are recorded")
local overflowNpc = { id = "overflow", recruited = true, alive = true,
    vanillaTraits = {}, vanillaTraitsAuthored = true,
    health = { current = 100, max = 100, state = "normal" } }
PNC.Registry.Data[overflowNpc.id] = overflowNpc
local overflowNutrition = PNC.IndividualNeeds.GetNutrition(overflowNpc)
overflowNutrition.calories = PNC.NeedsDefinitions.NUTRITION.maximumCalories
PNC.IndividualNeeds.Commands.ApplyFood(overflowNpc,
    { hunger = 0, calories = 500 }, "overflow_food")
T.equal(overflowNutrition.calories,
    PNC.NeedsDefinitions.NUTRITION.maximumCalories,
    "visible calories remain at the configured display cap")
T.equal(overflowNutrition.calorieOverflow, 0,
    "realism uses the player calorie cap without overflow")
local overflowPackedBeforeBurn = PNC.NeedsStateCodec.Encode(
    PNC.NeedsRepository.Records, age)
T.equal(overflowPackedBeforeBurn.n.overflow[11], 1,
    "realism nutrition presence is persisted")
local overflowDecoded = PNC.NeedsStateCodec.Decode(overflowPackedBeforeBurn)
T.equal(overflowDecoded.overflow.nutrition.calorieOverflow, 0,
    "legacy overflow is not retained outside player calorie bounds")
PNC.IndividualNeeds.ModifyNutrition(overflowNpc, -200, "burn_overflow")
T.equal(overflowNutrition.calories,
    PNC.NeedsDefinitions.NUTRITION.maximumCalories - 200,
    "calorie burn starts at the visible player cap")
PNC.IndividualNeeds.ModifyNutrition(overflowNpc, -400, "burn_balance")
T.equal(overflowNutrition.calorieOverflow, 0,
    "realism never creates calorie overflow")
T.equal(overflowNutrition.calories,
    PNC.NeedsDefinitions.NUTRITION.maximumCalories - 600,
    "calorie burn continues below the visible cap")
T.equal(npc.needs, nil, "needs are not stored in the NPC registry record")

local packed = PNC.NeedsStateCodec.Encode(PNC.NeedsRepository.Records, age)
T.equal(packed.v, 2, "compact codec version")
T.equal(packed.at, age, "one shared timestamp")
T.truthy(#packed.n.owned >= 5, "compact NPC tuple")
T.equal(packed.n.owned[1], 1000, "pressure stored as permille")
T.equal(packed.n.owned[4], 1400, "calories stored as integer")
local decoded, decodedAt = PNC.NeedsStateCodec.Decode(packed)
T.equal(decodedAt, age, "shared timestamp round trip")
T.equal(decoded.owned.needs.hunger, 1, "need round trip")
local overflowPacked = PNC.NeedsStateCodec.Encode(
    PNC.NeedsRepository.Records, age)
T.equal(overflowPacked.n.overflow[8], 0,
    "zero carbohydrate balance is compactly represented")
local unsupportedDecoded, unsupportedAt, unsupportedReason = PNC.NeedsStateCodec.Decode({
    v = 1, at = age, n = { legacy = { 0, 0, 0, 3700, 800, nil, nil, 500 } },
})
T.equal(unsupportedAt, 0, "unsupported payload is not partially restored")
T.equal(unsupportedReason, "version_mismatch",
    "unsupported payload requests a reset")
local unsupportedCount = 0
for _, _ in pairs(unsupportedDecoded) do unsupportedCount = unsupportedCount + 1 end
T.equal(unsupportedCount, 0, "unsupported payload is discarded")

for _, population in ipairs({ 100, 500, 1000 }) do
    local many = {}
    for index = 1, population do
        many[tostring(index)] = {
            needs = { hunger = index % 10 / 10, thirst = 0.5,
                fatigue = 0.25 },
            nutrition = { calories = index, weight = 80 + index % 5 },
        }
    end
    local scalePacked = PNC.NeedsStateCodec.Encode(many, age)
    local scaleDecoded = PNC.NeedsStateCodec.Decode(scalePacked)
    local count = 0
    for _, _ in pairs(scaleDecoded) do count = count + 1 end
    T.equal(count, population,
        tostring(population) .. " owned-need records round trip")
end

T.equal(PNC.NeedsRepository.Save(), true, "dirty compact state saves")
local persisted = ModData.values[PNC.NeedsRepository.MODDATA_KEY]
T.equal(persisted.v, 2, "repository writes v2")
T.equal(persisted.at, age, "repository writes one timestamp")
T.equal(persisted.n.owned[4], 1400, "repository persists nutrition")

SandboxVars.ProjectHoomans.PlayerOwnedNPCNutritionMode = 1
local simpleNPC = { id = "simple", recruited = true, alive = true,
    vanillaTraits = {}, vanillaTraitsAuthored = true }
PNC.Registry.Data[simpleNPC.id] = simpleNPC
T.truthy(PNC.IndividualNeeds.Ensure(simpleNPC),
    "simple mode still initializes primitive needs")
T.equal(PNC.IndividualNeeds.GetNutrition(simpleNPC), nil,
    "simple mode does not allocate detailed nutrition")
PNC.IndividualNeeds.Commands.ApplyFood(simpleNPC,
    { hunger = 0.25, calories = 900, carbohydrates = 50 }, "simple_food")
T.equal(PNC.IndividualNeeds.GetNutrition(simpleNPC), nil,
    "simple food does not create detailed nutrition")
SandboxVars.ProjectHoomans.PlayerOwnedNPCNutritionMode = 2

PNC.Health = { ApplyDamage = function(record, _, event)
    record.health.current = record.health.current - event.amount
    return true
end }
state.hunger, state.thirst = 1, 1
local beforeZeroElapsed = npc.health.current
PNC.IndividualNeeds.Update(npc, 0, "maximum_pressure_no_elapsed")
T.equal(npc.health.current, beforeZeroElapsed,
    "maximum pressure is not instant death")
T.truthy(PNC.Sandbox.PlayerOwnedNPCNeedMortalityEnabled(),
    "need mortality is enabled by default")
SandboxVars.ProjectHoomans.PlayerOwnedNPCNeedMortality = false
PNC.IndividualNeeds.Update(npc, 168, "nonlethal_catchup")
T.truthy(npc.health.current >= PNC.NeedsDefinitions.CONSEQUENCES.nonlethalHealthFloor,
    "disabled mortality preserves safe floor")
SandboxVars.ProjectHoomans.PlayerOwnedNPCNeedMortality = true
PNC.IndividualNeeds.Update(npc, 168, "lethal_catchup")
T.truthy(npc.health.current < PNC.NeedsDefinitions.CONSEQUENCES.nonlethalHealthFloor,
    "mortality ON permits eventual lethal damage")

local persistedBeforeReset = ModData.values[PNC.NeedsRepository.MODDATA_KEY]
for _, unsupportedVersion in ipairs({ 1, PNC.NeedsStateCodec.VERSION + 1 }) do
    persistedBeforeReset.v = unsupportedVersion
    PNC.NeedsRepository.Loaded = false
    PNC.NeedsRepository.Load(true)
    local resetCount = 0
    for _, _ in pairs(PNC.NeedsRepository.Records) do resetCount = resetCount + 1 end
    T.equal(resetCount, 0, "repository discards unsupported state")
    T.equal(PNC.NeedsRepository.LastReset.reason, "version_mismatch",
        "repository records the reset reason")
    T.equal(PNC.NeedsRepository.LastReset.fromVersion, unsupportedVersion,
        "repository records the unsupported version")
    T.equal(PNC.NeedsRepository.Dirty, true,
        "repository schedules the reset payload for save")
    T.equal(PNC.NeedsRepository.Save(), true,
        "repository saves a clean payload after reset")
    T.equal(ModData.values[PNC.NeedsRepository.MODDATA_KEY].v,
        PNC.NeedsStateCodec.VERSION,
        "repository rewrites the current version after reset")
    local resetPayloadCount = 0
    for _, _ in pairs(ModData.values[PNC.NeedsRepository.MODDATA_KEY].n) do
        resetPayloadCount = resetPayloadCount + 1
    end
    T.equal(resetPayloadCount, 0, "reset payload contains no stale records")
end

PNC.NeedsRepository.Remove(npc.id)
T.equal(PNC.NeedsRepository.Records[npc.id], nil,
    "permanent deletion removes compact need state")
T.finish("pnc_owned_needs_nutrition_persistence_smoke")

T.finish("pnc_owned_needs_nutrition_persistence_smoke")
