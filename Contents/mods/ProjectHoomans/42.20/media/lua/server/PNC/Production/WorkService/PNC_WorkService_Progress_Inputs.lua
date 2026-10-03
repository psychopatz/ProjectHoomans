-- Work input collection and worker assignment provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Status = PNC.WorkDefinitions.STATUS
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local setLiveOrder = Internal.setLiveOrder
local workerAvailable = Internal.workerAvailable
local claimStation = Internal.claimStation

local function collectInputs(orderId, workerId)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if tostring(order.workerId or "") ~= tostring(workerId or "") then
        return false, "WORKER_NOT_ASSIGNED"
    end
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    local ok, reason
    if PNC.WorkInputService
        and PNC.WorkInputService.RequiresCollection(order)
    then
        ok, reason = PNC.WorkInputService.Collect(order, worker)
    else
        local handler = Service.CollectionHandlers[order.operation]
        if not handler then return false, "COLLECTION_HANDLER_MISSING" end
        ok, reason = handler(order, worker)
    end
    if ok ~= true then
        order.status, order.blockedReason = Status.BLOCKED,
            tostring(reason or "INPUT_COLLECTION_FAILED")
        Repository.MarkDirty()
        return false, order.blockedReason
    end
    order.collectionTarget = nil
    order.status, order.blockedReason = Status.TRAVEL_TO_STATION, nil
    order.updatedAt, order.lastProgressAt = now(), now()
    order.recoveryAttempts = nil
    order.lastRecoveryAt = nil
    order.lastRecoveryReason = nil
    order.recoveryQuarantined = nil
    order.revision = order.revision + 1
    setLiveOrder(worker, order, order.stationTarget, "WORK_AT_STATION")
    Repository.MarkDirty()
    return true, copy(order)
end

local function assign(orderId, workerId)
    local order = Repository.Get(orderId)
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    local available, reason = workerAvailable(worker, order)
    if not available then return false, reason or "NO_QUALIFIED_WORKER" end
    return claimStation(order, worker)
end

Internal.CollectInputs = collectInputs
Internal.Assign = assign
