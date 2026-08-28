if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskLeaseService = PNC.TaskLeaseService or {}

local Leases = PNC.TaskLeaseService
Leases.ByID = Leases.ByID or {}
Leases.ByNPC = Leases.ByNPC or {}
Leases.Active = Leases.Active or {}
Leases.ActiveIndex = Leases.ActiveIndex or {}
Leases.PHASES = { ASSIGNED = true, TRAVEL = true, WAITING = true,
    WORKING = true, CANCELLING = true, ATOMIC_COMMIT = true,
    COMPLETING = true, DONE = true }
Leases.PHASE_ALIASES = { WAITING_FOR_WORLD = "WAITING" }
Leases.TRANSITIONS = {
    ASSIGNED = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    TRAVEL = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    WAITING = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    WORKING = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    ATOMIC_COMMIT = { WORKING = true, COMPLETING = true },
    CANCELLING = { CANCELLING = true, COMPLETING = true },
    COMPLETING = { COMPLETING = true, DONE = true },
    DONE = { DONE = true },
}

local function normalizePhase(phase)
    phase = string.upper(tostring(phase or ""))
    return Leases.PHASE_ALIASES[phase] or phase
end

local function emit(eventType, lease, details)
    local events = PNC.Tasking and PNC.Tasking.Events
    if not events or type(events.Emit) ~= "function" then return end
    details = details or {}
    details.npcId = lease.npcId
    details.entityId = lease.leaseId
    details.source = "TaskLeaseService"
    details.revision = lease.revision
    details.payload = details.payload or { taskId = lease.taskId,
        sourceDomain = lease.sourceDomain, phase = lease.phase }
    events.Emit(eventType, details, { enqueue = false })
end

local function transition(lease, phase, reason)
    phase = normalizePhase(phase)
    if not Leases.PHASES[phase] then
        return false, "INVALID_TASK_PHASE"
    end
    local allowed = Leases.TRANSITIONS[lease.phase]
    if not allowed or not allowed[phase] then
        if PNC.Tasking and PNC.Tasking.Diagnostics then
            PNC.Tasking.Diagnostics.counters.leaseTransitionFailures =
                PNC.Tasking.Diagnostics.counters.leaseTransitionFailures + 1
        end
        return false, "INVALID_TASK_PHASE_TRANSITION"
    end
    if lease.phase == phase then return true, lease end
    local previous = lease.phase
    lease.phase = phase
    lease.revision = lease.revision + 1
    emit("TASK_LEASE_PHASE_CHANGED", lease, {
        cause = reason or "phase_changed",
        payload = { from = previous, to = phase,
            taskId = lease.taskId, sourceDomain = lease.sourceDomain },
    })
    return true, lease
end

local function removeActive(leaseId)
    local index = Leases.ActiveIndex[leaseId]
    if not index then
        for cursor = #Leases.Active, 1, -1 do
            if Leases.Active[cursor] == leaseId then index = cursor; break end
        end
    end
    if not index then return false end
    local last = #Leases.Active
    local moved = Leases.Active[last]
    if index ~= last then
        Leases.Active[index] = moved
        Leases.ActiveIndex[moved] = index
    end
    Leases.Active[last] = nil
    Leases.ActiveIndex[leaseId] = nil
    return true
end

