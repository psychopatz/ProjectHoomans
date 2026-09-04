if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal
local providerDiagnosticCache = {}
local PROVIDER_DIAGNOSTICS_CACHE_MS = 1000

function Tasking.Queries.GetLease(npcId) return H.Copy(Leases.ForNPC(npcId)) end

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function providerDiagnostics(npcId)
    npcId = tostring(npcId or "")
    local at = now()
    local cached = providerDiagnosticCache[npcId]
    if cached and at - cached.at < PROVIDER_DIAGNOSTICS_CACHE_MS then
        return H.Copy(cached.value)
    end
    local output = {}
    for providerID, provider in pairs(Tasking.Providers or {}) do
        if type(provider.GetDiagnostics) == "function" then
            local context = { npcId = npcId, domain = providerID }
            local ok, report, reason = H.SafeCall(
                "provider_get_diagnostics", provider.GetDiagnostics,
                context, npcId)
            if ok and type(report) == "table" then
                output[providerID] = H.Copy(report)
            else
                output[providerID] = {
                    unavailable = reason or "PROVIDER_DIAGNOSTICS_FAILED",
                }
            end
        end
    end
    providerDiagnosticCache[npcId] = { at = at, value = H.Copy(output) }
    return output
end

local function sourceRevision(item)
    local domain = tostring(item and item.sourceDomain or "")
    local sourceRef = item and item.sourceRef
    if domain == "work" and PNC.WorkService and PNC.WorkService.Queries
        and PNC.WorkService.Queries.Get
    then
        local order = PNC.WorkService.Queries.Get(sourceRef)
        return order and tonumber(order.revision) or item and item.revision
    end
    if domain == "medical" and PNC.MedicalCareService
        and PNC.MedicalCareService.Get
    then
        local task = PNC.MedicalCareService.Get(sourceRef)
        return task and tonumber(task.revision) or item and item.revision
    end
    return item and tonumber(item.revision) or nil
end

local function cancellation(item, active)
    local domain = tostring(item and item.sourceDomain or "")
    local sourceRef = item and item.sourceRef
    local taskId = item and item.taskId
    local phase = tostring(item and item.phase or "")
    local nonInterruptible = PNC.TaskRequestDefinitions
        and PNC.TaskRequestDefinitions.NON_INTERRUPTIBLE_PHASE or {}
    if active and (item.cancellationRequested == true
        or nonInterruptible[phase] == true)
    then
        return nil, nil, false, item and tonumber(item.revision) or nil
    end
    if domain == "work" and sourceRef then
        return "work_cancel", sourceRef, true, sourceRevision(item)
    end
    if domain == "medical" and sourceRef then
        return "medical_cancel", sourceRef, true, sourceRevision(item)
    end
    if active and taskId then
        return "task_cancel", taskId, true, tonumber(item.revision)
    end
    -- Need, farming, fishing, lumber, and scavenge candidates are derived
    -- offers until the arbiter assigns a lease. They have no queue record that
    -- can be deleted safely from a colony-management screen.
    return nil, nil, false, nil
end

local function decorate(item, active)
    local output = H.Copy(item) or {}
    local action, requestId, cancellable, revision = cancellation(output, active)
    output.cancelAction = action
    output.cancelRequestId = requestId
    output.cancellable = cancellable == true
    output.cancelRevision = revision
    output.durable = output.sourceDomain == "work"
        or output.sourceDomain == "medical"
    return output
end

function Tasking.Queries.BuildBrain(npcId, limit)
    npcId = tostring(npcId or "")
    limit = math.max(1, math.min(16, math.floor(tonumber(limit) or 8)))
    local diagnostics = Tasking.Diagnostics.byNPC[npcId]
    local current = Leases.ForNPC(npcId)
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    local candidates = diagnostics and diagnostics.candidates or {}
    local generatedAt = diagnostics and tonumber(diagnostics.generatedAt) or nil
    local recordRevision = diagnostics
        and tonumber(diagnostics.recordRevision) or nil
    local currentRevision = record and tonumber(record.recordRevision) or nil
    local freshness = "NEVER_EVALUATED"
    if diagnostics then
        local age = generatedAt and math.max(0, now() - generatedAt) or nil
        freshness = generatedAt and age and age <= 10000
            and (currentRevision == nil or recordRevision == currentRevision)
            and "FRESH" or "STALE"
    end
    local visible = {}
    for index, candidate in ipairs(candidates) do
        if index > limit then break end
        local row = decorate(candidate, false)
        row.rank = index
        visible[#visible + 1] = row
    end
    local winner = visible[1] and H.Copy(visible[1]) or nil
    local currentRow = current and decorate(current, true) or nil
    return {
        freshness = freshness,
        generatedAt = generatedAt,
        recordRevision = recordRevision,
        leaseRevision = current and tonumber(current.revision) or nil,
        current = currentRow,
        winner = winner,
        candidates = visible,
        candidateCount = #candidates,
        hasMore = #candidates > limit,
        decision = diagnostics and diagnostics.lastReason
            or "NO_DIAGNOSTICS",
        lastCause = diagnostics and diagnostics.lastCause or nil,
        eventType = diagnostics and diagnostics.eventType or nil,
        providerFailures = diagnostics
            and H.Copy(diagnostics.providerFailures) or {},
        providerDiagnostics = providerDiagnostics(npcId),
    }
end

function Tasking.Queries.GetDiagnostics(npcId)
    return { npc = H.Copy(Tasking.Diagnostics.byNPC[tostring(npcId or "")]),
        counters = H.Copy(Tasking.Diagnostics.counters),
        dirtyQueueLength = Tasking.Inbox and Tasking.Inbox.Count
            and Tasking.Inbox.Count() or 0,
        dirtyQueueHighWater = Tasking.Inbox
            and Tasking.Inbox.highWaterMark or 0,
        lastEvent = H.Copy(Tasking.Diagnostics.lastEvent),
        lastFailure = H.Copy(Tasking.Diagnostics.lastFailure),
        recentFailures = H.Copy(Tasking.Diagnostics.recentFailures),
        leaseCount = Leases.Count(),
        leaseInvariants = Leases.CheckInvariants
            and Leases.CheckInvariants() or nil,
        persistenceRepairs = PNC.Persistence
            and PNC.Persistence.Repairs
            and PNC.Persistence.Repairs.GetDiagnostics
            and PNC.Persistence.Repairs.GetDiagnostics()
            or nil }
end

return Tasking
