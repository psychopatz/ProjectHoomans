--[[
    PNC Server Authority
    Owns server-side NPC ticking, presence reconciliation, sync dispatch, and
    debug command routing. Clients never create authoritative NPC records here.
]]

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Teleport = require "PsychopatzCore/World/PsychopatzTeleport"
local CommandRouter = PNC and PNC.ServerCommandRouter or {
    Handle = function() return false end,
}

if PNC and PNC.ServerLegacyDebugCommandHandler
    and PNC.ServerLegacyDebugCommandHandler.ConfigureTeleport
then
    PNC.ServerLegacyDebugCommandHandler.ConfigureTeleport(Teleport)
end

PNC = PNC or {}
PNC.Server = PNC.Server or {}

local Server = PNC.Server
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
local ZombieAggro = PNC.ZombieAggro
local Stamina = PNC.Stamina
local Animation = PNC.Animation
local BodyLifecycle = PNC.BodyLifecycle
local ConversationScene = PNC.ConversationScene
local PlayerCharacterLifecycle = PNC.PlayerCharacterLifecycle
local buildDebugRoster
local lastLivePositionSafetyRefreshAt = 0

local function getSyncInterval(record)
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

local function processRecord(record, now)
    local zombie = Registry.GetLiveZombie(record.id)
    local forceSyncEvent
    local decisionInterval
    local pathDue = false
    local forcePresence = record.runtime
        and record.runtime.forcePresenceCheck == true
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
    elseif (now - (tonumber(record.lastSyncAt) or 0)) >= getSyncInterval(record) then
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

function Server.OnTick()
    local now = Core.Now()
    local due
    local i
    if Presence.BeginServerTick then
        Presence.BeginServerTick(now)
    end
    Registry.EnsureLoaded()
    if PlayerCharacterLifecycle
        and PlayerCharacterLifecycle.Pump
        and (
            not PlayerCharacterLifecycle.IsDue
            or PlayerCharacterLifecycle.IsDue(now, false)
        )
    then
        PlayerCharacterLifecycle.Pump(now, false)
    end
    if PNC.FactionBehavior
        and PNC.FactionBehavior.PumpReconciliation
    then
        PNC.FactionBehavior.PumpReconciliation()
    end
    if PNC.FactionIncidentService
        and PNC.FactionIncidentService.PumpRuntime
    then
        PNC.FactionIncidentService.PumpRuntime(
            getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0
        )
    end
    if PNC.FactionTolls and PNC.FactionTolls.Pump then
        PNC.FactionTolls.Pump(now)
    end
    if PNC.NeedsScheduler and PNC.NeedsScheduler.Pump then
        PNC.NeedsScheduler.Pump(now)
    end
    if PNC.ProvisionScheduler and PNC.ProvisionScheduler.Pump then
        PNC.ProvisionScheduler.Pump(now)
    end
    if PNC.EnginePathPlanner
        and PNC.EnginePathPlanner.PumpServerFrame
    then
        PNC.EnginePathPlanner.PumpServerFrame()
    end
    if PNC.Travel and PNC.Travel.Service
        and PNC.Travel.Service.RefreshAbstractPositions
    then
        PNC.Travel.Service.RefreshAbstractPositions(now, false)
    end
    if BodyLifecycle and BodyLifecycle.PumpStartupBodyCleanup then
        BodyLifecycle.PumpStartupBodyCleanup(now, false)
    end
    if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
        BodyLifecycle.AuditLoadedBodies(now, false)
    end
    if PNC.CompanionVehicle and PNC.CompanionVehicle.AuditLoadedReservations then
        PNC.CompanionVehicle.AuditLoadedReservations(now, false)
    end
    if now - lastLivePositionSafetyRefreshAt
        >= (tonumber(Const.LIVE_POSITION_SAFETY_REFRESH_MS) or 1000)
    then
        Registry.RefreshLivePositions(false)
        lastLivePositionSafetyRefreshAt = now
    end
    Spatial.Rebuild(now, false)
    -- Player buckets must be current before the Director evaluates abstract
    -- arrivals or encounter observation safety.
    if PNC.WorldDirector and PNC.WorldDirector.Pump then
        PNC.WorldDirector.Pump()
    elseif PNC.MobileGroupDirector and PNC.MobileGroupDirector.Pump then
        PNC.MobileGroupDirector.Pump(now)
    end
    if Presence.RefreshMaterializationCandidates then
        Presence.RefreshMaterializationCandidates(now, false)
    end
    if Network.RefreshInterestSets then
        Network.RefreshInterestSets(now)
    end
    due = Scheduler.PopDue(Registry.Data, now)
    for i = 1, #due do
        processRecord(due[i], now)
    end
    if Network.FlushRosterDeltas then
        Network.FlushRosterDeltas(now, false)
    end
    if ZombieAggro and ZombieAggro.Pump then
        ZombieAggro.Pump(now)
    end
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.Pump
        and PNC.SocialEventHooks
    then
        if PNC.SocialEventHooks.PruneThreatAttributions then
            PNC.SocialEventHooks.PruneThreatAttributions(
                PNC.SocialEventHooks.WorldAgeHours()
            )
        end
        PNC.SocialEncounterTracker.Pump(
            PNC.SocialEventHooks.WorldAgeHours()
        )
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= Const.MODULE then
        return
    end

    if CommandRouter.Handle(command, player, args) then
        return
    end
end

local function onServerStarted()
    Registry.Load()
    if PNC.NPCKnowledge and PNC.NPCKnowledge.Load then
        PNC.NPCKnowledge.Load()
    end
    if PNC.Factions and PNC.Factions.Load then
        PNC.Factions.Load()
    end
    if PNC.Communities and PNC.Communities.Load then
        PNC.Communities.Load()
    end
    if PNC.ColonyStorageRepository and PNC.ColonyStorageRepository.Load then
        PNC.ColonyStorageRepository.Load()
    end
    if PNC.AbstractWorldStore and PNC.AbstractWorldStore.Load then
        PNC.AbstractWorldStore.Load()
    end
    if PNC.WorldDirector and PNC.WorldDirector.Initialize then
        PNC.WorldDirector.Initialize(true)
    end
    if PNC.Factions
        and PNC.Factions
            .ReconcileTerritorialLooterFactions
    then
        PNC.Factions.ReconcileTerritorialLooterFactions()
    end
    if PlayerCharacterLifecycle
        and PlayerCharacterLifecycle.OnServerStarted
    then
        PlayerCharacterLifecycle.OnServerStarted(Core.Now())
    end
    if BodyLifecycle and BodyLifecycle.RunStartupBodyCleanupNow then
        BodyLifecycle.RunStartupBodyCleanupNow(
            Core.Now(),
            "server_started",
            true
        )
    end
    if PNC.CompanionVehicle and PNC.CompanionVehicle.AuditLoadedReservations then
        PNC.CompanionVehicle.AuditLoadedReservations(Core.Now(), true)
    end
    if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
        BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
    end
    Core.LogInfo("PNC server started.")
end

local serverTick = Server.OnTick
if PNC.ProfilerIntegration and PNC.ProfilerIntegration.WrapServerTick then
    serverTick = PNC.ProfilerIntegration.WrapServerTick(serverTick)
    Server.OnTick = serverTick
end
Events.OnTick.Add(serverTick)
Events.OnClientCommand.Add(onClientCommand)
Events.OnServerStarted.Add(onServerStarted)
