--[[
    PNC NPC Combat Defense

    Owns the authoritative zombie-attack avoidance roll.  Movement tactics
    consume only the resulting near-miss signal; they do not independently
    guess that an attack might happen.  This keeps SP and MP on one combat
    calculation and gives the debug overlay a single source of truth.
]]

PNC = PNC or {}
PNC.CombatDefense = PNC.CombatDefense or {}

local Defense = PNC.CombatDefense
local Core = PNC.Core
local Const = PNC.Const
local Skills = PNC.Skills
local Spatial = PNC.SpatialIndex
local Wounds = PNC.NPCWounds

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
    if not state then return nil end
    radius = tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS) or 2.2
    state.radius = radius
    state.nearbyCount = Defense.CountNearbyZombies(
        record,
        npcBody,
        radius
    )
    state.updatedAt = tonumber(now)
        or Core and Core.Now and Core.Now()
        or 0
    return state
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
