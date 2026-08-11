-- Project Hoomans owns names and observation points only. PsychopatzCore owns
-- the profiler engine, lifecycle, histories, snapshots, and UI.
PNC = PNC or {}
PNC.ProfilerIntegration = PNC.ProfilerIntegration or {}

local Integration = PNC.ProfilerIntegration
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local BridgeBootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap
local liveControlEnabled = BridgeBootstrap and BridgeBootstrap.IsEnabled
    and BridgeBootstrap.IsEnabled() or false

if not Bootstrap.IsEnabled() and not liveControlEnabled then
    return Integration
end

local Profiler = PsychopatzCore and PsychopatzCore.Profiler

local function wrap(owner, key, metricName)
    if not owner or type(owner[key]) ~= "function" then return false end
    Integration.originals = Integration.originals or {}
    if Integration.originals[metricName] then return false end
    Integration.originals[metricName] = { owner = owner, key = key, callback = owner[key] }
    owner[key] = Profiler.Wrap(metricName, owner[key])
    return true
end

local function countMap(values)
    local count = 0
    for _, _ in pairs(values or {}) do count = count + 1 end
    return count
end

local function installScheduledJobPerformance()
    local scheduler = PNC.Scheduler
    local metricPrefix =
        "ProjectHoomans.Server.Update.Director.ScheduledJobs."
    local function wrapJob(name, job)
        if not job or type(job.callback) ~= "function" then
            return false
        end
        return wrap(
            job,
            "callback",
            metricPrefix .. tostring(name or "Unknown")
        )
    end
    if not scheduler or type(scheduler.RegisterJob) ~= "function" then
        return false
    end
    for name, job in pairs(scheduler.Jobs or {}) do
        wrapJob(name, job)
    end
    Integration.originals = Integration.originals or {}
    local hookMetric = metricPrefix .. "RegisterHook"
    if Integration.originals[hookMetric] then return true end
    local original = scheduler.RegisterJob
    Integration.originals[hookMetric] = {
        owner = scheduler,
        key = "RegisterJob",
        callback = original,
    }
    scheduler.RegisterJob = function(name, interval, callback, options)
        local registered
        local job
        registered, job = original(name, interval, callback, options)
        if registered then
            wrapJob(name, job)
        end
        return registered, job
    end
    return true
end

function Integration.Restore()
    for _, entry in pairs(Integration.originals or {}) do
        if entry.owner and entry.owner[entry.key] then entry.owner[entry.key] = entry.callback end
    end
    Integration.originals = nil
    Integration.serverInstalled = false
end

local ModDataProfiler = nil

local function installSharedPerformance()
Profiler.RegisterNamespace("ProjectHoomans", { displayName = "Project Hoomans" })
Profiler.RegisterStopHook("ProjectHoomans.restore", Integration.Restore)
wrap(PNC.SpatialIndex, "Rebuild", "ProjectHoomans.Server.Update.Spatial.Rebuild")
wrap(PNC.WorldCensus, "Refresh", "ProjectHoomans.WorldCensus.Refresh")
wrap(PNC.Perception, "GetZombieFrame", "ProjectHoomans.Server.Update.NPC.Perception")
wrap(PNC.BehaviorSystem, "Tick", "ProjectHoomans.Server.Update.NPC.Decision")
wrap(PNC.PathService, "Pump", "ProjectHoomans.Server.Update.NPC.Pathfinding")
wrap(PNC.Scheduler, "PopDue", "ProjectHoomans.Server.Update.Scheduler.PopDue")
wrap(PNC.Scheduler, "PumpJobs", "ProjectHoomans.Server.Update.Director.ScheduledJobs")
installScheduledJobPerformance()
wrap(PNC.Network, "BroadcastRecord", "ProjectHoomans.Network.BroadcastRecord")
wrap(PNC.Network, "FlushRosterDeltas", "ProjectHoomans.Server.Update.Network.FlushRosterDeltas")

