-- Cheap, always-available growth diagnostics for long-running simulations.
-- Hot paths only mutate scalar counters. Table scans happen from the profiler
-- sampler or an explicit Snapshot request, never from ordinary event logging.

PNC = PNC or {}
PNC.PerformanceScalingDiagnostics =
    PNC.PerformanceScalingDiagnostics or {}

local Diagnostics = PNC.PerformanceScalingDiagnostics
Diagnostics.Internal = Diagnostics.Internal or {}

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
Diagnostics.SleepAuditEnabled = false
Diagnostics.FollowerPresenceAuditEnabled = false
Diagnostics.FollowerAbandonmentAuditEnabled = false
Diagnostics.InventoryAuditEnabled = false
Diagnostics.NeedsAuditEnabled = false
-- Zombie pursuit tracing is opt-in because it can emit from both the
-- authoritative update loop and the multiplayer receive path.
Diagnostics.ZombieAggroAuditEnabled = false
-- NPC threat tracing is opt-in. It samples threat acquisition, group alerts,
-- target retention, and combat/path handoff without adding hot-path logging
-- to normal sessions.
Diagnostics.NPCThreatAuditEnabled = false
-- Firearm tracing is opt-in. It is intentionally disabled on a normal load
-- because it assembles per-shot fields and can produce substantial console
-- traffic during firefights.
Diagnostics.FirearmAuditEnabled = false
-- Server payload sizing is opt-in. When enabled it logs one bounded line per
-- guarded server send with the estimated bytes per top-level section, which is
-- how an over-budget command is attributed to its owner.
Diagnostics.NetworkPayloadAuditEnabled = false
-- Build pipeline tracing. Off by default: every call site guards on
-- Diagnostics.BuildAuditEnabled before assembling fields, so the disabled path
-- costs one boolean read. When enabled it emits one line per build stage with
-- a correlation id and millisecond stamps, which is how a build that opens a
-- selector, cursor or overlay and then silently vanishes is attributed to the
-- stage that tore it down.
Diagnostics.BuildAuditEnabled = false
-- Native handoff tracing is opt-in. It logs only suspicious native movement
-- boundaries, not every frame, so the normal disabled path remains a boolean
-- read at the callers.
Diagnostics.NativeHandoffAuditEnabled = false
Diagnostics.BuildTraceSequence = tonumber(Diagnostics.BuildTraceSequence) or 0
Diagnostics.BuildTraceSentAt = Diagnostics.BuildTraceSentAt or {}
Diagnostics.BuildTraceReceivedAt = Diagnostics.BuildTraceReceivedAt or {}
Diagnostics.SeatingSessionSequence =
    tonumber(Diagnostics.SeatingSessionSequence) or 0

-- Debug settings are registered by a dedicated provider after the
-- diagnostics state table exists and before counters are initialized.
require "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_Settings"

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
    "ZombieAggro.Behavior2PathRequests",
    "ZombieAggro.CharacterPathRequests",
    "ZombieAggro.Behavior2FallbackRequests",
    "ZombieAggro.StimulusEmitted",
    "ZombieAggro.StimulusNetworkedEmitted",
    "ZombieAggro.StimulusLocalEmitted",
    "ZombieAggro.StimulusSuppressedStealth",
    "ZombieAggro.StimulusUnavailable",
    "ZombieAggro.StimulusUselessReactivated",
    "ZombieAggro.StimulusSoundProbes",
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
    "Network.PayloadBudgetRejected",
    "Network.PayloadBudgetSends",
    "Network.PayloadChunkSends",
    "Network.PayloadChunkRebuilds",
}

for _, name in ipairs(COUNTER_NAMES) do
    if Diagnostics.Counters[name] == nil then
        Diagnostics.Counters[name] = 0
    end
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

Diagnostics.Internal.TimingNow = timingNow

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

function Diagnostics.IsNativeHandoffAuditEnabled()
    return Diagnostics.NativeHandoffAuditEnabled == true
end

