-- Bounded structured logging for the server-authoritative Population Director.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.PopulationLog = PNC.PopulationLog or {}

local Log = PNC.PopulationLog
local Core = PNC.Core
local Config = PNC.DirectorConfig.Population

Log.Entries = Log.Entries or {}

local function worldAge()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

local function safeValue(value)
    if type(value) == "boolean" then return value and "true" or "false" end
    if type(value) ~= "number" and type(value) ~= "string" then return nil end
    local output = tostring(value)
    output = string.gsub(output, "[%c%s]+", "_")
    return string.sub(output, 1, 160)
end

local function copyFields(fields)
    local output = {}
    for key, value in pairs(type(fields) == "table" and fields or {}) do
        local safe = safeValue(value)
        if safe ~= nil then output[tostring(key)] = safe end
    end
    return output
end

function Log.Write(level, eventName, fields)
    level = string.upper(tostring(level or "INFO"))
    local entry = {
        at = worldAge(),
        level = level,
        event = string.upper(tostring(eventName or "POPULATION_EVENT")),
        fields = copyFields(fields),
    }
    Log.Entries[#Log.Entries + 1] = entry
    while #Log.Entries > (Config.DIRECTOR_LOG_HISTORY_LIMIT or 160) do
        table.remove(Log.Entries, 1)
    end

    local keys = {}
    for key in pairs(entry.fields) do keys[#keys + 1] = key end
    table.sort(keys)
    local parts = { "[PopulationDirector]", "event=" .. entry.event,
        "worldHour=" .. string.format("%.3f", entry.at) }
    for _, key in ipairs(keys) do
        parts[#parts + 1] = key .. "=" .. entry.fields[key]
    end
    local message = table.concat(parts, " ")
    if level == "WARN" and Core and Core.LogWarn then
        Core.LogWarn(message)
    elseif Core and Core.LogInfo then
        Core.LogInfo(message)
    elseif print then
        print("[PNC][" .. level .. "] " .. message)
    end
    return entry
end

function Log.Info(eventName, fields)
    return Log.Write("INFO", eventName, fields)
end

function Log.Warn(eventName, fields)
    return Log.Write("WARN", eventName, fields)
end

function Log.GetEntries()
    return Core and Core.DeepCopy and Core.DeepCopy(Log.Entries) or Log.Entries
end

function Log.Clear()
    Log.Entries = {}
end

return Log
