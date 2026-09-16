-- Bandits damage bridge. The target mod remains responsible for the hit path.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Bandits = PNC.Compatibility.Bandits or {}
PNC.Compatibility.Bandits.Combat =
    PNC.Compatibility.Bandits.Combat or {}

local Combat = PNC.Compatibility.Bandits.Combat

function Combat.ApplyDamage(context)
    local target = context and context.target
    local payload = context and context.context or {}
    local victim = target and target.worldObject
    local attacker = payload.attackerBody
    local hit = payload.hit or {}
    local fakeZombie
    local health
    local amount = tonumber(hit.amount) or 0
    if not victim or not victim.isAlive or not victim:isAlive() then
        return false, "bandit_target_dead"
    end
    if amount <= 0 then return false, "bandit_damage_invalid" end
    if victim.setAttackedBy and attacker then
        victim:setAttackedBy(attacker)
    end
    fakeZombie = getCell and getCell():getFakeZombieForHit() or attacker
    if victim.Hit and hit.weaponItem then
        victim:Hit(hit.weaponItem, fakeZombie, amount, false, 1, false)
        return true, "hit_bandit"
    end
    if victim.getHealth and victim.setHealth then
        health = tonumber(victim:getHealth()) or 1
        victim:setHealth(math.max(0, health - amount))
        return true, "hit_bandit_health_fallback"
    end
    return false, "bandit_damage_path_unavailable"
end

return Combat
