if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}
PNC.FacilityJobsServiceInternal = PNC.FacilityJobsServiceInternal or {}

local H = PNC.FacilityJobsServiceInternal

-- World hydration and container-refill route acquisition.

function H.ManualWorldWaterActivity(record, options)
    local routes = PNC.NeedFacilityAwayRoutes
    local routeId = routes and routes.IsCampContext
        and routes.IsCampContext(record) and "camp_water"
        or "world_hydration"
    local route = routes and routes.Get and routes.Get(routeId) or nil
    local assignment
    if not route or type(route.Assign) ~= "function" then
        return nil, "WORLD_WATER_NOT_FOUND"
    end
    assignment = route.Assign(record, {
        forceWorld = true,
        manualOverride = type(options) == "table"
            and options.manualOverride == true,
    })
    if not assignment then
        return nil, "WORLD_WATER_NOT_FOUND"
    end
    return assignment
end

function H.ManualWaterRefillActivity(record, options)
    local water = PNC.NearbyWaterService
    local routes = PNC.NeedFacilityAwayRoutes
    local route = routes and routes.Get and routes.Get("water_refill") or nil
    local plan
    local planReason
    local assignment
    local reason
    if not water or type(water.ResolveHydrationPlan) ~= "function" then
        return nil, "WATER_REFILL_UNAVAILABLE"
    end
    plan, planReason = water.ResolveHydrationPlan(record, "refill")
    if not plan or plan.action ~= "fill_container" then
        return nil, planReason or "WATER_CONTAINER_NOT_REFILLABLE"
    end
    if not route or type(route.Assign) ~= "function" then
        return nil, "WATER_REFILL_UNAVAILABLE"
    end
    assignment, reason = route.Assign(record, {
        manualOverride = type(options) == "table"
            and options.manualOverride == true,
    })
    if not assignment or assignment.ok ~= true then
        return nil, reason or "WATER_FILL_SOURCE_UNAVAILABLE"
    end
    return assignment
end

-- Compatibility alias for older command/debug callers. It now resolves a
-- valid world source rather than the removed settlement water facility.
H.ManualNearbyWaterActivity = H.ManualWorldWaterActivity
return H
