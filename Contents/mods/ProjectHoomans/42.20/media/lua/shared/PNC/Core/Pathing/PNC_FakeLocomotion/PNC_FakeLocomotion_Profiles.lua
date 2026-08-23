PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}
PNC.FakeLocomotion.Internal = PNC.FakeLocomotion.Internal or {}

local FakeLocomotion = PNC.FakeLocomotion
local Internal = FakeLocomotion.Internal
local LocomotionProfiles = PNC.LocomotionProfiles

Internal.Constants = Internal.Constants or {
    MAX_STEP_DELTA_MS = 120,
    MIN_STEP_INTERVAL_MS = 35,
    MAX_NON_PROGRESS_STEPS = 24,
    MIN_CANDIDATE_DISTANCE = 0.0001,
    MIN_GOAL_PROGRESS = 0.001,
    STEERING_RESPONSE_PER_SECOND = 8,
    SHARP_TURN_DOT = 0.25,
    MIN_FORWARD_STEERING_DOT = 0.35,
    FACING_LOOKAHEAD_DISTANCE = 1.0,
}

function Internal.ResolveProfile(lane, mode)
    local profile = lane and lane.motionProfile or nil
    if profile then return profile end
    if LocomotionProfiles and LocomotionProfiles.GetBaseProfile then
        return LocomotionProfiles.GetBaseProfile(mode)
    end
    return {
        speed = 0.68,
        moveAnim = mode == "run" and "Run"
            or mode == "sneak" and "SneakWalk"
            or mode == "crawl" and "Crawl"
            or "Walk",
    }
end

function Internal.GetSpeedForMode(mode, lane)
    local profile = Internal.ResolveProfile(lane, mode)
    return tonumber(profile and profile.speed) or 0.68
end

function FakeLocomotion.GetModeSpeed(mode)
    return Internal.GetSpeedForMode(mode)
end

function FakeLocomotion.ComputeAnimSpeed(mode)
    if LocomotionProfiles and LocomotionProfiles.ComputeAnimSpeed then
        return LocomotionProfiles.ComputeAnimSpeed(mode)
    end
    return 1.0
end

function Internal.ComputeStepDistance(lane, mode, now)
    local constants = Internal.Constants
    local lastStepAt = tonumber(lane and lane.lastStepAt or 0) or 0
    local speed = Internal.GetSpeedForMode(mode, lane)
    local deltaMs
    if lastStepAt <= 0 then return speed * 0.05, 50 end
    deltaMs = math.max(0, now - lastStepAt)
    if deltaMs < constants.MIN_STEP_INTERVAL_MS then
        return 0, deltaMs
    end
    deltaMs = math.min(deltaMs, constants.MAX_STEP_DELTA_MS)
    return speed * (deltaMs / 1000), deltaMs
end

return Internal
