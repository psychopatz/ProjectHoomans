--[[
    PNC Combat Attack Actions
    Owns delayed hit windows, target re-resolution, zombie damage application,
    and active attack pumping so animations can complete before hits resolve.
]]

PNC = PNC or {}
PNC.Combat = PNC.Combat or {}
PNC.Combat.Internal = PNC.Combat.Internal or {}

local Combat = PNC.Combat
local Internal = Combat.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local Registry = PNC.Registry
local Health = PNC.Health
local Perception = PNC.Perception
local ZombieAggro = PNC.ZombieAggro
local Unarmed = PNC.CombatUnarmed
local ZombieReaction = PNC.CombatZombieReaction
local Skills = PNC.Skills
local Stamina = PNC.Stamina
local Tactics = PNC.CombatTactics
local Animation = PNC.Animation
local Damage = PNC.CombatDamage

local function applyWeaponWear(record)
    local weaponItem = Internal.resolveWeaponItem and Internal.resolveWeaponItem(record) or nil
    if Damage and Damage.ApplyWeaponConditionLoss then
        Damage.ApplyWeaponConditionLoss(record, weaponItem)
    end
end

local function captureTargetRef(target)
    local worldObject
    if not target then
        return nil
    end
    if target.kind == "zombie" and target.zombieId and Perception and Perception.FindZombieByID then
        worldObject = Perception.FindZombieByID(target.zombieId)
    elseif target.kind == "player" then
        worldObject = target.player
    end
    return {
        kind = target.kind,
        id = target.id,
        onlineID = target.onlineID,
        username = target.username,
        zombieId = target.zombieId,
        x = target.x,
        y = target.y,
        z = target.z,
        -- Runtime-only identity anchor. The stable ID remains authoritative
        -- across index rebuilds; this direct reference closes the short gap
        -- between attack commit and the delayed hit frame.
        worldObject = worldObject,
    }
end

local function resolveActionTarget(targetRef)
    local targetRecord
    local player
    local zombieTarget
    if not targetRef then
        return nil
    end
    if targetRef.kind == "player" then
        player = Core.ResolvePlayerByOnlineID(targetRef.onlineID) or Core.ResolvePlayerByUsername(targetRef.username)
        if not player then
            return nil
        end
        return {
            kind = "player",
            player = player,
            x = player:getX(),
            y = player:getY(),
            z = player:getZ(),
            distSq = 0,
        }
    end
    if targetRef.kind == "npc" then
        targetRecord = Registry.Get(targetRef.id)
        if not targetRecord or targetRecord.alive == false then
            return nil
        end
        return {
            kind = "npc",
            id = targetRecord.id,
            x = targetRecord.x,
            y = targetRecord.y,
            z = targetRecord.z,
            distSq = 0,
        }
    end
    if targetRef.kind == "zombie" then
        zombieTarget = targetRef.worldObject
        if zombieTarget and zombieTarget.isDead and zombieTarget:isDead() then
            zombieTarget = nil
        end
        if not zombieTarget then
            zombieTarget = Perception.FindZombieByID and Perception.FindZombieByID(targetRef.zombieId) or nil
        end
        if not zombieTarget or zombieTarget:isDead() then
            return nil
        end
        return {
            kind = "zombie",
            zombieId = targetRef.zombieId,
            worldObject = zombieTarget,
            x = zombieTarget:getX(),
            y = zombieTarget:getY(),
            z = zombieTarget:getZ(),
            distSq = 0,
        }
    end
    return nil
end

local function isActionTargetVisible(record, target)
    local worldObject
    local visible
    local visibilityKind
    if not target or not Perception or not Perception.CanSeeWorldObject then
        return false
    end
    if target.kind == "player" then
        worldObject = target.player
    elseif target.kind == "npc" then
        worldObject = Registry.GetLiveZombie(target.id)
    elseif target.kind == "zombie" then
        worldObject = target.worldObject or Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId) or nil
    end
    if not worldObject then
        return false
    end
    visible, visibilityKind = Perception.CanSeeWorldObject(record, worldObject)
    return visible == true and visibilityKind ~= "clearthroughwindow"
end

