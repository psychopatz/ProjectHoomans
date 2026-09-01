if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC.NeedFacilityAwayRoutes = PNC.NeedFacilityAwayRoutes or {}

local Routes = PNC.NeedFacilityAwayRoutes
Routes.BySource = Routes.BySource or {}
Routes.Ordered = Routes.Ordered or {}

function Routes.IsFollowing(record)
    local order = record and record.orderSpec or {}
    return tostring(order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
end

function Routes.IsCamped(record)
    local order = record and record.orderSpec or {}
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

-- Nearby-world needs are intentionally opt-in for residents. Followers and
-- camped companions may use a local source while away from the settlement; a
-- resident must use a home facility or its personal supply instead.
function Routes.IsNearbyWaterAllowed(record)
    if Routes.IsAwayCompanion(record) then return true end
    local runtime = record and record.runtime or {}
    return runtime.allowNearbyWater == true
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
    return PNC.NPCSupplyService
        and PNC.NPCSupplyService.HasPersonalSupply
        and PNC.NPCSupplyService.HasPersonalSupply(record, "FOOD", {
            hunger = math.max(0.001, tonumber(record and record.needs
                and record.needs.hunger) or 0.001),
            thirst = 0,
        }) == true
end

function Routes.HasPersonalHydration(record)
    if not PNC.NPCSupplyService
        or not PNC.NPCSupplyService.HasPersonalSupply
    then
        return false
    end
    local current = PNC.IndividualNeeds and PNC.IndividualNeeds.Get
        and PNC.IndividualNeeds.Get(record, "thirst")
        or record and record.needs and record.needs.thirst
    return PNC.NPCSupplyService.HasPersonalSupply(record, "HYDRATION", {
        hunger = 0,
        thirst = math.max(0.001, tonumber(current) or 0.001),
    }) == true
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
    capability = "water.nearby",
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
        local order = record and record.orderSpec or {}
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
        }, "water.nearby", {
            automatic = true, acquired = assignment,
            resource = assignment.resource,
            resourceKey = assignment.resourceKey,
            resourceKind = assignment.resourceKind or "nearby_water",
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
            and Routes.HasPersonalFood(record)
    end,
    Validate = function(record)
        if not Routes.IsAwayCompanion(record)
            or Routes.IsCombatActive(record)
        then
            return false, "FOLLOWER_NOT_FREE"
        end
        if not Routes.HasPersonalFood(record) then
            return false, "PERSONAL_FOOD_MISSING"
        end
        return true
    end,
    Assign = function(record)
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        return {
            ok = true,
            facilityId = "follower_food:" .. tostring(record.id),
            componentId = "", reservationId = "",
            target = {
                x = tonumber(record.x) or 0,
                y = tonumber(record.y) or 0,
                z = tonumber(record.z) or 0,
            },
            executionMode = live and "LIVE" or "ABSTRACT",
        }
    end,
    Start = function(record, lease, assignment)
        local order = record and record.orderSpec or {}
        local camped = Routes.IsCamped(record)
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "follower_food",
        }, "survival.eat.inventory", {
            automatic = true, acquired = assignment,
            resourceKind = "personal_food",
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
    end,
})

Routes.Register({
    sourceRef = "nearby_water",
    needId = "hydration",
    capability = "water.nearby",
    IsAvailable = function(record)
        return not Routes.IsCampContext(record)
            and Routes.IsNearbyWaterAllowed(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and waterSource(record) ~= nil
    end,
    TaskSuffix = function(record)
        local source = waterSource(record)
        return tostring(source and source.key or "unknown") .. ":"
            .. tostring(record.id)
    end,
    Validate = function(record)
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
        local source, sourceReason = waterSource(record)
        if not source then return false, sourceReason or "NEARBY_WATER_NOT_FOUND" end
        return true
    end,
    Assign = function(record)
        if not Routes.IsNearbyWaterAllowed(record) then
            return nil, "NEARBY_WATER_NOT_ALLOWED"
        end
        local source, sourceReason = waterSource(record)
        if not source then return nil, sourceReason or "NEARBY_WATER_NOT_FOUND" end
        local target, approaches = PNC.NearbyWaterService.BuildApproach(
            record, source)
        if not target then return nil, approaches end
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        return {
            ok = true, facilityId = "nearby_water:" .. tostring(source.key),
            componentId = "", reservationId = "",
            target = target, approachCandidates = approaches,
            resource = source, resourceKey = source.key,
            executionMode = live and "LIVE" or "ABSTRACT",
        }
    end,
    Start = function(record, lease, assignment)
        if Routes.IsCampContext(record) then
            return false, "CAMP_WATER_ROUTE_REQUIRED"
        end
        if not Routes.IsNearbyWaterAllowed(record) then
            return false, "NEARBY_WATER_NOT_ALLOWED"
        end
        local source, sourceReason = waterSource(record, assignment.resourceKey)
        if not source then return false, sourceReason or "NEARBY_WATER_NOT_FOUND" end
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "nearby_water",
        }, "water.nearby", {
            automatic = true, acquired = assignment, resource = source,
            resourceKey = source.key, resourceKind = "nearby_water",
            approachCandidates = assignment.approachCandidates,
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
        })
    end,
    CanContinue = function(record, lease)
        return not Routes.IsCampContext(record)
            and Routes.IsNearbyWaterAllowed(record)
            and not Routes.IsCombatActive(record)
            and waterSource(record, lease.resourceKey) ~= nil
    end,
})

return Routes
