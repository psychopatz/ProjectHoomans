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

local attackRecord = {
    id = "zombie_authority",
    x = 0,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "live",
    runtime = {},
    health = {
        current = 100,
        max = 100,
        state = "normal",
        body = { parts = {}, wounds = {} },
    },
}
local attackBody = {}
local allowed, attackResult = Wounds.ResolveZombieAttack(
    attackRecord, attackBody, nil, "zombie_1"
)
T.equal(allowed, false, "legacy attack fails closed without authority service")
T.equal(attackResult.outcome, "not_authority",
    "legacy attack reports missing authority")
allowed, attackResult = Wounds.ApplyResolvedZombieAttack(
    attackRecord,
    attackBody,
    nil,
    "zombie_1",
    { part = Wounds.Parts.Torso_Upper, damageType = "scratch" }
)
T.equal(allowed, false, "resolved attack fails closed without authority service")
T.equal(attackResult.outcome, "not_authority",
    "resolved attack reports missing authority")

PNC.Core.IsAuthority = function() return false end
allowed, attackResult = Wounds.ResolveZombieAttack(
    attackRecord, attackBody, nil, "zombie_1"
)
T.equal(allowed, false, "client cannot apply legacy zombie damage")
T.equal(attackResult.outcome, "not_authority",
    "legacy client rejection outcome")
allowed, attackResult = Wounds.ApplyResolvedZombieAttack(
    attackRecord,
    attackBody,
    nil,
    "zombie_1",
    { part = Wounds.Parts.Torso_Upper, damageType = "scratch" }
)
T.equal(allowed, false, "client cannot apply resolved zombie damage")
T.equal(attackResult.outcome, "not_authority",
    "resolved client rejection outcome")
T.equal(attackRecord.health.current, 100,
    "authority rejections leave health unchanged")
T.equal(next(attackRecord.health.body.wounds), nil,
    "authority rejections leave wound state unchanged")

PNC.Core.IsAuthority = function() return true end
PNC.Sandbox.NPCZombieWoundChance = function() return 100 end
PNC.Sandbox.NPCZombieBiteChance = function() return 0 end
PNC.Sandbox.NPCZombieLacerationChance = function() return 0 end
PNC.Health = {
    Ensure = function(record) return record.health end,
    ApplyDamage = function(record, _, event)
        record.health.current = record.health.current - event.amount
        return true
    end,
}
local zombieDebugMessages = {}
PNC.Core.IsRecordDebugEnabled = function(record)
    return record and record.runtime and record.runtime.debug == true
end
PNC.Core.LogRecordDebug = function(_, message)
    zombieDebugMessages[#zombieDebugMessages + 1] = message
end

local function makeAttackVictim(id)
    return {
        id = id,
        x = 0,
        y = 0,
        z = 0,
        alive = true,
        presenceState = "live",
        runtime = {},
        health = {
            current = 100,
            max = 100,
            state = "normal",
            body = { parts = {}, wounds = {} },
        },
    }
end

local legacyVictim = makeAttackVictim("legacy_attack")
legacyVictim.runtime.debug = true
randomValues = { 0, 9999, 0 }
allowed, attackResult = Wounds.ResolveZombieAttack(
    legacyVictim, attackBody, nil, "zombie_2"
)
T.equal(allowed, true, "authoritative legacy attack applies damage")
T.equal(attackResult.outcome, "wounded", "legacy attack outcome")
T.truthy(legacyVictim.health.body.wounds[attackResult.partId],
    "legacy attack records its body-part wound")
T.contains(zombieDebugMessages[#zombieDebugMessages],
    "health.zombie_attack route=legacy")
T.contains(zombieDebugMessages[#zombieDebugMessages],
    "status=applied reason=wounded")
T.contains(zombieDebugMessages[#zombieDebugMessages],
    "attacker=zombie_2")
PNC.NPCWounds.Internal.LogZombieAttackDebug(
    legacyVictim,
    "legacy\n" .. string.rep("r", 100),
    "rejected",
    "bad\nreason",
    { unsafe = true },
    "Torso_Upper",
    "scratch",
    { unsafe = true }
)
local boundedMessage = zombieDebugMessages[#zombieDebugMessages]
T.contains(boundedMessage, "attacker=unsupported")
T.contains(boundedMessage, "damage=unsupported")
T.truthy(not string.find(boundedMessage, "\n", 1, true),
    "diagnostics strip control characters")
T.truthy(#boundedMessage < 500, "diagnostic fields are length bounded")

local resolvedVictim = makeAttackVictim("resolved_attack")
allowed, attackResult = Wounds.ApplyResolvedZombieAttack(
    resolvedVictim,
    attackBody,
    nil,
    "zombie_3",
    {
        part = Wounds.Parts.Torso_Upper,
        damageType = "scratch",
        damageModel = false,
        damageChance = 100,
        damageRoll = 0,
    }
)
T.equal(allowed, true, "authoritative resolved attack applies damage")
T.equal(attackResult.outcome, "wounded", "resolved attack outcome")
T.equal(attackResult.partId, "Torso_Upper",
    "resolved attack preserves its selected body part")
T.truthy(resolvedVictim.health.body.wounds.Torso_Upper,
    "resolved attack records its body-part wound")

local rejectedVictim = makeAttackVictim("rejected_attack")
PNC.Health.ApplyDamage = function() return false end
allowed, attackResult = Wounds.ApplyResolvedZombieAttack(
    rejectedVictim,
    attackBody,
    nil,
    "zombie_4",
    {
        part = Wounds.Parts.Torso_Upper,
        damageType = "scratch",
        damageModel = false,
    }
)
T.equal(allowed, false, "rejected health damage rejects the wound")
T.equal(attackResult.outcome, "damage_rejected",
    "resolved damage rejection is reported")
T.equal(rejectedVictim.health.body.wounds.Torso_Upper, nil,
    "rejected health damage rolls back the wound")

local unavailableVictim = makeAttackVictim("unavailable_attack")
PNC.Health = nil
allowed, attackResult = Wounds.ApplyResolvedZombieAttack(
    unavailableVictim,
    attackBody,
    nil,
    "zombie_5",
    {
        part = Wounds.Parts.Torso_Upper,
        damageType = "scratch",
        damageModel = false,
    }
)
T.equal(allowed, false, "missing Health API safely rejects the attack")
T.equal(attackResult.outcome, "damage_unavailable",
    "missing Health API has an explicit result")
T.equal(unavailableVictim.health.body.wounds.Torso_Upper, nil,
    "missing Health API leaves wound state unchanged")

T.finish("pnc_zombie_damage_model_smoke")
