--[[
    PNC NPC Combat Defense

    Owns the authoritative zombie-attack exposure roll.  Movement tactics
    consume only the resulting near-miss signal; they do not independently
    guess that an attack might happen.  This keeps SP and MP on one combat
    calculation and gives the debug overlay a single source of truth.  The
    legacy avoidance resolver remains available behind the sandbox switch.
]]

PNC = PNC or {}
PNC.CombatDefense = PNC.CombatDefense or {}

local Defense = PNC.CombatDefense
local Core = PNC.Core
local Const = PNC.Const
local Skills = PNC.Skills
local Spatial = PNC.SpatialIndex
local Wounds = PNC.NPCWounds

local function settingNumber(name, fallback, minimum, maximum)
    local settings = PNC.Sandbox
    local getter = settings and settings[name]
    local value = getter and getter() or fallback
    value = tonumber(value) or tonumber(fallback) or 0
    if minimum ~= nil then value = math.max(value, minimum) end
    if maximum ~= nil then value = math.min(value, maximum) end
    return value
end

local function damageModelEnabled()
    local settings = PNC.Sandbox
    local getter = settings and settings.NPCZombieDamageModelEnabled
    if not getter then return false end
    return getter() == true
end

local function clamp(value, minimum, maximum)
    value = tonumber(value) or minimum
    if value < minimum then return minimum end
    if value > maximum then return maximum end
    return value
end

local function randomUnit()
    if ZombRand then
        return ZombRand(10000) / 10000
    end
    return math.random()
end

local function ensureState(record)
    if type(record) ~= "table" then return nil end
    record.runtime = record.runtime or {}
    record.runtime.combatDefense = record.runtime.combatDefense or {}
    return record.runtime.combatDefense
end

local function bodyPosition(record, npcBody)
    local x = npcBody and npcBody.getX and npcBody:getX()
        or tonumber(record and record.x) or 0
    local y = npcBody and npcBody.getY and npcBody:getY()
        or tonumber(record and record.y) or 0
    local z = npcBody and npcBody.getZ and npcBody:getZ()
        or tonumber(record and record.z) or 0
    return x, y, z
end

function Defense.CountNearbyZombies(record, npcBody, radius)
    local x
    local y
    local z
    local radiusSq
    local zombies
    local zombie
    local count = 0
    local i
    radius = tonumber(radius)
        or tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS)
        or 2.2
    x, y, z = bodyPosition(record, npcBody)
    radiusSq = radius * radius
    if not Spatial or not Spatial.QueryZombies then
        return 0
    end
    zombies = Spatial.QueryZombies(x, y, radius)
    for i = 1, #zombies do
        zombie = zombies[i]
        if zombie
            and (not zombie.isDead or not zombie:isDead())
            and (not Core.IsManagedNPCBody
                or not Core.IsManagedNPCBody(zombie))
            and zombie.getX
            and zombie.getY
            and zombie.getZ
            and math.abs((tonumber(zombie:getZ()) or z) - z) < 1
            and Core.DistanceSq(
                x,
                y,
                zombie:getX(),
                zombie:getY()
            ) <= radiusSq
        then
            count = count + 1
        end
    end
    return count
end

function Defense.Refresh(record, npcBody, now)
    local state = ensureState(record)
    local radius
    local x
    local y
    local z
    if not state then return nil end
    radius = damageModelEnabled()
        and settingNumber("NPCZombieDamageHitRadius", 2.2, 0.1, 6)
        or (tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS) or 2.2)
    now = tonumber(now) or Core.Now()
    x, y, z = bodyPosition(record, npcBody)
    if damageModelEnabled()
        and state.updatedAt
        and now - state.updatedAt
            < (tonumber(Const.NPC_ZOMBIE_DEFENSE_REFRESH_MS) or 200)
        and state.radius == radius
        and Core.DistanceSq(x, y, state.x or x, state.y or y) <= 0.25
        and math.abs(z - (state.z or z)) < 1
    then
        return state
    end
    state.radius = radius
    state.nearbyCount = Defense.CountNearbyZombies(
        record,
        npcBody,
        radius
    )
    state.x = x
    state.y = y
    state.z = z
    state.updatedAt = now
    return state
end

