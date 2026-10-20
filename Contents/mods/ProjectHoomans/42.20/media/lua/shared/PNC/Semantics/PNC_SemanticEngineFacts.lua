-- Typed, read-only engine observations exposed to semantic dialogue.
--
-- This catalog is intentionally separate from the generic dialogue fact
-- registry. It owns names, types, units, and authority metadata while the
-- generic registry still owns provider ordering, safe-copying, and failure
-- containment. Engine adapters publish observations; they never execute a
-- command through this module.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Facts = PNC.Semantics.DialogueFacts
    or require "PNC/Semantics/PNC_SemanticDialogueFacts"
local EngineFacts = PNC.Semantics.EngineFacts or {}
PNC.Semantics.EngineFacts = EngineFacts

EngineFacts.VERSION = 1
EngineFacts.CATALOG = EngineFacts.CATALOG or {
    {
        id = "world.time.world_age_hours",
        type = "number",
        unit = "hours",
        scope = "world",
        authority = "engine",
        description = "World age in simulation hours.",
    },
    {
        id = "world.time.game_day",
        type = "number",
        unit = "day",
        scope = "world",
        authority = "engine",
        description = "Zero-based elapsed simulation day.",
    },
    {
        id = "world.time.week",
        type = "number",
        unit = "week",
        scope = "world",
        authority = "derived",
        description = "One-based elapsed simulation week.",
    },
    {
        id = "world.time.hour",
        type = "number",
        unit = "hour",
        scope = "world",
        authority = "engine",
        description = "Current local simulation hour.",
    },
    {
        id = "world.time.time_band",
        type = "string",
        unit = "label",
        scope = "world",
        authority = "semantic",
        description = "Configured semantic time-of-day band.",
    },
    {
        id = "world.calendar.year",
        type = "number",
        unit = "year",
        scope = "world",
        authority = "engine",
        description = "Calendar year.",
    },
    {
        id = "world.calendar.month",
        type = "number",
        unit = "month",
        scope = "world",
        authority = "engine",
        description = "One-based calendar month.",
    },
    {
        id = "world.calendar.day",
        type = "number",
        unit = "day",
        scope = "world",
        authority = "engine",
        description = "One-based calendar day.",
    },
    {
        id = "world.weather.raining",
        type = "boolean",
        unit = "flag",
        scope = "world",
        authority = "engine",
        description = "Whether the observed climate is raining.",
    },
    {
        id = "world.weather.foggy",
        type = "boolean",
        unit = "flag",
        scope = "world",
        authority = "engine",
        description = "Whether the observed climate is foggy.",
    },
    {
        id = "world.weather.snowing",
        type = "boolean",
        unit = "flag",
        scope = "world",
        authority = "engine",
        description = "Whether the observed climate is snowing.",
    },
    {
        id = "world.weather.temperature_c",
        type = "number",
        unit = "celsius",
        scope = "world",
        authority = "engine",
        description = "Observed air temperature in Celsius.",
    },
    {
        id = "world.weather.transition",
        type = "string",
        unit = "transition",
        scope = "world",
        authority = "derived",
        description = "Last observed weather transition, such as clear->rain.",
    },
    {
        id = "player.stats.zombie_kills",
        type = "number",
        unit = "count",
        scope = "player",
        authority = "engine",
        description = "Native player zombie-kill counter.",
    },
}

local byID = {}
local index
for index = 1, #EngineFacts.CATALOG do
    local definition = EngineFacts.CATALOG[index]
    byID[definition.id] = definition
end

