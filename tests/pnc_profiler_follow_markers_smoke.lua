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
    Const = { ORDER_FOLLOW = "follow", PRESENCE_LIVE = "live" },
    Server = { Internal = { ProcessRecord = callback("process_record") } },
    Registry = { Data = {}, LiveByID = {}, DirtyByID = {} },
    WorldCensus = { OrdinaryZombies = {}, ManagedBodies = {} },
    Scheduler = { PopDue = callback("pop_due"), PumpJobs = callback("pump_jobs"),
        Schedule = callback("schedule"), Buckets = {} },
    SpatialIndex = { Rebuild = callback("rebuild"), QueryZombies = callback("query_zombies"),
        UpdateNPC = callback("update_npc") },
    Perception = { GetZombieFrame = callback("zombie_frame") },
    BehaviorSystem = { Tick = callback("behavior_tick") },
    BehaviorCompanion = {
        Tick = callback("companion_dispatch"),
        Internal = {
            TickFollowOwner = callback("follow_tick"),
            TickAbstractFollowOwner = callback("abstract_follow_tick"),
            UpdateOwnerMotionState = callback("owner_motion"),
            UpdateOwnerCombatState = callback("owner_combat"),
            AssessFollowHazards = callback("hazards"),
            ResolveHordeAwareFollowTarget = callback("horde_steer"),
            ResolveSampledFollowSlot = callback("sampled_slot"),
            ResolveFollowSlot = callback("resolve_slot"),
            TryRespondToThreat = callback("threat_response"),
            TryRespondToImmediateThreat = callback("immediate_threat"),
            ShouldScanFollowThreat = callback("threat_gate"),
            HoldAndFaceOwner = callback("hold"),
            ShouldIssueFollowMove = callback("move_gate"),
            EnforceOwnerPersonalSpace = callback("personal_space"),
        },
    },
    MoveIntent = {
        RequestMove = callback("move_request"),
        Hold = callback("move_hold"),
    },
    PathService = {
        Pump = callback("path_pump"),
        MoveToward = callback("move_toward"),
    },
    BehaviorRoaming = { Tick = callback("roaming_tick") },
    RoamAmbient = {
        Tick = callback("ambient_tick"),
        TryStart = callback("ambient_start"),
    },
    RoamingSeat = {
        Tick = callback("seat_tick"),
        TryStart = callback("seat_start"),
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
    { PNC.BehaviorCompanion, "Tick",
        "ProjectHoomans.Server.Update.NPC.Companion.Dispatch" },
    { PNC.BehaviorCompanion.Internal, "TickFollowOwner",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Tick" },
    { PNC.BehaviorCompanion.Internal, "TickAbstractFollowOwner",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.AbstractTick" },
    { PNC.BehaviorCompanion.Internal, "UpdateOwnerMotionState",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.OwnerMotion" },
    { PNC.BehaviorCompanion.Internal, "UpdateOwnerCombatState",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.OwnerCombat" },
    { PNC.BehaviorCompanion.Internal, "AssessFollowHazards",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Hazards" },
    { PNC.BehaviorCompanion.Internal, "ResolveHordeAwareFollowTarget",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.HordeSteer" },
    { PNC.BehaviorCompanion.Internal, "ResolveSampledFollowSlot",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Formation.SampledSlot" },
    { PNC.BehaviorCompanion.Internal, "ResolveFollowSlot",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Formation.ResolveSlot" },
    { PNC.BehaviorCompanion.Internal, "TryRespondToThreat",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.ThreatResponse" },
    { PNC.BehaviorCompanion.Internal, "TryRespondToImmediateThreat",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.ImmediateThreat" },
    { PNC.BehaviorCompanion.Internal, "ShouldScanFollowThreat",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.ThreatGate" },
    { PNC.BehaviorCompanion.Internal, "HoldAndFaceOwner",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.Hold" },
    { PNC.BehaviorCompanion.Internal, "ShouldIssueFollowMove",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.MoveGate" },
    { PNC.BehaviorCompanion.Internal, "EnforceOwnerPersonalSpace",
        "ProjectHoomans.Server.Update.NPC.FollowOwner.PersonalSpace" },
    { PNC.MoveIntent, "RequestMove",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveIntent.Request" },
    { PNC.MoveIntent, "Hold",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveIntent.Hold" },
    { PNC.PathService, "MoveToward",
        "ProjectHoomans.Server.Update.NPC.Pathing.MoveToward" },
    { PNC.BehaviorRoaming, "Tick",
        "ProjectHoomans.Server.Update.NPC.Roaming.Tick" },
    { PNC.RoamAmbient, "Tick",
        "ProjectHoomans.Server.Update.NPC.Roaming.Ambient.Tick" },
    { PNC.RoamAmbient, "TryStart",
        "ProjectHoomans.Server.Update.NPC.Roaming.Ambient.TryStart" },
    { PNC.RoamingSeat, "Tick",
        "ProjectHoomans.Server.Update.NPC.Roaming.Seat.Tick" },
    { PNC.RoamingSeat, "TryStart",
        "ProjectHoomans.Server.Update.NPC.Roaming.Seat.TryStart" },
}

local originals = {}
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
    T.truthy(owner[key] ~= originals[i].callback,
        metric .. " was not installed")
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

T.finish("pnc_profiler_follow_markers_smoke")
