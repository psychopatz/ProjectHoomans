-- Goal identity, tolerance, and resolved locomotion-profile policy.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal
local Core = Internal.Core
local LocomotionProfiles = Internal.LocomotionProfiles

function Internal.buildGoal(x, y, z, mode, stopDistance)
    return {
        x = tonumber(x) or 0,
        y = tonumber(y) or 0,
        z = tonumber(z) or 0,
        mode = tostring(mode or "walk"),
        stopDistance = tonumber(stopDistance) or 0.7,
    }
end

function Internal.getGoalTolerance(mode, stopDistance)
    local tolerance = tostring(mode or "walk") == "run" and 1.75 or 1.0
    if mode == "sneak" or mode == "crawl" then
        tolerance = 0.6
    end
    if tonumber(stopDistance) and tonumber(stopDistance) > tolerance then
        tolerance = math.min(tonumber(stopDistance) * 1.25, tolerance + 0.75)
    end
    return tolerance
end

function Internal.computeResolvedMode(record, lane, zombie, goal)
    local dist
    local previousMode
    if not lane or not goal then
        return "walk"
    end
    if lane.mode == "crawl" then
        return "crawl"
    end
    if record and record.runtime and record.runtime.target ~= nil then
        if lane.mode == "run" then
            return "run"
        end
        return "walk"
    end
    -- Behavior owns the requested locomotion mode. Stealth visibility is a
    -- combat/aggro policy and must not silently rewrite an existing path lane.
    if lane.mode == "sneak" then
        return "sneak"
    end
    if lane.mode ~= "walk" and lane.mode ~= "run" then
        return tostring(lane.mode or "walk")
    end
    if not zombie then
        return tostring(lane.mode or "walk")
    end
    dist = Core.Distance(zombie:getX(), zombie:getY(), goal.x, goal.y)
    previousMode = tostring(lane.resolvedMode or lane.mode or "walk")
    if previousMode == "run" then
        if dist <= math.max(tonumber(lane.stopDistance) or 0.7, Internal.RUN_STOP_DISTANCE) then
            return "walk"
        end
        return "run"
    end
    if dist >= math.max((tonumber(lane.stopDistance) or 0.7) + 2.75, Internal.RUN_START_DISTANCE) then
        return "run"
    end
    return "walk"
end

function Internal.computeAnimSpeedForMode(mode)
    if LocomotionProfiles and LocomotionProfiles.ComputeAnimSpeed then
        return LocomotionProfiles.ComputeAnimSpeed(mode)
    end
    return 1.0
end

function Internal.refreshResolvedLocomotion(record, lane, zombie, goal)
    local resolvedMode = Internal.computeResolvedMode(record, lane, zombie, goal)
    local profile
    if lane then
        lane.resolvedMode = resolvedMode
        profile = LocomotionProfiles and LocomotionProfiles.Resolve and LocomotionProfiles.Resolve(record, lane, zombie, goal, Core.Now()) or nil
        lane.motionProfile = profile
        lane.speed = tonumber(profile and profile.speed) or 0
        lane.animSpeed = tonumber(profile and profile.animSpeed) or Internal.computeAnimSpeedForMode(resolvedMode)
        lane.moveAnim = profile and tostring(profile.moveAnim or "Idle") or "Idle"
        lane.walkType = profile and tostring(profile.walkType or "") or ""
        lane.engineWalkType = profile and tostring(profile.engineWalkType or "") or ""
        lane.profileKey = profile and tostring(profile.profileKey or resolvedMode) or tostring(resolvedMode or "walk")
        lane.staminaMode = profile and tostring(profile.staminaMode or "travel") or "travel"
        lane.isRunning = profile and profile.isRunning == true or false
        lane.isCrawling = profile and profile.isCrawling == true or false
    end
    return resolvedMode
end

function Internal.getStopDistanceClass(stopDistance)
    local value = tonumber(stopDistance) or 0.7
    if value <= 0.35 then
        return "tight"
    end
    if value <= 0.9 then
        return "near"
    end
    return "wide"
end

function Internal.goalsDiffer(
    currentGoal,
    nextGoal,
    currentMode,
    coordinateTolerance
)
    local tolerance
    if not currentGoal or not nextGoal then
        return true
    end
    tolerance = tonumber(coordinateTolerance)
        or Internal.getGoalTolerance(
            currentMode or nextGoal.mode,
            nextGoal.stopDistance
        )
    return math.abs((currentGoal.x or 0) - (nextGoal.x or 0)) > tolerance
        or math.abs((currentGoal.y or 0) - (nextGoal.y or 0)) > tolerance
        or (currentGoal.z or 0) ~= (nextGoal.z or 0)
        or tostring(currentMode or "") ~= tostring(nextGoal.mode or "")
        or Internal.getStopDistanceClass(currentGoal.stopDistance) ~= Internal.getStopDistanceClass(nextGoal.stopDistance)
end

function Internal.isAtGoal(zombie, goal, stopDistance)
    local dist
    if not zombie or not goal then
        return false
    end
    dist = Core.Distance(zombie:getX(), zombie:getY(), goal.x, goal.y)
    return dist <= (tonumber(stopDistance) or 0.7) and zombie:getZ() == goal.z
end