local function finite(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function readPath(root, path)
    local current = root
    local part
    if type(path) ~= "string" then return nil end
    for part in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[part]
    end
    return current
end

local function call0(object, method)
    if object == nil then return nil end
    local ok, fn = pcall(function() return object[method] end)
    local value
    if not ok or type(fn) ~= "function" then return nil end
    ok, value = pcall(function() return fn(object) end)
    return ok and value or nil
end

local function worldValue(context, path)
    local world = context and context.worldContext or nil
    if path == "world_age_hours" then return world and world.worldAgeHours end
    if path == "game_day" then return world and world.gameDay end
    if path == "week" then return world and world.week end
    if path == "hour" then
        return world and (world.hour or world.time and world.time.hour)
    end
    local value = readPath(world, path)
    if value ~= nil then return value end
    if path == "time_band" then return world and world.timeBand end
    if path == "temperature_c" then
        return world and world.weather and world.weather.temperatureC
    end
    if path == "transition" then
        return world and world.weather and world.weather.transition
    end
    return nil
end

local function playerZombieKills(context)
    local overrides = context and context.engineFacts or nil
    local value = type(overrides) == "table"
        and overrides["player.stats.zombie_kills"] or nil
    if type(value) == "table" then value = value.value end
    if value ~= nil then return finite(value) end
    local player = context and context.player
    value = call0(player, "getZombieKills")
    return finite(value)
end

local function resolveEngineValue(subject, context)
    if string.sub(subject, 1, 11) == "world.time." then
        return worldValue(context, string.sub(subject, 12))
    end
    if string.sub(subject, 1, 15) == "world.calendar." then
        return worldValue(context, "calendar." .. string.sub(subject, 16))
    end
    if string.sub(subject, 1, 14) == "world.weather." then
        return worldValue(context, "weather." .. string.sub(subject, 15))
    end
    if subject == "player.stats.zombie_kills" then
        return playerZombieKills(context)
    end
    return nil
end

local function normalizeBoolean(value)
    if value == true or value == false then return value end
    local text = string.lower(tostring(value or ""))
    if text == "true" or text == "1" or text == "yes" then return true end
    if text == "false" or text == "0" or text == "no" then return false end
    return nil
end

local function typedValue(definition, value)
    if not definition or value == nil then return nil end
    if definition.type == "number" then return finite(value) end
    if definition.type == "boolean" then return normalizeBoolean(value) end
    value = tostring(value or "")
    return value ~= "" and value or nil
end

Facts.RegisterProvider("engine_context", {
    priority = 100,
    Resolve = function(ir, state, context)
        local subject = tostring(ir and ir.subject or "")
        local definition = byID[subject]
        local value
        if not definition then return nil, "engine_fact_unregistered" end
        value = typedValue(definition, resolveEngineValue(subject, context))
        if value == nil then return nil, "engine_fact_unavailable" end
        return {
            status = "known",
            value = value,
            type = definition.type,
            unit = definition.unit,
            scope = definition.scope,
            authority = definition.authority,
        }
    end,
})

function EngineFacts.Get(factID)
    return byID[tostring(factID or "")]
end

function EngineFacts.List()
    local output = {}
    for index = 1, #EngineFacts.CATALOG do
        local definition = EngineFacts.CATALOG[index]
        output[index] = {
            id = definition.id,
            type = definition.type,
            unit = definition.unit,
            scope = definition.scope,
            authority = definition.authority,
            description = definition.description,
        }
    end
    return output
end

function EngineFacts.Resolve(factID, context, state)
    local subject = tostring(factID or "")
    if not byID[subject] then
        return {
            subject = subject,
            status = "unknown",
            reason = "engine_fact_unregistered",
        }
    end
    return Facts.Resolve({ subject = subject }, state, context)
end

function EngineFacts.Compare(record, operator, expected)
    local actual
    local typedExpected
    local definition
    operator = operator or "=="
    if type(record) ~= "table" or record.status ~= "known" then return nil end
    definition = byID[record.subject]
    actual = record.value
    typedExpected = typedValue(definition, expected)
    if actual == nil or typedExpected == nil then return false end
    if definition.type == "string" then
        actual = tostring(actual)
        typedExpected = tostring(typedExpected)
        if operator == "contains" then
            return string.find(actual, typedExpected, 1, true) ~= nil
        end
    end
    if operator == "==" then return actual == typedExpected end
    if operator == "~=" then return actual ~= typedExpected end
    actual = tonumber(actual)
    typedExpected = tonumber(typedExpected)
    if actual == nil or typedExpected == nil then return false end
    if operator == ">=" then return actual >= typedExpected end
    if operator == "<=" then return actual <= typedExpected end
    if operator == ">" then return actual > typedExpected end
    if operator == "<" then return actual < typedExpected end
    return false
end

return EngineFacts
