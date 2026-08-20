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

function Routes.IsCombatActive(record)
    local runtime = record and record.runtime or {}
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    return runtime.attackAction ~= nil or runtime.target ~= nil
        or now < (tonumber(runtime.inCombatUntil) or 0)
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

Routes.Register({
    sourceRef = "follower_food",
    needId = "hunger",
    capability = "survival.eat.inventory",
    IsAvailable = function(record)
        return Routes.IsFollowing(record) and not Routes.IsCombatActive(record)
    end,
    Validate = function(record)
        if not Routes.IsFollowing(record) or Routes.IsCombatActive(record) then
            return false, "FOLLOWER_NOT_FREE"
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
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "nearby",
            definitionId = "follower_food",
        }, "survival.eat.inventory", {
            automatic = true, acquired = assignment,
            resourceKind = "personal_food",
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
        })
    end,
    CanContinue = function(record)
        return Routes.IsFollowing(record) and not Routes.IsCombatActive(record)
    end,
})

Routes.Register({
    sourceRef = "nearby_water",
    needId = "hydration",
    capability = "water.nearby",
    IsAvailable = function(record)
        return not Routes.IsCombatActive(record)
            and PNC.NearbyWaterService and PNC.NearbyWaterService.Find
            and PNC.NearbyWaterService.Find(record) ~= nil
    end,
    TaskSuffix = function(record)
        local source = PNC.NearbyWaterService.Find(record)
        return tostring(source and source.key or "unknown") .. ":"
            .. tostring(record.id)
    end,
    Validate = function(record)
        if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
        if not PNC.NearbyWaterService or not PNC.NearbyWaterService.Find
            or not PNC.NearbyWaterService.Find(record)
        then return false, "NEARBY_WATER_NOT_FOUND" end
        return true
    end,
    Assign = function(record)
        local source = PNC.NearbyWaterService
            and PNC.NearbyWaterService.Find(record) or nil
        if not source then return nil, "NEARBY_WATER_NOT_FOUND" end
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
        local source = PNC.NearbyWaterService
            and PNC.NearbyWaterService.Resolve(record, assignment.resourceKey)
            or nil
        if not source then return false, "NEARBY_WATER_NOT_FOUND" end
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
        return not Routes.IsCombatActive(record)
            and PNC.NearbyWaterService and PNC.NearbyWaterService.Resolve
            and PNC.NearbyWaterService.Resolve(record, lease.resourceKey) ~= nil
    end,
})

return Routes
