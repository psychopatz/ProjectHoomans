PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local Definitions = PNC.FacilityJobDefinitions
local KIND = Internal.KIND
local JOB = Internal.JOB

local function isRemovedWaterActivity(runtime, order)
    local capability = tostring(runtime and runtime.capability
        or order and order.capability or "")
    local sceneId = tostring(runtime and runtime.sceneId
        or order and order.sceneId or "")
    local resourceKind = tostring(runtime and runtime.resourceKind or "")
    return string.sub(capability, 1, 6) == "water."
        or string.sub(sceneId, 1, 15) == "facility.water."
        or resourceKind == "nearby_water"
end

function Internal.Tick(record, zombie)
    local runtime = Internal.State(record)
    local order = record.orderSpec or {}
    local definition = Definitions.Get(order.capability)
    local previousSleep
    -- The durable order normally owns this data. If a passive group repair
    -- replaced it while the activity remained live, use the canonical order
    -- captured at activity start instead of falling through to FollowOwner.
    if order.kind ~= KIND and runtime and runtime.activityOrder then
        order = runtime.activityOrder
        definition = Definitions.Get(order.capability)
    end
    if runtime and runtime.sleepWakePending == true
        and Internal.TickSleepWake
    then
        Internal.TickSleepWake(record, zombie)
        return true
    end
    if order.kind ~= KIND or not runtime then return false end
    if not definition then
        -- A save can contain a pre-migration spigot activity. It has no
        -- executable definition after the facility provider is removed, so
        -- release it once and restore the durable follow/home/camp order.
        if isRemovedWaterActivity(runtime, order) then
            local leaseId = tostring(runtime.taskLeaseId or "")
            Internal.Finish(record, zombie, "WATER_FACILITY_REMOVED")
            if leaseId ~= "" and PNC.Tasking
                and PNC.Tasking.Commands
                and PNC.Tasking.Commands.CancelForNPC
            then
                PNC.Tasking.Commands.CancelForNPC(
                    record.id, "WATER_FACILITY_REMOVED")
            end
            return true
        end
        return false
    end
    if runtime.campActivity == true
        and tostring(runtime.capability or "") == "sleep"
    then
        previousSleep = {
            resourceKey = runtime.resourceKey or order.resourceKey,
            sleepSurface = runtime.sleepSurface or order.sleepSurface,
            x = order.x, y = order.y, z = order.z,
            interactionX = order.interactionX,
            interactionY = order.interactionY,
            interactionZ = order.interactionZ,
            sleepAnchorX = order.sleepAnchorX,
            sleepAnchorY = order.sleepAnchorY,
            sleepAnchorZ = order.sleepAnchorZ,
            sleepAxis = order.sleepAxis,
            sleepFacing = order.sleepFacing,
            sleepSprite = order.sleepSprite,
            sleepGridX = order.sleepGridX,
            sleepGridY = order.sleepGridY,
            sleepGridWidth = order.sleepGridWidth,
            sleepGridHeight = order.sleepGridHeight,
            sleepSlotId = order.sleepSlotId,
            sleepSlotIndex = order.sleepSlotIndex,
            sleepCapacity = order.sleepCapacity,
            bedCapacity = order.bedCapacity,
            object = Internal.LiveSleepObject(record, runtime),
        }
    end
    if not Internal.RefreshCampActivity(record, zombie) then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        Internal.Finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return true
    end
    if previousSleep and (Internal.SleepTargetChanged(order, runtime, previousSleep)
        or previousSleep.object ~= Internal.LiveSleepObject(record, runtime))
    then
        if runtime.animationScene
            and tostring(runtime.capability or "") == "sleep"
            and PNC.AnimationScenes
            and PNC.AnimationScenes.Interrupt
        then
            -- Do not detach a bed/sofa from a live sleep animation. Let the
            -- scene owner complete its wake transaction before a refreshed
            -- target can start a new approach.
            PNC.AnimationScenes.Interrupt(record, zombie, "movement")
            return true
        end
        if runtime.sleepSurfaceEntered == true
            or previousSleep.object ~= nil
        then
            Internal.ClearSleepSurface(record, zombie, runtime,
                previousSleep.object, previousSleep.sleepSurface)
        end
        Internal.ResetPath(record, zombie, "sleep_surface_refreshed")
        runtime.arrivalSettled = false
        runtime.positioned = false
        runtime.facingApplied = false
        runtime.sleepSurfaceEntered = false
    end
    -- Facility descriptors intentionally drop Java object references when
    -- copied into runtime/save-safe state.  Rehydrate object-backed water
    -- sources after that boundary; a stale descriptor must not make the NPC
    -- continue toward an object that can no longer be used.
    local needsWorldWaterSource = runtime.resourceKind == "world_water"
        and (not runtime.resource or not runtime.resource.object
            and not runtime.resource.item)
    local needsWaterRefillSource = runtime.resourceKind == "water_refill"
        and (not runtime.resource or not runtime.resource.object)
    if (needsWorldWaterSource or needsWaterRefillSource)
        and PNC.NearbyWaterService
    then
        local resolver = runtime.resourceKind == "water_refill"
            and PNC.NearbyWaterService.ResolveFillSource
            or PNC.NearbyWaterService.Resolve
        local resolved
        local resolveReason
        if resolver then
            resolved, resolveReason = resolver(record, runtime.resourceKey)
        end
        runtime.resource = resolved
        if not resolved then
            local leaseId = runtime.taskLeaseId
            local failure = resolveReason or "WATER_SOURCE_UNAVAILABLE"
            runtime.failedReason = failure
            Internal.DeferActivityRetry(record, runtime)
            if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands
                and PNC.Tasking.Commands.CancelForNPC
            then
                PNC.Tasking.Commands.CancelForNPC(record.id, failure)
            else
                Internal.Finish(record, zombie, failure)
            end
            return true
        end
    end
    local campSafe, campFailure = Internal.CampActivityIsSafe(
        record, zombie, runtime, order)
    if not campSafe then
        local leaseId = runtime.taskLeaseId
        Internal.ResetPath(record, zombie, "camp_activity_safety")
        runtime.failedReason = campFailure
        Internal.Finish(record, zombie, campFailure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, campFailure)
        end
        return true
    end
    record.activeJob = definition.activeJob or JOB
    record.activeBehavior = "Facility:" .. tostring(order.capability)
    if not Internal.RetryWaterApproach(record, zombie, order, runtime) then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        Internal.DeferActivityRetry(record, runtime)
        Internal.Finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return true
    end
    local shouldStart, preparedSceneId = Internal.PrepareArrival(
        record, zombie, runtime, order, definition)
    if not shouldStart then return true end
    Internal.StartScene(
        record, zombie, runtime, order, definition, preparedSceneId)
    return true
end

return Internal
