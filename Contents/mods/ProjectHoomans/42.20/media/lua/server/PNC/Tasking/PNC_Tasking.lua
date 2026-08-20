if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Tasking/PNC_TaskPriority"
require "PNC/Tasking/PNC_TaskIntent"
require "PNC/Tasking/PNC_TaskLeaseService"

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics

Tasking.Commands = Tasking.Commands or {}
Tasking.Queries = Tasking.Queries or {}
Tasking.Events = Tasking.Events or {}
Tasking.Providers = Tasking.Providers or {}
Tasking.Executors = Tasking.Executors or {}
Tasking.Dirty = Tasking.Dirty or { queue = {}, byNPC = {} }
Tasking.Diagnostics = Tasking.Diagnostics or { byNPC = {}, counters = {
    reevaluations = 0, candidates = 0, preemptions = 0,
    facilityLookups = 0, executorTicks = 0 } }
Tasking.MAX_REEVALUATIONS_PER_PUMP = 8
Tasking.MAX_EXECUTOR_TICKS_PER_PUMP = 16
Tasking.PUMP_INTERVAL_MS = 250
Tasking.NextPumpAt = Tasking.NextPumpAt or 0
Tasking.ExecutorCursor = Tasking.ExecutorCursor or 0

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

function Tasking.Commands.RegisterProvider(domain, provider)
    domain = tostring(domain or "")
    if domain == "" or type(provider) ~= "table"
        or type(provider.GetCandidates) ~= "function"
        or type(provider.Validate) ~= "function"
        or type(provider.Assign) ~= "function"
    then return false, "INVALID_TASK_PROVIDER" end
    Tasking.Providers[domain] = provider
    return true, provider
end

function Tasking.Commands.RegisterExecutor(mode, executor)
    mode = string.upper(tostring(mode or ""))
    if mode == "" or type(executor) ~= "table"
        or type(executor.Tick) ~= "function"
    then return false, "INVALID_TASK_EXECUTOR" end
    Tasking.Executors[mode] = executor
    return true, executor
end

