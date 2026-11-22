-- Start and stop transactions for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.AutonomyExecutors = PNC.AutonomyExecutors or {}
PNC.AutonomyExecutors.RoamAmbient = PNC.AutonomyExecutors.RoamAmbient or {}

local Service = PNC.AutonomyExecutors.RoamAmbient
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local SCENE_BY_ACTION = {
    eat = "ambient.roam.eat", drink = "ambient.roam.drink",
}

function Service.CanWrite(record, reason)
    if ActorControl and ActorControl.CanWrite then
        return ActorControl.CanWrite(
            record,
            nil,
            "roam_ambient_provider",
            { reason = reason }
        ) == true
    end
    return true
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
    local reservations = PNC.FacilityReservations
    local id = tostring(state and state.reservationId or "")
    if id ~= "" and reservations and reservations.Release then
        reservations.Release(id, reason or "roam_ambient_stopped")
    end
    if state then state.reservationId = nil end
end

function Service.Finish(record, zombie, reason, ownerReason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamAmbient or nil
    local sleep = PNC.FacilityJobs and PNC.FacilityJobs.Sleep
    local id = tostring(record and record.id or "")
    if not state or state.finishing == true then return false end
    if not Service.CanWrite(record, ownerReason or reason or "roam_ambient_finish") then
        return false
    end
    state.finishing = true
    if state.action == "sleep" then
        if sleep and sleep.RestoreSleepPosition
            and state.positioned == true
        then
            local restored = sleep.RestoreSleepPosition(
                record, zombie, state, state)
            if not restored then
                state.finishing = false
                state.wakeExitPending = true
                state.wakeExitReason = tostring(reason or "")
                return false
            end
        elseif sleep and sleep.RestorePosition then
            sleep.RestorePosition(record, zombie, state)
        end
        if sleep and sleep.ClearSleepSurface then
            sleep.ClearSleepSurface(record, zombie, state)
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
    local scenes = PNC.AnimationScenes
    if not state then return false end
    if not Service.CanWrite(record, interruptReason or reason
        or "roam_ambient_stop")
    then
        return false
    end
    if scene and scene.id == state.sceneId
        and scenes and scenes.Interrupt
    then
        scenes.Interrupt(record, zombie, interruptReason or "movement")
        if runtime.animationScene and scenes.ClearScene then
            scenes.ClearScene(record, zombie,
                "roam_ambient_stop", true)
        end
    end
    Service.Finish(
        record,
        zombie,
        reason or "roam_ambient_stopped",
        interruptReason or reason
    )
    return true
end

function Service.StartScene(record, zombie, state, at)
    local started
    local reason
    local scenes = PNC.AnimationScenes
    if not Service.CanWrite(record, "roam_ambient_scene_start") then
        return false, "puppet_opera_writer_blocked:roam_ambient_provider"
    end
    if not scenes or not scenes.Request then
        started, reason = false, "animation_api_unavailable"
    else
        started, reason = scenes.Request(record, zombie, state.sceneId, {
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
    local common = PNC.BehaviorCommon
    record.runtime = runtime
    if not Service.CanWrite(record, "roam_ambient_start") then
        return false, "puppet_opera_writer_blocked:roam_ambient_provider"
    end
    local state = {
        action = plan.action, sceneId = SCENE_BY_ACTION[plan.action],
        scheduleKey = plan.key, startedAt = at, phase = "STARTING",
    }
    runtime.roamAmbient = state
    Service.ScheduleState(record).lastAttemptKey = plan.key
    record.activeBehavior = "Roam:ambient:" .. tostring(plan.action)
    if common and common.ClearCombatTarget then
        common.ClearCombatTarget(record, "roam_ambient_start", zombie)
    end
    if common and common.HaltMovement then
        common.HaltMovement(record, zombie, "roam_ambient_start")
    end
    return Service.StartScene(record, zombie, state, at)
end

return Service
