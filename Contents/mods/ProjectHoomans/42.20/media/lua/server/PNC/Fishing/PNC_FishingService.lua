-- Server-authoritative fishing service entry point. Zone scanning and job
-- execution live in separate modules to keep this composition seam small.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FishingService = PNC.FishingService or {}

local Service = PNC.FishingService
local Const = PNC.Const or {}
local Core = PNC.Core or {}
local Internal = Service.Internal or {}
local GridRegion
local Zones

do
    local ok, value = pcall(require, "PsychopatzCore/World/PC_GridRegion")
    if ok then GridRegion = value end
    ok, value = pcall(require, "PsychopatzCore/World/PC_ZoneRegistry")
    if ok then Zones = value end
end

Service.Internal = Internal
Internal.GridRegion = GridRegion
Internal.Zones = Zones
Service.MODDATA_KEY = "PNC_FishingWorld_V1"
Service.SCHEMA_VERSION = 1
Service.MAX_ZONE_TILES = tonumber(Const.FISHING_MAX_ZONE_TILES) or 10000
Service.MAX_WORKERS_PER_ZONE = tonumber(Const.FISHING_MAX_WORKERS) or 16
Service.ACTIVATION_RADIUS = tonumber(Const.FISHING_DEFAULT_RADIUS) or 16
Service.CLAIM_TTL_MS = 30000
Service.MAX_ELAPSED_MS = 15000
Service.Runtime = Service.Runtime or { spotClaims = {}, previousOrders = {} }
Service.Data = Service.Data or nil
Service.Loaded = Service.Loaded == true
Service.Dirty = Service.Dirty == true
Service.LastSaveAt = tonumber(Service.LastSaveAt) or 0

function Internal.Now()
    return Core and type(Core.Now) == "function" and Core.Now() or 0
end

function Internal.Copy(value)
    if Core and type(Core.DeepCopy) == "function" then return Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    local output = {}
    for key, item in pairs(value) do output[key] = Internal.Copy(item) end
    return output
end

function Internal.Integer(value)
    value = tonumber(value)
    if not value or value ~= math.floor(value) then return nil end
    return value
end

function Internal.MakeID(prefix)
    if Core and type(Core.GenerateID) == "function" then
        return tostring(Core.GenerateID(prefix))
    end
    return tostring(prefix) .. ":" .. tostring(Internal.Now())
end

function Internal.MarkDirty() Service.Dirty = true end

function Internal.EnsureData()
    if type(Service.Data) ~= "table" then
        Service.Data = { schemaVersion = Service.SCHEMA_VERSION,
            zones = {}, jobs = {}, zoneOrder = {} }
    end
    Service.Data.schemaVersion = Service.SCHEMA_VERSION
    Service.Data.zones = type(Service.Data.zones) == "table"
        and Service.Data.zones or {}
    Service.Data.jobs = type(Service.Data.jobs) == "table"
        and Service.Data.jobs or {}
    Service.Data.zoneOrder = type(Service.Data.zoneOrder) == "table"
        and Service.Data.zoneOrder or {}
    return Service.Data
end

function Internal.ZoneBounds(zone)
    if zone and zone.bounds then return zone.bounds end
    if GridRegion and zone and zone.geometry and GridRegion.bounds then
        zone.bounds = GridRegion.bounds(zone.geometry)
    end
    return zone and zone.bounds or nil
end

function Internal.ZoneContains(zone, x, y, z)
    local bounds = Internal.ZoneBounds(zone)
    if not bounds or x < bounds.minX or x > bounds.maxX
        or y < bounds.minY or y > bounds.maxY
        or z < bounds.minZ or z > bounds.maxZ
    then return false end
    if GridRegion and zone.geometry and GridRegion.containsPoint then
        return GridRegion.containsPoint(zone.geometry, x, y, z)
    end
    return true
end

function Service.GetZone(zoneId)
    Internal.EnsureData()
    return Service.Data.zones[tostring(zoneId or "")]
end

function Service.GetJob(npcId)
    Internal.EnsureData()
    return Service.Data.jobs[tostring(npcId or "")]
end

local function normalizeLoaded()
    local data = Internal.EnsureData()
    for key, zone in pairs(data.zones) do
        zone.id = tostring(zone.id or key)
        zone.enabled = zone.enabled ~= false
        zone.revision = math.max(1, math.floor(tonumber(zone.revision) or 1))
        zone.workers = type(zone.workers) == "table" and zone.workers or {}
        zone.fishingSpots = type(zone.fishingSpots) == "table"
            and zone.fishingSpots or {}
        zone.loot = type(zone.loot) == "table" and zone.loot
            or Internal.Copy(PNC.Fishing.DEFAULT_LOOT)
        data.zones[zone.id] = zone
        if zone.id ~= key then data.zones[key] = nil end
        if Zones and Zones.register then
            pcall(Zones.register, { id = zone.id, ownerType = zone.ownerType,
                ownerId = zone.ownerId, type = "fishing",
                subtype = "fishing_zone", geometry = zone.geometry,
                revision = zone.revision })
        end
    end
    Service.Runtime.spotClaims = {}
    for _, job in pairs(data.jobs) do
        job.npcId = tostring(job.npcId or "")
        job.zoneId = tostring(job.zoneId or "")
        job.active = job.active ~= false
        job.leaseId = nil
        job.previousOrder, job.previousOrderCaptured = nil, nil
    end
end

function Service.Load(force)
    if Service.Loaded and force ~= true then return true end
    local raw
    if ModData and type(ModData.getOrCreate) == "function" then
        raw = ModData.getOrCreate(Service.MODDATA_KEY)
    end
    if type(raw) == "table" then Service.Data = raw end
    Internal.EnsureData()
    normalizeLoaded()
    Service.Loaded, Service.Dirty = true, false
    return true, "loaded"
end

function Service.Save()
    if not Service.Loaded then Service.Load(true) end
    local data = Internal.EnsureData()
    if ModData and type(ModData.getOrCreate) == "function" then
        local target = ModData.getOrCreate(Service.MODDATA_KEY)
        if target then
            target.schemaVersion, target.zones = Service.SCHEMA_VERSION, data.zones
            target.jobs, target.zoneOrder = data.jobs, data.zoneOrder
        end
    end
    Service.LastSaveAt, Service.Dirty = Internal.Now(), false
    return true, "saved"
end

require "PNC/Fishing/PNC_FishingService_ZoneWorld"
require "PNC/Fishing/PNC_FishingService_Zone"
require "PNC/Fishing/PNC_FishingService_Job"
require "PNC/Fishing/PNC_FishingService_Lifecycle"
require "PNC/Fishing/PNC_FishingService_Work"

if Events and Events.OnInitGlobalModData and not Service.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Service.Load(true) end)
    Service.LoadHookRegistered = true
end
if Events and Events.OnSave and not Service.SaveHookRegistered then
    Events.OnSave.Add(function() Service.Save() end)
    Service.SaveHookRegistered = true
end

return Service