local function staminaRatio(record)
    local stamina = PNC.Stamina
    if stamina and stamina.GetRatio then
        return clamp(stamina.GetRatio(record), 0, 1)
    end
    return 1
end

local function fatigueExposure(ratio, safeRatio)
    ratio = clamp(ratio, 0, 1)
    safeRatio = clamp(safeRatio, 0, 1)
    if safeRatio <= 0 then return 1 end
    if ratio >= safeRatio then return 0 end
    local t = clamp((safeRatio - ratio) / safeRatio, 0, 1)
    return t * t * (3 - (2 * t))
end

function Defense.CalculateDamageChance(record, nearbyCount)
    local fitness = Skills and Skills.GetLevel
        and Skills.GetLevel(record, "Fitness")
        or 0
    local stamina = staminaRatio(record)
    local safeRatio = settingNumber(
        "NPCZombieDamageStaminaStartRatio",
        0.30,
        0,
        1
    )
    local exposure = fatigueExposure(stamina, safeRatio)
    local extra
    local escalation
    local crowdChance
    local baseChance
    local minimumSkill
    local fitnessScale
    local maximumSkill
    local skillMitigation
    local chance
    fitness = clamp(fitness, 0, 10)
    nearbyCount = math.max(1, math.floor(tonumber(nearbyCount) or 1))
    extra = math.max(0, nearbyCount - 1)
    escalation = math.max(0, extra - 2)
    crowdChance = extra * settingNumber(
        "NPCZombieDamageCrowdChancePerExtra",
        5,
        0,
        100
    )
    crowdChance = crowdChance + (escalation * escalation
        * settingNumber("NPCZombieDamageCrowdEscalation", 2, 0, 100))
    crowdChance = math.min(
        crowdChance,
        settingNumber("NPCZombieDamageCrowdChanceCap", 100, 0, 100)
    )
    baseChance = settingNumber(
        "NPCZombieDamageBaseChance",
        0,
        0,
        100
    )
    minimumSkill = settingNumber(
        "NPCZombieDamageMinimumSkillMitigation",
        15,
        0,
        100
    ) / 100
    fitnessScale = settingNumber(
        "NPCZombieDamageFitnessMitigationScale",
        45,
        0,
        100
    ) / 100
    maximumSkill = settingNumber(
        "NPCZombieDamageMaximumSkillMitigation",
        60,
        0,
        100
    ) / 100
    skillMitigation = clamp(
        minimumSkill + (fitness / 10) * fitnessScale,
        0,
        maximumSkill
    )
    chance = clamp((baseChance + crowdChance) / 100, 0, 1)
        * exposure
        * (1 - skillMitigation)
    return clamp(chance, 0, 1), {
        fitness = fitness,
        staminaRatio = stamina,
        safeStaminaRatio = safeRatio,
        fatigueExposure = exposure,
        nearbyCount = nearbyCount,
        crowdChance = crowdChance,
        skillMitigation = skillMitigation,
        baseChance = baseChance,
    }
end

local function resolveNearMiss(record, npcBody, zombie, now)
    local pushRoll = randomUnit()
    local pushed = false
    local reactionOptions
    if pushRoll
        < settingNumber(
            "NPC_ZOMBIE_DEFENSE_PUSH_CHANCE",
            tonumber(Const.NPC_ZOMBIE_DEFENSE_PUSH_CHANCE) or 0.50,
            0,
            1
        )
        and PNC.CombatZombieReaction
        and PNC.CombatZombieReaction.Start
    then
        reactionOptions = {
            kind = "npc_zombie_parry",
            stagger = true,
            hitForce = 0.92,
            durationMs = 280,
            pushDurationMs = 190,
            pushDistance = 0.42,
            stepDistance = 0.07,
        }
        pushed = PNC.CombatZombieReaction.Start(
            npcBody,
            zombie,
            reactionOptions
        ) == true
        if pushed
            and PNC.Network
            and PNC.Network.BroadcastZombieReaction
        then
            PNC.Network.BroadcastZombieReaction(
                zombie,
                npcBody,
                reactionOptions
            )
        end
    end
    if PNC.CombatTactics
        and PNC.CombatTactics.MarkZombieNearMiss
    then
        PNC.CombatTactics.MarkZombieNearMiss(
            record,
            zombie and zombie.getX and zombie:getX() or record.x,
            zombie and zombie.getY and zombie:getY() or record.y,
            zombie and zombie.getZ and zombie:getZ() or record.z,
            now
        )
    end
    return pushRoll, pushed
