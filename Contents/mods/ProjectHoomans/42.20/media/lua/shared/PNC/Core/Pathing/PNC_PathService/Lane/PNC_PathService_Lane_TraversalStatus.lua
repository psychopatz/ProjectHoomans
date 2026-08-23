-- Public traversal-ownership query for the active movement lane.

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

local PathService = PNC.PathService

local TRAVERSAL_OWNER_MODES = {
    door_open = true,
    fence_climb = true,
    window_climb = true,
    window_open = true,
}

function PathService.IsTraversalActive(record, zombie)
    local lane = record and record.runtime and record.runtime.pathing or nil
    local modData
    local actionState
    if lane and lane.traversalAction then
        return true, lane.traversalAction.kind or lane.ownerMode or "traversal"
    end
    if lane and TRAVERSAL_OWNER_MODES[tostring(lane.ownerMode or "")] then
        return true, lane.ownerMode
    end
    modData = zombie and zombie.getModData and zombie:getModData() or nil
    if modData and modData.PNC_BumpReleasePending == true and lane and lane.lastTraversalKind then
        return true, "traversal_release"
    end
    actionState = zombie and zombie.getActionStateName and string.lower(tostring(zombie:getActionStateName() or "")) or ""
    if actionState == "climbfence" or actionState == "climbwindow" then
        return true, actionState
    end
    return false, nil
end
