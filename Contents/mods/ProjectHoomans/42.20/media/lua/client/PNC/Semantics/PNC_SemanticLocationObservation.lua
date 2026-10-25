-- Bounded client observation for location-aware semantic conversation.
--
-- This is an observation seam, not a map authority. It may inspect the
-- loaded client cell through existing domain adapters, but it returns only
-- primitive observations. Server-side CampSite resolution and every actual
-- gameplay mutation remain authoritative elsewhere.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Observation = PNC.Semantics.LocationObservation or {}
PNC.Semantics.LocationObservation = Observation
local CampSiteHints = PNC.Semantics.ClientCampSiteHints
    or require "PNC/Semantics/PNC_SemanticCampSiteHints"

Observation.VERSION = 1
Observation.CACHE_MS = 750
Observation.MAX_CAMP_SITES = 8
Observation.Cache = Observation.Cache or {}

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function nowMs()
    if type(getTimestampMs) == "function" then
        local value = number(getTimestampMs())
        if value ~= nil then return value end
    end
    if type(getTimeInMillis) == "function" then
        local value = number(getTimeInMillis())
        if value ~= nil then return value end
    end
    return 0
end

local function call(object, method)
    local ok, fn = pcall(function() return object and object[method] end)
    if not ok then return nil end
    if type(fn) ~= "function" then return nil end
    local called, value = pcall(fn, object)
    return called and number(value) or nil
end

local function primitive(value, depth)
    if type(value) ~= "table" then
        if type(value) == "string" or type(value) == "number"
            or type(value) == "boolean"
        then
            return value
        end
        return nil
    end
    depth = tonumber(depth) or 0
    if depth >= 4 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 32 then break end
        if type(key) == "string" or type(key) == "number" then
            local copied = primitive(item, depth + 1)
            if copied ~= nil then
                output[key] = copied
                count = count + 1
            end
        end
    end
    return output
end

local function list(value, maximum)
    if type(value) ~= "table" then return {} end
    local output = {}
    maximum = math.max(0, tonumber(maximum) or Observation.MAX_CAMP_SITES)
    for index = 1, math.min(#value, maximum) do
        local copied = primitive(value[index])
        if type(copied) == "table" then output[#output + 1] = copied end
    end
    return output
end

local function position(origin)
    if type(origin) == "table" and origin.x ~= nil then
        return {
            x = number(origin.x), y = number(origin.y), z = number(origin.z) or 0,
        }
    end
    local x = call(origin, "getX")
    local y = call(origin, "getY")
    local z = call(origin, "getZ")
    if x == nil and y == nil and z == nil then return nil end
    return { x = x, y = y, z = z or 0 }
end

local function originFor(context)
    return context.selectionOrigin or context.origin or context.player
        or (type(getSpecificPlayer) == "function"
            and getSpecificPlayer(0) or nil)
end

local function cellFor(context)
    if context.cell then return context.cell end
    return type(getCell) == "function" and getCell() or nil
end

local function explicitObservation(context)
    local value = context.locationObservation
    if type(value) ~= "table" then return nil end
    -- Headless tests may provide the same compact primitive contract as a
    -- fixture. A production observation is deliberately not treated as a
    -- durable cache: the loaded cell and current room can change while the
    -- conversation remains open, so it must be re-observed through the
    -- client adapter and its bounded TTL cache.
    local source = tostring(value.source or "")
    if source ~= "harness_fixture" and source ~= "semantic_fixture" then
        return nil
    end
    local output = primitive(value)
    if type(output) ~= "table" then return nil end
    output.schemaVersion = Observation.VERSION
    output.kind = "semantic_location_observation"
    output.campSiteCandidates = list(
        value.campSiteCandidates or value.campSites,
        Observation.MAX_CAMP_SITES
    )
    return output
end

local function cacheKey(origin, cell, options)
    local at = position(origin) or {}
    return tostring(math.floor(at.x or 0)) .. ":"
        .. tostring(math.floor(at.y or 0)) .. ":"
        .. tostring(at.z or 0) .. "|" .. tostring(cell)
        .. "|" .. tostring(options.maxCampSites or Observation.MAX_CAMP_SITES)
end

function Observation.ClearCache()
    Observation.Cache = {}
end

-- Return one compact, player-local observation. Engine objects are used only
-- during the adapter call and never cross this boundary or enter persistence.
function Observation.Observe(context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}

    local explicit = explicitObservation(context)
    if explicit then
        explicit.observedAt = number(explicit.observedAt) or nowMs()
        return explicit, "explicit_observation"
    end

    local origin = originFor(context)
    local cell = cellFor(context)
    local timestamp = nowMs()
    local maximum = math.max(1, math.min(
        Observation.MAX_CAMP_SITES,
        tonumber(options.maxCampSites) or Observation.MAX_CAMP_SITES
    ))
    local key = cacheKey(origin, cell, { maxCampSites = maximum })
    local cached = Observation.Cache[key]
    if cached and timestamp - cached.at <= Observation.CACHE_MS then
        return cached.value, "cached_client_observation"
    end

    local prior = context.locationObservation
    local priorSource = type(prior) == "table"
        and tostring(prior.source or "") or ""
    local priorWasClientObservation = priorSource == "client_loaded_cell"
        or priorSource == "unavailable"
    local candidates = list(
        priorWasClientObservation and nil or context.campSiteCandidates,
        maximum
    )
    local campfireCandidates = list(
        priorWasClientObservation and nil or context.campfireCandidates,
        maximum
    )
    if #candidates == 0 and #campfireCandidates == 0
        and type(CampSiteHints) == "table"
        and type(CampSiteHints.Enumerate) == "function"
    then
        local discovered = CampSiteHints.Enumerate({
            player = origin,
            origin = origin,
            selectionOrigin = origin,
            cell = cell,
        }, {
            maxRooms = maximum,
            maxBuildings = options.maxBuildings or 16,
        })
        candidates = list(discovered, maximum)
    end
    for index = 1, #campfireCandidates do
        if #candidates >= maximum then break end
        candidates[#candidates + 1] = campfireCandidates[index]
    end

    local value = {
        schemaVersion = Observation.VERSION,
        kind = "semantic_location_observation",
        source = cell and "client_loaded_cell" or "unavailable",
        scope = "client_local",
        observedAt = timestamp,
        origin = position(origin),
        campSiteCandidates = candidates,
    }
    Observation.Cache[key] = { at = timestamp, value = value }
    return value, #candidates > 0 and "client_observation" or "no_loaded_location"
end

return Observation
