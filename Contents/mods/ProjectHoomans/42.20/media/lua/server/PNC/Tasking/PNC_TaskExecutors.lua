if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Live = {}
local Abstract = {}

function Live.Tick(lease)
    local record = PNC.Registry.Get(lease.npcId)
    local runtime = record and record.runtime and record.runtime.facilityActivity
    if not runtime or not PNC.FacilityReservations.ByID[lease.reservationId] then
        PNC.Tasking.Commands.MarkDirty(lease.npcId, "LIVE_EXECUTOR_INVALID")
        return false
    end
    local phase = runtime.phase == "TRAVELLING" and "TRAVEL"
        or runtime.phase == "SLEEPING" and "WORKING" or "WAITING"
    PNC.TaskLeaseService.SetPhase(lease.leaseId, phase)
    return true
end

function Abstract.Tick(lease)
    local record = PNC.Registry.Get(lease.npcId)
    if not record or not PNC.FacilityReservations.ByID[lease.reservationId] then
        PNC.Tasking.Commands.MarkDirty(lease.npcId, "ABSTRACT_EXECUTOR_INVALID")
        return false
    end
    local now = PNC.NeedsUtils.WorldAgeHours()
    local previous = tonumber(lease.lastEffectWorldHour) or now
    local elapsed = math.max(0, math.min(0.25, now - previous))
    lease.lastEffectWorldHour = now
    if lease.reservationId then PNC.FacilityReservations.Start(
        lease.reservationId, 30000) end
    if elapsed <= 0 then return true end
    PNC.TaskLeaseService.SetPhase(lease.leaseId, "WORKING")
    local ok, reason = PNC.IndividualNeeds.Commands.ApplyRest(
        record, elapsed, "abstract_sleep_task")
    if not ok or reason == "REST_COMPLETE" then
        PNC.Tasking.Commands.Complete(lease.leaseId, reason)
    end
    return ok
end

PNC.Tasking.Commands.RegisterExecutor("LIVE", Live)
PNC.Tasking.Commands.RegisterExecutor("ABSTRACT", Abstract)

return { Live = Live, Abstract = Abstract }
