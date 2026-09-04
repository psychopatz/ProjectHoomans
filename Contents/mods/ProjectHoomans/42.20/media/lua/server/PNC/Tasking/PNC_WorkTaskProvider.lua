if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = {}
local Work = PNC.WorkService
local Status = PNC.WorkDefinitions.STATUS
local Definitions = PNC.WorkDefinitions
local Recovery = PNC.Tasking and PNC.Tasking.Internal
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"

local function assignable(order)
    return order and not order.workerId
        and order.recoveryQuarantined ~= true
        and (order.status == Status.QUEUED
            or order.status == Status.WAITING_FOR_WORKER)
end

local function phaseFor(order)
    if order.status == Status.WORLD_EFFECT_PENDING then
        return "WORLD_EFFECT_PENDING"
    end
    return order.completionStarted == true and "ATOMIC_COMMIT"
        or order.phase == "DROP_PENDING" and "ATOMIC_COMMIT"
        or order.phase == "GRAB_PENDING" and "WAITING"
        or order.status == Status.TRAVEL_TO_STOCKPILE
            and "TRAVEL"
        or order.status == Status.TRAVEL_TO_STATION and "TRAVEL"
        or order.status == Status.WORKING and "WORKING" or "WAITING"
end

function Provider.GetCandidates(npcId)
    local record = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(npcId)
    if not record or record.alive == false or not Work then return {} end
    local output = {}
    local indexed = Work.Queries.ListAssignableForWorker ~= nil
    local orders = indexed
        and Work.Queries.ListAssignableForWorker(npcId, 64)
        or Work.Queries.List()
    for _, order in ipairs(orders) do
        local eligible = assignable(order)
            and (indexed or not Work.Queries.CanAssign
                or Work.Queries.CanAssign(order.id, npcId))
        if eligible == true then
            local priority = tonumber(order.priority) or 0
            local job = PNC.WorkDefinitions.JOB_BY_OPERATION
                and PNC.WorkDefinitions.JOB_BY_OPERATION[order.operation]
            output[#output + 1] = {
                taskId = order.id, npcId = tostring(npcId),
                kind = order.operation, sourceDomain = "work",
                sourceRef = order.id,
                precedence = priority >= 90 and "FORCED_ORDER"
                    or priority >= 50 and "HIGH_WORK" or "NORMAL_WORK",
                urgency = math.max(0, math.min(1, (priority + 100) / 200)),
                workPriority = job and WorkPolicy.GetPriority(record, job)
                    or nil,
                capability = PNC.WorkDefinitions.CAPABILITY_BY_OPERATION[
                    order.operation] or "work.construction",
                interruptPolicy = "NORMAL", revision = order.revision,
                createdAt = order.createdAt,
            }
        end
    end
    return output
end

function Provider.Validate(intent)
    local order = Work and Work.Queries.Get(intent.sourceRef)
    return assignable(order) and Work.Queries.CanAssign(
        intent.sourceRef, intent.npcId) == true
end

-- The task arbiter only needs GetCandidates during normal evaluation. The
-- diagnostic path is intentionally separate so inspecting one NPC does not
-- add a full repository explanation pass to every tasking pump.
function Provider.GetDiagnostics(npcId)
    if not Work or not Work.Queries
        or not Work.Queries.BuildAssignmentDiagnostics
    then
        return {
            totalOrders = 0,
            statusCounts = {},
            assignableOrders = 0,
            eligibleOrders = 0,
            rejectionCounts = {},
            eligibleOperations = {},
            samples = {},
            unavailable = "WORK_DIAGNOSTICS_UNAVAILABLE",
        }
    end
    return Work.Queries.BuildAssignmentDiagnostics(npcId)
end

function Provider.Assign(intent)
    local assigned, reason = Work.Commands.Assign(intent.sourceRef, intent.npcId)
    if assigned ~= true then return nil, reason end
    local order = Work.Queries.Get(intent.sourceRef)
    return {
        facilityId = order.facilityId, componentId = order.stationId,
        reservationId = order.facilityReservationId,
        executionMode = order.executionMode,
    }
end

function Provider.Start() return true end

function Provider.RollbackAssignment(intent, _, reason)
    local order = Work and Work.Queries.Get(intent.sourceRef)
    if not order or tostring(order.workerId or "") ~= intent.npcId then
        return true
    end
    return Work.Commands.ReleaseWorker(intent.npcId,
        reason or "assignment_rolled_back")
end

function Provider.CanContinue(lease)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    return order ~= nil and tostring(order.workerId or "") == lease.npcId
        and order.status ~= Status.CANCELLED
        and order.status ~= Status.COMPLETED
        and order.status ~= Status.FAILED
end

