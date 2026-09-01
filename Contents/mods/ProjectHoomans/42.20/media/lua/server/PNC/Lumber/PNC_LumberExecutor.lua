-- Tasking adapter for lumber jobs. The service owns world-resource state;
-- this module only exposes it to the shared task arbiter.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberExecutor = PNC.LumberExecutor or {}

local Executor = PNC.LumberExecutor
local Service = PNC.LumberService

local function recordFor(npcId)
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
end

local function liveBody(npcId)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(tostring(npcId or "")) or nil
end

function Executor.GetCandidates(npcId)
    local job = Service and Service.GetJob and Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local record = recordFor(npcId)
    if not job or not zone or job.active ~= true
        or zone.enabled ~= true
        or record and record.allowedJobs
            and record.allowedJobs.Lumber == false
    then
        return {}
    end
    return {{
        taskId = tostring(job.id), npcId = tostring(npcId), kind = "LUMBER",
        sourceDomain = "lumber", sourceRef = tostring(job.id),
        precedence = "FORCED_ORDER", urgency = 0.72,
        capability = "lumber", interruptPolicy = "NORMAL",
        revision = job.revision, createdAt = job.createdAt or 0,
    }}
end

function Executor.Validate(candidate)
    local record = recordFor(candidate and candidate.npcId)
    return Service and Service.ValidateJob
        and Service.ValidateJob(candidate and candidate.npcId,
            candidate and candidate.sourceRef)
        and not (record and record.allowedJobs
            and record.allowedJobs.Lumber == false)
        or false
end

function Executor.Assign(candidate)
    local job = Service and Service.GetJob(candidate and candidate.npcId)
    if not job or tostring(job.id) ~= tostring(candidate and candidate.sourceRef) then
        return nil, "lumber_job_missing"
    end
    return {
        executionMode = liveBody(candidate.npcId) and "LIVE" or "ABSTRACT",
        resourceKey = job.id, resourceKind = "LUMBER_JOB",
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
                reason or "lumber_job_failed")
        end
        return false
    end
    if complete and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.Complete
    then
        PNC.Tasking.Commands.Complete(lease.leaseId,
            reason or "lumber_zone_exhausted")
    end
    return true
end

function Executor.Cancel(lease, reason)
    if Service and Service.CancelJob then
        return Service.CancelJob(lease and lease.npcId,
            reason or "lumber_task_cancelled")
    end
    return true
end

function Executor.Complete(lease)
    local job = Service and Service.GetJob(lease and lease.npcId)
    if job then
        job.active = false
        job.leaseId = nil
        job.state, job.phase = "COMPLETED", "COMPLETE"
        Service.ReleaseTree(job.targetKey, "lumber_job_complete")
        job.targetKey, job.approach = nil, nil
        Service.RestoreOrder(lease.npcId)
    end
    return true
end

if PNC.Tasking and PNC.Tasking.Commands
    and PNC.Tasking.Commands.RegisterProvider
then
    PNC.Tasking.Commands.RegisterProvider("lumber", Executor)
end

return Executor
