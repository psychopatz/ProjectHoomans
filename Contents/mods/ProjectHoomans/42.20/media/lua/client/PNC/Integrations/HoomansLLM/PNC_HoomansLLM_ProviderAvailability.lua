-- Small, fail-closed reader for the optional pbrainz worker heartbeat.
--
-- BridgeBootstrap only tells the game that the Core file bridge is enabled;
-- it cannot tell us whether the external worker is still running.  This
-- presence document is therefore deliberately separate from request state.
require "PsychopatzCore/Serialization/PsychopatzJson"

PNC = PNC or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}
PNC.HoomansLLM.Internal = PNC.HoomansLLM.Internal or {}

local Availability = PNC.HoomansLLM.Internal.ProviderAvailability or {}
PNC.HoomansLLM.Internal.ProviderAvailability = Availability

local Json = require "PsychopatzCore/Serialization/PsychopatzJson"

Availability.VERSION = 1
Availability.STATE_PATH = "PsychopatzBridge/state/provider_state.json"
Availability.READY_PATH = "PsychopatzBridge/state/provider_state.ready.txt"
Availability.MAX_STATE_BYTES = 8192
Availability.MAX_MARKER_BYTES = 128
Availability.MAX_AGE_MS = 4000
Availability.MAX_CLOCK_SKEW_MS = 10000

local function trim(value)
    value = tostring(value or "")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    return value
end

local function readFile(path, maximum)
    if type(getFileReader) ~= "function" then
        return nil, "file_reader_unavailable"
    end
    local reader = getFileReader(path, false)
    if not reader then return nil, "file_unavailable" end
    local parts, size = {}, 0
    local line = reader:readLine()
    while line do
        size = size + #line + 1
        if size > maximum then
            reader:close()
            return nil, "size_limit"
        end
        parts[#parts + 1] = line
        line = reader:readLine()
    end
    reader:close()
    return table.concat(parts, "\n")
end

local function safeRead(path, maximum)
    local ok, value, reason = pcall(readFile, path, maximum)
    if not ok then return nil, "read_error" end
    return value, reason
end

local function runtimeID(options)
    local explicit = trim(options and options.runtimeID)
    if explicit ~= "" then return explicit end
    local bridge = PsychopatzCore and PsychopatzCore.Bridge
    if not bridge or type(bridge.GetRuntimeInfo) ~= "function" then
        return nil
    end
    local ok, info = pcall(bridge.GetRuntimeInfo)
    if not ok or type(info) ~= "table" then return nil end
    local value = trim(info.runtime_id)
    return value ~= "" and value or nil
end

local function unavailable(result, reason)
    result.ready = false
    result.reason = reason or "provider_unavailable"
    return result
end

function Availability.Read(options)
    options = type(options) == "table" and options or {}
    local result = {
        source = "pbrainz_provider_presence",
        available = false,
        ready = false,
        status = "unavailable",
    }
    local text, readReason = safeRead(
        options.statePath or Availability.STATE_PATH,
        Availability.MAX_STATE_BYTES
    )
    if not text then return unavailable(result, readReason) end

    local payload, decodeReason = Json.Decode(text, {
        maxString = Availability.MAX_STATE_BYTES,
        maxDepth = 8,
        maxCollection = 32,
    })
    if type(payload) ~= "table" then
        return unavailable(result, decodeReason or "invalid_state")
    end

    local reportedRuntime = trim(payload.runtime_id)
    if reportedRuntime == "" then
        return unavailable(result, "runtime_id_missing")
    end
    result.runtimeID = reportedRuntime
    result.provider = trim(payload.provider)
    result.model = trim(payload.model)
    result.status = trim(payload.status)

    local marker, markerReason = safeRead(
        options.readyPath or Availability.READY_PATH,
        Availability.MAX_MARKER_BYTES
    )
    if not marker then return unavailable(result, markerReason or "marker_missing") end
    if trim(marker) ~= reportedRuntime then
        return unavailable(result, "marker_mismatch")
    end

    local expectedRuntime = runtimeID(options)
    if not expectedRuntime then
        return unavailable(result, "bridge_runtime_unavailable")
    end
    if expectedRuntime ~= reportedRuntime then
        return unavailable(result, "stale_runtime")
    end

    local heartbeat = tonumber(payload.heartbeat_ms)
    if not heartbeat then return unavailable(result, "heartbeat_missing") end
    local now = tonumber(options.now)
        or (getTimeInMillis and getTimeInMillis())
        or 0
    if now <= 0 then return unavailable(result, "clock_unavailable") end
    local age = now - heartbeat
    result.heartbeatAt = heartbeat
    result.ageMs = age
    if age < -Availability.MAX_CLOCK_SKEW_MS then
        return unavailable(result, "heartbeat_clock_skew")
    end
    if age > Availability.MAX_AGE_MS then
        return unavailable(result, "heartbeat_stale")
    end

    result.available = true
    if result.status ~= "ready" or payload.ready ~= true then
        return unavailable(result, "provider_not_ready")
    end
    result.ready = true
    result.reason = nil
    return result
end

function Availability.IsReady(options)
    return Availability.Read(options).ready == true
end

return Availability
