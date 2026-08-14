if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskLeaseService = PNC.TaskLeaseService or {}

local Leases = PNC.TaskLeaseService
Leases.ByID = Leases.ByID or {}
Leases.ByNPC = Leases.ByNPC or {}
Leases.Active = Leases.Active or {}
Leases.PHASES = { ASSIGNED = true, TRAVEL = true, WAITING = true,
    WORKING = true, ATOMIC_COMMIT = true, COMPLETING = true, DONE = true }

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
        phase = "ASSIGNED", startedAt = PNC.Core.Now(), revision = 1,
        executionMode = assignment and assignment.executionMode or nil,
    }
    Leases.ByID[lease.leaseId], Leases.ByNPC[lease.npcId] = lease, lease.leaseId
    Leases.Active[#Leases.Active + 1] = lease.leaseId
    return lease
end

function Leases.Get(id) return Leases.ByID[tostring(id or "")] end
function Leases.ForNPC(id) return Leases.Get(Leases.ByNPC[tostring(id or "")]) end

function Leases.SetPhase(id, phase)
    local lease = Leases.Get(id)
    phase = tostring(phase or "")
    if not lease then return false, "LEASE_NOT_FOUND" end
    if not Leases.PHASES[phase] then return false, "INVALID_TASK_PHASE" end
    if lease.phase ~= phase then lease.phase, lease.revision = phase, lease.revision + 1 end
    return true, lease
end

function Leases.Release(id, reason)
    local lease = Leases.Get(id)
    if not lease then return false, "LEASE_NOT_FOUND" end
    if lease.reservationId and PNC.FacilityReservations then
        PNC.FacilityReservations.Release(lease.reservationId,
            reason == "complete" and "complete" or reason or "task_released")
    end
    Leases.ByID[lease.leaseId], Leases.ByNPC[lease.npcId] = nil, nil
    for index = #Leases.Active, 1, -1 do
        if Leases.Active[index] == lease.leaseId then
            table.remove(Leases.Active, index); break
        end
    end
    lease.phase, lease.releaseReason = "DONE", tostring(reason or "released")
    return true, lease
end

function Leases.Count()
    local count = 0
    for _, _ in pairs(Leases.ByID) do count = count + 1 end
    return count
end

return Leases
