-- Executor-failure recovery provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}

local Tasking = PNC.Tasking
local H = Tasking.Internal or {}
Tasking.Internal = H
local isNonInterruptible = H.RecoveryIsNonInterruptible
local retryOrQuarantine = H.RecoveryRetryOrQuarantine

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
