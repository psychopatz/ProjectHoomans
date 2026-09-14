-- Runtime-only ambience entry point for unowned area-roaming NPCs.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamAmbient = PNC.RoamAmbient or {}

require "PNC/Settlement/FacilityJobs/PNC_RoamAmbientPolicy"
require "PNC/Settlement/FacilityJobs/PNC_RoamAmbientSchedule"
require "PNC/Settlement/FacilityJobs/PNC_RoamAmbientDiscovery"
require "PNC/Settlement/FacilityJobs/PNC_RoamAmbientLifecycle"
require "PNC/Settlement/FacilityJobs/PNC_RoamAmbientTick"

local Service = PNC.RoamAmbient

function Service.TryStart(record, zombie, order, roaming, at)
    at = Service.CurrentTime(at)
    local id = tostring(record and record.id or "")
    if not Service.CanAttempt(record, zombie, roaming, at) then return false end
    if Service.AttemptAt ~= at then
        Service.AttemptAt = at
        Service.AttemptCount = 0
    end
    if (tonumber(Service.AttemptCount) or 0)
        >= (tonumber(Service.MAX_ATTEMPTS_PER_TICK) or 4)
    then
        return false
    end
    Service.AttemptCount = (tonumber(Service.AttemptCount) or 0) + 1
    Service.NextAttemptAt[id] = at + (tonumber(Service.CADENCE_MS) or 5000)
    local hours = Service.GetWorldAgeHours and Service.GetWorldAgeHours() or 0
    local plan = Service.GetActionPlan(record, hours)
    if not plan then return false end
    if plan.action == "sleep" then
        local candidate = Service.FindSleepSurface(zombie)
        if not candidate then return false end
        return Service.StartSleep(record, zombie, plan, candidate, at)
    end
    return Service.StartInstantAction(record, zombie, plan, at)
end

return Service
