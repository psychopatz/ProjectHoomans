if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}
local emit = Internal.emit
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local markAssignmentDirty = Internal.markAssignmentDirty
local releaseClaim = Internal.releaseClaim

function Service.Commands.Cancel(orderId, reason)
    local order = Repository.Get(orderId)
    if not order then return false, "WORK_ORDER_UNAVAILABLE" end
    if order.status == Status.CANCELLED then return true, copy(order) end
    if terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if order.completionStarted == true then
        order.cancellationRequested = true
        order.cancellationReason = tostring(reason or "cancelled")
        order.status, order.updatedAt = Status.CANCELLING, now()
        order.revision = order.revision + 1
        Repository.MarkDirty()
        return true, "CANCELLATION_DEFERRED"
    end
    if order.status ~= Status.CANCELLING then
        order.status, order.cancellationRequested = Status.CANCELLING, true
        order.cancellationReason = tostring(reason or "cancelled")
        order.updatedAt, order.revision = now(), order.revision + 1
        Repository.MarkDirty()
    end
    local cancellation = Service.CancellationHandlers
        and Service.CancellationHandlers[order.operation]
    if cancellation then
        local cancelled, cancellationReason = cancellation(order)
        if cancelled == false then
            return false, cancellationReason or "CANCELLATION_FAILED"
        end
    end
    releaseClaim(order, order.cancellationReason, true, false)
    order.status, order.cancelledAt = Status.CANCELLED, now()
    order.terminalPersisted = false
    order.blockedReason, order.revision = nil, order.revision + 1
    Repository.MarkDirty()
    emit(EventTypes.WORK_ORDER_CANCELLED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation })
    return true, copy(order)
end

function Service.Commands.ReleaseWorker(workerId, reason)
    workerId = tostring(workerId or "")
    local orderId = Service.ClaimsByWorker[workerId]
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(workerId) or nil
    orderId = orderId or record and record.runtime
        and record.runtime.workOrderId or nil
    local order = orderId and Repository.Get(orderId) or nil
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    local released, releaseReason = releaseClaim(order,
        reason or "worker_released", false, true)
    if released == false then return false, releaseReason end
    order.status = Status.WAITING_FOR_WORKER
    order.blockedReason = nil
    order.updatedAt, order.revision = now(), order.revision + 1
    Repository.MarkDirty()
    markAssignmentDirty(order, "WORKER_RELEASED")
    return true, copy(order)
end

-- Release the durable work claim and its Tasking lease as one operation.
-- Tasking's work provider calls ReleaseWorker during lease cleanup, so this
-- wrapper is only used by external scheduler/recovery paths.
function Service.Commands.ReleaseAssignment(workerId, reason)
    workerId = tostring(workerId or "")
    local lease = PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC
        and PNC.TaskLeaseService.ForNPC(workerId) or nil
    if lease and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.CancelLease
    then
        local ok, state = PNC.Tasking.Commands.CancelLease(lease.leaseId,
            reason or "work_assignment_released")
        if ok ~= true then return false, state end
        if PNC.TaskLeaseService.Get(lease.leaseId) then
            return false, state == "CANCELLATION_DEFERRED"
                and "TASK_CANCELLATION_DEFERRED" or "TASK_CLEANUP_PENDING"
        end
        return true
    end
    return Service.Commands.ReleaseWorker(workerId, reason)
end

function Service.Commands.Pause(orderId, paused)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if paused ~= false and order.status == Status.PAUSED then
        return true, copy(order)
    end
    order.status = paused == false and Status.WAITING_FOR_WORKER or Status.PAUSED
    if paused ~= false then
        -- Pausing relinquishes the live worker. Corpse interactions use
        -- nonblocking presentation scenes, so they need the same operation
        -- cleanup boundary as lumber or the scene can continue after the
        -- worker has returned to its previous order.
        releaseClaim(order, "paused", false,
            order.operation == "LUMBER"
                or order.operation == "CORPSE_HAUL")
    end
    order.revision = order.revision + 1; Repository.MarkDirty()
    return true, copy(order)
end

-- Releasing a worker is deliberately different from cancelling an order: the
-- order, progress, reservations, and any staged inputs remain durable. Resume
-- uses the same claim release path, then lets the normal scheduler acquire a
-- worker again once they are home.
function Service.Commands.Resume(orderId)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if order.workerId or order.stationId or order.facilityReservationId then
        releaseClaim(order, "resumed")
    end
    order.status = Status.WAITING_FOR_WORKER
    order.blockedReason = nil
    order.updatedAt, order.revision = now(), order.revision + 1
    Repository.MarkDirty()
    markAssignmentDirty(order, "WORK_REQUEST_RESUMED")
    return true, copy(order)
end

function Service.Commands.SetPriority(orderId, priority)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    order.priority = math.max(-100, math.min(100,
        math.floor(tonumber(priority) or 0)))
    order.revision, order.updatedAt = order.revision + 1, now()
    Repository.MarkDirty()
    markAssignmentDirty(order, "WORK_PRIORITY_CHANGED")
    return true, copy(order)
end

local function authorizedOrder(player, orderId)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    local order = Repository.Get(orderId)
    if not context then return nil, reason end
    if not order or order.colonyId ~= tostring(context.colony.id)
        or order.factionId ~= tostring(context.faction.id)
    then return nil, "WORK_ORDER_FORBIDDEN" end
    return order
end

function Service.Commands.CancelForPlayer(player, orderId, reason)
    local order, denied = authorizedOrder(player, orderId)
    if not order then return false, denied end
    return Service.Commands.Cancel(order.id, reason)
end

function Service.Commands.PauseForPlayer(player, orderId, paused)
    local order, denied = authorizedOrder(player, orderId)
    if not order then return false, denied end
    return Service.Commands.Pause(order.id, paused)
end

function Service.Commands.ResumeForPlayer(player, orderId)
    local order, denied = authorizedOrder(player, orderId)
    if not order then return false, denied end
    return Service.Commands.Resume(order.id)
end


function Service.Commands.SetPriorityForPlayer(player, orderId, priority)
    local order, denied = authorizedOrder(player, orderId)
    if not order then return false, denied end
    return Service.Commands.SetPriority(order.id, priority)
end


return Service
