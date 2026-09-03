if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
local H = Tasking.Internal or {}
Tasking.Internal = H

Tasking.PROGRESS_TIMEOUT_MS = Tasking.PROGRESS_TIMEOUT_MS or 60000
Tasking.RECOVERY_RETRY_INTERVAL_MS =
    Tasking.RECOVERY_RETRY_INTERVAL_MS or 5000
Tasking.MAX_STALL_RECOVERY_ATTEMPTS =
    Tasking.MAX_STALL_RECOVERY_ATTEMPTS or 2
Tasking.WATCHDOG_DOMAINS = Tasking.WATCHDOG_DOMAINS or {}
Tasking.WATCHDOG_DOMAINS.work = true
-- NeedFacility now reports effect progress from FacilityJobs. Travel remains
-- outside this watchdog; PathService owns movement liveness.
Tasking.WATCHDOG_DOMAINS.NeedFacility = true
-- Direct task providers must expose the same liveness contract as the
-- durable WorkService and NeedFacility providers. Their domain-specific
-- services still own cleanup; this table only opts them into the shared
-- lease watchdog.
Tasking.WATCHDOG_DOMAINS.farming = true
Tasking.WATCHDOG_DOMAINS.fishing = true
Tasking.WATCHDOG_DOMAINS.lumber = true
Tasking.WATCHDOG_DOMAINS.scavenge = true

local WATCHDOG_PHASES = {
    -- WorkService's clock currently represents collection/output progress,
    -- not locomotion. Keep travel owned by PathService until Work exposes a
    -- truthful movement-progress probe.
    WORKING = true,
}

local function counters()
    Tasking.Diagnostics = Tasking.Diagnostics or {}
    Tasking.Diagnostics.counters = Tasking.Diagnostics.counters or {}
    return Tasking.Diagnostics.counters
end

local function emit(eventType, lease, payload)
    if Tasking.Events and type(Tasking.Events.Emit) == "function" then
        Tasking.Events.Emit(eventType, {
            npcId = lease and lease.npcId,
            source = "Tasking.Recovery",
            entityId = lease and lease.leaseId,
            payload = payload or {},
        })
    end
end

local function isNonInterruptible(lease)
    local definitions = PNC.TaskRequestDefinitions
    return definitions and definitions.NON_INTERRUPTIBLE_PHASE
        and definitions.NON_INTERRUPTIBLE_PHASE[lease.phase] == true
end

local function isWatchable(lease, snapshot)
    if not lease
        or Tasking.WATCHDOG_DOMAINS[tostring(lease.sourceDomain or "")] ~= true
        or isNonInterruptible(lease)
    then
        return false
    end
    if snapshot and snapshot.watchable ~= nil then
        return snapshot.watchable == true
    end
    return WATCHDOG_PHASES[tostring(lease.phase or "")] == true
end

local function stateFor(lease, at, reportedProgressAt)
    local state = lease.recovery
    if type(state) ~= "table" then
        state = { attempts = 0, nextAttemptAt = 0 }
        lease.recovery = state
    end
    local progressAt = tonumber(reportedProgressAt)
        or tonumber(lease.lastProgressAt)
        or tonumber(lease.startedAt) or at
    if state.observedProgressAt ~= progressAt then
        state.observedProgressAt = progressAt
        state.attempts = 0
        state.nextAttemptAt = 0
        state.quarantined = nil
    end
    return state, progressAt
end

local function refreshProviderState(lease)
    local provider = lease and Tasking.Providers
        and Tasking.Providers[lease.sourceDomain]
    if not provider or type(provider.GetRecoveryState) ~= "function" then
        return nil
    end
    local ok, snapshot = pcall(provider.GetRecoveryState, lease)
    if not ok or type(snapshot) ~= "table" then return nil end
    if snapshot.lastProgressAt ~= nil then
        lease.lastProgressAt = snapshot.lastProgressAt
    end
    if snapshot.phase then lease.phase = snapshot.phase end
    return snapshot
end

-- Movement is owned by PathService. Providers may ask for this observation,
-- but must not create a second path watchdog or mutate the movement lane from
-- their recovery probe.
function H.ApplyMovementRecovery(snapshot, lease, record)
    if type(snapshot) ~= "table"
        or tostring(snapshot.phase or "") ~= "TRAVEL"
    then return snapshot end

    local pathService = PNC.PathService
    local zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record and record.id or lease and lease.npcId)
        or nil
    local movement = pathService
        and pathService.GetMovementRecoveryState
        and pathService.GetMovementRecoveryState(record, zombie)
        or nil
    if movement then
        if tonumber(movement.lastProgressAt)
            and tonumber(movement.lastProgressAt) > 0
        then
            snapshot.lastProgressAt = movement.lastProgressAt
        end
        snapshot.movement = movement
        if movement.active == true then
            snapshot.watchable = movement.watchable == true
            snapshot.forceRecovery = movement.forceRecovery == true
            snapshot.recoveryReason = movement.forceRecovery == true
                and "path_traversal_timeout" or nil
        else
            snapshot.watchable = true
            snapshot.timeoutMs = 15000
            snapshot.recoveryReason = "path_lane_inactive"
        end
    else
        -- A travel phase with no lane is a bounded coordination failure. Give
        -- the behavior pump a short window to create the lane, then release
        -- the lease so the task can be reevaluated cleanly.
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "path_lane_missing"
    end
    return snapshot
