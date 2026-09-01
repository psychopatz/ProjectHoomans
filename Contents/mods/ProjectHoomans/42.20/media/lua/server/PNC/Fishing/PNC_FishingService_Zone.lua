-- Fishing-zone persistence and public zone operations.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.FishingService
local H = Service.Internal
local GridRegion = H.GridRegion
local Zones = H.Zones

local function normalizeRegion(args)
    if type(args.region) ~= "table" or not GridRegion
        or type(GridRegion.validate) ~= "function"
    then
        return nil, "fishing_region_unavailable"
    end
    local valid, reason, normalized = GridRegion.validate(args.region)
    if not valid then return nil, reason or "fishing_zone_empty" end
    if type(GridRegion.isConnected) == "function"
        and not GridRegion.isConnected(normalized, 4)
    then
        return nil, "fishing_zone_disconnected"
    end
    local bounds = GridRegion.bounds(normalized)
    if not bounds then return nil, "fishing_zone_bounds_missing" end
    if bounds.minZ ~= bounds.maxZ then
        return nil, "fishing_zone_multiple_levels"
    end
    if GridRegion.countTiles(normalized) > Service.MAX_ZONE_TILES then
        return nil, "fishing_zone_too_large"
    end
    return {
        geometry = normalized,
        minX = bounds.minX, minY = bounds.minY,
        maxX = bounds.maxX, maxY = bounds.maxY,
        minZ = bounds.minZ, maxZ = bounds.maxZ,
    }
end

local function buildRectangle(minX, minY, maxX, maxY, z)
    local rows = {}
    for y = minY, maxY do rows[y] = { minX, maxX } end
    return { levels = { [z] = { rows = rows } } }
end

local function normalizeRectangle(args)
    local minX, minY = H.Integer(args.minX), H.Integer(args.minY)
    local maxX, maxY = H.Integer(args.maxX), H.Integer(args.maxY)
    local z = H.Integer(args.z) or 0
    if not minX or not minY or not maxX or not maxY then
        return nil, "fishing_zone_coordinates_invalid"
    end
    if minX > maxX then minX, maxX = maxX, minX end
    if minY > maxY then minY, maxY = maxY, minY end
    if (maxX - minX + 1) * (maxY - minY + 1) > Service.MAX_ZONE_TILES then
        return nil, "fishing_zone_too_large"
    end
    return { minX = minX, minY = minY, maxX = maxX, maxY = maxY,
        minZ = z, maxZ = z, geometry = buildRectangle(minX, minY, maxX, maxY, z) }
end

local function registerCoreZone(zone)
    if not Zones or type(Zones.register) ~= "function" then return true end
    local ok, result = pcall(Zones.register, {
        id = zone.id, ownerType = zone.ownerType, ownerId = zone.ownerId,
        type = "fishing", subtype = "fishing_zone",
        geometry = zone.geometry, revision = zone.revision,
    })
    return ok and result ~= false
end

function Service.ValidateZone(zone)
    if not zone or zone.enabled ~= true then return false, "fishing_zone_disabled" end
    if zone.valid ~= true or #(zone.fishingSpots or {}) <= 0 then
        return false, "fishing_zone_invalid"
    end
    return true
end

function Service.RescanZone(zoneId)
    local zone = Service.GetZone(zoneId)
    if not zone then return false, "fishing_zone_not_found" end
    local valid, reason = H.DeriveFishingSpots(zone)
    zone.revision = (tonumber(zone.revision) or 0) + 1
    H.MarkDirty()
    return valid, reason
end

