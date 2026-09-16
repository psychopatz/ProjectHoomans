-- Bounded diagnostics for the semantic dialogue pipeline.
--
-- This module is deliberately independent from the parser, dialogue policy,
-- networking, and task providers.  It is a diagnostic sink, not a second
-- semantic service.  When disabled, Record returns before inspecting or
-- copying the payload supplied by a hot-path caller.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Diagnostics = PNC.Semantics.SemanticDiagnostics or {}
PNC.Semantics.SemanticDiagnostics = Diagnostics

local SETTING_ID = "ProjectHoomans.SemanticDialogueAudit"
local SOURCE = "ProjectHoomans.Semantics"
local MAX_STRING = 256
local MAX_DEPTH = 4
local MAX_KEYS = 32
local MAX_CONSOLE_VALUE = 512

Diagnostics.VERSION = 1
Diagnostics.SETTING_ID = SETTING_ID
Diagnostics.Enabled = Diagnostics.Enabled == true
Diagnostics.ConsoleDedupe = Diagnostics.ConsoleDedupe or {}
Diagnostics.SettingRegistered = Diagnostics.SettingRegistered == true

local function bounded(value, maximum)
    local output = tostring(value or "")
    maximum = tonumber(maximum) or MAX_STRING
    if #output <= maximum then return output end
    return string.sub(output, 1, maximum - 3) .. "..."
end

local function now()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        local ok, value = pcall(PNC.Core.Now)
        if ok and tonumber(value) then return tonumber(value) end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and tonumber(value) then return tonumber(value) end
    end
    return 0
end

local function sortedKeys(value)
    local keys = {}
    for key in pairs(value or {}) do
        keys[#keys + 1] = tostring(key)
    end
    table.sort(keys)
    return keys
end

-- Only primitive values and bounded tables are retained.  Java objects,
-- functions, threads, and userdata are represented by their type rather than
-- being retained or traversed by the diagnostic buffer.
local function sanitize(value, depth, seen)
    local valueType = type(value)
    if value == nil or valueType == "boolean" or valueType == "number" then
        return value
    end
    if valueType == "string" then
        return bounded(value, MAX_STRING)
    end
    if valueType ~= "table" then
        return "[omitted:" .. valueType .. "]"
    end
    depth = tonumber(depth) or 0
    if depth >= MAX_DEPTH then return "[depth-limit]" end
    seen = seen or {}
    if seen[value] then return "[cycle]" end

    seen[value] = true
    local output = {}
    local keys = sortedKeys(value)
    for index = 1, math.min(#keys, MAX_KEYS) do
        local key = keys[index]
        local original
        for candidate, _ in pairs(value) do
            if tostring(candidate) == key then
                original = candidate
                break
            end
        end
        output[key] = sanitize(value[original], depth + 1, seen)
    end
    if #keys > MAX_KEYS then output["[truncated]"] = "32+ entries" end
    seen[value] = nil
    return output
end

local function quote(value)
    value = bounded(value, MAX_CONSOLE_VALUE)
    value = string.gsub(value, "[\r\n]", " ")
    value = string.gsub(value, '"', "'")
    return '"' .. value .. '"'
end

local function compact(value, depth)
    local valueType = type(value)
    if value == nil then return "null" end
    if valueType == "string" then return quote(value) end
    if valueType == "boolean" then return value and "true" or "false" end
    if valueType == "number" then return tostring(value) end
    if valueType ~= "table" then return quote(valueType) end
    depth = tonumber(depth) or 0
    if depth >= 2 then return quote("depth-limit") end

    local keys = sortedKeys(value)
    local fields = {}
    for index = 1, math.min(#keys, 16) do
        local key = keys[index]
        local original
        for candidate, _ in pairs(value) do
            if tostring(candidate) == key then
                original = candidate
                break
            end
        end
        fields[#fields + 1] = key .. "=" .. compact(value[original], depth + 1)
    end
    if #keys > 16 then fields[#fields + 1] = "truncated=16+" end
    return "{" .. table.concat(fields, ",") .. "}"
end

local function settingObject()
    local settings = PsychopatzCore and PsychopatzCore.DebugSettings
    if settings and type(settings.Register) == "function" then
        return settings
    end
    if type(require) == "function" then
        pcall(require, "PsychopatzCore/Debug/PsychopatzDebugSettings")
    end
    return PsychopatzCore and PsychopatzCore.DebugSettings or nil
end

function Diagnostics.IsEnabled()
    return Diagnostics.Enabled == true
end

function Diagnostics.SetEnabled(enabled)
    Diagnostics.Enabled = enabled == true
    if not Diagnostics.Enabled then Diagnostics.ConsoleDedupe = {} end
    return Diagnostics.Enabled
end

local function consoleAllowed(eventName, data, options)
    options = type(options) == "table" and options or {}
    if options.console == false then return false end

    local dedupeKey = options.dedupeKey
    if dedupeKey == nil then
        dedupeKey = tostring(eventName or "event") .. "|"
            .. tostring(options.requestID or data and data.requestID or "")
    end
    dedupeKey = tostring(dedupeKey)
    local interval = math.max(0, tonumber(options.consoleIntervalMs) or 0)
    if interval <= 0 then return true end

    local at = now()
    local previous = Diagnostics.ConsoleDedupe[dedupeKey]
    if previous and at - previous < interval then return false end
    Diagnostics.ConsoleDedupe[dedupeKey] = at
    return true
end

local function logConsole(eventName, requestID, data, options)
    if not consoleAllowed(eventName, data, options) then return false end
    local fields = {
        "semantic_audit",
        "event=" .. bounded(eventName or "event", 96),
    }
    requestID = tostring(requestID or "")
    if requestID ~= "" then
        fields[#fields + 1] = "requestID=" .. quote(requestID)
    end
    for _, key in ipairs(sortedKeys(data)) do
        fields[#fields + 1] = key .. "=" .. compact(data[key], 0)
    end
    local message = table.concat(fields, " ")
    if PNC.Core and type(PNC.Core.LogInfo) == "function" then
        PNC.Core.LogInfo(message)
    elseif type(print) == "function" then
        print("[PNC][INFO] " .. message)
    end
    return true
end

function Diagnostics.Record(eventName, data, options)
    -- Keep this as the first meaningful operation.  Callers can pass live
    -- tables from the game; disabled diagnostics must not inspect them.
    if not Diagnostics.IsEnabled() then return false end

    eventName = bounded(eventName or "event", 160)
    options = type(options) == "table" and options or {}
    data = sanitize(type(data) == "table" and data or {}, 0, {})
    local requestID = options.requestID or data.requestID
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    if trace and type(trace.Record) == "function" then
        trace.Record({
            source = SOURCE,
            event = eventName,
            requestID = requestID,
            data = data,
        })
    end
    logConsole(eventName, requestID, data, options)
    return true
end

local function registerSetting()
    local settings = settingObject()
    if not settings or type(settings.Register) ~= "function" then
        return false
    end
    settings.Register({
        id = SETTING_ID,
        source = "Project Hoomans",
        order = 140,
        title = "Semantic dialogue audit",
        description = "Logs local NLU, MarketSense queries, task plans, world targets, and semantic responses.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SetEnabled(enabled)
        end,
    })
    Diagnostics.SettingRegistered = true
    if type(settings.IsEnabled) == "function" then
        Diagnostics.SetEnabled(settings.IsEnabled(SETTING_ID) == true)
    end
    return true
end

registerSetting()

return Diagnostics
