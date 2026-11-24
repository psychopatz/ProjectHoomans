local T = require "tests/support/test"

T.addPackagePaths()

local nowMs = 1000
local worldHours = 29.0
local timeOfDay = 14.0
local engineReads = 0

getGameTime = function()
    engineReads = engineReads + 1
    return {
        getWorldAgeHours = function() return worldHours end,
        getTimeOfDay = function() return timeOfDay end,
    }
end

PNC = {
    Core = {
        Now = function() return nowMs end,
    },
}

local Clock = T.load("ProjectHoomans", "shared", "PNC/Core/Base/PNC_WorldClock.lua")

-- 1. Caching: multiple reads inside CACHE_TTL_MS hit engine only once.
Clock.Reset()
local snap1 = Clock.Snapshot(nowMs)
T.equal(engineReads, 1, "first Snapshot should sample engine once")
T.equal(snap1.timeOfDay, 14.0, "timeOfDay mismatch")
T.equal(snap1.band, "day", "14:00 should be day")
T.falsy(snap1.isNightCamp, "14:00 should not be night camp")
T.falsy(snap1.isSleepCurfew, "14:00 should not be sleep curfew")

nowMs = nowMs + 100
T.equal(Clock.GetTimeOfDay(), 14.0, "cached GetTimeOfDay mismatch")
T.equal(Clock.GetWorldAgeHours(), 29.0, "cached GetWorldAgeHours mismatch")
T.falsy(Clock.IsNightCampHour(), "cached IsNightCampHour mismatch")
T.falsy(Clock.IsSleepCurfewHour(), "cached IsSleepCurfewHour mismatch")
T.equal(engineReads, 1, "subsequent reads within TTL should use cache")

-- 2. Cache expiry refreshes from engine.
timeOfDay = 20.0
worldHours = 35.0
nowMs = nowMs + Clock.CACHE_TTL_MS
local snap2 = Clock.Snapshot(nowMs)
T.equal(engineReads, 2, "Snapshot after TTL should resample engine")
T.equal(snap2.timeOfDay, 20.0, "refreshed timeOfDay mismatch")
T.equal(snap2.band, "dusk", "20:00 should be dusk")
T.truthy(snap2.isNightCamp, "20:00 should be night camp")
T.falsy(snap2.isSleepCurfew, "20:00 should not yet be 11 PM sleep curfew")

-- 3. 11 PM curfew & overnight cycle key consistency.
timeOfDay = 23.5
worldHours = 38.5
local snap3 = Clock.Snapshot(nowMs, true)
T.equal(engineReads, 3, "forced Snapshot should resample engine")
T.truthy(snap3.isNightCamp, "23:30 should be night camp")
T.truthy(snap3.isSleepCurfew, "23:30 should be sleep curfew")
T.equal(snap3.band, "night", "23:30 should be night band")

local keyEvening, dawnEvening = Clock.NightCycleKey(35.0, 20.0)
local keyLate, dawnLate = Clock.NightCycleKey(41.0, 2.0)
T.equal(keyEvening, keyLate, "20:00 and 02:00 of the same night must share one cycle key")
T.near(dawnEvening, dawnLate, 0.01, "dawn world-age hour should match across midnight")
T.near(Clock.NightRemainingHours(20.0), 10.0, 0.01, "20:00 -> 06:00 should be 10h remaining")
T.near(Clock.NightRemainingHours(2.0), 4.0, 0.01, "02:00 -> 06:00 should be 4h remaining")
T.equal(Clock.NightRemainingHours(12.0), 0, "12:00 daytime should have 0 night hours remaining")

T.finish("pnc_world_clock_smoke")
