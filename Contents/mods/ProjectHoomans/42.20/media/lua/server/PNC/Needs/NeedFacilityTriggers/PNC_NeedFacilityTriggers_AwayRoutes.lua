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

local function liveBody(record)
    return PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
end

Routes.Register({
    sourceRef = "personal_hydration",
    needId = "hydration",
    capability = "survival.drink.inventory",
    IsAvailable = function(record)
        local planned, plan = planAction(record, "drink_container")
        if plan then
            return planned and not Routes.IsCombatActive(record)
                and not personalDrinkRetryBlocked(record)
        end
        return not Routes.IsCombatActive(record)
            and not personalDrinkRetryBlocked(record)
            and Routes.HasPersonalHydration(record)
    end,
    Validate = function(record)
        local planned, plan = planAction(record, "drink_container")
        if plan then
            if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
            if personalDrinkRetryBlocked(record) then
                return false, "PERSONAL_DRINK_RETRY_COOLDOWN"
            end
            return planned, planned and nil or "PERSONAL_HYDRATION_MISSING"
        end
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if personalDrinkRetryBlocked(record) then
            return false, "PERSONAL_DRINK_RETRY_COOLDOWN"
        end
        if not Routes.HasPersonalHydration(record) then
            return false, "PERSONAL_HYDRATION_MISSING"
        end
        return true
    end,
    TaskSuffix = function(record)
        local _, plan = planAction(record, "drink_container")
        if plan and plan.activityItemID then
            return tostring(plan.activityItemID) .. ":" .. tostring(record.id)
        end
        return tostring(record and record.id or "unknown")
    end,
    Assign = function(record)
        local live = liveBody(record)
        local planned, plan = planAction(record, "drink_container")
        if plan then
            if not planned then return nil, "PERSONAL_HYDRATION_MISSING" end
            return {
                ok = true,
                facilityId = "personal_hydration:" .. tostring(record.id),
                componentId = "", reservationId = "",
                resourceKind = "personal_drink",
                activityItemID = plan.activityItemID,
                activityItemFullType = plan.activityItemFullType,
                target = {
                    x = tonumber(record.x) or 0,
                    y = tonumber(record.y) or 0,
                    z = tonumber(record.z) or 0,
                },
                executionMode = live and "LIVE" or "ABSTRACT",
            }
        end
        local available, fullType, itemID = Routes.HasPersonalHydration(record)
        if not available then return nil, "PERSONAL_HYDRATION_MISSING" end
        return {
            ok = true,
            facilityId = "personal_hydration:" .. tostring(record.id),
            componentId = "", reservationId = "",
            resourceKind = "personal_drink",
            activityItemID = itemID,
            activityItemFullType = fullType,
            target = {
                x = tonumber(record.x) or 0,
                y = tonumber(record.y) or 0,
                z = tonumber(record.z) or 0,
            },
            executionMode = live and "LIVE" or "ABSTRACT",
        }
    end,
    Start = function(record, lease, assignment)
        local order = routeOrder(record)
        local camped = Routes.IsCamped(record)
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "personal_hydration",
        }, "survival.drink.inventory", {
            automatic = true, acquired = assignment,
            resourceKind = "personal_drink",
            activityItemID = assignment.activityItemID,
            activityItemFullType = assignment.activityItemFullType,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
            campActivity = camped,
            campId = camped and order.campId or nil,
            campX = camped and order.x or nil,
            campY = camped and order.y or nil,
            campZ = camped and order.z or nil,
            campRadius = camped and order.radius or nil,
            resourceRadius = camped and order.resourceRadius or nil,
        })
    end,
    CanContinue = function(record, lease)
        local activity = record and record.runtime
            and record.runtime.facilityActivity or nil
        local active = activity
            and tostring(activity.taskLeaseId or "")
                == tostring(lease and lease.leaseId or "")
        local planned, plan = planAction(record, "drink_container")
        if plan then
            return not Routes.IsCombatActive(record)
                and (active or planned)
        end
        return not Routes.IsCombatActive(record)
            and (active or (not personalDrinkRetryBlocked(record)
                and Routes.HasPersonalHydration(record)))
    end,
})

