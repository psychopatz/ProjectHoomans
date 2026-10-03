if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Executor = PNC and PNC.MedicalCareExecutor
if not Executor then return end
local Internal = Executor.Internal
local Service = Internal.Service
local Status = Internal.Status
local Registry = Internal.Registry
local WorkPolicy = Internal.WorkPolicy
local Recovery = Internal.Recovery
local preflightMissingSupply = Internal.preflightMissingSupply
local hasTaskBandage = Internal.hasTaskBandage
local Treatment = Internal.Treatment
local Common = Internal.Common

function Executor.GetCandidates(npcId)
    local actor = Registry and Registry.Get and Registry.Get(npcId) or nil
    local candidates = {}
    local at = PNC.Core.Now()
    if not actor or not Internal.IsDoctor(actor) then return candidates end
    for _, task in ipairs(Service.List(false)) do
        local supplyTask = preflightMissingSupply(task, at)
        if supplyTask then
            Executor.RequestBandageSupport(supplyTask.id)
        elseif task.status == Status.WAITING_FOR_SUPPLY then
            Executor.RequestBandageSupport(task.id)
        end
    end
    for _, task in ipairs(Service.List(false)) do
        local ready = (tonumber(task.retryAt) or 0) <= at
        local supplyReady = task.status == Status.WAITING_FOR_SUPPLY
            and hasTaskBandage(actor, task)
        if (ready and task.status ~= Status.WAITING_FOR_SUPPLY)
            or supplyReady
        then
            local valid = Internal.CanTreat(actor, task)
            if valid then
                candidates[#candidates + 1] = {
                    taskId = "medical_care:" .. tostring(task.id)
                        .. ":" .. tostring(npcId),
                    npcId = tostring(npcId),
                    kind = "MEDICAL_CARE",
                    sourceDomain = "medical",
                    sourceRef = task.id,
                    precedence = (tonumber(task.priority) or 0) >= 100
                        and "CRITICAL_NEED" or "NORMAL_NEED",
                    urgency = math.max(0, math.min(1,
                        (tonumber(task.priority) or 0) / 100)),
                    workPriority = WorkPolicy.GetPriority(actor, "MedicalCare"),
                    capability = "MEDICAL_CARE",
                    interruptPolicy = "NORMAL",
                    revision = task.revision,
                    createdAt = task.createdAt,
                }
                break
            end
        end
    end
    return candidates
end

function Executor.Validate(intent)
    local actor = Registry and Registry.Get and Registry.Get(intent and intent.npcId) or nil
    local task = Service.Get(intent and intent.sourceRef)
    if not task or Service.TERMINAL[task.status] then return false end
    return Internal.CanTreat(actor, task) == true
end

function Executor.Assign(intent)
    local task = Service.Get(intent and intent.sourceRef)
    local actorId = intent and tostring(intent.npcId or "") or ""
    local actor = Registry and Registry.Get and Registry.Get(actorId) or nil
    local valid = task and actor and Internal.CanTreat(actor, task)
    local changed
    if not valid then return nil, "medical_task_invalid" end
    if task.actorId and tostring(task.actorId) ~= actorId then
        return nil, "medical_task_claimed"
    end
    changed = Service.SetPhase(task.id, Status.CLAIMED, {
        actorId = actorId,
        clearReservation = true,
        clearBlockedReason = true,
    })
    if not changed then return nil, "medical_task_claim_failed" end
    return {
        executionMode = "LIVE",
        resourceKey = task.id,
        resourceKind = "MEDICAL_CARE",
    }
end

function Executor.Start(lease)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease.npcId) or nil
    local now = PNC.Core.Now()
    if not task or not record then return false, "medical_actor_unavailable" end
    record.runtime = record.runtime or {}
    record.runtime.medicalCare = {
        phase = "traveling",
        taskId = task.id,
        patientId = task.patientId,
        startedAt = now,
        lastObservedAt = now,
    }
    record.runtime.forceSyncEvent = "medical_care_started"
    record.activeBehavior = "MedicalCare"
    record.runtime.tacticalState = "medical_care"
    if PNC.TaskLeaseService and PNC.TaskLeaseService.SetPhase then
        PNC.TaskLeaseService.SetPhase(lease.leaseId, "TRAVEL")
    end
    Service.SetPhase(task.id, Status.TRAVELING, {
        actorId = lease.npcId,
        clearBlockedReason = true,
    })
    return true
end

function Executor.CanContinue(lease)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease and lease.npcId) or nil
    if not task or Service.TERMINAL[task.status] then return false end
    if not record or record.alive == false then return false end
    return tostring(task.actorId or "") == tostring(lease and lease.npcId or "")
end

function Executor.GetRecoveryState(lease)
    local task = Service.Get(lease and lease.sourceRef)
    local record = Registry and Registry.Get and Registry.Get(lease and lease.npcId) or nil
    local snapshot
    if not task or Service.TERMINAL[task.status] then return { terminal = true } end
    snapshot = {
        phase = "WAITING",
        lastProgressAt = task.lastProgressAt or lease and lease.lastProgressAt,
        watchable = false,
    }
    if task.status == Status.TRAVELING then
        snapshot.phase = "TRAVEL"
        snapshot.watchable = true
        if Recovery and Recovery.ApplyMovementRecovery then
            snapshot = Recovery.ApplyMovementRecovery(snapshot, lease, record)
        end
    elseif task.status == Status.AT_PATIENT
        or task.status == Status.TREATING
    then
        snapshot.phase = "WORKING"
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "medical_treatment_timeout"
    end
    return snapshot
end


return Executor