end

local function resolveDamageModelAttack(record, npcBody, zombie, now)
    local state = Defense.Refresh(record, npcBody, now)
    local nearbyCount
    local chance
    local details
    local roll
    local avoided
    local pushRoll
    local pushed = false
    local part
    local damageType
    if not state then return false, nil end
    nearbyCount = math.max(1, tonumber(state.nearbyCount) or 0)
    chance, details = Defense.CalculateDamageChance(record, nearbyCount)
    roll = randomUnit()
    avoided = roll >= chance
    if avoided then
        pushRoll, pushed = resolveNearMiss(record, npcBody, zombie, now)
    else
        -- The bite/laceration/scratch roll is deliberately deferred until the
        -- stamina/crowd exposure roll has succeeded. A safe attack therefore
        -- cannot consume or accidentally create a bite-type result.
        part = Wounds and Wounds.ChooseZombieAttackPart
            and Wounds.ChooseZombieAttackPart()
            or nil
        damageType = Wounds and Wounds.RollZombieAttackType
            and Wounds.RollZombieAttackType()
            or "scratch"
    end
    state.damageModel = true
    state.damageType = damageType
    state.partId = part and part.id or nil
    state.fitness = details.fitness
    state.staminaRatio = details.staminaRatio
    state.safeStaminaRatio = details.safeStaminaRatio
    state.fatigueExposure = details.fatigueExposure
    state.crowdChance = details.crowdChance
    state.skillMitigation = details.skillMitigation
    state.baseChance = details.baseChance
    state.protection = 0
    state.mobilityChance = 1 - chance
    state.damageChance = chance
    state.avoidChance = 1 - chance
    state.roll = roll
    state.damageRoll = roll
    state.avoided = avoided
    state.pushRoll = pushRoll
    state.pushed = pushed
    state.lastResolvedAt = now
    state.outcome = avoided
        and (details.fatigueExposure <= 0 and "stamina_safe" or "avoided")
        or "hit"
    return avoided, {
        outcome = state.outcome,
        damageModel = true,
        part = part,
        partId = state.partId,
        damageType = damageType,
        nearbyCount = nearbyCount,
        radius = state.radius,
        fitness = details.fitness,
        staminaRatio = details.staminaRatio,
        safeStaminaRatio = details.safeStaminaRatio,
        fatigueExposure = details.fatigueExposure,
        crowdChance = details.crowdChance,
        skillMitigation = details.skillMitigation,
        baseChance = details.baseChance,
        protection = 0,
        mobilityChance = 1 - chance,
        damageChance = chance,
        avoidChance = 1 - chance,
        roll = roll,
        damageRoll = roll,
        pushRoll = pushRoll,
        pushed = pushed,
    }
end

function Defense.CalculateAvoidChance(
    record,
    npcBody,
    damageType,
    nearbyCount,
    part
)
    local fitness = Skills and Skills.GetLevel
        and Skills.GetLevel(record, "Fitness")
        or 0
    local protection = Wounds and Wounds.GetProtection
        and Wounds.GetProtection(npcBody, part, damageType)
        or 0
    local baseChance
    local crowdPenalty
    local rawChance
    local finalChance
    fitness = clamp(fitness, 0, 10)
    nearbyCount = math.max(1, math.floor(tonumber(nearbyCount) or 1))
    if fitness >= 2 then
        baseChance =
            (tonumber(Const.NPC_ZOMBIE_DEFENSE_FITNESS_TWO_CHANCE)
                or 0.98)
            + ((fitness - 2)
                * (
                    tonumber(
                        Const.NPC_ZOMBIE_DEFENSE_HIGH_FITNESS_STEP
                    ) or 0.0015
                ))
    else
        baseChance =
            (tonumber(Const.NPC_ZOMBIE_DEFENSE_FITNESS_BASE)
                or 0.90)
            + (
                fitness
                * (
                    tonumber(
                        Const.NPC_ZOMBIE_DEFENSE_FITNESS_STEP
                    ) or 0.04
                )
            )
    end
    crowdPenalty = math.max(
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MIN_CROWD_PENALTY)
            or 0.075,
        (tonumber(Const.NPC_ZOMBIE_DEFENSE_CROWD_PENALTY)
            or 0.14)
            - (fitness * 0.005)
    )
    rawChance = baseChance
        - (math.max(0, nearbyCount - 1) * crowdPenalty)
    rawChance = clamp(
        rawChance,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MIN_CHANCE) or 0.05,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MAX_CHANCE) or 0.995
    )
    -- Armor is a secondary no-harm layer after mobility. Bite, scratch/
    -- laceration, and bullet defense therefore use their matching item stat.
    finalChance = 1
        - ((1 - rawChance)
            * (1 - clamp(protection, 0, 100) / 100))
    return clamp(
        finalChance,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MIN_CHANCE) or 0.05,
        tonumber(Const.NPC_ZOMBIE_DEFENSE_MAX_CHANCE) or 0.995
    ), clamp(protection, 0, 100), fitness, rawChance
