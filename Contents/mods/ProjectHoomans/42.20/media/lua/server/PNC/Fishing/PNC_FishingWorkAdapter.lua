-- Fishing WorkService operation adapter and lifecycle handlers.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FishingWorkAdapter = PNC.FishingWorkAdapter or {}

local Adapter = PNC.FishingWorkAdapter
local Work = PNC.WorkService
local Service = PNC.FishingService
local Repository = PNC.WorkRepository

local function recordFor(npcId)
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
end

local function isCamped(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.IsCamped
        and PNC.HomeDutyService.IsCamped(record) == true
end

local function zoneCenter(zone)
    local b = zone and zone.bounds
    if b then
        return {
            x = math.floor((b.minX + b.maxX) / 2),
            y = math.floor((b.minY + b.maxY) / 2),
            z = tonumber(b.minZ) or 0,
        }
    end
    local spot = zone and zone.fishingSpots and zone.fishingSpots[1]
    if spot then
        return { x = spot.standX, y = spot.standY, z = spot.standZ or 0 }
    end
    return nil
end

local function jobForOrder(order)
    if not Service or not Service.GetJob then return nil end
    local payload = order and order.payload
    local npcId = (payload and payload.npcId) or (order and order.workerId)
        or (order and order.requiredWorkerId)
    local job = npcId and Service.GetJob(npcId) or nil
    if job and payload and payload.fishingJobId
        and tostring(job.id) ~= tostring(payload.fishingJobId)
    then
        return nil
    end
    return job
end

---Resolves the fishing spot or zone center target for a FISHING work order.
function Adapter.Target(order, worker)
    if worker and isCamped(worker) then return nil, "NPC_CAMPED" end
    local job = jobForOrder(order)
    if not job and order and order.payload and order.payload.zoneId
        and not order.requiredWorkerId
    then
        local zone = Service.GetZone(order.payload.zoneId)
        if not zone or not Service.ValidateZone(zone) then
            return nil, "FISHING_ZONE_INVALID"
        end
        local spot = zone.fishingSpots and zone.fishingSpots[1]
        local target = spot and { x = spot.standX, y = spot.standY, z = spot.standZ or 0 }
            or zoneCenter(zone)
        if not target then return nil, "FISHING_SPOT_MISSING" end
        return {
            ok = true,
            componentId = "fishing-zone:" .. tostring(zone.id),
            claimKey = "fishing-zone:" .. tostring(zone.id),
            targetKind = "fishing_zone",
            target = target,
            phase = "TRAVEL",
        }
    end
    local zone = job and Service.GetZone(job.zoneId) or nil
    if not job or not zone or not Service.ValidateZone(zone) then
        return nil, "FISHING_JOB_UNAVAILABLE"
    end
    local spot = job.spot or (zone.fishingSpots and zone.fishingSpots[1])
    local target = spot and { x = spot.standX, y = spot.standY, z = spot.standZ or 0 }
        or zoneCenter(zone)
    if not target then return nil, "FISHING_SPOT_MISSING" end
    return {
        ok = true,
        componentId = "fishing:" .. tostring(job.id),
        claimKey = "fishing:" .. tostring(job.id),
        targetKind = "fishing_zone",
        target = target,
        phase = job.phase == "WORKING" and "WORK_AT_STATION" or "TRAVEL",
    }
end

---Executes live or abstract fishing work under WorkService lease ownership.
function Adapter.Execute(order, lease)
    local job = jobForOrder(order)
    if (not job or job.active ~= true) and order and order.workerId
        and order.payload and order.payload.zoneId
        and type(Service.AssignWorker) == "function"
    then
        local okAssign, assigned = Service.AssignWorker(
            order.payload.zoneId, order.workerId)
        if okAssign and type(assigned) == "table" then job = assigned end
    end
    if not job or job.active ~= true then
        return false, "FISHING_JOB_UNAVAILABLE"
    end
    if tostring(job.leaseId or "") ~= tostring(lease and lease.leaseId or "") then
        local started, startReason = Service.StartJob(lease)
        if not started then return false, startReason or "FISHING_START_FAILED" end
        job.workOrderId = order.id
    end
    local ok, complete, reason = Service.TickJob(lease)
    if not ok then return false, reason or "FISHING_EXECUTION_FAILED" end
    local spot = job.spot
    if spot and order and Repository then
        order.target = { x = spot.standX, y = spot.standY, z = spot.standZ or 0 }
        local record = recordFor(order.workerId)
        if record and type(record.orderSpec) == "table" then
            record.orderSpec.x, record.orderSpec.y, record.orderSpec.z =
                spot.standX, spot.standY, spot.standZ or 0
            record.orderSpec.phase = tostring(job.phase or "WORKING")
        end
    end
    if complete then
        local progressed, progressReason = Work.Commands.AddProgress(
            order.id, order.workerId, order.requiredWork)
        if progressed ~= true then
            return false, progressReason or "FISHING_COMPLETION_FAILED"
        end
    end
    return true
end

---Releases storage reservations, held fishing tools, and job state on finish.
function Adapter.Complete(order)
    local job = jobForOrder(order)
    local record = recordFor(order and order.workerId)
    if job and PNC.WorkOutputService and PNC.WorkOutputService.ReleaseOutputCapacity then
        PNC.WorkOutputService.ReleaseOutputCapacity(job, PNC.ColonyStorageService)
    end
    if record and PNC.WorkItemService and PNC.WorkItemService.Release then
        local released, releaseReason = PNC.WorkItemService.Release(
            record, "FISHING", nil, { reason = "fishing_work_complete" })
        if released == false then return false, releaseReason end
    end
    if job and Service and Service.CancelJob then
        Service.CancelJob(job.npcId, "fishing_work_complete")
    end
    return true
end

---Cancels a FISHING work order using the shared cleanup handler.
function Adapter.Cancel(order)
    return Adapter.Complete(order)
end

require "PNC/Fishing/PNC_FishingWorkAdapter_OrderBridge"

if Work and Work.RegisterOperation then
    Work.RegisterOperation("FISHING", {
        TargetProvider = Adapter.Target,
        ExecutionHandler = Adapter.Execute,
        AbstractExecutionHandler = Adapter.Execute,
        CompletionHandler = Adapter.Complete,
        CleanupHandler = Adapter.Cancel,
        CancelHandler = Adapter.Cancel,
    })
end
if Work and Work.RegisterReconciler then
    Work.RegisterReconciler("FISHING", Adapter.Reconcile)
end

return Adapter
