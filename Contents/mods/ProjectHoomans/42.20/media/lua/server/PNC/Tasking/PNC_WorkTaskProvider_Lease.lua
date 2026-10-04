-- Work task lease lifecycle and recovery provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = PNC.WorkTaskProvider or {}
local Internal = Provider.Internal or {}
local Work = PNC.WorkService
local Status = PNC.WorkDefinitions.STATUS
local Recovery = PNC.Tasking and PNC.Tasking.Internal
local FatigueGate = PNC.WorkFatigueGate
    or require "PNC/Core/Needs/PNC_WorkFatigueGate"
local needsFatigueGate = Internal.NeedsFatigueGate
local sendHomeForRest = Internal.SendHomeForRest
local phaseFor = Internal.PhaseFor

function Provider.CanContinue(lease)
    local order = Work and Work.Queries.Get(lease.sourceRef)
    if order and needsFatigueGate(order.operation) then
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(lease.npcId) or nil
        local fatigueOK, fatigueReason = FatigueGate.Check(record)
        if not fatigueOK then return false, fatigueReason end
    end
    return order ~= nil and tostring(order.workerId or "") == lease.npcId
        and order.status ~= Status.CANCELLED
        and order.status ~= Status.COMPLETED
        and order.status ~= Status.FAILED
        and order.status ~= Status.BLOCKED
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
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(lease.npcId) or nil
    if ok then sendHomeForRest(record, order, reason) end
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
        if order.operation == "LUMBER" then
            -- PathService owns live movement recovery. A Lumber travel lane
            -- may be repathed, switched from native to scripted movement, or
            -- briefly have no lane while the same target is reissued. Do not
            -- release the durable Lumber claim and restore the NPC's home
            -- order during that bounded handoff.
            snapshot.watchable = false
        end
    end
    return snapshot
end
