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
        dirtyQueueLength = Tasking.Inbox and Tasking.Inbox.Count
            and Tasking.Inbox.Count() or 0,
        dirtyQueueHighWater = Tasking.Inbox
            and Tasking.Inbox.highWaterMark or 0,
        lastEvent = H.Copy(Tasking.Diagnostics.lastEvent),
        lastFailure = H.Copy(Tasking.Diagnostics.lastFailure),
        recentFailures = H.Copy(Tasking.Diagnostics.recentFailures),
        leaseCount = Leases.Count(),
        leaseInvariants = Leases.CheckInvariants
            and Leases.CheckInvariants() or nil,
        persistenceRepairs = PNC.Persistence
            and PNC.Persistence.Repairs
            and PNC.Persistence.Repairs.GetDiagnostics
            and PNC.Persistence.Repairs.GetDiagnostics()
            or nil }
end

return Tasking
