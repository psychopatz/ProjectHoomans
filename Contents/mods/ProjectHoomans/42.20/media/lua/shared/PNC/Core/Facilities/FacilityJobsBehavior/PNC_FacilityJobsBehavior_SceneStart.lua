-- Facility activity admission and animation-scene startup.
-- The tick provider delegates here after movement and interaction placement
-- are ready; all durable runtime mutations remain on the shared Internal table.

PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local Diagnostics = PNC.PerformanceScalingDiagnostics
local MAX_SCENE_START_ATTEMPTS = Internal.MAX_SCENE_START_ATTEMPTS
local WATER_RETRY_COOLDOWN_MS = 5000
local PERSONAL_FOOD_RETRY_COOLDOWN_MS = 5000

local function deferActivityRetry(record, runtime)
    local capability = tostring(runtime and runtime.capability or "")
    local foodActivity = runtime and (
        runtime.resourceKind == "personal_food"
        or capability == "food.dine"
        or capability == "survival.eat.inventory")
    if runtime and runtime.resourceKind == "world_water" then
        record.runtime.worldWaterRetryAt = Internal.CurrentTime(runtime)
            + WATER_RETRY_COOLDOWN_MS
    elseif runtime and runtime.resourceKind == "water_refill" then
        record.runtime.waterRefillRetryAt = Internal.CurrentTime(runtime)
            + WATER_RETRY_COOLDOWN_MS
    elseif runtime and runtime.resourceKind == "personal_drink" then
        record.runtime.personalDrinkRetryAt = Internal.CurrentTime(runtime)
            + WATER_RETRY_COOLDOWN_MS
    elseif foodActivity then
        record.runtime.personalFoodRetryAt = Internal.CurrentTime(runtime)
            + PERSONAL_FOOD_RETRY_COOLDOWN_MS
    end
end

Internal.DeferActivityRetry = deferActivityRetry

local function waterRefillSceneReady(record, runtime)
    local waterService = PNC.WaterContainerService
    local inventory = PNC.Inventory
    local policy = PNC.WaterHydrationPolicy
    local inv
    local item
    local description
    local freeCapacity
    if tostring(runtime and runtime.resourceKind or "") ~= "water_refill"
    then
        return true
    end
    if not policy or not policy.AllowsActivity then
        return false, "WATER_POLICY_UNAVAILABLE"
    end
    local allowed, policyReason = policy.AllowsActivity(record, runtime)
    if not allowed then return false, policyReason end
    if not inventory or not inventory.EnsureRecordInventory
        or not inventory.DescribeLiquidContainer
    then
        return true
    end
    if waterService and waterService.CanRefill then
        return waterService.CanRefill(
            record, runtime and runtime.activityItemID)
    end
    inv = inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    item = inv and inv.items
        and inv.items[tostring(runtime.activityItemID or "")] or nil
    if not item then return false, "WATER_CONTAINER_NOT_REFILLABLE" end
    description = inventory.DescribeLiquidContainer(item)
    if not description then return false, "WATER_CONTAINER_NOT_REFILLABLE" end
    freeCapacity = tonumber(description.freeCapacity)
        or (tonumber(description.capacity) or 0)
            - (tonumber(description.amount) or 0)
    if freeCapacity <= 0 then return false, "WATER_CONTAINER_FULL" end
    if description.canFill ~= true then
        return false, "WATER_CONTAINER_NOT_REFILLABLE"
    end
    return true
end

