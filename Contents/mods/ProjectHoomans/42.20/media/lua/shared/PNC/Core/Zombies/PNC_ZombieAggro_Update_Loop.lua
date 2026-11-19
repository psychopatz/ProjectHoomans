local ZombieAggro = require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Path"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Pursuit"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Targets"

local Internal = ZombieAggro.Internal
local Core = Internal.Core
local Const = Internal.Const
local Registry = Internal.Registry
local ZombieReaction = Internal.ZombieReaction
local isForeignOwnedBody = Internal.isForeignOwnedBody
local isMultiplayerServer = Internal.isMultiplayerServer
local setNoLungeAttack = Internal.setNoLungeAttack
local logPursuitDiagnostic = Internal.logPursuitDiagnostic
local isPursuitAuditEnabled = Internal.isPursuitAuditEnabled
local actionStateName = Internal.actionStateName
local clearMPTargetDirective = Internal.clearMPTargetDirective
local pursueNPCRecord = Internal.pursueNPCRecord
local acquireNearestTarget = Internal.acquireNearestTarget
local incrementDiagnostic = Internal.incrementDiagnostic

local function hasActiveWork()
    local liveByID = Registry and Registry.LiveByID or nil
    if not liveByID then
        return true
    end
    for id, body in pairs(liveByID) do
        if id ~= nil and body ~= nil then
            return true
        end
    end
    local activeSet = ZombieAggro.ActiveSet
    if activeSet and activeSet.order and #activeSet.order > 0 then
        return true
    end
    local bites = ZombieAggro.State and ZombieAggro.State.bites or nil
    if bites then
        for _, _ in pairs(bites) do
            return true
        end
    end
    return false
end

local function closeOrHitCooldown(zombie, npcBody, hitSettling)
    if hitSettling == true or not npcBody then
        return 0
    end
    if Core and Core.DistanceSq
        and zombie.getX and zombie.getY
        and npcBody.getX and npcBody.getY
    then
        local biteDist = Const and tonumber(Const.ZOMBIE_BITE_DISTANCE) or 1.2
        local closeRange = biteDist + 1.5
        if Core.DistanceSq(
            zombie:getX(),
            zombie:getY(),
            npcBody:getX(),
            npcBody:getY()
        ) <= (closeRange * closeRange) then
            return 0
        end
    end
    return (Const and tonumber(Const.ZOMBIE_AGGRO_PURSUIT_INTERVAL_MS)) or 150
end

