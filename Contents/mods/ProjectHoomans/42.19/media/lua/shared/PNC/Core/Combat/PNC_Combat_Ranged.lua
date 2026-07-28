--[[
    PNC Combat Ranged
    Owns firearm attack start logic. It starts a ranged attack action and lets
    the shared attack pump resolve the delayed hit window.
]]

PNC = PNC or {}
PNC.Combat = PNC.Combat or {}

local Combat = PNC.Combat
local Internal = PNC.Combat.Internal or {}
local Core = PNC.Core
local Const = PNC.Const
local Equipment = PNC.Equipment
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Damage = PNC.CombatDamage
local Firearms = PNC.Firearms
local Tactics = PNC.CombatTactics

function Combat.TryRanged(record, zombie, target)
    local now = Core.Now()
    local profile = record.combatProfile or {}
    local cooldownMs = tonumber(profile.rangedCooldownMs) or 1800
    local damage = tonumber(profile.rangedDamage) or 7
    local dist
    local equipmentInfo = Equipment.Describe(record)
    local skillID = "Aiming"
    local aimingLevel = Skills and Skills.GetLevel and Skills.GetLevel(record, "Aiming") or 0
    local anim
    local weaponItem = Internal.resolveWeaponItem and Internal.resolveWeaponItem(record, zombie) or nil
    local ammoReady
    local ammoReason
    local magazine
    local reloadStarted
    local reloadReason
    local shotReady
    local shotReason

    if not target then
        return false, "no_target"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive and PNC.PathService.IsTraversalActive(record, zombie) then
        return false, "traversal_active"
    end
    if equipmentInfo.combatModeResolved ~= "ranged" and equipmentInfo.combatModeResolved ~= "mixed" then
        return false, equipmentInfo.weaponStatus or "ranged_weapon_unavailable"
    end
    if not weaponItem or not weaponItem.IsWeapon or not weaponItem:IsWeapon() then
        return false, "ranged_weapon_instance_unavailable"
    end
    if Combat.HasActiveAttack and Combat.HasActiveAttack(record, now) then
        return false, "attack_in_progress"
    end

    -- Empty magazines begin reloading as soon as the previous shot action
    -- releases. Do not make a double-barrel wait through its attack cooldown
    -- before it is even allowed to start the reload animation.
    if Firearms and Firearms.GetMagazineState then
        magazine, ammoReason = Firearms.GetMagazineState(record, weaponItem)
        if not magazine then
            return false, ammoReason or "magazine_unavailable"
        end
        if magazine.ammoNotRequired ~= true
            and (tonumber(magazine.count) or 0) <= 0
        then
            if magazine.unlimitedReserve == true
                or (tonumber(magazine.looseAmmo) or 0) > 0
            then
                reloadStarted, reloadReason = Firearms.StartReload(
                    record,
                    zombie,
                    target,
                    weaponItem
                )
                if reloadStarted then return false, "reload_started" end
                return false, reloadReason or "reload_required"
            end
            return false, "out_of_ammo"
        end
    end
    if not Internal.canAttack(record, now, cooldownMs) then
        return false, "cooldown_active"
    end

    dist = math.sqrt(tonumber(target.distSq) or 0)
    if dist > Const.RANGED_RANGE then
        return false, "target_out_of_range"
    end
    if Stamina and Stamina.CanSpendAttack and not Stamina.CanSpendAttack(record, "ranged", skillID) then
        return false, "stamina_exhausted"
    end
    if Tactics and Tactics.CanTakeRangedShot then
        shotReady, shotReason = Tactics.CanTakeRangedShot(record, target)
        if not shotReady then
            return false, shotReason or "aiming"
        end
    end

    if Firearms and Firearms.PrepareShot then
        ammoReady, ammoReason, magazine = Firearms.PrepareShot(record, weaponItem)
        if not ammoReady then
            if ammoReason == "reload_required" and Firearms.StartReload then
                reloadStarted, reloadReason = Firearms.StartReload(record, zombie, target, weaponItem)
                if reloadStarted then
                    return false, "reload_started"
                end
                return false, reloadReason or ammoReason
            end
            return false, ammoReason or "out_of_ammo"
        end
    end

    if Damage and Damage.GetAttackDamage and Damage.IsWeaponDamageEnabled and Damage.IsWeaponDamageEnabled() then
        damage = Damage.GetAttackDamage(record, "ranged", weaponItem, damage, aimingLevel)
    else
        damage = damage * (0.9 + math.min(aimingLevel, 8) * 0.05)
    end
    record.runtime.lastAttackAt = now
    record.runtime.inCombatUntil = now + Const.DEBUG_COMBAT_HOLD_MS
    Internal.faceTarget(zombie, target, record, Internal.ATTACK_TIMINGS.ranged.duration, "ranged_windup")
    if zombie then
        anim = Internal.triggerRangedWeaponAnim(zombie, record, equipmentInfo)
    end
    Internal.buildAttackAction(
        record,
        target,
        "ranged",
        "ranged",
        anim or "PNC_AttackPistol",
        damage,
        skillID,
        {
            ammoConsumed = ammoReady == true,
            weaponFullType = magazine and magazine.descriptor and magazine.descriptor.fullType or nil,
        }
    )
    if Tactics and Tactics.MarkRangedShot then
        Tactics.MarkRangedShot(record)
    end
    return true, "ranged_attack_started"
end
