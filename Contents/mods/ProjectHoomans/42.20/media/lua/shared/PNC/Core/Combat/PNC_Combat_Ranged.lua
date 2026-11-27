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
local Resolution = PNC.CombatResolution
local Firearms = PNC.Firearms
local Tactics = PNC.CombatTactics
local TraitEffects = PNC.NPCTraitEffects
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function readMethod(target, methodName, ...)
    local method
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    return method(target, ...)
end

local function logFirearmAudit(eventName, record, target, ...)
    local fields
    local i
    if not Diagnostics
        or Diagnostics.FirearmAuditEnabled ~= true
        or type(Diagnostics.LogFirearmAudit) ~= "function"
    then
        return false
    end
    fields = {
        "side=authority",
        "shotId=unassigned",
        "npc=" .. tostring(record and record.id or ""),
        "class=" .. tostring(record and record.tacticalClass or "unknown"),
        "faction=" .. tostring(record and record.affiliation
            and record.affiliation.factionID or ""),
        "hostility=" .. tostring(record and record.hostility
            and record.hostility.mode or ""),
        "targetKind=" .. tostring(target and target.kind or ""),
    }
    for i = 1, select("#", ...) do
        fields[#fields + 1] = tostring(select(i, ...))
    end
    return Diagnostics.LogFirearmAudit(eventName, fields)
end

local function resolveFirearmTiming(record, profile, descriptor)
    local modifiers = TraitEffects
        and TraitEffects.ResolveFirearmModifiers
        and TraitEffects.ResolveFirearmModifiers(record) or {}
    local defaultTimings = Internal.ATTACK_TIMINGS and Internal.ATTACK_TIMINGS.ranged
        or { hitDelay = 180, duration = 620 }
    local hitDelayMs = (descriptor and tonumber(descriptor.shotHitDelayMs))
        or defaultTimings.hitDelay
    local durationMs = (descriptor and tonumber(descriptor.shotDurationMs))
        or defaultTimings.duration
    local baseCooldown = (descriptor and tonumber(descriptor.fireCooldownMs))
        or tonumber(profile.rangedCooldownMs)
        or 1800
    local aiming = Skills and Skills.GetLevel
        and math.max(0, math.min(10, tonumber(Skills.GetLevel(record, "Aiming")) or 0))
        or 0
    if descriptor and tonumber(descriptor.fireCooldownMs) then
        baseCooldown = math.floor(baseCooldown * (1 - aiming * 0.015))
    end
    local cooldown = Resolution and Resolution.GetRangedCooldown
        and Resolution.GetRangedCooldown(
            record,
            baseCooldown,
            modifiers,
            { actionDurationMs = durationMs }
        )
        or baseCooldown
    local burstSize = descriptor and tonumber(descriptor.burstSize) or 0
    local burstPauseMs = descriptor and tonumber(descriptor.burstPauseMs) or 0
    local runtime = record and record.runtime or nil
    if burstSize > 0 and burstPauseMs > 0 and runtime
        and (tonumber(runtime.firearmBurstCount) or 0) >= burstSize
    then
        cooldown = cooldown + burstPauseMs
    end
    return modifiers, cooldown, hitDelayMs, durationMs
end

local function buildShotProfile(record, target, modifiers, distance)
    if not Resolution or not Resolution.BuildRangedShotProfile then
        return nil
    end
    return Resolution.BuildRangedShotProfile(record, target, {
        modifiers = modifiers,
        distance = distance,
        aimConfidence = record.runtime.combatAim
            and record.runtime.combatAim.confidence or 0,
        pressureCount = record.runtime.combatAim
            and record.runtime.combatAim.visiblePressureCount or 0,
    })
end

function Combat.TryRanged(record, zombie, target)
    local now = Core.Now()
    local profile = record.combatProfile or {}
    local firearmModifiers
    local cooldownMs
    local damage = tonumber(profile.rangedDamage) or 7
    local dist
    local equipmentInfo = Equipment.Describe(record)
    local skillID = "Aiming"
    local aimingLevel
    local anim
    local weaponItem
    local ammoReady
    local ammoReason
    local magazine
    local reloadStarted
    local reloadReason
    local shotReady
    local shotReason
    local shotProfile

    if not target then
        return false, "no_target"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive and PNC.PathService.IsTraversalActive(record, zombie) then
        return false, "traversal_active"
    end
    if equipmentInfo.combatModeResolved ~= "ranged" and equipmentInfo.combatModeResolved ~= "mixed" then
        return false, equipmentInfo.weaponStatus or "ranged_weapon_unavailable"
    end
    weaponItem = Internal.resolveWeaponItem and Internal.resolveWeaponItem(record, zombie) or nil
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
        magazine, ammoReason = Firearms.GetMagazineState(record, weaponItem, {
            skipLooseAmmoWhenLoaded = true,
        })
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
    local firearmDescriptor = (magazine and magazine.descriptor)
        or (Firearms and Firearms.Describe and Firearms.Describe(record, weaponItem, zombie))
        or nil
    local shotHitDelayMs
    local shotDurationMs
    firearmModifiers, cooldownMs, shotHitDelayMs, shotDurationMs =
        resolveFirearmTiming(record, profile, firearmDescriptor)
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

    shotProfile = buildShotProfile(record, target, firearmModifiers, dist)

    if Firearms and Firearms.PrepareShot then
        ammoReady, ammoReason, magazine = Firearms.PrepareShot(record, weaponItem, magazine)
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

    aimingLevel = Skills and Skills.GetLevel and Skills.GetLevel(record, "Aiming") or 0
    if Resolution and Resolution.GetAttackDamage and Resolution.IsWeaponDamageEnabled and Resolution.IsWeaponDamageEnabled() then
        damage = Resolution.GetAttackDamage(record, "ranged", weaponItem, damage, aimingLevel)
    else
        damage = damage * (0.9 + math.min(aimingLevel, 8) * 0.05)
    end
    if Internal.prepareAttackMovement then
        Internal.prepareAttackMovement(
            record,
            zombie,
            "ranged_windup"
        )
    end
    record.runtime.lastAttackAt = now
    record.runtime.inCombatUntil = now + Const.DEBUG_COMBAT_HOLD_MS
    local burstSize = firearmDescriptor and tonumber(firearmDescriptor.burstSize) or 0
    if burstSize > 0 then
        local prevBurst = tonumber(record.runtime.firearmBurstCount) or 0
        record.runtime.firearmBurstCount = (prevBurst >= burstSize) and 1 or (prevBurst + 1)
    else
        record.runtime.firearmBurstCount = 0
    end
    Internal.faceTarget(zombie, target, record, shotDurationMs, "ranged_windup")
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
            hitDelayMs = shotHitDelayMs,
            durationMs = shotDurationMs,
            ammoConsumed = ammoReady == true,
            weaponFullType = magazine and magazine.descriptor and magazine.descriptor.fullType or nil,
            cadenceClass = firearmDescriptor and firearmDescriptor.cadenceClass or nil,
            effectiveCooldownMs = cooldownMs,
            firearmModifiers = firearmModifiers,
            rangedShotProfile = shotProfile,
        }
    )
    if Tactics and Tactics.MarkRangedShot then
        Tactics.MarkRangedShot(record, firearmDescriptor and firearmDescriptor.followUpAimScale or nil)
    end
    logFirearmAudit("ranged_attack_started", record, target,
        "animation=" .. tostring(anim or "PNC_AttackPistol"),
        "weapon=" .. tostring(weaponItem and readMethod(weaponItem, "getFullType") or ""),
        "distance=" .. tostring(dist),
        "cooldownMs=" .. tostring(cooldownMs),
        "hitChance=" .. tostring(shotProfile and shotProfile.hitChance or ""))
    return true, "ranged_attack_started"
end
