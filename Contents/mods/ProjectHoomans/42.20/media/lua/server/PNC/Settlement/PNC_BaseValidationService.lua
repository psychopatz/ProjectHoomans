if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.BaseValidationService = PNC.BaseValidationService or {}

local Validation = PNC.BaseValidationService
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
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

function Validation.CanCreate(region)
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
    return result(true)
end

return Validation
