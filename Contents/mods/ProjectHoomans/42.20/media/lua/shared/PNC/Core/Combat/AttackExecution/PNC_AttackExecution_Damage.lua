-- Damage service adapters and weapon-condition handling.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Resolution = PNC.CombatResolution

function AttackExecution.applyWeaponWear(record)
    local weaponItem = Internal.resolveWeaponItem and Internal.resolveWeaponItem(record) or nil
    if Resolution and Resolution.ApplyWeaponConditionLoss then
        Resolution.ApplyWeaponConditionLoss(record, weaponItem)
    end
end

function Internal.applyDamageToZombie(record, attackerZombie, target, damage, attackType)
    if not Resolution or not Resolution.ApplyTargetDamage then
        return false, "damage_service_unavailable"
    end
    return Resolution.ApplyTargetDamage(record, attackerZombie, target, {
        damage = damage,
        attackType = attackType,
        attackKind = attackType,
        weaponItem = Internal.resolveWeaponItem(record),
    })
end
