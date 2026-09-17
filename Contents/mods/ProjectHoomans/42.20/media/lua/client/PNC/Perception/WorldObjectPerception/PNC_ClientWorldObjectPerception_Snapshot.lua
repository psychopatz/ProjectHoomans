-- Snapshot cache and public assembly for the client perception hub.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and PsychopatzCore.RuntimeRole.AllowsClientCode
    and not PsychopatzCore.RuntimeRole.AllowsClientCode()
then return end

local Perception = PNC.Perception.WorldObjects
local Internal = Perception.Internal
local ObservationCache = Internal.ObservationCache

local function number(value)
    return Internal.Number(value)
end

local function copyPrimitive(value)
    return Internal.CopyPrimitive(value)
end

local function snapshotKey(cell, originX, originY, originZ, radius, maxObjects,
    includeCampPreview)
    return tostring(cell) .. "|" .. tostring(math.floor(originX)) .. ":"
        .. tostring(math.floor(originY)) .. ":" .. tostring(originZ) .. "|"
        .. tostring(radius) .. ":" .. tostring(maxObjects) .. ":"
        .. tostring(includeCampPreview == true) .. "|v"
        .. tostring(Perception.ProviderVersion)
end

local function unavailable(reason, originX, originY, originZ, timestamp)
    local snapshot = {
        version = Perception.VERSION,
        status = "UNAVAILABLE",
        reason = reason,
        origin = originX and {
            x = originX, y = originY, z = originZ or 0,
        } or nil,
        objects = {},
        zones = {},
        diagnostics = {
            clientOnly = true,
            serverRequests = 0,
        },
        providers = Perception.ListProviders(),
        observedAt = timestamp,
    }
    return snapshot
end

function Perception.ClearSnapshotCache()
    Perception.SnapshotCache = {}
    if ObservationCache and ObservationCache.ClearCache then
        ObservationCache.ClearCache()
    end
end

function Perception.BuildSnapshot(options)
    options = type(options) == "table" and options or {}
    local origin = options.origin or Internal.CurrentPlayer()
    local originX, originY, originZ = Internal.Position(origin)
    local timestamp = number(options.nowMs) or Internal.NowMs()
    local radius = math.max(1, math.min(Perception.MAX_RADIUS,
        math.floor(number(options.radius) or Perception.DEFAULT_RADIUS)))
    local maxObjects = math.max(1, math.min(
        ObservationCache.MAX_OBJECTS_HARD or 1024,
        math.floor(number(options.maxObjects) or Perception.MAX_OBJECTS)))
    local cacheMs = math.max(0, number(options.cacheMs)
        or Perception.DEFAULT_CACHE_MS)
    local cell = options.cell or Internal.CurrentCell()
    if originX == nil or originY == nil then
        return unavailable("world_origin_unavailable", nil, nil, nil,
            timestamp)
    end
    if not cell then
        return unavailable("cell_unavailable", originX, originY, originZ,
            timestamp)
    end

    local includeCampPreview = options.skipCampPreview ~= true
    local key = snapshotKey(cell, originX, originY, originZ, radius,
        maxObjects, includeCampPreview)
    local cached = Perception.SnapshotCache[key]
    if cached and timestamp - cached.at <= cacheMs then
        cached.snapshot.diagnostics.snapshotCacheHit = true
        return cached.snapshot
    end

    local context = {
        origin = origin,
        originX = originX, originY = originY, originZ = originZ,
        roomCache = {},
    }
    local observations, scanStats = ObservationCache.ObserveDetailed(
        cell, originX, originY, originZ, {
            radius = radius,
            maxObjects = maxObjects,
            cacheMs = cacheMs,
            nowMs = timestamp,
            cacheTag = "perception:" .. tostring(Perception.ProviderVersion),
            decorate = function(object, square, record)
                return Internal.DescribeObject(object, square, record, context)
            end,
        })
    if not observations then
        return unavailable(scanStats and scanStats.reason
            or "observation_unavailable", originX, originY, originZ,
            timestamp)
    end

    local objects = {}
    for index = 1, #observations do
        local observation = observations[index]
        objects[#objects + 1] = {
            x = observation.x,
            y = observation.y,
            z = observation.z,
            objectIndex = observation.objectIndex,
            objectKey = observation.objectKey,
            targetID = observation.targetID,
            resourceKey = observation.resourceKey,
            metadata = copyPrimitive(observation.metadata) or {},
            facts = copyPrimitive(observation.facts) or {},
            source = observation.source,
        }
    end
    local zones, roomDiagnostics = Internal.CollectZones(cell, origin,
        originX, originY, originZ, radius, objects)
    local snapshot = {
        version = Perception.VERSION,
        status = "READY",
        origin = { x = originX, y = originY, z = originZ },
        radius = radius,
        maxObjects = maxObjects,
        objects = objects,
        zones = zones,
        campPreview = includeCampPreview
            and Internal.PreviewCamp(origin, cell) or nil,
        diagnostics = {
            scan = copyPrimitive(scanStats) or {},
            rooms = roomDiagnostics,
            snapshotCacheHit = false,
            clientOnly = true,
            serverRequests = 0,
            providerVersion = Perception.ProviderVersion,
        },
        providers = Perception.ListProviders(),
        observedAt = timestamp,
    }
    Perception.SnapshotCache[key] = { at = timestamp, snapshot = snapshot }
    return snapshot
end

function Perception.GetSnapshot(options)
    return Perception.BuildSnapshot(options)
end

return Perception
