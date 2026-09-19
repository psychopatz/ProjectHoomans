PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local function logAttack(record, status, reason, attackerId, partId, woundType, damage)
    if Internal.LogZombieAttackDebug then
        Internal.LogZombieAttackDebug(
            record,
            "legacy",
            status,
            reason,
            attackerId,
            partId,
            woundType,
            damage
        )
    end
end

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

function Wounds.ResolveZombieAttack(
    record,
    npcBody,
    attacker,
    attackerZombieId
)
    if not Internal.HasServerAuthority() then
        logAttack(record, "rejected", "not_authority", attackerZombieId)
        return false, { outcome = "not_authority" }
    end
    if not Internal.IsLiveZombieTarget(record, npcBody) then
        logAttack(record, "rejected", "target_invalid", attackerZombieId)
        return false, { outcome = "target_invalid" }
    end
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
        local result = {
            outcome = "parried",
            partId = part.id,
            protection = protection,
            chance = finalChance,
            roll = woundRoll,
        }
        logAttack(record, "rejected", result.outcome, attackerZombieId,
            part.id, woundType)
        return false, result
    end
    local wound, failure, damage = Internal.ApplyZombieWoundDamage(
        record,
        npcBody,
        attacker,
        attackerZombieId,
        part,
        woundType,
        { outcome = "damage_rejected", partId = part.id }
    )
    if not wound then
        logAttack(record, "rejected", failure and failure.outcome,
            attackerZombieId, part.id, woundType)
        return false, failure
    end
    Internal.RecordZombieDamage(record, attacker, attackerZombieId)
    Internal.EmitZombieDamageHook(
        record,
        npcBody,
        attacker,
        damage,
        wound,
        attackerZombieId,
        "npc_zombie_attack"
    )
    local result = {
        outcome = "wounded",
        partId = part.id,
        woundType = wound.type,
        protection = protection,
        chance = finalChance,
        roll = woundRoll,
        infected = Wounds.HasActiveInfection(record),
    }
    logAttack(record, "applied", result.outcome, attackerZombieId,
        part.id, wound.type, damage)
    return true, result
end

return Wounds
