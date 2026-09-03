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

local function safeOptional(stage, owner, method, context, ...)
    local callback = owner and owner[method]
    if type(callback) ~= "function" then return true, nil end
    return H.SafePhase(stage, callback, context, ...)
end

function H.PrepareTick(now)
    safeOptional("server_prepare.scaling_begin", ScalingDiagnostics,
        "BeginFrame")
    safeOptional("server_prepare.presence_begin", Presence,
        "BeginServerTick", nil, now)
    safeOptional("server_prepare.registry_load", Registry, "EnsureLoaded")

    local shouldPumpLifecycle = true
    if PlayerCharacterLifecycle
        and type(PlayerCharacterLifecycle.IsDue) == "function"
    then
        local ok, isDue = H.SafePhase("server_prepare.lifecycle_due",
            PlayerCharacterLifecycle.IsDue, nil, now, false)
        shouldPumpLifecycle = ok and isDue ~= false
    end
    if shouldPumpLifecycle then
        safeOptional("server_prepare.lifecycle_pump", PlayerCharacterLifecycle,
            "Pump", nil, now, false)
    end
    safeOptional("server_prepare.faction_reconciliation",
        PNC.FactionBehavior, "PumpReconciliation")
    if PNC.FactionIncidentService
        and type(PNC.FactionIncidentService.PumpRuntime) == "function"
    then
        H.SafePhase("server_prepare.faction_incidents", function()
            local gameTime = getGameTime and getGameTime() or nil
            local worldAge = gameTime and gameTime.getWorldAgeHours
                and gameTime:getWorldAgeHours() or 0
            PNC.FactionIncidentService.PumpRuntime(worldAge)
        end)
    end
    safeOptional("server_prepare.faction_tolls", PNC.FactionTolls, "Pump",
        nil, now)
    safeOptional("server_prepare.needs", PNC.NeedsScheduler, "Pump", nil,
        now)
    safeOptional("server_prepare.living_room", PNC.LivingRoomService, "Pump",
        nil, now)
    safeOptional("server_prepare.provision", PNC.ProvisionScheduler, "Pump",
        nil, now)
    safeOptional("server_prepare.lumber", PNC.LumberService, "Pump", nil,
        now)
    safeOptional("server_prepare.engine_path", PNC.EnginePathPlanner,
        "PumpServerFrame")
    if PNC.Travel and PNC.Travel.Service then
        safeOptional("server_prepare.abstract_travel",
            PNC.Travel.Service, "RefreshAbstractPositions", nil, now, false)
    end
    safeOptional("server_prepare.body_startup_cleanup", BodyLifecycle,
        "PumpStartupBodyCleanup", nil, now, false)
    safeOptional("server_prepare.body_audit", BodyLifecycle,
        "AuditLoadedBodies", nil, now, false)
    safeOptional("server_prepare.vehicle_reservations", PNC.CompanionVehicle,
        "AuditLoadedReservations", nil, now, false)
    if now - H.LastLivePositionSafetyRefreshAt
        >= (tonumber(Const.LIVE_POSITION_SAFETY_REFRESH_MS) or 1000)
    then
        local ok = safeOptional("server_prepare.live_positions", Registry,
            "RefreshLivePositions", nil, false)
        if ok then H.LastLivePositionSafetyRefreshAt = now end
    end
    safeOptional("server_prepare.spatial_rebuild", Spatial, "Rebuild", nil,
        now, false)
    -- Player buckets must be current before the Director evaluates abstract
    -- arrivals or encounter observation safety.
    if PNC.WorldDirector and type(PNC.WorldDirector.Pump) == "function" then
        safeOptional("server_prepare.world_director", PNC.WorldDirector,
            "Pump")
    elseif PNC.MobileGroupDirector
        and type(PNC.MobileGroupDirector.Pump) == "function"
    then
        safeOptional("server_prepare.mobile_group_director",
            PNC.MobileGroupDirector, "Pump", nil, now)
    end
    safeOptional("server_prepare.presence_candidates", Presence,
        "RefreshMaterializationCandidates", nil, now, false)
    safeOptional("server_prepare.network_interest", Network,
        "RefreshInterestSets", nil, now)

    local ok, due = H.SafePhase("server_prepare.scheduler_pop_due",
        PNC.Scheduler and PNC.Scheduler.PopDue, nil, Registry.Data, now)
    if not ok or type(due) ~= "table" then return {} end
    return due
end

function H.FinishTick(now)
    safeOptional("server_finish.network_flush", Network, "FlushRosterDeltas",
        nil, now, false)
    safeOptional("server_finish.zombie_aggro", ZombieAggro, "Pump", nil, now)
    if PNC.SocialEncounterTracker
        and PNC.SocialEncounterTracker.Pump
        and PNC.SocialEventHooks
    then
        H.SafePhase("server_finish.social_encounters", function()
            local worldAge = PNC.SocialEventHooks.WorldAgeHours()
            if PNC.SocialEventHooks.PruneThreatAttributions then
                PNC.SocialEventHooks.PruneThreatAttributions(worldAge)
            end
            PNC.SocialEncounterTracker.Pump(worldAge)
        end)
    end
    if PNC.SocialGreeting and PNC.SocialGreeting.Pump then
        H.SafePhase("server_finish.social_greeting", function()
            local worldAge = PNC.SocialEventHooks
                and PNC.SocialEventHooks.WorldAgeHours
                and PNC.SocialEventHooks.WorldAgeHours() or nil
            PNC.SocialGreeting.Pump(worldAge)
        end)
    end
end
