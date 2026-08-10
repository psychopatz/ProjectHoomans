-- Committed shove, melee, and ranged hit resolution.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Perception = PNC.Perception
local Unarmed = PNC.CombatUnarmed
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Resolution = PNC.CombatResolution
local FirearmEffects = PNC.FirearmEffects

function Internal.applyAttackActionHit(record, zombie, action, target)
    local zombieTarget
    local attackApplied
    local attackReason
    if not action or not target then
        return false, "target_lost"
    end

    if action.attackType == "ranged" and action.ammoConsumed ~= true then
        local weaponItem = Internal.resolveWeaponItem and Internal.resolveWeaponItem(record) or nil
        local consumed
        local ammoReason
        if Resolution and Resolution.ConsumeAmmo then
            consumed, ammoReason = Resolution.ConsumeAmmo(record, weaponItem)
            if not consumed then
                return false, ammoReason or "out_of_ammo"
            end
        end
        action.ammoConsumed = true
    end

    if action.attackType == "ranged" and action.shotEffectDone ~= true then
        action.shotEffectDone = true
        if FirearmEffects and FirearmEffects.Emit then
            FirearmEffects.Emit(
                record,
                zombie,
                target,
                Internal.resolveWeaponItem and Internal.resolveWeaponItem(record, zombie) or nil
            )
        end
    end

    if action.attackKind == "shove" then
        zombieTarget = target.kind == "zombie" and Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId) or nil
        if not zombieTarget then
            return false, "invalid_zombie_target"
        end
        if Unarmed and Unarmed.ApplyZombieShove and Unarmed.ApplyZombieShove(zombie, zombieTarget) then
            if Stamina and Stamina.SpendAttack then
                Stamina.SpendAttack(record, "melee", action.skillID or "Strength")
            end
            if Skills and Skills.AddXP then
                Skills.AddXP(record, "Strength", 2)
            end
            return true, "shoved_zombie"
        end
        return false, "zombie_shove_failed"
    end

    if action.attackKind == "ground" or action.attackType == "melee" then
        if target.kind == "player" then
            attackApplied, attackReason = Resolution and Resolution.ApplyTargetDamage
                and Resolution.ApplyTargetDamage(record, zombie, target, {
                    damage = action.damage,
                    attackType = "melee",
                    attackKind = action.attackKind,
                    weaponItem = Internal.resolveWeaponItem(record),
                })
            if attackApplied then
                AttackExecution.applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "melee", action.skillID)
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, action.skillID or "Strength", action.attackKind == "ground" and 4 or 5)
                    Skills.AddXP(record, "Maintenance", 1)
                end
                return true, attackReason or "hit_player"
            end
            return false, attackReason or "invalid_player_target"
        end
        if target.kind == "npc" then
            attackApplied, attackReason = Resolution and Resolution.ApplyTargetDamage
                and Resolution.ApplyTargetDamage(record, zombie, target, {
                    damage = action.damage,
                    attackType = "melee",
                    attackKind = action.attackKind,
                    weaponItem = Internal.resolveWeaponItem(record),
                })
            if attackApplied then
                AttackExecution.applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "melee", action.skillID)
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, action.skillID or "Strength", 5)
                    Skills.AddXP(record, "Maintenance", 1)
                end
                return true, attackReason or "hit_npc"
            end
            return false, attackReason or "npc_damage_rejected"
        end
        if target.kind == "zombie" then
            attackApplied, attackReason = Internal.applyDamageToZombie(record, zombie, target, action.damage, "melee")
            if attackApplied then
                AttackExecution.applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "melee", action.skillID)
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, action.skillID or "Strength", action.attackKind == "ground" and 4 or 5)
                    Skills.AddXP(record, "Maintenance", 1)
                end
            end
            return attackApplied, attackReason
        end
    end

    if action.attackType == "ranged" then
        if target.kind == "player" then
            attackApplied, attackReason = Resolution and Resolution.ApplyTargetDamage
                and Resolution.ApplyTargetDamage(record, zombie, target, {
                    damage = action.damage,
                    attackType = "ranged",
                    attackKind = action.attackKind,
                    weaponItem = Internal.resolveWeaponItem(record),
                })
            if attackApplied then
                AttackExecution.applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "ranged", action.skillID or "Aiming")
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, "Aiming", 5)
                    Skills.AddXP(record, "Reloading", 2)
                end
                return true, attackReason or "hit_player"
            end
            return false, attackReason or "invalid_player_target"
        end
        if target.kind == "npc" then
            attackApplied, attackReason = Resolution and Resolution.ApplyTargetDamage
                and Resolution.ApplyTargetDamage(record, zombie, target, {
                    damage = action.damage,
                    attackType = "ranged",
                    attackKind = action.attackKind,
                    weaponItem = Internal.resolveWeaponItem(record),
                })
            if attackApplied then
                AttackExecution.applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "ranged", action.skillID or "Aiming")
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, "Aiming", 5)
                    Skills.AddXP(record, "Reloading", 2)
                end
                return true, attackReason or "hit_npc"
            end
            return false, attackReason or "npc_damage_rejected"
        end
        if target.kind == "zombie" then
            attackApplied, attackReason = Internal.applyDamageToZombie(record, zombie, target, action.damage, "ranged")
            if attackApplied then
                AttackExecution.applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "ranged", action.skillID or "Aiming")
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, "Aiming", 5)
                    Skills.AddXP(record, "Reloading", 2)
                end
            end
            return attackApplied, attackReason
        end
    end

    return false, "unknown_target"
end
