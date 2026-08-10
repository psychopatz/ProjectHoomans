--[[
    PNC Combat Melee
    Owns melee, shove, and downed-shove entry points. It decides which attack
    action to start and leaves hit timing to the attack action pump.
]]

PNC = PNC or {}
PNC.Combat = PNC.Combat or {}

local Combat = PNC.Combat
local Internal = PNC.Combat.Internal or {}
local Core = PNC.Core
local Const = PNC.Const
local Equipment = PNC.Equipment
local Perception = PNC.Perception
local Unarmed = PNC.CombatUnarmed
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Resolution = PNC.CombatResolution
local Tactics = PNC.CombatTactics

function Combat.TryMelee(record, zombie, target)
    local now = Core.Now()
    local profile = record.combatProfile or {}
    local damage = tonumber(profile.meleeDamage) or 10
    local dist
    local equipmentInfo = Equipment.Describe(record)
    local zombieTarget
    local anim
    local weaponItem = Internal.resolveWeaponItem and Internal.resolveWeaponItem(record, zombie) or nil
    -- WeaponType is primarily an animation-family resolver and may classify a
    -- valid modded weapon as barehand. Combat capability follows the actual
    -- equipped InventoryItem instead.
    local isBarehand = not (weaponItem and weaponItem.IsWeapon and weaponItem:IsWeapon())
    local cooldownMs = isBarehand and (tonumber(profile.unarmedCooldownMs) or Const.UNARMED_COOLDOWN_MS) or (tonumber(profile.meleeCooldownMs) or 900)
    local skillID = Skills and Skills.ResolveWeaponSkill and Skills.ResolveWeaponSkill(record, record.equipment and record.equipment.primaryFullType, "melee") or "Strength"
    local skillLevel = Skills and Skills.GetLevel and Skills.GetLevel(record, skillID) or 0
    local strengthLevel = Skills and Skills.GetLevel and Skills.GetLevel(record, "Strength") or 0
    local groundSafe
    local liveTarget
    local emergencyMelee

    if not target then
        return false, "no_target"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive and PNC.PathService.IsTraversalActive(record, zombie) then
        return false, "traversal_active"
    end
    if Combat.HasActiveAttack and Combat.HasActiveAttack(record, now) then
        return false, "attack_in_progress"
    end

    -- Range owns approach arbitration. Checking cooldown first made an NPC
    -- outside strike reach stand still for the cooldown window (or forever
    -- after a stale timestamp) instead of proactively closing on its target.
    if Internal.refreshTargetDistance then
        dist, liveTarget = Internal.refreshTargetDistance(
            record,
            zombie,
            target
        )
    else
        dist = math.sqrt(tonumber(target.distSq) or 0)
    end
    if dist > (
        tonumber(Const.MELEE_COMMIT_RANGE)
            or tonumber(Const.MELEE_APPROACH_STOP_DISTANCE)
            or 1.0
    ) then
        return false, "target_out_of_range"
    end
    if not Internal.canAttack(record, now, cooldownMs) then
        return false, "cooldown_active"
    end
    emergencyMelee = target.kind == "zombie"
        and record.runtime
        and now <= (
            tonumber(record.runtime.emergencyMeleeUntil) or 0
        )
        or false
    if Stamina and Stamina.CanSpendAttack
        and not Stamina.CanSpendAttack(record, "melee", skillID)
        and not emergencyMelee
    then
        return false, "stamina_exhausted"
    end

    if not isBarehand and Resolution and Resolution.GetAttackDamage and Resolution.IsWeaponDamageEnabled and Resolution.IsWeaponDamageEnabled() then
        damage = Resolution.GetAttackDamage(record, "melee", weaponItem, damage, skillLevel)
    else
        damage = damage * (0.9 + math.min(skillLevel, 8) * 0.04 + math.min(strengthLevel, 6) * 0.02)
    end
    if emergencyMelee then
        damage = damage * 0.55
        record.runtime.emergencyMeleeUntil = nil
    end
    if Internal.prepareAttackMovement then
        Internal.prepareAttackMovement(
            record,
            zombie,
            "melee_windup"
        )
    end
    record.runtime.lastAttackAt = now
    record.runtime.inCombatUntil = now + Const.DEBUG_COMBAT_HOLD_MS
    Internal.faceTarget(zombie, target, record, Internal.ATTACK_TIMINGS.melee.duration, "melee_windup")

    if target.kind == "zombie" then
        zombieTarget = liveTarget
            or Perception.FindZombieByID
                and Perception.FindZombieByID(target.zombieId)
            or nil
        if zombieTarget then
            groundSafe = Unarmed
                and Unarmed.IsGroundTarget
                and Unarmed.IsGroundTarget(zombieTarget)
                and (
                    not Tactics
                    or not Tactics.ShouldUseGroundFinisher
                    or Tactics.ShouldUseGroundFinisher(record, target) == true
                )
            if groundSafe then
                damage = isBarehand
                    and (tonumber(profile.unarmedGroundDamage)
                        or Const.UNARMED_GROUND_DAMAGE)
                    or damage * 1.15
                anim = Unarmed and Unarmed.PlayGroundAttack and Unarmed.PlayGroundAttack(zombie, record, zombieTarget) or "PNC_Attack2HStamp"
                Internal.buildAttackAction(record, target, "ground", "melee", anim, damage, skillID)
                return true, "ground_attack_started"
            end
        end
    end

    if isBarehand then
        damage = tonumber(profile.unarmedDamage) or Const.UNARMED_DAMAGE
        anim = Internal.triggerUnarmedAttackAnim
            and Internal.triggerUnarmedAttackAnim()
            or "PNC_AttackBareHands1"
    else
        Internal.playAttackSound(zombie, record, weaponItem)
        anim = Internal.triggerMeleeWeaponAnim(
            zombie,
            record,
            equipmentInfo
        )
    end
    Internal.buildAttackAction(
        record,
        target,
        "melee",
        "melee",
        anim or "PNC_Attack1H1",
        damage,
        skillID
    )
    return true, isBarehand
        and "unarmed_attack_started"
        or "melee_attack_started"
