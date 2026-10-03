if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC.NeedFacilityAwayRoutes = PNC.NeedFacilityAwayRoutes or {}

local Routes = PNC.NeedFacilityAwayRoutes
Routes.BySource = Routes.BySource or {}
Routes.Ordered = Routes.Ordered or {}

-- Facility activities temporarily own orderSpec, but their previousOrder is
-- the durable movement context that must remain visible to need routes.
local function routeOrder(record)
    local order = record and record.orderSpec or nil
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    if tostring(order and order.kind or "") == "facility_activity"
        and type(activity and activity.previousOrder) == "table"
    then
        return activity.previousOrder
    end
    return order or {}
end

function Routes.IsFollowing(record)
    local order = routeOrder(record)
    return tostring(order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
end

function Routes.IsCamped(record)
    local order = routeOrder(record)
    return tostring(order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_CAMP or "camp")
end

local function hasActiveCampActivity(record)
    local order = record and record.orderSpec or nil
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    return tostring(order and order.kind or "") == "facility_activity"
        and activity ~= nil and activity.campActivity == true
end

function Routes.IsCampContext(record)
    return Routes.IsCamped(record) or hasActiveCampActivity(record)
end

-- Shared eligibility seam for needs that are allowed to use temporary,
-- world-local resources. New camp activities should use this predicate rather
-- than duplicating order-kind checks in each route.
function Routes.IsAwayCompanion(record)
    return Routes.IsFollowing(record) or Routes.IsCampContext(record)
end

-- World hydration is available to any free companion. The old implementation
-- restricted this to followers/camps because it assumed residents had to use
-- the settlement water facility. With that provider removed, a resident can
-- use a valid sink, well, or other discovered world source too.
function Routes.IsNearbyWaterAllowed(record)
    local runtime = record and record.runtime or {}
    return runtime.allowNearbyWater ~= false
end

function Routes.IsCombatActive(record)
    local runtime = record and record.runtime or {}
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    local target = runtime.target
    local combatTarget = type(target) == "table" and target.kind ~= nil
    return runtime.attackAction ~= nil or runtime.combatTarget ~= nil
        or combatTarget
        or now < (tonumber(runtime.inCombatUntil) or 0)
end

function Routes.HasPersonalFood(record)
    local available
    local fullType
    local itemID
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then return false end
    available, fullType, itemID = PNC.NPCSupplyService.HasPersonalSupply(
        record, "FOOD", {
            hunger = math.max(0.001, tonumber(record and record.needs
                and record.needs.hunger) or 0.001),
            thirst = 0,
        })
    return available == true, fullType, itemID
end

function Routes.HasPersonalHydration(record)
    local water = PNC.NearbyWaterService
    if water and water.ResolveHydrationPlan then
        local plan = water.ResolveHydrationPlan(record)
        if plan and plan.action == "drink_container" then
            return true, plan.activityItemFullType, plan.activityItemID
        end
        return false
    end
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then
        return false
    end
    local current = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and PNC.IndividualNeeds.Get(record, "thirst")
        or record and record.needs and record.needs.thirst
    local available, fullType, itemID = PNC.NPCSupplyService.HasPersonalSupply(
        record, "HYDRATION", {
        hunger = 0,
        thirst = math.max(0.001, tonumber(current) or 0.001),
    })
    return available == true, fullType, itemID
end

function Routes.Register(route)
    if type(route) ~= "table" or tostring(route.sourceRef or "") == ""
        or tostring(route.needId or "") == ""
        or type(route.IsAvailable) ~= "function"
    then return false, "INVALID_AWAY_NEED_ROUTE" end
    route.sourceRef = tostring(route.sourceRef)
    route.needId = tostring(route.needId)
    if not Routes.BySource[route.sourceRef] then
        Routes.Ordered[#Routes.Ordered + 1] = route
    end
    Routes.BySource[route.sourceRef] = route
    return true, route
end

function Routes.Get(sourceRef)
    return Routes.BySource[tostring(sourceRef or "")]
end

function Routes.Resolve(record, definition)
    for _, route in ipairs(Routes.Ordered) do
        if route.needId == tostring(definition and definition.id or "")
            and route.IsAvailable(record, definition) == true
        then return route end
    end
    return nil
end

function Routes.BuildCandidate(route, record, definition, metadata)
    local suffix = route.TaskSuffix and route.TaskSuffix(record) or record.id
    return {
        taskId = route.sourceRef .. ":" .. tostring(suffix),
        npcId = tostring(record.id), kind = definition.kind,
        sourceDomain = "NeedFacility", sourceRef = route.sourceRef,
        precedence = metadata.precedence, urgency = metadata.urgency,
        capability = route.capability,
        interruptPolicy = "NORMAL", revision = 1,
    }
end

local function waterSource(record, key)
    local service = PNC.NearbyWaterService
    if not service then return nil, "NEARBY_WATER_UNAVAILABLE" end
    if service.FindWithStatus then return service.FindWithStatus(record, key) end
    if key and service.Resolve then return service.Resolve(record, key) end
    if service.Find then return service.Find(record) end
    return nil, "NEARBY_WATER_UNAVAILABLE"
end

local function worldWaterRetryBlocked(record)
    local runtime = record and record.runtime or nil
    local retryAt = tonumber(runtime and runtime.worldWaterRetryAt) or 0
    local now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    return retryAt > now
end

local function personalDrinkRetryBlocked(record)
    local runtime = record and record.runtime or nil
    local retryAt = tonumber(runtime and runtime.personalDrinkRetryAt) or 0
    local now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    return retryAt > now
end

local function personalFoodRetryBlocked(record)
    local runtime = record and record.runtime or nil
    local retryAt = tonumber(runtime and runtime.personalFoodRetryAt) or 0
    local now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    return retryAt > now
end

local function waterRefillRetryBlocked(record)
    local runtime = record and record.runtime or nil
    local retryAt = tonumber(runtime and runtime.waterRefillRetryAt) or 0
    local now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    return retryAt > now
end

local function activityFailed(activity)
    return activity ~= nil
        and (activity.failedReason ~= nil
            or activity.failureRequested == true)
end

local function waterContainer(record)
    local inventory = PNC.Inventory
    if not inventory then return nil end
    return inventory.GetWaterContainer
        and inventory.GetWaterContainer(record)
        or inventory.FindWaterContainer
        and inventory.FindWaterContainer(record)
        or nil
end

local function hydrationPlan(record, mode)
    local service = PNC.NearbyWaterService
    if not service or not service.ResolveHydrationPlan then return nil end
    return service.ResolveHydrationPlan(record, mode)
end

local function planAction(record, action, mode)
    local plan = hydrationPlan(record, mode)
    return plan and plan.action == action, plan
end

local function fillableWaterSource(record)
    local service = PNC.NearbyWaterService
    local plan = hydrationPlan(record)
    if plan and plan.action == "fill_container" then
        return plan.source, plan.source and nil
            or "WATER_FILL_SOURCE_UNAVAILABLE"
    end
    if not service or not service.FindFillSource then
        return nil, "NEARBY_WATER_UNAVAILABLE"
    end
    return service.FindFillSource(record)
end

local function campSleep(record, options)
    local service = PNC.CampResourceService
    if not service or not service.AcquireSleep then
        return nil, "CAMP_RESOURCES_UNAVAILABLE"
    end
    return service.AcquireSleep(record, options)
end

local function campWater(record, options)
    local service = PNC.CampResourceService
    if not service or not service.AcquireWater then
        return nil, "CAMP_RESOURCES_UNAVAILABLE"
    end
    return service.AcquireWater(record, options)
end

local function refillContext(record, options)
    local policy = PNC.WaterHydrationPolicy
    if not policy or not policy.GetContext then
        return nil, "WATER_POLICY_UNAVAILABLE"
    end
    return policy.GetContext(record, options)
end

local function restrictRefillTarget(record, context, source, target,
        approaches)
    local policy = PNC.WaterHydrationPolicy
    if not policy or not policy.RestrictTargets then
        return nil, nil, "WATER_POLICY_UNAVAILABLE"
    end
    return policy.RestrictTargets(record, context, source, target,
        approaches)
end

local function worldWaterMovementAllowed(record, options)
    if type(options) == "table" and options.manualOverride == true then
        return true
    end
    if not Routes.IsFollowing(record) then return true end
    local home = PNC.NeedFacilityHomeRoute
    return home and home.IsAtHome and home.IsAtHome(record) == true
end

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

Routes.Internal = Routes.Internal or {}
Routes.Internal.routeOrder = routeOrder
Routes.Internal.hasActiveCampActivity = hasActiveCampActivity
Routes.Internal.waterSource = waterSource
Routes.Internal.worldWaterRetryBlocked = worldWaterRetryBlocked
Routes.Internal.personalDrinkRetryBlocked = personalDrinkRetryBlocked
Routes.Internal.personalFoodRetryBlocked = personalFoodRetryBlocked
Routes.Internal.waterRefillRetryBlocked = waterRefillRetryBlocked
Routes.Internal.activityFailed = activityFailed
Routes.Internal.waterContainer = waterContainer
Routes.Internal.hydrationPlan = hydrationPlan
Routes.Internal.planAction = planAction
Routes.Internal.fillableWaterSource = fillableWaterSource
Routes.Internal.campSleep = campSleep
Routes.Internal.campWater = campWater
Routes.Internal.refillContext = refillContext
Routes.Internal.restrictRefillTarget = restrictRefillTarget
Routes.Internal.worldWaterMovementAllowed = worldWaterMovementAllowed
Routes.Internal.liveBody = liveBody

require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_AwayRoutes_PersonalHydration"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_AwayRoutes_WaterRefill"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_AwayRoutes_Camp"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_AwayRoutes_PersonalFood"
require "PNC/Needs/NeedFacilityTriggers/PNC_NeedFacilityTriggers_AwayRoutes_WorldWater"

return Routes
