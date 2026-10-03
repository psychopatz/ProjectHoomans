-- Lumber WorkService order creation and reconciliation bridge.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberWorkAdapter = PNC.LumberWorkAdapter or {}

local Adapter = PNC.LumberWorkAdapter
local Internal = Adapter.Internal or {}
local Work = Internal.Work
local Service = Internal.Service
local Status = Internal.Status
local recordFor = Internal.RecordFor
local publishWorkerWait = Internal.PublishWorkerWait
local markDirty = Internal.MarkDirty

function Adapter.EnsureOrder(job)
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not job or job.active ~= true
    then return false, "WORK_SERVICE_UNAVAILABLE" end
    local existing = job.workOrderId and Work.Queries
        and Work.Queries.Get and Work.Queries.Get(job.workOrderId) or nil
    if existing and existing.status ~= Status.CANCELLED
        and existing.status ~= Status.COMPLETED
        and existing.status ~= Status.FAILED
    then
        publishWorkerWait(job, existing)
        return true, existing
    end
    local worker = recordFor(job.npcId)
    local base = PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(worker, job.baseId) or nil
    local baseId = tostring(job.baseId or "")
    if baseId == "" and base then baseId = tostring(base.id or "") end
    if base and base.id then job.baseId = base.id end
    local order, reason = Work.Commands.Queue({
        operation = "LUMBER",
        colonyId = base and base.colonyId or "",
        factionId = base and base.factionId or "",
        baseId = baseId,
        requiredWorkerId = job.npcId, requiredWork = 1, priority = 90,
        locationPolicy = { start = "ANYWHERE", execution = "REMOTE",
            returnHome = "STAY" },
        payload = {
            lumberJobId = job.id, zoneId = job.zoneId, npcId = job.npcId,
        },
    })
    if not order then return false, reason or "LUMBER_WORK_ORDER_FAILED" end
    job.workOrderId = order.id
    publishWorkerWait(job, order)
    markDirty()
    return true, order
end

function Adapter.CancelOrder(job, reason)
    if not job or not job.workOrderId or not Work
        or not Work.Commands or not Work.Commands.Cancel
    then return false end
    local order = Work.Queries and Work.Queries.Get
        and Work.Queries.Get(job.workOrderId) or nil
    if not order or order.status == Status.CANCELLED
        or order.status == Status.COMPLETED or order.status == Status.FAILED
    then return true end
    local ok = Work.Commands.Cancel(job.workOrderId,
        reason or "lumber_job_cancelled")
    return ok == true
end

function Adapter.Reconcile()
    if not Service or not Service.Data or not Service.Data.jobs then return 0 end
    local count = 0
    for _, job in pairs(Service.Data.jobs) do
        if job and job.active == true then
            local ok = Adapter.EnsureOrder(job)
            if ok then count = count + 1 end
        end
    end
    return count
end

if Work and Work.RegisterTargetProvider then
    Work.RegisterTargetProvider("LUMBER", Adapter.Target)
end
if Work and Work.RegisterExecution then
    Work.RegisterExecution("LUMBER", Adapter.Execute)
end
if Work and Work.RegisterAbstractExecution then
    Work.RegisterAbstractExecution("LUMBER", Adapter.Execute)
end
if Work then
    Work.CompletionHandlers = Work.CompletionHandlers or {}
    Work.CompletionHandlers.LUMBER = Adapter.Complete
    Work.CancellationHandlers = Work.CancellationHandlers or {}
    Work.CancellationHandlers.LUMBER = Adapter.Cancel
end


return Adapter
