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
-- Preserve the legacy default when the core registry is unavailable (for
-- example, in an isolated smoke test). A real game session resolves this
-- through PsychopatzCore.DebugSettings during startup.
Diagnostics.Enabled = Diagnostics.Enabled ~= false
-- Runtime timing is sampled, rather than collected on every hot-path call.
-- Keep this enabled while diagnosing the current server stall; the sampler
-- only takes one sample per phase per second and summaries are rate-limited.
Diagnostics.TimingEnabled = Diagnostics.TimingEnabled ~= false
Diagnostics.TimingSampleIntervalMs =
    tonumber(Diagnostics.TimingSampleIntervalMs) or 1000
Diagnostics.RuntimeLogEnabled = Diagnostics.RuntimeLogEnabled ~= false
Diagnostics.RuntimeLogIntervalMs =
    tonumber(Diagnostics.RuntimeLogIntervalMs) or 10000
Diagnostics.NextRuntimeLogAt = tonumber(Diagnostics.NextRuntimeLogAt) or 0
Diagnostics.Timings = Diagnostics.Timings or {}
Diagnostics.TimingLastSampleAt = Diagnostics.TimingLastSampleAt or {}
-- Seating auditing is intentionally independent from the normal runtime
-- summaries. It is off by default and only runs when its startup setting is
-- active, or when an explicit emergency runtime override is used.
Diagnostics.SeatingAuditEnabled = false
Diagnostics.FollowerPresenceAuditEnabled = false
Diagnostics.FollowerAbandonmentAuditEnabled = false

local PERFORMANCE_SETTING_ID = "ProjectHoomans.PerformanceDiagnostics"
local SEATING_AUDIT_SETTING_ID = "ProjectHoomans.SeatingAudit"
local FOLLOWER_PRESENCE_AUDIT_SETTING_ID =
    "ProjectHoomans.FollowerPresenceAudit"
local FOLLOWER_ABANDONMENT_AUDIT_SETTING_ID =
    "ProjectHoomans.FollowerAbandonmentAudit"
local function initializeCentralDebugSettings()
    local settings = PsychopatzCore and PsychopatzCore.DebugSettings
    if not settings or type(settings.Register) ~= "function" then
        pcall(require, "PsychopatzCore/Debug/PsychopatzDebugSettings")
        settings = PsychopatzCore and PsychopatzCore.DebugSettings
    end
    if not settings or type(settings.Register) ~= "function" then return end
    settings.Register({
        id = PERFORMANCE_SETTING_ID,
        source = "Project Hoomans",
        order = 50,
        title = "Performance scaling diagnostics",
        description = "Enables counters, gauges, sampled timings, and summaries.",
        -- This is an existing diagnostic surface. Preserve its current
        -- behavior for existing installs; new diagnostic registrations should
        -- normally use defaultEnabled = false.
        defaultEnabled = true,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.Enabled = enabled == true
            Diagnostics.TimingEnabled = Diagnostics.Enabled
            Diagnostics.RuntimeLogEnabled = Diagnostics.Enabled
        end,
    })
    settings.Register({
        id = SEATING_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 100,
        title = "Seating threat audit",
        description = "Captures seated threat, scene, path, and bump handoffs.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SeatingAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = FOLLOWER_PRESENCE_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 110,
        title = "Follower presence audit",
        description = "Logs abstract/live follower transitions and movement.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.FollowerPresenceAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = FOLLOWER_ABANDONMENT_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 120,
        title = "Follower abandonment audit",
        description = "Logs follow combat departure and return commentary.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.FollowerAbandonmentAuditEnabled = enabled == true
        end,
    })
    Diagnostics.Enabled = settings.IsEnabled(PERFORMANCE_SETTING_ID) == true
    Diagnostics.TimingEnabled = Diagnostics.Enabled
        and Diagnostics.TimingEnabled ~= false
    Diagnostics.RuntimeLogEnabled = Diagnostics.Enabled
        and Diagnostics.RuntimeLogEnabled ~= false
    -- The registry applies these two cheap diagnostic gates at startup or
    -- after an explicit Debug Settings Apply action. Direct callers can still
    -- use SetSeatingAuditEnabled as a temporary emergency runtime override.
    Diagnostics.SeatingAuditEnabled = settings.IsEnabled(
        SEATING_AUDIT_SETTING_ID) == true
    Diagnostics.FollowerPresenceAuditEnabled = settings.IsEnabled(
        FOLLOWER_PRESENCE_AUDIT_SETTING_ID) == true
    Diagnostics.FollowerAbandonmentAuditEnabled = settings.IsEnabled(
        FOLLOWER_ABANDONMENT_AUDIT_SETTING_ID) == true
