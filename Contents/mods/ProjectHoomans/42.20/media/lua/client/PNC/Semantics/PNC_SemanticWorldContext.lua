-- Cached, client-observed world context for semantic conversation.
--
-- This module only observes the local simulation. It never mutates world
-- state, starts tasks, or decides whether an action is authoritative. The
-- snapshot is intentionally small and cached because it is consumed by both
-- local routing and optional LLM context assembly.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local World = PNC.Semantics.WorldContext or {}
PNC.Semantics.WorldContext = World

require "PNC/Conversation/PNC_ConversationTime"

World.VERSION = 1
World.DEFAULT_TTL_MS = 1000
World.Internal = World.Internal or {}
local cache = {}
local DEFAULT_CACHE_KEY = "__default_player__"

local function call0(object, methodName)
    if object == nil then return false, nil end
    local ok, method = pcall(function() return object[methodName] end)
    if not ok or type(method) ~= "function" then return false, nil end
    return pcall(function() return method(object) end)
end

local function call1(object, methodName, argument)
    if object == nil then return false, nil end
    local ok, method = pcall(function() return object[methodName] end)
    if not ok or type(method) ~= "function" then return false, nil end
    return pcall(function() return method(object, argument) end)
end

local function call2(object, methodName, first, second)
    if object == nil then return false, nil end
    local ok, method = pcall(function() return object[methodName] end)
    if not ok or type(method) ~= "function" then return false, nil end
    return pcall(function() return method(object, first, second) end)
end

local function readMember(object, memberName)
    if object == nil then return nil end
    local ok, value = pcall(function() return object[memberName] end)
    return ok and value or nil
end

local function readNumber(object, methodName)
    local ok, value = call0(object, methodName)
    value = ok and tonumber(value) or nil
    return value
end

local function readBoolean(object, methodName)
    local ok, value = call0(object, methodName)
    if not ok then return nil end
    if value == true or value == false then return value end
    local text = string.lower(tostring(value or ""))
    if text == "true" or text == "1" then return true end
    if text == "false" or text == "0" then return false end
    return nil
end

local function readString(object, methodName)
    local ok, value = call0(object, methodName)
    if not ok then return nil end
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function firstNumber(object, methods)
    local index
    for index = 1, #methods do
        local value = readNumber(object, methods[index])
        if value ~= nil then return value end
    end
    return nil
end

local function firstBoolean(object, methods)
    local index
    for index = 1, #methods do
        local value = readBoolean(object, methods[index])
        if value ~= nil then return value end
    end
    return nil
end

-- GameTime stores month/day as zero-based values. Prefer the engine's
-- explicit day-plus-one helper when available and keep the arithmetic
-- fallback for older/partial test doubles.
local function calendarDay(gameTime)
    local day = readNumber(gameTime, "getDayPlusOne")
    if day ~= nil then return day end
    day = readNumber(gameTime, "getDay")
    return day ~= nil and day + 1 or nil
end

local function calendarMonth(gameTime)
    local month = readNumber(gameTime, "getMonth")
    return month ~= nil and month + 1 or nil
end

local function nowMillis(options)
    if type(options) == "table" and options.now ~= nil then
        return tonumber(options.now) or 0
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and tonumber(value) then return tonumber(value) end
    end
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 0
end

local function globalObject(getter)
    if type(getter) ~= "function" then return nil end
    local ok, value = pcall(getter)
    return ok and value or nil
end

local function isCharacterArgument(value)
    local ok
    local result
    local getX
    local getY
    if value == nil then return false end
    if type(instanceof) == "function" then
        ok, result = pcall(instanceof, value, "IsoGameCharacter")
        if ok then return result == true end
    end
    ok, getX = pcall(function() return value.getX end)
    if not ok or type(getX) ~= "function" then return false end
    ok, getY = pcall(function() return value.getY end)
    return ok and type(getY) == "function"
end

local function localPlayer(options)
    if type(options) == "table"
        and isCharacterArgument(options.player)
    then
        return options.player
    end
    if type(getSpecificPlayer) == "function" then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok then return player end
    end
    return nil
end

local function timeSnapshot(gameTime, worldAgeHours)
    local timeOfDay = readNumber(gameTime, "getTimeOfDay")
    local hour = readNumber(gameTime, "getHour")
    local minutes = readNumber(gameTime, "getMinutes")
    local available = gameTime ~= nil
        and (timeOfDay ~= nil or hour ~= nil or minutes ~= nil)
    if hour == nil and timeOfDay ~= nil then hour = math.floor(timeOfDay) end
    if hour == nil then hour = 12 end
    if minutes == nil and timeOfDay ~= nil then
        minutes = math.floor((timeOfDay - math.floor(timeOfDay)) * 60 + 0.5)
    end
    minutes = minutes or 0
    if timeOfDay == nil then timeOfDay = hour + minutes / 60 end
    local calendar = {
        year = readNumber(gameTime, "getYear"),
        month = calendarMonth(gameTime),
        day = calendarDay(gameTime),
    }
    local gameDay = math.floor((tonumber(worldAgeHours) or 0) / 24)
    local timeBand = nil
    local time = PNC.Conversation and PNC.Conversation.Time
    if time and type(time.Resolve) == "function" then
        local ok, value = pcall(time.Resolve, timeOfDay)
        if ok then timeBand = value end
    end
    return {
        available = available,
        worldAgeHours = tonumber(worldAgeHours) or 0,
        gameDay = gameDay,
        timeOfDay = timeOfDay,
        hour = math.floor(hour),
        minute = math.max(0, math.min(59, math.floor(minutes))),
        band = timeBand,
        calendar = calendar,
    }
