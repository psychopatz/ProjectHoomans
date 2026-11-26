-- Shared lifecycle primitives for world-object interaction executors
-- (settlement, camp, roaming seat, roaming sleep, and future object actions).
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorldObjects = PNC.WorldObjects or {}
PNC.WorldObjects.ActivityHelpers = PNC.WorldObjects.ActivityHelpers or {}

local Helpers = PNC.WorldObjects.ActivityHelpers

function Helpers.ReleaseReservation(state, reason, reservationsService)
    local reservations = reservationsService or PNC.FacilityReservations
    local id = tostring(state and state.reservationId or "")
    if id ~= "" and reservations and type(reservations.Release) == "function" then
        reservations.Release(id, reason or "object_activity_stopped")
    end
    if state then state.reservationId = nil end
end

function Helpers.InterruptScene(record, zombie, state, interruptReason, clearReason)
    local runtime = record and record.runtime or nil
    local scene = runtime and runtime.animationScene or nil
    local scenes = PNC.AnimationScenes
    if not state or not scene or scene.id ~= state.sceneId
        or not scenes or type(scenes.Interrupt) ~= "function"
    then
        return false
    end
    scenes.Interrupt(record, zombie, interruptReason or "movement")
    if runtime.animationScene and type(scenes.ClearScene) == "function" then
        scenes.ClearScene(record, zombie, clearReason or "object_activity_stop", true)
    end
    return true
end

function Helpers.BindLiveObject(runtimeTable, record, object)
    if type(runtimeTable) ~= "table" or not record or record.id == nil then
        return false
    end
    runtimeTable.LiveObjects = runtimeTable.LiveObjects or {}
    runtimeTable.LiveObjects[tostring(record.id)] = object
    return true
end

function Helpers.ClearLiveObject(runtimeTable, record)
    if type(runtimeTable) ~= "table" or not runtimeTable.LiveObjects
        or not record or record.id == nil
    then
        return false
    end
    runtimeTable.LiveObjects[tostring(record.id)] = nil
    return true
end

function Helpers.ResetPath(record, zombie, reason, facilityHelper)
    if facilityHelper and type(facilityHelper.ResetPath) == "function" then
        facilityHelper.ResetPath(record, zombie, reason)
        return true
    end
    if PNC.PathService and type(PNC.PathService.Reset) == "function" then
        PNC.PathService.Reset(zombie, record)
        return true
    end
    return false
end

return Helpers
