-- Attacker resolution and grounded counter-stagger policy.

local Internal = PNC.LiveBodyControl.Internal
local Core = PNC.Core

function Internal.randomUnit()
    if ZombRand then return ZombRand(10000) / 10000 end
    return math.random()
end

function Internal.resolveGroundAttacker(record, zombie)
    local attacker = zombie and zombie.getAttackedBy
        and zombie:getAttackedBy() or nil
    local target
    if attacker then return attacker end
    target = PNC.Perception and PNC.Perception.ResolveRecentAttacker
        and PNC.Perception.ResolveRecentAttacker(
            record,
            Core and Core.Now and Core.Now() or 0
        ) or nil
    if not target then return nil end
    if target.kind == "player" then return target.player end
    if target.kind == "npc" and PNC.Registry and PNC.Registry.GetLiveZombie then
        return PNC.Registry.GetLiveZombie(target.id)
    end
    if target.kind == "zombie" then
        return target.worldObject or (
            PNC.Perception.FindZombieByID
                and PNC.Perception.FindZombieByID(target.zombieId)
                or nil
        )
    end
    return nil
end

function Internal.isFriendlyGroundAttacker(record, attacker)
    local other
    if PNC.PlayerDamage and PNC.PlayerDamage.IsFriendlyOwner
        and PNC.PlayerDamage.IsFriendlyOwner(record, attacker)
    then
        return true
    end
    if not (Core and Core.IsManagedNPCBody
        and Core.IsManagedNPCBody(attacker))
    then
        return false
    end
    other = PNC.Registry and PNC.Registry.FindRecordByZombie
        and PNC.Registry.FindRecordByZombie(attacker) or nil
    if not other then return false end
    if tostring(other.id or "") == tostring(record.id or "") then
        return true
    end
    if PNC.Relationships and PNC.Relationships.AreNPCsEnemies then
        return not PNC.Relationships.AreNPCsEnemies(record, other)
    end
    if record.ownerOnlineID ~= nil and other.ownerOnlineID ~= nil then
        return tonumber(record.ownerOnlineID) == tonumber(other.ownerOnlineID)
    end
    return tostring(record.tacticalClass or "") == tostring(other.tacticalClass or "")
end

function Internal.counterStagger(record, zombie, attacker)
    local maxRange = tonumber(
        PNC.Const and PNC.Const.NPC_GROUNDED_COUNTER_STAGGER_RANGE
    ) or 2.25
    local dx
    local dy
    if not attacker or not attacker.getX or not attacker.getY
        or not attacker.getZ
        or math.abs(attacker:getZ() - zombie:getZ()) >= 1
    then
        return false
    end
    dx = attacker:getX() - zombie:getX()
    dy = attacker:getY() - zombie:getY()
    if (dx * dx) + (dy * dy) > maxRange * maxRange then return false end
    if Internal.isFriendlyGroundAttacker(record, attacker) then return false end
    if attacker.getObjectName
        and tostring(attacker:getObjectName() or "") == "Player"
    then
        if attacker.clearVariable then attacker:clearVariable("BumpFallType") end
        if attacker.setBumpType then attacker:setBumpType("stagger") end
        if attacker.setBumpFall then attacker:setBumpFall(false) end
        if attacker.setBumpStaggered then attacker:setBumpStaggered(true) end
        return true
    end
    if PNC.CombatZombieReaction and PNC.CombatZombieReaction.Start then
        return PNC.CombatZombieReaction.Start(zombie, attacker, {
            kind = "grounded_counter_stagger",
            stagger = true,
            knockdown = false,
            hitForce = 0.82,
            durationMs = 240,
            pushDurationMs = 150,
            pushDistance = 0.28,
            stepDistance = 0.06,
        }) == true
    end
    return false
end
