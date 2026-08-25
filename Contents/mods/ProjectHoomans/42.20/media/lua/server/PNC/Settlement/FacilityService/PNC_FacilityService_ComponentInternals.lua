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

local function isBuilt(facility)
    return facility.constructionState == nil
        or facility.constructionState == "BUILT"
end

local function validationFacilityWithoutRole(facility, role)
    local output = PNC.Core.DeepCopy(facility)
    output.componentIds = {}
    for componentId, present in pairs(facility.componentIds or {}) do
        local component = present == true
            and Repository.GetComponent(componentId) or nil
        if not component or component.role ~= role then
            output.componentIds[componentId] = present
        end
    end
    return output
end

local function applyComponent(base, facility, input)
    input = type(input) == "table" and PNC.Core.DeepCopy(input) or {}
    local existing = input.id and Repository.GetComponent(input.id) or nil
    if existing and existing.facilityId ~= facility.id then
        return { ok = false, reason = "INVALID_COMPONENT" }
    end
    input.id = tostring(input.id or PNC.Core.GenerateID("component"))
    local check = Validation.NormalizeComponent(base, facility, input)
    if not check.ok then return check end
    local component = check.details.component
    component.revision = existing and ((tonumber(existing.revision) or 0) + 1) or 0
    Repository.State.components[component.id] = component
    facility.componentIds[component.id] = true
    if PNC.FacilityInteractionTargets then
        PNC.FacilityInteractionTargets.Invalidate(component.id)
    end
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_COMPONENT_CHANGED, { facilityId = facility.id,
        componentId = component.id, operation = existing and "EDIT" or "ADD",
        revision = facility.revision })
    return { ok = true, facility = facility, component = component,
        event = existing and "FacilityComponentChanged" or "FacilityComponentAdded" }
end

local function removeComponent(base, facility, component)
    Repository.State.components[component.id] = nil
    facility.componentIds[component.id] = nil
    if PNC.FacilityInteractionTargets then
        PNC.FacilityInteractionTargets.Invalidate(component.id)
    end
    if PNC.FacilityReservations then
        PNC.FacilityReservations.ReleaseComponent(component.id)
    end
    touch(base, facility); updateState(base, facility); Service.RebuildIndexes()
    emit(PNC.EventTypes.FACILITY_COMPONENT_CHANGED, { facilityId = facility.id,
        componentId = component.id, operation = "REMOVE",
        revision = facility.revision })
    return { ok = true, facility = facility,
        event = "FacilityComponentRemoved" }
end

function Service.FinalizeSetComponent(facilityId, input)
    local facility = Repository.GetFacility(facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    local result = applyComponent(base, facility, input)
    if result.ok ~= true then return false, result.reason end
    if facility.definitionId == "stockpile" and result.component
        and result.component.role == "storage.stockpile"
        and result.component.region
    then
        facility.constructionRegion = PNC.Core.DeepCopy(result.component.region)
    end
    facility.constructionState, facility.constructionWorkOrderId = "BUILT", nil
    Service.RefreshState(facility)
    return true, result.event
end

function Service.FinalizeRemoveComponent(facilityId, componentId)
    local facility = Repository.GetFacility(facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    local component = Repository.GetComponent(componentId)
    if not base or not component or component.facilityId ~= facility.id then
        return false, "COMPONENT_NOT_FOUND"
    end
    if component.managedByFacility == true then
        return false, "FACILITY_COMPONENT_MANAGED"
    end
    if facility.definitionId == "stockpile"
        or component.role == "storage.stockpile"
    then
        return false, "STOCKPILE_CANNOT_DECONSTRUCT"
    end
    if component.role == "work.zone" then
        return false, "FACILITY_WORK_ZONE_REQUIRED"
    end
    local result = removeComponent(base, facility, component)
    facility.constructionState, facility.constructionWorkOrderId = "BUILT", nil
    Service.RefreshState(facility)
    return true, result.event
end


Internal.isBuilt = isBuilt
Internal.validationFacilityWithoutRole = validationFacilityWithoutRole
Internal.applyComponent = applyComponent
Internal.removeComponent = removeComponent

return Service