-- This is deliberately a bounded event log. Callers should invoke it only at
-- ownership boundaries or when WalkToward/path2 is already suspicious; the
-- function itself still rechecks the setting for isolated callers/tests.
function Diagnostics.LogNativeHandoff(
    record,
    body,
    eventName,
    source,
    navigation,
    extra
)
    local engineState
    local actionState
    local hasPath
    local moving
    local fields
    local message
    if Diagnostics.NativeHandoffAuditEnabled ~= true then return false end
    navigation = navigation or record and record.runtime
        and record.runtime.localNavigation or nil
    engineState = body and body.getCurrentStateName
        and string.lower(tostring(body:getCurrentStateName() or "")) or ""
    actionState = body and body.getActionStateName
        and string.lower(tostring(body:getActionStateName() or "")) or ""
    hasPath = body and body.getPath2 and body:getPath2() ~= nil or false
    moving = body and body.isMoving and body:isMoving() == true or false
    fields = {
        "native_handoff",
        "event=" .. tostring(eventName or "unknown"),
        "source=" .. tostring(source or "unknown"),
        "npc=" .. tostring(record and record.id or "nil"),
        "state=" .. tostring(engineState ~= "" and engineState or "unknown"),
        "action=" .. tostring(actionState ~= "" and actionState or "idle"),
        "path2=" .. tostring(hasPath),
        "moving=" .. tostring(moving),
        "nativeActive=" .. tostring(navigation
            and navigation.nativeActive == true),
        "controller=" .. tostring(navigation
            and navigation.controllerMode or ""),
        "revision=" .. tostring(navigation
            and navigation.requestRevision or ""),
        "requestPending=" .. tostring(navigation
            and navigation.requestPending == true),
        "at=" .. tostring(PNC.Core and PNC.Core.Now
            and PNC.Core.Now() or 0),
    }
    if extra and extra ~= "" then fields[#fields + 1] = tostring(extra) end
    message = table.concat(fields, " ")
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(message)
    else
        print("[PNC][INFO] " .. message)
    end
    return true
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

function Diagnostics.SetSleepAuditEnabled(enabled)
    Diagnostics.SleepAuditEnabled = enabled == true
    if Diagnostics.SleepAuditEnabled == true then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("sleep_audit event=enabled")
        else
            print("[PNC][INFO] sleep_audit event=enabled")
        end
    end
    return Diagnostics.SleepAuditEnabled
end

function Diagnostics.IsSleepAuditEnabled()
    return Diagnostics.SleepAuditEnabled == true
end

function Diagnostics.SetInventoryAuditEnabled(enabled)
    Diagnostics.InventoryAuditEnabled = enabled == true
    if Diagnostics.InventoryAuditEnabled == true then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("inventory_audit event=enabled")
        else
            print("[PNC][INFO] inventory_audit event=enabled")
        end
    end
    return Diagnostics.InventoryAuditEnabled
end

function Diagnostics.IsInventoryAuditEnabled()
    return Diagnostics.InventoryAuditEnabled == true
end

function Diagnostics.SetNeedsAuditEnabled(enabled)
    Diagnostics.NeedsAuditEnabled = enabled == true
    if Diagnostics.NeedsAuditEnabled == true then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("needs_audit event=enabled")
        else
            print("[PNC][INFO] needs_audit event=enabled")
        end
    end
    return Diagnostics.NeedsAuditEnabled
end

function Diagnostics.IsNeedsAuditEnabled()
    return Diagnostics.NeedsAuditEnabled == true
end

function Diagnostics.SetZombieAggroAuditEnabled(enabled)
    Diagnostics.ZombieAggroAuditEnabled = enabled == true
    if Diagnostics.ZombieAggroAuditEnabled == true then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("ZombieAggro.audit event=enabled")
        else
            print("[PNC][INFO] ZombieAggro.audit event=enabled")
        end
    end
    return Diagnostics.ZombieAggroAuditEnabled
end

function Diagnostics.IsZombieAggroAuditEnabled()
    return Diagnostics.ZombieAggroAuditEnabled == true
end

function Diagnostics.SetNPCThreatAuditEnabled(enabled)
    Diagnostics.NPCThreatAuditEnabled = enabled == true
    if Diagnostics.NPCThreatAuditEnabled == true then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("npc_threat_audit event=enabled")
        else
            print("[PNC][INFO] npc_threat_audit event=enabled")
        end
    end
    return Diagnostics.NPCThreatAuditEnabled
end

function Diagnostics.IsNPCThreatAuditEnabled()
    return Diagnostics.NPCThreatAuditEnabled == true
end

function Diagnostics.SetFirearmAuditEnabled(enabled)
    Diagnostics.FirearmAuditEnabled = enabled == true
    if Diagnostics.FirearmAuditEnabled == true then
        if PNC.Core and PNC.Core.LogInfo then
            PNC.Core.LogInfo("firearm_audit event=enabled")
        else
            print("[PNC][INFO] firearm_audit event=enabled")
        end
    end
    return Diagnostics.FirearmAuditEnabled
end

function Diagnostics.IsFirearmAuditEnabled()
    return Diagnostics.FirearmAuditEnabled == true
end

require "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_Runtime"
require "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_AuditLogging"
require "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics_InventoryAudit"

return Diagnostics
