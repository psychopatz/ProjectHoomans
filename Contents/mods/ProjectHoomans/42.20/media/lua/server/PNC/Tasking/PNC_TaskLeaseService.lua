-- Server-authoritative task lease composition root.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.TaskLeaseService = PNC.TaskLeaseService or {}

local Leases = PNC.TaskLeaseService
Leases.Internal = Leases.Internal or {}
Leases.ByID = Leases.ByID or {}
Leases.ByNPC = Leases.ByNPC or {}
Leases.Active = Leases.Active or {}
Leases.ActiveIndex = Leases.ActiveIndex or {}
Leases.PHASES = { ASSIGNED = true, TRAVEL = true, WAITING = true,
    WORKING = true, CANCELLING = true, ATOMIC_COMMIT = true,
    COMPLETING = true, DONE = true }
Leases.PHASE_ALIASES = {
    WAITING_FOR_WORLD = "WAITING",
    WORLD_EFFECT_PENDING = "WAITING",
}
Leases.TRANSITIONS = {
    ASSIGNED = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    TRAVEL = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    WAITING = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    WORKING = { TRAVEL = true, WAITING = true, WORKING = true,
        CANCELLING = true, ATOMIC_COMMIT = true, COMPLETING = true },
    ATOMIC_COMMIT = { WORKING = true, COMPLETING = true },
    CANCELLING = { CANCELLING = true, COMPLETING = true },
    COMPLETING = { COMPLETING = true, DONE = true },
    DONE = { DONE = true },
}

require "PNC/Tasking/PNC_TaskLeaseService_Context"
require "PNC/Tasking/PNC_TaskLeaseService_Creation"
require "PNC/Tasking/PNC_TaskLeaseService_Queries"
require "PNC/Tasking/PNC_TaskLeaseService_Cancellation"
require "PNC/Tasking/PNC_TaskLeaseService_Release"

return Leases
