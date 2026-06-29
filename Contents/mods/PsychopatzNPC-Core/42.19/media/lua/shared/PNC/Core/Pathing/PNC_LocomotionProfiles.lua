--[[
    PNC Locomotion Profiles
    Resolves shared fake-locomotion profiles so transport, animation, stamina,
    and replication all use the same motion choice and cadence.
]]

PNC = PNC or {}
PNC.LocomotionProfiles = PNC.LocomotionProfiles or {}

local LocomotionProfiles = PNC.LocomotionProfiles
local Stamina = PNC.Stamina

local WALK_SPEED = 0.76
local WALK_ANIM_SPEED = 1.04

local BASE_PROFILES = {
    walk = {
        speed = WALK_SPEED,
        moveAnim = "Walk",
        walkType = "Walk",
        engineWalkType = "Walk",
        isRunning = false,
        isCrawling = false,
        profileKey = "walk",
    },
    run = {
        speed = 2.10,
        moveAnim = "Run",
        walkType = "Run",
        engineWalkType = "Run",
        isRunning = true,
        isCrawling = false,
        profileKey = "run",
    },
    sneak = {
        speed = 0.48,
        moveAnim = "SneakWalk",
        walkType = "SneakWalk",
        engineWalkType = "SneakWalk",
        isRunning = false,
        isCrawling = false,
        profileKey = "sneak",
    },
    crawl = {
        speed = 0.30,
        moveAnim = "Crawl",
        walkType = "Crawl",
        engineWalkType = "",
        isRunning = false,
        isCrawling = true,
        profileKey = "crawl",
    },
    recovery_walk = {
        speed = 0.58,
        moveAnim = "Walk",
        walkType = "Walk",
        engineWalkType = "Walk",
        isRunning = false,
        isCrawling = false,
        profileKey = "recovery_walk",
    },
    recovery_sneak = {
        speed = 0.42,
        moveAnim = "SneakWalk",
        walkType = "SneakWalk",
        engineWalkType = "SneakWalk",
        isRunning = false,
        isCrawling = false,
        profileKey = "recovery_sneak",
    },
}

local function copyProfile(profile)
    local resolved = {}
    local key
    for key, value in pairs(profile or BASE_PROFILES.walk) do
        resolved[key] = value
    end
    return resolved
end

local function clamp(value, minValue, maxValue)
    local numeric = tonumber(value) or minValue
    if numeric < minValue then
        return minValue
    end
    if numeric > maxValue then
        return maxValue
    end
    return numeric
end

local function resolveProfileSpeed(profile)
    if type(profile) == "table" then
        return tonumber(profile.speed) or WALK_SPEED
    end
    return tonumber(BASE_PROFILES[tostring(profile or "walk")] and BASE_PROFILES[tostring(profile or "walk")].speed) or WALK_SPEED
end

local function computeAnimSpeedForProfile(profile)
    local moveAnim
    local speed
    local ratio
    local animSpeed
    if type(profile) ~= "table" then
        profile = BASE_PROFILES[tostring(profile or "walk")] or BASE_PROFILES.walk
    end
    moveAnim = tostring(profile.moveAnim or "Walk")
    speed = resolveProfileSpeed(profile)
    ratio = speed / math.max(0.01, WALK_SPEED)
    animSpeed = WALK_ANIM_SPEED * math.sqrt(math.max(0.2, ratio))
    if moveAnim == "Run" then
        return clamp(animSpeed, 1.40, 1.74)
    end
    if moveAnim == "SneakWalk" then
        return clamp(animSpeed, 0.76, 0.96)
    end
    if moveAnim == "Crawl" then
        return clamp(animSpeed, 0.62, 0.80)
    end
    return clamp(animSpeed, 0.88, 1.12)
end

local function resolveStaminaMode(record, lane, requestedMode)
    local runtime = record and record.runtime or nil
    local retreatState = runtime and runtime.combatRetreat or nil
    requestedMode = tostring(requestedMode or "walk")
    if requestedMode == "crawl" then
        return "crawl"
    end
    if requestedMode == "sneak" or (runtime and runtime.stealthActive == true) then
        return "sneak"
    end
    if retreatState and (tonumber(retreatState.lockUntil) or 0) > 0 then
        return "combat_retreat"
    end
    if runtime and runtime.target then
        return "combat_close"
    end
    return "travel"
end

function LocomotionProfiles.GetBaseProfile(profileKey)
    return copyProfile(BASE_PROFILES[tostring(profileKey or "walk")] or BASE_PROFILES.walk)
end

function LocomotionProfiles.ComputeAnimSpeed(profileOrMode)
    return computeAnimSpeedForProfile(profileOrMode)
end

function LocomotionProfiles.GetSpeed(profileOrMode)
    return resolveProfileSpeed(profileOrMode)
end

function LocomotionProfiles.Resolve(record, lane, zombie, goal, now)
    local requestedMode
    local staminaMode
    local movementProfile
    local profile
    local profileKey
    local lanePhase

    lanePhase = lane and tostring(lane.phase or "idle") or "idle"
    requestedMode = tostring(
        lane and (lane.resolvedMode or lane.mode)
        or goal and goal.mode
        or "walk"
    )
    staminaMode = resolveStaminaMode(record, lane, requestedMode)
    movementProfile = Stamina and Stamina.BuildMovementProfile and Stamina.BuildMovementProfile(record, requestedMode, {
        now = now,
        staminaMode = staminaMode,
        moving = lanePhase == "requested" or lanePhase == "active",
        hasTarget = record and record.runtime and record.runtime.target ~= nil,
        zombie = zombie,
    }) or {
        profileKey = requestedMode,
        requestedMode = requestedMode,
        staminaMode = staminaMode,
        ratio = 1,
        moveExhausted = false,
    }
    profileKey = tostring(movementProfile.profileKey or requestedMode)
    profile = copyProfile(BASE_PROFILES[profileKey] or BASE_PROFILES[requestedMode] or BASE_PROFILES.walk)
    profile.requestedMode = requestedMode
    profile.profileKey = profileKey
    profile.staminaMode = tostring(movementProfile.staminaMode or staminaMode)
    profile.staminaRatio = tonumber(movementProfile.ratio) or 1
    profile.moveExhausted = movementProfile.moveExhausted == true
    profile.pauseRatio = tonumber(movementProfile.pauseRatio) or nil
    profile.resumeRatio = tonumber(movementProfile.resumeRatio) or nil
    profile.animSpeed = tonumber(movementProfile.animSpeed) or computeAnimSpeedForProfile(profile)
    profile.engineWalkType = tostring(profile.engineWalkType or "")
    profile.walkType = tostring(profile.walkType or "")
    profile.moveAnim = tostring(profile.moveAnim or "Walk")
    profile.isRunning = profile.isRunning == true
    profile.isCrawling = profile.isCrawling == true
    return profile
end
