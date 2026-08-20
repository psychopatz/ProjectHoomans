if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Live = {}
local Abstract = {}

function Live.Tick(lease)
    local record = PNC.Registry.Get(lease.npcId)
    local runtime = record and record.runtime and record.runtime.facilityActivity
    local reservation = lease.reservationId
        and PNC.FacilityReservations.ByID[lease.reservationId] or nil
    if not runtime or not reservation then
        PNC.Tasking.Commands.MarkDirty(lease.npcId, "LIVE_EXECUTOR_INVALID")
        return false
    end
    -- Travel can take longer than the initial reservation window. Keep the
    -- bed/workstation owned by this task until the scene is actually running;
    -- OnSceneTick continues the same renewal once the NPC is settled.
    local now = PNC.Core.Now()
    if now >= (tonumber(lease.nextReservationRenewAt) or 0) then
        local renewed = PNC.FacilityReservations.Start(
            lease.reservationId, 30000)
        if not renewed then
            PNC.Tasking.Commands.MarkDirty(lease.npcId,
                "LIVE_RESERVATION_RENEW_FAILED")
            return false
        end
        lease.nextReservationRenewAt = now + 10000
    end
    local phase = runtime.phase == "TRAVELLING" and "TRAVEL"
        or runtime.phase ~= "QUEUED" and runtime.phase ~= "STARTING"
            and "WORKING" or "WAITING"
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
    PNC.TaskLeaseService.SetPhase(lease.leaseId, "WORKING")
    local definition = PNC.FacilityJobDefinitions.Get(lease.capability)
    local ok, complete, reason = PNC.NeedFacilityEffects.Tick(
        record, lease, definition, elapsed, PNC.Core.Now())
    if not ok then
        PNC.Tasking.Commands.CancelForNPC(lease.npcId,
            reason or "ABSTRACT_NEED_EFFECT_FAILED")
        return false
    end
    if complete then
        PNC.Tasking.Commands.Complete(lease.leaseId,
            reason or "NEED_COMPLETE")
    end
    return true
end

PNC.Tasking.Commands.RegisterExecutor("LIVE", Live)
PNC.Tasking.Commands.RegisterExecutor("ABSTRACT", Abstract)

return { Live = Live, Abstract = Abstract }
