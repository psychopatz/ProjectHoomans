if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BaseValidationService = PNC.BaseValidationService or {}

local Validation = PNC.BaseValidationService
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local Definitions = PNC.SettlementDefinitions

local function result(ok, reason, details)
    return { ok = ok == true, reason = reason, details = details }
end

function Validation.ProjectFootprint(region)
    local normalized = GridRegion.normalize(region)
    local footprint = { levels = { [0] = { rows = {} } } }
    for _, level in pairs(normalized.levels) do
        for y, spans in pairs(level.rows) do
            local row = footprint.levels[0].rows[y]
            if not row then row = {}; footprint.levels[0].rows[y] = row end
            for index = 1, #spans do row[#row + 1] = spans[index] end
        end
    end
    return GridRegion.normalize(footprint)
end

function Validation.CanUse(player, base)
    if PNC.BasePermissions and PNC.BasePermissions.CanManage then
        return PNC.BasePermissions.CanManage(player, base) == true
    end
    if not base or not player then return false end
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    return faction and tostring(faction.id) == tostring(base.factionId)
end

function Validation.CanCreateFor(player, colonyId, factionId)
    if PNC.BasePermissions and PNC.BasePermissions.CanCreate then
        return PNC.BasePermissions.CanCreate(player, colonyId, factionId) == true
    end
    local faction = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil
    local colony = PNC.Communities and PNC.Communities.Get
        and PNC.Communities.Get(colonyId) or nil
    return faction ~= nil and colony ~= nil
        and tostring(faction.id) == tostring(factionId)
        and tostring(colony.factionID or colony.factionId) == tostring(factionId)
        and colony.status == "active"
end

local function rectangleRegion(minX, minY, maxX, maxY, minZ, maxZ)
    local region = { levels = {} }
    local z
    for z = math.floor(tonumber(minZ) or 0),
        math.floor(tonumber(maxZ) or tonumber(minZ) or 0)
    do
        local rows = {}
        local y
        for y = math.floor(tonumber(minY) or 0),
            math.floor(tonumber(maxY) or tonumber(minY) or 0)
        do
            rows[y] = {
                math.floor(tonumber(minX) or 0),
                math.floor(tonumber(maxX) or tonumber(minX) or 0),
            }
        end
        region.levels[z] = { rows = rows }
    end
    return GridRegion.normalize(region)
end

local function conflictsWithRegisteredBase(footprint, options)
    local exported = Zones.export and Zones.export() or { byID = {} }
    for zoneID, zone in pairs(exported.byID or {}) do
        if zone.ownerType == "projecthoomans.base"
            and GridRegion.intersects(footprint, zone.geometry)
        then
            local base = PNC.SettlementRepository
                and PNC.SettlementRepository.GetBase
                and PNC.SettlementRepository.GetBase(zone.ownerId) or nil
            local sameFaction = base and tostring(base.factionId)
                == tostring(options.factionId or "")
            return sameFaction and "PLAYER_ZONE_OCCUPIED"
                or "NPC_BASE_OCCUPIED", zoneID
        end
    end
    return nil
end

local function conflictsWithCommunity(footprint, options)
    local communities = PNC.Communities and PNC.Communities.List
        and PNC.Communities.List() or {}
    for _, community in ipairs(communities) do
        if community.status == "active"
            and tostring(community.id) ~= tostring(options.colonyId or "")
        then
            local site = community.site
            local home = site and site.home or community.home
            local bounds = site and site.bounds or nil
            local region
            if bounds then
                region = rectangleRegion(bounds.minX, bounds.minY,
                    bounds.maxX, bounds.maxY, bounds.minZ, bounds.maxZ)
            elseif home and tonumber(home.x) and tonumber(home.y) then
                local radius = math.max(1, math.floor(tonumber(home.radius) or 1))
                region = rectangleRegion(home.x - radius, home.y - radius,
                    home.x + radius, home.y + radius, home.z, home.z)
            end
            if region and GridRegion.intersects(footprint, region) then
                return "NPC_BASE_OCCUPIED", community.id
            end
        end
    end
    return nil
end

local function safehouseValue(safehouse, method)
    if not safehouse or not safehouse[method] then return nil end
    local ok, value = pcall(safehouse[method], safehouse)
    return ok and tonumber(value) or nil
end

local function conflictsWithSafehouse(footprint)
    if not SafeHouse or not SafeHouse.getSafehouseList then return nil end
    local ok, list = pcall(SafeHouse.getSafehouseList)
    if not ok or not list then return nil end
    local count = list.size and list:size() or #list
    local index
    for index = 0, count - 1 do
        local safehouse = list.get and list:get(index) or list[index + 1]
        local x = safehouseValue(safehouse, "getX")
        local y = safehouseValue(safehouse, "getY")
        local width = safehouseValue(safehouse, "getW")
        local height = safehouseValue(safehouse, "getH")
        if x and y and width and height then
            local region = rectangleRegion(x, y, x + width - 1,
                y + height - 1, 0, 0)
            if GridRegion.intersects(footprint, region) then
                return "PLAYER_ZONE_OCCUPIED", tostring(index)
            end
        end
    end
    return nil
