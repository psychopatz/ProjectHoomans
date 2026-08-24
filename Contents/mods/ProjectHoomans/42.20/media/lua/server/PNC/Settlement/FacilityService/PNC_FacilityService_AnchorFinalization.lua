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
local emit = Internal.emit
local touch = Internal.touch
local updateState = Internal.updateState
local validationFacilityWithoutRole = Internal.validationFacilityWithoutRole

function Service.FinalizeReplaceAnchorRole(facilityId, role, anchors)
    local facility = Repository.GetFacility(facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base or not facility then return false, "FACILITY_NOT_FOUND" end
    local level = Definitions.GetLevel(facility.definitionId, facility.level)
    local limit = level and level.componentLimits and level.componentLimits[role]
    if not limit or limit.kind ~= "anchor" then
        return false, "INVALID_COMPONENT_ROLE"
    end
    anchors = type(anchors) == "table" and anchors or {}
    if #anchors < (tonumber(limit.minCount) or 0)
        or limit.maxCount and #anchors > limit.maxCount
    then return false, "FACILITY_COMPONENT_LIMIT" end
    local validationFacility = validationFacilityWithoutRole(facility, role)
    local normalized = {}
    for index, anchor in ipairs(anchors) do
        local check = Validation.NormalizeComponent(base, validationFacility, {
            id = PNC.Core.GenerateID("component"), kind = "anchor", role = role,
            x = anchor.x, y = anchor.y, z = anchor.z,
            targetResolver = role == "sleep.bed" and "sleepSpot" or nil,
        })
        if check.ok ~= true then return false, check.reason end
        normalized[index] = check.details.component
    end
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present == true and Repository.GetComponent(componentId)
        if component and component.role == role then
            facility.componentIds[componentId] = nil
            Repository.State.components[componentId] = nil
            if PNC.FacilityInteractionTargets then
                PNC.FacilityInteractionTargets.Invalidate(componentId)
            end
            if PNC.FacilityReservations then
                PNC.FacilityReservations.ReleaseComponent(componentId)
            end
        end
    end
    for _, component in ipairs(normalized) do
        Repository.State.components[component.id] = component
        facility.componentIds[component.id] = true
    end
    touch(base, facility)
    updateState(base, facility)
    Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_COMPONENT_CHANGED, {
        facilityId = facility.id, role = role, operation = "REPLACE_ROLE",
        revision = facility.revision,
    })
    facility.constructionState, facility.constructionWorkOrderId = "BUILT", nil
    Service.RefreshState(facility)
    return true, "FacilityAnchorRoleReplaced"
end


return Service
