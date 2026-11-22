-- Damage service adapters and weapon-condition handling.

local Combat = PNC.Combat
local Internal = Combat.Internal
local AttackExecution = Internal.AttackExecution
local Resolution = PNC.CombatResolution

function AttackExecution.applyWeaponWear(record, zombie, weaponItem)
    weaponItem = weaponItem
        or (Internal.resolveWeaponItem and Internal.resolveWeaponItem(record, zombie))
        or nil
    if Resolution and Resolution.ApplyWeaponConditionLoss then
        Resolution.ApplyWeaponConditionLoss(record, weaponItem)
    end
end

function Internal.applyDamageToZombie(record, attackerZombie, target, damage, attackType, weaponItem, weaponFullType)
    if not Resolution or not Resolution.ApplyTargetDamage then
        return false, "damage_service_unavailable"
    end
    weaponItem = weaponItem
        or (Internal.resolveWeaponItem and Internal.resolveWeaponItem(record, attackerZombie))
        or nil
    return Resolution.ApplyTargetDamage(record, attackerZombie, target, {
        damage = damage,
        attackType = attackType,
        attackKind = attackType,
        weaponItem = weaponItem,
        weaponFullType = weaponFullType,
    })
end
