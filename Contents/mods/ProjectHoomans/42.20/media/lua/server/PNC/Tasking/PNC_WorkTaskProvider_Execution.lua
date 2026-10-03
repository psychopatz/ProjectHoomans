-- Work task live and abstract execution dispatch provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = PNC.WorkTaskProvider or {}
local Internal = Provider.Internal or {}
local Work = PNC.WorkService
local Status = PNC.WorkDefinitions.STATUS
local Definitions = PNC.WorkDefinitions
local FatigueGate = PNC.WorkFatigueGate
    or require "PNC/Core/Needs/PNC_WorkFatigueGate"
local needsFatigueGate = Internal.NeedsFatigueGate
local phaseFor = Internal.PhaseFor

function Provider.Tick(lease)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    if not order or order.status == Status.CANCELLED
        or order.status == Status.COMPLETED or order.status == Status.FAILED
    then
        lease.reservationId = nil
        return PNC.Tasking.Commands.Complete(lease.leaseId,
            order and order.status or "WORK_ORDER_REMOVED")
    end
    if order.status == Status.BLOCKED then
        -- A blocked durable order must not retain an executor lease. The
        -- provider cancellation path releases the domain claim and operation
        -- runtime, allowing the order's domain reconciler or UI to retry it.
        if PNC.Tasking.Commands.CancelLease then
            local stopped = PNC.Tasking.Commands.CancelLease(lease.leaseId,
                "blocked_order_recovery")
            if stopped then return true end
        end
        return false, order.blockedReason or "WORK_ORDER_BLOCKED"
    end
    if tostring(order.workerId or "") ~= lease.npcId then
        PNC.Tasking.Events.Emit("WORK_ASSIGNMENT_LOST", {
            npcId = lease.npcId, source = "Tasking.WorkProvider",
            entityId = lease.sourceRef,
        })
        return false
    end
    if needsFatigueGate(order.operation) then
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(lease.npcId) or nil
        local fatigueOK, fatigueReason = FatigueGate.Check(record)
        if not fatigueOK and PNC.Tasking.Commands.CancelLease then
            local released = PNC.Tasking.Commands.CancelLease(lease.leaseId,
                fatigueReason)
            return released ~= false
        end
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
