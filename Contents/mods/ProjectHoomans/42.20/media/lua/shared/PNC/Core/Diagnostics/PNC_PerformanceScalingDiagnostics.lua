-- Cheap, always-available growth diagnostics for long-running simulations.
-- Hot paths only mutate scalar counters. Table scans happen from the profiler
-- sampler or an explicit Snapshot request, never from ordinary event logging.

PNC = PNC or {}
PNC.PerformanceScalingDiagnostics =
    PNC.PerformanceScalingDiagnostics or {}

local Diagnostics = PNC.PerformanceScalingDiagnostics

Diagnostics.Counters = Diagnostics.Counters or {}
Diagnostics.Gauges = Diagnostics.Gauges or {}
Diagnostics.Breakdowns = Diagnostics.Breakdowns or {
    pathPumpsByCaller = {},
    logicalAdvancesByCaller = {},
    dirtyMarksByReason = {},
}
Diagnostics.BreakdownSizes = Diagnostics.BreakdownSizes or {}
Diagnostics.LastExported = Diagnostics.LastExported or {}
Diagnostics.Frame = tonumber(Diagnostics.Frame) or 0
Diagnostics.MAX_BREAKDOWN_KEYS = 64

local COUNTER_NAMES = {
    "Pathing.PathRequests",
    "Pathing.EnginePathRequests",
    "Pathing.PathPumps",
    "Pathing.LogicalAdvances",
    "Pathing.DuplicatePumpSameFrame",
    "Pathing.DuplicateLogicalAdvanceSameFrame",
    "Pathing.Replans",
    "Pathing.Retries",
    "Pathing.Timeouts",
    "Pathing.BlockedRoutes",
    "Pathing.CompletedRoutes",
    "Pathing.FailedRoutes",
    "ZombieAggro.AggroRefreshes",
    "ZombieAggro.RefreshNPCs",
    "ZombieAggro.CandidateQueries",
    "ZombieAggro.CandidateCount",
    "ZombieAggro.ProcessedCount",
    "ZombieAggro.Compactions",
    "ZombieAggro.PathRequests",
    "ZombieAggro.PathRequestsDeferred",
    "Scheduler.Reschedules",
    "Scheduler.StaleSkipped",
    "Scheduler.DueProcessed",
    "Scheduler.Deferred",
    "NPCDecisions.DirtyMarks",
    "NPCDecisions.DirtyMarksDeduplicated",
    "NPCDecisions.DecisionRuns",
    "NPCDecisions.CandidateBuilds",
    "NPCDecisions.TaskAssignments",
    "NPCDecisions.TaskSwitches",
    "NPCDecisions.SameTaskReselections",
    "NPCDecisions.BehaviorTicks",
    "NPCDecisions.BehaviorJobSwitches",
    "NPCDecisions.BehaviorSameJobReselections",
    "LiveAbstract.AbstractPathRequests",
    "LiveAbstract.AbstractAggroQueries",
    "LiveAbstract.AbstractBodyUpdates",
    "LiveAbstract.AbstractPhysicalTraversal",
    "LiveAbstract.ManagedBodyUpdates",
    "Spatial.ZombieCandidateQueries",
    "Spatial.ZombieCellsExamined",
    "Spatial.ZombieCandidatesReturned",
    "Spatial.ZombieResultTables",
    "UI.NameplateUpdateCalls",
    "UI.NameplateRefreshes",
    "UI.LoadedZombieScans",
    "UI.LoadedZombiesScanned",
    "UI.BodyIndexRebuilds",
    "UI.BodyIndexZombiesScanned",
    "UI.NameplateEntryBuilds",
    "UI.NameplateRenderCalls",
    "UI.NameplateEntriesRendered",
}

for _, name in ipairs(COUNTER_NAMES) do
    if Diagnostics.Counters[name] == nil then
        Diagnostics.Counters[name] = 0
    end
end

local function countMap(values)
    local count = 0
    for _, _ in pairs(values or {}) do
        count = count + 1
    end
    return count
end

