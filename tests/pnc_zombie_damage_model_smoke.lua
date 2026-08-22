local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local now = 1000
local staminaRatio = 1
local fitness = 0
local nearby = 1
local randomValues = {}

ZombRand = function()
    return table.remove(randomValues, 1) or 0
end

PNC = {
    Const = {
        NPC_ZOMBIE_DEFENSE_RADIUS = 2.2,
        NPC_ZOMBIE_DEFENSE_REFRESH_MS = 200,
        NPC_ZOMBIE_DEFENSE_PUSH_CHANCE = 0.5,
    },
    Core = {
        Now = function() return now end,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return dx * dx + dy * dy
        end,
        IsManagedNPCBody = function() return false end,
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local copy = {}
            for key, item in pairs(value) do
                copy[key] = PNC.Core.DeepCopy(item)
            end
            return copy
        end,
    },
    Skills = {
        GetLevel = function(_, skill)
            T.equal(skill, "Fitness", "damage model skill")
            return fitness
        end,
    },
    Stamina = {
        GetRatio = function() return staminaRatio end,
    },
    SpatialIndex = {
        QueryZombies = function()
            local output = {}
            for index = 1, nearby do
                output[index] = {
                    isDead = function() return false end,
                    getX = function() return index * 0.2 end,
                    getY = function() return 0 end,
                    getZ = function() return 0 end,
                }
            end
            return output
        end,
    },
    Sandbox = {
        NPCZombieDamageModelEnabled = function() return true end,
        NPCZombieDamageStaminaStartRatio = function() return 0.30 end,
        NPCZombieDamageBaseChance = function() return 0 end,
        NPCZombieDamageHitRadius = function() return 2.2 end,
        NPCZombieDamageCrowdChancePerExtra = function() return 5 end,
        NPCZombieDamageCrowdEscalation = function() return 2 end,
        NPCZombieDamageCrowdChanceCap = function() return 100 end,
        NPCZombieDamageMinimumSkillMitigation = function() return 15 end,
        NPCZombieDamageFitnessMitigationScale = function() return 45 end,
        NPCZombieDamageMaximumSkillMitigation = function() return 60 end,
    },
    NPCWounds = {
        ChooseZombieAttackPart = function()
            return { id = "Torso_Upper" }
        end,
        RollZombieAttackType = function()
            error("wound type must not roll while stamina is safe")
        end,
    },
}

local Defense = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/PNC_Combat_Defense.lua"
)

local record = {
    id = "damage_model",
    x = 0,
    y = 0,
    z = 0,
    runtime = {},
}
local body = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

local chance, details = Defense.CalculateDamageChance(record, 1)
T.near(chance, 0, 0.000001, "full stamina is immune")
T.near(details.crowdChance, 0, 0.000001, "one zombie crowd chance")

randomValues = { 0, 0 }
local avoided, safeResult = Defense.ResolveZombieAttack(
    record,
    body,
    {},
    now
)
T.equal(avoided, true, "safe stamina avoids the attack")
T.equal(safeResult.outcome, "stamina_safe", "safe stamina outcome")

staminaRatio = 0
nearby = 2
chance, details = Defense.CalculateDamageChance(record, nearby)
T.near(details.crowdChance, 5, 0.000001, "two zombie crowd chance")
T.near(chance, 0.0425, 0.000001, "two zombie exhausted chance")

PNC.NPCWounds.RollZombieAttackType = function() return "bite" end
randomValues = { 0 }
local exposed, exposedResult = Defense.ResolveZombieAttack(
    record,
    body,
    {},
    now + 201
)
T.equal(exposed, false, "low stamina exposes the attack")
T.equal(exposedResult.damageType, "bite", "bite type rolls after exposure")

nearby = 3
chance, details = Defense.CalculateDamageChance(record, nearby)
T.near(details.crowdChance, 10, 0.000001, "three zombie crowd chance")
T.near(chance, 0.085, 0.000001, "three zombie exhausted chance")

fitness = 10
chance = Defense.CalculateDamageChance(record, 3)
T.near(chance, 0.04, 0.000001, "Fitness mitigates crowd chance")

SandboxVars = {
    ProjectHoomans = {
        NPCZombieDamageModel = true,
        NPCZombieClothingConditionExponent = 1,
        NPCZombieClothingBlockMultiplier = 1,
        NPCZombieClothingSafeDurabilityLoss = 1,
        NPCZombieClothingPenetratingDurabilityLoss = 2,
        NPCZombieClothingDowngradeLaceration = 25,
        NPCZombieClothingDowngradeScratch = 60,
        NPCZombieBiteChance = 20,
        NPCZombieLacerationChance = 30,
    },
}

PNC = PNC
PNC.Sandbox = nil
T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_Sandbox.lua")
local Wounds = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_NPCWounds.lua"
)

local condition = 10
local coveredParts = {
    size = function() return 1 end,
    get = function(_, index)
        return index == 0 and "Torso_Upper" or nil
    end,
}
local item = {
    getCoveredParts = function() return coveredParts end,
    getBiteDefense = function() return 80 end,
    getScratchDefense = function() return 60 end,
    getCondition = function() return condition end,
    getConditionMax = function() return 10 end,
    setCondition = function(_, value) condition = value end,
}
local wornEntry = {
    getItem = function() return item end,
    getLocation = function() return "FullSuit" end,
}
local wornItems = {
    size = function() return 1 end,
    get = function() return wornEntry end,
}
local clothingBody = {
    getWornItems = function() return wornItems end,
}
local part = { id = "Torso_Upper" }

randomValues = { 0 }
local clothing = Wounds.ResolveZombieClothing(
    clothingBody,
    part,
    "bite"
)
T.equal(clothing.blocked, true, "clothing blocks the bite")
T.equal(clothing.finalWoundType, nil, "blocked bite has no wound")
T.equal(condition, 9, "blocked clothing loses one condition")

condition = 10
randomValues = { 9999 }
clothing = Wounds.ResolveZombieClothing(
    clothingBody,
    part,
    "bite"
)
T.equal(clothing.blocked, false, "penetrating clothing roll")
T.equal(clothing.finalWoundType, "scratch", "strong clothing downgrades bite")
T.equal(condition, 8, "penetrating clothing loses two condition")

randomValues = { 0 }
T.equal(Wounds.RollZombieAttackType(), "bite", "bite type roll remains independent")

T.finish("pnc_zombie_damage_model_smoke")
