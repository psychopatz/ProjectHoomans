--[[
    PNC Stamina Movement
    Tracks locomotion exhaustion, movement drain, and the short sprint breather
    used by fake locomotion and combat retreat spacing.
]]

PNC = PNC or {}
PNC.Stamina = PNC.Stamina or {}

local Stamina = PNC.Stamina
local Core = PNC.Core
local Const = PNC.Const

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

local function ensureRuntime(record)
    local runtime
    if not record then
        return nil
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    runtime.moveExhausted = runtime.moveExhausted == true
    runtime.moveExhaustedProfileKey = runtime.moveExhaustedProfileKey or nil
    runtime.sprintSlowUntil = tonumber(runtime.sprintSlowUntil) or 0
    runtime.staminaRecoveryMode = runtime.staminaRecoveryMode or nil
    return runtime
end

local function getThresholds(requestedMode)
    requestedMode = tostring(requestedMode or "walk")
    if requestedMode == "crawl" then
        return Const.STAMINA_MOVE_CRAWL_PAUSE, Const.STAMINA_MOVE_CRAWL_RESUME
    end
    if requestedMode == "sneak" or requestedMode == "recovery_walk" or requestedMode == "recovery_sneak" then
        return Const.STAMINA_MOVE_RECOVERY_PAUSE, Const.STAMINA_MOVE_RECOVERY_RESUME
    end
    return Const.STAMINA_MOVE_EXHAUST_PAUSE, Const.STAMINA_MOVE_EXHAUST_RESUME
end

local function resolveExhaustedProfile(requestedMode, staminaMode, now, runtime)
    requestedMode = tostring(requestedMode or "walk")
    staminaMode = tostring(staminaMode or "travel")
    if requestedMode == "crawl" then
        return "crawl"
    end
    if requestedMode == "sneak" then
        return "recovery_sneak"
    end
    if requestedMode == "run" then
        runtime.sprintSlowUntil = math.max(tonumber(runtime.sprintSlowUntil) or 0, now + Const.STAMINA_SPRINT_BREATHER_MS)
        if staminaMode == "combat_close" or staminaMode == "combat_retreat" then
            return "recovery_walk"
        end
        return "recovery_sneak"
    end
    return "recovery_walk"
end

local function getDrainPerSecond(profileKey)
    profileKey = tostring(profileKey or "walk")
    if profileKey == "run" then
        return Const.STAMINA_MOVE_DRAIN_RUN
    end
    if profileKey == "sneak" then
        return Const.STAMINA_MOVE_DRAIN_SNEAK
    end
    if profileKey == "crawl" then
        return Const.STAMINA_MOVE_DRAIN_CRAWL
    end
    if profileKey == "recovery_walk" then
        return Const.STAMINA_MOVE_DRAIN_RECOVERY_WALK
    end
    if profileKey == "recovery_sneak" then
        return Const.STAMINA_MOVE_DRAIN_RECOVERY_SNEAK
    end
    return Const.STAMINA_MOVE_DRAIN_WALK
end

function Stamina.BuildMovementProfile(record, requestedMode, options)
    local runtime = ensureRuntime(record)
    local now = tonumber(options and options.now) or Core.Now()
    local ratio = Stamina.GetRatio(record)
    local pauseRatio
    local resumeRatio
    local staminaMode
    local moveExhausted
    local profileKey

    requestedMode = tostring(requestedMode or "walk")
    staminaMode = tostring(options and options.staminaMode or "travel")
    pauseRatio, resumeRatio = getThresholds(requestedMode)
    moveExhausted = runtime and runtime.moveExhausted == true or false

    if moveExhausted and ratio >= resumeRatio then
        moveExhausted = false
        if runtime then
            runtime.moveExhausted = false
            runtime.moveExhaustedProfileKey = nil
        end
    elseif (not moveExhausted) and ratio <= pauseRatio then
        moveExhausted = true
        if runtime then
            runtime.moveExhausted = true
        end
    end

    if requestedMode == "run" and (tonumber(runtime and runtime.sprintSlowUntil or 0) or 0) > now then
        profileKey = staminaMode == "sneak" and "recovery_sneak" or "recovery_walk"
        moveExhausted = true
        if runtime then
            runtime.moveExhausted = true
            runtime.moveExhaustedProfileKey = profileKey
        end
    elseif moveExhausted then
        profileKey = resolveExhaustedProfile(requestedMode, staminaMode, now, runtime or {})
        if runtime then
            runtime.moveExhaustedProfileKey = profileKey
        end
    else
        profileKey = requestedMode
    end

    if runtime then
        runtime.staminaRecoveryMode = options and options.moving and staminaMode or nil
    end

    return {
        requestedMode = requestedMode,
        profileKey = profileKey,
        staminaMode = staminaMode,
        ratio = ratio,
        pauseRatio = pauseRatio,
        resumeRatio = resumeRatio,
        moveExhausted = moveExhausted,
    }
end

function Stamina.ApplyMovementDrain(record, elapsedSeconds)
    local stamina = record and record.stamina or nil
    local runtime = ensureRuntime(record)
    local lane = runtime and runtime.pathing or nil
    local profileKey
    local staminaMode
    local drainPerSecond
    local drain

    if not stamina or not lane then
        return 0
    end
    if lane.phase ~= "requested" and lane.phase ~= "active" then
        if runtime then
            runtime.staminaRecoveryMode = runtime.target and "combat_close" or nil
        end
        return 0
    end

    profileKey = lane.profileKey or lane.resolvedMode or lane.mode or "walk"
    staminaMode = tostring(lane.staminaMode or "travel")
    drainPerSecond = getDrainPerSecond(profileKey)
    if staminaMode == "combat_close" then
        drainPerSecond = drainPerSecond + 1.0
    elseif staminaMode == "combat_retreat" and profileKey == "run" then
        drainPerSecond = drainPerSecond + 1.5
    elseif staminaMode == "crawl" then
        drainPerSecond = math.max(0.5, drainPerSecond - 0.2)
    end
    if runtime and runtime.moveExhausted == true then
        drainPerSecond = math.max(0.5, drainPerSecond * 0.55)
        runtime.staminaRecoveryMode = "move_recovery"
    else
        runtime.staminaRecoveryMode = staminaMode
    end

    drain = math.max(0, drainPerSecond * math.max(0, tonumber(elapsedSeconds) or 0))
    stamina.current = clamp((tonumber(stamina.current) or 0) - drain, 0, tonumber(stamina.max) or 100)
    return drain
end
