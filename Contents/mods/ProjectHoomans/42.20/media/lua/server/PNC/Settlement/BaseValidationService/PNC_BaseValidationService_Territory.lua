if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.BaseValidationService
local H = Validation.Internal
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local Definitions = PNC.SettlementDefinitions

local function pointRegion(x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return nil end
    return { levels = { [z] = { rows = { [y] = { x, x } } } } }
end

local function activeOrder(order)
    local status = tostring(order and order.status or "")
    return status ~= "COMPLETED" and status ~= "CANCELLED"
        and status ~= "FAILED"
end

local function buildingOrderFootprint(order)
    local building = PNC.BuildingServiceInternal
    local payload = order and order.payload or nil
    local blueprint = payload and payload.blueprint or nil
    if not building or type(building.FootprintForBlueprint) ~= "function"
        or not blueprint
    then return nil end
    return building.FootprintForBlueprint(blueprint)
end

local function pendingComponentRegion(component)
    if type(component) ~= "table" then return nil end
    if component.kind == "anchor" then
        return pointRegion(component.x, component.y, component.z)
    end
    return component.occupiedRegion or component.region
end

local function anchor(anchors, anchorType, anchorID, role, region)
    if type(region) ~= "table"
        or GridRegion.countTiles(region) <= 0
    then return end
    anchors[#anchors + 1] = {
        type = anchorType,
        id = anchorID,
        role = role,
        region = Validation.ProjectFootprint(region),
    }
end

-- Returns the durable world footprint that a base territory must continue to
-- contain. This is intentionally derived from server records rather than the
-- client snapshot so shrink decisions cannot strand a facility or stockpile.
function Validation.RequiredAnchors(base)
    local anchors = {}
    local repository = PNC.SettlementRepository
    if not base or not repository then return anchors end

    for facilityID, _ in pairs(base.facilityIds or {}) do
        local facility = repository.GetFacility(facilityID)
        if facility then
            anchor(anchors, "facility", facility.id, "facility.footprint",
                facility.constructionRegion)
            for componentID, _ in pairs(facility.componentIds or {}) do
                local component = repository.GetComponent(componentID)
                if component then
                    local region = component.kind == "anchor"
                        and pointRegion(component.x, component.y, component.z)
                        or component.occupiedRegion or component.region
                    anchor(anchors, "facility_component", component.id,
                        component.role, region)
                end
            end
        end
    end

    for nodeID, _ in pairs(base.stockpileNodeIds or {}) do
        local node = repository.GetStockpileNode(nodeID)
        if node then
            anchor(anchors, "stockpile_node", node.id, "storage.access",
                pointRegion(node.x, node.y, node.z))
        end
    end

    local work = PNC.WorkRepository
    for orderID, order in pairs(work and work.State
        and work.State.byId or {}) do
        local sameBase = tostring(order.baseId or "")
            == tostring(base.id or "")
        if activeOrder(order) and sameBase
            and order.operation == "BUILD_OBJECT" then
            anchor(anchors, "building_order", orderID, "building.footprint",
                buildingOrderFootprint(order))
        end
        if activeOrder(order) and sameBase
            and order.operation == "RECONSTRUCT" then
            local payload = order.payload or {}
            local change = payload.change or {}
            if change.action == "set" and change.component then
                local component = change.component
                anchor(anchors, "pending_component",
                    component.id or orderID, component.role,
                    pendingComponentRegion(component))
            elseif change.action == "replace_role"
                and type(change.anchors) == "table"
            then
                for index, component in ipairs(change.anchors) do
                    anchor(anchors, "pending_component",
                        tostring(orderID) .. ":" .. tostring(index),
                        change.role, pointRegion(component.x, component.y,
                            component.z))
                end
            end
        end
    end
    return anchors
end

function Validation.RequiredFootprint(base)
    local footprint = { levels = {} }
    for _, required in ipairs(Validation.RequiredAnchors(base)) do
        footprint = GridRegion.union(footprint, required.region)
    end
    return footprint
end

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
    if operation == "REMOVE" then
        for _, required in ipairs(Validation.RequiredAnchors(base)) do
            if not GridRegion.containsRegion(candidate, required.region) then
                return H.Result(false, "OUTSIDE_BASE", {
                    anchorType = required.type,
                    anchorId = required.id,
                    role = required.role,
                })
            end
        end
    end
    return H.Result(true, nil, { footprint = candidate, claimed = claimed })
end
