-- Lease lookup and invariant queries.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Leases = PNC.TaskLeaseService

function Leases.Get(id) return Leases.ByID[tostring(id or "")] end
function Leases.ForNPC(id) return Leases.Get(Leases.ByNPC[tostring(id or "")]) end

function Leases.CheckInvariants()
    for id, lease in pairs(Leases.ByID) do
        if tostring(lease.leaseId) ~= tostring(id)
            or Leases.ByNPC[lease.npcId] ~= lease.leaseId
            or Leases.ActiveIndex[lease.leaseId] == nil
        then
            return false, "LEASE_INDEX_MISMATCH"
        end
    end
    for npcId, leaseId in pairs(Leases.ByNPC) do
        local lease = Leases.ByID[leaseId]
        if not lease or tostring(lease.npcId) ~= tostring(npcId) then
            return false, "LEASE_NPC_INDEX_MISMATCH"
        end
    end
    return true
end

function Leases.Count()
    local count = 0
    for _, _ in pairs(Leases.ByID) do count = count + 1 end
    return count
end
