-- Route cleanup and invalidation API.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal

local function hasActiveNativeState(navigation)
    if not navigation then return false end
    return navigation.nativeActive == true
        or navigation.requestPending == true
        or navigation.controllerMode ~= nil
        or navigation.nativeTraversalState ~= nil
        or navigation.serverMovementLease == true
        or navigation.bodyLease ~= nil
        or (tonumber(navigation.requestStartedAt) or 0) > 0
        or (tonumber(navigation.movingStartedAt) or 0) > 0
end

function Planner.Clear(record, body)
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    if navigation and navigation.provider == "engine_path" then
        Internal.ClearEngineRequest(body or navigation.body, navigation)
    end
    if record and record.runtime then
        record.runtime.localNavigation = nil
    end
end

function Planner.Invalidate(record, reason, body)
    local navigation = record and record.runtime
        and record.runtime.localNavigation or nil
    if not navigation or navigation.provider ~= "engine_path" then
        return false
    end
    if not hasActiveNativeState(navigation) then
        navigation.plannedAt = 0
        navigation.lastPlanReason = reason or "invalidated"
        return false, "native_already_inactive"
    end
    Internal.ClearEngineRequest(body or navigation.body, navigation)
    navigation.plannedAt = 0
    navigation.lastPlanReason = reason or "invalidated"
    return true
end
