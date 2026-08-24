if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}
PNC.FacilityService.Internal = PNC.FacilityService.Internal or {}

local Service = PNC.FacilityService
local Internal = Service.Internal
local Repository = PNC.SettlementRepository
local Validation = PNC.FacilityValidationService
local Definitions = PNC.FacilityDefinitions
local Costs = PNC.FacilityCostService
local EventsBus = PsychopatzCore and PsychopatzCore.Events


local function pointFromRegion(region)
    local zKeys = {}
    for z, _ in pairs(region and region.levels or {}) do zKeys[#zKeys + 1] = z end
    table.sort(zKeys)
    for _, z in ipairs(zKeys) do
        local level = region.levels[z]
        local yKeys = {}
        for y, _ in pairs(level.rows or {}) do yKeys[#yKeys + 1] = y end
        table.sort(yKeys)
        for _, y in ipairs(yKeys) do
            local spans = level.rows[y]
            if spans and spans[1] ~= nil then
                return { x = spans[1], y = y, z = z }
            end
        end
    end
end

function Service.ResolveWorkTarget(facilityOrId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    if not facility then return nil, "FACILITY_NOT_FOUND" end
    local componentIds = {}
    for componentId, _ in pairs(facility.componentIds or {}) do
        componentIds[#componentIds + 1] = componentId
    end
    table.sort(componentIds)
    for _, componentId in ipairs(componentIds) do
        local component = Repository.GetComponent(componentId)
        if component and component.kind == "anchor" then
            return { x = component.x, y = component.y, z = component.z,
                componentId = component.id, role = component.role }
        end
    end
    for _, componentId in ipairs(componentIds) do
        local component = Repository.GetComponent(componentId)
        if component and component.kind == "region" and component.region then
            local point = pointFromRegion(component.region)
            if point then
                point.componentId, point.role = component.id, component.role
                return point
            end
        end
    end
    local point = pointFromRegion(facility.constructionRegion)
    if point then
        point.componentId, point.role = "footprint:" .. facility.id,
            "facility.footprint"
        return point
    end
    return nil, "FACILITY_HAS_NO_WORK_TARGET"
end


return Service
