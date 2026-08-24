if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Tasking = PNC.Tasking
local Priority = PNC.TaskPriority
local Leases = PNC.TaskLeaseService
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local H = Tasking.Internal

function Tasking.Queries.GetLease(npcId) return H.Copy(Leases.ForNPC(npcId)) end
function Tasking.Queries.GetDiagnostics(npcId)
    return { npc = H.Copy(Tasking.Diagnostics.byNPC[tostring(npcId or "")]),
        counters = H.Copy(Tasking.Diagnostics.counters),
        dirtyQueueLength = #Tasking.Dirty.queue, leaseCount = Leases.Count() }
end

return Tasking

