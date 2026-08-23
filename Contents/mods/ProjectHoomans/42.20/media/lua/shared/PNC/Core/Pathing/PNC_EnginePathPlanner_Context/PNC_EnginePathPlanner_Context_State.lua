PNC = PNC or {}
PNC.EnginePathPlanner = PNC.EnginePathPlanner or {}
PNC.EnginePathPlanner.Internal = PNC.EnginePathPlanner.Internal or {}

local Planner = PNC.EnginePathPlanner
local Internal = Planner.Internal

Planner.RequestBudget = Planner.RequestBudget or {
    windowStartedAt = 0,
    used = 0,
}
Planner.ActiveServerRoutes = Planner.ActiveServerRoutes or {}

function Internal.GetSquare(x, y, z)
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare then return nil end
    return cell:getGridSquare(
        math.floor(tonumber(x) or 0),
        math.floor(tonumber(y) or 0),
        math.floor(tonumber(z) or 0)
    )
end

function Internal.EnsureNavigation(record)
    if not record then return nil end
    record.runtime = record.runtime or {}
    local navigation = record.runtime.localNavigation
    if not navigation or navigation.provider ~= "engine_path" then
        navigation = {
            provider = "engine_path",
            plannedAt = 0,
            requestStartedAt = 0,
            requestPending = false,
            nativeActive = false,
            planFailures = 0,
        }
        record.runtime.localNavigation = navigation
    end
    navigation.record = record
    return navigation
end

return Internal