local function isCommittedMeleeTargetInRange(zombie, target)
    local dx
    local dy
    local dz
    local range
    if not zombie or not target or target.x == nil or target.y == nil then
        return false
    end
    dx = (tonumber(target.x) or zombie:getX()) - zombie:getX()
    dy = (tonumber(target.y) or zombie:getY()) - zombie:getY()
    dz = math.abs((tonumber(target.z) or zombie:getZ()) - zombie:getZ())
    range = (tonumber(Const.MELEE_RANGE) or 1.3) + (tonumber(Const.MELEE_HIT_TOLERANCE) or 0.12)
    return dz <= 0.25 and ((dx * dx) + (dy * dy)) <= (range * range)
end

function Internal.clearAttackAction(record)
    if record and record.runtime then
        record.runtime.attackAction = nil
    end
end

function Internal.finishAttackAction(record, zombie)
    if Animation and Animation.FinishBump then
        Animation.FinishBump(zombie, true)
    end
    Internal.clearAttackAction(record)
end

function Internal.buildAttackAction(record, target, attackKind, attackType, anim, damage, skillID, extra)
    local now = Core.Now()
    local timings = Internal.ATTACK_TIMINGS[attackKind] or Internal.ATTACK_TIMINGS.melee
    local action = {
        attackKind = attackKind,
        attackType = attackType,
        anim = anim,
        damage = damage,
        skillID = skillID,
        startedAt = now,
        hitAt = now + timings.hitDelay,
        finishAt = now + timings.duration,
        hitDone = false,
        target = captureTargetRef(target),
    }
    local key
    if type(extra) == "table" then
        for key, value in pairs(extra) do
            action[key] = value
        end
    end
    record.runtime.attackAction = action
    -- Server.OnTick consumes this after movement pumping and sends exactly one
    -- transition snapshot, avoiding both a delayed attack start and a duplicate
    -- periodic snapshot in the same tick.
    if isServer and isServer() then
        record.runtime.forceSyncEvent = "attack_start"
    end
    return action
end

function Internal.applyDamageToZombie(record, attackerZombie, target, damage, attackType)
    local victim = target and target.worldObject or nil
    local fakeZombie
    local weaponItem
    local health
    local scaledDamage
    local applied = false
    local reactionOptions
    local reactionManaged

    if (not victim) and target and target.zombieId and Perception.FindZombieByID then
        victim = Perception.FindZombieByID(target.zombieId)
    end
    if not victim or victim:isDead() then
        return false, "invalid_zombie_target"
    end

    weaponItem = Internal.resolveWeaponItem(record)
    fakeZombie = getCell and getCell():getFakeZombieForHit() or nil
    if attackType == "ranged" then
        scaledDamage = math.max(0.12, (tonumber(damage) or 0) * 0.06)
    else
        scaledDamage = math.max(0.18, (tonumber(damage) or 0) * 0.08)
    end

    reactionOptions = {
        kind = attackType == "ranged" and "ranged" or "melee",
        hitReaction = attackType == "ranged" and "ShotBelly" or "HitReaction",
        hitForce = attackType == "ranged" and 0.78 or 0.92,
        pushDistance = attackType == "ranged" and 0 or 0.18,
        pushDurationMs = attackType == "ranged" and 0 or 150,
        durationMs = attackType == "ranged" and 140 or 220,
        stepDistance = attackType == "ranged" and 0.02 or 0.06,
        stagger = attackType ~= "ranged",
        settleMs = attackType == "ranged" and 420 or 650,
    }

    reactionManaged = ZombieReaction and ZombieReaction.ApplyWeaponHit ~= nil
    if reactionManaged then
        applied = ZombieReaction.ApplyWeaponHit(attackerZombie or fakeZombie, victim, weaponItem, scaledDamage, reactionOptions)
    elseif weaponItem and victim.Hit then
        applied = pcall(function()
            victim:Hit(weaponItem, fakeZombie or attackerZombie, scaledDamage, false, 1, false)
        end)
    end

    if not applied then
        health = tonumber(victim:getHealth()) or 1
        victim:setHealth(health - scaledDamage)
        if victim:getHealth() <= 0 then
            if victim.Kill then
                victim:Kill(attackerZombie or fakeZombie)
            elseif victim.setHealth then
                victim:setHealth(0)
            end
        end
    end
    if not reactionManaged and ZombieReaction and ZombieReaction.Start then
        ZombieReaction.Start(attackerZombie or fakeZombie, victim, reactionOptions)
    elseif not reactionManaged and attackType == "ranged" and victim.setHitReaction then
        victim:setHitReaction("ShotBelly")
    elseif not reactionManaged and victim.setHitReaction then
        victim:setHitReaction("HitReaction")
    end
    if ZombieAggro and ZombieAggro.OnZombieProvoked and (attackerZombie or fakeZombie) then
        ZombieAggro.OnZombieProvoked(victim, attackerZombie or fakeZombie)
    end
    -- IsoZombie:Hit has no native zombie-on-zombie hit packet. Replicate only
    -- the server-approved visual result; damage and death stay authoritative.
    if PNC.Network and PNC.Network.BroadcastZombieReaction then
        PNC.Network.BroadcastZombieReaction(victim, attackerZombie, reactionOptions)
    end
    applyWeaponWear(record)
    return true, applied and "hit_zombie" or "hit_zombie_fallback"