local function incrementMap(values, key, amount, sizeKey)
    key = tostring(key or "unspecified")
    if values[key] == nil then
        local size = tonumber(Diagnostics.BreakdownSizes[sizeKey]) or 0
        if size >= Diagnostics.MAX_BREAKDOWN_KEYS then
            key = "other"
        else
            Diagnostics.BreakdownSizes[sizeKey] = size + 1
        end
    end
    values[key] = (tonumber(values[key]) or 0) + (tonumber(amount) or 1)
end

function Diagnostics.Increment(name, amount)
    name = tostring(name or "")
    if name == "" then return 0 end
    Diagnostics.Counters[name] =
        (tonumber(Diagnostics.Counters[name]) or 0)
        + (tonumber(amount) or 1)
    return Diagnostics.Counters[name]
end

function Diagnostics.SetGauge(name, value)
    name = tostring(name or "")
    if name == "" then return 0 end
    Diagnostics.Gauges[name] = tonumber(value) or 0
    return Diagnostics.Gauges[name]
end

function Diagnostics.BeginFrame()
    Diagnostics.Frame = Diagnostics.Frame + 1
    return Diagnostics.Frame
end

local function routeDiagnostics(record)
    local runtime = record and record.runtime or nil
    if not runtime then return nil end
    return runtime.pathing or runtime
end

function Diagnostics.RecordPathPump(record, caller)
    Diagnostics.Increment("Pathing.PathPumps")
    incrementMap(
        Diagnostics.Breakdowns.pathPumpsByCaller,
        caller,
        1,
        "pathPumpsByCaller"
    )
    local state = routeDiagnostics(record)
    if state then
        if state.diagnosticLastPumpFrame == Diagnostics.Frame then
            Diagnostics.Increment("Pathing.DuplicatePumpSameFrame")
        end
        state.diagnosticLastPumpFrame = Diagnostics.Frame
    end
end

function Diagnostics.RecordLogicalAdvance(record, caller)
    Diagnostics.Increment("Pathing.LogicalAdvances")
    incrementMap(
        Diagnostics.Breakdowns.logicalAdvancesByCaller,
        caller,
        1,
        "logicalAdvancesByCaller"
    )
    local state = routeDiagnostics(record)
    if state then
        if state.diagnosticLastLogicalAdvanceFrame == Diagnostics.Frame then
            Diagnostics.Increment(
                "Pathing.DuplicateLogicalAdvanceSameFrame"
            )
        end
        state.diagnosticLastLogicalAdvanceFrame = Diagnostics.Frame
    end
end

function Diagnostics.RecordDirtyMark(reason)
    Diagnostics.Increment("NPCDecisions.DirtyMarks")
    incrementMap(
        Diagnostics.Breakdowns.dirtyMarksByReason,
        reason,
        1,
        "dirtyMarksByReason"
    )
end

