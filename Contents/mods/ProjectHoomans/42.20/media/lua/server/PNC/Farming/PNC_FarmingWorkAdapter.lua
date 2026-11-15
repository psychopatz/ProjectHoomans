-- Farming WorkService operation registration and cleanup adapter.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingWorkAdapter = PNC.FarmingWorkAdapter or {}

local Adapter = PNC.FarmingWorkAdapter
local Work = PNC.WorkService

require "PNC/Farming/PNC_FarmingWorkAdapter_Selection"
require "PNC/Farming/PNC_FarmingWorkAdapter_OrderBridge"
require "PNC/Farming/PNC_FarmingWorkAdapter_Actions"
require "PNC/Farming/PNC_FarmingWorkAdapter_Execution"

local Internal = Adapter.Internal

---Releases output reservations, staged inputs, and held FARMING digging tools.
function Adapter.Complete(order)
    local worker = Internal and Internal.RecordFor
        and Internal.RecordFor(order and order.workerId) or nil
    if order and PNC.WorkOutputService
        and PNC.WorkOutputService.ReleaseOutputCapacity
    then
        PNC.WorkOutputService.ReleaseOutputCapacity(order, PNC.ColonyStorageService)
    end
    if order and PNC.WorkInputService and PNC.WorkInputService.Cancel then
        local ok, reason = PNC.WorkInputService.Cancel(order)
        if ok == false then return false, reason end
    end
    if worker and PNC.WorkItemService and PNC.WorkItemService.Release then
        local released, releaseReason = PNC.WorkItemService.Release(
            worker, "FARMING", nil, { reason = "farming_work_complete" })
        if released == false then return false, releaseReason end
    end
    return true
end

---Cancels a FARMING work order and cleans up reservations and tools.
function Adapter.Cancel(order)
    return Adapter.Complete(order)
end

if Work and Work.RegisterOperation then
    Work.RegisterOperation("FARMING", {
        TargetProvider = Adapter.Target,
        ExecutionHandler = Adapter.ExecuteLive,
        AbstractExecutionHandler = Adapter.ExecuteAbstract,
        CompletionHandler = Adapter.Complete,
        CleanupHandler = Adapter.Cancel,
        CancelHandler = Adapter.Cancel,
    })
end

return Adapter
