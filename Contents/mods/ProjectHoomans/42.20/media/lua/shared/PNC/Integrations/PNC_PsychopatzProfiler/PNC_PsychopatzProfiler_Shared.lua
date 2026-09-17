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
    -- Keep the network event envelope separate from the snapshot builders.
    -- BuildRecordPayload selects one of these two paths, so the capture can
    -- distinguish a full combat-event snapshot from a compact presence tick.
    Internal.Wrap(PNC.Network, "BuildSnapshot",
        "ProjectHoomans.Network.Snapshot.Full")
    Internal.Wrap(PNC.Network, "BuildPresenceDelta",
        "ProjectHoomans.Network.Snapshot.PresenceDelta")
    Internal.Wrap(PNC.Equipment, "Describe",
        "ProjectHoomans.Network.Snapshot.Equipment")
    Internal.Wrap(PNC.Inventory, "BuildSummaryPayload",
        "ProjectHoomans.Network.Snapshot.Inventory")
    Internal.Wrap(PNC.Skills, "BuildSnapshot",
        "ProjectHoomans.Network.Snapshot.Skills")
    Internal.Wrap(PNC.VisualProfiles, "RollAppearance",
        "ProjectHoomans.Network.Snapshot.Appearance")
    Internal.Wrap(PNC.NPCWounds, "BuildSnapshot",
        "ProjectHoomans.Network.Snapshot.Wounds")
    Internal.Wrap(PNC.Firearms, "BuildDebugState",
        "ProjectHoomans.Network.Snapshot.Firearms")
    Internal.Wrap(PNC.BehaviorTreatment, "BuildSnapshot",
        "ProjectHoomans.Network.Snapshot.Treatment")
    Internal.Wrap(PNC.Treatment, "BuildMedicalCareSnapshot",
        "ProjectHoomans.Network.Snapshot.Medical")
    Internal.Wrap(PNC.Network, "FlushRosterDeltas",
        "ProjectHoomans.Server.Update.Network.FlushRosterDeltas")

    -- Companion-follow phases are intentionally exposed below the broad
    -- BehaviorSystem.Tick marker. These wrappers are diagnostic-only and are
    -- installed only while the performance section is active, so the normal
    -- gameplay path keeps its existing call graph and state transitions.
    local companion = PNC.BehaviorCompanion
    local companionInternal = companion and companion.Internal or nil
    Internal.Wrap(companion, "Tick",
        "ProjectHoomans.Server.Update.NPC.Companion.Dispatch")
    Internal.Wrap(companionInternal, "TickFollowOwner",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Tick")
    Internal.Wrap(companionInternal, "TickAbstractFollowOwner",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.AbstractTick")
    Internal.Wrap(companionInternal, "UpdateOwnerMotionState",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.OwnerMotion")
    Internal.Wrap(companionInternal, "UpdateOwnerCombatState",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.OwnerCombat")
    Internal.Wrap(companionInternal, "AssessFollowHazards",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Hazards")
    Internal.Wrap(companionInternal, "ResolveHordeAwareFollowTarget",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.HordeSteer")
    Internal.Wrap(companionInternal, "ResolveSampledFollowSlot",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Formation.SampledSlot")
    Internal.Wrap(companionInternal, "ResolveFollowSlot",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Formation.ResolveSlot")
    Internal.Wrap(companionInternal, "TryRespondToThreat",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.ThreatResponse")
    Internal.Wrap(companionInternal, "TryRespondToImmediateThreat",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.ImmediateThreat")
    Internal.Wrap(companionInternal, "ShouldScanFollowThreat",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.ThreatGate")
    Internal.Wrap(companionInternal, "HoldAndFaceOwner",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Hold")
    Internal.Wrap(companionInternal, "ShouldIssueFollowMove",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.MoveGate")
    Internal.Wrap(companionInternal, "EnforceOwnerPersonalSpace",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.PersonalSpace")

    -- These are global movement authorities. Keeping them separate from the
    -- existing PathService.Pump marker shows whether a follow spike is caused
    -- by deciding on a move or by the engine/native path pump itself.
    Internal.Wrap(PNC.MoveIntent, "RequestMove",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveIntent.Request")
    Internal.Wrap(PNC.MoveIntent, "Hold",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveIntent.Hold")
    Internal.Wrap(PNC.PathService, "MoveToward",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveToward")

    -- Follow is evaluated beside transient roaming presentation leases. These
    -- markers make an order/lease conflict visible without changing which
    -- subsystem owns the actor.
    Internal.Wrap(PNC.BehaviorRoaming, "Tick",
        "ProjectHoomans.Server.Update.NPC.Roaming.Tick")
    Internal.Wrap(PNC.RoamAmbient, "Tick",
        "ProjectHoomans.Server.Update.NPC.Roaming.Ambient.Tick")
    Internal.Wrap(PNC.RoamAmbient, "TryStart",
        "ProjectHoomans.Server.Update.NPC.Roaming.Ambient.TryStart")
    Internal.Wrap(PNC.RoamingSeat, "Tick",
        "ProjectHoomans.Server.Update.NPC.Roaming.Seat.Tick")
    Internal.Wrap(PNC.RoamingSeat, "TryStart",
        "ProjectHoomans.Server.Update.NPC.Roaming.Seat.TryStart")

    -- Combat orchestration markers. These are installed only while the
    -- performance section is enabled and are restored with the other wrappers.
    Internal.Wrap(PNC.BehaviorHostile, "Tick",
        "ProjectHoomans.Server.Update.NPC.Combat.Hostile")
    Internal.Wrap(PNC.BehaviorCombat, "TickCommittedAction",
        "ProjectHoomans.Server.Update.NPC.Combat.CommittedAction")
    Internal.Wrap(PNC.BehaviorCombat, "TickEngage",
        "ProjectHoomans.Server.Update.NPC.Combat.Engage")
    Internal.Wrap(PNC.CombatEngagement, "Tick",
        "ProjectHoomans.Server.Update.NPC.Combat.Engagement")
    Internal.Wrap(PNC.CombatTactics, "PreAttackDecision",
        "ProjectHoomans.Server.Update.NPC.Combat.PreAttackDecision")
    Internal.Wrap(PNC.CombatTactics and PNC.CombatTactics.Internal,
        "AssessThreat",
        "ProjectHoomans.Server.Update.NPC.Combat.ThreatAssessment")
    Internal.Wrap(PNC.CombatTactics and PNC.CombatTactics.Internal,
        "BuildZombieThreatCentroid",
        "ProjectHoomans.Server.Update.NPC.Combat.ThreatCentroid")
    Internal.Wrap(PNC.Combat, "PumpAttackAction",
        "ProjectHoomans.Server.Update.NPC.Combat.AttackPump")
    Internal.Wrap(PNC.Combat and PNC.Combat.Internal,
        "applyAttackActionHit",
        "ProjectHoomans.Server.Update.NPC.Combat.AttackHitResolution")
    Internal.Wrap(PNC.CombatDefense, "Refresh",
        "ProjectHoomans.Server.Update.NPC.Combat.Defense")

    -- Targeting and spatial work are separate because combat decisions can be
    -- cheap while a perception/spatial query still causes a burst.
    Internal.Wrap(PNC.BehaviorTargeting, "ResolveImmediateZombieThreat",
        "ProjectHoomans.Server.Update.NPC.Combat.ImmediateThreat")
    Internal.Wrap(PNC.BehaviorTargeting, "UpdateTargetFromWorld",
        "ProjectHoomans.Server.Update.NPC.Combat.TargetRefresh")
    Internal.Wrap(PNC.Perception, "FindImmediateZombieThreat",
        "ProjectHoomans.Server.Update.NPC.Combat.ImmediateThreat.Scan")
    Internal.Wrap(PNC.Perception, "FindNearestEnemyZombie",
        "ProjectHoomans.Server.Update.NPC.Combat.TargetSearch")
    Internal.Wrap(PNC.Perception, "GetVisibleZombieEntries",
        "ProjectHoomans.Server.Update.NPC.Combat.VisibilityScan")
    Internal.Wrap(PNC.Perception, "CountZombiesInFrame",
        "ProjectHoomans.Server.Update.NPC.Combat.FrameZombieCount")
    Internal.Wrap(PNC.SpatialIndex, "QueryZombies",
        "ProjectHoomans.Server.Update.NPC.Combat.SpatialZombieQuery")
    Internal.Wrap(PNC.ZombieAggro, "RefreshActiveSet",
        "ProjectHoomans.Server.Update.NPC.Combat.ZombieAggro.RefreshActiveSet")

    -- Stamina has a broad update marker on the server. These narrower markers
    -- identify whether the remaining cost is derived-state work, movement
    -- drain, replication, or attack resource arbitration.
    Internal.Wrap(PNC.Stamina, "ApplyMovementDrain",
        "ProjectHoomans.Server.Update.NPC.Stamina.MovementDrain")
    Internal.Wrap(PNC.Stamina, "BuildMovementProfile",
        "ProjectHoomans.Server.Update.NPC.Stamina.MovementProfile")
    Internal.Wrap(PNC.Stamina, "BuildSnapshot",
        "ProjectHoomans.Server.Update.NPC.Stamina.Snapshot")
    Internal.Wrap(PNC.Stamina, "CanSpendAttack",
        "ProjectHoomans.Server.Update.NPC.Stamina.AttackCheck")
    Internal.Wrap(PNC.Stamina, "SpendAttack",
        "ProjectHoomans.Server.Update.NPC.Stamina.AttackSpend")

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
    end)
end

return Integration
