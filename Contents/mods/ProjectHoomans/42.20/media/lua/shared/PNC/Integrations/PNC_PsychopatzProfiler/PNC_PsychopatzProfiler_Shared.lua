local Integration = PNC and PNC.ProfilerIntegration or nil
if not Integration or Integration._loadingProviders ~= true then
    return Integration
end

local Internal = Integration.Internal
if type(Internal) ~= "table" then return Integration end

function Internal.InstallSharedPerformance()
    local Profiler = Internal.Profiler
    Profiler.RegisterNamespace("ProjectHoomans", {
        displayName = "Project Hoomans",
    })
    Profiler.RegisterStopHook("ProjectHoomans.restore", Integration.Restore)
    Internal.Wrap(PNC.SpatialIndex, "Rebuild",
        "ProjectHoomans.Server.Update.Spatial.Rebuild")
    Internal.Wrap(PNC.WorldCensus, "Refresh",
        "ProjectHoomans.WorldCensus.Refresh")
    Internal.Wrap(PNC.Perception, "GetZombieFrame",
        "ProjectHoomans.Server.Update.NPC.Perception")
    Internal.Wrap(PNC.BehaviorSystem, "Tick",
        "ProjectHoomans.Server.Update.NPC.Decision")
    Internal.Wrap(PNC.PathService, "Pump",
        "ProjectHoomans.Server.Update.NPC.Pathfinding")
    Internal.Wrap(PNC.Scheduler, "PopDue",
        "ProjectHoomans.Server.Update.Scheduler.PopDue")
    Internal.Wrap(PNC.Scheduler, "PumpJobs",
        "ProjectHoomans.Server.Update.Director.ScheduledJobs")
    Internal.InstallScheduledJobPerformance()
    Internal.Wrap(PNC.Network, "BroadcastRecord",
        "ProjectHoomans.Network.BroadcastRecord")
    Internal.Wrap(PNC.Network, "FlushRosterDeltas",
        "ProjectHoomans.Server.Update.Network.FlushRosterDeltas")

    Profiler.RegisterSampler("ProjectHoomans.shared", function(api)
        local Registry = PNC.Registry
        local Census = PNC.WorldCensus
        local Aggro = PNC.ZombieAggro and PNC.ZombieAggro.ActiveSet or nil
        local Scaling = PNC.PerformanceScalingDiagnostics
        if Scaling and Scaling.Export then Scaling.Export(api) end
        api.SetGauge("ProjectHoomans.NPC.Total",
            Internal.CountMap(Registry and Registry.Data))
        api.SetGauge("ProjectHoomans.NPC.Live",
            Internal.CountMap(Registry and Registry.LiveByID))
        api.SetGauge("ProjectHoomans.World.LoadedZombies",
            #(Census and Census.OrdinaryZombies or {}))
        api.SetGauge("ProjectHoomans.World.ManagedBodies",
            #(Census and Census.ManagedBodies or {}))
        api.SetGauge("ProjectHoomans.ZombieAggro.Active",
            Aggro and (#Aggro.order - (Aggro.holes or 0)) or 0)
        api.SetGauge("ProjectHoomans.Scheduler.PendingBuckets",
            Internal.CountMap(PNC.Scheduler and PNC.Scheduler.Buckets))
        local storageRepository = PNC.ColonyStorageRepository
        local storageService = PNC.ColonyStorageService
        local storageMetrics = storageService and storageService.Metrics or {}
        local storageCount, logicalItems, records, usedWeight, capacity =
            0, 0, 0, 0, 0
        for _, storage in pairs(
            storageRepository and storageRepository.ByID or {}
        ) do
            storageCount = storageCount + 1
            logicalItems = logicalItems
                + storage.inventory:getLogicalItemCount()
            records = records + storage.inventory:getRecordCount()
            usedWeight = usedWeight + storage.inventory:getWeight()
            capacity = capacity + (storage.inventory.maxWeight or 0)
        end
        api.SetGauge("ProjectHoomans.ColonyStorage.Count", storageCount)
        api.SetGauge("ProjectHoomans.ColonyStorage.LogicalItems", logicalItems)
        api.SetGauge("ProjectHoomans.ColonyStorage.SerializedRecords", records)
        api.SetGauge("ProjectHoomans.ColonyStorage.UsedWeight", usedWeight)
        api.SetGauge("ProjectHoomans.ColonyStorage.Capacity", capacity)
        api.SetGauge("ProjectHoomans.ColonyStorage.Deposits",
            storageMetrics.deposits or 0)
        api.SetGauge("ProjectHoomans.ColonyStorage.Withdrawals",
            storageMetrics.withdrawals or 0)
        api.SetGauge("ProjectHoomans.ColonyStorage.TransferFailures",
            storageMetrics.transferFailures or 0)
        api.SetGauge("ProjectHoomans.ColonyStorage.CapacityRejects",
            storageMetrics.capacityRejects or 0)
        local supplyMetrics = PNC.SupplyMetrics or {}
        for _, name in ipairs({
            "supplyRequests", "supplyRequestsSatisfiedFromPersonalInventory",
            "supplyRequestsSentToStorage", "supplyRequestsSucceeded",
            "supplyRequestsFailed", "foodRequests", "hydrationRequests",
            "medicalRequests", "reservationsCreated", "reservationFailures",
            "instantAcquisitions", "acquisitionFailures", "candidateQueries",
            "candidateItemsEvaluated", "supplyRetriesSuppressed",
            "deltaInventoryMutations", "deltaInventoryCompactions",
            "deltaToFullPromotions", "provisionPolicyRevision",
            "provisionDirtyNPCs", "provisionEvaluations",
            "provisionRulesEvaluated", "provisionRulesSatisfied",
            "provisionRulesDeficient", "provisionRequestsCreated",
            "provisionRequestsSucceeded", "provisionRequestsFailed",
            "provisionRequestsSuppressedByIncoming",
            "provisionRequestsSuppressedByNeedRequest",
            "provisionSchedulerQueueSize", "provisionSchedulerProcessed",
            "provisionStorageShortages",
        }) do
            api.SetGauge("ProjectHoomans.NPCSupply." .. name,
                supplyMetrics[name] or 0)
        end
    end)
end

return Integration
