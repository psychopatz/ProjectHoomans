local ZombieAggro = require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Path"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Pursuit"

local Internal = ZombieAggro.Internal
local Core = Internal.Core
local Const = Internal.Const
local Settings = Internal.Settings
local Stealth = Internal.Stealth
local setNoLungeAttack = Internal.setNoLungeAttack
local incrementDiagnostic = Internal.incrementDiagnostic
local logPursuitDiagnostic = Internal.logPursuitDiagnostic
local isMultiplayerServer = Internal.isMultiplayerServer
local suppressForStealth = Internal.suppressForStealth
local pursueForcedTarget = Internal.pursueForcedTarget
local clearMPTargetDirective = Internal.clearMPTargetDirective

local function acquireNearestTarget(zombie)
    local nearestRecord
    local nearestBody
    local nearestDistSq
    local nearestPlayer
    local nearestPlayerDistSq
    nearestRecord, nearestBody, nearestDistSq = Internal.findNearestLiveNPC(zombie, Const.ZOMBIE_AGGRO_RADIUS)
    nearestPlayer, nearestPlayerDistSq = Internal.findNearestLivePlayer(
        zombie,
        Const.ZOMBIE_AGGRO_RADIUS
    )
    if nearestPlayer
        and not Internal.shouldPreferNPCOverPlayer(
            nearestDistSq,
            nearestPlayerDistSq
        )
    then
        logPursuitDiagnostic(
            zombie, nil, "server_target", "player_preferred",
            "npcDistanceSq=" .. tostring(nearestDistSq)
                .. " playerDistanceSq=" .. tostring(nearestPlayerDistSq),
            Core.Now()
        )
        setNoLungeAttack(zombie, false)
        return nil, nil
    end
    if nearestRecord and nearestBody then
        logPursuitDiagnostic(
            zombie, nearestRecord.id, "server_target", "npc_selected",
            "npcDistanceSq=" .. tostring(nearestDistSq)
                .. " playerDistanceSq=" .. tostring(nearestPlayerDistSq),
            Core.Now()
        )
        incrementDiagnostic("ZombieAggro.NPCTargetSelected")
        Internal.forceAggro(zombie, nearestBody)
        if isMultiplayerServer() then
            setNoLungeAttack(zombie, true)
        else
            setNoLungeAttack(
                zombie,
                math.sqrt(nearestDistSq) <= Const.ZOMBIE_AGGRO_KEEP_RADIUS
            )
        end
        return nearestRecord, nearestBody
    end
    logPursuitDiagnostic(
        zombie, nil, "server_target", "no_npc_selected",
        "npcDistanceSq=" .. tostring(nearestDistSq)
            .. " playerDistanceSq=" .. tostring(nearestPlayerDistSq),
        Core.Now()
    )
    setNoLungeAttack(zombie, false)
    return nil, nil
end

local function pursueNPCRecord(zombie, record, npcBody, now, hitSettling)
    local lease
    if not record or not npcBody then
        clearMPTargetDirective(zombie, now)
        return false
    end
    lease = Internal.GetPursuitLease
        and Internal.GetPursuitLease(zombie, now)
        or nil
    if lease
        and Internal.ShouldYieldToPursuitOwner
        and Internal.ShouldYieldToPursuitOwner(
            zombie, "ProjectHoomans", now, 100
        )
    then
        logPursuitDiagnostic(
            zombie,
            record.id,
            "server_target",
            "foreign_pursuit_owner",
            "owner=" .. tostring(lease.owner)
                .. " provider=" .. tostring(lease.provider),
            now
        )
        return false
    end
    if not Settings.CanZombieTargetRecord(record) then
        Internal.clearZombieTarget(zombie)
        clearMPTargetDirective(zombie, now)
        ZombieAggro.ClearBiteEntryForZombie(zombie, "target_protected")
        return false
    end
    if Stealth and Stealth.ShouldSuppressZombieAggro and Stealth.ShouldSuppressZombieAggro(record) then
        suppressForStealth(zombie, record)
        clearMPTargetDirective(zombie, now)
    else
        pursueForcedTarget(zombie, npcBody, record, now, hitSettling)
    end
    return true
end


Internal.acquireNearestTarget = acquireNearestTarget
Internal.pursueNPCRecord = pursueNPCRecord
return ZombieAggro
