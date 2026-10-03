if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Routes = PNC and PNC.NeedFacilityAwayRoutes
if not Routes then
    return
end

local Internal = Routes.Internal
if not Internal then
    return
end

local routeOrder = Internal.routeOrder
local personalFoodRetryBlocked = Internal.personalFoodRetryBlocked

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
        local order = routeOrder(record)
        local camped = Routes.IsCamped(record)
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
                -- A camped NPC eats at its assigned room anchor. A follower
                -- that has no camp keeps the existing current-position
                -- behavior, so this route remains useful outside camps.
                x = camped and (tonumber(order.x) or tonumber(record.x) or 0)
                    or tonumber(record.x) or 0,
                y = camped and (tonumber(order.y) or tonumber(record.y) or 0)
                    or tonumber(record.y) or 0,
                z = camped and (tonumber(order.z) or tonumber(record.z) or 0)
                    or tonumber(record.z) or 0,
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


return Routes