Routes.Register({
    sourceRef = "water_refill",
    needId = "hydration",
    capability = "survival.fill.water",
    IsAvailable = function(record)
        local planned, plan = planAction(record, "fill_container", "refill")
        if plan then
            return planned and liveBody(record) ~= nil
                and not Routes.IsCombatActive(record)
        end
        local live = liveBody(record)
        local item = waterContainer(record)
        return live ~= nil
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and not waterRefillRetryBlocked(record)
            and item ~= nil
            and PNC.Inventory.IsRefillableWaterContainer(item)
            and fillableWaterSource(record) ~= nil
    end,
    Validate = function(record)
        local planned, plan = planAction(record, "fill_container", "refill")
        if plan then
            if not liveBody(record) then return false, "NPC_BODY_UNAVAILABLE" end
            if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
            return planned, planned and nil or "WATER_FILL_SOURCE_UNAVAILABLE"
        end
        local item = waterContainer(record)
        if not liveBody(record) then return false, "NPC_BODY_UNAVAILABLE" end
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if Routes.HasPersonalHydration(record) then
            return false, "PERSONAL_HYDRATION_AVAILABLE"
        end
        if waterRefillRetryBlocked(record) then
            return false, "WATER_REFILL_RETRY_COOLDOWN"
        end
        if not item or not PNC.Inventory.IsRefillableWaterContainer(item) then
            return false, "WATER_CONTAINER_NOT_REFILLABLE"
        end
        local source, reason = fillableWaterSource(record)
        if not source then return false, reason or "WATER_FILL_SOURCE_UNAVAILABLE" end
        return true
    end,
    TaskSuffix = function(record)
        local _, plan = planAction(record, "fill_container", "refill")
        if plan then
            return tostring(plan.containerID or "container") .. ":"
                .. tostring(plan.sourceKey or "source") .. ":"
                .. tostring(record.id)
        end
        local item = waterContainer(record)
        local source = fillableWaterSource(record)
        return tostring(item and item.id or "container") .. ":"
            .. tostring(source and source.key or "source") .. ":"
            .. tostring(record.id)
    end,
    Assign = function(record)
        local planned, plan = planAction(record, "fill_container", "refill")
        if plan then
            local target
            local approaches
            local live
            if not planned then
                return nil, "WATER_FILL_SOURCE_UNAVAILABLE"
            end
            live = liveBody(record)
            if not live then return nil, "NPC_BODY_UNAVAILABLE" end
            target, approaches = PNC.NearbyWaterService.BuildApproach(
                record, plan.source)
            if not target then return nil, approaches end
            return {
                ok = true,
                facilityId = "water_refill:" .. tostring(plan.sourceKey),
                componentId = "", reservationId = "",
                resourceKind = "water_refill",
                resource = plan.source, resourceKey = plan.sourceKey,
                activityItemID = plan.activityItemID,
                activityItemFullType = plan.activityItemFullType,
                target = target, approachCandidates = approaches,
                executionMode = "LIVE",
            }
        end
        local item = waterContainer(record)
        local source, sourceReason = fillableWaterSource(record)
        if not item then return nil, "WATER_CONTAINER_NOT_REFILLABLE" end
        if not source then
            return nil, sourceReason or "WATER_FILL_SOURCE_UNAVAILABLE"
        end
        local target, approaches = PNC.NearbyWaterService.BuildApproach(
            record, source)
        if not target then return nil, approaches end
        return {
            ok = true,
            facilityId = "water_refill:" .. tostring(source.key),
            componentId = "", reservationId = "",
            resourceKind = "water_refill",
            resource = source, resourceKey = source.key,
            activityItemID = item.id, activityItemFullType = item.type,
            target = target, approachCandidates = approaches,
            executionMode = "LIVE",
        }
    end,
    Start = function(record, lease, assignment)
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "water_refill",
        }, "survival.fill.water", {
            automatic = true, acquired = assignment,
            resource = assignment.resource,
            resourceKey = assignment.resourceKey,
            resourceKind = "water_refill",
            activityItemID = assignment.activityItemID,
            activityItemFullType = assignment.activityItemFullType,
            approachCandidates = assignment.approachCandidates,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = false,
        })
    end,
    CanContinue = function(record, lease)
        local activity = record and record.runtime
            and record.runtime.facilityActivity or nil
        local active = activity
            and tostring(activity.taskLeaseId or "")
                == tostring(lease and lease.leaseId or "")
        local planned, plan = planAction(record, "fill_container", "refill")
        -- An active lease is not permission to keep a stale refill alive. The
        -- destination may have become full during the delayed scene effect;
        -- let the completion/failure callback clean up, then require the
        -- current shared planner to select a new action. This prevents the
        -- full bottle from re-entering the refill scene forever.
        if active then
            if activity.completionRequested == true then
                return true
            end
            return not Routes.IsCombatActive(record)
                and not Routes.HasPersonalHydration(record)
                and waterContainer(record) ~= nil
                and PNC.Inventory.IsRefillableWaterContainer(
                    waterContainer(record))
                and fillableWaterSource(record) ~= nil
        end
        if plan then
            return not Routes.IsCombatActive(record)
                and planned
        end
        local item = waterContainer(record)
        return not Routes.IsCombatActive(record)
            and (not Routes.HasPersonalHydration(record)
                and item ~= nil
                and PNC.Inventory.IsRefillableWaterContainer(item)
                and fillableWaterSource(record) ~= nil)
    end,
})