function Diagnostics.RefreshGauges()
    local registry = PNC.Registry
    local scheduler = PNC.Scheduler
    local aggro = PNC.ZombieAggro and PNC.ZombieAggro.ActiveSet or nil
    local tasking = PNC.Tasking
    local work = PNC.WorkRepository
    local activeRoutes = 0
    local workOrders = 0
    local claimedOrders = 0
    local blockedOrders = 0

    for _, record in pairs(registry and registry.Data or {}) do
        local lane = record and record.runtime
            and record.runtime.pathing or nil
        if lane and (lane.phase == "requested" or lane.phase == "active") then
            activeRoutes = activeRoutes + 1
        end
    end
    Diagnostics.SetGauge("Pathing.ActiveRoutes", activeRoutes)

    Diagnostics.SetGauge(
        "ZombieAggro.LoadedZombieCount",
        #(PNC.WorldCensus and PNC.WorldCensus.OrdinaryZombies or {})
    )
    Diagnostics.SetGauge(
        "ZombieAggro.ActiveCount",
        aggro and countMap(aggro.byID) or 0
    )
    Diagnostics.SetGauge(
        "ZombieAggro.QueuePhysicalSize",
        aggro and #aggro.order or 0
    )
    Diagnostics.SetGauge(
        "ZombieAggro.QueueLiveSize",
        aggro and countMap(aggro.byID) or 0
    )
    Diagnostics.SetGauge(
        "ZombieAggro.QueueHoles",
        aggro and (tonumber(aggro.holes) or 0) or 0
    )

    Diagnostics.SetGauge(
        "Scheduler.LiveRecords",
        countMap(scheduler and scheduler.SlotByID)
    )
    Diagnostics.SetGauge(
        "Scheduler.PhysicalEntries",
        scheduler and (tonumber(scheduler.PhysicalEntries) or 0) or 0
    )
    local schedulerLive = Diagnostics.Gauges["Scheduler.LiveRecords"] or 0
    local schedulerPhysical =
        Diagnostics.Gauges["Scheduler.PhysicalEntries"] or 0
    Diagnostics.SetGauge(
        "Scheduler.PhysicalToLiveRatio",
        schedulerLive > 0 and schedulerPhysical / schedulerLive
            or (schedulerPhysical > 0 and schedulerPhysical or 0)
    )
    Diagnostics.SetGauge(
        "Scheduler.DueBacklog",
        scheduler and (tonumber(scheduler.DueBacklog) or 0) or 0
    )
    Diagnostics.SetGauge(
        "Scheduler.OldestOverdueMs",
        scheduler and (tonumber(scheduler.OldestOverdueMs) or 0) or 0
    )

    Diagnostics.SetGauge(
        "Tasking.DirtyQueueSize",
        tasking and tasking.Dirty and #tasking.Dirty.queue or 0
    )
    Diagnostics.SetGauge(
        "Tasking.DirtyQueueLiveSize",
        tasking and tasking.Dirty and countMap(tasking.Dirty.byNPC) or 0
    )

    for _, order in pairs(
        work and work.State and work.State.byId or {}
    ) do
        workOrders = workOrders + 1
        if order and order.workerId ~= nil then
            claimedOrders = claimedOrders + 1
        end
        if order and order.status == "BLOCKED" then
            blockedOrders = blockedOrders + 1
        end
    end
    Diagnostics.SetGauge("Tasking.WorkOrderCount", workOrders)
    Diagnostics.SetGauge("Tasking.ClaimedOrders", claimedOrders)
    Diagnostics.SetGauge("Tasking.BlockedOrders", blockedOrders)
end

local function metricPart(value)
    value = string.gsub(tostring(value or "unspecified"), "[^%w]+", "_")
    if #value > 48 then value = string.sub(value, 1, 48) end
    return value ~= "" and value or "unspecified"
end

local function exportCounter(api, name, value)
    local metric = "ProjectHoomans.Scaling." .. name
    local previous = Diagnostics.LastExported[name]
    api.SetGauge(metric .. ".Total", value)
    api.RecordRate(
        metric .. ".Rate",
        previous == nil and 0 or math.max(0, value - previous)
    )
    Diagnostics.LastExported[name] = value
end

function Diagnostics.Export(api)
    if not api or not api.SetGauge or not api.RecordRate then return false end
    Diagnostics.RefreshGauges()
    for name, value in pairs(Diagnostics.Counters) do
        exportCounter(api, name, tonumber(value) or 0)
    end
    for name, value in pairs(Diagnostics.Gauges) do
        api.SetGauge("ProjectHoomans.Scaling." .. name, value)
    end
    for breakdown, values in pairs(Diagnostics.Breakdowns) do
        for key, value in pairs(values) do
            exportCounter(
                api,
                "Breakdown." .. metricPart(breakdown)
                    .. "." .. metricPart(key),
                tonumber(value) or 0
            )
        end
    end
    return true
end

local function copyMap(values)
    local output = {}
    for key, value in pairs(values or {}) do output[key] = value end
    return output
end

function Diagnostics.Snapshot()
    Diagnostics.RefreshGauges()
    local breakdowns = {}
    for name, values in pairs(Diagnostics.Breakdowns) do
        breakdowns[name] = copyMap(values)
    end
    return {
        frame = Diagnostics.Frame,
        counters = copyMap(Diagnostics.Counters),
        gauges = copyMap(Diagnostics.Gauges),
        breakdowns = breakdowns,
    }
end

return Diagnostics
