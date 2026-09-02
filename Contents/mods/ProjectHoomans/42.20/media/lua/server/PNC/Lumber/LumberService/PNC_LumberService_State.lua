-- Persistent LumberService state, schema normalization, and shared primitives.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.LumberService
local Internal = Service.Internal
local Core = Internal.Core
local GridRegion = Internal.GridRegion
local Zones = Internal.Zones

local function now()
    if Core and type(Core.Now) == "function" then return Core.Now() end
    return 0
end

local function copy(value)
    if Core and type(Core.DeepCopy) == "function" then
        return Core.DeepCopy(value)
    end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = copy(item) end
    return output
end

local function integer(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge or value ~= math.floor(value)
    then return nil end
    return value
end

local function finite(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge
        or value == -math.huge
    then return nil end
    return value
end

local function makeID(prefix)
    if Core and type(Core.GenerateID) == "function" then
        return tostring(Core.GenerateID(prefix))
    end
    return tostring(prefix) .. ":" .. tostring(now())
end

local function markDirty()
    Service.Dirty = true
end

local function ensureData()
    if type(Service.Data) ~= "table" then
        Service.Data = {
            schemaVersion = Service.SCHEMA_VERSION,
            zones = {},
            trees = {},
            jobs = {},
            zoneOrder = {},
        }
    end
    Service.Data.schemaVersion = Service.SCHEMA_VERSION
    Service.Data.zones = type(Service.Data.zones) == "table"
        and Service.Data.zones or {}
    Service.Data.trees = type(Service.Data.trees) == "table"
        and Service.Data.trees or {}
    Service.Data.jobs = type(Service.Data.jobs) == "table"
        and Service.Data.jobs or {}
    Service.Data.zoneOrder = type(Service.Data.zoneOrder) == "table"
        and Service.Data.zoneOrder or {}
    return Service.Data
end

local function zoneBounds(zone)
    if zone and zone.bounds then return zone.bounds end
    if GridRegion and zone and zone.geometry
        and type(GridRegion.bounds) == "function"
    then
        zone.bounds = GridRegion.bounds(zone.geometry)
    end
    return zone and zone.bounds or nil
end

local function zoneContains(zone, x, y, z)
    local bounds = zoneBounds(zone)
    if not bounds or x < bounds.minX or x > bounds.maxX
        or y < bounds.minY or y > bounds.maxY
        or z < bounds.minZ or z > bounds.maxZ
    then return false end
    if GridRegion and type(GridRegion.containsPoint) == "function" then
        return GridRegion.containsPoint(zone.geometry, x, y, z)
    end
    return true
end

local function registerCoreZone(zone)
    if not Zones or type(Zones.register) ~= "function" then return true end
    local ok, result = pcall(Zones.register, {
        id = zone.id,
        ownerType = zone.ownerType,
        ownerId = zone.ownerId,
        type = "lumber",
        subtype = "lumber_zone",
        geometry = zone.geometry,
        revision = zone.revision,
    })
    return ok and result ~= false
end

local function unregisterCoreZone(zoneId)
    if Zones and type(Zones.remove) == "function" then
        pcall(Zones.remove, zoneId)
    end
end

local function buildRectangle(minX, minY, maxX, maxY, z)
    local rows = {}
    for y = minY, maxY do rows[y] = { minX, maxX } end
    return {
        levels = {
            [z] = { rows = rows },
        },
    }
end

local function normalizeRectangle(args)
    local minX = integer(args.minX)
    local minY = integer(args.minY)
    local maxX = integer(args.maxX)
    local maxY = integer(args.maxY)
    local z = integer(args.z) or 0
    if not minX or not minY or not maxX or not maxY then
        return nil, "zone_coordinates_invalid"
    end
    if minX > maxX then minX, maxX = maxX, minX end
    if minY > maxY then minY, maxY = maxY, minY end
    local width = maxX - minX + 1
    local height = maxY - minY + 1
    if width < 1 or height < 1 or width * height > Service.MAX_ZONE_TILES then
        return nil, "zone_too_large"
    end
    return {
        minX = minX, minY = minY, maxX = maxX, maxY = maxY,
        minZ = z, maxZ = z,
        geometry = buildRectangle(minX, minY, maxX, maxY, z),
    }
end

local function normalizeRegion(args)
    if type(args.region) ~= "table" or not GridRegion
        or type(GridRegion.validate) ~= "function"
    then
        return nil, "region_unavailable"
    end
    local valid, reason, normalized = GridRegion.validate(args.region)
    if not valid then return nil, reason or "zone_empty" end
    if GridRegion.isConnected and not GridRegion.isConnected(normalized, 4) then
        return nil, "zone_disconnected"
    end
    local bounds = GridRegion.bounds(normalized)
    if not bounds then return nil, "zone_bounds_missing" end
    if bounds.minZ ~= bounds.maxZ then
        return nil, "zone_multiple_levels"
    end
    if GridRegion.countTiles(normalized) > Service.MAX_ZONE_TILES then
        return nil, "zone_too_large"
    end
    return {
        minX = bounds.minX, minY = bounds.minY,
        maxX = bounds.maxX, maxY = bounds.maxY,
        minZ = bounds.minZ, maxZ = bounds.maxZ,
        geometry = normalized,
    }
end

local function ensureZoneRuntime(zone)
    zone.workers = type(zone.workers) == "table" and zone.workers or {}
    zone.treeKeys = type(zone.treeKeys) == "table" and zone.treeKeys or {}
    zone.treeIndex = type(zone.treeIndex) == "table" and zone.treeIndex or {}
    for index = 1, #zone.treeKeys do
        zone.treeIndex[tostring(zone.treeKeys[index])] = true
    end
    zone.scan = type(zone.scan) == "table" and zone.scan or {}
    local bounds = zoneBounds(zone)
    if bounds then
        zone.scan.x = integer(zone.scan.x) or bounds.minX
        zone.scan.y = integer(zone.scan.y) or bounds.minY
        zone.scan.z = integer(zone.scan.z) or bounds.minZ
    end
    zone.scan.scannedTiles = math.max(0,
        math.floor(tonumber(zone.scan.scannedTiles) or 0))
    zone.scan.loadedTiles = math.max(0,
        math.floor(tonumber(zone.scan.loadedTiles) or 0))
    zone.scan.unloadedTiles = math.max(0,
        math.floor(tonumber(zone.scan.unloadedTiles) or 0))
    zone.scan.unresolved = type(zone.scan.unresolved) == "table"
        and zone.scan.unresolved or {}
    zone.scan.unresolvedSeen = type(zone.scan.unresolvedSeen) == "table"
        and zone.scan.unresolvedSeen or {}
    for index = 1, #zone.scan.unresolved do
        local entry = zone.scan.unresolved[index]
        if type(entry) == "table" then
            zone.scan.unresolvedSeen[
                tostring(entry.x) .. ":" .. tostring(entry.y) .. ":"
                    .. tostring(entry.z)
            ] = true
        end
    end
    zone.scan.retryCursor = math.max(1,
        math.floor(tonumber(zone.scan.retryCursor) or 1))
    zone.scan.phase = tostring(zone.scan.phase
        or (#zone.scan.unresolved > 0 and "RETRY_UNLOADED" or "INITIAL"))
    zone.scan.complete = zone.scan.complete == true
    if #zone.scan.unresolved > 0 then
        zone.scan.complete = false
        zone.scan.phase = "RETRY_UNLOADED"
    end
    zone.enabled = zone.enabled ~= false
    zone.revision = math.max(0, math.floor(tonumber(zone.revision) or 0))
    return zone
end

local function normalizeTree(tree, key)
    tree.key = tostring(tree.key or key or "")
    tree.x = integer(tree.x)
    tree.y = integer(tree.y)
    tree.z = integer(tree.z) or 0
    tree.status = tostring(tree.status or "DISCOVERED")
    tree.signature = tostring(tree.signature or "")
    tree.maxWork = math.max(1, tonumber(tree.maxWork) or 1)
    tree.remainingWork = math.max(0,
        math.min(tree.maxWork, tonumber(tree.remainingWork) or tree.maxWork))
    tree.logYield = math.max(1, math.floor(tonumber(tree.logYield) or 1))
    tree.revision = math.max(0, math.floor(tonumber(tree.revision) or 0))
    return tree
end

local function normalizeLoadedState()
    local data = ensureData()
    local zone
    local key
    for key, zone in pairs(data.zones) do
        zone.id = tostring(zone.id or key)
        ensureZoneRuntime(zone)
        data.zones[zone.id] = zone
        if zone.id ~= key then data.zones[key] = nil end
        registerCoreZone(zone)
    end
    for key, zone in pairs(data.trees) do
        data.trees[key] = normalizeTree(zone, key)
        if data.trees[key].status == "CLAIMED"
            or data.trees[key].status == "IN_PROGRESS"
        then
            data.trees[key].status = "DISCOVERED"
        end
    end
    Service.Runtime.claims = {}
    for _, job in pairs(data.jobs) do
        job.npcId = tostring(job.npcId or "")
        job.zoneId = tostring(job.zoneId or "")
        job.active = job.active ~= false
        job.state = tostring(job.state or "READY")
        job.phase = tostring(job.phase or "WAITING")
        job.revision = math.max(0, math.floor(tonumber(job.revision) or 0))
        job.leaseId = nil
    end
end

function Service.Load(force)
    if Service.Loaded and force ~= true then return true end
    local raw
    if ModData and type(ModData.getOrCreate) == "function" then
        raw = ModData.getOrCreate(Service.MODDATA_KEY)
    end
    if type(raw) == "table" then Service.Data = raw end
    ensureData()
    normalizeLoadedState()
    Service.Runtime.nextWorkReconcileAt = 0
    Service.Loaded = true
    Service.Dirty = false
    return true, "loaded"
end

function Service.Save()
    if not Service.Loaded then Service.Load(true) end
    local data = ensureData()
    if ModData and type(ModData.getOrCreate) == "function" then
        local target = ModData.getOrCreate(Service.MODDATA_KEY)
        if target then
            target.schemaVersion = Service.SCHEMA_VERSION
            target.zones = data.zones
            target.trees = data.trees
            target.jobs = data.jobs
            target.zoneOrder = data.zoneOrder
        end
    end
    Service.LastSaveAt = now()
    Service.Dirty = false
    return true, "saved"
end

function Service.GetZone(zoneId)
    ensureData()
    return Service.Data.zones[tostring(zoneId or "")]
end

function Service.GetTree(treeKey)
    ensureData()
    return Service.Data.trees[tostring(treeKey or "")]
end

function Service.GetJob(npcId)
    ensureData()
    return Service.Data.jobs[tostring(npcId or "")]
end

Internal.Now = now
Internal.Copy = copy
Internal.Integer = integer
Internal.Finite = finite
Internal.MakeID = makeID
Internal.MarkDirty = markDirty
Internal.EnsureData = ensureData
Internal.ZoneBounds = zoneBounds
Internal.ZoneContains = zoneContains
Internal.RegisterCoreZone = registerCoreZone
Internal.UnregisterCoreZone = unregisterCoreZone
Internal.NormalizeRegion = normalizeRegion
Internal.NormalizeRectangle = normalizeRectangle
Internal.EnsureZoneRuntime = ensureZoneRuntime

return Service
