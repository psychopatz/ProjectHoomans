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

local waterSource = Internal.waterSource
local worldWaterRetryBlocked = Internal.worldWaterRetryBlocked
local planAction = Internal.planAction
local worldWaterMovementAllowed = Internal.worldWaterMovementAllowed

Routes.Register({
    sourceRef = "world_hydration",
    needId = "hydration",
    capability = "survival.drink.world",
    IsAvailable = function(record)
        local planned, plan = planAction(record, "drink_source")
        if plan then
            return planned and not Routes.IsCampContext(record)
                and worldWaterMovementAllowed(record)
                and Routes.IsNearbyWaterAllowed(record)
                and not Routes.IsCombatActive(record)
                and not worldWaterRetryBlocked(record)
        end
        return not Routes.IsCampContext(record)
            and worldWaterMovementAllowed(record)
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
            if not worldWaterMovementAllowed(record) then
                return false, "FOLLOWING_SOURCE_WATER_NOT_ALLOWED"
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
        if not worldWaterMovementAllowed(record) then
            return false, "FOLLOWING_SOURCE_WATER_NOT_ALLOWED"
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
        if not worldWaterMovementAllowed(record, options) then
            return nil, "FOLLOWING_SOURCE_WATER_NOT_ALLOWED"
        end
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
                manualOverride = type(options) == "table"
                    and options.manualOverride == true,
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
            manualOverride = type(options) == "table"
                and options.manualOverride == true,
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
        if not worldWaterMovementAllowed(record, assignment) then
            return false, "FOLLOWING_SOURCE_WATER_NOT_ALLOWED"
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
            manualOverride = assignment.manualOverride == true,
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
                and worldWaterMovementAllowed(record, activity)
                and Routes.IsNearbyWaterAllowed(record)
                and not Routes.IsCombatActive(record)
                and (active or planned)
        end
        return not Routes.IsCampContext(record)
            and worldWaterMovementAllowed(record)
            and Routes.IsNearbyWaterAllowed(record)
            and not Routes.IsCombatActive(record)
            and not Routes.HasPersonalHydration(record)
            and not worldWaterRetryBlocked(record)
            and waterSource(record, lease.resourceKey) ~= nil
    end,
})


return Routes
