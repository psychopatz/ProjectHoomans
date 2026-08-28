-- Stable tasking service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Tasking/PNC_TaskPriority"
require "PNC/Tasking/PNC_TaskIntent"
require "PNC/Tasking/PNC_TaskLeaseService"

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
Tasking.Commands = Tasking.Commands or {}
Tasking.Queries = Tasking.Queries or {}
Tasking.Events = Tasking.Events or {}
Tasking.Inbox = Tasking.Inbox or {}
Tasking.Providers = Tasking.Providers or {}
Tasking.Executors = Tasking.Executors or {}
Tasking.Internal = Tasking.Internal or {}
Tasking.Dirty = Tasking.Dirty or { queue = {}, byNPC = {} }
Tasking.Dirty.queue = Tasking.Dirty.queue or {}
Tasking.Dirty.byNPC = Tasking.Dirty.byNPC or {}
Tasking.Dirty.head = Tasking.Dirty.head or 1
Tasking.Dirty.tail = Tasking.Dirty.tail or #Tasking.Dirty.queue
Tasking.Dirty.pendingCount = Tasking.Dirty.pendingCount or 0
Tasking.Diagnostics = Tasking.Diagnostics or { byNPC = {}, counters = {
    reevaluations = 0, candidates = 0, preemptions = 0,
    facilityLookups = 0, executorTicks = 0 } }
Tasking.Diagnostics.byNPC = Tasking.Diagnostics.byNPC or {}
Tasking.Diagnostics.counters = Tasking.Diagnostics.counters or {}
Tasking.Diagnostics.recentFailures = Tasking.Diagnostics.recentFailures or {}
Tasking.Diagnostics.recentEvents = Tasking.Diagnostics.recentEvents or {}
Tasking.Diagnostics.counters.callbackFailures =
    Tasking.Diagnostics.counters.callbackFailures or 0
Tasking.Diagnostics.counters.executorFailures =
    Tasking.Diagnostics.counters.executorFailures or 0
Tasking.Diagnostics.counters.eventEmits =
    Tasking.Diagnostics.counters.eventEmits or 0
Tasking.Diagnostics.counters.eventCoalesces =
    Tasking.Diagnostics.counters.eventCoalesces or 0
Tasking.Diagnostics.counters.eventProcesses =
    Tasking.Diagnostics.counters.eventProcesses or 0
Tasking.Diagnostics.counters.eventRetries =
    Tasking.Diagnostics.counters.eventRetries or 0
Tasking.Diagnostics.counters.leaseTransitionFailures =
    Tasking.Diagnostics.counters.leaseTransitionFailures or 0
Tasking.Diagnostics.counters.candidateTruncations =
    Tasking.Diagnostics.counters.candidateTruncations or 0
Tasking.MAX_REEVALUATIONS_PER_PUMP = 8
Tasking.MAX_EXECUTOR_TICKS_PER_PUMP = 16
Tasking.MAX_CANDIDATES_PER_PROVIDER = 64
Tasking.PUMP_INTERVAL_MS = 250
Tasking.NextPumpAt = Tasking.NextPumpAt or 0
Tasking.ExecutorCursor = Tasking.ExecutorCursor or 0
Tasking.ORPHAN_RECONCILE_INTERVAL_MS = 5000
Tasking.NextOrphanReconcileAt = Tasking.NextOrphanReconcileAt or 0

require "PNC/Tasking/Tasking/PNC_Tasking_Core"
require "PNC/Tasking/Tasking/PNC_Tasking_EventInbox"
require "PNC/Tasking/Tasking/PNC_Tasking_Assignment"
require "PNC/Tasking/Tasking/PNC_Tasking_Evaluation"
require "PNC/Tasking/Tasking/PNC_Tasking_Lifecycle"
require "PNC/Tasking/Tasking/PNC_Tasking_Pump"
require "PNC/Tasking/Tasking/PNC_Tasking_Queries"

if Events and Events.OnTick and not Tasking.TickHookRegistered then
    Events.OnTick.Add(function() Tasking.Commands.Pump() end)
    Tasking.TickHookRegistered = true
end

require "PNC/Tasking/PNC_TaskExecutors"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers"

return Tasking
