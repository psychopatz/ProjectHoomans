-- WorkService bridge for lumber jobs.
--
-- WorkService owns the durable worker/order lifecycle. LumberService remains
-- the sole authority for the selected map zone, tree claims, work points,
-- physical tree hits, abstract progress, and log output.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberWorkAdapter = PNC.LumberWorkAdapter or {}

local Adapter = PNC.LumberWorkAdapter
local Work = PNC.WorkService
local Service = PNC.LumberService
local Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
local WorldEffects = PNC.WorldEffectService

local function recordFor(npcId)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(
        tostring(npcId or "")) or nil
end

local function jobForOrder(order)
    local payload = order and order.payload or nil
    local jobId = payload and tostring(payload.lumberJobId or "") or ""
    local npcId = payload and tostring(payload.npcId or "") or ""
    local job = npcId ~= "" and Service and Service.GetJob
        and Service.GetJob(npcId) or nil
    if not job or jobId == "" or tostring(job.id) ~= jobId then return nil end
    return job
end

local function zoneCenter(zone)
    local bounds = zone and zone.bounds or nil
    if not bounds then return nil end
    return {
        x = (tonumber(bounds.minX) + tonumber(bounds.maxX)) / 2 + 0.5,
        y = (tonumber(bounds.minY) + tonumber(bounds.maxY)) / 2 + 0.5,
        z = (tonumber(bounds.minZ) or 0) + 0.0,
    }
end

local function clearRuntime(record)
    if not record or not record.runtime then return end
    record.runtime.lumber = nil
    record.runtime.lumberJobId = nil
end

local function publishWorkerWait(job, order)
    local record = recordFor(job and job.npcId)
    if not record or not order or order.workerId then return end
    local status = tostring(order.status or "QUEUED")
    if status ~= tostring(Status.QUEUED or "QUEUED")
        and status ~= tostring(Status.WAITING_FOR_WORKER
            or "WAITING_FOR_WORKER")
    then return end
    record.runtime = record.runtime or {}
    local current = record.runtime.lumber
    if current and current.phase ~= "WAITING"
        and current.phase ~= "WAITING_FOR_WORKER"
    then return end
    record.runtime.lumber = {
        jobId = job.id, zoneId = job.zoneId,
        workOrderId = order.id, phase = "WAITING_FOR_WORKER",
        state = "WAITING", waitingFor = "worker",
        waitingReason = status,
    }
    record.activeJob = "Lumber"
    record.activeBehavior = "Lumber:WAITING_FOR_WORKER"
end

local function markDirty()
    if Service then Service.Dirty = true end
end

local function bind(order, lease, job)
    if not order or not lease or not job then return false end
    job.workOrderId = order.id
    job.leaseId = lease.leaseId
    job.executionMode = tostring(lease.executionMode or "ABSTRACT")
    local record = recordFor(order.workerId)
    if record then
        record.runtime = record.runtime or {}
        record.runtime.lumberJobId = job.id
    end
    markDirty()
    return true
end

local function updateLiveTarget(order, job)
    if not order or not job or not job.approach or not order.workerId then
        return
    end
    local record = recordFor(order.workerId)
    if not record or not record.orderSpec
        or record.orderSpec.kind ~= "production_work"
    then return end
    order.stationTarget = {
        x = job.approach.x, y = job.approach.y, z = job.approach.z,
    }
    order.targetKind = "lumber_tree"
    order.livePhase = job.phase
    local setLiveOrder = Work and Work.Internal and Work.Internal.setLiveOrder
    if setLiveOrder then
        setLiveOrder(record, order, order.stationTarget,
            job.phase == "CHOPPING" and "WORK_AT_STATION" or "TRAVEL")
    end
end

