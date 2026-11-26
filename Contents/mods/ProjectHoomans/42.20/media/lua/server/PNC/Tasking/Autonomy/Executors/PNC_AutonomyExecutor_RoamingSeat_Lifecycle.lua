if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.AutonomyExecutors.RoamingSeat
local Internal = Service.Internal or {}

local facilityJobs = Internal.facilityJobs
local facilityReservations = Internal.facilityReservations
local currentTime = Internal.currentTime
local function activityHelpers()
    return PNC.WorldObjects and PNC.WorldObjects.ActivityHelpers or nil
end

local function release(state, reason)
    local helpers = activityHelpers()
    if helpers and helpers.ReleaseReservation then
        helpers.ReleaseReservation(
            state, reason or "roaming_seat_stopped", facilityReservations())
        return
    end
    local reservations = facilityReservations()
    local id = tostring(state and state.reservationId or "")
    if id ~= "" and reservations and reservations.Release then
        reservations.Release(id, reason or "roaming_seat_stopped")
    end
    if state then state.reservationId = nil end
end

local function resetRoam(record, preserveIdleDwell)
    local roaming = record.runtime and record.runtime.roaming or nil
    local at
    local dwellUntil
    if not roaming then return end
    if preserveIdleDwell == true then
        at = currentTime()
        dwellUntil = math.max(
            tonumber(roaming.waitUntil) or 0,
            at + Service.POST_SEAT_DWELL_MIN_MS
                + ZombRand(Service.POST_SEAT_DWELL_MAX_MS
                    - Service.POST_SEAT_DWELL_MIN_MS + 1)
        )
        roaming.waitUntil = dwellUntil
        roaming.idleSince = at
        roaming.seatCooldownUntil = dwellUntil
        roaming.phase = "idle"
    else
        roaming.waitUntil = nil
        roaming.idleSince = nil
        roaming.seatCooldownUntil = nil
        roaming.phase = nil
    end
    roaming.pausePending = nil
    roaming.goalX, roaming.goalY, roaming.goalZ = nil, nil, nil
end

local function finish(record, zombie, reason, preserveIdleDwell)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
    if not state or state.finishing == true then return false end
    state.finishing = true
    if seating and seating.ClearFurnitureSeat then
        seating.ClearFurnitureSeat(record, zombie, state)
    end
    if seating and seating.RestorePosition then
        seating.RestorePosition(record, zombie, state)
    end
    local helpers = activityHelpers()
    if helpers and helpers.ResetPath then
        helpers.ResetPath(record, zombie, reason or "roaming_seat_stopped", seating)
    elseif seating and seating.ResetPath then
        seating.ResetPath(record, zombie, reason or "roaming_seat_stopped")
    end
    release(state, reason)
    if helpers and helpers.ClearLiveObject then
        helpers.ClearLiveObject(PNC.SeatingRuntime, record)
    elseif PNC.SeatingRuntime and PNC.SeatingRuntime.LiveObjects then
        PNC.SeatingRuntime.LiveObjects[tostring(record.id)] = nil
    end
    runtime.roamingSeat = nil
    resetRoam(record, preserveIdleDwell ~= false)
    return true
end

local function stop(record, zombie, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    if not state then return false end
    state.stopRequested = true
    local helpers = activityHelpers()
    if helpers and helpers.InterruptScene then
        helpers.InterruptScene(
            record, zombie, state, "movement", "roaming_seat_stop")
    else
        local scene = runtime and runtime.animationScene or nil
        if scene and scene.id == state.sceneId
            and PNC.AnimationScenes and PNC.AnimationScenes.Interrupt
        then
            PNC.AnimationScenes.Interrupt(record, zombie, "movement")
            if runtime.animationScene
                and PNC.AnimationScenes.ClearScene
            then
                PNC.AnimationScenes.ClearScene(
                    record, zombie, "roaming_seat_stop", true
                )
            end
        end
    end
    return finish(record, zombie, reason or "roaming_seat_stopped")
end

Internal.release = release
Internal.resetRoam = resetRoam
Internal.finish = finish
Internal.stop = stop
Service.Stop = stop