end

local function weatherSnapshot(climate, player)
    local precipitation = firstNumber(climate, {
        "getPrecipitationIntensity",
    })
    local raining = firstBoolean(climate, { "isRaining" })
    if raining == nil then
        local value = readMember(climate, "isRaining")
        if value == true or value == false then raining = value end
    end
    if raining == nil and precipitation ~= nil then
        raining = precipitation > 0
    end

    local fogIntensity = firstNumber(climate, {
        "getFogIntensity",
    })
    if fogIntensity == nil and isCharacterArgument(player) then
        local ok, value = call1(climate, "getFogIntensityForCharacter", player)
        if ok then fogIntensity = tonumber(value) end
    end
    local foggy = firstBoolean(climate, { "isFoggy" })
    if foggy == nil then
        local value = readMember(climate, "isFoggy")
        if value == true or value == false then foggy = value end
    end
    if foggy == nil and fogIntensity ~= nil then foggy = fogIntensity > 0.10 end

    local rainIntensity = firstNumber(climate, { "getRainIntensity" })
    local snowIntensity = firstNumber(climate, { "getSnowIntensity" })
    local snowing = firstBoolean(climate, { "isSnowing" })
    if snowing == nil then
        snowing = firstBoolean(climate, { "getPrecipitationIsSnow" })
    end
    if snowing == nil and snowIntensity ~= nil then
        snowing = snowIntensity > 0
    end

    local temperature = nil
    if isCharacterArgument(player) then
        local ok, value = call2(
            climate, "getAirTemperatureForCharacter", player, false
        )
        if ok then temperature = tonumber(value) end
    end
    temperature = temperature or firstNumber(climate, {
        "getTemperature",
        "getAirTemperature",
    })

    return {
        source = climate and "climate_manager" or "unavailable",
        precipitationIntensity = precipitation,
        raining = raining,
        rainIntensity = rainIntensity,
        snowing = snowing,
        snowIntensity = snowIntensity,
        fogIntensity = fogIntensity,
        foggy = foggy,
        temperatureC = temperature,
        windIntensity = firstNumber(climate, {
            "getWindIntensity", "getWindPower",
        }),
        cloudIntensity = readNumber(climate, "getCloudIntensity"),
        humidity = readNumber(climate, "getHumidity"),
        season = readString(climate, "getSeasonName"),
    }
end

local function positionSnapshot(player)
    if player == nil then return nil end
    local x = readNumber(player, "getX")
    local y = readNumber(player, "getY")
    local z = readNumber(player, "getZ")
    if x == nil and y == nil and z == nil then return nil end
    return { x = x, y = y, z = z }
end

local function build(options, sampledAt)
    local player = localPlayer(options)
    local gameTime = globalObject(getGameTime)
    local worldAgeHours = readNumber(gameTime, "getWorldAgeHours") or 0
    local climate = globalObject(getClimateManager)
    local indoors = firstBoolean(player, { "isInARoom", "isInside" })
    local snapshotTime = timeSnapshot(gameTime, worldAgeHours)
    local snapshot = {
        schemaVersion = World.VERSION,
        kind = "world_context",
        sampledAt = sampledAt,
        time = snapshotTime,
        worldAgeHours = snapshotTime.worldAgeHours,
        gameDay = snapshotTime.gameDay,
        timeOfDay = snapshotTime.timeOfDay,
        timeBand = snapshotTime.band,
        calendar = snapshotTime.calendar,
        weather = weatherSnapshot(climate, player),
        environment = {
            indoors = indoors,
            position = positionSnapshot(player),
            observationScope = "client_local",
        },
    }
    return snapshot
end

function World.Get(options)
    options = type(options) == "table" and options or {}
    local sampledAt = nowMillis(options)
    local player = localPlayer(options)
    local key = options.cacheKey or player or DEFAULT_CACHE_KEY
    local entry = cache[key]
    local ttl = math.max(
        0,
        tonumber(options.ttlMs) or World.DEFAULT_TTL_MS
    )
    if not options.force and entry
        and sampledAt >= entry.sampledAt
        and sampledAt - entry.sampledAt <= ttl
    then
        return entry.snapshot
    end
    local snapshot = build(options, sampledAt)
    cache[key] = { sampledAt = sampledAt, snapshot = snapshot }
    return snapshot
end

function World.Sample(options)
    options = type(options) == "table" and options or {}
    options.force = true
    return World.Get(options)
end

function World.Clear()
    cache = {}
    return true
end

World.Internal.Call0 = call0
World.Internal.Call1 = call1
World.Internal.Call2 = call2
World.Internal.Build = build

return World
