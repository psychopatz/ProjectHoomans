-- Bounded, runtime-only faction diagnostics. This module never writes
-- ModData and accepts no live engine values into its buffer.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.FactionTelemetry = PNC.FactionTelemetry or {}

local Telemetry = PNC.FactionTelemetry
local Balance = PNC.FactionBalance
local Core = PNC.Core

Telemetry.Entries = Telemetry.Entries or {}
Telemetry.Sequence = tonumber(Telemetry.Sequence) or 0

local Flags = {
    callback = "DebugDiplomacyCallbacks",
    attribution = "DebugDiplomacyCallbacks",
    aggregation = "DebugIncidentAggregation",
    incident = "EnableValidationTelemetry",
    escalation = "EnableValidationTelemetry",
    intent = "DebugIntentResolution",
    treaty_reconciliation = "DebugTreatyReconciliation",
    validation = "EnableValidationTelemetry",
}

local function enabled(category)
    local config = PNC.Config and PNC.Config.Factions or {}
    return config.EnableValidationTelemetry == true
        or config[Flags[category]] == true
end

local function anyEnabled()
    local config = PNC.Config and PNC.Config.Factions or {}
    return config.EnableValidationTelemetry == true
        or config.DebugDiplomacyCallbacks == true
        or config.DebugIncidentAggregation == true
        or config.DebugIntentResolution == true
        or config.DebugTreatyReconciliation == true
end

local function scalar(value)
    local kind = type(value)
    if kind == "string" then
        return string.sub(value, 1, 512)
    end
    if kind == "number" then
        if value == value and value ~= math.huge
            and value ~= -math.huge
        then
            return value
        end
        return nil
    end
    if kind == "boolean" then return value end
    return nil
end

local function sanitize(value, depth, budget)
    local simple = scalar(value)
    if simple ~= nil then return simple, budget end
    if type(value) ~= "table" or depth >= 4 or budget <= 0 then
        return nil, budget
    end
    local output = {}
    local count = 0
    for key, child in pairs(value) do
        local safeKey = scalar(key)
        if safeKey ~= nil and count < 64 and budget > 0 then
            local safeChild
            safeChild, budget = sanitize(
                child, depth + 1, budget - 1
            )
            if safeChild ~= nil then
                output[safeKey] = safeChild
                count = count + 1
            end
        end
    end
    return output, budget
end

local function copy(value)
    local output = sanitize(value, 0, 512)
    return output
end

local function record(category, entry)
    if not enabled(category) then return false, "disabled" end
    local safe = copy(type(entry) == "table" and entry or {})
    Telemetry.Sequence = Telemetry.Sequence + 1
    safe.sequence = Telemetry.Sequence
    safe.category = category
    Telemetry.Entries[#Telemetry.Entries + 1] = safe
    local maximum = math.floor(
        Balance and Balance.Get("telemetryHistoryLimit") or 512
    )
    while #Telemetry.Entries > maximum do
        table.remove(Telemetry.Entries, 1)
    end
    return true, "recorded", copy(safe)
end

function Telemetry.RecordCallback(entry)
    return record("callback", entry)
end

function Telemetry.RecordAttribution(entry)
    return record("attribution", entry)
end

function Telemetry.RecordAggregation(entry)
    return record("aggregation", entry)
end

function Telemetry.RecordIncident(entry)
    return record("incident", entry)
end

function Telemetry.RecordEscalation(entry)
    return record("escalation", entry)
end

function Telemetry.RecordIntent(entry)
    return record("intent", entry)
end

function Telemetry.RecordTreatyReconciliation(entry)
    return record("treaty_reconciliation", entry)
end

function Telemetry.RecordValidation(entry)
    return record("validation", entry)
end

function Telemetry.GetRecent(maximum)
    maximum = math.max(
        0,
        math.floor(tonumber(maximum) or #Telemetry.Entries)
    )
    local output = {}
    local first = math.max(1, #Telemetry.Entries - maximum + 1)
    for index = first, #Telemetry.Entries do
        output[#output + 1] = copy(Telemetry.Entries[index])
    end
    return output
end

function Telemetry.Clear()
    if Core and Core.IsAuthority
        and Core.IsAuthority() ~= true
    then
        return false, "not_authority"
    end
    Telemetry.Entries = {}
    return true, "cleared"
end

function Telemetry.BuildSnapshot(filters)
    filters = type(filters) == "table" and filters or {}
    local output = {}
    local recent = Telemetry.GetRecent(filters.maximum or 128)
    for _, entry in ipairs(recent) do
        local categoryMatch = not filters.category
            or entry.category == filters.category
        local sourceMatch = not filters.sourceFactionID
            or entry.sourceFactionID == filters.sourceFactionID
        local targetMatch = not filters.targetFactionID
            or entry.targetFactionID == filters.targetFactionID
        if categoryMatch and sourceMatch and targetMatch then
            output[#output + 1] = entry
        end
    end
    return {
        enabled = anyEnabled(),
        count = #Telemetry.Entries,
        maximum = Balance and Balance.Get(
            "telemetryHistoryLimit"
        ) or 512,
        sequence = Telemetry.Sequence,
        entries = output,
    }
end

return Telemetry
