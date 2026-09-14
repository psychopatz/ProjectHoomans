local T = require "tests/support/test"

PNC = {
    Core = {},
    Registry = {
        Data = {
            live = {
                runtime = { pathing = { phase = "active" } },
            },
        },
    },
    WorldCensus = { OrdinaryZombies = { {}, {}, {} } },
    Scheduler = {
        SlotByID = { live = 10, other = 11 },
        PhysicalEntries = 5,
        DueBacklog = 2,
        OldestOverdueMs = 125,
    },
    ZombieAggro = {
        ActiveSet = {
            byID = { z1 = {}, z2 = {} },
            order = { "z1", false, "z2" },
            holes = 1,
        },
    },
    Tasking = {
        Dirty = {
            queue = { { npcId = "live" }, { npcId = "stale" } },
            byNPC = { live = {} },
        },
    },
    WorkRepository = {
        State = {
            byId = {
                a = { status = "WORKING", workerId = "live" },
                b = { status = "BLOCKED" },
            },
        },
    },
}

local clock = 1000
local logs = {}
PNC.Core.Now = function() return clock end
PNC.Core.LogInfo = function(message) logs[#logs + 1] = message end

local Diagnostics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics.lua"
)

T.equal(
    Diagnostics.Counters["LiveAbstract.AbstractPathRequests"],
    0,
    "safety counters start at zero"
)

local timerName, timerStart = Diagnostics.BeginTiming("test.phase", clock)
clock = 1007
Diagnostics.EndTiming(timerName, timerStart, "npc-test")

local record = { runtime = { pathing = { phase = "active" } } }
Diagnostics.BeginFrame()
Diagnostics.RecordPathPump(record, "scheduler")
Diagnostics.RecordPathPump(record, "zombie_update")
Diagnostics.RecordLogicalAdvance(record, "engine")
Diagnostics.RecordLogicalAdvance(record, "engine")
Diagnostics.RecordDirtyMark("PATH_FAILED")

local snapshot = Diagnostics.Snapshot()
T.equal(snapshot.gauges["Pathing.ActiveRoutes"], 1, "active routes")
T.equal(snapshot.gauges["ZombieAggro.LoadedZombieCount"], 3,
    "loaded zombies")
T.equal(snapshot.gauges["ZombieAggro.QueuePhysicalSize"], 3,
    "aggro physical queue")
T.equal(snapshot.gauges["ZombieAggro.QueueLiveSize"], 2,
    "aggro live queue")
T.equal(snapshot.gauges["Scheduler.LiveRecords"], 2,
    "scheduler live records")
T.equal(snapshot.gauges["Scheduler.PhysicalEntries"], 5,
    "scheduler physical entries")
T.near(snapshot.gauges["Scheduler.PhysicalToLiveRatio"], 2.5, 0.001,
    "scheduler physical to live ratio")
T.equal(snapshot.gauges["Tasking.DirtyQueueSize"], 2,
    "dirty physical queue")
T.equal(snapshot.gauges["Tasking.DirtyQueueLiveSize"], 1,
    "dirty live queue")
T.equal(snapshot.gauges["Tasking.WorkOrderCount"], 2,
    "work order count")
T.equal(snapshot.gauges["Tasking.ClaimedOrders"], 1,
    "claimed orders")
T.equal(snapshot.gauges["Tasking.BlockedOrders"], 1,
    "blocked orders")
T.equal(snapshot.counters["Pathing.DuplicatePumpSameFrame"], 1,
    "duplicate route pump")
T.equal(
    snapshot.counters["Pathing.DuplicateLogicalAdvanceSameFrame"],
    1,
    "duplicate logical advance"
)
T.falsy(Diagnostics.FirearmAuditEnabled, "firearm audit defaults off")
T.falsy(Diagnostics.InventoryAuditEnabled, "inventory audit defaults off")
T.falsy(Diagnostics.NeedsAuditEnabled, "needs audit defaults off")
T.equal(Diagnostics.LogInventoryAudit("disabled", { "unexpected=field" }),
    false, "disabled inventory audit emitted a log")
T.equal(Diagnostics.LogNeedsAudit("disabled", { "unexpected=field" }),
    false, "disabled needs audit emitted a log")
Diagnostics.SetInventoryAuditEnabled(true)
T.truthy(Diagnostics.LogInventoryAudit("mutation", {
    "npc=npc-test", "revisionBefore=1", "revisionAfter=2",
}), "inventory audit emitted")
T.contains(logs[#logs],
    "inventory_audit event=mutation npc=npc-test revisionBefore=1 revisionAfter=2",
    "inventory audit uses the dedicated log marker")
Diagnostics.SetNeedsAuditEnabled(true)
T.truthy(Diagnostics.LogNeedsAudit("changed", {
    "npc=npc-test", "need=thirst", "before=0.5", "after=0.0",
}), "needs audit emitted")
T.contains(logs[#logs],
    "needs_audit event=changed npc=npc-test need=thirst before=0.5 after=0.0",
    "needs audit uses the dedicated log marker")
Diagnostics.SetFirearmAuditEnabled(true)
T.truthy(Diagnostics.LogFirearmAudit("test_stage", {
    "side=authority",
    "shotId=test-shot",
}), "firearm audit emitted")
T.contains(logs[#logs], "firearm_audit event=test_stage side=authority shotId=test-shot",
    "firearm audit uses the dedicated log marker")
T.equal(snapshot.breakdowns.dirtyMarksByReason.PATH_FAILED, 1,
    "dirty reason breakdown")
T.equal(snapshot.timings["test.phase"].calls, 1, "timing sample count")
T.near(snapshot.timings["test.phase"].lastMs, 7, 0.001,
    "timing sample duration")
T.equal(snapshot.timings["test.phase"].lastContext, "npc-test",
    "timing context")

local gauges = {}
local rates = {}
local api = {
    SetGauge = function(name, value) gauges[name] = value end,
    RecordRate = function(name, value) rates[name] = value end,
}
T.truthy(Diagnostics.Export(api), "first export")
T.equal(
    gauges["ProjectHoomans.Scaling.Pathing.PathPumps.Total"],
    2,
    "exported path pump total"
)
T.equal(
    rates["ProjectHoomans.Scaling.Pathing.PathPumps.Rate"],
    0,
    "first export establishes rate baseline"
)
T.equal(gauges["ProjectHoomans.Scaling.Timing.test.phase.LastMs"], 7,
    "exported timing sample")
Diagnostics.Increment("Pathing.PathPumps", 3)
T.truthy(Diagnostics.Export(api), "second export")
T.equal(
    rates["ProjectHoomans.Scaling.Pathing.PathPumps.Rate"],
    3,
    "counter delta exported as rate"
)

T.finish("pnc_performance_scaling_diagnostics_smoke")