end

function Internal.applyAttackActionHit(record, zombie, action, target)
    local targetRecord
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
        if Damage and Damage.ConsumeAmmo then
            consumed, ammoReason = Damage.ConsumeAmmo(record, weaponItem)
            if not consumed then
                return false, ammoReason or "out_of_ammo"
            end
        end
        action.ammoConsumed = true
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
            if Damage and Damage.ApplyPlayerDamage and Damage.ApplyPlayerDamage(target.player, action.damage, "melee", Internal.resolveWeaponItem(record))
                or (not Damage and Health.ApplyDamageToPlayer(target.player, action.damage))
            then
                applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "melee", action.skillID)
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, action.skillID or "Strength", action.attackKind == "ground" and 4 or 5)
                    Skills.AddXP(record, "Maintenance", 1)
                end
                return true, "hit_player"
            end
            return false, "invalid_player_target"
        end
        if target.kind == "npc" then
            targetRecord = Registry.Get(target.id)
            if not targetRecord then
                return false, "invalid_npc_target"
            end
            if Health.ApplyDamage(targetRecord, Registry.GetLiveZombie(target.id), {
                amount = action.damage,
                type = "melee",
                attackerID = record.id,
                attackerKind = "npc",
            }) then
                applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "melee", action.skillID)
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, action.skillID or "Strength", 5)
                    Skills.AddXP(record, "Maintenance", 1)
                end
                return true, "hit_npc"
            end
            return false, "npc_damage_rejected"
        end
        if target.kind == "zombie" then
            if Stamina and Stamina.SpendAttack then
                Stamina.SpendAttack(record, "melee", action.skillID)
            end
            if Skills and Skills.AddXP then
                Skills.AddXP(record, action.skillID or "Strength", action.attackKind == "ground" and 4 or 5)
                Skills.AddXP(record, "Maintenance", 1)
            end
            attackApplied, attackReason = Internal.applyDamageToZombie(record, zombie, target, action.damage, "melee")
            if attackApplied and action.attackKind == "melee" and Tactics and Tactics.ShouldPressureShove and Tactics.ShouldPressureShove(record) then
                zombieTarget = Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId) or nil
                if zombieTarget and Unarmed and Unarmed.ApplyZombieShove then
                    Unarmed.ApplyZombieShove(zombie, zombieTarget, {
                        kind = "pressure_shove",
                        hitForce = 1.02,
                        pushDistance = 0.22,
                        pushDurationMs = 170,
                        durationMs = 220,
                        stepDistance = 0.06,
                    })
                end
            end
            return attackApplied, attackReason
        end
    end

    if action.attackType == "ranged" then
        if target.kind == "player" then
            if Damage and Damage.ApplyPlayerDamage and Damage.ApplyPlayerDamage(target.player, action.damage, "ranged", Internal.resolveWeaponItem(record))
                or (not Damage and Health.ApplyDamageToPlayer(target.player, action.damage))
            then
                applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "ranged", action.skillID or "Aiming")
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, "Aiming", 5)
                    Skills.AddXP(record, "Reloading", 2)
                end
                return true, "hit_player"
            end
            return false, "invalid_player_target"
        end
        if target.kind == "npc" then
            targetRecord = Registry.Get(target.id)
            if not targetRecord then
                return false, "invalid_npc_target"
            end
            if Health.ApplyDamage(targetRecord, Registry.GetLiveZombie(target.id), {
                amount = action.damage,
                type = "ranged",
                attackerID = record.id,
                attackerKind = "npc",
            }) then
                applyWeaponWear(record)
                if Stamina and Stamina.SpendAttack then
                    Stamina.SpendAttack(record, "ranged", action.skillID or "Aiming")
                end
                if Skills and Skills.AddXP then
                    Skills.AddXP(record, "Aiming", 5)
                    Skills.AddXP(record, "Reloading", 2)
                end
                return true, "hit_npc"
            end
            return false, "npc_damage_rejected"
        end
        if target.kind == "zombie" then
            if Stamina and Stamina.SpendAttack then
                Stamina.SpendAttack(record, "ranged", action.skillID or "Aiming")
            end
            if Skills and Skills.AddXP then
                Skills.AddXP(record, "Aiming", 5)
                Skills.AddXP(record, "Reloading", 2)
            end
            return Internal.applyDamageToZombie(record, zombie, target, action.damage, "ranged")
        end
    end

    return false, "unknown_target"
