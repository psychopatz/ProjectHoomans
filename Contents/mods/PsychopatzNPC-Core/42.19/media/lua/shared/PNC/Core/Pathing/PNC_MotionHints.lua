--[[
    PNC Motion Hints
    Shared helpers for compact, server-authored movement segments that clients
    can interpolate visually without taking locomotion authority.
]]

PNC = PNC or {}
PNC.MotionHints = PNC.MotionHints or {}

local MotionHints = PNC.MotionHints
local Core = PNC.Core

local function clamp(value, minValue, maxValue)
    value = tonumber(value) or minValue
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
end

local function copyHint(hint)
    if type(hint) ~= "table" then
        return nil
    end
    return {
        fromX = tonumber(hint.fromX) or 0,
        fromY = tonumber(hint.fromY) or 0,
        fromZ = tonumber(hint.fromZ) or 0,
        toX = tonumber(hint.toX) or 0,
        toY = tonumber(hint.toY) or 0,
        toZ = tonumber(hint.toZ) or 0,
        dirX = tonumber(hint.dirX) or 0,
        dirY = tonumber(hint.dirY) or 0,
        startedAt = tonumber(hint.startedAt) or 0,
        durationMs = clamp(hint.durationMs, 40, 1200),
        kind = hint.kind and tostring(hint.kind) or nil,
        moveAnim = hint.moveAnim and tostring(hint.moveAnim) or nil,
        walkType = hint.walkType and tostring(hint.walkType) or nil,
        engineWalkType = hint.engineWalkType and tostring(hint.engineWalkType) or nil,
        animSpeed = tonumber(hint.animSpeed) or nil,
        isRunning = hint.isRunning == true,
        isCrawling = hint.isCrawling == true,
        profileKey = hint.profileKey and tostring(hint.profileKey) or nil,
    }
end

local function computeDurationMs(fromX, fromY, toX, toY, options, lane)
    local dx = (tonumber(toX) or 0) - (tonumber(fromX) or 0)
    local dy = (tonumber(toY) or 0) - (tonumber(fromY) or 0)
    local distance = math.sqrt((dx * dx) + (dy * dy))
    local explicit = options and tonumber(options.durationMs) or nil
    local speed = options and tonumber(options.speed) or tonumber(lane and lane.speed) or 0
    if explicit then
        return clamp(math.floor(explicit + 0.5), 40, 1200)
    end
    if distance <= 0.001 then
        return 120
    end
    if speed <= 0.001 then
        return 150
    end
    return clamp(math.floor((distance / speed) * 1000), 40, 1200)
end

function MotionHints.Clear(lane)
    if not lane then
        return
    end
    lane.motionHint = nil
end

function MotionHints.Remember(lane, fromX, fromY, fromZ, toX, toY, toZ, now, options)
    local profile
    local durationMs
    local dx
    local dy
    if not lane then
        return nil
    end
    options = type(options) == "table" and options or {}
    profile = options.profile or lane.motionProfile or nil
    durationMs = computeDurationMs(fromX, fromY, toX, toY, options, lane)
    dx = (tonumber(toX) or tonumber(fromX) or 0) - (tonumber(fromX) or 0)
    dy = (tonumber(toY) or tonumber(fromY) or 0) - (tonumber(fromY) or 0)
    lane.motionHint = {
        fromX = tonumber(fromX) or 0,
        fromY = tonumber(fromY) or 0,
        fromZ = tonumber(fromZ) or 0,
        toX = tonumber(toX) or tonumber(fromX) or 0,
        toY = tonumber(toY) or tonumber(fromY) or 0,
        toZ = tonumber(toZ) or tonumber(fromZ) or 0,
        dirX = dx,
        dirY = dy,
        startedAt = tonumber(now) or Core.Now(),
        durationMs = durationMs,
        kind = options.kind and tostring(options.kind) or "move",
        moveAnim = profile and tostring(profile.moveAnim or lane.moveAnim or "Walk") or tostring(lane.moveAnim or "Walk"),
        walkType = profile and tostring(profile.walkType or lane.walkType or "") or tostring(lane.walkType or ""),
        engineWalkType = profile and tostring(profile.engineWalkType or lane.engineWalkType or "") or tostring(lane.engineWalkType or ""),
        animSpeed = tonumber(profile and profile.animSpeed) or tonumber(lane.animSpeed) or 1.0,
        isRunning = profile and profile.isRunning == true or lane.isRunning == true,
        isCrawling = profile and profile.isCrawling == true or lane.isCrawling == true,
        profileKey = profile and tostring(profile.profileKey or lane.profileKey or "walk") or tostring(lane.profileKey or "walk"),
    }
    return lane.motionHint
end

function MotionHints.RememberHold(lane, x, y, z, now, durationMs, options)
    options = type(options) == "table" and options or {}
    options.durationMs = durationMs
    return MotionHints.Remember(lane, x, y, z, x, y, z, now, options)
end

function MotionHints.Copy(hint)
    return copyHint(hint)
end

function MotionHints.BuildNetworkHint(record, lane, now)
    local hint = lane and lane.motionHint or nil
    local currentX
    local currentY
    local currentZ
    local lastX
    local lastY
    local lastZ
    local durationMs
    local rebuilt
    if not record or not lane then
        return nil
    end
    currentX = tonumber(record.x)
    currentY = tonumber(record.y)
    currentZ = tonumber(record.z)
    if currentX == nil or currentY == nil or currentZ == nil then
        return nil
    end
    lastX = lane.lastNetworkX ~= nil and tonumber(lane.lastNetworkX) or nil
    lastY = lane.lastNetworkY ~= nil and tonumber(lane.lastNetworkY) or nil
    lastZ = lane.lastNetworkZ ~= nil and tonumber(lane.lastNetworkZ) or nil
    if lastX ~= nil and lastY ~= nil and lastZ ~= nil then
        durationMs = clamp((tonumber(now) or Core.Now()) - (tonumber(lane.lastNetworkAt) or 0), 60, 450)
        rebuilt = MotionHints.Remember(
            { motionProfile = lane.motionProfile, moveAnim = lane.moveAnim, walkType = lane.walkType, engineWalkType = lane.engineWalkType, animSpeed = lane.animSpeed, isRunning = lane.isRunning, isCrawling = lane.isCrawling, profileKey = lane.profileKey, speed = lane.speed },
            lastX,
            lastY,
            lastZ,
            currentX,
            currentY,
            currentZ,
            tonumber(lane.lastNetworkAt) or ((tonumber(now) or Core.Now()) - durationMs),
            {
                durationMs = (hint and (hint.kind == "fence_climb" or hint.kind == "window_climb"))
                    and durationMs
                    or math.max(tonumber(hint and hint.durationMs) or 0, durationMs),
                kind = hint and hint.kind or (lane.specialAnim and "special" or "move"),
                profile = lane.motionProfile,
            }
        )
        return copyHint(rebuilt)
    end
    return copyHint(hint)
end

function MotionHints.MarkBroadcast(record, lane, now)
    if not record or not lane then
        return
    end
    lane.lastNetworkX = tonumber(record.x) or lane.lastNetworkX
    lane.lastNetworkY = tonumber(record.y) or lane.lastNetworkY
    lane.lastNetworkZ = tonumber(record.z) or lane.lastNetworkZ
    lane.lastNetworkAt = tonumber(now) or Core.Now()
end
