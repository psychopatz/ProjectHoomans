if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Optional idle behavior is kept outside FacilityJobs itself. The activity
-- service owns reservations/scenes; this module only decides when an idle
-- companion may use a living-room chair.
PNC = PNC or {}
PNC.LivingRoomService = PNC.LivingRoomService or {}

local Service = PNC.LivingRoomService
Service.NextAttemptAt = Service.NextAttemptAt or {}
Service.CADENCE_MS = 5000

local function baseFor(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
end

local function eligible(record, now)
    if not record or record.alive == false
        or not PNC.CompanionCommands.IsCompanion(record)
    then return false end
    if PNC.TaskLeaseService and PNC.TaskLeaseService.ForNPC(record.id) then
        return false
    end
    if record.runtime and (record.runtime.workOrderId
        or record.runtime.facilityActivity)
    then return false end
    if tostring(record.orderSpec and record.orderSpec.kind or "")
        ~= "colony_home"
    then return false end
    local base = baseFor(record)
    if not base or not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return false
    end
    local nextAt = tonumber(Service.NextAttemptAt[tostring(record.id)]) or 0
    return now >= nextAt, base
end

function Service.Pump(now)
    now = tonumber(now) or PNC.Core.Now()
    if not PNC.Registry then return 0 end
    local started = 0
    local function consider(record)
        local allowed, base = eligible(record, now)
        if not allowed then return end
        Service.NextAttemptAt[tostring(record.id)] = now + Service.CADENCE_MS
        local facilities = PNC.FacilityService.ListByCapability(
            base.id, "living")
        if #facilities == 0 then return end
        local live = PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        local ok = PNC.FacilityJobs and PNC.FacilityJobs.StartForFacility
            and PNC.FacilityJobs.StartForFacility(record, facilities[1], {
                automatic = true, abstract = live == nil,
            })
        if ok then started = started + 1 end
    end
    if PNC.Registry.ForEach then PNC.Registry.ForEach(consider)
    else for _, record in pairs(PNC.Registry.Data or {}) do consider(record) end end
    return started
end

return Service
