-- Per-record movement, scene, and preemption ticking for roaming ambience.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamAmbient = PNC.RoamAmbient or {}

local Service = PNC.RoamAmbient
local Common = PNC.BehaviorCommon

local function canContinue(record, zombie, state, at)
    local runtime = record and record.runtime or nil
    local health = record and record.health or nil
    if not Service.LiveEligible(record, zombie, true)
        or not state or runtime.roamAmbient ~= state
    then
        return false
    end
    if runtime.target ~= nil or runtime.combatTarget ~= nil
        or runtime.attackAction ~= nil or runtime.facilityActivity ~= nil
        or runtime.workOrderId ~= nil or runtime.taskLeaseId ~= nil
        or runtime.medicalCare ~= nil or runtime.treatment ~= nil
        or at < (tonumber(runtime.inCombatUntil) or 0)
        or at < (tonumber(health and health.recentDamageUntil) or 0)
    then
        return false
    end
    return true
end

function Service.Tick(record, zombie, at)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamAmbient or nil
    local sleep = PNC.FacilityJobs and PNC.FacilityJobs.Sleep
    at = Service.CurrentTime(at)
    if not state then return false end
    if not canContinue(record, zombie, state, at) then
        Service.Stop(record, zombie, "roam_ambient_preempted", "combat")
        return true
    end
    local scene = runtime.animationScene
    if scene and scene.id == state.sceneId then
        if state.action == "sleep"
            and (Service.GetWorldAgeHours and Service.GetWorldAgeHours() or 0)
                >= (tonumber(state.wakeAt) or math.huge)
        then
            Service.Stop(record, zombie, "roam_ambient_sleep_wake", "movement")
            return true
        end
        return false
    end
    if scene then
        Service.Stop(record, zombie, "roam_ambient_scene_replaced", "movement")
        return true
    end
    if state.action ~= "sleep" then
        record.activeBehavior = "Roam:ambient:" .. tostring(state.action)
        Service.StartScene(record, zombie, state, at)
        return true
    end
    if not state.target then
        Service.Stop(record, zombie, "roam_ambient_sleep_target_missing", "movement")
        return true
    end
    local distance = PNC.Core.Distance(zombie:getX(), zombie:getY(),
        state.target.x, state.target.y)
    if distance > 0.85
        or math.abs((tonumber(zombie:getZ()) or 0)
            - (tonumber(state.target.z) or 0)) >= 0.5
    then
        state.phase = "TRAVELLING"
        record.activeBehavior = "Roam:ambient:sleep:travel"
        if Common and Common.ClearCombatTarget then
            Common.ClearCombatTarget(record, "roam_ambient_sleep_travel", zombie)
        end
        if Common and Common.MoveRecord then
            Common.MoveRecord(record, zombie, state.target.x, state.target.y,
                state.target.z, "walk", 0.70, "roam_ambient_sleep")
        end
        return true
    end
    if state.arrivalSettled ~= true then
        Service.ResetPath(record, zombie, "roam_ambient_sleep_arrival")
        if Common and Common.HaltMovement then
            Common.HaltMovement(record, zombie, "roam_ambient_sleep_arrival")
        end
        state.arrivalSettled = true
    end
    if state.positioned ~= true then
        local x = tonumber(state.interactionX) or state.target.x
        local y = tonumber(state.interactionY) or state.target.y
        local z = tonumber(state.interactionZ) or state.target.z
        if not PNC.LiveBodyControl
            or not PNC.LiveBodyControl.SetAuthoritativePosition
        then
            Service.Stop(record, zombie,
                "roam_ambient_sleep_position_unavailable", "movement")
            return true
        end
        state.approachPosition = {
            x = zombie:getX(), y = zombie:getY(), z = zombie:getZ(),
        }
        PNC.LiveBodyControl.SetAuthoritativePosition(zombie, x, y, z)
        record.x, record.y, record.z = x, y, z
        state.positioned = true
    end
    if state.sleepSurfaceEntered ~= true then
        local prepared, reason = sleep.PrepareSleepSurface(
            record, zombie, state, state)
        if not prepared then
            Service.Stop(record, zombie, reason or "roam_ambient_sleep_surface", "movement")
            return true
        end
    end
    if PNC.LiveBodyControl
        and PNC.LiveBodyControl.StabilizePresentationBody
    then
        PNC.LiveBodyControl.StabilizePresentationBody(record, zombie, at, "sleep")
    end
    record.activeBehavior = "Roam:ambient:sleep"
    Service.StartScene(record, zombie, state, at)
    return true
end

function Service.OnSceneTick(record, zombie, scene, at)
    local state = record and record.runtime and record.runtime.roamAmbient
    if not state or not scene or scene.id ~= state.sceneId then return false end
    if not canContinue(record, zombie, state, Service.CurrentTime(at)) then
        return false
    end
    if state.action == "sleep" then
        local hours = Service.GetWorldAgeHours and Service.GetWorldAgeHours() or 0
        return hours < (tonumber(state.wakeAt) or math.huge)
    end
    return true
end

function Service.OnSceneStopped(record, zombie, scene, reason)
    local state = record and record.runtime and record.runtime.roamAmbient
    if state and scene and scene.id == state.sceneId then
        Service.Finish(record, zombie, reason or "roam_ambient_scene_stopped")
    end
end

return Service