function Internal.StartScene(record, zombie, runtime, order, definition, sceneId)
    local scene = record.runtime.animationScene
    local startupNow
    local refillReady
    local refillReason
    local started
    local startReason
    if scene and scene.id == sceneId then return true end

    startupNow = Internal.CurrentTime(runtime)
    if tostring(runtime.startupSceneId or "") ~= tostring(sceneId)
        or runtime.startupStartedAt == nil
    then
        runtime.startupSceneId = sceneId
        runtime.startupStartedAt = startupNow
        runtime.startupAttempts = 0
    end
    runtime.startupAttempts = (tonumber(runtime.startupAttempts) or 0) + 1
    runtime.startupLastAttemptAt = startupNow
    runtime.phase = "STARTING"
    runtime.lastProgressAt = startupNow
    runtime.lastProgressReason = "facility_scene_starting"
    runtime.lastEffectWorldHour = PNC.NeedsUtils
        and PNC.NeedsUtils.WorldAgeHours() or nil
    if tostring(runtime.capability or "") == "sleep"
        and PNC.LiveBodyControl
        and PNC.LiveBodyControl.StabilizePresentationBody
    then
        PNC.LiveBodyControl.StabilizePresentationBody(
            record,
            zombie,
            startupNow,
            "sleep"
        )
    end
    refillReady, refillReason = waterRefillSceneReady(record, runtime)
    if not refillReady then
        local leaseId = runtime.taskLeaseId
        runtime.failedReason = refillReason
        runtime.lastProgressReason = "water_refill_scene_admission_failed"
        deferActivityRetry(record, runtime)
        if runtime.resourceKind == "water_refill"
            and PNC.NeedFacilityEffects
            and PNC.NeedFacilityEffects.ReportWaterRefillResult
        then
            PNC.NeedFacilityEffects.ReportWaterRefillResult(
                record,
                runtime,
                false,
                refillReason,
                {
                    stage = "scene_admission",
                    itemID = runtime.activityItemID,
                }
            )
        end
        Internal.Finish(record, zombie, refillReason)
        if leaseId ~= "" and PNC.TaskLeaseService
            and PNC.TaskLeaseService.Get
            and PNC.TaskLeaseService.SetPhase
        then
            local lease = PNC.TaskLeaseService.Get(leaseId)
            if lease and lease.phase == "WORKING" then
                PNC.TaskLeaseService.SetPhase(leaseId, "WAITING")
            end
        end
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands
            and PNC.Tasking.Commands.CancelForNPC
        then
            PNC.Tasking.Commands.CancelForNPC(record.id, refillReason)
        end
        return true
    end
    started, startReason = PNC.AnimationScenes.Request(record, zombie, sceneId, {
        reason = "facility_" .. tostring(order.capability),
        repeatMode = definition.completeWithScene == true
            and "once" or "loop",
    })
    if tostring(runtime.capability or "") == "sleep"
        and Diagnostics and Diagnostics.SleepAuditEnabled == true
        and Diagnostics.LogSleepState
    then
        Diagnostics.LogSleepState(
            "sleep_scene_request",
            record,
            zombie,
            record.runtime.animationScene,
            started == true and "accepted"
                or startReason or "scene_request_failed",
            {
                "requestedScene=" .. tostring(sceneId or ""),
                "accepted=" .. tostring(started == true),
                "attempt=" .. tostring(runtime.startupAttempts or 0),
                "requestReason=" .. tostring(startReason or ""),
            }
        )
    end
    if started ~= true then
        if startReason == "traversal_active" then
            -- Native window/fence passage owns the body until its bounded
            -- completion or recovery edge. Do not count the deliberately
            -- deferred drink as a scene-start failure.
            runtime.phase = "WAITING_TRAVERSAL"
            runtime.interruptReason = "traversal_active"
            runtime.startupAttempts = 0
            runtime.lastProgressAt = startupNow
            runtime.lastProgressReason =
                "facility_waiting_for_traversal"
            return true
        end
        -- Do not leave the nameplate in STARTING when scene setup fails. The
        -- next decision may retry the activity, but the failure is observable.
        runtime.phase = "INTERRUPTED"
        runtime.interruptReason = tostring(
            startReason or "scene_request_failed"
        )
        if runtime.startupAttempts >= MAX_SCENE_START_ATTEMPTS then
            local leaseId = runtime.taskLeaseId
            local failure = "FACILITY_SCENE_START_FAILED"
            runtime.failedReason = failure
            deferActivityRetry(record, runtime)
            Internal.Finish(record, zombie, failure)
            if leaseId ~= "" and PNC.Tasking
                and PNC.Tasking.Commands
                and PNC.Tasking.Commands.CancelForNPC
            then
                PNC.Tasking.Commands.CancelForNPC(record.id, failure)
            end
            return true
        end
    else
        runtime.startupAttempts = 0
        runtime.startupStartedAt = nil
        runtime.lastProgressAt = startupNow
        runtime.lastProgressReason = "facility_scene_started"
    end
    return true
end

return Internal
