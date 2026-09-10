local T = require "tests/support/test"

T.addPackagePaths()

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"

local function region(x1, y1, x2, y2)
    local rows = {}
    for y = y1, y2 do rows[y] = { x1, x2 } end
    return { levels = { [0] = { rows = rows } } }
end

local current = region(0, 0, 4, 4)
T.truthy(Zones.register({ id = "base-zone-anchor-smoke",
    ownerType = "projecthoomans.base", ownerId = "base-anchor-smoke",
    type = "base", geometry = current }), "base zone registration")

local facilities = {
    facility = {
        id = "facility-anchor-smoke", constructionRegion = region(0, 0, 0, 0),
        componentIds = {},
    },
    component_facility = {
        id = "facility-component-anchor-smoke",
        constructionRegion = region(1, 1, 1, 1),
        componentIds = { component = true },
    },
}
local components = {
    component = {
        id = "component-anchor-smoke", facilityId = "facility-component-anchor-smoke",
        kind = "region", role = "storage.stockpile", region = region(0, 0, 0, 0),
    },
}
local nodes = {
    node = { id = "node-anchor-smoke", x = 0, y = 0, z = 0 },
}

PNC = {
    BaseValidationService = {
        Internal = {
            Result = function(ok, reason, details)
                return { ok = ok == true, reason = reason, details = details }
            end,
        },
        ProjectFootprint = function(value) return value end,
    },
    SettlementDefinitions = {
        GetTerritoryCapacity = function() return 100 end,
    },
    SettlementRepository = {
        GetFacility = function(id) return facilities[id] end,
        GetComponent = function(id) return components[id] end,
        GetStockpileNode = function(id) return nodes[id] end,
    },
    WorkRepository = { State = { byId = {} } },
}

T.load("ProjectHoomans", "server",
    "PNC/Settlement/BaseValidationService/PNC_BaseValidationService_Territory.lua")
local Validation = PNC.BaseValidationService

local function baseWith(facilityIds, stockpileNodeIds)
    return {
        id = "base-anchor-smoke", baseZoneId = "base-zone-anchor-smoke",
        hqLevel = 1, barricadeCount = 0,
        facilityIds = facilityIds or {},
        stockpileNodeIds = stockpileNodeIds or {},
    }
end

local facilityCheck = Validation.CanChange(
    baseWith({ facility = true }), current, region(0, 0, 0, 0), "REMOVE")
T.falsy(facilityCheck.ok, "facility footprint cannot be shrunk away")
T.equal(facilityCheck.reason, "OUTSIDE_BASE", "facility anchor reason")
T.equal(facilityCheck.details.anchorType, "facility",
    "facility anchor type")

local componentCheck = Validation.CanChange(
    baseWith({ component_facility = true }), current,
    region(0, 0, 0, 0), "REMOVE")
T.falsy(componentCheck.ok, "facility component cannot be shrunk away")
T.equal(componentCheck.details.anchorType, "facility_component",
    "facility component anchor type")

local nodeCheck = Validation.CanChange(
    baseWith({}, { node = true }), current, region(0, 0, 0, 0), "REMOVE")
T.falsy(nodeCheck.ok, "storage access node cannot be shrunk away")
T.equal(nodeCheck.details.anchorType, "stockpile_node",
    "storage node anchor type")

PNC.WorkRepository.State.byId = {
    ["reconstruct-anchor-smoke"] = {
        id = "reconstruct-anchor-smoke", baseId = "base-anchor-smoke",
        operation = "RECONSTRUCT", status = "RECONSTRUCTING",
        payload = { change = { action = "set", component = {
            id = "pending-component-anchor-smoke", kind = "region",
            role = "storage.stockpile", region = region(0, 0, 0, 0),
        } } },
    },
}
local pendingCheck = Validation.CanChange(
    baseWith(), current, region(0, 0, 0, 0), "REMOVE")
T.falsy(pendingCheck.ok, "pending reconstruction footprint can be stranded")
T.equal(pendingCheck.details.anchorType, "pending_component",
    "pending reconstruction anchor type")

PNC.BuildingServiceInternal = {
    FootprintForBlueprint = function() return region(0, 0, 0, 0) end,
}
PNC.WorkRepository.State.byId = {
    ["order-anchor-smoke"] = {
        id = "order-anchor-smoke", baseId = "base-anchor-smoke",
        operation = "BUILD_OBJECT", status = "WAITING_FOR_WORKER",
        payload = { blueprint = { x = 0, y = 0, z = 0 } },
    },
}
local orderCheck = Validation.CanChange(
    baseWith(), current, region(0, 0, 0, 0), "REMOVE")
T.falsy(orderCheck.ok, "queued building footprint cannot be shrunk away")
T.equal(orderCheck.details.anchorType, "building_order",
    "queued building anchor type")

PNC.WorkRepository.State.byId["order-anchor-smoke"].status = "COMPLETED"
local completedOrderCheck = Validation.CanChange(
    baseWith(), current, region(0, 0, 0, 0), "REMOVE")
T.truthy(completedOrderCheck.ok, "completed building is no longer an anchor")

T.finish("pnc_base_territory_anchor_smoke")
