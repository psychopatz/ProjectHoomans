-- Sleep target hydration and start transaction for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamAmbient = PNC.AutonomyExecutors.RoamAmbient or {}

local Service = PNC.AutonomyExecutors.RoamAmbient

local TARGET_FIELDS = {
    "interactionX", "interactionY", "interactionZ", "interactionAxis",
    "interactionFacing", "interactionSurfaceOffset", "sleepAnchorX",
    "sleepAnchorY", "sleepAnchorZ", "sleepAxis", "sleepFacing",
    "sleepSprite", "sleepGridX", "sleepGridY", "sleepGridWidth",
    "sleepGridHeight", "sleepSlotId", "sleepSlotIndex", "sleepCapacity",
    "bedCapacity",
}

local function copyTarget(state, target)
    state.target = {
        x = tonumber(target.x) or 0, y = tonumber(target.y) or 0,
        z = tonumber(target.z) or 0,
    }
    state.x, state.y, state.z = state.target.x, state.target.y, state.target.z
    for index = 1, #TARGET_FIELDS do
        local key = TARGET_FIELDS[index]
        state[key] = target[key]
    end
    state.sleepSurface = tostring(target.sleepSurface or state.sleepSurface or "")
end

function Service.StartSleep(record, zombie, plan, candidate, at)
    local runtime = record.runtime or {}
    record.runtime = runtime
    local sleep = PNC.FacilityJobs and PNC.FacilityJobs.Sleep
    local reservations = PNC.FacilityReservations
    if not Service.CanWrite(record, "roam_ambient_sleep_start") then
        return false, "puppet_opera_writer_blocked:roam_ambient_provider"
    end
    if not sleep or not sleep.PrepareSleepSurface
        or not sleep.ClearSleepSurface
        or not reservations or not reservations.ReserveResource
    then
        return false
    end
    local ok, reservation = reservations.ReserveResource(
        "ambient:roam", candidate.resource, record.id,
        "ambient_roam_sleep", 30000, {
            automatic = true, ambient = true,
            sleepSlotId = candidate.target.sleepSlotId,
            sleepCapacity = candidate.target.sleepCapacity
                or candidate.resource.sleepCapacity,
        })
    if not ok or type(reservation) ~= "table" then return false end
    local state = {
        action = "sleep",
        sceneId = tostring(candidate.target and candidate.target.sceneId
            or ("ambient.roam.sleep." .. tostring(
                candidate.resource.sleepSurface or "bed"))),
        campRole = candidate.role or (candidate.target and candidate.target.campRole),
        tempCampfireKey = candidate.tempCampfireKey
            or (candidate.target and candidate.target.tempCampfireKey),
        scheduleKey = plan.key, wakeAt = plan.wakeAt,
        startedAt = at, phase = "TRAVELLING", reservationId = reservation.id,
        resourceKey = candidate.resource.resourceKey,
        resourceKind = candidate.resource.resourceKind,
        resource = PNC.FacilityResources.CopyDescriptor
            and PNC.FacilityResources.CopyDescriptor(candidate.resource)
            or candidate.resource,
        positioned = false, arrivalSettled = false,
        sleepSurfaceEntered = false,
        sleepSlotId = candidate.target.sleepSlotId,
        sleepSlotIndex = candidate.target.sleepSlotIndex,
        sleepCapacity = candidate.target.sleepCapacity
            or candidate.resource.sleepCapacity,
        bedCapacity = candidate.target.bedCapacity
            or candidate.target.sleepCapacity,
        approachCandidates = candidate.targets,
    }
    copyTarget(state, candidate.target)
    runtime.roamAmbient = state
    Service.ScheduleState(record).lastAttemptKey = plan.key
    if PNC.SleepRuntime and PNC.SleepRuntime.LiveObjects then
        PNC.SleepRuntime.LiveObjects[tostring(record.id)] = candidate.object
    end
    return Service.Tick(record, zombie, at)
end

return Service
