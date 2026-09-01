if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.BaseValidationService
local H = Validation.Internal
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local Definitions = PNC.SettlementDefinitions

function Validation.CanChange(base, current, delta, operation, expectedRevision)
    if not base then return H.Result(false, "BASE_NOT_FOUND") end
    if expectedRevision ~= nil and tonumber(expectedRevision) ~= base.revision then
        return H.Result(false, "REVISION_CONFLICT", { revision = base.revision })
    end
    delta = Validation.ProjectFootprint(delta)
    local candidate = operation == "REMOVE"
        and GridRegion.subtract(current, delta) or GridRegion.union(current, delta)
    local claimed = GridRegion.countTiles(candidate)
    if claimed <= 0 then return H.Result(false, "EMPTY_REGION") end
    if not GridRegion.isConnected(candidate, 4) then
        return H.Result(false, "BASE_DISCONNECTED")
    end
    local capacity = Definitions.GetTerritoryCapacity(base.hqLevel, base.barricadeCount)
    if claimed > capacity then
        return H.Result(false, "BASE_CAPACITY_EXCEEDED", {
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
                    return H.Result(false, "OUTSIDE_BASE", { componentId = componentId })
                end
                local externalStockpileRegion = facility
                    and facility.definitionId == "stockpile"
                    and component and component.role == "storage.stockpile"
                if component and component.kind == "region"
                    and not externalStockpileRegion
                    and not GridRegion.containsRegion(candidate,
                        Validation.ProjectFootprint(component.region))
                then
                    return H.Result(false, "OUTSIDE_BASE", { componentId = componentId })
                end
            end
        end
        for nodeId, _ in pairs(base.stockpileNodeIds or {}) do
            local node = PNC.SettlementRepository.GetStockpileNode(nodeId)
            if node and not GridRegion.containsXY(candidate, node.x, node.y) then
                return H.Result(false, "OUTSIDE_BASE", { nodeId = nodeId })
            end
        end
    end
    return H.Result(true, nil, { footprint = candidate, claimed = claimed })
end
