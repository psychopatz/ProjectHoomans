-- Extensible actor posture contract for stationary and contextual behaviors.
-- Future behaviors (wall leaning, crouch work, fireside warmth, etc.) register
-- posture providers here instead of duplicating checks across idle/gaze/facing.

local LiveBodyControl = PNC.LiveBodyControl

LiveBodyControl.POSTURE_STANDING = "STANDING"
LiveBodyControl.POSTURE_SEATED_FURNITURE = "SEATED_FURNITURE"
LiveBodyControl.POSTURE_SEATED_GROUND = "SEATED_GROUND"
LiveBodyControl.POSTURE_LEANING = "LEANING"
LiveBodyControl.POSTURE_SLEEPING = "SLEEPING"
LiveBodyControl.POSTURE_OPERA_STATIONARY = "OPERA_STATIONARY"
LiveBodyControl.POSTURE_OPERA_CARRYING = "OPERA_CARRYING"
LiveBodyControl.POSTURE_OPERA_CARRIED = "OPERA_CARRIED"

LiveBodyControl.PostureProviders = LiveBodyControl.PostureProviders or {}

local ROTATION_LOCKED_POSTURES = {
    [LiveBodyControl.POSTURE_SEATED_FURNITURE] = true,
    [LiveBodyControl.POSTURE_LEANING] = true,
    [LiveBodyControl.POSTURE_SLEEPING] = true,
    [LiveBodyControl.POSTURE_OPERA_STATIONARY] = true,
    [LiveBodyControl.POSTURE_OPERA_CARRIED] = true,
}

local function isFloorSeatingState(state, order)
    if type(state) == "table" then
        if state.floorSeating == true then return true end
        if tostring(state.resourceKind or "") == "floor_seating" then
            return true
        end
        if tostring(state.sceneId or "") == "facility.living.sit" then
            return true
        end
    end
    if type(order) == "table" then
        if order.floorSeating == true then return true end
        if tostring(order.resourceKind or "") == "floor_seating" then
            return true
        end
        if tostring(order.sceneId or "") == "facility.living.sit" then
            return true
        end
    end
    return false
end

local function hasSeatedBodyFlags(zombie)
    if not zombie then return false, false end
    if zombie.isSittingOnFurniture
        and zombie:isSittingOnFurniture() == true
    then
        return true, false
    end
    if zombie.isSitOnGround and zombie:isSitOnGround() == true then
        return true, true
    end
    if zombie.getVariableBoolean
        and zombie:getVariableBoolean("PNCSeated") == true
    then
        return true, false
    end
    return false, false
end

---Registers a custom posture resolver `fn(record, zombie) -> postureString|nil`.
function LiveBodyControl.RegisterPostureProvider(name, resolver)
    local key = tostring(name or "")
    if key == "" or type(resolver) ~= "function" then
        return false
    end
    LiveBodyControl.PostureProviders[key] = resolver
    return true
end

function LiveBodyControl.UnregisterPostureProvider(name)
    local key = tostring(name or "")
    if key == "" then return false end
    LiveBodyControl.PostureProviders[key] = nil
    return true
end

---Returns the canonical posture string for `record`/`zombie`.
function LiveBodyControl.GetPosture(record, zombie)
    local runtime = type(record) == "table" and record.runtime or nil
    if LiveBodyControl.IsSleeping and LiveBodyControl.IsSleeping(record) then
        return LiveBodyControl.POSTURE_SLEEPING
    end
    if LiveBodyControl.IsSeated and LiveBodyControl.IsSeated(record) then
        local activity = runtime and runtime.facilityActivity or nil
        local roamingSeat = runtime and runtime.roamingSeat or nil
        if (activity and activity.seating == true
                and isFloorSeatingState(activity, record and record.orderSpec))
            or (roamingSeat and roamingSeat.seating == true
                and isFloorSeatingState(roamingSeat, nil))
        then
            return LiveBodyControl.POSTURE_SEATED_GROUND
        end
        return LiveBodyControl.POSTURE_SEATED_FURNITURE
    end
    if runtime and type(runtime.postureState) == "string"
        and runtime.postureState ~= ""
    then
        return runtime.postureState
    end
    for _, resolver in pairs(LiveBodyControl.PostureProviders) do
        local ok, posture = pcall(resolver, record, zombie)
        if ok and type(posture) == "string" and posture ~= "" then
            return posture
        end
    end
    local seatedFlag, isGround = hasSeatedBodyFlags(zombie)
    if seatedFlag then
        return isGround and LiveBodyControl.POSTURE_SEATED_GROUND
            or LiveBodyControl.POSTURE_SEATED_FURNITURE
    end
    return LiveBodyControl.POSTURE_STANDING
end

---True when body yaw must remain locked to furniture/wall/bed geometry.
function LiveBodyControl.IsBodyRotationLocked(record, zombie)
    local posture = LiveBodyControl.GetPosture(record, zombie)
    return ROTATION_LOCKED_POSTURES[posture] == true
end

---True only when a full-body standing idle animation is safe to inject.
function LiveBodyControl.AllowsStandingIdle(record, zombie)
    local runtime = type(record) == "table" and record.runtime or nil
    local orderKind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    if orderKind == "facility_activity" then
        return false
    end
    if runtime and (
        runtime.facilityActivity ~= nil
        or runtime.roamingSeat ~= nil
        or runtime.roamAmbient ~= nil
        or runtime.lifeActivity ~= nil
    ) then
        return false
    end
    return LiveBodyControl.GetPosture(record, zombie)
        == LiveBodyControl.POSTURE_STANDING
end

return LiveBodyControl
