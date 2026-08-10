-- Damage service adapters and weapon-condition handling.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Damage = PNC.CombatDamage

function AttackExecution.applyWeaponWear(record)
    local weaponItem = Internal.resolveWeaponItem and Internal.resolveWeaponItem(record) or nil
    if Damage and Damage.ApplyWeaponConditionLoss then
        Damage.ApplyWeaponConditionLoss(record, weaponItem)
    end
end

function Internal.applyDamageToZombie(record, attackerZombie, target, damage, attackType)
    if not Damage or not Damage.ApplyTargetDamage then
        return false, "damage_service_unavailable"
    end
    return Damage.ApplyTargetDamage(record, attackerZombie, target, {
        damage = damage,
        attackType = attackType,
        attackKind = attackType,
        weaponItem = Internal.resolveWeaponItem(record),
    })
end