end

function H.GetRecoveryState(lease, at)
    at = tonumber(at) or PNC.Core.Now()
    local state = lease and lease.recovery
    if type(state) ~= "table" then return nil end
    if state.quarantined == true then return "QUARANTINED" end
    if tonumber(at) < (tonumber(state.nextAttemptAt) or 0) then
        return "RECOVERY_BACKOFF"
    end
    return nil
end

local function stopLease(lease, reason)
    if type(H.StopLease) ~= "function" then
        return false, "TASK_STOP_UNAVAILABLE"
    end
    if type(H.SafeCall) == "function" then
        local callOK, released, releaseReason = H.SafeCall(
            "task_recovery_stop", H.StopLease, {
                npcId = lease and lease.npcId,
                leaseId = lease and lease.leaseId,
                domain = lease and lease.sourceDomain,
            }, lease, reason)
        if not callOK then return false, released end
        return released == true, releaseReason
    end
    local callOK, released, releaseReason = pcall(H.StopLease,
        lease, reason)
    if not callOK then return false, released end
    return released == true, releaseReason
end

local function retryOrQuarantine(lease, at, reason, failureEvent,
        recoveredEvent, recoveryCounter, failureCounter, quarantineCounter)
    local state = stateFor(lease, at)
    if state.quarantined == true then return false, "QUARANTINED" end
    if at < (tonumber(state.nextAttemptAt) or 0) then
        return false, "RECOVERY_BACKOFF"
    end

    state.attempts = (tonumber(state.attempts) or 0) + 1
    state.lastAttemptAt = at
    state.lastReason = reason
    local released, releaseReason = stopLease(lease, reason)
    if released then
        local diagnostics = counters()
        diagnostics[recoveryCounter] =
            (diagnostics[recoveryCounter] or 0) + 1
        emit(recoveredEvent, lease, {
            reason = reason, attempt = state.attempts,
        })
        return true, "RECOVERED"
    end

    local diagnostics = counters()
    diagnostics[failureCounter] = (diagnostics[failureCounter] or 0) + 1
    state.nextAttemptAt = at + Tasking.RECOVERY_RETRY_INTERVAL_MS
    if state.attempts >= Tasking.MAX_STALL_RECOVERY_ATTEMPTS then
        state.quarantined = true
        diagnostics[quarantineCounter] =
            (diagnostics[quarantineCounter] or 0) + 1
        emit("TASK_RECOVERY_QUARANTINED", lease, {
            reason = reason, attempt = state.attempts,
            error = releaseReason or "TASK_CLEANUP_FAILED",
        })
        return false, "QUARANTINED"
    end
    emit(failureEvent, lease, {
        reason = reason, attempt = state.attempts,
        error = releaseReason or "TASK_CLEANUP_FAILED",
    })
    return false, "RECOVERY_PENDING"
end

function H.RecoverStalledLease(lease, at)
    at = tonumber(at) or PNC.Core.Now()
    if not lease or lease.cancellationRequested == true then
        return nil, "CANCELLING"
    end
    local snapshot = refreshProviderState(lease)
    if snapshot and snapshot.terminal == true then
        return nil, "TERMINAL"
    end
    if not isWatchable(lease, snapshot) then
        return nil, "NOT_APPLICABLE"
    end
    local state, progressAt = stateFor(lease, at,
        snapshot and snapshot.lastProgressAt)
    local timeoutMs = snapshot and tonumber(snapshot.timeoutMs)
        or Tasking.PROGRESS_TIMEOUT_MS
    if snapshot and snapshot.forceRecovery == true then
        timeoutMs = 0
    end
    if at - progressAt < timeoutMs then
        return nil, "HEALTHY"
    end
    if state.quarantined == true then return false, "QUARANTINED" end
    return retryOrQuarantine(
        lease,
        at,
        snapshot and snapshot.recoveryReason or "task_progress_timeout",
        "TASK_STALL_RECOVERY_FAILED", "TASK_STALLED_RECOVERED",
        "stallRecoveries", "stallRecoveryFailures", "stallQuarantines")
end

function H.RecoverExecutorFailure(lease, at, reason)
    at = tonumber(at) or PNC.Core.Now()
    if not lease or lease.cancellationRequested == true
        or isNonInterruptible(lease)
    then
        return false, "NOT_APPLICABLE"
    end
    return retryOrQuarantine(lease, at, reason or "task_executor_failed",
        "TASK_EXECUTOR_RECOVERY_FAILED", "TASK_EXECUTOR_RECOVERED",
        "executorRecoveries", "executorRecoveryFailures",
        "executorQuarantines")
end

return Tasking
