-- Bounded client observation cache for semantic world targets.
--
-- This module owns the expensive part of client-side target discovery:
-- reading metadata from objects in the currently loaded cell.  It stores only
-- primitive observations, never Java objects, so the matcher can reuse one
-- short-lived scan for several surface phrases without retaining live world
-- references or contacting the server.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Observer = PNC.Semantics.ClientWorldTargetObservationCache or {}
PNC.Semantics.ClientWorldTargetObservationCache = Observer

Observer.VERSION = 2
Observer.DEFAULT_CACHE_MS = 500
Observer.MAX_RADIUS = 24
-- The observer is intentionally bounded, but a square-distance scan that
-- starts in the far corner of the radius can spend the whole budget on
-- unrelated objects before it reaches the object the player is looking at.
-- Keep this high enough for a dense loaded cell while retaining a hard cap.
Observer.MAX_OBJECTS = 512
Observer.MAX_OBJECTS_HARD = 1024
-- Candidate filtering may skip hundreds of floor/wall entries before it
-- reaches a meaningful object. Keep that pre-filter pass bounded as well;
-- otherwise a debug refresh could trade the old false-positive flood for a
-- different unbounded metadata scan.
Observer.MAX_INSPECTED_OBJECTS = 4096
-- Campfires are GlobalObjects and must remain discoverable even when a dense
-- square exhausts the ordinary-object budget.  This separate cap keeps the
-- priority path bounded without allowing it to inflate into an unbounded scan.
Observer.MAX_SPECIAL_OBJECTS = 32
Observer.Cache = Observer.Cache or {}
local Scanner = PNC.Semantics.ClientWorldTargetObservationScanner
    or require "PNC/Semantics/PNC_SemanticWorldTargetObservationCache_Scanner"

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function objectBudget(value)
    return math.max(1, math.min(Observer.MAX_OBJECTS_HARD,
        math.floor(number(value) or Observer.MAX_OBJECTS)))
end

local function cacheKey(originX, originY, originZ, radius, maxObjects, cacheTag)
    return tostring(math.floor(originX)) .. ":"
        .. tostring(math.floor(originY)) .. ":"
        .. tostring(originZ) .. ":" .. tostring(radius) .. ":"
        .. tostring(maxObjects) .. ":" .. tostring(cacheTag or "plain")
end

function Observer.ClearCache()
    Observer.Cache = {}
end

function Observer.Invalidate(cell)
    if cell then
        Observer.Cache[cell] = nil
    else
        Observer.ClearCache()
    end
end

function Observer.Observe(cell, originX, originY, originZ, options)
    options = type(options) == "table" and options or {}
    originX = number(originX)
    originY = number(originY)
    originZ = number(originZ) or 0
    if not cell then return nil, { reason = "cell_unavailable" } end
    if originX == nil or originY == nil then
        return nil, { reason = "world_origin_unavailable" }
    end
    if type(cell.getGridSquare) ~= "function" then
        return nil, { reason = "cell_unavailable" }
    end

    local radius = math.max(1, math.min(Observer.MAX_RADIUS,
        math.floor(number(options.radius) or 16)))
    local maxObjects = objectBudget(options.maxObjects)
    local timestamp = number(options.nowMs) or 0
    local cacheMs = math.max(0, number(options.cacheMs)
        or Observer.DEFAULT_CACHE_MS)
    local bucket = Observer.Cache[cell]
    if not bucket then
        bucket = {}
        Observer.Cache[cell] = bucket
    end
    local key = cacheKey(originX, originY, originZ, radius, maxObjects,
        options.cacheTag)
    local cached = bucket[key]
    if cached and timestamp - cached.at <= cacheMs then
        return cached.observations, {
            objectCount = cached.objectCount,
            campfireCount = cached.campfireCount,
            truncated = cached.truncated,
            inspectedObjectCount = cached.inspectedObjectCount,
            rejectedObjectCount = cached.rejectedObjectCount,
            filterErrorCount = cached.filterErrorCount,
            inspectionTruncated = cached.inspectionTruncated,
            maxObjects = cached.maxObjects,
            cached = true,
        }
    end

    local observations, objectCount, truncated, campfireCount,
        inspectedObjectCount, rejectedObjectCount, filterErrorCount,
        inspectionTruncated = Scanner.Scan(Observer,
        cell, originX, originY, originZ, radius, maxObjects,
        options.decorate, options.filter or options.candidate,
        options.includeUnknown == true)
    bucket[key] = {
        at = timestamp,
        observations = observations,
        objectCount = objectCount,
        campfireCount = campfireCount,
        truncated = truncated,
        inspectedObjectCount = inspectedObjectCount,
        rejectedObjectCount = rejectedObjectCount,
        filterErrorCount = filterErrorCount,
        inspectionTruncated = inspectionTruncated,
        maxObjects = maxObjects,
    }
    return observations, {
        objectCount = objectCount,
        campfireCount = campfireCount,
        truncated = truncated,
        inspectedObjectCount = inspectedObjectCount,
        rejectedObjectCount = rejectedObjectCount,
        filterErrorCount = filterErrorCount,
        inspectionTruncated = inspectionTruncated,
        maxObjects = maxObjects,
        cached = false,
    }
end

-- Detailed observations use the same bounded scan and cache as semantic target
-- hints, but store provider facts alongside each primitive record. A distinct
-- cache tag prevents a plain hint lookup from satisfying a detailed debug
-- lookup with an undecorated snapshot.
function Observer.ObserveDetailed(cell, originX, originY, originZ, options)
    options = type(options) == "table" and options or {}
    local detailed = {}
    for key, value in pairs(options) do detailed[key] = value end
    detailed.cacheTag = detailed.cacheTag or "detailed"
    return Observer.Observe(cell, originX, originY, originZ, detailed)
end

return Observer
