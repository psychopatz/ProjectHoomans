if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.RoamingSeat
local Internal = Service.Internal or {}
local Core = PNC.Core
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon
local Jobs = PNC.FacilityJobs
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Reservations = PNC.FacilityReservations
local Diagnostics = PNC.PerformanceScalingDiagnostics
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"
local facilityJobs = Internal.facilityJobs
local facilityReservations = Internal.facilityReservations
local currentTime = Internal.currentTime

local function release(state, reason)
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
    if seating and seating.ResetPath then
        seating.ResetPath(record, zombie, reason or "roaming_seat_stopped")
    end
    release(state, reason)
    if PNC.SeatingRuntime and PNC.SeatingRuntime.LiveObjects then
        PNC.SeatingRuntime.LiveObjects[tostring(record.id)] = nil
    end
    runtime.roamingSeat = nil
    resetRoam(record, preserveIdleDwell ~= false)
    Service.NextAttemptAt[tostring(record.id)] =
        currentTime() + Service.CADENCE_MS
    return true
end

local function stop(record, zombie, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local scene = runtime and runtime.animationScene or nil
    local internal
    if not state then return false end
    state.stopRequested = true
    if scene and scene.id == state.sceneId
        and PNC.AnimationScenes and PNC.AnimationScenes.Interrupt
    then
        PNC.AnimationScenes.Interrupt(record, zombie, "movement")
        if runtime.animationScene
            and PNC.AnimationScenes.Internal
            and PNC.AnimationScenes.Internal.ClearScene
        then
            internal = PNC.AnimationScenes.Internal
            internal.ClearScene(record, zombie, "roaming_seat_stop", true)
        end
    end
    return finish(record, zombie, reason or "roaming_seat_stopped")
end

local function beginAttempt(id, at)
    if at < (tonumber(Service.NextAttemptAt[id]) or 0) then
        return false
    end
    if Service.AttemptAt ~= at then
        Service.AttemptAt = at
        Service.AttemptCount = 0
    end
    if (tonumber(Service.AttemptCount) or 0)
        >= Service.MAX_ATTEMPTS_PER_TICK
    then
        return false
    end
    Service.AttemptCount = (tonumber(Service.AttemptCount) or 0) + 1
    Service.NextAttemptAt[id] = at + Service.CADENCE_MS
    return true
end


Internal.release = release
Internal.resetRoam = resetRoam
Internal.finish = finish
Internal.stop = stop
Internal.beginAttempt = beginAttempt