Routes.Register({
    sourceRef = "camp_sleep",
    needId = "sleep",
    capability = "sleep",
    IsAvailable = function(record)
        return Routes.IsCamped(record)
            and not Routes.IsCombatActive(record)
            and PNC.CampResourceService ~= nil
    end,
    Validate = function(record)
        if not Routes.IsCamped(record) then return false, "NOT_CAMPED" end
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if not PNC.CampResourceService then
            return false, "CAMP_RESOURCES_UNAVAILABLE"
        end
        return true
    end,
    TaskSuffix = function(record)
        local order = record and record.orderSpec or {}
        return tostring(order.campId or record.id)
            .. ":" .. tostring(record.id)
    end,
    Assign = function(record)
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        return campSleep(record, { abstract = live == nil })
    end,
    Start = function(record, lease, assignment)
        if not Routes.IsCamped(record) then return false, "NOT_CAMPED" end
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "camp",
        }, "sleep", {
            automatic = true, acquired = assignment,
            resource = assignment.resource,
            resourceKey = assignment.resourceKey,
            resourceKind = assignment.resourceKind,
            approachCandidates = assignment.approachCandidates,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
            campActivity = true, campId = assignment.campId,
            campX = assignment.campX,
            campY = assignment.campY,
            campZ = assignment.campZ,
            campRadius = assignment.campRadius,
            resourceRadius = assignment.resourceRadius,
        })
    end,
    CanContinue = function(record)
        return Routes.IsCampContext(record) and not Routes.IsCombatActive(record)
    end,
})

Routes.Register({
    sourceRef = "camp_water",
    needId = "hydration",
    capability = "survival.drink.world",
    IsAvailable = function(record)
        local live = liveBody(record)
        return Routes.IsCamped(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and PNC.CampResourceService
            and PNC.CampResourceService.FindWater
            and PNC.CampResourceService.FindWater(record, {
                abstract = live == nil,
            }) ~= nil
    end,
    Validate = function(record)
        local live = liveBody(record)
        if not Routes.IsCampContext(record) then
            return false, "NOT_CAMPED"
        end
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if Routes.HasPersonalHydration(record) then
            return false, "PERSONAL_HYDRATION_AVAILABLE"
        end
        if not PNC.CampResourceService
            or not PNC.CampResourceService.FindWater
        then
            return false, "CAMP_RESOURCES_UNAVAILABLE"
        end
        local resource, _, _, _, reason = PNC.CampResourceService.FindWater(
            record, { abstract = live == nil })
        if not resource then return false, reason or "CAMP_WATER_UNAVAILABLE" end
        return true
    end,
    TaskSuffix = function(record)
        local live = liveBody(record)
        local resource = PNC.CampResourceService.FindWater(record, {
            abstract = live == nil,
        })
        local order = routeOrder(record)
        return tostring(order.campId or "camp") .. ":"
            .. tostring(resource and resource.resourceKey or "unknown")
            .. ":" .. tostring(record.id)
    end,
    Assign = function(record)
        local live = liveBody(record)
        return campWater(record, { abstract = live == nil })
    end,
    Start = function(record, lease, assignment)
        if not Routes.IsCampContext(record) then return false, "NOT_CAMPED" end
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "camp",
        }, "survival.drink.world", {
            automatic = true, acquired = assignment,
            resource = assignment.resource,
            resourceKey = assignment.resourceKey,
            resourceKind = assignment.resourceKind or "world_water",
            approachCandidates = assignment.approachCandidates,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
            campActivity = true, campId = assignment.campId,
            campX = assignment.campX,
            campY = assignment.campY,
            campZ = assignment.campZ,
            campRadius = assignment.campRadius,
            resourceRadius = assignment.resourceRadius,
        })
    end,
    CanContinue = function(record)
        local live = liveBody(record)
        return Routes.IsCampContext(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and PNC.CampResourceService
            and PNC.CampResourceService.FindWater
            and PNC.CampResourceService.FindWater(record, {
                abstract = live == nil,
            }) ~= nil
    end,
})