end

function Combat.TryShove(record, zombie, target, reason)
    local now = Core.Now()
    local zombieTarget
    local profile = record and record.combatProfile or {}
    if not record or not zombie or not target then
        return false, "no_target"
    end
    if target.kind ~= "zombie" then
        return false, "shove_requires_zombie"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive
        and PNC.PathService.IsTraversalActive(record, zombie)
    then
        return false, "traversal_active"
    end
    if Combat.HasActiveAttack and Combat.HasActiveAttack(record, now) then
        return false, "attack_in_progress"
    end
    if not Internal.canAttack(
        record,
        now,
        tonumber(profile.shoveCooldownMs) or Const.INCAP_SHOVE_COOLDOWN_MS
    ) then
        return false, "cooldown_active"
    end
    if math.sqrt(tonumber(target.distSq) or 0)
        > (tonumber(Const.COMBAT_SHOVE_RANGE) or 1.35)
    then
        return false, "target_out_of_range"
    end
    if Stamina and Stamina.CanSpendAttack
        and not Stamina.CanSpendAttack(record, "melee", "Strength")
        and reason ~= "exhausted_defensive_shove"
    then
        return false, "stamina_exhausted"
    end
    zombieTarget = Perception.FindZombieByID
        and Perception.FindZombieByID(target.zombieId) or nil
    if not zombieTarget then return false, "invalid_zombie_target" end
    if Internal.prepareAttackMovement then
        Internal.prepareAttackMovement(
            record,
            zombie,
            reason or "shove_windup"
        )
    end
    record.runtime.lastAttackAt = now
    record.runtime.inCombatUntil = now + Const.DEBUG_COMBAT_HOLD_MS
    Internal.faceTarget(
        zombie,
        target,
        record,
        Internal.ATTACK_TIMINGS.shove.duration,
        reason or "tactical_shove"
    )
    if Unarmed and Unarmed.PlayShove then
        Unarmed.PlayShove(zombie, record, zombieTarget)
    end
    Internal.buildAttackAction(
        record,
        target,
        "shove",
        "melee",
        "PNC_Shove",
        tonumber(profile.shoveDamage) or Const.UNARMED_DAMAGE,
        "Strength"
    )
    return true, reason or "shove_started"
end
