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
local calculatedState = Internal.calculatedState
local emit = Internal.emit
local updateState = Internal.updateState

function Service.ListByCapability(baseId, capability, stationId)
    local output = {}
    local requestedBaseId = tostring(baseId or "")
    local requestedStationId = tostring(stationId or "")
    for id, _ in pairs(Service.ByCapability[tostring(capability or "")] or {}) do
        local facility = Repository.GetFacility(id)
        if facility and tostring(facility.baseId or "") == requestedBaseId then
            local definition = Definitions.Get(facility.definitionId)
            local facilityStationId = definition and definition.stationId
                or facility.definitionId
            local stationMatches = requestedStationId == ""
                or tostring(facilityStationId or "") == requestedStationId
            if stationMatches then
            -- Saved facilities may still carry the cached state calculated by
            -- an older component definition (notably the retired
            -- research.room requirement). Capability discovery is the last
            -- gate before assigning a worker, so refresh the inexpensive
            -- logical state here instead of leaving valid work in limbo.
            local base = PNC.BaseService.Get(facility.baseId)
            local currentState = base and calculatedState(base, facility)
                or "INVALID_COMPONENT"
            if facility.cachedState ~= currentState then
                facility.cachedState = currentState
                Repository.MarkDirty()
            end
            local hasRequestedWorkstation = false
            if string.sub(tostring(capability or ""), 1, 5) == "work."
                and facility.constructionState == "BUILT"
            then
                for componentId, _ in pairs(facility.componentIds or {}) do
                    local component = Repository.GetComponent(componentId)
                    if component and component.role == capability then
                        hasRequestedWorkstation = true
                        break
                    end
                end
            end
            -- Workstation lanes become usable independently. A workshop with
            -- a craft station may craft while its disassembly station remains
            -- unassigned, and research benches behave the same way.
            if currentState == "OPERATIONAL" or hasRequestedWorkstation then
                output[#output + 1] = facility
            end
            end
        end
    end
    return output
end

function Service.RevalidateTargets(facilityOrId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or Repository.GetFacility(facilityOrId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then return false, "FACILITY_NOT_FOUND" end
    for componentId, _ in pairs(facility.componentIds or {}) do
        local component = Repository.GetComponent(componentId)
        local validator = component and PNC.FacilityWorldValidation
            and (component.kind == "anchor"
                and PNC.FacilityWorldValidation.ValidateAnchor
                or PNC.FacilityWorldValidation.ValidateRegion) or nil
        if validator then
            local valid, reason = validator(component)
            if valid ~= true then
                local previous = facility.cachedState
                facility.cachedState = "INVALID_COMPONENT"
                if previous ~= facility.cachedState then
                    emit(PNC.EventTypes.FACILITY_STATE_CHANGED, {
                        facilityId = facility.id, state = facility.cachedState,
                        revision = facility.revision,
                    })
                end
                return false, reason or "INVALID_TARGET", componentId
            end
        end
    end
    updateState(base, facility)
    return true, facility.cachedState
end


return Service
