-- Start and stop transactions for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamAmbient = PNC.RoamAmbient or {}

local Service = PNC.RoamAmbient
local Common = PNC.BehaviorCommon
local Scenes = PNC.AnimationScenes
local Reservations = PNC.FacilityReservations

local SCENE_BY_ACTION = {
    eat = "ambient.roam.eat", drink = "ambient.roam.drink",
}

local TARGET_FIELDS = {
    "interactionX", "interactionY", "interactionZ", "interactionAxis",
    "interactionFacing", "interactionSurfaceOffset", "sleepAnchorX",
    "sleepAnchorY", "sleepAnchorZ", "sleepAxis", "sleepFacing",
    "sleepSprite", "sleepGridX", "sleepGridY", "sleepGridWidth",
    "sleepGridHeight",
}

local function copyTarget(state, target)
    state.target = {
        x = tonumber(target.x) or 0, y = tonumber(target.y) or 0,
        z = tonumber(target.z) or 0,
    }
    state.x, state.y, state.z = state.target.x, state.target.y, state.target.z
    local index
    for index = 1, #TARGET_FIELDS do
        local key = TARGET_FIELDS[index]
        state[key] = target[key]
    end
    state.sleepSurface = tostring(target.sleepSurface or state.sleepSurface or "")
end

function Service.ResetPath(record, zombie, reason)
    local sleep = PNC.FacilityJobs and PNC.FacilityJobs.Sleep
    if sleep and sleep.ResetPath then
        sleep.ResetPath(record, zombie, reason)
    elseif PNC.PathService and PNC.PathService.Reset then
        PNC.PathService.Reset(zombie, record)
    end
end

local function releaseReservation(state, reason)
    local id = tostring(state and state.reservationId or "")
    if id ~= "" and Reservations and Reservations.Release then
        Reservations.Release(id, reason or "roam_ambient_stopped")
    end
    if state then state.reservationId = nil end
end

function Service.Finish(record, zombie, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamAmbient or nil
    local sleep = PNC.FacilityJobs and PNC.FacilityJobs.Sleep
    local id = tostring(record and record.id or "")
    if not state or state.finishing == true then return false end
    state.finishing = true
    if state.action == "sleep" then
        if sleep and sleep.ClearSleepSurface then
            sleep.ClearSleepSurface(record, zombie, state)
        end
        if sleep and sleep.RestorePosition then
            sleep.RestorePosition(record, zombie, state)
        end
        Service.ResetPath(record, zombie, reason or "roam_ambient_sleep_stopped")
        if PNC.SleepRuntime and PNC.SleepRuntime.LiveObjects then
            PNC.SleepRuntime.LiveObjects[id] = nil
        end
        releaseReservation(state, reason)
    end
    runtime.roamAmbient = nil
    Service.NextAttemptAt[id] = Service.CurrentTime()
        + (tonumber(Service.ACTION_COOLDOWN_MS) or 30000)
    return true
end

function Service.Stop(record, zombie, reason, interruptReason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamAmbient or nil
    local scene = runtime and runtime.animationScene or nil
    if not state then return false end
    if scene and scene.id == state.sceneId
        and Scenes and Scenes.Interrupt
    then
        Scenes.Interrupt(record, zombie, interruptReason or "movement")
        if runtime.animationScene and Scenes.Internal
            and Scenes.Internal.ClearScene
        then
            Scenes.Internal.ClearScene(record, zombie,
                "roam_ambient_stop", true)
        end
    end
    Service.Finish(record, zombie, reason or "roam_ambient_stopped")
    return true
end

function Service.StartScene(record, zombie, state, at)
    local started
    local reason
    if not Scenes or not Scenes.Request then
        started, reason = false, "animation_api_unavailable"
    else
        started, reason = Scenes.Request(record, zombie, state.sceneId, {
            now = at,
            reason = "roam_ambient_" .. tostring(state.action),
            repeatMode = state.action == "sleep" and "loop" or "once",
        })
    end
    if started ~= true then
        state.startReason = tostring(reason or "scene_request_failed")
        if Service.ScheduleState(record).lastAttemptKey == state.scheduleKey then
            Service.ScheduleState(record).lastAttemptKey = nil
        end
        Service.Stop(record, zombie, "roam_ambient_scene_failed", "movement")
        return false
    end
    state.phase = state.action == "sleep" and "SLEEPING" or "ACTIVE"
    return true
end

function Service.StartInstantAction(record, zombie, plan, at)
    local runtime = record.runtime or {}
    local state = {
        action = plan.action, sceneId = SCENE_BY_ACTION[plan.action],
        scheduleKey = plan.key, startedAt = at, phase = "STARTING",
    }
    runtime.roamAmbient = state
    Service.ScheduleState(record).lastAttemptKey = plan.key
    record.activeBehavior = "Roam:ambient:" .. tostring(plan.action)
    if Common and Common.ClearCombatTarget then
        Common.ClearCombatTarget(record, "roam_ambient_start", zombie)
    end
    if Common and Common.HaltMovement then
        Common.HaltMovement(record, zombie, "roam_ambient_start")
    end
    return Service.StartScene(record, zombie, state, at)
end

function Service.StartSleep(record, zombie, plan, candidate, at)
    local runtime = record.runtime or {}
    local sleep = PNC.FacilityJobs and PNC.FacilityJobs.Sleep
    local ok
    local reservation
    local state
    if not sleep or not sleep.PrepareSleepSurface
        or not sleep.ClearSleepSurface
        or not Reservations or not Reservations.ReserveResource
    then
        return false
    end
    ok, reservation = Reservations.ReserveResource(
        "ambient:roam", candidate.resource, record.id,
        "ambient_roam_sleep", 30000, { automatic = true, ambient = true })
    if not ok or type(reservation) ~= "table" then return false end
    state = {
        action = "sleep",
        sceneId = "ambient.roam.sleep." .. tostring(
            candidate.resource.sleepSurface or "bed"),
        scheduleKey = plan.key, wakeAt = plan.wakeAt,
        startedAt = at, phase = "TRAVELLING", reservationId = reservation.id,
        resourceKey = candidate.resource.resourceKey,
        resourceKind = candidate.resource.resourceKind,
        resource = PNC.FacilityResources.CopyDescriptor
            and PNC.FacilityResources.CopyDescriptor(candidate.resource)
            or candidate.resource,
        positioned = false, arrivalSettled = false,
        sleepSurfaceEntered = false,
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
