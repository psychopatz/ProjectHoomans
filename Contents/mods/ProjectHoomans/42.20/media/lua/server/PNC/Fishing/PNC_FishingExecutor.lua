-- Tasking adapter for fishing jobs. FishingService owns zone state, spot
-- reservations, work points, and inventory mutation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FishingExecutor = PNC.FishingExecutor or {}

local Executor = PNC.FishingExecutor
local Service = PNC.FishingService
local Const = PNC.Const or {}
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"
local Recovery = PNC.Tasking and PNC.Tasking.Internal

local function liveBody(npcId)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(tostring(npcId or "")) or nil
end

local function recordFor(npcId)
    return PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(tostring(npcId or "")) or nil
end

local function isCamped(record)
    return PNC.HomeDutyService
        and PNC.HomeDutyService.IsCamped
        and PNC.HomeDutyService.IsCamped(record) == true
end

local function fishingWorkOrder(record, job, zone)
    local base = PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
    return {
        id = "fishing:" .. tostring(job.id), operation = "FISHING",
        requiredWorkerId = record.id,
        baseId = base and base.id or "",
        colonyId = base and base.colonyId or "",
        factionId = base and base.factionId or "",
        priority = 90, payload = { fishingJobId = job.id,
            zoneId = zone and zone.id or job.zoneId },
    }
end

local function ensureFishingWorkItem(record, job, zone, body)
    local items = PNC.WorkItemService
    if not items or type(items.Check) ~= "function" then return true end
    local report = items.Check(record, "FISHING")
    if not report.ok then
        if type(items.PrepareOrder) ~= "function" then
            return false, report.reason or "WAITING_FOR_WORK_ITEM"
        end
        return items.PrepareOrder(fishingWorkOrder(record, job, zone))
    end
    if type(items.Ensure) ~= "function" then return true end
    local ready, reason, ensureReport = items.Ensure(record, "FISHING", body, {
        owner = "work:FISHING", priority = "WORK",
        applyHands = body ~= nil,
    })
    return ready, reason, ensureReport
end

local function setLeasePhase(lease, job)
    local phase = tostring(job and job.phase or "WAITING")
    local leasePhase = phase == "TRAVEL" and "TRAVEL"
        or phase == "WORKING" and "WORKING" or "WAITING"
    if PNC.TaskLeaseService and PNC.TaskLeaseService.SetPhase then
        PNC.TaskLeaseService.SetPhase(lease.leaseId, leasePhase)
    end
end

function Executor.GetCandidates(npcId)
    local record = recordFor(npcId)
    if not record or isCamped(record) then return {} end
    local job = Service and Service.GetJob and Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    if not job or not zone or job.active ~= true
        or zone.enabled ~= true or not Service.ValidateZone(zone)
        or not WorkPolicy.IsEnabled(record, "Fishing")
    then return {} end
    local ready = ensureFishingWorkItem(record, job, zone)
    if ready ~= true then return {} end
    return {{
        taskId = tostring(job.id), npcId = tostring(npcId), kind = "FISHING",
        sourceDomain = "fishing", sourceRef = tostring(job.id),
        precedence = "FORCED_ORDER", urgency = 0.72,
        workPriority = WorkPolicy.GetPriority(record, "Fishing"),
        capability = "fishing", interruptPolicy = "NORMAL",
        revision = job.revision, createdAt = job.createdAt or 0,
    }}
end

function Executor.Validate(intent)
    local npcId = intent and intent.npcId
    local record = recordFor(npcId)
    if not record or isCamped(record) then return false end
    local job = Service and Service.GetJob and Service.GetJob(npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    return Service and Service.ValidateJob
        and Service.ValidateJob(npcId, intent and intent.sourceRef)
        and WorkPolicy.IsEnabled(record, "Fishing") or false
end

function Executor.Assign(intent)
    local record = recordFor(intent and intent.npcId)
    if not record or isCamped(record) then return nil, "NPC_CAMPED" end
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
    local record = recordFor(lease and lease.npcId)
    local job = Service and Service.GetJob and Service.GetJob(lease and lease.npcId)
    local zone = job and Service.GetZone(job.zoneId) or nil
    local body = liveBody(lease and lease.npcId)
    local ready, reason = false, "fishing_work_item_unavailable"
    local ensureReport
    if record and job and zone then
        ready, reason, ensureReport = ensureFishingWorkItem(record, job, zone, body)
    end
    if ready ~= true then
        if record and job and Service.FishingDiagnostics
            and Service.FishingDiagnostics.RecordTransition
        then
            Service.FishingDiagnostics.RecordTransition(record, job, body,
                reason, { event = "work_item_wait", phase = job.phase,
                    toolID = ensureReport and ensureReport.selected
                        and ensureReport.selected.itemID or nil,
                    tool = ensureReport and ensureReport.selected
                        and ensureReport.selected.fullType or nil })
        end
        return false, reason
    end
    local started, startReason = Service.StartJob(lease)
    if started then setLeasePhase(lease, Service.GetJob(lease.npcId)) end
    return started, startReason
end

function Executor.CanContinue(lease)
    local record = recordFor(lease and lease.npcId)
    local job = Service and Service.GetJob(lease and lease.npcId)
    return record ~= nil and not isCamped(record)
        and job ~= nil and job.active == true
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
        watchable = false,
    }
    if phase == "TRAVEL" then
        snapshot.phase, snapshot.watchable = "TRAVEL", true
        if Recovery and Recovery.ApplyMovementRecovery then
            snapshot = Recovery.ApplyMovementRecovery(snapshot, lease,
                recordFor(lease.npcId))
        end
    elseif phase == "WORKING" then
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "fishing_work_timeout"
    else
        snapshot.phase = "WAITING"
    end
    return snapshot
end

function Executor.Tick(lease)
    local ok, complete, reason = Service.TickJob(lease)
    setLeasePhase(lease, Service.GetJob(lease.npcId))
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
    local record = recordFor(lease and lease.npcId)
    if record and PNC.WorkItemService and PNC.WorkItemService.Release then
        local released, releaseReason = PNC.WorkItemService.Release(
            record, "FISHING", nil, { reason = reason or "fishing_cancelled" })
        if released == false then return false, releaseReason end
    end
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