function Provider.Cancel(lease, reason)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    if not order or tostring(order.workerId or "") ~= lease.npcId then
        lease.reservationId = nil
        return true
    end
    local recovery = reason == "task_progress_timeout"
        or reason == "task_executor_failed"
    local recoveryState
    if recovery and Work.Commands.RecordRecovery then
        local recorded, recordedState = Work.Commands.RecordRecovery(
            order.id, reason, PNC.Tasking
                and PNC.Tasking.MAX_STALL_RECOVERY_ATTEMPTS)
        if recorded ~= true then
            lease.reservationId = nil
            return false, recordedState or "WORK_RECOVERY_RECORD_FAILED"
        end
        recoveryState = recordedState
    end
    local ok, result = Work.Commands.ReleaseWorker(lease.npcId,
        reason or "task_lease_released")
    lease.reservationId = nil
    if recovery and recoveryState == "QUARANTINE" then
        if ok == true and Work.Commands.Quarantine then
            local quarantined, quarantineResult = Work.Commands.Quarantine(
                order.id, "TASK_RECOVERY_EXHAUSTED")
            if quarantined == true then return true, quarantineResult end
            result = quarantineResult
        end
        if Work.Commands.Cancel then
            local cancelled, cancelledResult = Work.Commands.Cancel(order.id,
                "TASK_RECOVERY_EXHAUSTED")
            if cancelled == true then return true, cancelledResult end
            result = cancelledResult or result
        end
    end
    return ok, result
end

function Provider.Complete() return true end

function Provider.GetRecoveryState(lease)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    if not order then return { terminal = true } end
    if order.status == Status.CANCELLED
        or order.status == Status.COMPLETED or order.status == Status.FAILED
    then
        return { terminal = true }
    end
    local snapshot = {
        lastProgressAt = order.lastProgressAt,
        phase = phaseFor(order),
    }
    if snapshot.phase == "TRAVEL"
        and Recovery and Recovery.ApplyMovementRecovery
    then
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(lease.npcId) or nil
        snapshot = Recovery.ApplyMovementRecovery(snapshot, lease, record)
    end
    return snapshot
end

function Provider.Tick(lease)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    if not order or order.status == Status.CANCELLED
        or order.status == Status.COMPLETED or order.status == Status.FAILED
    then
        lease.reservationId = nil
        return PNC.Tasking.Commands.Complete(lease.leaseId,
            order and order.status or "WORK_ORDER_REMOVED")
    end
    if tostring(order.workerId or "") ~= lease.npcId then
        PNC.Tasking.Events.Emit("WORK_ASSIGNMENT_LOST", {
            npcId = lease.npcId, source = "Tasking.WorkProvider",
            entityId = lease.sourceRef,
        })
        return false
    end
    local phase = phaseFor(order)
    if lease.phase ~= phase then
        PNC.TaskLeaseService.SetPhase(lease.leaseId, phase)
    end
    if tonumber(order.lastProgressAt) ~= tonumber(lease.lastProgressAt) then
        lease.lastProgressAt = order.lastProgressAt
    end
    local mode = tostring(order.executionMode or lease.executionMode or "LIVE")
    local handler
    if mode == "ABSTRACT" then
        handler = Work.AbstractExecutionHandlers
            and Work.AbstractExecutionHandlers[order.operation]
    else
        handler = Work.ExecutionHandlers
            and Work.ExecutionHandlers[order.operation]
    end
    if mode == "ABSTRACT" and not handler
        and Definitions.ExecutionPolicy
        and Definitions.ExecutionPolicy(order.operation) ~= "ABSTRACT_SAFE"
    then
        return false, "ABSTRACT_EXECUTION_UNSUPPORTED"
    end
    if handler then
        local ok, reason = handler(order, lease)
        if ok == false then
            if PNC.Core and PNC.Core.LogWarn then
                PNC.Core.LogWarn("work_execution_failed operation="
                    .. tostring(order.operation)
                    .. " order=" .. tostring(order.id)
                    .. " npc=" .. tostring(lease.npcId)
                    .. " reason=" .. tostring(reason
                        or "work_operation_failed"))
            end
            if PNC.Tasking.Commands.CancelLease then
                PNC.Tasking.Commands.CancelLease(lease.leaseId,
                    reason or "work_operation_failed")
                return true
            end
            return false, reason or "WORK_OPERATION_FAILED"
        end
        local updated = Work.Queries.Get(lease.sourceRef)
        if updated and updated.status == Status.WORLD_EFFECT_PENDING then
            return PNC.Tasking.Commands.Complete(lease.leaseId,
                updated.status)
        end
        if updated and (updated.status == Status.CANCELLED
            or updated.status == Status.COMPLETED
            or updated.status == Status.FAILED)
        then
            return PNC.Tasking.Commands.Complete(lease.leaseId,
                updated.status)
        end
    end
    return true
end

if PNC.Tasking and PNC.Tasking.Commands then
    PNC.Tasking.Commands.RegisterProvider("work", Provider)
end

PNC.WorkTaskProvider = Provider
return Provider
