-- Management snapshots, periodic orchestration, and PZ event hooks.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local copy = Internal.Copy
local now = Internal.Now
local ensureData = Internal.EnsureData
local expireClaims = Internal.ExpireClaims
local reconcileLoadedSquare = Internal.ReconcileLoadedSquare

function Service.GetSnapshot(zoneId)
    local zone = Service.GetZone(zoneId)
    if not zone then return nil end
    local available, inProgress, depleted = 0, 0, 0
    for index = 1, #(zone.treeKeys or {}) do
        local tree = Service.Data.trees[zone.treeKeys[index]]
        if tree then
            if tree.status == "DEPLETED" then depleted = depleted + 1
            elseif tree.status == "IN_PROGRESS" then inProgress = inProgress + 1
            elseif tree.status ~= "INVALID" then available = available + 1 end
        end
    end
    local workers = {}
    for npcId, _ in pairs(zone.workers or {}) do
        local job = Service.GetJob(npcId)
        local workerRecord = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(tostring(npcId)) or nil
        local runtime = workerRecord and workerRecord.runtime
            and workerRecord.runtime.lumber or nil
        local tree = job and job.targetKey
            and Service.GetTree(job.targetKey) or nil
        local workOrder = job and job.workOrderId and PNC.WorkRepository
            and PNC.WorkRepository.Get
            and PNC.WorkRepository.Get(job.workOrderId) or nil
        workers[#workers + 1] = {
            npcId = npcId, jobId = job and job.id or nil,
            state = job and job.state or "MISSING",
            phase = job and job.phase or "MISSING",
            treeKey = job and job.targetKey or nil,
            executionMode = job and job.executionMode or nil,
            workOrderId = job and job.workOrderId or nil,
            workOrderStatus = workOrder and workOrder.status or nil,
            workOrderProgress = workOrder and workOrder.progress or nil,
            workOrderRequiredWork = workOrder
                and workOrder.requiredWork or nil,
            waitingReason = runtime and runtime.waitingReason or nil,
            waitingFor = runtime and runtime.waitingFor or nil,
            toolDiagnostic = copy(runtime and runtime.tool or nil),
            remainingWork = tree and tree.remainingWork or nil,
            maxWork = tree and tree.maxWork or nil,
            approach = copy(job and job.approach or nil),
        }
    end
    return {
        id = zone.id, revision = zone.revision, enabled = zone.enabled,
        bounds = copy(zone.bounds), geometry = copy(zone.geometry),
        scan = copy(zone.scan),
        discovered = #(zone.treeKeys or {}), available = available,
        inProgress = inProgress, depleted = depleted, workers = workers,
    }
end

function Service.Pump(at)
    if not Service.Loaded then Service.Load(true) end
    at = tonumber(at) or now()
    if at < (tonumber(Service.Runtime.nextPumpAt) or 0) then return 0 end
    Service.Runtime.nextPumpAt = at + Service.SCAN_INTERVAL_MS
    expireClaims(at)
    local data = ensureData()
    local processed = 0
    local count = #data.zoneOrder
    if count > 0 then
        for _ = 1, Service.SCAN_ZONES_PER_PUMP do
            Service.Runtime.zoneCursor =
                (Service.Runtime.zoneCursor % count) + 1
            local zone = data.zones[data.zoneOrder[Service.Runtime.zoneCursor]]
            if zone and zone.enabled and not zone.scan.complete then
                Service.ScanZone(zone.id, Service.SCAN_TILES_PER_PUMP)
                processed = processed + 1
            end
        end
    end
    if PNC.LumberWorkAdapter and PNC.LumberWorkAdapter.Reconcile
        and at >= (tonumber(Service.Runtime.nextWorkReconcileAt) or 0)
    then
        Service.Runtime.nextWorkReconcileAt = at
            + Service.WORK_RECONCILE_INTERVAL_MS
        PNC.LumberWorkAdapter.Reconcile()
    end
    if Service.Dirty and at - Service.LastSaveAt >= 5000 then
        Service.Save()
    end
    return processed
end

if Events and Events.OnInitGlobalModData and not Service.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Service.Load(true) end)
    Service.LoadHookRegistered = true
end
if Events and Events.OnSave and not Service.SaveHookRegistered then
    Events.OnSave.Add(function() Service.Save() end)
    Service.SaveHookRegistered = true
end
if Events and Events.LoadGridsquare and not Service.LoadSquareHookRegistered then
    Events.LoadGridsquare.Add(function(square)
        if not Service.Loaded then Service.Load(true) end
        reconcileLoadedSquare(square)
    end)
    Service.LoadSquareHookRegistered = true
end

return Service
