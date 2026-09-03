-- Tasking adapter for lumber jobs. The service owns world-resource state;
-- this module only exposes it to the shared task arbiter.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberExecutor = PNC.LumberExecutor or {}

local Executor = PNC.LumberExecutor
local Service = PNC.LumberService
local Recovery = PNC.Tasking and PNC.Tasking.Internal
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"

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
        or record and not WorkPolicy.IsEnabled(record, "Lumber")
    then
        return {}
    end
    -- WorkService is the sole durable lumber authority in production. The
    -- adapter creates/reconciles the LUMBER order; keeping this legacy
    -- provider registered alongside it would let Tasking race two leases for
    -- the same tree job. The direct route remains available to isolated
    -- compatibility loads where WorkService is absent.
    if PNC.LumberWorkAdapter and PNC.WorkService then
        if PNC.LumberWorkAdapter.EnsureOrder then
            PNC.LumberWorkAdapter.EnsureOrder(job)
        end
        return {}
    end
    return {{
        taskId = tostring(job.id), npcId = tostring(npcId), kind = "LUMBER",
        sourceDomain = "lumber", sourceRef = tostring(job.id),
        precedence = "FORCED_ORDER", urgency = 0.72,
        workPriority = WorkPolicy.GetPriority(record, "Lumber"),
        capability = "lumber", interruptPolicy = "NORMAL",
        revision = job.revision, createdAt = job.createdAt or 0,
    }}
end

function Executor.Validate(candidate)
    if PNC.LumberWorkAdapter and PNC.WorkService then return false end
    local record = recordFor(candidate and candidate.npcId)
    local job = Service and Service.GetJob(candidate and candidate.npcId)
    return Service and Service.ValidateJob
        and Service.ValidateJob(candidate and candidate.npcId,
            candidate and candidate.sourceRef)
        and (not record or WorkPolicy.IsEnabled(record, "Lumber"))
        or false
end

function Executor.Assign(candidate)
    if PNC.LumberWorkAdapter and PNC.WorkService then
        return nil, "LUMBER_WORK_AUTHORITY"
    end
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

function Executor.GetRecoveryState(lease)
    local job = Service and Service.GetJob
        and Service.GetJob(lease and lease.npcId) or nil
    if not job or job.active ~= true then return { terminal = true } end
    local phase = tostring(job.phase or job.state or "WAITING")
    local snapshot = {
        phase = phase,
        lastProgressAt = job.lastProgressAt or lease and lease.lastProgressAt,
        watchable = phase == "CHOPPING",
    }
    if phase == "TRAVEL"
        and Recovery and Recovery.ApplyMovementRecovery
    then
        snapshot = Recovery.ApplyMovementRecovery(snapshot, lease,
            recordFor(lease.npcId))
    end
    return snapshot
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

if not (PNC.LumberWorkAdapter and PNC.WorkService)
    and PNC.Tasking and PNC.Tasking.Commands
    and PNC.Tasking.Commands.RegisterProvider
then
    PNC.Tasking.Commands.RegisterProvider("lumber", Executor)
end

return Executor
