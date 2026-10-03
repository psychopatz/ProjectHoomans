local ZombieAggro = PNC.ZombieAggro
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Settings = PNC.Sandbox
local Internal = ZombieAggro.Internal
local PURSUIT_OWNER = "ProjectHoomans"
local isForeignOwnedBody = Internal.isForeignOwnedBody

function Internal.canZombieAttack(zombie, now)
    local modData = Internal.getZombieModData(zombie)
    local lastAttackAt
    if not modData then
        return false
    end
    lastAttackAt = tonumber(modData.PNC_LastAttackAt or 0) or 0
    if (now - lastAttackAt) < Const.ZOMBIE_ATTACK_COOLDOWN_MS then
        return false
    end
    modData.PNC_LastAttackAt = now
    return true
end

function Internal.forceAggro(zombie, npcBody)
    local modData
    local record
    local npcId
    local now
    if not zombie or not npcBody or isForeignOwnedBody(zombie) then
        return
    end
    now = Core.Now()
    if Internal.ShouldYieldToPursuitOwner(zombie, PURSUIT_OWNER, now) then
        return false
    end
    modData = Internal.getZombieModData(zombie)
    record = Registry.FindRecordByZombie(npcBody)
    npcId = record and record.id or nil
    if record and not Settings.CanZombieTargetRecord(record) then
        Internal.clearZombieTarget(zombie)
        return false
    end
    if modData then
        modData.PNC_AggroNPCId = npcId
        modData.PNC_AggroNPCUntil = npcId
            and (now + Const.ZOMBIE_NPC_AGGRO_LEASE_MS) or nil
    end
    if npcId and not Internal.AcquirePursuitLease(
        zombie,
        PURSUIT_OWNER,
        "Hoomans",
        npcId,
        now,
        Const.ZOMBIE_NPC_AGGRO_LEASE_MS,
        100,
        "hoomans_npc"
    ) then
        return false
    end
    if npcId and ZombieAggro.Activate then
        ZombieAggro.Activate(
            zombie,
            Core.Now(),
            "forced_aggro",
            Const.ZOMBIE_NPC_AGGRO_LEASE_MS
        )
    end
    -- Preserve the attacker and action-state context installed by
    -- IsoZombie:Hit(). Clearing either during the hit frame prevents vanilla
    -- stagger from entering or exiting correctly.
    if PNC.CombatZombieReaction
        and PNC.CombatZombieReaction.IsEngineHitSettling
        and PNC.CombatZombieReaction.IsEngineHitSettling(zombie)
    then
        return
    end
    if not (isServer and isServer() == true) then
        if zombie.setTarget then
            zombie:setTarget(nil)
        end
        if zombie.setAttackedBy then
            zombie:setAttackedBy(nil)
        end
    end
    return npcId ~= nil
end
