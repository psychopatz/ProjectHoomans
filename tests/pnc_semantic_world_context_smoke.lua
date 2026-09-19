local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}

local now = 1000
local precipitation = 0.40
local climateCalls = 0
local player = {}
function player:getX() return 101.5 end
function player:getY() return 202.5 end
function player:getZ() return 0 end
function player:isInARoom() return false end

local gameTime = {}
function gameTime:getWorldAgeHours() return 49.5 end
function gameTime:getYear() return 1993 end
-- GameTime's month/day accessors are zero-based in the engine.
function gameTime:getMonth() return 6 end
function gameTime:getDay() return 13 end
function gameTime:getTimeOfDay() return 13.5 end
function gameTime:getHour() return 13 end
function gameTime:getMinutes() return 30 end

local climate = {}
function climate:getPrecipitationIntensity()
    climateCalls = climateCalls + 1
    return precipitation
end
function climate:isRaining() return precipitation > 0 end
function climate:getFogIntensity() return 0.25 end
function climate:getAirTemperatureForCharacter(value)
    if value ~= player then error("non-character weather argument") end
    return 18.5
end

getTimeInMillis = function() return now end
getGameTime = function() return gameTime end
getClimateManager = function() return climate end
getSpecificPlayer = function() return player end

local World = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticWorldContext.lua"
)
World.Clear()
local resolvedTimeOfDay
World.SetTimeBandResolver(function(timeOfDay)
    resolvedTimeOfDay = timeOfDay
    return "sunset"
end)

local first = World.Get({ player = player, force = true })
T.equal(first.kind, "world_context", "world context kind")
T.equal(first.gameDay, 2, "world age produces compact game day")
T.equal(first.time.hour, 13, "calendar hour is captured")
T.equal(first.time.minute, 30, "calendar minute is captured")
T.equal(first.time.band, "sunset", "time band uses its injected resolver")
T.equal(resolvedTimeOfDay, 13.5,
    "time band resolver receives the world time snapshot")
T.equal(first.calendar.year, 1993, "calendar year is captured")
T.equal(first.calendar.month, 7, "calendar month is normalized to one-based")
T.equal(first.calendar.day, 14, "calendar day is normalized to one-based")
T.equal(first.weather.raining, true, "rain state is captured")
T.equal(first.weather.foggy, true, "fog state is derived")
T.near(first.weather.temperatureC, 18.5, 0.001,
    "temperature is captured when the API is available")
T.equal(first.environment.indoors, false, "local indoor state is captured")
T.near(first.environment.position.x, 101.5, 0.001,
    "local position is captured")

local identityOnly = World.Get({
    player = "Friend",
    cacheKey = "identity_only",
    force = true,
})
T.near(identityOnly.weather.temperatureC, 18.5, 0.001,
    "display identity is not passed to character weather APIs")

now = 1500
precipitation = 0
local cached = World.Get({ player = player })
T.equal(cached, first, "world context is cached within the sampling window")
T.equal(cached.weather.raining, true, "cached weather remains internally consistent")

now = 2201
local refreshed = World.Get({ player = player })
T.falsy(refreshed == first, "expired world context is resampled")
T.equal(refreshed.weather.raining, false, "resampled rain state updates")
T.truthy(climateCalls >= 2, "weather provider was sampled again")

getGameTime = nil
getClimateManager = nil
getSpecificPlayer = nil
local unavailable = World.Sample({ now = 4000 })
T.equal(unavailable.time.available, false,
    "missing game time is represented as unavailable")
T.equal(unavailable.weather.source, "unavailable",
    "missing climate state is represented as unavailable")

T.finish("pnc_semantic_world_context_smoke")
