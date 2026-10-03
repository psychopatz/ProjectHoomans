if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Internal = Triggers.Internal
local Definitions = PNC.NeedFacilityTriggerDefinitions
local AwayRoutes = PNC.NeedFacilityAwayRoutes
local HomeRoute = PNC.NeedFacilityHomeRoute

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

Triggers.HasFacility = HomeRoute.HasFacility

local function resolveAwayRoute(record, definition)
    if not AwayRoutes.IsAwayCompanion(record)
        and HomeRoute.IsAvailable(record, definition)
    then return nil end
    return AwayRoutes.Resolve(record, definition)
end

local function hasRoute(record, definition)
    return not AwayRoutes.IsAwayCompanion(record)
        and HomeRoute.IsAvailable(record, definition)
        or resolveAwayRoute(record, definition) ~= nil
end

local function definitionFor(lease)
    local route = AwayRoutes.Get(lease and lease.sourceRef)
    return Definitions.Get(route and route.needId or lease and lease.sourceRef)
end

local function taskPhaseFor(activity, lease)
    -- Abstract execution does not run the scene state machine, so its lease
    -- phase is the authoritative phase after the provider starts it.
    if lease and tostring(lease.executionMode or "") == "ABSTRACT" then
        return lease.phase == "WORKING" and "WORKING" or "WAITING"
    end
    local phase = tostring(activity and activity.phase or "")
    if phase == "TRAVELLING" then return "TRAVEL" end
    if phase == "QUEUED" or phase == "STARTING"
        or phase == "REPATHING" or phase == "RESEATING"
        or phase == "INTERRUPTED"
    then return "WAITING" end
    return "WORKING"
end

local function manuallyDisabled(record, definition)
    return record and record.runtime
        and tostring(record.runtime.manualActivityDisabled or "")
            == tostring(definition and definition.capability or "")
end

local function campPlacementLocked(record)
    local coordinator = PNC.CampMovementCoordinator
    local runtime = record and record.runtime or nil
    local placement = runtime and runtime.campPlacement or nil
    local order = record and record.orderSpec or nil
    local state
    if coordinator and type(coordinator.IsPlacementLocked) == "function" then
        return coordinator.IsPlacementLocked(record) == true
    end
    state = placement and placement.state
        or order and order.placementState or ""
    state = string.lower(tostring(state))
    return state == "queued" or state == "moving" or state == "failed"
end


Internal.RecordFor = recordFor
Internal.ResolveAwayRoute = resolveAwayRoute
Internal.HasRoute = hasRoute
Internal.DefinitionFor = definitionFor
Internal.TaskPhaseFor = taskPhaseFor
Internal.ManuallyDisabled = manuallyDisabled
Internal.CampPlacementLocked = campPlacementLocked
Triggers.HasFacility = HomeRoute.HasFacility
