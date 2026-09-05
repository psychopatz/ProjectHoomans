local Integration = PNC and PNC.ProfilerIntegration or nil
if not Integration or Integration._loadingProviders ~= true then
    return Integration
end

local Internal = Integration and Integration.Internal or nil
if type(Internal) ~= "table" then return Integration end

function Integration.InstallServer()
    local Profiler = Internal and Internal.Profiler or nil
    if not Profiler
        or type(Profiler.IsSectionEnabled) ~= "function"
        or not Profiler.IsSectionEnabled("performance")
    then
        return false
    end
    if Integration.serverInstalled then return false end
    local function wrap(owner, key, metric)
        Internal.Wrap(owner, key, "ProjectHoomans." .. metric)
    end
    wrap(PNC.WorldDirector, "Pump", "Server.Update.Director")
    wrap(PNC.PopulationDirector, "Pump", "Server.Update.Director.Population")
    wrap(PNC.PersistenceCoordinator, "Commit", "Persistence.Commit")
    wrap(PNC.PlayerCharacters, "Save", "Persistence.PlayerCharacters")
    wrap(PNC.NPCKnowledge, "Save", "Persistence.NPCKnowledge")
    wrap(PNC.Factions, "Save", "Persistence.Factions")
    wrap(PNC.Communities, "Save", "Persistence.Communities")
    wrap(PNC.ColonyStorageRepository, "Save", "Persistence.ColonyStorage")
    wrap(PNC.AbstractWorldStore, "Save", "Persistence.AbstractWorld")
    wrap(PNC.WorldDiscovery, "Save", "Persistence.WorldDiscovery")
    wrap(PNC.Conversation and PNC.Conversation.History, "Save",
        "Persistence.ConversationHistory")
    wrap(PNC.Registry, "FlushDirty", "Persistence.NPCRecords")
    wrap(PNC.PlayerCharacterLifecycle, "Pump",
        "Server.Update.PlayerCharacters")
    wrap(PNC.FactionBehavior, "PumpReconciliation",
        "Server.Update.FactionReconciliation")
    wrap(PNC.FactionIncidentService, "PumpRuntime",
        "Server.Update.FactionIncidents")
    wrap(PNC.FactionTolls, "Pump", "Server.Update.FactionTolls")
    wrap(PNC.NeedsScheduler, "Pump", "Server.Update.Needs")
    wrap(PNC.EnginePathPlanner, "PumpServerFrame",
        "Server.Update.EnginePathPlanner")
    wrap(PNC.BodyLifecycle, "PumpStartupBodyCleanup",
        "Server.Update.BodyCleanup")
    wrap(PNC.BodyLifecycle, "AuditLoadedBodies", "Server.Update.BodyAudit")
    wrap(PNC.CompanionVehicle, "AuditLoadedReservations",
        "Server.Update.VehicleAudit")
    wrap(PNC.Presence, "RefreshMaterializationCandidates",
        "Server.Update.MaterializationCandidates")
    wrap(PNC.Presence, "Materialize", "Server.Update.NPC.Materialize")
    wrap(PNC.Network, "RefreshInterestSets",
        "Server.Update.Network.RefreshInterestSets")
    wrap(PNC.ZombieAggro, "Pump", "Server.Update.ZombieAggro")
    wrap(PNC.SocialEncounterTracker, "Pump",
        "Server.Update.SocialEncounters")
    wrap(PNC.Presence, "Reconcile", "Server.Update.NPC.Presence")
    wrap(PNC.Health, "Update", "Server.Update.NPC.Health")
    wrap(PNC.Stamina, "Update", "Server.Update.NPC.Stamina")
    wrap(PNC.Animation, "SyncLocomotion", "Server.Update.NPC.Animation")
    wrap(PNC.SpatialIndex, "UpdateNPC", "Server.Update.NPC.SpatialUpdate")
    wrap(PNC.Network, "QueuePeriodicRoster",
        "Server.Update.NPC.QueueRoster")
    wrap(PNC.Scheduler, "Schedule", "Server.Update.NPC.Schedule")
    local networkInternal = PNC.Network and PNC.Network.Internal or nil
    wrap(networkInternal, "QueueBroadcastRoster",
        "Network.BroadcastRecord.QueueRoster")
    wrap(networkInternal, "CollectRecordRecipients",
        "Network.BroadcastRecord.FindRecipients")
    wrap(networkInternal, "BuildRecordPayload",
        "Network.BroadcastRecord.BuildPayload")
    wrap(networkInternal, "SendRecordPayload",
        "Network.BroadcastRecord.SendPayload")
    Internal.Profiler.RegisterSampler("ProjectHoomans.server", function(api)
        local groups = PNC.AbstractGroups and PNC.AbstractGroups.List
            and PNC.AbstractGroups.List() or {}
        local sites = PNC.Communities and PNC.Communities.ListSites
            and PNC.Communities.ListSites() or {}
        local dirty = Internal.CountMap(PNC.Registry and PNC.Registry.DirtyByID)
        local blockedPaths = 0
        local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
        for _, record in pairs(PNC.Registry and PNC.Registry.Data or {}) do
            local lane = record and record.runtime
                and record.runtime.pathing or nil
            if lane and lane.nativeBlockedGoalX ~= nil
                and now < (tonumber(lane.nativeBlockedUntil) or 0)
            then
                blockedPaths = blockedPaths + 1
            end
        end
        api.SetGauge("ProjectHoomans.Groups.Total", #groups)
        api.SetGauge("ProjectHoomans.Settlements.Total", #sites)
        api.SetGauge("ProjectHoomans.Persistence.DirtyRecords", dirty)
        api.SetGauge("ProjectHoomans.Pathing.BlockedGoals", blockedPaths)
    end)
    Integration.serverInstalled = true
    return true
end

function Integration.WrapServerTick(callback)
    local Profiler = Internal and Internal.Profiler or nil
    if type(callback) ~= "function" then return callback end
    if not Profiler
        or type(Profiler.IsSectionEnabled) ~= "function"
        or not Profiler.IsSectionEnabled("performance")
    then
        return callback
    end
    local wrapped = Internal.Profiler.Wrap(
        "ProjectHoomans.Server.Update",
        callback,
        { protectErrors = true }
    )
    Internal.Profiler.RegisterStopHook("ProjectHoomans.serverTick", function()
        if Events and Events.OnTick and Events.OnTick.Remove then
            Events.OnTick.Remove(wrapped)
            Events.OnTick.Add(callback)
        end
        if PNC.Server then PNC.Server.OnTick = callback end
    end)
    return wrapped
end

return Integration