function Adapter.Target(order, worker)
    local job = jobForOrder(order)
    local zone = job and Service.GetZone(job.zoneId) or nil
    if not job or not zone or zone.enabled ~= true then
        return nil, "LUMBER_JOB_UNAVAILABLE"
    end
    local target
    local tree = job.targetKey and Service.GetTree(job.targetKey) or nil
    if tree and Service.FindApproach then
        target = Service.FindApproach(tree, worker)
    end
    target = target or zoneCenter(zone)
    if not target then return nil, "LUMBER_ZONE_TARGET_MISSING" end
    return {
        ok = true,
        componentId = "lumber:" .. tostring(job.id),
        claimKey = "lumber:" .. tostring(job.id),
        targetKind = "lumber_zone",
        target = target,
        phase = job.phase == "CHOPPING" and "WORK_AT_STATION" or "TRAVEL",
    }
end

function Adapter.Execute(order, lease)
    local job = jobForOrder(order)
    if not job or job.active ~= true then
        return false, "LUMBER_JOB_UNAVAILABLE"
    end
    if tostring(job.leaseId or "") ~= tostring(lease.leaseId or "") then
        bind(order, lease, job)
    end
    local ok, complete, reason = Service.TickJob(lease)
    if not ok then return false, reason or "LUMBER_EXECUTION_FAILED" end
    updateLiveTarget(order, job)
    if complete then
        local progressed, progressReason = Work.Commands.AddProgress(
            order.id, order.workerId, order.requiredWork)
        if progressed ~= true then
            return false, progressReason or "LUMBER_COMPLETION_FAILED"
        end
    end
    return true
end

function Adapter.Complete(order)
    local job = jobForOrder(order)
    if not job then return true end
    if Service.ReleaseTree then
        Service.ReleaseTree(job.targetKey, "lumber_work_complete")
    end
    job.active = false
    job.leaseId = nil
    job.workOrderId = nil
    job.targetKey, job.approach = nil, nil
    job.state, job.phase = "COMPLETED", "COMPLETE"
    job.revision = (tonumber(job.revision) or 0) + 1
    clearRuntime(recordFor(order.workerId))
    markDirty()
    return true
end

function Adapter.Cancel(order)
    local job = jobForOrder(order)
    if not job then return true end
    if Service.ReleaseTree then
        Service.ReleaseTree(job.targetKey, "lumber_work_released")
    end
    local terminal = order.status == Status.CANCELLING
        or order.cancellationRequested == true
    job.leaseId = nil
    job.workOrderId = terminal and nil or order.id
    job.targetKey, job.approach = nil, nil
    job.active = not terminal
    job.state = terminal and "CANCELLED" or "READY"
    job.phase = terminal and "CANCELLED" or "WAITING"
    job.revision = (tonumber(job.revision) or 0) + 1
    clearRuntime(recordFor(order.workerId))
    markDirty()
    return true
end

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
    local order, reason = Work.Commands.Queue({
        operation = "LUMBER", colonyId = "", factionId = "", baseId = "",
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

if WorldEffects and WorldEffects.RegisterProvider
    and WorldEffects.Register
then
    WorldEffects.RegisterProvider("LUMBER", {
        List = function()
            local output = {}
            for _, tree in pairs(Service.Data and Service.Data.trees or {}) do
                if type(tree) == "table" and type(tree.worldEffect) == "table" then
                    output[#output + 1] = tree
                end
            end
            return output
        end,
        GetOwnerID = function(tree) return tree and tree.key end,
        GetEffects = function(tree)
            return tree and type(tree.worldEffect) == "table"
                and { tree.worldEffect } or {}
        end,
        IsPending = function(_, effect)
            local state = tostring(effect and effect.state or "PENDING")
            return state ~= "APPLIED" and state ~= "CANCELLED"
                and state ~= "CONFLICT" and state ~= "FAILED"
        end,
        MarkDirty = function() Service.Dirty = true end,
    })
    WorldEffects.Register("TREE_REMOVE", {
        Apply = function(tree, effect)
            return Service.ApplyDeferredTreeRemoval(tree, effect)
        end,
        GetPoints = function(tree, effect)
            return { {
                role = "target", x = effect.x or tree.x,
                y = effect.y or tree.y, z = effect.z or tree.z,
            } }
        end,
    })
end

return Adapter
