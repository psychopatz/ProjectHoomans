-- Lease creation and active-index ownership.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Leases = PNC.TaskLeaseService
local Internal = Leases.Internal

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
        workPriority = intent.workPriority,
        capability = intent.capability, interruptPolicy = intent.interruptPolicy,
        facilityId = assignment and assignment.facilityId or nil,
        facilitySlotId = assignment and assignment.componentId or nil,
        reservationId = assignment and assignment.reservationId or nil,
        resourceKey = assignment and assignment.resourceKey or nil,
        resourceKind = assignment and assignment.resourceKind or nil,
        activityItemID = assignment and assignment.activityItemID or nil,
        activityItemFullType = assignment
            and assignment.activityItemFullType or nil,
        manual = assignment and assignment.manual == true or false,
        phase = "ASSIGNED", startedAt = PNC.Core.Now(), revision = 1,
        lastProgressAt = PNC.Core.Now(), cancellationRequested = false,
        executionMode = assignment and assignment.executionMode or nil,
    }
    Leases.ByID[lease.leaseId], Leases.ByNPC[lease.npcId] = lease, lease.leaseId
    Leases.Active[#Leases.Active + 1] = lease.leaseId
    Leases.ActiveIndex[lease.leaseId] = #Leases.Active
    Internal.Emit("TASK_LEASE_CREATED", lease, { cause = "assigned" })
    return lease
end

Internal.RemoveActive = removeActive
