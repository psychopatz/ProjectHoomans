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

local function zoneHasActionableWork(zone)
    if not zone or zone.enabled ~= true then return false end
    if zone.scan and zone.scan.complete ~= true then return true end
    for index = 1, #(zone.treeKeys or {}) do
        local tree = Service.GetTree and Service.GetTree(zone.treeKeys[index]) or nil
        if tree and tree.status ~= "DEPLETED" and tree.status ~= "INVALID" then
            return true
        end
    end
    return false
end

local function baseForZone(zone, worker)
    local base = PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(worker, zone and zone.baseId) or nil
    if not base and PNC.BaseService then
        if zone and zone.baseId and PNC.BaseService.Get then
            base = PNC.BaseService.Get(zone.baseId)
        end
        if not base and PNC.BaseService.GetForColony then
            base = PNC.BaseService.GetForColony(zone and zone.ownerId)
        end
    end
    return base
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
    local zoneOrderId = "lumber-zone:" .. tostring(job.zoneId or "")
    local claimedAutonomous = Work.Queries and Work.Queries.Get
        and Work.Queries.Get(zoneOrderId) or nil
    if claimedAutonomous and tostring(claimedAutonomous.workerId or "")
        == tostring(job.npcId or "")
        and claimedAutonomous.status ~= Status.CANCELLED
        and claimedAutonomous.status ~= Status.COMPLETED
        and claimedAutonomous.status ~= Status.FAILED
    then
        job.workOrderId = claimedAutonomous.id
        if type(claimedAutonomous.payload) == "table" then
            claimedAutonomous.payload.lumberJobId = job.id
            claimedAutonomous.payload.npcId = job.npcId
        end
        publishWorkerWait(job, claimedAutonomous)
        markDirty()
        return true, claimedAutonomous
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
        precedence = "FORCED_ORDER",
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

---Maintains an autonomous NORMAL_WORK lumber order for enabled zones.
function Adapter.EnsureZoneOrder(zone)
    if not Work or not Work.Commands or not Work.Commands.Queue
        or not zone or not zone.id
    then return false, "WORK_SERVICE_UNAVAILABLE" end
    local orderId = "lumber-zone:" .. tostring(zone.id)
    local existing = Work.Queries and Work.Queries.Get
        and Work.Queries.Get(orderId) or nil
    local actionable = zoneHasActionableWork(zone)
    if not actionable then
        if existing and not existing.workerId
            and existing.status ~= Status.CANCELLED
            and existing.status ~= Status.COMPLETED
            and existing.status ~= Status.FAILED
            and Work.Commands.Cancel
        then
            Work.Commands.Cancel(orderId, "lumber_zone_inactive")
        end
        return false, "LUMBER_ZONE_INACTIVE"
    end
    if existing and existing.status ~= Status.CANCELLED
        and existing.status ~= Status.COMPLETED
        and existing.status ~= Status.FAILED
    then
        return true, existing
    end
    local base = baseForZone(zone, nil)
    local order, reason = Work.Commands.Queue({
        id = orderId,
        operation = "LUMBER",
        colonyId = base and base.colonyId or "",
        factionId = base and base.factionId or "",
        baseId = tostring(zone.baseId or (base and base.id) or ""),
        requiredWorkerId = nil, requiredWork = 1, priority = 50,
        precedence = "NORMAL_WORK",
        locationPolicy = { start = "ANYWHERE", execution = "REMOTE",
            returnHome = "STAY" },
        payload = { zoneId = zone.id, autonomous = true },
    })
    if not order then return false, reason or "LUMBER_ZONE_ORDER_FAILED" end
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
    if not Service or not Service.Data then return 0 end
    local count = 0
    for _, job in pairs(Service.Data.jobs or {}) do
        if job and job.active == true then
            local ok = Adapter.EnsureOrder(job)
            if ok then count = count + 1 end
        end
    end
    for _, zone in pairs(Service.Data.zones or {}) do
        if zone and Adapter.EnsureZoneOrder(zone) then
            count = count + 1
        end
    end
    return count
end

if Work and Work.RegisterOperation then
    Work.RegisterOperation("LUMBER", {
        TargetProvider = Adapter.Target,
        ExecutionHandler = Adapter.Execute,
        AbstractExecutionHandler = Adapter.Execute,
        CompletionHandler = Adapter.Complete,
        CleanupHandler = Adapter.Cancel,
        CancelHandler = Adapter.Cancel,
    })
else
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
end
if Work and Work.RegisterReconciler then
    Work.RegisterReconciler("LUMBER", Adapter.Reconcile)
end


return Adapter
