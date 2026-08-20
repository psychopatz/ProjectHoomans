local T = require "tests/support/test"

PNC = {
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
T.equal(snapshot.breakdowns.dirtyMarksByReason.PATH_FAILED, 1,
    "dirty reason breakdown")

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
Diagnostics.Increment("Pathing.PathPumps", 3)
T.truthy(Diagnostics.Export(api), "second export")
T.equal(
    rates["ProjectHoomans.Scaling.Pathing.PathPumps.Rate"],
    3,
    "counter delta exported as rate"
)

T.finish("pnc_performance_scaling_diagnostics_smoke")
