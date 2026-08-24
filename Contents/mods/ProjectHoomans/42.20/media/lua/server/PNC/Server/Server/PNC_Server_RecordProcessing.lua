if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.Server.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local Spatial = PNC.SpatialIndex
local Presence = PNC.Presence
local Health = PNC.Health
local Behavior = PNC.BehaviorSystem
local PathService = PNC.PathService
local Scheduler = PNC.Scheduler
local SimulationClock = PNC.SimulationClock
local SimulationLOD = PNC.SimulationLOD
local Network = PNC.Network
local Stamina = PNC.Stamina
local Animation = PNC.Animation
local ConversationScene = PNC.ConversationScene
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics

function H.GetSyncInterval(record)
    local runtime = record and record.runtime or nil
    if record and record.presenceState ~= Const.PRESENCE_LIVE then
        return 500
    end
    if runtime and runtime.attackAction then
        return 75
    end
    if runtime and runtime.target then
        return 100
    end
    if runtime and runtime.pathing and (runtime.pathing.phase == "requested" or runtime.pathing.phase == "active") then
        return 150
    end
    if runtime and runtime.pathing and Core.Now() < ((tonumber(runtime.pathing.visualMovingUntil) or 0) + 250) then
        return 150
    end
    return 500
end

function H.ProcessRecord(record, now)
    local zombie = Registry.GetLiveZombie(record.id)
    local forceSyncEvent
    local decisionInterval
    local pathDue = false
    local forcePresence = record.runtime
        and record.runtime.forcePresenceCheck == true
    if ScalingDiagnostics
        and zombie
        and record.presenceState == Const.PRESENCE_ABSTRACT
    then
        ScalingDiagnostics.Increment(
            "LiveAbstract.AbstractBodyUpdates"
        )
    end
    if zombie and Registry.RefreshLivePosition then
        Registry.RefreshLivePosition(record, zombie, false)
    end
    if ConversationScene and ConversationScene.Pump then
        ConversationScene.Pump(record, zombie, now)
    end
    if not SimulationClock
        or SimulationClock.IsDue(
            record,
            "presence",
            now,
            SimulationLOD and SimulationLOD.GetPresenceInterval(record) or 500,
            forcePresence
        )
    then
        Presence.Reconcile(record)
    end
    zombie = Registry.GetLiveZombie(record.id)
    if not SimulationClock
        or SimulationClock.IsDue(
            record,
            "vitals",
            now,
            SimulationLOD and SimulationLOD.GetVitalsInterval(record) or 250,
            false
        )
    then
        Health.Update(record, zombie, now)
        if Stamina and Stamina.Update then
            Stamina.Update(record, zombie, now)
        end
    end

    if record.alive == false then
        if not (record.runtime and record.runtime.deathRetired)
            and record.lastSyncAt ~= record.presenceRevision
        then
            Network.BroadcastRemoval(record.id, "death")
            record.lastSyncAt = record.presenceRevision
        end
        if Spatial and Spatial.RemoveNPC then
            Spatial.RemoveNPC(record.id)
        end
        return
    end

    if now >= (tonumber(record.nextThinkAt) or 0) then
        record.runtime = record.runtime or {}
        record.runtime.abstractStepElapsedMs = math.max(
            0,
            now - (tonumber(record.lastThinkAt) or now)
        )
        Behavior.Tick(record, zombie, now)
        -- A behavior may abstract a boarding companion or materialize a
        -- disembarking one. Refresh the lease-bound body before any pathing or
        -- animation work so this tick never pumps a removed IsoZombie (and a
        -- newly materialized passenger is immediately eligible for setup).
        zombie = Registry.GetLiveZombie(record.id)
        record.lastThinkAt = now
        decisionInterval = SimulationLOD
            and SimulationLOD.GetDecisionInterval(record)
            or Scheduler.GetCadence(record)
        record.nextThinkAt = now + decisionInterval
    end

    pathDue = zombie and record.alive ~= false and (
        not SimulationClock
        or SimulationClock.IsDue(
            record,
            "path",
            now,
            SimulationLOD and SimulationLOD.GetPathInterval(record) or 100,
            false
        )
    )
    if pathDue then
        PathService.Pump(record, zombie)
        if Registry.RefreshLivePosition then
            Registry.RefreshLivePosition(record, zombie, false)
        end
    end

    forceSyncEvent = record.runtime and record.runtime.forceSyncEvent or nil
    if forceSyncEvent then
        record.runtime.forceSyncEvent = nil
        Network.BroadcastRecord(record, forceSyncEvent)
        record.lastSyncAt = now
    elseif (now - (tonumber(record.lastSyncAt) or 0)) >= H.GetSyncInterval(record) then
        Network.BroadcastRecord(record, "tick")
        record.lastSyncAt = now
    end

    if zombie and pathDue and Animation and Animation.SyncLocomotion then
        Animation.SyncLocomotion(zombie, record)
    end
    if Spatial and Spatial.UpdateNPC then
        Spatial.UpdateNPC(record)
    end
    if Network and Network.QueuePeriodicRoster then
        Network.QueuePeriodicRoster(record, now)
    end
    if Scheduler and Scheduler.Schedule then
        Scheduler.Schedule(record, now + Scheduler.GetCadence(record))
    end
end