end

initializeCentralDebugSettings()

local COUNTER_NAMES = {
    "Pathing.PathRequests",
    "Pathing.EnginePathRequests",
    "Pathing.PathPumps",
    "Pathing.LogicalAdvances",
    "Pathing.DuplicatePumpSameFrame",
    "Pathing.NativeFallbacks",
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
    if Diagnostics.Enabled ~= true then return 0 end
    name = tostring(name or "")
    if name == "" then return 0 end
    Diagnostics.Counters[name] =
        (tonumber(Diagnostics.Counters[name]) or 0)
        + (tonumber(amount) or 1)
    return Diagnostics.Counters[name]
end

function Diagnostics.SetGauge(name, value)
    if Diagnostics.Enabled ~= true then return 0 end
    name = tostring(name or "")
    if name == "" then return 0 end
    Diagnostics.Gauges[name] = tonumber(value) or 0
    return Diagnostics.Gauges[name]
end

local function timingNow(fallback)
    if fallback ~= nil then return tonumber(fallback) or 0 end
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if getTimeInMillis then return tonumber(getTimeInMillis()) or 0 end
    return 0
end

-- Returns a timer token only when this phase is due for a sample. Callers can
-- use the nil fast path to avoid allocations and a second clock read.
function Diagnostics.BeginTiming(name, at)
    if Diagnostics.Enabled ~= true or Diagnostics.TimingEnabled ~= true then
        return nil, nil
    end
    name = tostring(name or "")
    if name == "" then return nil, nil end
    local current = timingNow(at)
    local last = Diagnostics.TimingLastSampleAt[name]
    if last ~= nil
        and current - last < Diagnostics.TimingSampleIntervalMs
    then
        return nil, nil
    end
    Diagnostics.TimingLastSampleAt[name] = current
    return name, timingNow()
end

local function timingState(name)
    local state = Diagnostics.Timings[name]
    if state then return state end
    state = {
        calls = 0, totalMs = 0, lastMs = 0, maxMs = 0,
        lastContext = nil, slowCalls = 0,
    }
    Diagnostics.Timings[name] = state
    return state
end

function Diagnostics.EndTiming(name, startedAt, context)
    if Diagnostics.Enabled ~= true or not name or startedAt == nil then return 0 end
    local elapsed = math.max(0, timingNow() - (tonumber(startedAt) or 0))
    local state = timingState(name)
    state.calls = state.calls + 1
    state.totalMs = state.totalMs + elapsed
    state.lastMs = elapsed
    state.maxMs = math.max(state.maxMs, elapsed)
    if context ~= nil then state.lastContext = tostring(context) end
    if elapsed >= 5 then state.slowCalls = state.slowCalls + 1 end
    return elapsed
end

function Diagnostics.SetRuntimeLoggingEnabled(enabled)
    Diagnostics.RuntimeLogEnabled = Diagnostics.Enabled == true
        and enabled == true
end

function Diagnostics.IsEnabled()
    return Diagnostics.Enabled == true
end

function Diagnostics.SetSeatingAuditEnabled(enabled)
    Diagnostics.SeatingAuditEnabled = enabled == true
    if Diagnostics.SeatingAuditEnabled == true then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("seating_audit event=enabled")
        else
            print("[PNC][INFO] seating_audit event=enabled")
        end
    end
    return Diagnostics.SeatingAuditEnabled
end

function Diagnostics.IsSeatingAuditEnabled()
    return Diagnostics.SeatingAuditEnabled == true
end

function Diagnostics.IsFollowerPresenceAuditEnabled()
    return Diagnostics.FollowerPresenceAuditEnabled == true
end

function Diagnostics.IsFollowerAbandonmentAuditEnabled()
    return Diagnostics.FollowerAbandonmentAuditEnabled == true
end

-- Callers guard this function before assembling fields. That keeps the
-- disabled path free of snapshots, clocks, tables, and string concatenation.
function Diagnostics.LogSeatingAudit(eventName, fields)
    local output
    if Diagnostics.SeatingAuditEnabled ~= true then return false end
    output = { "seating_audit", "event=" .. tostring(eventName or "unknown") }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    local message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

-- Follower presence auditing is intentionally separate from the general
-- performance and seating streams. Callers must check the gate before
-- assembling fields so disabled gameplay pays only a boolean check.
function Diagnostics.LogFollowerPresence(eventName, fields)
    local output
    if Diagnostics.FollowerPresenceAuditEnabled ~= true then return false end
    output = { "follower_presence", "event=" .. tostring(eventName or "unknown") }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    local message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

-- Callers guard this function before assembling fields so disabled gameplay
-- pays only a boolean check.
function Diagnostics.LogFollowerAbandonment(eventName, fields)
    local output
    if Diagnostics.FollowerAbandonmentAuditEnabled ~= true then return false end
    output = {
        "follower_abandonment",
        "event=" .. tostring(eventName or "unknown"),
    }
    for _, field in ipairs(fields or {}) do
        output[#output + 1] = tostring(field)
    end
    local message = table.concat(output, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

local function timingText(name)
    local state = Diagnostics.Timings[name]
    if not state or (tonumber(state.calls) or 0) <= 0 then
        return "-"
    end
    local calls = tonumber(state.calls) or 1
    return string.format("%.2f/%.2f/%.2f/%d",
        tonumber(state.lastMs) or 0,
        (tonumber(state.totalMs) or 0) / calls,
        tonumber(state.maxMs) or 0,
        calls)
end

local function boundedIDs(values, limit)
    local output = {}
    local seen = {}
    limit = tonumber(limit) or 8
    for _, value in ipairs(values or {}) do
        local id = tostring(value or "")
        if id ~= "" and not seen[id] and #output < limit then
            seen[id] = true
            output[#output + 1] = id
        end
    end
    return table.concat(output, ",")
end

function Diagnostics.LogRuntimeSummary(now)
    if Diagnostics.Enabled ~= true or Diagnostics.RuntimeLogEnabled ~= true then
        return false
    end
    now = timingNow(now)
    if now < Diagnostics.NextRuntimeLogAt then return false end
    Diagnostics.NextRuntimeLogAt = now + Diagnostics.RuntimeLogIntervalMs
    Diagnostics.RefreshGauges()

    local activeNPCs = {}
    local leases = PNC.TaskLeaseService
    for _, leaseID in ipairs(leases and leases.Active or {}) do
        local lease = leases.Get and leases.Get(leaseID) or nil
        if lease then activeNPCs[#activeNPCs + 1] = lease.npcId end
    end
    local provisionNPCs = {}
    for _, entry in ipairs(PNC.ProvisionScheduler
        and PNC.ProvisionScheduler.Queue or {}) do
        provisionNPCs[#provisionNPCs + 1] = entry.npcID
    end

    local fields = {
        "runtime_diag",
        "live=" .. tostring(Diagnostics.Gauges["Scheduler.LiveRecords"] or 0),
        "zombies=" .. tostring(Diagnostics.Gauges["ZombieAggro.LoadedZombieCount"] or 0),
        "leases=" .. tostring(Diagnostics.Gauges["Tasking.ActiveLeases"] or 0),
        "inbox=" .. tostring(Diagnostics.Gauges["Tasking.EventInboxSize"] or 0),
        "work=" .. tostring(Diagnostics.Gauges["Tasking.WorkOrderCount"] or 0),
        "provisionQueue=" .. tostring(Diagnostics.Gauges["Provision.QueueSize"] or 0),
        "leaseNPCs=" .. boundedIDs(activeNPCs),
        "provisionNPCs=" .. boundedIDs(provisionNPCs),
        "pathPumps=" .. tostring(
            Diagnostics.Counters["Pathing.PathPumps"] or 0
        ),
        "duplicatePathPumps=" .. tostring(
            Diagnostics.Counters["Pathing.DuplicatePumpSameFrame"] or 0
        ),
        "nativeFallbacks=" .. tostring(
            Diagnostics.Counters["Pathing.NativeFallbacks"] or 0
        ),
        "server=" .. timingText("Server.Update"),
        "prepare=" .. timingText("Server.Prepare"),
        "finish=" .. timingText("Server.Finish"),
        "record=" .. timingText("Server.ProcessRecord"),
        "tasking=" .. timingText("Tasking.Pump"),
        "domains=" .. table.concat({
            "work:" .. timingText("Tasking.Domain.work"),
            "NeedFacility:" .. timingText("Tasking.Domain.NeedFacility"),
            "farming:" .. timingText("Tasking.Domain.farming"),
            "fishing:" .. timingText("Tasking.Domain.fishing"),
            "lumber:" .. timingText("Tasking.Domain.lumber"),
            "scavenge:" .. timingText("Tasking.Domain.scavenge"),
        }, ","),
        "workTick=" .. timingText("WorkService.Tick"),
        "needs=" .. timingText("Needs.Pump"),
        "provisionAudit=" .. timingText("Provision.Audit"),
        "provisionProcess=" .. timingText("Provision.Process"),
        "census=" .. timingText("WorldCensus.Refresh"),
        "spatial=" .. timingText("Spatial.Rebuild"),
        "corpse=" .. timingText("CorpseHaul.Pump"),
    }
    local message = table.concat(fields, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
end

function Diagnostics.BeginFrame()
    if Diagnostics.Enabled ~= true then return Diagnostics.Frame end
    Diagnostics.Frame = Diagnostics.Frame + 1
    return Diagnostics.Frame
end

local function routeDiagnostics(record)
    local runtime = record and record.runtime or nil
    if not runtime then return nil end
    return runtime.pathing or runtime
end

function Diagnostics.RecordPathPump(record, caller)
    if Diagnostics.Enabled ~= true then return end
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
    if Diagnostics.Enabled ~= true then return end
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
    if Diagnostics.Enabled ~= true then return end
    Diagnostics.Increment("NPCDecisions.DirtyMarks")
    incrementMap(
        Diagnostics.Breakdowns.dirtyMarksByReason,
        reason,
        1,
        "dirtyMarksByReason"
    )
end

function Diagnostics.RefreshGauges()
    if Diagnostics.Enabled ~= true then return false end
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
    local leases = PNC.TaskLeaseService
    Diagnostics.SetGauge(
        "Tasking.ActiveLeases",
        leases and #leases.Active or 0
    )
    Diagnostics.SetGauge(
        "Tasking.EventInboxSize",
        tasking and tasking.Inbox and tasking.Inbox.Count
            and tasking.Inbox.Count() or 0
    )

    local provision = PNC.ProvisionScheduler
    Diagnostics.SetGauge(
        "Provision.QueueSize",
        provision and #provision.Queue or 0
    )
    Diagnostics.SetGauge(
        "Provision.QueuedLiveSize",
        provision and countMap(provision.Queued) or 0
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
    if Diagnostics.Enabled ~= true
        or not api or not api.SetGauge or not api.RecordRate
    then
        return false
    end
    Diagnostics.RefreshGauges()
    for name, value in pairs(Diagnostics.Counters) do
        exportCounter(api, name, tonumber(value) or 0)
    end
    for name, value in pairs(Diagnostics.Gauges) do
        api.SetGauge("ProjectHoomans.Scaling." .. name, value)
    end
    for name, state in pairs(Diagnostics.Timings) do
        local prefix = "ProjectHoomans.Scaling.Timing." .. name
        local calls = tonumber(state.calls) or 0
        api.SetGauge(prefix .. ".LastMs", tonumber(state.lastMs) or 0)
        api.SetGauge(prefix .. ".AverageMs",
            calls > 0 and (tonumber(state.totalMs) or 0) / calls or 0)
        api.SetGauge(prefix .. ".MaxMs", tonumber(state.maxMs) or 0)
        api.SetGauge(prefix .. ".Samples", calls)
        api.SetGauge(prefix .. ".SlowSamples", tonumber(state.slowCalls) or 0)
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
    if Diagnostics.Enabled ~= true then
        return {
            disabled = true,
            frame = Diagnostics.Frame,
            counters = {}, gauges = {}, breakdowns = {}, timings = {},
        }
    end
    Diagnostics.RefreshGauges()
    local breakdowns = {}
    local timings = {}
    for name, values in pairs(Diagnostics.Breakdowns) do
        breakdowns[name] = copyMap(values)
    end
    for name, state in pairs(Diagnostics.Timings) do
        timings[name] = copyMap(state)
    end
    return {
        frame = Diagnostics.Frame,
        counters = copyMap(Diagnostics.Counters),
        gauges = copyMap(Diagnostics.Gauges),
        breakdowns = breakdowns,
        timings = timings,
    }
end

return Diagnostics