end

function Combat.HasActiveAttack(record, now)
    local action = record and record.runtime and record.runtime.attackAction or nil
    now = tonumber(now) or Core.Now()
    return action ~= nil and now < (tonumber(action.finishAt) or 0)
end

function Combat.PumpAttackAction(record, zombie)
    local now = Core.Now()
    local action = record and record.runtime and record.runtime.attackAction or nil
    local target
    local bumpFinished
    if not action then
        return false, "no_attack"
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive and PNC.PathService.IsTraversalActive(record, zombie) then
        -- Traversal owns the bump animation. Do not call finishAttackAction:
        -- that would mark the traversal bump complete and teleport the body.
        Internal.clearAttackAction(record)
        return false, "attack_cancelled_for_traversal"
    end
    if not zombie or record.alive == false then
        Internal.finishAttackAction(record, zombie)
        return false, "attack_cleared"
    end

    target = resolveActionTarget(action.target)
    if not target then
        Internal.finishAttackAction(record, zombie)
        return false, "target_lost_or_dead"
    end
    if target
        and not isActionTargetVisible(record, target)
        and not (action.attackType == "melee" and isCommittedMeleeTargetInRange(zombie, target))
    then
        Internal.finishAttackAction(record, zombie)
        return false, "target_not_visible"
    end
    if target then
        Internal.faceTarget(zombie, target, record, 120, "attack_followthrough")
    end

    if (not action.hitDone) and now >= (tonumber(action.hitAt) or 0) then
        action.hitDone = true
        if action.attackType == "melee" and not isCommittedMeleeTargetInRange(zombie, target) then
            action.lastResult = false
            action.lastReason = "target_out_of_range_at_hit"
        else
            action.lastResult, action.lastReason = Internal.applyAttackActionHit(record, zombie, action, target)
        end
        if action.lastResult ~= true and Core and Core.Log then
            Core.Log("WARN", "attack_hit_failed npc=" .. tostring(record and record.id or "nil") .. " reason=" .. tostring(action.lastReason or "unknown") .. " target=" .. tostring(target and target.kind or "nil"))
        end
    end

    bumpFinished = zombie.getVariableBoolean and zombie:getVariableBoolean("BumpAnimFinished") or false
    if bumpFinished == true and action.hitDone ~= true then
        action.hitDone = true
        if action.attackType == "melee" and not isCommittedMeleeTargetInRange(zombie, target) then
            action.lastResult = false
            action.lastReason = "target_out_of_range_at_anim_end"
        else
            action.lastResult, action.lastReason = Internal.applyAttackActionHit(record, zombie, action, target)
        end
    end
    if target == nil or bumpFinished == true or now >= (tonumber(action.finishAt) or 0) then
        Internal.finishAttackAction(record, zombie)
        return false, action.lastReason or (target and "attack_finished" or "target_lost")
    end

    return true, action.attackType == "ranged" and "attack_anim_ranged" or "attack_anim_melee"
end
