-- Cached, client-observed world context for semantic conversation.
--
-- This module only observes the local simulation. It never mutates world
-- state, starts tasks, or decides whether an action is authoritative. The
-- snapshot is intentionally small and cached because it is consumed by both
-- local routing and optional LLM context assembly.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
require "PNC/Semantics/PNC_SemanticWorldContext_Environment"

local World = PNC.Semantics.WorldContext or {}
PNC.Semantics.WorldContext = World
local Environment = PNC.Semantics.WorldContextEnvironment

World.VERSION = 1
World.DEFAULT_TTL_MS = 1000
World.Internal = World.Internal or {}
local cache = {}
local timeBandResolver = nil
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

local environmentReaders = {
    call1 = call1,
    call2 = call2,
    firstBoolean = firstBoolean,
    firstNumber = firstNumber,
    isCharacterArgument = isCharacterArgument,
    readBoolean = readBoolean,
    readMember = readMember,
    readNumber = readNumber,
    readString = readString,
}

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
    local snapshotTime = Environment.TimeSnapshot(
        gameTime, worldAgeHours, timeBandResolver, environmentReaders)
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
        weather = Environment.WeatherSnapshot(
            climate, player, environmentReaders),
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

function World.SetTimeBandResolver(resolver)
    timeBandResolver = type(resolver) == "function" and resolver or nil
    World.Clear()
    return timeBandResolver ~= nil
end

World.Internal.Call0 = call0
World.Internal.Call1 = call1
World.Internal.Call2 = call2
World.Internal.Build = build

return World
