if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConstructionService = PNC.ConstructionService or {}
PNC.ConstructionService.Internal =
    PNC.ConstructionService.Internal or {}

local Service = PNC.ConstructionService
local Internal = Service.Internal
Internal.LifecycleInternal = Internal.LifecycleInternal or {}
local H = Internal.LifecycleInternal

function Internal.Prepare(order)
    if order.operation ~= "CONSTRUCT" and order.operation ~= "RECONSTRUCT" then
        return true
    end
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    local expectedState = order.operation == "CONSTRUCT"
        and "UNDER_CONSTRUCTION" or "RECONSTRUCTING"
    if facility and (facility.constructionState ~= expectedState
        or tostring(facility.constructionWorkOrderId or "") ~= order.id)
    then
        facility.constructionState = expectedState
        facility.constructionWorkOrderId = order.id
        PNC.FacilityService.RefreshState(facility)
    end
    local input = order.payload and order.payload.input or nil
    if order.funded == true or input and (input.funded == true
        or input.committed == true)
    then order.funded = true; return true end
    -- A reconstruction that carries no input payload is a structural change
    -- with no material boundary (for example an empty test/edit operation).
    -- It remains runnable without treating an old, compacted save as funded.
    if not input and order.operation == "RECONSTRUCT" then
        order.funded = true
        return true
    end
    if input then
        if PNC.WorkInputService.IsReady(order) then return true end
        return false, "CONSTRUCTION_INPUTS_UNAVAILABLE"
    end
    return false, "CONSTRUCTION_NOT_FUNDED"
end

return Service
