-- Movement-lane schema initialization.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local Internal = PNC.PathService.Internal

function Internal.ensureMoveLane(record)
    local runtime
    local lane
    if not record then
        return nil
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    lane = runtime.pathing or {}
    runtime.pathing = lane
    Internal.ensureLaneRequestState(lane)
    Internal.ensureLaneProgressState(lane)
    Internal.ensureLaneNativeAndPresentationState(lane)
    Internal.ensureLaneTraversalAndFacingState(lane)
    return lane
end
