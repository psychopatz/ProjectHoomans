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
local personalDrinkRetryBlocked = Internal.personalDrinkRetryBlocked
local planAction = Internal.planAction
local liveBody = Internal.liveBody

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


return Routes