end

function Defense.ResolveZombieAttack(record, npcBody, zombie, now)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return true, {
            outcome = "not_authority",
            damageModel = damageModelEnabled(),
        }
    end
    if damageModelEnabled() then
        return resolveDamageModelAttack(record, npcBody, zombie, now)
    end
    local state
    local nearbyCount
    local part
    local damageType
    local chance
    local protection
    local fitness
    local mobilityChance
    local roll
    local avoided
    local pushRoll
    local pushed = false
    local reactionOptions
    now = tonumber(now) or Core.Now()
    state = Defense.Refresh(record, npcBody, now)
    if not state then return false, nil end
    nearbyCount = math.max(1, tonumber(state.nearbyCount) or 0)
    part = Wounds and Wounds.ChooseZombieAttackPart
        and Wounds.ChooseZombieAttackPart()
        or nil
    damageType = Wounds and Wounds.RollZombieAttackType
        and Wounds.RollZombieAttackType()
        or "scratch"
    chance, protection, fitness, mobilityChance =
        Defense.CalculateAvoidChance(
            record,
            npcBody,
            damageType,
            nearbyCount,
            part
        )
    roll = randomUnit()
    avoided = roll < chance
    if avoided then
        pushRoll = randomUnit()
        if pushRoll
            < (
                tonumber(Const.NPC_ZOMBIE_DEFENSE_PUSH_CHANCE)
                    or 0.50
            )
            and PNC.CombatZombieReaction
            and PNC.CombatZombieReaction.Start
        then
            reactionOptions = {
                kind = "npc_zombie_parry",
                stagger = true,
                hitForce = 0.92,
                durationMs = 280,
                pushDurationMs = 190,
                pushDistance = 0.42,
                stepDistance = 0.07,
            }
            pushed = PNC.CombatZombieReaction.Start(
                npcBody,
                zombie,
                reactionOptions
            ) == true
            if pushed
                and PNC.Network
                and PNC.Network.BroadcastZombieReaction
            then
                PNC.Network.BroadcastZombieReaction(
                    zombie,
                    npcBody,
                    reactionOptions
                )
            end
        end
        if PNC.CombatTactics
            and PNC.CombatTactics.MarkZombieNearMiss
        then
            PNC.CombatTactics.MarkZombieNearMiss(
                record,
                zombie and zombie.getX and zombie:getX() or record.x,
                zombie and zombie.getY and zombie:getY() or record.y,
                zombie and zombie.getZ and zombie:getZ() or record.z,
                now
            )
        end
    end
    state.damageType = damageType
    state.partId = part and part.id or nil
    state.fitness = fitness
    state.protection = protection
    state.mobilityChance = mobilityChance
    state.avoidChance = chance
    state.roll = roll
    state.avoided = avoided
    state.pushRoll = pushRoll
    state.pushed = pushed
    state.lastResolvedAt = now
    state.outcome = avoided
        and (pushed and "avoided_push" or "avoided")
        or "hit"
    return avoided, {
        outcome = state.outcome,
        part = part,
        partId = state.partId,
        damageType = damageType,
        nearbyCount = nearbyCount,
        radius = state.radius,
        fitness = fitness,
        protection = protection,
        mobilityChance = mobilityChance,
        avoidChance = chance,
        roll = roll,
        pushed = pushed,
    }
end

return Defense
