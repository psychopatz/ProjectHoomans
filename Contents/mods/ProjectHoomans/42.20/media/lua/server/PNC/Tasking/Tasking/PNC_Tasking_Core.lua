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

function Tasking.Commands.RegisterProvider(domain, provider)
    domain = tostring(domain or "")
    if domain == "" or type(provider) ~= "table"
        or type(provider.GetCandidates) ~= "function"
        or type(provider.Validate) ~= "function"
        or type(provider.Assign) ~= "function"
    then return false, "INVALID_TASK_PROVIDER" end
    Tasking.Providers[domain] = provider
    return true, provider
end

function Tasking.Commands.RegisterExecutor(mode, executor)
    mode = string.upper(tostring(mode or ""))
    if mode == "" or type(executor) ~= "table"
        or type(executor.Tick) ~= "function"
    then return false, "INVALID_TASK_EXECUTOR" end
    Tasking.Executors[mode] = executor
    return true, executor
end

function Tasking.Commands.MarkDirty(npcId, cause)
    npcId = tostring(npcId or "")
    if npcId == "" then return false end
    local pending = Tasking.Dirty.byNPC[npcId]
    cause = tostring(cause or (pending and pending.cause) or "unspecified")
    if ScalingDiagnostics then
        ScalingDiagnostics.RecordDirtyMark(cause)
    end
    if pending then
        pending.cause = cause
        if ScalingDiagnostics then
            ScalingDiagnostics.Increment(
                "NPCDecisions.DirtyMarksDeduplicated"
            )
        end
        return true
    end
    local entry = { npcId = npcId, cause = cause }
    Tasking.Dirty.byNPC[npcId] = entry
    Tasking.Dirty.queue[#Tasking.Dirty.queue + 1] = entry
    return true
end

return Tasking

