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
local now = Internal.now
local terminal = Internal.terminal
local markAssignmentDirty = Internal.markAssignmentDirty
local releaseClaim = Internal.releaseClaim
local assignedOrderForRecord = Internal.assignedOrderForRecord
local restoreOrderIsSafe = Internal.restoreOrderIsSafe

local function clearStaleWorkerState(record, workOrder, reason)
    if not record then return false end
    local runtime = record.runtime or {}
    local zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local previous = workOrder and workOrder.previousOrder or nil
    local restored = false
    record.runtime = runtime
    if PNC.AnimationScenes and PNC.AnimationScenes.Stop
        and runtime.animationScene
    then
        PNC.AnimationScenes.Stop(record, zombie, reason or "stale_work_order")
    else
        runtime.animationScene = nil
    end
    runtime.workOrderId = nil
    runtime.lastProductionWorkAt = nil
    if restoreOrderIsSafe(record, previous)
        and PNC.OrderSystem and PNC.OrderSystem.SetOrder
    then
        PNC.OrderSystem.SetOrder(record, previous)
        restored = true
    end
    if not restored and record.orderSpec
        and record.orderSpec.kind == "production_work"
    then
        local baseId = workOrder and workOrder.baseId
            or runtime.homeBaseId
        local sentHome = false
        if baseId and PNC.HomeDutyService
            and PNC.HomeDutyService.SendHome
        then
            sentHome = PNC.HomeDutyService.SendHome(record, baseId,
                reason or "stale_work_order") == true
        end
        if not sentHome and PNC.OrderSystem
            and PNC.OrderSystem.SetOrder
        then
            PNC.OrderSystem.SetOrder(record, nil)
        elseif not sentHome then
            record.orderSpec = nil
        elseif record.orderSpec
            and record.orderSpec.kind == "production_work"
            and PNC.OrderSystem and PNC.OrderSystem.SetOrder
        then
            PNC.OrderSystem.SetOrder(record, {
                kind = "colony_home", baseId = baseId,
            })
        end
    end
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "stale_work_order_recovered")
    end
    if PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.MarkDirty
    then
        PNC.Tasking.Commands.MarkDirty(record.id,
            "STALE_WORK_ORDER_RECOVERED")
    end
    return true
end

-- Runtime claims and persisted NPC order specs are separate pieces of state.
-- Rebuild the in-memory claim indexes and repair mismatches before processing
-- orders so a reload cannot leave the former worker executing in parallel.
function Service.ReconcileWorkerState()
    Repository.Load()
    local orderIds = {}
    local workers = {}
    local stations = {}
    local repaired = 0
    for id, order in pairs(Repository.State.byId or {}) do
        if not terminal(order) and order.workerId then
            orderIds[#orderIds + 1] = id
        end
    end
    table.sort(orderIds, function(left, right)
        local a, b = Repository.State.byId[left], Repository.State.byId[right]
        local ap, bp = tonumber(a.priority) or 0, tonumber(b.priority) or 0
        if ap ~= bp then return ap > bp end
        local ac, bc = tonumber(a.createdAt) or 0, tonumber(b.createdAt) or 0
        if ac ~= bc then return ac < bc end
        return tostring(left) < tostring(right)
    end)
    for _, id in ipairs(orderIds) do
        local order = Repository.State.byId[id]
        local workerId = tostring(order.workerId or "")
        local worker = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(workerId) or nil
        local valid = worker and worker.alive ~= false
            and worker.runtime
            and tostring(worker.runtime.workOrderId or "")
                == tostring(order.id or "")
        if valid and (workers[workerId]
            or order.stationId and stations[tostring(order.stationId)])
        then
            valid = false
        end
        if valid then
            workers[workerId] = order.id
            if order.stationId then
                stations[tostring(order.stationId)] = order.id
            end
        else
            releaseClaim(order, "stale_worker_claim", false, true)
            if order.status ~= Status.PAUSED
                and order.status ~= Status.CANCELLING
            then
                order.status = Status.WAITING_FOR_WORKER
                order.blockedReason = nil
            end
            order.updatedAt, order.revision = now(), order.revision + 1
            Repository.MarkDirty()
            markAssignmentDirty(order, "STALE_WORKER_CLAIM_RECOVERED")
            repaired = repaired + 1
        end
    end
    Service.ClaimsByWorker, Service.ClaimsByStation = workers, stations
    if PNC.Registry and PNC.Registry.ForEach then
        PNC.Registry.ForEach(function(record)
            local runtimeOrder = assignedOrderForRecord(record)
            local spec = record and record.orderSpec or nil
            local specOrder = spec and spec.kind == "production_work"
                and Repository.Get(spec.workOrderId) or nil
            local specValid = specOrder and not terminal(specOrder)
                and tostring(specOrder.workerId or "")
                    == tostring(record.id or "")
                and runtimeOrder
                and tostring(specOrder.id or "")
                    == tostring(runtimeOrder.id or "")
            if spec and spec.kind == "production_work"
                and not specValid and not runtimeOrder
            then
                clearStaleWorkerState(record, specOrder,
                    "stale_work_order_spec")
                repaired = repaired + 1
            elseif record.runtime and record.runtime.workOrderId
                and not runtimeOrder
            then
                clearStaleWorkerState(record, specOrder,
                    "stale_work_order_runtime")
                repaired = repaired + 1
            end
        end)
    end
    return repaired
end


return Service
