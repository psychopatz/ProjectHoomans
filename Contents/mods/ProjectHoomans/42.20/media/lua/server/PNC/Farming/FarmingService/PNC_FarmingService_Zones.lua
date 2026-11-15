-- Zone-based farming designation and zone configuration commands.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FarmingService = PNC.FarmingService or {}
local Service = PNC.FarmingService
local Internal = Service.Internal
local Farming = PNC.Farming
local Catalog = PNC.FarmingCatalog

Service.Data = Service.Data or { zones = {}, zoneOrder = {} }

local function makeId(prefix)
    if PNC.Core and type(PNC.Core.GenerateID) == "function" then
        return PNC.Core.GenerateID(prefix)
    end
    local n = #(Service.Data.zoneOrder or {}) + 1
    return tostring(prefix or "farm_zone") .. ":" .. tostring(n)
end

---Creates a designated farming zone compatible with ZoneService and WorkService.
function Service.CreateZone(args)
    args = type(args) == "table" and args or {}
    if not Farming or type(Farming.ZoneInfo) ~= "function" then
        return nil, "FARMING_CORE_UNAVAILABLE"
    end
    local ok, reason, info = Farming.ZoneInfo(args)
    if not ok or not info then return nil, reason or "FARM_ZONE_INVALID" end
    local id = tostring(args.id or makeId("farm_zone"))
    if Service.Data.zones[id] then return nil, "FARM_ZONE_EXISTS" end
    local zone = {
        schemaVersion = Farming.SCHEMA_VERSION,
        id = id,
        ownerType = tostring(args.ownerType or "colony"),
        ownerId = tostring(args.ownerId or args.colonyId or ""),
        colonyId = tostring(args.colonyId or args.ownerId or ""),
        factionId = tostring(args.factionId or ""),
        baseId = tostring(args.baseId or ""),
        geometry = info.region or args.geometry or args.region,
        bounds = {
            minX = info.minX, maxX = info.maxX,
            minY = info.minY, maxY = info.maxY,
            minZ = info.z, maxZ = info.z,
        },
        desiredCrop = Farming.NormalizeCrop(args.desiredCrop or args.crop),
        policy = Farming.NormalizePolicy(args.policy),
        enabled = args.enabled ~= false,
        revision = 1,
        workers = {},
        createdAt = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0,
    }
    Internal.EnsureAbstractTiles(zone)
    if PNC.WorkZoneService and type(PNC.WorkZoneService.CreateZone) == "function" then
        PNC.WorkZoneService.CreateZone({
            id = zone.id, operation = "FARMING", zoneType = "FARMING",
            ownerType = zone.ownerType, ownerId = zone.ownerId,
            colonyId = zone.colonyId, factionId = zone.factionId,
            baseId = zone.baseId, geometry = zone.geometry,
            bounds = zone.bounds, enabled = zone.enabled,
        })
    elseif PNC.ZoneService and type(PNC.ZoneService.Register) == "function" then
        PNC.ZoneService.Register({
            id = zone.id, type = "FARMING",
            ownerType = zone.ownerType, ownerId = zone.ownerId,
            geometry = zone.geometry, bounds = zone.bounds, enabled = zone.enabled,
        })
    end
    Service.Data.zones[id] = zone
    Service.Data.zoneOrder[#Service.Data.zoneOrder + 1] = id
    for _, npcId in ipairs(type(args.npcIds) == "table" and args.npcIds or {}) do
        Service.AssignWorker(id, npcId)
    end
    if PNC.FarmingWorkAdapter and PNC.FarmingWorkAdapter.EnsureZoneOrder then
        PNC.FarmingWorkAdapter.EnsureZoneOrder(zone)
    end
    return zone
end

---Looks up a designated farming zone by id.
function Service.GetZone(zoneId)
    return zoneId and Service.Data.zones[tostring(zoneId)] or nil
end

---Lists farming zones, optionally filtered by ownerId/colonyId.
function Service.ListZones(ownerId)
    local out = {}
    for _, id in ipairs(Service.Data.zoneOrder or {}) do
        local z = Service.Data.zones[id]
        if z and (not ownerId or z.ownerId == ownerId or z.colonyId == ownerId) then
            out[#out + 1] = z
        end
    end
    return out
end

---Updates a farming zone's desiredCrop and reconciles WorkService orders.
function Service.SetZoneDesiredCrop(zoneId, desiredCrop)
    local zone = Service.GetZone(zoneId)
    if not zone then return false, "FARM_ZONE_NOT_FOUND" end
    local crop = Farming.NormalizeCrop(desiredCrop)
    if not crop or not Catalog or not Catalog.Get or not Catalog.Get(crop) then
        return false, "UNKNOWN_CROP"
    end
    zone.desiredCrop = crop
    zone.revision = (tonumber(zone.revision) or 1) + 1
    if PNC.FarmingWorkAdapter and PNC.FarmingWorkAdapter.EnsureZoneOrder then
        PNC.FarmingWorkAdapter.EnsureZoneOrder(zone)
    end
    return true, zone
end

---Updates a farming zone's policy and reconciles WorkService orders.
function Service.SetZonePolicy(zoneId, policy)
    local zone = Service.GetZone(zoneId)
    if not zone then return false, "FARM_ZONE_NOT_FOUND" end
    zone.policy = Farming.NormalizePolicy(policy)
    zone.revision = (tonumber(zone.revision) or 1) + 1
    if PNC.FarmingWorkAdapter and PNC.FarmingWorkAdapter.EnsureZoneOrder then
        PNC.FarmingWorkAdapter.EnsureZoneOrder(zone)
    end
    return true, zone
end

---Assigns a colonist manually to a farming zone (queues FORCED_ORDER when WorkAdapter is loaded).
function Service.AssignWorker(zoneId, npcId)
    local zone = Service.GetZone(zoneId)
    npcId = tostring(npcId or "")
    if not zone then return false, "FARM_ZONE_NOT_FOUND" end
    if npcId == "" then return false, "NPC_REQUIRED" end
    zone.workers = zone.workers or {}
    zone.workers[npcId] = true
    if PNC.WorkZoneService and type(PNC.WorkZoneService.AssignWorker) == "function" then
        PNC.WorkZoneService.AssignWorker(zoneId, npcId)
    end
    if PNC.FarmingWorkAdapter and PNC.FarmingWorkAdapter.EnsureManualOrder then
        return PNC.FarmingWorkAdapter.EnsureManualOrder(zone, npcId)
    end
    return true, zone
end

return Service
