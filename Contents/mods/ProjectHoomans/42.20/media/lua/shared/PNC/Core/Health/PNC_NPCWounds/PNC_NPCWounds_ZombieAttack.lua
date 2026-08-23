PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local function chooseWoundType()
    local roll = Internal.RandomPercent()
    local biteChance = Settings.NPCZombieBiteChance()
    local lacerationChance =
        Settings.NPCZombieLacerationChance()
    if roll < biteChance then return "bite" end
    if roll < math.min(
        100,
        biteChance + lacerationChance
    ) then
        return "laceration"
    end
    return "scratch"
end

function Wounds.ChooseZombieAttackPart()
    return Internal.ChoosePart()
end

function Wounds.RollZombieAttackType()
    return chooseWoundType()
end

local function recordZombieDamage(
    record,
    attacker,
    attackerZombieId
)
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.RecordNPCDamaged
        and PNC.SocialEventHooks
    then
        PNC.SocialEncounterTracker.RecordNPCDamaged(
            record,
            attackerZombieId,
            PNC.SocialEventHooks.WorldAgeHours(),
            {
                x = attacker and attacker.getX
                    and attacker:getX() or record.x,
                y = attacker and attacker.getY
                    and attacker:getY() or record.y,
                z = attacker and attacker.getZ
                    and attacker:getZ() or record.z,
            }
        )
    end
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent = "npc_wound"
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "wounds")
    end
end

function Wounds.ResolveZombieAttack(
    record,
    npcBody,
    attacker,
    attackerZombieId
)
    local part = Internal.ChoosePart()
    local woundType = chooseWoundType()
    local protection =
        Wounds.GetProtection(npcBody, part, woundType)
    local baseChance = Settings.NPCZombieWoundChance()
    local finalChance = Core.Clamp(
        baseChance * (1 - protection / 100),
        0,
        100
    )
    local woundRoll = Internal.RandomPercent()
    if woundRoll >= finalChance then
        return false, {
            outcome = "parried",
            partId = part.id,
            protection = protection,
            chance = finalChance,
            roll = woundRoll,
        }
    end
    local wound, damage = Internal.AddWound(
        record,
        part,
        woundType,
        Core.Now()
    )
    PNC.Health.ApplyDamage(record, npcBody, {
        amount = damage,
        partId = part.id,
        type = "zombie_" .. woundType,
        attackerKind = "zombie",
        attackerZombieId = attackerZombieId,
        x = attacker and attacker.getX
            and attacker:getX() or record.x,
        y = attacker and attacker.getY
            and attacker:getY() or record.y,
        z = attacker and attacker.getZ
            and attacker:getZ() or record.z,
    })
    recordZombieDamage(record, attacker, attackerZombieId)
    return true, {
        outcome = "wounded",
        partId = part.id,
        woundType = wound.type,
        protection = protection,
        chance = finalChance,
        roll = woundRoll,
        infected = Wounds.HasActiveInfection(record),
    }
end

local function resolveDamageModel(npcBody, defenseResult)
    local part = defenseResult and defenseResult.part or nil
    local initialWoundType = tostring(
        defenseResult and defenseResult.damageType or "scratch"
    )
    local woundType = initialWoundType
    local protection = 0
    local clothingResult
    if not part or not Internal.WoundStats[woundType] then
        return nil, {
            outcome = "invalid_resolved_attack",
            partId = defenseResult
                and defenseResult.partId or nil,
        }
    end
    if defenseResult and defenseResult.damageModel == true then
        clothingResult = Wounds.ResolveZombieClothing(
            npcBody,
            part,
            initialWoundType
        )
        protection = tonumber(clothingResult.protection) or 0
        if clothingResult.blocked then
            return nil, {
                outcome = clothingResult.outcome,
                partId = part.id,
                initialWoundType = initialWoundType,
                protection = protection,
                blockChance = clothingResult.blockChance,
                clothingRoll = clothingResult.roll,
                durabilityLoss =
                    clothingResult.durabilityLoss,
                conditionBefore =
                    clothingResult.conditionBefore,
                conditionAfter =
                    clothingResult.conditionAfter,
                damageChance = defenseResult.damageChance,
                damageRoll = defenseResult.damageRoll,
            }
        end
        woundType =
            clothingResult.finalWoundType or initialWoundType
    else
        protection = tonumber(
            defenseResult and defenseResult.protection
        ) or 0
    end
    return {
        part = part,
        initialWoundType = initialWoundType,
        woundType = woundType,
        protection = protection,
        clothingResult = clothingResult,
    }
