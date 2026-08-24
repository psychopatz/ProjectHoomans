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
    if input and tonumber(order.progress) and tonumber(order.progress) > 0
        and not order.funded
        and input.funded ~= true and input.committed ~= true
        and (input.storageId == nil or input.storageId == "")
        and (input.reservationId == nil or input.reservationId == "")
    then
        -- Compatibility for a construction record compacted by an older
        -- save path. Its progress proves that the material boundary was
        -- crossed, but the old runtime reservation was not durable.
        order.funded = true
        input.funded, input.committed = true, true
        input.legacyRecovered = true
        PNC.WorkRepository.MarkDirty()
        return true
    end
    if order.funded == true or input and (input.funded == true
        or input.committed == true)
    then order.funded = true; return true end
    if input then
        if PNC.WorkInputService.IsReady(order) then return true end
        return false, "CONSTRUCTION_INPUTS_UNAVAILABLE"
    end
    if order.progress > 0 or order.createdAt then
        order.funded = true
        order.payload = order.payload or {}
        order.payload.input = { consume = true, funded = true,
            committed = true, legacyRecovered = true }
        PNC.WorkRepository.MarkDirty()
        return true
    end
    return false, "CONSTRUCTION_NOT_FUNDED"
end

return Service

