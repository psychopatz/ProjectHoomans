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
SandboxVars = { ProjectHoomans = {} }

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
PNC.IndividualNeeds.Set(npc, "hunger", 1, "test")
PNC.IndividualNeeds.Commands.ApplyFood(npc,
    { hunger = 0, calories = 600 }, "test_food")
T.equal(PNC.IndividualNeeds.Get(npc, "hunger"), 1,
    "nutrition is independent from fullness")
T.equal(PNC.IndividualNeeds.GetNutrition(npc).calories, 600,
    "food calories are recorded")
T.equal(npc.needs, nil, "needs are not stored in the NPC registry record")

local packed = PNC.NeedsStateCodec.Encode(PNC.NeedsRepository.Records, age)
T.equal(packed.v, 1, "compact codec version")
T.equal(packed.at, age, "one shared timestamp")
T.equal(#packed.n.owned, 5, "compact NPC tuple")
T.equal(packed.n.owned[1], 1000, "pressure stored as permille")
T.equal(packed.n.owned[4], 600, "calories stored as integer")
local decoded, decodedAt = PNC.NeedsStateCodec.Decode(packed)
T.equal(decodedAt, age, "shared timestamp round trip")
T.equal(decoded.owned.needs.hunger, 1, "need round trip")
local rejected = PNC.NeedsStateCodec.Decode({ v = 2, at = age, n = {} })
T.equal(rejected.owned, nil, "non-v1 payload is not migrated")

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
T.equal(persisted.v, 1, "repository writes only v1")
T.equal(persisted.at, age, "repository writes one timestamp")
T.equal(persisted.n.owned[4], 600, "repository persists nutrition")

PNC.Health = { ApplyDamage = function(record, _, event)
    record.health.current = record.health.current - event.amount
    return true
end }
state.hunger, state.thirst = 1, 1
local beforeZeroElapsed = npc.health.current
PNC.IndividualNeeds.Update(npc, 0, "maximum_pressure_no_elapsed")
T.equal(npc.health.current, beforeZeroElapsed,
    "maximum pressure is not instant death")
PNC.IndividualNeeds.Update(npc, 168, "nonlethal_catchup")
T.truthy(npc.health.current >= PNC.NeedsDefinitions.CONSEQUENCES.nonlethalHealthFloor,
    "default mortality OFF preserves safe floor")
SandboxVars.ProjectHoomans.PlayerOwnedNPCNeedMortality = true
PNC.IndividualNeeds.Update(npc, 168, "lethal_catchup")
T.truthy(npc.health.current < PNC.NeedsDefinitions.CONSEQUENCES.nonlethalHealthFloor,
    "mortality ON permits eventual lethal damage")

PNC.NeedsRepository.Remove(npc.id)
T.equal(PNC.NeedsRepository.Records[npc.id], nil,
    "permanent deletion removes compact need state")
T.finish("pnc_owned_needs_nutrition_persistence_smoke")

T.finish("pnc_owned_needs_nutrition_persistence_smoke")