Routes.Register({
    sourceRef = "follower_food",
    needId = "hunger",
    capability = "survival.eat.inventory",
    IsAvailable = function(record)
        return Routes.IsAwayCompanion(record)
            and not Routes.IsCombatActive(record)
            and not personalFoodRetryBlocked(record)
            and Routes.HasPersonalFood(record)
    end,
    Validate = function(record)
        if not Routes.IsAwayCompanion(record)
            or Routes.IsCombatActive(record)
        then
            return false, "FOLLOWER_NOT_FREE"
        end
        if personalFoodRetryBlocked(record) then
            return false, "PERSONAL_FOOD_RETRY_COOLDOWN"
        end
        if not Routes.HasPersonalFood(record) then
            return false, "PERSONAL_FOOD_MISSING"
        end
        return true
    end,
    Assign = function(record)
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        local available, fullType, itemID = Routes.HasPersonalFood(record)
        if not available then return nil, "PERSONAL_FOOD_MISSING" end
        return {
            ok = true,
            facilityId = "follower_food:" .. tostring(record.id),
            componentId = "", reservationId = "",
            resourceKind = "personal_food",
            activityItemID = itemID,
            activityItemFullType = fullType,
            target = {
                x = tonumber(record.x) or 0,
                y = tonumber(record.y) or 0,
                z = tonumber(record.z) or 0,
            },
            executionMode = live and "LIVE" or "ABSTRACT",
        }
    end,
    Start = function(record, lease, assignment)
        local order = routeOrder(record)
        local camped = Routes.IsCamped(record)
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "follower_food",
        }, "survival.eat.inventory", {
            automatic = true, acquired = assignment,
            resourceKind = "personal_food",
            activityItemID = assignment.activityItemID,
            activityItemFullType = assignment.activityItemFullType,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
            campActivity = camped,
            campId = camped and order.campId or nil,
            campX = camped and order.x or nil,
            campY = camped and order.y or nil,
            campZ = camped and order.z or nil,
            campRadius = camped and order.radius or nil,
            resourceRadius = camped and order.resourceRadius or nil,
        })
    end,
    CanContinue = function(record)
        return Routes.IsAwayCompanion(record)
            and not Routes.IsCombatActive(record)
            and not personalFoodRetryBlocked(record)
    end,
})

