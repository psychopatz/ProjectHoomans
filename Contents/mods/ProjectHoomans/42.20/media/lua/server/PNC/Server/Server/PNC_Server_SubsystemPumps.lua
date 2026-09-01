if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.Server.Internal
local Const = PNC.Const
local Registry = PNC.Registry
local Spatial = PNC.SpatialIndex
local Presence = PNC.Presence
local BodyLifecycle = PNC.BodyLifecycle
local PlayerCharacterLifecycle = PNC.PlayerCharacterLifecycle
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local Network = PNC.Network
local ZombieAggro = PNC.ZombieAggro

H.LastLivePositionSafetyRefreshAt =
    tonumber(H.LastLivePositionSafetyRefreshAt) or 0

function H.PrepareTick(now)
    if ScalingDiagnostics then
        ScalingDiagnostics.BeginFrame()
    end
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
    if PNC.LivingRoomService and PNC.LivingRoomService.Pump then
        PNC.LivingRoomService.Pump(now)
    end
    if PNC.ProvisionScheduler and PNC.ProvisionScheduler.Pump then
        PNC.ProvisionScheduler.Pump(now)
    end
    if PNC.LumberService and PNC.LumberService.Pump then
        PNC.LumberService.Pump(now)
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
    if now - H.LastLivePositionSafetyRefreshAt
        >= (tonumber(Const.LIVE_POSITION_SAFETY_REFRESH_MS) or 1000)
    then
        Registry.RefreshLivePositions(false)
        H.LastLivePositionSafetyRefreshAt = now
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
    return PNC.Scheduler.PopDue(Registry.Data, now)
end

function H.FinishTick(now)
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
    if PNC.SocialGreeting and PNC.SocialGreeting.Pump then
        PNC.SocialGreeting.Pump(
            PNC.SocialEventHooks and PNC.SocialEventHooks.WorldAgeHours
                and PNC.SocialEventHooks.WorldAgeHours()
                or nil
        )
    end
end