function Service.CreateZone(args)
    args = type(args) == "table" and args or {}
    if not Service.Loaded then Service.Load(true) end
    local rectangle, reason
    if args.region ~= nil then
        rectangle, reason = normalizeRegion(args)
    else
        rectangle, reason = normalizeRectangle(args)
    end
    if not rectangle then return nil, reason end
    local id = tostring(args.id or H.MakeID("fishing_zone"))
    local data = H.EnsureData()
    if id == "" or data.zones[id] then return nil, "fishing_zone_exists" end
    local zone = {
        schemaVersion = Service.SCHEMA_VERSION, id = id,
        ownerType = tostring(args.ownerType or "player"),
        ownerId = tostring(args.ownerId or ""), geometry = rectangle.geometry,
        bounds = { minX = rectangle.minX, minY = rectangle.minY,
            maxX = rectangle.maxX, maxY = rectangle.maxY,
            minZ = rectangle.minZ, maxZ = rectangle.maxZ },
        enabled = true, revision = 1, workers = {},
        loot = type(args.loot) == "table" and H.Copy(args.loot)
            or H.Copy(PNC.Fishing.DEFAULT_LOOT),
        catchChance = tonumber(args.catchChance),
        skillCatchBonus = tonumber(args.skillCatchBonus),
        workPointsPerSecond = tonumber(args.workPointsPerSecond),
        requiredWorkPoints = tonumber(args.requiredWorkPoints),
        createdAt = H.Now(),
    }
    if GridRegion and GridRegion.validate then
        local valid, validationReason, normalized = GridRegion.validate(zone.geometry)
        if not valid then return nil, validationReason end
        zone.geometry = normalized
        if GridRegion.bounds then zone.bounds = GridRegion.bounds(normalized) end
    end
    local valid, validationReason = H.DeriveFishingSpots(zone)
    if not valid then return nil, validationReason end
    if not registerCoreZone(zone) then return nil, "zone_registry_rejected" end
    data.zones[id] = zone
    data.zoneOrder[#data.zoneOrder + 1] = id
    local ids = type(args.npcIds) == "table" and args.npcIds or {}
    for index = 1, math.min(#ids, Service.MAX_WORKERS_PER_ZONE) do
        Service.AssignWorker(id, ids[index])
    end
    H.MarkDirty()
    Service.Save()
    return zone
end

function Service.DeleteZone(zoneId, reason)
    local zone = Service.GetZone(zoneId)
    local data = H.EnsureData()
    local id = tostring(zoneId or "")
    if not zone then return false, "fishing_zone_not_found" end
    local workerIds = {}
    for npcId, _ in pairs(zone.workers or {}) do
        workerIds[#workerIds + 1] = npcId
    end
    for _, npcId in ipairs(workerIds) do
        if Service.CancelJob then
            Service.CancelJob(npcId, reason or "fishing_zone_deleted")
        else
            zone.workers[npcId] = nil
        end
    end
    if Zones and type(Zones.remove) == "function" then
        pcall(Zones.remove, id)
    end
    data.zones[id] = nil
    for index = #data.zoneOrder, 1, -1 do
        if tostring(data.zoneOrder[index]) == id then
            table.remove(data.zoneOrder, index)
        end
    end
    H.MarkDirty()
    Service.Save()
    return true, "fishing_zone_deleted"
end

local function distanceSq(record, x, y)
    local rx, ry = tonumber(record and record.x) or 0, tonumber(record and record.y) or 0
    local dx, dy = rx - x, ry - y
    return dx * dx + dy * dy
end

function Service.IsNearby(record, zone, radius)
    local spot
    local distance
    for _, candidate in ipairs(zone and zone.fishingSpots or {}) do
        local value = distanceSq(record, candidate.standX, candidate.standY)
        if not spot or value < distance
            or (value == distance and tostring(candidate.id) < tostring(spot.id))
        then spot, distance = candidate, value end
    end
    local rz = tonumber(record and record.z) or 0
    local sz = spot and tonumber(spot.standZ) or rz
    radius = tonumber(radius) or Service.ACTIVATION_RADIUS
    return spot ~= nil and math.abs(rz - sz) <= 0.6
        and distance <= radius * radius, spot,
        distance and math.sqrt(distance) or nil
end

return Service
