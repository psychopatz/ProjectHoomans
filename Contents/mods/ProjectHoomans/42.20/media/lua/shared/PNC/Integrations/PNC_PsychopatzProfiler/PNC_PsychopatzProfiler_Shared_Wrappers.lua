local Integration = PNC and PNC.ProfilerIntegration or nil
if not Integration or Integration._loadingProviders ~= true then
    return Integration
end

local Internal = Integration.Internal
if type(Internal) ~= "table" then return Integration end

function Internal.InstallSharedPerformanceWrappers()
    local Profiler = Internal.Profiler
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
    -- BuildRecordPayload selects the detailed, combat-damage, or presence
    -- path so captures can attribute each payload cost correctly.
    Internal.Wrap(PNC.Network, "BuildSnapshot",
        "ProjectHoomans.Network.Snapshot.Full")
    Internal.Wrap(PNC.Network, "BuildCombatDamageDelta",
        "ProjectHoomans.Network.Snapshot.CombatDamageDelta")
    Internal.Wrap(PNC.Network, "BuildPresenceDelta",
        "ProjectHoomans.Network.Snapshot.PresenceDelta")
    Internal.Wrap(PNC.Equipment, "Describe",
        "ProjectHoomans.Network.Snapshot.Equipment")
    Internal.Wrap(PNC.Inventory, "BuildSummaryPayload",
        "ProjectHoomans.Network.Snapshot.Inventory")
    Internal.Wrap(PNC.Skills, "BuildSnapshot",
        "ProjectHoomans.Network.Snapshot.Skills")
    Internal.Wrap(PNC.Identity, "RollAppearance",
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
    Internal.Wrap(companion, "Tick",
        "ProjectHoomans.Server.Update.NPC.Companion.Dispatch")
    if companion and companion.InstallProfilerWrappers then
        companion.InstallProfilerWrappers(Internal.Wrap)
    end

    -- These are global movement authorities. Keeping them separate from the
    -- existing PathService.Pump marker shows whether a follow spike is caused
    -- by deciding on a move or by the engine/native path pump itself.
    Internal.Wrap(PNC.MoveIntent, "RequestMove",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveIntent.Request")
    Internal.Wrap(PNC.MoveIntent, "Hold",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveIntent.Hold")
    Internal.Wrap(PNC.PathService, "MoveToward",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveToward")
    local enginePlanner = PNC.EnginePathPlanner
    Internal.Wrap(enginePlanner, "Invalidate",
        "ProjectHoomans.Server.Update.NPC.Pathing.NativeInvalidate")
    if enginePlanner and enginePlanner.InstallProfilerWrappers then
        enginePlanner.InstallProfilerWrappers(Internal.Wrap)
    end

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
    if PNC.CombatTactics and PNC.CombatTactics.InstallProfilerWrappers then
        PNC.CombatTactics.InstallProfilerWrappers(Internal.Wrap)
    end
    Internal.Wrap(PNC.Combat, "PumpAttackAction",
        "ProjectHoomans.Server.Update.NPC.Combat.AttackPump")
    if PNC.Combat and PNC.Combat.InstallProfilerWrappers then
        PNC.Combat.InstallProfilerWrappers(Internal.Wrap)
    end
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

end

return Integration
