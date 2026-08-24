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

function H.ResetFacility(order, state)
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    if facility then
        facility.constructionState = state
        facility.constructionWorkOrderId = nil
        PNC.FacilityService.RefreshState(facility)
    end
end

function H.CancelBuild(order)
    local refunded, refundOrReason = H.RefundConstruction(order)
    if not refunded then return false, refundOrReason end
    local released, releaseReason = PNC.WorkInputService.Cancel(order)
    if released == false then return false, releaseReason end
    H.ResetFacility(order, "PLANNED")
    return true, refundOrReason
end

function H.CancelDeconstruct(order)
    H.ResetFacility(order, order.payload.previousConstructionState or "BUILT")
    return true
end

function H.CancelReconstruct(order)
    local change = order.payload and order.payload.change or {}
    if change.action ~= "remove" then
        local refunded, refundOrReason = H.RefundConstruction(order)
        if not refunded then return false, refundOrReason end
    end
    local released, releaseReason = PNC.WorkInputService.Cancel(order)
    if released == false then return false, releaseReason end
    H.ResetFacility(order, "BUILT")
    return true
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.CONSTRUCT = H.CancelBuild
PNC.WorkService.CancellationHandlers.RECONSTRUCT = H.CancelReconstruct
PNC.WorkService.CancellationHandlers.DECONSTRUCT = H.CancelDeconstruct
PNC.WorkService.RegisterTargetProvider("CONSTRUCT", Internal.ResolveTarget)
PNC.WorkService.RegisterTargetProvider("RECONSTRUCT", Internal.ResolveTarget)
PNC.WorkService.RegisterTargetProvider("DECONSTRUCT", Internal.ResolveTarget)
PNC.WorkService.RegisterPreparation("CONSTRUCT", Internal.Prepare)
PNC.WorkService.RegisterPreparation("RECONSTRUCT", Internal.Prepare)
PNC.WorkService.RegisterCompletion("CONSTRUCT", H.CompleteBuild)
PNC.WorkService.RegisterCompletion("RECONSTRUCT", H.CompleteReconstruct)
PNC.WorkService.RegisterCompletion("DECONSTRUCT", H.CompleteDeconstruct)

return Service
