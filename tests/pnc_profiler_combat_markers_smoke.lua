local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = nil
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
Bootstrap.mode = "BASIC"
local Profiler = require "PsychopatzCore/Profiler/PsychopatzProfiler"
local now = 0
local function callback(name)
    return function() return name end
end

Profiler.Start("BASIC", {
    nowMs = function() return now end,
    sourceType = function() return "test" end,
})

PNC = {
    Core = { Now = function() return now end },
    Server = { Internal = { ProcessRecord = callback("process_record") } },
    Registry = { Data = {}, LiveByID = {}, DirtyByID = {} },
    WorldCensus = { OrdinaryZombies = {}, ManagedBodies = {} },
    Scheduler = { PopDue = callback("pop_due"), PumpJobs = callback("pump_jobs"),
        Schedule = callback("schedule"), Buckets = {} },
    SpatialIndex = { Rebuild = callback("rebuild"), QueryZombies = callback("query_zombies"),
        UpdateNPC = callback("update_npc") },
    Perception = {
        GetZombieFrame = callback("zombie_frame"),
        GetVisibleZombieEntries = callback("visible_entries"),
        CountZombiesInFrame = callback("frame_count"),
        FindImmediateZombieThreat = callback("immediate_threat"),
        FindNearestEnemyZombie = callback("nearest_zombie"),
    },
    BehaviorSystem = { Tick = callback("behavior_tick") },
    BehaviorHostile = { Tick = callback("hostile_tick") },
    BehaviorCombat = {
        TickCommittedAction = callback("committed_action"),
        TickEngage = callback("engage"),
    },
    BehaviorTargeting = {
        ResolveImmediateZombieThreat = callback("resolve_immediate"),
        UpdateTargetFromWorld = callback("target_refresh"),
    },
    Combat = {
        PumpAttackAction = callback("attack_pump"),
        Internal = { applyAttackActionHit = callback("attack_hit") },
    },
    CombatEngagement = { Tick = callback("engagement") },
    CombatTactics = {
        PreAttackDecision = callback("pre_attack"),
        Internal = {
            AssessThreat = callback("assess_threat"),
            BuildZombieThreatCentroid = callback("threat_centroid"),
        },
    },
    CombatDefense = { Refresh = callback("defense") },
    Stamina = {
        Update = callback("stamina_update"),
        ApplyMovementDrain = callback("movement_drain"),
        BuildMovementProfile = callback("movement_profile"),
        BuildSnapshot = callback("stamina_snapshot"),
        CanSpendAttack = callback("attack_check"),
        SpendAttack = callback("attack_spend"),
    },
    Equipment = { Describe = callback("equipment") },
    Inventory = { BuildSummaryPayload = callback("inventory") },
    Skills = { BuildSnapshot = callback("skills") },
    VisualProfiles = { RollAppearance = callback("appearance") },
    NPCWounds = { BuildSnapshot = callback("wounds") },
    Firearms = { BuildDebugState = callback("firearms") },
    BehaviorTreatment = { BuildSnapshot = callback("treatment") },
    Treatment = { BuildMedicalCareSnapshot = callback("medical") },
    ZombieAggro = {
        Pump = callback("aggro_pump"),
        RefreshActiveSet = callback("aggro_refresh"),
        ActiveSet = { order = {}, holes = 0 },
    },
    Network = {
        BroadcastRecord = callback("broadcast"),
        BuildSnapshot = callback("full_snapshot"),
        BuildPresenceDelta = callback("presence_delta"),
        FlushRosterDeltas = callback("flush_roster"),
        QueuePeriodicRoster = callback("periodic_roster"),
        Internal = {
            QueueBroadcastRoster = callback("queue_broadcast"),
            CollectRecordRecipients = callback("recipients"),
            BuildRecordPayload = callback("build_payload"),
            SendRecordPayload = callback("send_payload"),
        },
    },
}