Profiler.RegisterSampler("ProjectHoomans.shared", function(api)
    local Registry = PNC.Registry
    local Census = PNC.WorldCensus
    local Aggro = PNC.ZombieAggro and PNC.ZombieAggro.ActiveSet or nil
    api.SetGauge("ProjectHoomans.NPC.Total", countMap(Registry and Registry.Data))
    api.SetGauge("ProjectHoomans.NPC.Live", countMap(Registry and Registry.LiveByID))
    api.SetGauge("ProjectHoomans.World.LoadedZombies", #(Census and Census.OrdinaryZombies or {}))
    api.SetGauge("ProjectHoomans.World.ManagedBodies", #(Census and Census.ManagedBodies or {}))
    api.SetGauge("ProjectHoomans.ZombieAggro.Active", Aggro and (#Aggro.order - (Aggro.holes or 0)) or 0)
    api.SetGauge("ProjectHoomans.Scheduler.PendingBuckets", countMap(PNC.Scheduler and PNC.Scheduler.Buckets))
    local storageRepository = PNC.ColonyStorageRepository
    local storageService = PNC.ColonyStorageService
    local storageMetrics = storageService and storageService.Metrics or {}
    local storageCount, logicalItems, records, usedWeight, capacity = 0, 0, 0, 0, 0
    for _, storage in pairs(storageRepository and storageRepository.ByID or {}) do
        storageCount = storageCount + 1
        logicalItems = logicalItems + storage.inventory:getLogicalItemCount()
        records = records + storage.inventory:getRecordCount()
        usedWeight = usedWeight + storage.inventory:getWeight()
        capacity = capacity + (storage.inventory.maxWeight or 0)
    end
    api.SetGauge("ProjectHoomans.ColonyStorage.Count", storageCount)
    api.SetGauge("ProjectHoomans.ColonyStorage.LogicalItems", logicalItems)
    api.SetGauge("ProjectHoomans.ColonyStorage.SerializedRecords", records)
    api.SetGauge("ProjectHoomans.ColonyStorage.UsedWeight", usedWeight)
    api.SetGauge("ProjectHoomans.ColonyStorage.Capacity", capacity)
    api.SetGauge("ProjectHoomans.ColonyStorage.Deposits", storageMetrics.deposits or 0)
    api.SetGauge("ProjectHoomans.ColonyStorage.Withdrawals", storageMetrics.withdrawals or 0)
    api.SetGauge("ProjectHoomans.ColonyStorage.TransferFailures", storageMetrics.transferFailures or 0)
    api.SetGauge("ProjectHoomans.ColonyStorage.CapacityRejects", storageMetrics.capacityRejects or 0)
    local supplyMetrics = PNC.SupplyMetrics or {}
    for _, name in ipairs({
        "supplyRequests", "supplyRequestsSatisfiedFromPersonalInventory",
        "supplyRequestsSentToStorage", "supplyRequestsSucceeded",
        "supplyRequestsFailed", "foodRequests", "hydrationRequests",
        "medicalRequests", "reservationsCreated", "reservationFailures",
        "instantAcquisitions", "acquisitionFailures", "candidateQueries",
        "candidateItemsEvaluated", "supplyRetriesSuppressed",
        "deltaInventoryMutations", "deltaInventoryCompactions",
        "deltaToFullPromotions",
    }) do
        api.SetGauge("ProjectHoomans.NPCSupply." .. name,
            supplyMetrics[name] or 0)
    end
    local report = ModDataProfiler and ModDataProfiler.Scan and ModDataProfiler.Scan(false) or nil
    if report then
        api.SetGauge("ProjectHoomans.ModData.PersistedEstimatedBytes", report.persisted.estimatedBytes)
        api.SetGauge("ProjectHoomans.ModData.RuntimeEstimatedBytes", report.runtimeRecords.estimatedBytes)
        api.SetGauge("ProjectHoomans.ModData.InventoryEstimatedBytes", report.inventories.estimatedBytes)
        api.SetGauge("ProjectHoomans.ModData.InventoryItems", report.inventories.itemCount)
        api.SetGauge("ProjectHoomans.ModData.InventoryOperationLogEntries", report.inventories.operationLogEntries)
        api.SetGauge("ProjectHoomans.ModData.ScanMs", report.scanMs)
    end
end)
end
function Integration.InstallServer()
    if not Profiler.IsSectionEnabled("performance") then return false end
    if Integration.serverInstalled then return false end
    wrap(PNC.WorldDirector, "Pump", "ProjectHoomans.Server.Update.Director")
    wrap(PNC.PopulationDirector, "Pump", "ProjectHoomans.Server.Update.Director.Population")
    wrap(PNC.PersistenceCoordinator, "Commit", "ProjectHoomans.Persistence.Commit")
    wrap(PNC.PlayerCharacters, "Save", "ProjectHoomans.Persistence.PlayerCharacters")
    wrap(PNC.NPCKnowledge, "Save", "ProjectHoomans.Persistence.NPCKnowledge")
    wrap(PNC.Factions, "Save", "ProjectHoomans.Persistence.Factions")
    wrap(PNC.Communities, "Save", "ProjectHoomans.Persistence.Communities")
    wrap(PNC.ColonyStorageRepository, "Save",
        "ProjectHoomans.Persistence.ColonyStorage")
    wrap(PNC.AbstractWorldStore, "Save", "ProjectHoomans.Persistence.AbstractWorld")
    wrap(PNC.WorldDiscovery, "Save", "ProjectHoomans.Persistence.WorldDiscovery")
    wrap(PNC.Conversation and PNC.Conversation.History, "Save",
        "ProjectHoomans.Persistence.ConversationHistory")
    wrap(PNC.Registry, "FlushDirty", "ProjectHoomans.Persistence.NPCRecords")
    wrap(PNC.PlayerCharacterLifecycle, "Pump", "ProjectHoomans.Server.Update.PlayerCharacters")
    wrap(PNC.FactionBehavior, "PumpReconciliation", "ProjectHoomans.Server.Update.FactionReconciliation")
    wrap(PNC.FactionIncidentService, "PumpRuntime", "ProjectHoomans.Server.Update.FactionIncidents")
    wrap(PNC.FactionTolls, "Pump", "ProjectHoomans.Server.Update.FactionTolls")
    wrap(PNC.NeedsScheduler, "Pump", "ProjectHoomans.Server.Update.Needs")
    wrap(PNC.EnginePathPlanner, "PumpServerFrame", "ProjectHoomans.Server.Update.EnginePathPlanner")
    wrap(PNC.BodyLifecycle, "PumpStartupBodyCleanup", "ProjectHoomans.Server.Update.BodyCleanup")
    wrap(PNC.BodyLifecycle, "AuditLoadedBodies", "ProjectHoomans.Server.Update.BodyAudit")
    wrap(PNC.CompanionVehicle, "AuditLoadedReservations", "ProjectHoomans.Server.Update.VehicleAudit")
    wrap(PNC.Presence, "RefreshMaterializationCandidates", "ProjectHoomans.Server.Update.MaterializationCandidates")
    wrap(PNC.Presence, "Materialize", "ProjectHoomans.Server.Update.NPC.Materialize")
    wrap(PNC.Network, "RefreshInterestSets", "ProjectHoomans.Server.Update.Network.RefreshInterestSets")
    wrap(PNC.ZombieAggro, "Pump", "ProjectHoomans.Server.Update.ZombieAggro")
    wrap(PNC.SocialEncounterTracker, "Pump", "ProjectHoomans.Server.Update.SocialEncounters")
    wrap(PNC.Presence, "Reconcile", "ProjectHoomans.Server.Update.NPC.Presence")
    wrap(PNC.Health, "Update", "ProjectHoomans.Server.Update.NPC.Health")
    wrap(PNC.Stamina, "Update", "ProjectHoomans.Server.Update.NPC.Stamina")
    wrap(PNC.Animation, "SyncLocomotion", "ProjectHoomans.Server.Update.NPC.Animation")
    wrap(PNC.SpatialIndex, "UpdateNPC", "ProjectHoomans.Server.Update.NPC.SpatialUpdate")
    wrap(PNC.Network, "QueuePeriodicRoster", "ProjectHoomans.Server.Update.NPC.QueueRoster")
    wrap(PNC.Scheduler, "Schedule", "ProjectHoomans.Server.Update.NPC.Schedule")
    local networkInternal = PNC.Network and PNC.Network.Internal or nil
    wrap(networkInternal, "QueueBroadcastRoster", "ProjectHoomans.Network.BroadcastRecord.QueueRoster")
    wrap(networkInternal, "CollectRecordRecipients", "ProjectHoomans.Network.BroadcastRecord.FindRecipients")
    wrap(networkInternal, "BuildRecordPayload", "ProjectHoomans.Network.BroadcastRecord.BuildPayload")
    wrap(networkInternal, "SendRecordPayload", "ProjectHoomans.Network.BroadcastRecord.SendPayload")
    Profiler.RegisterSampler("ProjectHoomans.server", function(api)
        local groups = PNC.AbstractGroups and PNC.AbstractGroups.List and PNC.AbstractGroups.List() or {}
        local sites = PNC.Communities and PNC.Communities.ListSites and PNC.Communities.ListSites() or {}
        local dirty = countMap(PNC.Registry and PNC.Registry.DirtyByID)
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
    if type(callback) ~= "function" then return callback end
    if not Profiler.IsSectionEnabled("performance") then return callback end
    local wrapped = Profiler.Wrap("ProjectHoomans.Server.Update", callback)
    Profiler.RegisterStopHook("ProjectHoomans.serverTick", function()
        if Events and Events.OnTick and Events.OnTick.Remove then
            Events.OnTick.Remove(wrapped)
            Events.OnTick.Add(callback)
        end
        if PNC.Server then PNC.Server.OnTick = callback end
    end)
    return wrapped
end

function Integration.ApplyCaptureConfig(config)
    Profiler = PsychopatzCore and PsychopatzCore.Profiler
    if not Profiler or not Profiler.IsRunning or not Profiler.IsRunning() then
        Integration.Restore()
        return config.mode == "OFF"
    end
    if Profiler.IsSectionEnabled("moddata") then
        ModDataProfiler = require "PNC/Integrations/PNC_PsychopatzModDataProfiler"
        if ModDataProfiler.Register then ModDataProfiler.Register(config) end
    else
        ModDataProfiler = nil
    end
    if Profiler.IsSectionEnabled("npc") then
        local NPCProfiler = require "PNC/Integrations/PNC_PsychopatzNPCProfiler"
        if NPCProfiler.Register then NPCProfiler.Register(config) end
    end
    if Profiler.IsSectionEnabled("performance") then
        installSharedPerformance()
        Integration.InstallServer()
        if PNC.Server and type(PNC.Server.OnTick) == "function" then
            local original = PNC.Server.OnTick
            local wrapped = Integration.WrapServerTick(original)
            if wrapped ~= original then
                if Events and Events.OnTick and Events.OnTick.Remove then Events.OnTick.Remove(original) end
                if Events and Events.OnTick and Events.OnTick.Add then Events.OnTick.Add(wrapped) end
                PNC.Server.OnTick = wrapped
            end
        end
    end
    return true
end

Bootstrap.RegisterCaptureController("ProjectHoomans", Integration.ApplyCaptureConfig)
Integration.ApplyCaptureConfig(Bootstrap.GetCaptureConfig())

return Integration
