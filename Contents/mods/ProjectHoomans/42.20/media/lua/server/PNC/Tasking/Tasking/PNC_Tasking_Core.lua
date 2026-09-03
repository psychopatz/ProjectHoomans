if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal

function H.Copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

function H.RecordFailure(stage, context, message)
    local diagnostics = Tasking.Diagnostics
    diagnostics.counters.callbackFailures =
        diagnostics.counters.callbackFailures + 1
    local failure = {
        stage = tostring(stage or "unknown"),
        npcId = context and context.npcId or nil,
        leaseId = context and context.leaseId or nil,
        domain = context and context.domain or nil,
        at = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
        error = tostring(message or "unknown callback failure"),
    }
    diagnostics.lastFailure = failure
    local recent = diagnostics.recentFailures
    recent[#recent + 1] = failure
    while #recent > 32 do table.remove(recent, 1) end
    return failure
end

-- All provider and executor callbacks pass through this boundary. A failed
-- callback is data for the scheduler, not an exception that can terminate the
-- entire PZ tick.
function H.SafeCall(stage, callback, context, ...)
    if type(callback) ~= "function" then
        H.RecordFailure(stage, context, "CALLBACK_UNAVAILABLE")
        return false, nil, "CALLBACK_UNAVAILABLE"
    end
    local ok, first, second, third, fourth = pcall(callback, ...)
    if not ok then
        H.RecordFailure(stage, context, first)
        return false, nil, tostring(first)
    end
    return true, first, second, third, fourth
end

function Tasking.Commands.RegisterProvider(domain, provider)
    domain = tostring(domain or "")
    if domain == "" or type(provider) ~= "table"
        or type(provider.GetCandidates) ~= "function"
        or type(provider.Validate) ~= "function"
        or type(provider.Assign) ~= "function"
    then return false, "INVALID_TASK_PROVIDER" end
    if Tasking.WATCHDOG_DOMAINS
        and Tasking.WATCHDOG_DOMAINS[domain] == true
        and type(provider.GetRecoveryState) ~= "function"
    then return false, "TASK_PROVIDER_RECOVERY_UNSUPPORTED" end
    if Tasking.Providers[domain] then
        return false, "TASK_PROVIDER_ALREADY_REGISTERED"
    end
    Tasking.Providers[domain] = provider
    return true, provider
end

function Tasking.Commands.RegisterExecutor(mode, executor)
    mode = string.upper(tostring(mode or ""))
    if mode == "" or type(executor) ~= "table"
        or type(executor.Tick) ~= "function"
    then return false, "INVALID_TASK_EXECUTOR" end
    if Tasking.Executors[mode] then
        return false, "TASK_EXECUTOR_ALREADY_REGISTERED"
    end
    Tasking.Executors[mode] = executor
    return true, executor
end

return Tasking
