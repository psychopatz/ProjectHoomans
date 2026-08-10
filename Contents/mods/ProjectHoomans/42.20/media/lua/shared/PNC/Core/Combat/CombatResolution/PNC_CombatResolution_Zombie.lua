local Resolution = PNC.CombatResolution

function Resolution.ApplyZombieDamage(attackerRecord, attackerZombie, target, hit)
    local perception = PNC.Perception
    local reaction = PNC.CombatZombieReaction
    local victim = target and target.worldObject or nil
    local fakeZombie
    local scaledDamage
    local applied = false
    local health
    local reactionOptions
    local threatID
    local threatTarget
    local protectedRecord
    local actorKey
    local targetKey
    local socialNow
    if not victim and target and target.zombieId and perception and perception.FindZombieByID then
        victim = perception.FindZombieByID(target.zombieId)
    end
    if not victim or victim:isDead() then return false, "invalid_zombie_target" end
    threatID = target and target.zombieId
        or (victim.getOnlineID and victim:getOnlineID())
        or (victim.getPersistentOutfitID
            and victim:getPersistentOutfitID())
    actorKey = attackerRecord
        and PNC.EntityRef
        and PNC.EntityRef.ForNPC(attackerRecord.id) or nil
    threatTarget = victim.getTarget and victim:getTarget() or nil
    protectedRecord = threatTarget
        and PNC.Registry
        and PNC.Registry.FindRecordByZombie
        and PNC.Registry.FindRecordByZombie(threatTarget) or nil
    targetKey = protectedRecord
        and PNC.EntityRef.ForNPC(protectedRecord.id) or nil
    socialNow = PNC.SocialEventHooks
        and PNC.SocialEventHooks.WorldAgeHours
        and PNC.SocialEventHooks.WorldAgeHours() or nil
    if actorKey
        and socialNow
        and PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.RecordActivity
    then
        PNC.SocialEncounterTracker.RecordActivity({
            actorKey = actorKey,
            targetKey = targetKey,
            threatID = threatID,
            threatWasTargeting = targetKey ~= nil,
            occurredAt = socialNow,
            actorX = attackerRecord.x,
            actorY = attackerRecord.y,
            actorZ = attackerRecord.z,
            targetX = protectedRecord and protectedRecord.x or nil,
            targetY = protectedRecord and protectedRecord.y or nil,
            targetZ = protectedRecord and protectedRecord.z or nil,
            x = victim:getX(),
            y = victim:getY(),
            z = victim:getZ(),
        })
    end
    fakeZombie = getCell and getCell():getFakeZombieForHit() or nil
    scaledDamage = hit.attackType == "ranged"
        and math.max(0.12, hit.amount * 0.06)
        or math.max(0.18, hit.amount * 0.08)
    reactionOptions = {
        kind = hit.attackType == "ranged" and "ranged" or "melee",
        hitReaction = hit.attackType == "ranged" and "ShotBelly" or "HitReaction",
        hitForce = hit.attackType == "ranged" and 0.78 or 0.92,
        pushDistance = hit.attackType == "ranged" and 0 or 0.18,
        pushDurationMs = hit.attackType == "ranged" and 0 or 150,
        durationMs = hit.attackType == "ranged" and 140 or 220,
        stepDistance = hit.attackType == "ranged" and 0.02 or 0.06,
        stagger = hit.attackType ~= "ranged",
        settleMs = hit.attackType == "ranged" and 420 or 650,
        partId = hit.partId,
        woundType = hit.woundType,
    }
    if reaction and reaction.ApplyWeaponHit then
        applied = reaction.ApplyWeaponHit(
            attackerZombie or fakeZombie,
            victim,
            hit.weaponItem,
            scaledDamage,
            reactionOptions
        )
    elseif hit.weaponItem and victim.Hit then
        applied = pcall(function()
            victim:Hit(hit.weaponItem, fakeZombie or attackerZombie, scaledDamage, false, 1, false)
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
    if not (reaction and reaction.ApplyWeaponHit) and reaction and reaction.Start then
        reaction.Start(attackerZombie or fakeZombie, victim, reactionOptions)
    end
    if PNC.ZombieAggro and PNC.ZombieAggro.OnZombieProvoked and (attackerZombie or fakeZombie) then
        PNC.ZombieAggro.OnZombieProvoked(victim, attackerZombie or fakeZombie)
    end
    if PNC.Network and PNC.Network.BroadcastZombieReaction then
        PNC.Network.BroadcastZombieReaction(victim, attackerZombie, reactionOptions)
    end
    if actorKey
        and socialNow
        and threatID ~= nil
        and ((victim.isDead and victim:isDead())
            or (victim.getHealth
                and (tonumber(victim:getHealth()) or 1) <= 0))
        and PNC.SocialEventHooks
        and PNC.SocialEventHooks.OnThreatNeutralized
    then
        PNC.SocialEventHooks.OnThreatNeutralized({
            actorKey = actorKey,
            targetKey = targetKey,
            threatID = threatID,
            threatWasTargeting = targetKey ~= nil,
            occurredAt = socialNow,
            x = victim:getX(),
            y = victim:getY(),
            z = victim:getZ(),
        })
    end
    return true, applied and "hit_zombie" or "hit_zombie_fallback", hit
end

return Resolution
