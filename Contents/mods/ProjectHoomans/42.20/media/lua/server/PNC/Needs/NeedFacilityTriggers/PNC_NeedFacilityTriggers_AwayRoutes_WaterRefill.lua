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

local waterRefillRetryBlocked = Internal.waterRefillRetryBlocked
local activityFailed = Internal.activityFailed
local waterContainer = Internal.waterContainer
local planAction = Internal.planAction
local fillableWaterSource = Internal.fillableWaterSource
local refillContext = Internal.refillContext
local restrictRefillTarget = Internal.restrictRefillTarget
local liveBody = Internal.liveBody

Routes.Register({
    sourceRef = "water_refill",
    needId = "hydration",
    capability = "survival.fill.water",
    IsAvailable = function(record)
        local context = refillContext(record)
        if not context then return false end
        local planned, plan = planAction(record, "fill_container", "refill")
        if plan then
            return planned and liveBody(record) ~= nil
                and not Routes.IsCombatActive(record)
                and not waterRefillRetryBlocked(record)
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
        local context, contextReason = refillContext(record)
        if not context then return false, contextReason end
        local planned, plan = planAction(record, "fill_container", "refill")
        if plan then
            if not liveBody(record) then return false, "NPC_BODY_UNAVAILABLE" end
            if Routes.IsCombatActive(record) then return false, "NPC_BUSY" end
            if waterRefillRetryBlocked(record) then
                return false, "WATER_REFILL_RETRY_COOLDOWN"
            end
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
    Assign = function(record, options)
        local context, contextReason = refillContext(record, options)
        if not context then return nil, contextReason end
        local planned, plan = planAction(record, "fill_container", "refill")
        if waterRefillRetryBlocked(record) then
            return nil, "WATER_REFILL_RETRY_COOLDOWN"
        end
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
            target, approaches, contextReason = restrictRefillTarget(
                record, context, plan.source, target, approaches)
            if not target then return nil, contextReason end
            return {
                ok = true,
                facilityId = "water_refill:" .. tostring(plan.sourceKey),
                componentId = "", reservationId = "",
                resourceKind = "water_refill",
                resource = plan.source, resourceKey = plan.sourceKey,
                activityItemID = plan.activityItemID,
                activityItemFullType = plan.activityItemFullType,
                target = target, approachCandidates = approaches,
                waterContextKind = context.kind,
                waterBaseId = context.baseId,
                manualOverride = context.manualOverride == true,
                executionMode = "LIVE",
            }
        end
        local item = waterContainer(record)
        local source, sourceReason = fillableWaterSource(record)
        if not item or not PNC.Inventory.IsRefillableWaterContainer(item) then
            return nil, "WATER_CONTAINER_NOT_REFILLABLE"
        end
        if not source then
            return nil, sourceReason or "WATER_FILL_SOURCE_UNAVAILABLE"
        end
        local target, approaches = PNC.NearbyWaterService.BuildApproach(
            record, source)
        if not target then return nil, approaches end
        target, approaches, contextReason = restrictRefillTarget(
            record, context, source, target, approaches)
        if not target then return nil, contextReason end
        return {
            ok = true,
            facilityId = "water_refill:" .. tostring(source.key),
            componentId = "", reservationId = "",
            resourceKind = "water_refill",
            resource = source, resourceKey = source.key,
            activityItemID = item.id, activityItemFullType = item.type,
            target = target, approachCandidates = approaches,
            waterContextKind = context.kind,
            waterBaseId = context.baseId,
            manualOverride = context.manualOverride == true,
            executionMode = "LIVE",
        }
    end,
    Start = function(record, lease, assignment)
        local policy = PNC.WaterHydrationPolicy
        if not policy or not policy.AllowsActivity then
            return false, "WATER_POLICY_UNAVAILABLE"
        end
        local allowed, reason = policy.AllowsActivity(record, assignment)
        if not allowed then return false, reason end
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
            manualOverride = assignment.manualOverride == true,
            waterContextKind = assignment.waterContextKind,
            waterBaseId = assignment.waterBaseId,
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
            if activityFailed(activity) then return false end
            if activity.completionRequested == true then
                return true
            end
            local policy = PNC.WaterHydrationPolicy
            if not policy or not policy.AllowsActivity then return false end
            local allowed = policy.AllowsActivity(record, activity)
            if not allowed then return false end
            if waterRefillRetryBlocked(record) then return false end
            return not Routes.IsCombatActive(record)
                and not Routes.HasPersonalHydration(record)
                and waterContainer(record) ~= nil
                and PNC.Inventory.IsRefillableWaterContainer(
                    waterContainer(record))
                and fillableWaterSource(record) ~= nil
        end
        local context = refillContext(record)
        if not context then return false end
        if waterRefillRetryBlocked(record) then return false end
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


return Routes
