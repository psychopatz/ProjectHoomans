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
local Repository = PNC.WorkRepository

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

local function statusForJob(job)
    local phase = tostring(job and job.phase or "")
    if phase == "CHOPPING" or phase == "GRAB_PENDING"
        or phase == "DEPOSIT_PENDING"
    then
        return Status.WORKING or "WORKING"
    end
    if phase == "WAITING_FOR_WORKER" then
        return Status.WAITING_FOR_WORKER or "WAITING_FOR_WORKER"
    end
    if phase == "WAITING_FOR_TOOL"
        or phase == "WAITING_FOR_ENDURANCE"
        or phase == "WAITING_FOR_STOCKPILE"
    then
        return Status.WAITING_RESOURCE or "WAITING_RESOURCE"
    end
    if phase == "WAITING_FOR_TREE_CHUNK"
        or phase == "WAITING_FOR_MATERIALIZATION"
    then
        return Status.WAITING_FOR_WORLD or "WAITING_FOR_WORLD"
    end
    if phase == "OUTPUT_DESTINATION_APPROACH"
        or phase == "CARRYING"
    then
        return Status.TRAVEL_TO_STOCKPILE or "TRAVEL_TO_STOCKPILE"
    end
    if phase == "TRAVEL" or phase == "OUTPUT_APPROACH" then
        return Status.TRAVEL_TO_STATION or "TRAVEL_TO_STATION"
    end
    return Status.WAITING_RESOURCE or "WAITING_RESOURCE"
end

local function updateLiveTarget(order, job)
    if not order or not job or not order.workerId then
        return
    end
    local record = recordFor(order.workerId)
    if not record or not record.orderSpec
        or record.orderSpec.kind ~= "production_work"
    then return end
    local projectionChanged = false
    local projectedStatus = statusForJob(job)
    if projectedStatus
        and order.status ~= Status.CANCELLED
        and order.status ~= Status.COMPLETED
        and order.status ~= Status.FAILED
        and order.status ~= Status.CANCELLING
        and order.status ~= projectedStatus
    then
        order.status = projectedStatus
        projectionChanged = true
    end
    local progressAt = tonumber(job.lastProgressAt)
    if progressAt and tonumber(order.lastProgressAt) ~= progressAt then
        order.lastProgressAt = progressAt
        projectionChanged = true
    end
    local target = job.approach
    local targetKind = "lumber_tree"
    if job.pendingOutput then
        targetKind = "lumber_output"
        if job.phase == "OUTPUT_DESTINATION_APPROACH"
            and job.outputDestination
        then
            target = job.outputDestination
        else
            local tree = Service.GetTree(job.pendingOutput.treeKey)
            target = tree and {
                x = tree.x + 0.5, y = tree.y + 0.5, z = tree.z,
            } or target
        end
    end
    if not target then
        if projectionChanged and Repository and Repository.MarkDirty then
            Repository.MarkDirty()
        end
        return
    end
    order.stationTarget = {
        x = target.x, y = target.y, z = target.z,
    }
    order.targetKind = targetKind
    order.phase = job.phase
    order.livePhase = job.phase
    local setLiveOrder = Work and Work.Internal and Work.Internal.setLiveOrder
    if setLiveOrder then
        setLiveOrder(record, order, order.stationTarget, job.phase)
    end
    if projectionChanged and Repository and Repository.MarkDirty then
        Repository.MarkDirty()
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

if WorldEffects and WorldEffects.RegisterProvider
    and WorldEffects.Register
then
    WorldEffects.RegisterProvider("LUMBER", {
        List = function()
            local output = {}
            for _, tree in pairs(Service.Data and Service.Data.trees or {}) do
                if type(tree) == "table"
                    and (type(tree.worldEffect) == "table"
                        or type(tree.outputEffect) == "table")
                then
                    output[#output + 1] = tree
                end
            end
            return output
        end,
        GetOwnerID = function(tree) return tree and tree.key end,
        GetEffects = function(tree)
            local output = {}
            if type(tree and tree.worldEffect) == "table" then
                output[#output + 1] = tree.worldEffect
            end
            if type(tree and tree.outputEffect) == "table" then
                output[#output + 1] = tree.outputEffect
            end
            return output
        end,
        -- LUMBER_OUTPUT is visible in the same ledger snapshot but is not a
        -- generic loaded-square mutation. Its state machine is owned by the
        -- lumber worker, so the world-effects pump must not auto-apply it.
        IsPending = function(_, effect)
            if tostring(effect and effect.kind or "") ~= "TREE_REMOVE" then
                return false
            end
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
