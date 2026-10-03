local ZombieAggro = require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Path"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Pursuit"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Targets"

local Internal = ZombieAggro.Internal
local Core = Internal.Core
local ZombieReaction = Internal.ZombieReaction
local isForeignOwnedBody = Internal.isForeignOwnedBody
local isMultiplayerServer = Internal.isMultiplayerServer
local setNoLungeAttack = Internal.setNoLungeAttack
local logPursuitDiagnostic = Internal.logPursuitDiagnostic
local actionStateName = Internal.actionStateName
local clearMPTargetDirective = Internal.clearMPTargetDirective
local pursueNPCRecord = Internal.pursueNPCRecord
local acquireNearestTarget = Internal.acquireNearestTarget
local incrementDiagnostic = Internal.incrementDiagnostic

local function processZombie(zombie, now)
    local target
    local record
    local npcBody
    local hitSettling
    local zombieId
    local biteEntry
    if isForeignOwnedBody(zombie) then
        return
    end
    if Internal.ShouldYieldToPursuitOwner
        and Internal.ShouldYieldToPursuitOwner(zombie, "ProjectHoomans", now)
    then
        return
    end
    if ZombieReaction and ZombieReaction.Pump then
        ZombieReaction.Pump(zombie, now)
    end
    hitSettling = ZombieReaction
        and ZombieReaction.IsEngineHitSettling
        and ZombieReaction.IsEngineHitSettling(zombie, now)
        or false
    -- Keep target selection and path goals current during the brief hit
    -- animation. The animation may pause locomotion; it must not drop aggro.
    if ZombieAggro.UpdateBiteState(zombie, now) then
        -- Bite flow owns the zombie while the bite is active.
        zombieId = Internal.ensureZombieID(zombie)
        biteEntry = ZombieAggro.BiteInternal
            and ZombieAggro.BiteInternal.GetBiteEntry
            and ZombieAggro.BiteInternal.GetBiteEntry(zombieId)
        logPursuitDiagnostic(
            zombie,
            biteEntry and biteEntry.npcId or nil,
            "server_combat",
            "bite_state_owns_zombie",
            "action=" .. actionStateName(zombie)
                .. " phase=" .. tostring(biteEntry and biteEntry.phase)
                .. " damageApplied="
                .. tostring(biteEntry and biteEntry.appliedDamage == true),
            now
        )
        return
    end

    -- Keep a valid NPC lease through player proximity. Reacquisition below
    -- falls back to players only after this NPC target is no longer eligible.
    record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
    if pursueNPCRecord(zombie, record, npcBody, now, hitSettling) then
        return
    end

    target = zombie.getTarget and zombie:getTarget() or nil
    if Core.IsManagedNPCBody(target) then
        Internal.forceAggro(zombie, target)
        record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
        pursueNPCRecord(zombie, record, npcBody, now, hitSettling)
        return
    end
    if Internal.isCloseLivePlayerTarget(zombie, target) then
        record, npcBody = acquireNearestTarget(zombie)
        if not pursueNPCRecord(zombie, record, npcBody, now, hitSettling) then
            setNoLungeAttack(zombie, false)
            clearMPTargetDirective(zombie, now)
        end
        return
    end
    record, npcBody = acquireNearestTarget(zombie)
    if isMultiplayerServer() then
        -- Clear a stale directive when this zombie no longer has an eligible
        -- NPC target; active directives are refreshed by pursueForcedTarget.
        if not record or not npcBody then
            clearMPTargetDirective(zombie, now)
        end
    end
end

function ZombieAggro.Pump(now)
    if not Core.IsAuthority() then
        return
    end

    if ZombieAggro.PumpBiteRecovery then
        ZombieAggro.PumpBiteRecovery(now)
    end

    if ZombieAggro.RefreshActiveSet then
        ZombieAggro.RefreshActiveSet(now, false)
    end
    if ZombieAggro.PumpActiveSet then
        return ZombieAggro.PumpActiveSet(now, processZombie)
    end
    return 0
end

Internal.UpdateProviders = Internal.UpdateProviders or {}
Internal.UpdateProviders.Multiplayer = Multiplayer
Internal.UpdateProviders.isMultiplayerServer = isMultiplayerServer
Internal.UpdateProviders.incrementDiagnostic = incrementDiagnostic
Internal.UpdateProviders.logPursuitDiagnostic = logPursuitDiagnostic
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Multiplayer"

return ZombieAggro