Routes.Register({
    sourceRef = "world_hydration",
    needId = "hydration",
    capability = "survival.drink.world",
    IsAvailable = function(record)
        local planned, plan = planAction(record, "drink_source")
        if plan then
            return planned and not Routes.IsCampContext(record)
                and Routes.IsNearbyWaterAllowed(record)
                and not Routes.IsCombatActive(record)
                and not worldWaterRetryBlocked(record)
        end
        return not Routes.IsCampContext(record)
            and Routes.IsNearbyWaterAllowed(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and not worldWaterRetryBlocked(record)
            and waterSource(record) ~= nil
    end,
    TaskSuffix = function(record)
        local _, plan = planAction(record, "drink_source")
        if plan then
            return tostring(plan.sourceKey or "unknown") .. ":"
                .. tostring(record.id)
        end
        local source = waterSource(record)
        return tostring(source and source.key or "unknown") .. ":"
            .. tostring(record.id)
    end,
    Validate = function(record)
        local planned, plan = planAction(record, "drink_source")
        if plan then
            if Routes.IsCampContext(record) then
                return false, "CAMP_WATER_ROUTE_REQUIRED"
            end
            if not Routes.IsNearbyWaterAllowed(record) then
                return false, "NEARBY_WATER_NOT_ALLOWED"
            end
            if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
            if worldWaterRetryBlocked(record) then
                return false, "WORLD_WATER_RETRY_COOLDOWN"
            end
            return planned, planned and nil or "NEARBY_WATER_NOT_FOUND"
        end
        if Routes.IsCampContext(record) then
            return false, "CAMP_WATER_ROUTE_REQUIRED"
        end
        if not Routes.IsNearbyWaterAllowed(record) then
            return false, "NEARBY_WATER_NOT_ALLOWED"
        end
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if Routes.HasPersonalHydration(record) then
            return false, "PERSONAL_HYDRATION_AVAILABLE"
        end
        if worldWaterRetryBlocked(record) then
            return false, "WORLD_WATER_RETRY_COOLDOWN"
        end
        local source, sourceReason = waterSource(record)
        if not source then return false, sourceReason or "NEARBY_WATER_NOT_FOUND" end
        return true
    end,
    Assign = function(record, options)
        local planned
        local plan
        if not (type(options) == "table" and options.forceWorld == true) then
            planned, plan = planAction(record, "drink_source")
        end
        if plan then
            local target
            local approaches
            local live
            if not planned then return nil, "NEARBY_WATER_NOT_FOUND" end
            target, approaches = PNC.NearbyWaterService.BuildApproach(
                record, plan.source)
            if not target then return nil, approaches end
            live = PNC.Registry and PNC.Registry.GetLiveZombie
                and PNC.Registry.GetLiveZombie(record.id) or nil
            return {
                ok = true,
                facilityId = "world_water:" .. tostring(plan.sourceKey),
                componentId = "", reservationId = "",
                resourceKind = "world_water",
                target = target, approachCandidates = approaches,
                resource = plan.source, resourceKey = plan.sourceKey,
                executionMode = live and "LIVE" or "ABSTRACT",
            }
        end
        if not Routes.IsNearbyWaterAllowed(record) then
            return nil, "NEARBY_WATER_NOT_ALLOWED"
        end
        if worldWaterRetryBlocked(record) then
            return nil, "WORLD_WATER_RETRY_COOLDOWN"
        end
        local source, sourceReason = waterSource(record)
        if not source then return nil, sourceReason or "NEARBY_WATER_NOT_FOUND" end
        local target, approaches = PNC.NearbyWaterService.BuildApproach(
            record, source)
        if not target then return nil, approaches end
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        return {
            ok = true, facilityId = "world_water:" .. tostring(source.key),
            componentId = "", reservationId = "",
            resourceKind = "world_water",
            target = target, approachCandidates = approaches,
            resource = source, resourceKey = source.key,
            executionMode = live and "LIVE" or "ABSTRACT",
        }
    end,
    Start = function(record, lease, assignment)
        local source = assignment.resource
        local sourceReason
        if Routes.IsCampContext(record) then
            return false, "CAMP_WATER_ROUTE_REQUIRED"
        end
        if not Routes.IsNearbyWaterAllowed(record) then
            return false, "NEARBY_WATER_NOT_ALLOWED"
        end
        if not source then
            source, sourceReason = waterSource(record, assignment.resourceKey)
        end
        if not source then return false, sourceReason or "NEARBY_WATER_NOT_FOUND" end
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "world_water",
        }, "survival.drink.world", {
            automatic = true, acquired = assignment, resource = source,
            resourceKey = source.key, resourceKind = "world_water",
            approachCandidates = assignment.approachCandidates,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
        })
    end,
    CanContinue = function(record, lease)
        local planned, plan = planAction(record, "drink_source")
        if plan then
            local activity = record and record.runtime
                and record.runtime.facilityActivity or nil
            local active = activity
                and tostring(activity.taskLeaseId or "")
                    == tostring(lease and lease.leaseId or "")
            return not Routes.IsCampContext(record)
                and Routes.IsNearbyWaterAllowed(record)
                and not Routes.IsCombatActive(record)
                and (active or planned)
        end
        return not Routes.IsCampContext(record)
            and Routes.IsNearbyWaterAllowed(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and not worldWaterRetryBlocked(record)
            and waterSource(record, lease.resourceKey) ~= nil
    end,
})

return Routes
