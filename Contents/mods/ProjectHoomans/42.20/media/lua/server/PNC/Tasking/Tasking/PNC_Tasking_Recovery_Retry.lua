-- Shared task recovery retry and quarantine policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
local H = Tasking.Internal or {}
Tasking.Internal = H
local counters = H.RecoveryCounters
local emit = H.RecoveryEmit
local stateFor = H.RecoveryStateFor

local function stopLease(lease, reason)
    if type(H.StopLease) ~= "function" then
        return false, "TASK_STOP_UNAVAILABLE"
    end
    local callOK, released, releaseReason = H.SafeCall(
        "task_recovery_stop", H.StopLease, {
            npcId = lease and lease.npcId,
            leaseId = lease and lease.leaseId,
            domain = lease and lease.sourceDomain,
        }, lease, reason)
    if not callOK then return false, releaseReason end
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

H.RecoveryStopLease = stopLease
H.RecoveryRetryOrQuarantine = retryOrQuarantine