function Tasking.Commands.MarkDirty(npcId, cause)
    npcId = tostring(npcId or "")
    if npcId == "" then return false end
    local pending = Tasking.Dirty.byNPC[npcId]
    cause = tostring(cause or (pending and pending.cause) or "unspecified")
    if ScalingDiagnostics then
        ScalingDiagnostics.RecordDirtyMark(cause)
    end
    if pending then
        pending.cause = cause
        if ScalingDiagnostics then
            ScalingDiagnostics.Increment(
                "NPCDecisions.DirtyMarksDeduplicated"
            )
        end
        return true
    end
    local entry = { npcId = npcId, cause = cause }
    Tasking.Dirty.byNPC[npcId] = entry
    Tasking.Dirty.queue[#Tasking.Dirty.queue + 1] = entry
    return true
end

local function collect(record)
    local candidates = {}
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.CandidateBuilds")
    end
    for domain, provider in pairs(Tasking.Providers) do
        local ok, values = pcall(provider.GetCandidates, record.id)
        if ok then
            for _, value in ipairs(type(values) == "table" and values or {}) do
                local intent = PNC.TaskIntent.Normalize(value)
                if intent then
                    local valid = provider.Validate(intent)
                    if valid == true then candidates[#candidates + 1] = intent end
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return Priority.Compare(a, b) > 0 end)
    return candidates
end

local function stopLease(lease, reason)
    local provider = Tasking.Providers[lease.sourceDomain]
    if provider and provider.Cancel then provider.Cancel(lease, reason) end
    Leases.Release(lease.leaseId, reason)
end

local function externalCurrent(record)
    if record and record.runtime and record.runtime.workOrderId then
        return { taskId = "work:" .. tostring(record.runtime.workOrderId),
            precedence = "NORMAL_WORK", urgency = 0.5,
            phase = record.orderSpec and record.orderSpec.phase == "COMMIT"
                and "ATOMIC_COMMIT" or "WORKING" }
    end
    local kind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    if kind ~= "" and kind ~= "colony_home"
        and kind ~= tostring(PNC.Const and PNC.Const.ORDER_GUARD or "guard")
        and kind ~= "facility_activity"
    then
        return { taskId = "order:" .. kind, precedence = "FORCED_ORDER",
            urgency = 0.5, phase = "WORKING" }
    end
    return nil
end

function Tasking.Commands.Reevaluate(npcId, cause)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId)
    local diagnostics = { lastCause = tostring(cause or "manual"), candidates = {} }
    Tasking.Diagnostics.byNPC[tostring(npcId)] = diagnostics
    Tasking.Diagnostics.counters.reevaluations =
        Tasking.Diagnostics.counters.reevaluations + 1
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.DecisionRuns")
    end
    if not record or record.alive == false then
        local existing = Leases.ForNPC(npcId)
        if existing then stopLease(existing, "npc_unavailable") end
        diagnostics.lastReason = "NPC_UNAVAILABLE"
        return false, diagnostics.lastReason
    end
    local current = Leases.ForNPC(npcId)
    local previousTaskId = current and current.taskId or nil
    if current then
        local provider = Tasking.Providers[current.sourceDomain]
        local canContinue = provider and provider.CanContinue
            and provider.CanContinue(current) == true
        if not canContinue then
            stopLease(current, "task_invalidated"); current = nil
        end
    end
    local candidates = collect(record)
    Tasking.Diagnostics.counters.candidates =
        Tasking.Diagnostics.counters.candidates + #candidates
    for _, intent in ipairs(candidates) do
        diagnostics.candidates[#diagnostics.candidates + 1] = copy(intent)
    end
    local winner = candidates[1]
    if not winner then diagnostics.lastReason = current and "CURRENT_ONLY" or "NO_CANDIDATE"; return current ~= nil end
    if current and current.taskId == winner.taskId then
        current.urgency, current.precedence = winner.urgency, winner.precedence
        if ScalingDiagnostics then
            ScalingDiagnostics.Increment(
                "NPCDecisions.SameTaskReselections"
            )
        end
        diagnostics.lastReason = "CURRENT_TASK_CONTINUES"; return true, current
    end
    if current then
        local allowed, reason = Priority.CanPreempt(current, winner)
        if not allowed then diagnostics.lastReason = reason; return true, current end
        stopLease(current, "preempted")
        Tasking.Diagnostics.counters.preemptions =
            Tasking.Diagnostics.counters.preemptions + 1
    else
        local external = externalCurrent(record)
        if external then
            previousTaskId = external.taskId
            local allowed, reason = Priority.CanPreempt(external, winner)
            if not allowed then diagnostics.lastReason = reason; return false, reason end
            local released = PNC.WorkService and PNC.WorkService.Commands
                and PNC.WorkService.Commands.ReleaseWorker
                and PNC.WorkService.Commands.ReleaseWorker(record.id,
                    "task_preempted")
            if not released then diagnostics.lastReason = "PREEMPTION_FAILED"; return false, diagnostics.lastReason end
            Tasking.Diagnostics.counters.preemptions =
                Tasking.Diagnostics.counters.preemptions + 1
        end
    end
    local provider = Tasking.Providers[winner.sourceDomain]
    local assignment, reason = provider.Assign(winner)
    if not assignment then diagnostics.lastReason = reason or "ASSIGN_FAILED"; return false, diagnostics.lastReason end
    local lease, leaseReason = Leases.Create(winner, assignment)
    if not lease then
        if assignment.reservationId and PNC.FacilityReservations then
            PNC.FacilityReservations.Release(assignment.reservationId,
                "lease_creation_failed")
        end
        diagnostics.lastReason = leaseReason; return false, leaseReason
    end
    local started, startReason = provider.Start(lease, assignment)
    if started ~= true then
        Leases.Release(lease.leaseId, "start_failed")
        diagnostics.lastReason = startReason or "START_FAILED"
        return false, diagnostics.lastReason
    end
    diagnostics.lastReason, diagnostics.currentLeaseId = "ASSIGNED", lease.leaseId
    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.TaskAssignments")
        if previousTaskId and previousTaskId ~= winner.taskId then
            ScalingDiagnostics.Increment("NPCDecisions.TaskSwitches")
        end
    end
    return true, lease
end

function Tasking.Commands.Complete(leaseId, reason)
    local lease = Leases.Get(leaseId)
    if not lease then return false, "LEASE_NOT_FOUND" end
    local provider = Tasking.Providers[lease.sourceDomain]
    if provider and provider.Complete then provider.Complete(lease, reason) end
    return Leases.Release(leaseId, "complete")
end

function Tasking.Commands.CancelForNPC(npcId, reason)
    local lease = Leases.ForNPC(npcId)
    if not lease then return false, "LEASE_NOT_FOUND" end
    stopLease(lease, reason or "cancelled")
    return true
end

function Tasking.Commands.SetPhase(npcId, phase)
    local lease = Leases.ForNPC(npcId)
    return lease and Leases.SetPhase(lease.leaseId, phase)
        or false, "LEASE_NOT_FOUND"
end

function Tasking.Commands.Pump(at, budget)
    at = tonumber(at) or PNC.Core.Now()
    if at < Tasking.NextPumpAt then return 0 end
    Tasking.NextPumpAt = at + Tasking.PUMP_INTERVAL_MS
    if Tasking.Initialized ~= true then
        Tasking.Initialized = true
        if PNC.Registry and PNC.Registry.ForEach then
            PNC.Registry.ForEach(function(record)
                if record and record.alive ~= false then
                    Tasking.Commands.MarkDirty(record.id, "TASKING_INITIALIZED")
                end
            end)
        end
    end
    local processed = 0
    local maximum = math.max(1, math.floor(tonumber(budget)
        or Tasking.MAX_REEVALUATIONS_PER_PUMP))
    while processed < maximum and #Tasking.Dirty.queue > 0 do
        local entry = table.remove(Tasking.Dirty.queue, 1)
        if Tasking.Dirty.byNPC[entry.npcId] == entry then
            Tasking.Dirty.byNPC[entry.npcId] = nil
            Tasking.Commands.Reevaluate(entry.npcId, entry.cause)
            processed = processed + 1
        end
    end
    local executorBudget = Tasking.MAX_EXECUTOR_TICKS_PER_PUMP
    local activeCount = #Leases.Active
    local executorSteps = math.min(activeCount, executorBudget)
    for _ = 1, executorSteps do
        if #Leases.Active <= 0 then break end
        Tasking.ExecutorCursor = (Tasking.ExecutorCursor % #Leases.Active) + 1
        local lease = Leases.Get(Leases.Active[Tasking.ExecutorCursor])
        local executor = lease and Tasking.Executors[lease.executionMode]
        if executor then executor.Tick(lease); Tasking.Diagnostics.counters.executorTicks = Tasking.Diagnostics.counters.executorTicks + 1 end
    end
    return processed
end

function Tasking.Queries.GetLease(npcId) return copy(Leases.ForNPC(npcId)) end
function Tasking.Queries.GetDiagnostics(npcId)
    return { npc = copy(Tasking.Diagnostics.byNPC[tostring(npcId or "")]),
        counters = copy(Tasking.Diagnostics.counters),
        dirtyQueueLength = #Tasking.Dirty.queue, leaseCount = Leases.Count() }
end

if Events and Events.OnTick and not Tasking.TickHookRegistered then
    Events.OnTick.Add(function() Tasking.Commands.Pump() end)
    Tasking.TickHookRegistered = true
end


require "PNC/Tasking/PNC_TaskExecutors"
require "PNC/Needs/PNC_NeedsTaskProvider"

return Tasking
