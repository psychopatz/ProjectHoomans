local Integration = PNC and PNC.ProfilerIntegration or nil
if not Integration or Integration._loadingProviders ~= true then
    return Integration
end

local Internal = Integration.Internal
if type(Internal) ~= "table" then return Integration end

function Internal.InstallSharedPerformanceSampler()
    local Profiler = Internal.Profiler
    Profiler.RegisterSampler("ProjectHoomans.shared", function(api)
        local Registry = PNC.Registry
        local Census = PNC.WorldCensus
        local Aggro = PNC.ZombieAggro and PNC.ZombieAggro.ActiveSet or nil
        local Const = PNC.Const or {}
        local Scaling = PNC.PerformanceScalingDiagnostics
        local followOrders = 0
        local followLive = 0
        local followAbstract = 0
        local followOwnerMoving = 0
        local followHolding = 0
        local followTargeted = 0
        local followPathActive = 0
        local followOwners = {}
        local ambientLeases = 0
        local roamingSeatLeases = 0
        local waterActivities = 0
        local refillActivities = 0
        local worldWaterActivities = 0
        local manualWaterOverrides = 0
        for _, record in pairs(Registry and Registry.Data or {}) do
            local order = record and record.orderSpec or nil
            local runtime = record and record.runtime or nil
            local followState = runtime and runtime.followState or nil
            local path = runtime and runtime.pathing or nil
            local activity = runtime and runtime.facilityActivity or nil
            if runtime and runtime.roamAmbient then
                ambientLeases = ambientLeases + 1
            end
            if runtime and runtime.roamingSeat then
                roamingSeatLeases = roamingSeatLeases + 1
            end
            if activity and (activity.resourceKind == "water_refill"
                or activity.resourceKind == "world_water")
            then
                waterActivities = waterActivities + 1
                if activity.resourceKind == "water_refill" then
                    refillActivities = refillActivities + 1
                else
                    worldWaterActivities = worldWaterActivities + 1
                end
                if activity.manualOverride == true then
                    manualWaterOverrides = manualWaterOverrides + 1
                end
            end
            if order and tostring(order.kind or "")
                == tostring(Const.ORDER_FOLLOW or "follow")
            then
                followOrders = followOrders + 1
                if record.presenceState == Const.PRESENCE_LIVE
                    or record.presenceState == "live"
                then
                    followLive = followLive + 1
                else
                    followAbstract = followAbstract + 1
                end
                local ownerKey = order.ownerOnlineID
                    or record.ownerOnlineID
                    or order.ownerUsername
                    or record.ownerUsername
                if ownerKey ~= nil then
                    followOwners[tostring(ownerKey)] = true
                end
                if followState and followState.ownerMoving == true then
                    followOwnerMoving = followOwnerMoving + 1
                end
                if followState and followState.stationaryHolding == true then
                    followHolding = followHolding + 1
                end
                if runtime and runtime.target ~= nil then
                    followTargeted = followTargeted + 1
                end
                if path and (
                    path.phase == "requested" or path.phase == "active"
                ) then
                    followPathActive = followPathActive + 1
                end
            end
        end
        if Scaling and Scaling.Export then Scaling.Export(api) end
        api.SetGauge("ProjectHoomans.NPC.Total",
            Internal.CountMap(Registry and Registry.Data))
        api.SetGauge("ProjectHoomans.NPC.Live",
            Internal.CountMap(Registry and Registry.LiveByID))
        api.SetGauge("ProjectHoomans.Follow.Orders", followOrders)
        api.SetGauge("ProjectHoomans.Follow.Live", followLive)
        api.SetGauge("ProjectHoomans.Follow.Abstract", followAbstract)
        api.SetGauge("ProjectHoomans.Follow.OwnerMoving", followOwnerMoving)
        api.SetGauge("ProjectHoomans.Follow.StationaryHolding", followHolding)
        api.SetGauge("ProjectHoomans.Follow.Targeted", followTargeted)
        api.SetGauge("ProjectHoomans.Follow.PathActive", followPathActive)
        api.SetGauge("ProjectHoomans.Follow.OwnerGroups",
            Internal.CountMap(followOwners))
        api.SetGauge("ProjectHoomans.Roaming.AmbientLeases", ambientLeases)
        api.SetGauge("ProjectHoomans.Roaming.SeatLeases", roamingSeatLeases)
        api.SetGauge("ProjectHoomans.NPC.Water.Active", waterActivities)
        api.SetGauge("ProjectHoomans.NPC.Water.RefillActive", refillActivities)
        api.SetGauge("ProjectHoomans.NPC.Water.WorldActive",
            worldWaterActivities)
        api.SetGauge("ProjectHoomans.NPC.Water.ManualOverrides",
            manualWaterOverrides)
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
    end)end

return Integration
