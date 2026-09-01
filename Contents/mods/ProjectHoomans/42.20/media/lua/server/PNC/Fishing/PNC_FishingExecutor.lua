-- Tasking adapter for fishing jobs. FishingService owns zone state, spot
-- reservations, work points, and inventory mutation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FishingExecutor = PNC.FishingExecutor or {}

local Executor = PNC.FishingExecutor
local Service = PNC.FishingService
local Const = PNC.Const or {}

local function liveBody(npcId)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(tostring(npcId or "")) or nil
end

local function recordFor(npcId)
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
end

function Executor.GetCandidates(npcId)
    local job = Service and Service.GetJob and Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = recordFor(npcId)
    if not job or not zone or not record or job.active ~= true
        or zone.enabled ~= true or not Service.ValidateZone(zone)
        or record.allowedJobs and record.allowedJobs.Fishing == false
        or not Service.IsNearby(record, zone)
    then return {} end
    return {{
        taskId = tostring(job.id), npcId = tostring(npcId), kind = "FISHING",
        sourceDomain = "fishing", sourceRef = tostring(job.id),
        precedence = "FORCED_ORDER", urgency = 0.72,
        capability = "fishing", interruptPolicy = "NORMAL",
        revision = job.revision, createdAt = job.createdAt or 0,
    }}
end

function Executor.Validate(intent)
    local npcId = intent and intent.npcId
    local job = Service and Service.GetJob and Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = recordFor(npcId)
    return Service and Service.ValidateJob
        and Service.ValidateJob(npcId, intent and intent.sourceRef)
        and record ~= nil
        and not (record.allowedJobs
            and record.allowedJobs.Fishing == false)
        and Service.IsNearby(record, zone) or false
end

function Executor.Assign(intent)
    local job = Service and Service.GetJob and Service.GetJob(intent and intent.npcId)
    if not job or tostring(job.id) ~= tostring(intent and intent.sourceRef) then
        return nil, "fishing_job_missing"
    end
    return {
        executionMode = liveBody(intent.npcId) and "LIVE" or "ABSTRACT",
        resourceKey = job.id, resourceKind = "FISHING_JOB",
    }
end

function Executor.Start(lease)
    return Service.StartJob(lease)
end

function Executor.CanContinue(lease)
    local job = Service and Service.GetJob(lease and lease.npcId)
    return job ~= nil and job.active == true
        and tostring(job.id) == tostring(lease and lease.sourceRef)
        and tostring(job.leaseId or "") == tostring(lease and lease.leaseId)
end

function Executor.Tick(lease)
    local ok, complete, reason = Service.TickJob(lease)
    if not ok then
        if PNC.Tasking and PNC.Tasking.Commands
            and PNC.Tasking.Commands.CancelLease
        then
            PNC.Tasking.Commands.CancelLease(lease.leaseId,
                reason or "fishing_job_failed")
        end
        return false
    end
    if complete and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.Complete
    then
        PNC.Tasking.Commands.Complete(lease.leaseId,
            reason or "fishing_complete")
    end
    return true
end

function Executor.Cancel(lease, reason)
    if Service and Service.CancelJob then
        return Service.CancelJob(lease and lease.npcId,
            reason or "fishing_task_cancelled")
    end
    return true
end

function Executor.Complete(lease)
    return Executor.Cancel(lease, "fishing_complete")
end

if PNC.Tasking and PNC.Tasking.Commands
    and PNC.Tasking.Commands.RegisterProvider
then
    PNC.Tasking.Commands.RegisterProvider("fishing", Executor)
end

return Executor
