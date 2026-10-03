-- Shared work task provider policy and lease-state context.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
local Provider = PNC.WorkTaskProvider or {}
Provider.Internal = Provider.Internal or {}
local Internal = Provider.Internal
local Status = PNC.WorkDefinitions.STATUS

local function needsFatigueGate(operation)
    return operation == "LUMBER" or operation == "CORPSE_HAUL"
end

local function sendHomeForRest(record, order, reason)
    if reason ~= "WORKER_NEEDS_REST" or not record or not order
        or not PNC.HomeDutyService
        or not PNC.HomeDutyService.SendHome
        or not PNC.HomeDutyService.IsAtHome
        or PNC.HomeDutyService.IsAtHome(record, order.baseId)
    then return end
    PNC.HomeDutyService.SendHome(record, order.baseId, "work_fatigue_gate")
end

local function assignable(order)
    return order and not order.workerId
        and order.recoveryQuarantined ~= true
        and (order.status == Status.QUEUED
            or order.status == Status.WAITING_FOR_WORKER)
end

local function phaseFor(order)
    if order.status == Status.WORLD_EFFECT_PENDING then
        return "WORLD_EFFECT_PENDING"
    end
    return order.completionStarted == true and "ATOMIC_COMMIT"
        or order.phase == "DROP_PENDING" and "ATOMIC_COMMIT"
        or order.phase == "GRAB_PENDING" and "WAITING"
        or order.status == Status.TRAVEL_TO_STOCKPILE
            and "TRAVEL"
        or order.status == Status.TRAVEL_TO_STATION and "TRAVEL"
        or order.status == Status.WORKING and "WORKING" or "WAITING"
end

Internal.NeedsFatigueGate = needsFatigueGate
Internal.SendHomeForRest = sendHomeForRest
Internal.Assignable = assignable
Internal.PhaseFor = phaseFor
