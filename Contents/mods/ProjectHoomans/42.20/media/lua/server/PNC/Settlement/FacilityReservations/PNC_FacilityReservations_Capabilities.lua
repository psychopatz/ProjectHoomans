if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Reservations = PNC.FacilityReservations
local H = Reservations.Internal

function H.ComponentForCapability(facility, capability)
    local jobDefinition = PNC.FacilityJobDefinitions
        and PNC.FacilityJobDefinitions.Get(capability) or nil
    local preferredRole = jobDefinition and jobDefinition.role or capability
    local fallback
    for componentId, _ in pairs(facility.componentIds or {}) do
        local component = PNC.SettlementRepository.GetComponent(componentId)
        if component and (not H.IsExclusiveComponent(component)
            or not Reservations.ByComponent[componentId])
        then
            if component.role == preferredRole then return component end
            fallback = fallback or component
        end
    end
    return fallback
end

function H.CapabilityForComponent(facility, component)
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level) or nil
    for _, capability in ipairs(level and level.capabilities or {}) do
        local definition = PNC.FacilityJobDefinitions
            and PNC.FacilityJobDefinitions.Get(capability) or nil
        if definition and definition.role == component.role then
            return capability
        end
    end
    return nil
end

function PNC.FacilityService.GetActivityCapability(facilityOrId,
    componentId)
    local facility = type(facilityOrId) == "table" and facilityOrId
        or PNC.SettlementRepository.GetFacility(facilityOrId)
    local component = componentId and PNC.SettlementRepository.GetComponent(
        componentId) or nil
    if not facility or not component
        or component.facilityId ~= facility.id
    then
        return nil
    end
    return H.CapabilityForComponent(facility, component)
end

function Reservations.HasCapacity(facility, capability)
    local resourceBinding = PNC.FacilityResources
        and PNC.FacilityResources.GetBinding
        and PNC.FacilityResources.GetBinding(facility, capability)
    if resourceBinding then
        local resources = PNC.FacilityResources.GetResources
            and PNC.FacilityResources.GetResources(facility,
                resourceBinding.detectorId) or {}
        for index = 1, #resources do
            local resource = resources[index]
            if not Reservations.ByResource[resource.resourceKey] then
                return H.HasActivityCapacity(facility.id, capability)
            end
        end
        -- A virtual resource, such as floor sleeping, supplies capacity even
        -- when a scan finds no physical furniture.
        if resourceBinding.virtual then
            return H.HasActivityCapacity(facility.id, capability)
        end
        return false
    end
    if not facility or not H.ComponentForCapability(facility, capability) then
        return false
    end
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    local limit = level and level.activityLimits
        and level.activityLimits[capability]
        and level.activityLimits[capability].maxConcurrent
    local key = facility.id .. ":" .. tostring(capability)
    return not limit
        or (tonumber(Reservations.ByActivity[key]) or 0) < limit
end

return Reservations
