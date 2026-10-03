-- WorkService stale NPC worker state reconciliation provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local terminal = Internal.terminal
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
    if PNC.Tasking and PNC.Tasking.Events
        and PNC.Tasking.Events.Emit
    then
        PNC.Tasking.Events.Emit("STALE_WORK_ORDER_RECOVERED", {
            npcId = record.id, source = "WorkService.Reconciliation",
            entityId = workOrder and workOrder.id,
        })
    end
    return true
end

local function reconcileWorkerRecords()
    local repaired = 0
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

Internal.ReconcileWorkerRecords = reconcileWorkerRecords

return Service
