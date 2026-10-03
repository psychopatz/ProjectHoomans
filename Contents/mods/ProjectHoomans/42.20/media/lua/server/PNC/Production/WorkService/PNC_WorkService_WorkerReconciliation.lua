-- WorkService worker reconciliation composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

require "PNC/Production/WorkService/PNC_WorkService_WorkerReconciliation_Claims"
require "PNC/Production/WorkService/PNC_WorkService_WorkerReconciliation_State"

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository

function Service.ReconcileWorkerState()
    Repository.Load()
    return Internal.RebuildWorkerClaims()
        + Internal.ReconcileWorkerRecords()
end

return Service
