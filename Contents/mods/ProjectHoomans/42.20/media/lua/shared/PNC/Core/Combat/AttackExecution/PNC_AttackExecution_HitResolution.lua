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
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function logFirearmAudit(eventName, record, action, ...)
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
        "actionType=" .. tostring(action and action.attackType or ""),
    }
    for i = 1, select("#", ...) do
        fields[#fields + 1] = tostring(select(i, ...))
    end
    return Diagnostics.LogFirearmAudit(eventName, fields)
end

local function commitMeleeImpactAudio(record, action, target)
    if Internal.commitMeleeImpactAudio then
        Internal.commitMeleeImpactAudio(record, action, target)
    end
end

local function resolveRangedOutcome(record, target, action)
    local rangedHit
    local rangedReason
    local rangedProfile
    if not Resolution or not Resolution.ResolveRangedShot then
        return true, nil, nil
    end
    if type(action.rangedOutcome) ~= "table" then
        rangedHit, rangedReason, rangedProfile =
            Resolution.ResolveRangedShot(record, target, {
                profile = action.rangedShotProfile,
            })
        action.rangedOutcome = {
            hit = rangedHit == true,
            reason = rangedReason or "ranged_miss",
            profile = rangedProfile,
        }
        logFirearmAudit("ranged_attack_resolved", record, action,
            "result=" .. tostring(action.rangedOutcome.reason),
            "chance=" .. tostring(rangedProfile and rangedProfile.hitChance or ""),
            "roll=" .. tostring(rangedProfile and rangedProfile.roll or ""))
    end
    return action.rangedOutcome.hit == true,
        action.rangedOutcome.reason or "ranged_miss",
        action.rangedOutcome.profile
end

local function resolveMeleeOutcome(record, target, action)
    local meleeHit
    local meleeReason
    local meleeProfile
    if not Resolution or not Resolution.ResolveMeleeStrike then
        return true, nil, nil
    end
    if type(action.meleeOutcome) ~= "table" then
        meleeHit, meleeReason, meleeProfile =
            Resolution.ResolveMeleeStrike(record, target, {
                profile = action.meleeStrikeProfile,
            })
        action.meleeOutcome = {
            hit = meleeHit == true,
            reason = meleeReason or "melee_miss",
            profile = meleeProfile,
        }
    end
    return action.meleeOutcome.hit == true,
        action.meleeOutcome.reason or "melee_miss",
        action.meleeOutcome.profile
end

local function commitMeleeSwingResources(record, action)
    if action.meleeResourcesCommitted == true then return end
    action.meleeResourcesCommitted = true
    AttackExecution.applyWeaponWear(record)
    if Stamina and Stamina.SpendAttack then
        Stamina.SpendAttack(record, "melee", action.skillID)
    end
end

function Internal.applyAttackActionHit(record, zombie, action, target)
    local zombieTarget
    local attackApplied
    local attackReason
    local rangedReady
    local rangedReason
    local rangedProfile
    local meleeReady
    local meleeReason
    local meleeProfile
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
        logFirearmAudit("attack_effect_gate", record, action,
            "effectDone=true", "firearmEmitter=" .. tostring(FirearmEffects ~= nil))
        if FirearmEffects and FirearmEffects.Emit then
            FirearmEffects.Emit(
                record,
                zombie,
                target,
                Internal.resolveWeaponItem and Internal.resolveWeaponItem(record, zombie) or nil
            )
        else
            logFirearmAudit("attack_effect_rejected", record, action,
                "reason=firearm_effect_service_unavailable")
        end
    end

    if action.attackType == "ranged" then
        rangedReady, rangedReason, rangedProfile =
            resolveRangedOutcome(record, target, action)
        if not rangedReady then
            return false, rangedReason, rangedProfile
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

    if action.attackType == "melee" and action.attackKind ~= "ground" then
        meleeReady, meleeReason, meleeProfile =
            resolveMeleeOutcome(record, target, action)
        if not meleeReady then
            if meleeReason ~= "not_authority" then
                commitMeleeSwingResources(record, action)
            end
            return false, meleeReason or "melee_miss", meleeProfile
        end
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
                commitMeleeImpactAudio(record, action, target)
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
                commitMeleeImpactAudio(record, action, target)
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
                commitMeleeImpactAudio(record, action, target)
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