end

local function applyResolvedDamage(
    record,
    npcBody,
    attacker,
    attackerZombieId,
    attack,
    defenseResult
)
    local part = attack.part
    local body = Wounds.Ensure(record)
    local previousWound = body.wounds[part.id]
        and Core.DeepCopy(body.wounds[part.id]) or nil
    local previousInfection = body.infection
        and Core.DeepCopy(body.infection) or nil
    local wound, damage = Internal.AddWound(
        record,
        part,
        attack.woundType,
        Core.Now()
    )
    local applied = PNC.Health.ApplyDamage(record, npcBody, {
        amount = damage,
        partId = part.id,
        type = "zombie_" .. attack.woundType,
        attackerKind = "zombie",
        attackerZombieId = attackerZombieId,
        x = attacker and attacker.getX
            and attacker:getX() or record.x,
        y = attacker and attacker.getY
            and attacker:getY() or record.y,
        z = attacker and attacker.getZ
            and attacker:getZ() or record.z,
    })
    if not applied then
        body.wounds[part.id] = previousWound
        body.infection = previousInfection
        Wounds.Recalculate(record)
        return nil, {
            outcome = "damage_rejected",
            partId = part.id,
            initialWoundType = attack.initialWoundType,
            woundType = attack.woundType,
            protection = attack.protection,
            damageChance =
                defenseResult and defenseResult.damageChance or nil,
            damageRoll =
                defenseResult and defenseResult.damageRoll or nil,
        }
    end
    return wound
end

local function buildResolvedResult(
    record,
    wound,
    attack,
    defenseResult
)
    local clothingResult = attack.clothingResult
    return {
        outcome = "wounded",
        partId = attack.part.id,
        woundType = wound.type,
        initialWoundType = attack.initialWoundType,
        protection = attack.protection,
        blockChance = clothingResult
            and clothingResult.blockChance or nil,
        clothingRoll = clothingResult
            and clothingResult.roll or nil,
        durabilityLoss = clothingResult
            and clothingResult.durabilityLoss or 0,
        conditionBefore = clothingResult
            and clothingResult.conditionBefore or nil,
        conditionAfter = clothingResult
            and clothingResult.conditionAfter or nil,
        chance = defenseResult
            and (
                defenseResult.damageChance
                or defenseResult.avoidChance
            ) or nil,
        roll = defenseResult
            and (
                defenseResult.damageRoll
                or defenseResult.roll
            ) or nil,
        damageChance = defenseResult
            and defenseResult.damageChance or nil,
        damageRoll = defenseResult
            and defenseResult.damageRoll or nil,
        infected = Wounds.HasActiveInfection(record),
    }
end

function Wounds.ApplyResolvedZombieAttack(
    record,
    npcBody,
    attacker,
    attackerZombieId,
    defenseResult
)
    if Core and Core.IsAuthority and not Core.IsAuthority() then
        return false, { outcome = "not_authority" }
    end
    local attack, result =
        resolveDamageModel(npcBody, defenseResult)
    if not attack then return false, result end
    local wound
    wound, result = applyResolvedDamage(
        record,
        npcBody,
        attacker,
        attackerZombieId,
        attack,
        defenseResult
    )
    if not wound then return false, result end
    recordZombieDamage(record, attacker, attackerZombieId)
    return true, buildResolvedResult(
        record,
        wound,
        attack,
        defenseResult
    )
end

return Wounds
