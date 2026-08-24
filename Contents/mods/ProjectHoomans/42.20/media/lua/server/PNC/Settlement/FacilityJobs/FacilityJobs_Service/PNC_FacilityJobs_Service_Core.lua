if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local Jobs = PNC.FacilityJobs
local H = PNC.FacilityJobsServiceInternal
local Repository = PNC.SettlementRepository

function H.LivePosition(record)
    local zombie = record and record.id and PNC.Registry
        and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    if zombie and (not zombie.isDead or not zombie:isDead()) then
        return zombie:getX(), zombie:getY(), zombie:getZ()
    end
    return tonumber(record and record.x) or 0,
        tonumber(record and record.y) or 0,
        tonumber(record and record.z) or 0
end

function H.StopExistingActivity(record, reason)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local taskLeaseId = tostring(activity and activity.taskLeaseId or "")
    if taskLeaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands
        and PNC.Tasking.Commands.CancelForNPC
    then
        PNC.Tasking.Commands.CancelForNPC(record.id, reason)
    end
    if record and record.runtime and record.runtime.facilityActivity
        and Jobs.Stop
    then
        return Jobs.Stop(record, reason)
    end
    return true, "facility_activity_stopped"
end

function Jobs.StopControlled(record, reason)
    if not record or not record.runtime
        or not record.runtime.facilityActivity
    then
        return false, "facility_activity_not_active"
    end
    return H.StopExistingActivity(record, reason or "player_stop")
end

