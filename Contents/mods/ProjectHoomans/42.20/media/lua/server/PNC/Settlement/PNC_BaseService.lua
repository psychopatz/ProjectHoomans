if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.BaseService = PNC.BaseService or {}

local Service = PNC.BaseService
local Repository = PNC.SettlementRepository
local Validation = PNC.BaseValidationService
local Definitions = PNC.SettlementDefinitions
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local EventsBus = PsychopatzCore and PsychopatzCore.Events

Service.ProcessedRequests = Service.ProcessedRequests or {}
Service.ProcessedRequestOrder = Service.ProcessedRequestOrder or {}
Service.MAX_PROCESSED_REQUESTS = 256

local function emit(eventType, payload)
    if EventsBus and EventsBus.emit then EventsBus.emit(eventType, payload) end
end

local function beginRequest(requestId)
    requestId = requestId and tostring(requestId) or nil
    if requestId and Service.ProcessedRequests[requestId] then
        return false, Service.ProcessedRequests[requestId]
    end
    return true, requestId
end

local function finishRequest(requestId, response)
    if requestId then
        Service.ProcessedRequests[requestId] = response
        Service.ProcessedRequestOrder[#Service.ProcessedRequestOrder + 1] = requestId
        if #Service.ProcessedRequestOrder > Service.MAX_PROCESSED_REQUESTS then
            local expired = table.remove(Service.ProcessedRequestOrder, 1)
            Service.ProcessedRequests[expired] = nil
        end
    end
    return response
end

local function response(ok, reason, entity, event)
    return { ok = ok == true, reason = reason, base = entity, event = event }
end

local function touch(base)
    base.revision = (tonumber(base.revision) or 0) + 1
    Repository.MarkDirty()
end

function Service.Get(id) return Repository.GetBase(id) end

function Service.GetForColony(colonyId)
    return Repository.FindBaseByColony(tostring(colonyId or ""))
end

function Service.GetTerritorySummary(baseOrId)
    local base = type(baseOrId) == "table" and baseOrId or Service.Get(baseOrId)
    if not base then return nil end
    local zone = Zones.get(base.baseZoneId)
    local capacity = Definitions.GetTerritoryCapacity(base.hqLevel, base.barricadeCount)
    local claimed = zone and zone.cachedTileCount or 0
    return {
        claimedArea = claimed,
        territoryCapacity = capacity,
        territoryLimit = Definitions.GetTerritoryLimit(base.hqLevel),
        freeExpansionCapacity = math.max(0, capacity - claimed),
        barricadeCount = base.barricadeCount,
    }
end

function Service.Create(player, args)
    args = type(args) == "table" and args or {}
    local allowed, requestId = beginRequest(args.requestId)
    if not allowed then return requestId end
    if Service.GetForColony(args.colonyId) then
        return finishRequest(requestId, response(false, "BASE_ALREADY_EXISTS"))
    end
    if not Validation.CanCreateFor(player, args.colonyId, args.factionId) then
        return finishRequest(requestId, response(false, "NO_PERMISSION"))
    end
    local check = Validation.CanCreate(args.region)
    if not check.ok then return finishRequest(requestId, response(false, check.reason)) end
    local id = tostring(args.baseId or PNC.Core.GenerateID("base"))
    local zoneId = tostring(args.zoneId or PNC.Core.GenerateID("base_zone"))
    local base = {
        schemaVersion = Definitions.SCHEMA_VERSION, id = id,
        colonyId = tostring(args.colonyId or ""),
        factionId = tostring(args.factionId or ""),
        hqLevel = 1, barricadeCount = 0, baseZoneId = zoneId,
        facilityIds = {}, stockpileNodeIds = {}, revision = 0,
    }
    local ok, zoneOrReason = Zones.register({
        schemaVersion = 1, id = zoneId, ownerType = "projecthoomans.base",
        ownerId = id, type = "base", subtype = "territory",
        geometry = check.details.footprint,
    })
    if not ok then return finishRequest(requestId, response(false, zoneOrReason)) end
    Repository.State.bases[id] = base
    Repository.MarkDirty()
    emit(PNC.EventTypes.BASE_CREATED, { baseId = id, colonyId = base.colonyId,
        revision = base.revision })
    return finishRequest(requestId, response(true, nil, base, "BaseCreated"))
end

local function changeGeometry(player, args, operation)
    local allowed, requestId = beginRequest(args.requestId)
    if not allowed then return requestId end
    local base = Service.Get(args.baseId)
    if not base then return finishRequest(requestId, response(false, "BASE_NOT_FOUND")) end
    if not Validation.CanUse(player, base) then
        return finishRequest(requestId, response(false, "NO_PERMISSION"))
    end
    local zone = Zones.get(base.baseZoneId)
    local check = Validation.CanChange(base, zone and zone.geometry,
        args.regionDelta, operation, args.expectedRevision)
    if not check.ok then
        return finishRequest(requestId, response(false, check.reason, base))
    end
    local ok, updated = Zones.updateGeometry(base.baseZoneId,
        check.details.footprint, zone.revision)
    if not ok then return finishRequest(requestId, response(false, updated, base)) end
    touch(base)
    local event = operation == "REMOVE" and "BaseShrunk" or "BaseExpanded"
    emit(PNC.EventTypes.BASE_ZONE_CHANGED, { baseId = base.id, operation = operation,
        revision = base.revision, zoneRevision = updated.revision })
    return finishRequest(requestId, response(true, nil, base, event))
end

function Service.Expand(player, args)
    return changeGeometry(player, type(args) == "table" and args or {}, "ADD")
end

function Service.Shrink(player, args)
    return changeGeometry(player, type(args) == "table" and args or {}, "REMOVE")
end

function Service.BuildBarricade(player, args)
    args = type(args) == "table" and args or {}
    local allowed, requestId = beginRequest(args.requestId)
    if not allowed then return requestId end
    local base = Service.Get(args.baseId)
    if not Validation.CanUse(player, base) then
        return finishRequest(requestId, response(false, base and "NO_PERMISSION" or "BASE_NOT_FOUND"))
    end
    local check = Validation.CanBuildBarricade(base, args.expectedRevision)
    if not check.ok then return finishRequest(requestId, response(false, check.reason, base)) end
    base.barricadeCount = base.barricadeCount + 1
    touch(base)
    emit(PNC.EventTypes.BARRICADE_BUILT, { baseId = base.id,
        barricadeCount = base.barricadeCount, revision = base.revision })
    return finishRequest(requestId, response(true, nil, base, "BarricadeBuilt"))
end

function Service.UpgradeHQ(player, args)
    args = type(args) == "table" and args or {}
    local allowed, requestId = beginRequest(args.requestId)
    if not allowed then return requestId end
    local base = Service.Get(args.baseId)
    if not Validation.CanUse(player, base) then
        return finishRequest(requestId, response(false, base and "NO_PERMISSION" or "BASE_NOT_FOUND"))
    end
    local check = Validation.CanUpgradeHQ(base, args.expectedRevision)
    if not check.ok then return finishRequest(requestId, response(false, check.reason, base)) end
    base.hqLevel = base.hqLevel + 1
    touch(base)
    emit(PNC.EventTypes.HQ_UPGRADED, { baseId = base.id,
        hqLevel = base.hqLevel, revision = base.revision })
    return finishRequest(requestId, response(true, nil, base, "HQUpgraded"))
end

function Service.BuildSnapshot(baseOrId)
    local base = type(baseOrId) == "table" and baseOrId or Service.Get(baseOrId)
    if not base then return nil end
    local output = PNC.Core.DeepCopy(base)
    output.territory = Service.GetTerritorySummary(base)
    local zone = Zones.get(base.baseZoneId)
    output.geometry = zone and {
        tileCount = zone.cachedTileCount, bounds = zone.cachedBounds,
        spanCount = GridRegion.spanCount(zone.geometry),
        connected = GridRegion.isConnected(zone.geometry, 4),
        revision = zone.revision,
        region = PNC.Core.DeepCopy(zone.geometry),
    } or nil
    return output
end

return Service
