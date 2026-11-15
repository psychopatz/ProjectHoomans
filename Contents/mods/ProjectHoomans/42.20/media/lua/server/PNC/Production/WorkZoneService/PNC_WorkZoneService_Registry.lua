-- WorkZoneService registry: PC_GridRegion geometry validation, PC_ZoneRegistry
-- registration, and CreateZone / DeleteZone / DisableZone lifecycle commands.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local CoreZones = require "PsychopatzCore/World/PC_ZoneRegistry"

PNC = PNC or {}
PNC.WorkZoneService = PNC.WorkZoneService or {}
PNC.WorkZoneService.Internal = PNC.WorkZoneService.Internal or {}

local Service = PNC.WorkZoneService
local Internal = Service.Internal

Service.Data = Service.Data or { zones = {}, zoneOrder = {}, seq = 0 }

function Internal.now()
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function makeBoundsRegion(bounds)
    if type(bounds) ~= "table" then return nil end
    local minX = math.floor(tonumber(bounds.minX or bounds.x1 or bounds.x) or 0)
    local maxX = math.floor(tonumber(bounds.maxX or bounds.x2 or minX) or minX)
    local minY = math.floor(tonumber(bounds.minY or bounds.y1 or bounds.y) or 0)
    local maxY = math.floor(tonumber(bounds.maxY or bounds.y2 or minY) or minY)
    local z = math.floor(tonumber(bounds.minZ or bounds.z or 0) or 0)
    if maxX < minX then minX, maxX = maxX, minX end
    if maxY < minY then minY, maxY = maxY, minY end
    local rows = {}
    for y = minY, maxY do
        rows[y] = { minX, maxX }
    end
    return { levels = { [z] = rows } }
end

local function hasEntries(t)
    if type(t) ~= "table" then return false end
    for _, _ in pairs(t) do return true end
    return false
end

function Internal.resolveGeometry(args)
    local raw = type(args) == "table" and (args.geometry or args.region) or nil
    if not hasEntries(raw) then
        raw = makeBoundsRegion(args and args.bounds or args)
    end
    if not raw or not GridRegion or type(GridRegion.validate) ~= "function" then
        return nil, nil, "INVALID_ZONE_GEOMETRY"
    end
    local ok, reason, normalized = GridRegion.validate(raw)
    if not ok or not normalized then
        return nil, nil, reason or "INVALID_ZONE_GEOMETRY"
    end
    local bounds = GridRegion.bounds and GridRegion.bounds(normalized) or nil
    return normalized, bounds, nil
end

local function generateZoneId(zoneType)
    if PNC.Core and type(PNC.Core.GenerateID) == "function" then
        return PNC.Core.GenerateID("workzone_" .. string.lower(tostring(zoneType or "work")))
    end
    Service.Data.seq = (tonumber(Service.Data.seq) or 0) + 1
    return "workzone:" .. tostring(zoneType or "work") .. ":" .. tostring(Service.Data.seq)
end

local function syncCoreZone(zone)
    if not CoreZones or type(CoreZones.register) ~= "function" then return end
    CoreZones.register({
        id = zone.id,
        ownerType = zone.ownerType,
        ownerId = zone.ownerId,
        type = "work_zone",
        subtype = zone.operation,
        geometry = zone.geometry,
        revision = zone.revision,
    })
end

---Creates or registers a work zone with normalized PC_GridRegion geometry.
function Service.CreateZone(args)
    args = type(args) == "table" and args or {}
    local geometry, bounds, geomReason = Internal.resolveGeometry(args)
    if not geometry then return nil, geomReason end

    local operation = string.upper(tostring(args.operation or args.zoneType or "WORK"))
    local id = tostring(args.id or generateZoneId(operation))
    if Service.Data.zones[id] then return nil, "WORK_ZONE_EXISTS" end

    local zone = {
        id = id,
        operation = operation,
        zoneType = tostring(args.zoneType or operation),
        ownerType = tostring(args.ownerType or "colony"),
        ownerId = tostring(args.ownerId or args.colonyId or ""),
        colonyId = tostring(args.colonyId or args.ownerId or ""),
        factionId = tostring(args.factionId or ""),
        baseId = tostring(args.baseId or ""),
        geometry = geometry,
        bounds = bounds,
        enabled = args.enabled ~= false,
        workers = {},
        claims = {},
        cursor = 1,
        revision = 1,
        createdAt = Internal.now(),
        metadata = type(args.metadata) == "table" and args.metadata or {},
    }
    Service.Data.zones[id] = zone
    Service.Data.zoneOrder[#Service.Data.zoneOrder + 1] = id
    syncCoreZone(zone)
    if type(args.npcIds) == "table" and Service.AssignWorker then
        for _, npcId in ipairs(args.npcIds) do
            Service.AssignWorker(id, npcId)
        end
    end
    return zone
end

---Looks up a registered work zone by id.
function Service.GetZone(zoneId)
    return zoneId and Service.Data.zones[tostring(zoneId)] or nil
end

---Lists work zones filtered optionally by colonyId, ownerId, or operation.
function Service.ListZones(filter)
    filter = type(filter) == "table" and filter or {}
    local out = {}
    for _, id in ipairs(Service.Data.zoneOrder or {}) do
        local z = Service.Data.zones[id]
        if z then
            local okColony = not filter.colonyId or z.colonyId == filter.colonyId
            local okOwner = not filter.ownerId or z.ownerId == filter.ownerId
            local okOp = not filter.operation or z.operation == filter.operation
            local okEnabled = filter.enabled == nil or z.enabled == filter.enabled
            if okColony and okOwner and okOp and okEnabled then
                out[#out + 1] = z
            end
        end
    end
    return out
end

---Disables a work zone and increments its revision.
function Service.DisableZone(zoneId)
    local zone = Service.GetZone(zoneId)
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    zone.enabled = false
    zone.revision = (tonumber(zone.revision) or 1) + 1
    return true, zone
end

---Deletes a work zone from WorkZoneService and PC_ZoneRegistry.
function Service.DeleteZone(zoneId)
    local id = tostring(zoneId or "")
    local zone = Service.GetZone(id)
    if not zone then return false, "WORK_ZONE_NOT_FOUND" end
    zone.claims = {}
    zone.workers = {}
    Service.Data.zones[id] = nil
    local nextOrder = {}
    for _, existingId in ipairs(Service.Data.zoneOrder or {}) do
        if existingId ~= id then nextOrder[#nextOrder + 1] = existingId end
    end
    Service.Data.zoneOrder = nextOrder
    if CoreZones and type(CoreZones.remove) == "function" then
        CoreZones.remove(id)
    end
    return true
end

return Service