local function processZombie(zombie, now, foreignChecked)
    local target
    local record
    local npcBody
    local hitSettling
    local zombieId
    local biteEntry
    local nativePlayerOwned
    local nativePlayerTarget
    local nativePlayerSource
    local nativePlayerAction
    local idleInterval = (Const and tonumber(Const.ZOMBIE_AGGRO_IDLE_INTERVAL_MS)) or 250
    if foreignChecked ~= true and isForeignOwnedBody(zombie) then
        return idleInterval, nil
    end
    if Internal.ShouldYieldToPursuitOwner
        and Internal.ShouldYieldToPursuitOwner(zombie, "ProjectHoomans", now)
    then
        return idleInterval, nil
    end
    if ZombieReaction and ZombieReaction.Pump then
        ZombieReaction.Pump(zombie, now)
    end
    hitSettling = ZombieReaction
        and ZombieReaction.IsEngineHitSettling
        and ZombieReaction.IsEngineHitSettling(zombie, now)
        or false

    -- A vanilla player target must win before Hoomans renews the NPC lease,
    -- clears the native target, or reapplies NoLungeAttack. This is the
    -- singleplayer race fix and is also used by the MP server-side authority
    -- when the native target is visible there.
    if Internal.ShouldYieldToNativePlayerAttack then
        nativePlayerOwned, nativePlayerTarget, nativePlayerSource,
            nativePlayerAction = Internal.ShouldYieldToNativePlayerAttack(
                zombie, now
            )
    end
    if nativePlayerOwned
        and ZombieAggro.BiteInternal
        and ZombieAggro.BiteInternal.GetBiteEntry
    then
        zombieId = Internal.ensureZombieID(zombie)
        biteEntry = ZombieAggro.BiteInternal.GetBiteEntry(zombieId)
        if biteEntry
            and biteEntry.phase == "windup"
            and biteEntry.appliedDamage ~= true
            and ZombieAggro.BiteInternal.CancelBeforeImpact
        then
            ZombieAggro.BiteInternal.CancelBeforeImpact(
                zombieId, "native_player_handoff", now
            )
            biteEntry = nil
        end
    end
    -- Keep target selection and path goals current during the brief hit
    -- animation. The animation may pause locomotion; it must not drop aggro.
    if ZombieAggro.UpdateBiteState(zombie, now) then
        -- Bite flow owns the zombie while the bite is active.
        zombieId = Internal.ensureZombieID(zombie)
        biteEntry = ZombieAggro.BiteInternal
            and ZombieAggro.BiteInternal.GetBiteEntry
            and ZombieAggro.BiteInternal.GetBiteEntry(zombieId)
        if isPursuitAuditEnabled() then
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
        end
        local biteNpcBody = biteEntry and biteEntry.npcId
            and Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(biteEntry.npcId)
            or nil
        return 0, biteNpcBody
    end

    if nativePlayerOwned then
        Internal.BeginNativePlayerHandoff(
            zombie,
            nativePlayerTarget,
            now,
            "player_target_" .. tostring(nativePlayerSource or "handoff")
        )
        if isPursuitAuditEnabled() then
            logPursuitDiagnostic(
                zombie,
                nil,
                "compatibility",
                "native_player_handoff",
                "action=" .. tostring(nativePlayerAction)
                    .. " source=" .. tostring(nativePlayerSource),
                now
            )
        end
        return 0, nil
    end

    -- A foreign provider may own the native target without publishing a
    -- Hoomans lease. Preserve that provider's target/path/lunge state and let
    -- its own callback finish the handoff.
    if Internal.GetNativeTargetOwner then
        local nativeOwner = Internal.GetNativeTargetOwner(zombie)
        if nativeOwner and nativeOwner ~= "ProjectHoomans" then
            if isPursuitAuditEnabled() then
                logPursuitDiagnostic(
                    zombie,
                    nil,
                    "compatibility",
                    "native_control_yield",
                    "owner=" .. tostring(nativeOwner),
                    now
                )
            end
            return idleInterval, nil
        end
    end

    -- Keep a valid NPC lease through player proximity. Reacquisition below
    -- falls back to players only after this NPC target is no longer eligible.
    record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
    if pursueNPCRecord(zombie, record, npcBody, now, hitSettling) then
        return closeOrHitCooldown(zombie, npcBody, hitSettling), npcBody
    end

    target = zombie.getTarget and zombie:getTarget() or nil
    if Core.IsManagedNPCBody(target) then
        Internal.forceAggro(zombie, target)
        record, npcBody = Internal.getForcedNPCBodyTarget(zombie, now)
        if pursueNPCRecord(zombie, record, npcBody, now, hitSettling) then
            return closeOrHitCooldown(zombie, npcBody, hitSettling), npcBody
        end
        return idleInterval, nil
    end
    if Internal.isCloseLivePlayerTarget(zombie, target) then
        record, npcBody = acquireNearestTarget(zombie)
        if not pursueNPCRecord(zombie, record, npcBody, now, hitSettling) then
            setNoLungeAttack(zombie, false)
            clearMPTargetDirective(zombie, now)
            return idleInterval, nil
        end
        return closeOrHitCooldown(zombie, npcBody, hitSettling), npcBody
    end
    record, npcBody = acquireNearestTarget(zombie)
    if isMultiplayerServer() then
        -- Clear a stale directive when this zombie no longer has an eligible
        -- NPC target; active directives are refreshed by pursueForcedTarget.
        if not record or not npcBody then
            clearMPTargetDirective(zombie, now)
        end
    end
    if record and npcBody then
        return 0, npcBody
    end
    return idleInterval, nil
end

function ZombieAggro.Pump(now)
    if not Core.IsAuthority() then
        return 0
    end
    if not hasActiveWork() then
        return 0
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
Internal.UpdateProviders.isPursuitAuditEnabled = isPursuitAuditEnabled
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Multiplayer"

return ZombieAggro