function Leases.Create(intent, assignment)
    if Leases.ByNPC[intent.npcId] then return nil, "NPC_ALREADY_LEASED" end
    local lease = {
        leaseId = PNC.Core.GenerateID("task_lease"), npcId = intent.npcId,
        taskId = intent.taskId, kind = intent.kind,
        sourceDomain = intent.sourceDomain, sourceRef = intent.sourceRef,
        precedence = intent.precedence, urgency = intent.urgency,
        capability = intent.capability, interruptPolicy = intent.interruptPolicy,
        facilityId = assignment and assignment.facilityId or nil,
        facilitySlotId = assignment and assignment.componentId or nil,
        reservationId = assignment and assignment.reservationId or nil,
        resourceKey = assignment and assignment.resourceKey or nil,
        resourceKind = assignment and assignment.resourceKind or nil,
        phase = "ASSIGNED", startedAt = PNC.Core.Now(), revision = 1,
        lastProgressAt = PNC.Core.Now(), cancellationRequested = false,
        executionMode = assignment and assignment.executionMode or nil,
    }
    Leases.ByID[lease.leaseId], Leases.ByNPC[lease.npcId] = lease, lease.leaseId
    Leases.Active[#Leases.Active + 1] = lease.leaseId
    Leases.ActiveIndex[lease.leaseId] = #Leases.Active
    emit("TASK_LEASE_CREATED", lease, { cause = "assigned" })
    return lease
end

function Leases.RequestCancellation(id, reason)
    local lease = Leases.Get(id)
    if not lease then return false, "LEASE_NOT_FOUND" end
    local nonInterruptible = PNC.TaskRequestDefinitions
        and PNC.TaskRequestDefinitions.NON_INTERRUPTIBLE_PHASE or {}
    local atomic = nonInterruptible[lease.phase]
    if lease.cancellationRequested == true then
        if atomic then
            lease.cancellationDeferred = true
            return true, "CANCELLATION_DEFERRED"
        end
        lease.cancellationDeferred = false
        if lease.phase ~= "CANCELLING" then
            return transition(lease, "CANCELLING", "cancellation_requested")
        end
        return true, "CANCELLING"
    end
    lease.cancellationRequested = true
    lease.cancellationReason = tostring(reason or "cancelled")
    lease.revision = lease.revision + 1
    lease.cancellationDeferred = atomic == true
    if not atomic then
        local changed, transitionReason = transition(lease, "CANCELLING",
            "cancellation_requested")
        if not changed then return false, transitionReason end
    end
    return true, atomic and "CANCELLATION_DEFERRED" or "CANCELLING"
end

function Leases.Get(id) return Leases.ByID[tostring(id or "")] end
function Leases.ForNPC(id) return Leases.Get(Leases.ByNPC[tostring(id or "")]) end

function Leases.SetPhase(id, phase)
    local lease = Leases.Get(id)
    if not lease then return false, "LEASE_NOT_FOUND" end
    return transition(lease, phase, "provider_phase_update")
end

function Leases.Release(id, reason)
    local lease = Leases.Get(id)
    if not lease then return false, "LEASE_NOT_FOUND" end
    if lease.reservationId and PNC.FacilityReservations then
        local ok, released = pcall(PNC.FacilityReservations.Release,
            lease.reservationId,
            reason == "complete" and "complete" or reason or "task_released")
        if not ok or released == false then
            if PNC.Tasking and PNC.Tasking.Internal
                and PNC.Tasking.Internal.RecordFailure
            then
                PNC.Tasking.Internal.RecordFailure(
                    "lease_reservation_release", {
                        npcId = lease.npcId, leaseId = lease.leaseId,
                        domain = lease.sourceDomain,
                    }, ok and "RESERVATION_RELEASE_REJECTED" or released)
            end
            return false, "RESERVATION_RELEASE_FAILED"
        end
    end
    Leases.ByID[lease.leaseId], Leases.ByNPC[lease.npcId] = nil, nil
    removeActive(lease.leaseId)
    lease.phase, lease.releaseReason = "DONE", tostring(reason or "released")
    lease.revision = lease.revision + 1
    emit("TASK_LEASE_RELEASED", lease, { cause = lease.releaseReason })
    return true, lease
end

function Leases.CheckInvariants()
    for id, lease in pairs(Leases.ByID) do
        if tostring(lease.leaseId) ~= tostring(id)
            or Leases.ByNPC[lease.npcId] ~= lease.leaseId
            or Leases.ActiveIndex[lease.leaseId] == nil
        then
            return false, "LEASE_INDEX_MISMATCH"
        end
    end
    for npcId, leaseId in pairs(Leases.ByNPC) do
        local lease = Leases.ByID[leaseId]
        if not lease or tostring(lease.npcId) ~= tostring(npcId) then
            return false, "LEASE_NPC_INDEX_MISMATCH"
        end
    end
    return true
end

function Leases.Count()
    local count = 0
    for _, _ in pairs(Leases.ByID) do count = count + 1 end
    return count
end

return Leases
