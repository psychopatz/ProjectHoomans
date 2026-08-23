PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const
local Stealth = PNC.Stealth

function Perception.ResolveCompanionTarget(record)
    local owner
    local ownerThreatZombie
    local npcTarget
    local zombieTarget
    local hostileToOwnerNPC
    local hostileToOwnerZombie
    local immediateZombie
    local defenseRadius = Internal.GetCompanionDefenseRadius()

    local recentAttacker = Perception.ResolveRecentAttacker(
        record,
        Core.Now and Core.Now() or 0
    )
    if recentAttacker then return recentAttacker end
    owner = Core.ResolvePlayerByOnlineID(record.ownerOnlineID) or Core.ResolvePlayerByUsername(record.ownerUsername)
    immediateZombie = Perception.FindImmediateZombieThreat(record)
    if immediateZombie then
        return immediateZombie
    end
    if owner and (not record.hostility or record.hostility.attackZombies ~= false) then
        ownerThreatZombie = Internal.FindZombieTargetingOwner(
            record,
            owner,
            defenseRadius
        )
        if ownerThreatZombie then
            return ownerThreatZombie
        end
    end

    if Stealth and Stealth.ShouldSuppressCompanionCombat and Stealth.ShouldSuppressCompanionCombat(record) then
        record.runtime = record.runtime or {}
        record.runtime.targetKind = "none"
        record.runtime.combatBlockReason = "follow_stealth_hidden"
        return nil
    end

    if not record.hostility or record.hostility.attackNPCs ~= false then
        npcTarget = Perception.FindNearestEnemyNPC(record, defenseRadius)
    end
    if not record.hostility or record.hostility.attackZombies ~= false then
        zombieTarget = Perception.FindBestEnemyZombie(record, defenseRadius)
    end
    if npcTarget or zombieTarget then
        return Internal.PickNearest(npcTarget, zombieTarget)
    end

    if owner then
        hostileToOwnerNPC = (not record.hostility or record.hostility.attackNPCs ~= false) and Perception.FindNearestEnemyNPC({
            id = record.id,
            faction = record.faction,
            x = owner:getX(),
            y = owner:getY(),
            z = owner:getZ(),
            hostility = record.hostility,
        }, defenseRadius)
        hostileToOwnerZombie = (not record.hostility or record.hostility.attackZombies ~= false) and Perception.FindBestEnemyZombie({
            id = record.id,
            faction = record.faction,
            x = owner:getX(),
            y = owner:getY(),
            z = owner:getZ(),
            hostility = record.hostility,
        }, defenseRadius)
        return Internal.PickNearest(hostileToOwnerNPC, hostileToOwnerZombie)
    end

    return nil
end

-- Companion orders are protective, not an invitation to hunt everything in
-- perception range. Direct attackers always win; otherwise companions defend
-- the owner, and only broaden target selection while the owner is fighting.
function Perception.ResolveCompanionProtectionTarget(record, ownerEngaged)
    local now = Core.Now and Core.Now() or 0
    local immediate = Perception.ResolveRecentAttacker(record, now)
    local owner
    local ownerThreat
    if immediate then
        immediate.immediateSelfDefense = true
        return immediate
    end
    immediate = Perception.FindImmediateZombieThreat(record)
    if immediate then
        immediate.immediateSelfDefense = true
        return immediate
    end
    owner = Core.ResolvePlayerByOnlineID(record.ownerOnlineID)
        or Core.ResolvePlayerByUsername(record.ownerUsername)
    if owner and (not record.hostility
        or record.hostility.attackZombies ~= false)
    then
        ownerThreat = Internal.FindZombieTargetingOwner(
            record,
            owner,
            Internal.GetCompanionDefenseRadius()
        )
        if ownerThreat then return ownerThreat end
    end
    if ownerEngaged == true then
        return Perception.ResolveCompanionTarget(record)
    end
    return nil
end

function Perception.ResolveHostileTarget(record)
    local hostileConfig = record and record.hostility or {}
    local organizationalFactionID = PNC.Factions
        and PNC.Factions.GetOrganizationalFactionID
        and PNC.Factions.GetOrganizationalFactionID(record)
        or nil
    local npcTarget = nil
    local playerTarget = nil
    local zombieTarget = nil
    local immediateThreat = Perception.ResolveRecentAttacker(
        record,
        Core.Now and Core.Now() or 0
    ) or Perception.FindImmediateZombieThreat(record)

    if immediateThreat then return immediateThreat end

    if hostileConfig.attackNPCs ~= false then
        npcTarget = Perception.FindNearestEnemyNPC(record, 12)
    end
    -- Organizational hostility is resolved dynamically for each player by
    -- CanNPCTargetPlayer(). Do not let a cached compatibility flag prevent
    -- that authoritative check after a transfer or treaty change.
    if organizationalFactionID
        or hostileConfig.attackPlayers ~= false
    then
        playerTarget = Perception.FindNearestEnemyPlayer(record, 12)
    end
    if hostileConfig.attackZombies ~= false then
        zombieTarget = Perception.FindBestEnemyZombie(record, Const.ZOMBIE_TARGET_RADIUS)
    end

    return Internal.PickNearest(Internal.PickNearest(npcTarget, playerTarget), zombieTarget)
end

function Perception.ResolveRoamingTarget(record, radius)
    local hostility = record and record.hostility or {}
    local organizationalFactionID = PNC.Factions
        and PNC.Factions.GetOrganizationalFactionID
        and PNC.Factions.GetOrganizationalFactionID(record)
        or nil
    local searchRadius = math.max(1, tonumber(radius) or Const.ROAM_TARGET_RADIUS or 12)
    local npcTarget = nil
    local playerTarget = nil
    local zombieTarget = nil
    local immediateThreat = Perception.ResolveRecentAttacker(
        record,
        Core.Now and Core.Now() or 0
    ) or Perception.FindImmediateZombieThreat(record, searchRadius)

    if immediateThreat then return immediateThreat end

    if hostility.attackNPCs ~= false then
        npcTarget = Perception.FindNearestEnemyNPC(record, searchRadius)
    end
    if organizationalFactionID
        or hostility.attackPlayers == true
    then
        playerTarget = Perception.FindNearestEnemyPlayer(record, searchRadius)
    end
    if hostility.attackZombies ~= false then
        zombieTarget = Perception.FindBestEnemyZombie(record, searchRadius)
    end

    return Internal.PickNearest(Internal.PickNearest(npcTarget, playerTarget), zombieTarget)
end
