-- Stalled task lease recovery provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
local H = Tasking.Internal or {}
Tasking.Internal = H
local refreshProviderState = H.RecoveryRefreshProviderState
local isWatchable = H.RecoveryIsWatchable
local stateFor = H.RecoveryStateFor
local progressBaseline = H.RecoveryProgressBaseline
local retryOrQuarantine = H.RecoveryRetryOrQuarantine

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
        progressBaseline(lease, snapshot))
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
