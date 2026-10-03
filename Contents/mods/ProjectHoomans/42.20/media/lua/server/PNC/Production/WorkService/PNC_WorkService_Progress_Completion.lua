-- Work completion and deferred world-effect finalization provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Status = PNC.WorkDefinitions.STATUS
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}
local emit = Internal.emit
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local releaseClaim = Internal.releaseClaim
local returnHomeAfterWork = Internal.returnHomeAfterWork

local function complete(order)
    if order.completionCommitted == true then return true end
    local worker = order.workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    local handler = Service.CompletionHandlers[order.operation]
    if not handler then
        order.status, order.blockedReason = Status.BLOCKED, "COMPLETION_HANDLER_MISSING"
        Repository.MarkDirty(); return false, order.blockedReason
    end
    order.completionStarted = true
    Repository.MarkDirty()
    local callOk, ok, reason = pcall(handler, order)
    if not callOk then
        order.completionError = tostring(ok)
        ok, reason = false, "COMPLETION_EXCEPTION"
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn("work completion exception order="
                .. tostring(order.id) .. " error=" .. tostring(order.completionError))
        end
    end
    if ok ~= true then
        if order.cancellationRequested == true then
            releaseClaim(order, order.cancellationReason or "cancelled", true,
                true)
            order.status, order.cancelledAt = Status.CANCELLED, now()
            order.completionStarted, order.blockedReason = nil, nil
            order.terminalPersisted = false
            order.revision = order.revision + 1
            Repository.MarkDirty()
            return true, "CANCELLED_AFTER_ATOMIC_FAILURE"
        end
        local recovery = Service.CompletionRecoveryHandlers
            and Service.CompletionRecoveryHandlers[order.operation]
        if recovery then
            local recoveryOK, recovered, recoveryReason = pcall(recovery,
                order, tostring(reason or "COMPLETION_FAILED"), worker)
            if recoveryOK and recovered == true then
                order.completionStarted = nil
                Repository.MarkDirty()
                return false, recoveryReason or reason
            end
            if not recoveryOK and PNC.Core and PNC.Core.LogWarn then
                PNC.Core.LogWarn("work completion recovery exception order="
                    .. tostring(order.id) .. " error=" .. tostring(recovered))
            end
        end
        order.status, order.blockedReason = Status.BLOCKED,
            tostring(reason or "COMPLETION_FAILED")
        order.completionStarted = nil
        Repository.MarkDirty(); return false, order.blockedReason
    end
    local completedWorker = worker
    order.completionCommitted = true
    order.terminalPersisted = false
    order.status, order.progress = Status.COMPLETED, order.requiredWork
    if order.cancellationRequested == true then
        order.cancellationOutcome = "COMPLETED_DURING_CANCELLATION"
    end
    order.cancellationRequested, order.cancellationReason = nil, nil
    order.completedAt, order.updatedAt = now(), now()
    order.revision = order.revision + 1
    releaseClaim(order, "complete")
    if returnHomeAfterWork then
        returnHomeAfterWork(completedWorker, order)
    end
    Repository.MarkDirty()
    emit(EventTypes.WORK_ORDER_COMPLETED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation })
    return true
end

local function completeDeferred(orderId, reason)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then
        return false, "WORK_ORDER_UNAVAILABLE"
    end
    if order.status ~= Status.WORLD_EFFECT_PENDING
        or type(order.worldEffect) ~= "table"
        or tostring(order.worldEffect.state or "") ~= "APPLIED"
    then
        return false, "WORLD_EFFECT_NOT_APPLIED"
    end
    local completedWorker = order.workerId and PNC.Registry
        and PNC.Registry.Get and PNC.Registry.Get(order.workerId) or nil
    order.completionCommitted = true
    order.completionStarted = nil
    order.cancellationRequested, order.cancellationReason = nil, nil
    order.terminalPersisted = false
    order.status, order.progress = Status.COMPLETED, order.requiredWork
    order.blockedReason = nil
    order.completedAt, order.updatedAt = now(), now()
    order.completionReason = tostring(reason or "deferred_world_effect")
    order.revision = (tonumber(order.revision) or 0) + 1
    releaseClaim(order, order.completionReason, false, false)
    if returnHomeAfterWork and completedWorker then
        returnHomeAfterWork(completedWorker, order)
    end
    Repository.MarkDirty()
    emit(EventTypes.WORK_ORDER_COMPLETED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation,
        deferred = true })
    return true, copy(order)
end

Internal.Complete = complete
Internal.CompleteDeferred = completeDeferred