local targets = {
    { PNC.Server.Internal, "ProcessRecord", "ProjectHoomans.Server.Update.NPC.ProcessRecord" },
    { PNC.Network, "BuildSnapshot", "ProjectHoomans.Network.Snapshot.Full" },
    { PNC.Network, "BuildPresenceDelta", "ProjectHoomans.Network.Snapshot.PresenceDelta" },
    { PNC.Equipment, "Describe", "ProjectHoomans.Network.Snapshot.Equipment" },
    { PNC.Inventory, "BuildSummaryPayload", "ProjectHoomans.Network.Snapshot.Inventory" },
    { PNC.Skills, "BuildSnapshot", "ProjectHoomans.Network.Snapshot.Skills" },
    { PNC.VisualProfiles, "RollAppearance", "ProjectHoomans.Network.Snapshot.Appearance" },
    { PNC.NPCWounds, "BuildSnapshot", "ProjectHoomans.Network.Snapshot.Wounds" },
    { PNC.Firearms, "BuildDebugState", "ProjectHoomans.Network.Snapshot.Firearms" },
    { PNC.BehaviorTreatment, "BuildSnapshot", "ProjectHoomans.Network.Snapshot.Treatment" },
    { PNC.Treatment, "BuildMedicalCareSnapshot", "ProjectHoomans.Network.Snapshot.Medical" },
    { PNC.BehaviorHostile, "Tick", "ProjectHoomans.Server.Update.NPC.Combat.Hostile" },
    { PNC.BehaviorCombat, "TickCommittedAction", "ProjectHoomans.Server.Update.NPC.Combat.CommittedAction" },
    { PNC.BehaviorCombat, "TickEngage", "ProjectHoomans.Server.Update.NPC.Combat.Engage" },
    { PNC.CombatEngagement, "Tick", "ProjectHoomans.Server.Update.NPC.Combat.Engagement" },
    { PNC.CombatTactics, "PreAttackDecision", "ProjectHoomans.Server.Update.NPC.Combat.PreAttackDecision" },
    { PNC.CombatTactics.Internal, "AssessThreat", "ProjectHoomans.Server.Update.NPC.Combat.ThreatAssessment" },
    { PNC.CombatTactics.Internal, "BuildZombieThreatCentroid", "ProjectHoomans.Server.Update.NPC.Combat.ThreatCentroid" },
    { PNC.Combat, "PumpAttackAction", "ProjectHoomans.Server.Update.NPC.Combat.AttackPump" },
    { PNC.Combat.Internal, "applyAttackActionHit", "ProjectHoomans.Server.Update.NPC.Combat.AttackHitResolution" },
    { PNC.CombatDefense, "Refresh", "ProjectHoomans.Server.Update.NPC.Combat.Defense" },
    { PNC.BehaviorTargeting, "ResolveImmediateZombieThreat", "ProjectHoomans.Server.Update.NPC.Combat.ImmediateThreat" },
    { PNC.BehaviorTargeting, "UpdateTargetFromWorld", "ProjectHoomans.Server.Update.NPC.Combat.TargetRefresh" },
    { PNC.Perception, "FindImmediateZombieThreat", "ProjectHoomans.Server.Update.NPC.Combat.ImmediateThreat.Scan" },
    { PNC.Perception, "FindNearestEnemyZombie", "ProjectHoomans.Server.Update.NPC.Combat.TargetSearch" },
    { PNC.Perception, "GetVisibleZombieEntries", "ProjectHoomans.Server.Update.NPC.Combat.VisibilityScan" },
    { PNC.Perception, "CountZombiesInFrame", "ProjectHoomans.Server.Update.NPC.Combat.FrameZombieCount" },
    { PNC.SpatialIndex, "QueryZombies", "ProjectHoomans.Server.Update.NPC.Combat.SpatialZombieQuery" },
    { PNC.ZombieAggro, "RefreshActiveSet", "ProjectHoomans.Server.Update.NPC.Combat.ZombieAggro.RefreshActiveSet" },
    { PNC.Stamina, "ApplyMovementDrain", "ProjectHoomans.Server.Update.NPC.Stamina.MovementDrain" },
    { PNC.Stamina, "BuildMovementProfile", "ProjectHoomans.Server.Update.NPC.Stamina.MovementProfile" },
    { PNC.Stamina, "BuildSnapshot", "ProjectHoomans.Server.Update.NPC.Stamina.Snapshot" },
    { PNC.Stamina, "CanSpendAttack", "ProjectHoomans.Server.Update.NPC.Stamina.AttackCheck" },
    { PNC.Stamina, "SpendAttack", "ProjectHoomans.Server.Update.NPC.Stamina.AttackSpend" },
    { PNC.Network.Internal, "BuildRecordPayload", "ProjectHoomans.Network.BroadcastRecord.BuildPayload" },
}

local originals = {}
local i
for i = 1, #targets do
    originals[i] = {
        callback = targets[i][1][targets[i][2]],
        returnValue = targets[i][1][targets[i][2]](),
    }
end

local Integration = require "PNC/Integrations/PNC_PsychopatzProfiler"
Integration.InstallServer()

for i = 1, #targets do
    local owner = targets[i][1]
    local key = targets[i][2]
    local metric = targets[i][3]
    T.truthy(owner[key] ~= originals[i].callback, metric .. " was not installed")
    T.equal(owner[key](), originals[i].returnValue,
        metric .. " changed the wrapped return value")
end

now = 1000
Profiler.Sample(1000)
local metrics = Profiler.GetMetrics("timer", "ProjectHoomans")
local seen = {}
for i = 1, #metrics do seen[metrics[i].name] = true end
for i = 1, #targets do
    T.truthy(seen[targets[i][3]], targets[i][3] .. " was not recorded")
end

Profiler.Stop()
for i = 1, #targets do
    T.equal(targets[i][1][targets[i][2]], originals[i].callback,
        targets[i][3] .. " was not restored")
end

T.finish("pnc_profiler_combat_markers_smoke")