end

function Validation.CanCreate(region, options)
    options = type(options) == "table" and options or {}
    local footprint = Validation.ProjectFootprint(region)
    local count = GridRegion.countTiles(footprint)
    if count <= 0 then return result(false, "EMPTY_REGION") end
    if not GridRegion.isConnected(footprint, 4) then
        return result(false, "BASE_DISCONNECTED")
    end
    if count > Definitions.STARTING_TERRITORY then
        return result(false, "BASE_CAPACITY_EXCEEDED", { claimed = count,
            capacity = Definitions.STARTING_TERRITORY })
    end
    local reason, conflictId = conflictsWithRegisteredBase(footprint, options)
    if not reason then
        reason, conflictId = conflictsWithSafehouse(footprint)
    end
    if not reason then
        reason, conflictId = conflictsWithCommunity(footprint, options)
    end
    if reason then
        return result(false, reason, { conflictId = conflictId })
    end
    return result(true, nil, { footprint = footprint, claimed = count })
end

function Validation.CanChange(base, current, delta, operation, expectedRevision)
    if not base then return result(false, "BASE_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= base.revision then
        return result(false, "REVISION_CONFLICT", { revision = base.revision })
    end
    delta = Validation.ProjectFootprint(delta)
    local candidate = operation == "REMOVE"
        and GridRegion.subtract(current, delta) or GridRegion.union(current, delta)
    local claimed = GridRegion.countTiles(candidate)
    if claimed <= 0 then return result(false, "EMPTY_REGION") end
    if not GridRegion.isConnected(candidate, 4) then
        return result(false, "BASE_DISCONNECTED")
    end
    local capacity = Definitions.GetTerritoryCapacity(base.hqLevel, base.barricadeCount)
    if claimed > capacity then
        return result(false, "BASE_CAPACITY_EXCEEDED", {
            claimed = claimed, capacity = capacity })
    end
    if operation == "REMOVE" and PNC.SettlementRepository then
        for facilityId, _ in pairs(base.facilityIds or {}) do
            local facility = PNC.SettlementRepository.GetFacility(facilityId)
            for componentId, _ in pairs(facility and facility.componentIds or {}) do
                local component = PNC.SettlementRepository.GetComponent(componentId)
                if component and component.kind == "anchor"
                    and not GridRegion.containsXY(candidate, component.x, component.y)
                then
                    return result(false, "OUTSIDE_BASE", { componentId = componentId })
                end
                if component and component.kind == "region"
                    and not GridRegion.containsRegion(candidate,
                        Validation.ProjectFootprint(component.region))
                then
                    return result(false, "OUTSIDE_BASE", { componentId = componentId })
                end
            end
        end
        for nodeId, _ in pairs(base.stockpileNodeIds or {}) do
            local node = PNC.SettlementRepository.GetStockpileNode(nodeId)
            if node and not GridRegion.containsXY(candidate, node.x, node.y) then
                return result(false, "OUTSIDE_BASE", { nodeId = nodeId })
            end
        end
    end
    return result(true, nil, { footprint = candidate, claimed = claimed })
end

function Validation.CanBuildBarricade(base, expectedRevision)
    if not base then return result(false, "BASE_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= base.revision then
        return result(false, "REVISION_CONFLICT", { revision = base.revision })
    end
    local rawNext = Definitions.STARTING_TERRITORY
        + (base.barricadeCount + 1) * Definitions.TILES_PER_BARRICADE
    local limit = Definitions.GetTerritoryLimit(base.hqLevel)
    if rawNext > limit then return result(false, "HQ_TERRITORY_LIMIT") end
    return result(true)
end

function Validation.CanUpgradeHQ(base, expectedRevision)
    if not base then return result(false, "BASE_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= base.revision then
        return result(false, "REVISION_CONFLICT", { revision = base.revision })
    end
    if not Definitions.GetHQLevel(base.hqLevel + 1) then
        return result(false, "MAX_LEVEL")
    end
    local technologyId = "hq:" .. tostring(base.hqLevel + 1)
    if not PNC.ResearchService
        or not PNC.ResearchService.Queries.HasTechnology(
            base.colonyId, technologyId)
    then
        return result(false, "TECHNOLOGY_REQUIRED", {
            technologyId = technologyId,
        })
    end
    return result(true)
end

return Validation
