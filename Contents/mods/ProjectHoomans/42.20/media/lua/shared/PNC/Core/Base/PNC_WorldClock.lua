--[[
    PNC WorldClock
    Single cached source of truth for Project Zomboid world-age hours,
    clock time-of-day, time bands, and night/curfew windows across server
    and client subsystems. Avoids repeated Java GameTime JNI calls per tick
    and guarantees every subsystem agrees on what time of day it is.
]]

PNC = PNC or {}
PNC.WorldClock = PNC.WorldClock or {}

local Clock = PNC.WorldClock

Clock.CACHE_TTL_MS = 250
Clock.CAMP_START_HOUR = 19
Clock.SLEEP_CURFEW_HOUR = 23
Clock.NIGHT_END_HOUR = 6
Clock.DAWN_START_HOUR = 5
Clock.DAY_START_HOUR = 8
Clock.DUSK_START_HOUR = 17
Clock.NIGHT_START_HOUR = 21

local cachedSnapshot = nil
local cachedAtMs = -1

local function nowMs(override)
    if override ~= nil then
        return tonumber(override) or 0
    end
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        return tonumber(core.Now()) or 0
    end
    if type(getTimeInMillis) == "function" then
        return tonumber(getTimeInMillis()) or 0
    end
    if type(getTimestampMs) == "function" then
        return tonumber(getTimestampMs()) or 0
    end
    return 0
end

local function normalizeHour(hour)
    local h = tonumber(hour)
    if h == nil then return 12 end
    h = h % 24
    if h < 0 then h = h + 24 end
    return h
end

local function computeBand(hour)
    hour = normalizeHour(hour)
    if hour >= Clock.DAWN_START_HOUR and hour < Clock.DAY_START_HOUR then
        return "dawn"
    end
    if hour >= Clock.DUSK_START_HOUR and hour < Clock.NIGHT_START_HOUR then
        return "dusk"
    end
    if hour < Clock.DAWN_START_HOUR or hour >= Clock.NIGHT_START_HOUR then
        return "night"
    end
    return "day"
end

local function isNightCamp(hour)
    hour = normalizeHour(hour)
    return hour >= Clock.CAMP_START_HOUR or hour < Clock.NIGHT_END_HOUR
end

local function isSleepCurfew(hour)
    hour = normalizeHour(hour)
    return hour >= Clock.SLEEP_CURFEW_HOUR or hour < Clock.NIGHT_END_HOUR
end

local function sampleFromEngine(now)
    local gt = type(getGameTime) == "function" and getGameTime() or nil
    local worldAgeHours = 0
    local tod = nil
    local available = false

    if gt then
        if gt.getWorldAgeHours then
            local ok, val = pcall(gt.getWorldAgeHours, gt)
            if ok and tonumber(val) ~= nil then
                worldAgeHours = tonumber(val)
                available = true
            end
        end
        if gt.getTimeOfDay then
            local ok, val = pcall(gt.getTimeOfDay, gt)
            if ok and tonumber(val) ~= nil then
                tod = normalizeHour(val)
                available = true
            end
        end
        if tod == nil and gt.getHour then
            local okH, h = pcall(gt.getHour, gt)
            local okM, m = gt.getMinutes and pcall(gt.getMinutes, gt) or false, 0
            if okH and tonumber(h) ~= nil then
                tod = normalizeHour(tonumber(h) + (okM and (tonumber(m) or 0) or 0) / 60)
                available = true
            end
        end
    end

    if tod == nil then
        tod = normalizeHour(worldAgeHours)
    end

    local wholeHour = math.floor(tod)
    local minute = math.max(0, math.min(59, math.floor((tod - wholeHour) * 60 + 0.5)))

    local snap = cachedSnapshot or {}
    snap.available = available
    snap.sampledAtMs = now
    snap.worldAgeHours = worldAgeHours
    snap.timeOfDay = tod
    snap.hour = wholeHour
    snap.minute = minute
    snap.band = computeBand(tod)
    snap.isNightCamp = isNightCamp(tod)
    snap.isSleepCurfew = isSleepCurfew(tod)
    snap.isNight = (tod >= Clock.NIGHT_START_HOUR or tod < Clock.DAWN_START_HOUR)

    cachedSnapshot = snap
    cachedAtMs = now
    return snap
end

function Clock.Invalidate()
    cachedSnapshot = nil
    cachedAtMs = -1
end

Clock.Reset = Clock.Invalidate

function Clock.Snapshot(now, force)
    local t = nowMs(now)
    if not force
        and cachedSnapshot ~= nil
        and cachedAtMs >= 0
        and t >= cachedAtMs
        and (t - cachedAtMs) < (tonumber(Clock.CACHE_TTL_MS) or 250)
    then
        return cachedSnapshot
    end
    return sampleFromEngine(t)
end

function Clock.GetWorldAgeHours(now, force)
    return Clock.Snapshot(now, force).worldAgeHours
end

function Clock.GetTimeOfDay(now, force)
    return Clock.Snapshot(now, force).timeOfDay
end

function Clock.GetTimeBand(hourOverride, now)
    if hourOverride ~= nil then
        return computeBand(hourOverride)
    end
    return Clock.Snapshot(now).band
end

function Clock.IsNightCampHour(hourOverride, now)
    if hourOverride ~= nil then
        return isNightCamp(hourOverride)
    end
    return Clock.Snapshot(now).isNightCamp
end

function Clock.IsSleepCurfewHour(hourOverride, now)
    if hourOverride ~= nil then
        return isSleepCurfew(hourOverride)
    end
    return Clock.Snapshot(now).isSleepCurfew
end

function Clock.NightRemainingHours(hourOverride, now)
    local tod = hourOverride ~= nil
        and normalizeHour(hourOverride)
        or Clock.GetTimeOfDay(now)
    if tod >= Clock.CAMP_START_HOUR then
        return (24 - tod) + Clock.NIGHT_END_HOUR
    end
    if tod < Clock.NIGHT_END_HOUR then
        return Clock.NIGHT_END_HOUR - tod
    end
    return 0
end

function Clock.NightCycleKey(worldAgeHours, timeOfDay, now)
    local snap = (worldAgeHours == nil or timeOfDay == nil) and Clock.Snapshot(now) or nil
    local hours = tonumber(worldAgeHours) or (snap and snap.worldAgeHours) or 0
    local tod = timeOfDay ~= nil and normalizeHour(timeOfDay) or (snap and snap.timeOfDay) or 0
    local remaining = Clock.NightRemainingHours(tod)
    local dawnWorldHour = hours + remaining
    local cycleKey = math.floor(dawnWorldHour / 24 + 0.5)
    return cycleKey, dawnWorldHour
end

return Clock
