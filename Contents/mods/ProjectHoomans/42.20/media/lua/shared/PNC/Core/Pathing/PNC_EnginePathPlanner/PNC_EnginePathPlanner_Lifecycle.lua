-- Route cleanup and invalidation API.

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal

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
    Internal.ClearEngineRequest(body or navigation.body, navigation)
    navigation.plannedAt = 0
    navigation.lastPlanReason = reason or "invalidated"
    return true
end
