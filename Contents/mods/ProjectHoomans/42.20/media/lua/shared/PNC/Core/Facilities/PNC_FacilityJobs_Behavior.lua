-- Runtime behavior for data-defined facility activities. Server services
-- acquire targets/reservations; this module owns travel, scenes, effects, and
-- interruption-safe body placement.

PNC = PNC or {}
PNC.FacilityJobs = PNC.FacilityJobs or {}

local Jobs = PNC.FacilityJobs
local Definitions = PNC.FacilityJobDefinitions
local KIND = "facility_activity"
local JOB = "FacilityActivity"

local function normalize(_, spec)
    return {
        kind = KIND,
        capability = tostring(spec.capability or ""),
        facilityId = tostring(spec.facilityId or ""),
        facilityName = tostring(spec.facilityName or spec.facilityId or "Facility"),
        componentId = tostring(spec.componentId or ""),
        componentRole = tostring(spec.componentRole or ""),
        reservationId = tostring(spec.reservationId or ""),
        x = tonumber(spec.x) or 0,
        y = tonumber(spec.y) or 0,
        z = tonumber(spec.z) or 0,
        interactionX = tonumber(spec.interactionX),
        interactionY = tonumber(spec.interactionY),
        interactionZ = tonumber(spec.interactionZ),
        interactionAxis = tostring(spec.interactionAxis or ""),
        interactionFacing = tostring(spec.interactionFacing or ""),
        sceneId = tostring(spec.sceneId or ""),
        sleepSurface = tostring(spec.sleepSurface or ""),
        taskLeaseId = tostring(spec.taskLeaseId or ""),
        resourceKind = tostring(spec.resourceKind or ""),
        resourceKey = tostring(spec.resourceKey or ""),
        debugHold = spec.debugHold == true,
    }
end

local function state(record)
    return record and record.runtime and record.runtime.facilityActivity or nil
end

local function restorePosition(record, zombie, runtime)
    if not runtime or runtime.positioned ~= true then return end
    local position = runtime.approachPosition
    if zombie and position and PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        PNC.LiveBodyControl.SetAuthoritativePosition(
            zombie, position.x, position.y, position.z)
        record.x, record.y, record.z = position.x, position.y, position.z
    end
    runtime.positioned = false
end

local function finish(record, zombie, reason)
    local runtime = state(record)
    if not runtime or runtime.finishing == true then return false end
    runtime.finishing = true
    restorePosition(record, zombie, runtime)
    if PNC.FacilityReservations and runtime.reservationId ~= ""
        and runtime.taskLeaseId == ""
    then
        PNC.FacilityReservations.Release(
            runtime.reservationId,
            reason == "rested" and "complete" or tostring(reason or "stopped"))
    end
    local previous = runtime.previousOrder
    record.runtime.facilityActivity = nil
    record.runtime.facilityDebugWork = nil
    PNC.OrderSystem.SetOrder(record, previous)
    return true
end

function Jobs.Stop(record, reason)
    local runtime = state(record)
    local zombie
    if not runtime then return false, "facility_activity_not_active" end
    zombie = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    runtime.stopRequested = true
    if record.runtime.animationScene and PNC.AnimationScenes then
        PNC.AnimationScenes.Stop(record, zombie, reason or "player_stop")
    end
    finish(record, zombie, reason or "player_stop")
    return true, "facility_activity_stopped"
end

function Jobs.OnSceneTick(record, zombie, scene, now)
    local runtime = state(record)
    local definition = runtime and Definitions.Get(runtime.capability) or nil
    local sceneId = runtime and runtime.sceneId ~= "" and runtime.sceneId
        or definition and definition.sceneId
    if not runtime or not definition or scene.id ~= sceneId then
        return false
    end
    runtime.phase = definition.activityLabel or "WORKING"
    if PNC.FacilityReservations and runtime.reservationId ~= ""
        and now >= (tonumber(runtime.nextReservationRenewAt) or 0)
    then
        PNC.FacilityReservations.Start(runtime.reservationId, 30000)
        runtime.nextReservationRenewAt = now + 10000
    end
    if runtime.taskLeaseId ~= "" and PNC.Tasking
        and PNC.Tasking.Commands and PNC.Tasking.Commands.SetPhase
    then PNC.Tasking.Commands.SetPhase(record.id, "WORKING") end
    if definition.needEffect and PNC.NeedFacilityEffects
        and PNC.NeedsUtils
    then
        local worldNow = PNC.NeedsUtils.WorldAgeHours()
        local previous = tonumber(runtime.lastEffectWorldHour) or worldNow
        local elapsed = math.max(0, math.min(0.25, worldNow - previous))
        runtime.lastEffectWorldHour = worldNow
        local ok, complete, effectReason, value =
            PNC.NeedFacilityEffects.Tick(
                record, runtime, definition, elapsed, now)
        runtime.effectValue = value
        if not ok then
            runtime.failedReason = effectReason or "NEED_EFFECT_FAILED"
            runtime.completionRequested = true
            return false
        end
        if runtime.debugHold ~= true and complete then
            runtime.completionRequested = true
            return false
        end
    end
    return true
end

function Jobs.OnSceneStopped(record, zombie, scene, reason)
    local runtime = state(record)
    if not runtime then return end
    restorePosition(record, zombie, runtime)
    runtime.arrivalSettled = false
    if runtime.stopRequested == true then return end
    if runtime.failedReason then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return
    end
    if runtime.completionRequested == true or reason == "callback_complete" then
        local leaseId = runtime.taskLeaseId
        finish(record, zombie, "complete")
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.Complete(leaseId, "NEED_COMPLETE")
        end
        return
    end
    runtime.phase = "INTERRUPTED"
    runtime.interruptReason = tostring(reason or "interrupted")
end

function Jobs.Tick(record, zombie)
    local order = record.orderSpec or {}
    local runtime = state(record)
    local definition = Definitions.Get(order.capability)
    local distance
    local scene
    local sceneId
    if order.kind ~= KIND or not runtime or not definition then return false end
    if runtime.resourceKind == "nearby_water" and not runtime.resource
        and PNC.NearbyWaterService and PNC.NearbyWaterService.Resolve
    then
        runtime.resource = PNC.NearbyWaterService.Resolve(record,
            runtime.resourceKey)
    end
    record.activeJob = definition.activeJob or JOB
    record.activeBehavior = "Facility:" .. tostring(order.capability)
    sceneId = order.sceneId ~= "" and order.sceneId or definition.sceneId
    runtime.sceneId = sceneId
    runtime.sleepSurface = order.sleepSurface
    distance = PNC.Core.Distance(record.x, record.y, order.x, order.y)
    runtime.target = { x = order.x, y = order.y, z = order.z }
    runtime.distance = distance
    if distance > (tonumber(definition.arrivalDistance) or 0.85)
        or math.abs((tonumber(record.z) or 0) - order.z) >= 0.5
    then
        runtime.phase = "TRAVELLING"
        if runtime.taskLeaseId ~= "" and PNC.Tasking
            and PNC.Tasking.Commands
        then PNC.Tasking.Commands.SetPhase(record.id, "TRAVEL") end
        PNC.BehaviorCommon.ClearCombatTarget(record, "facility_travel", zombie)
        PNC.BehaviorCommon.MoveRecord(record, zombie, order.x, order.y, order.z,
            "walk", 0.7, "facility_activity")
        return true
    end
    PNC.BehaviorCommon.ClearCombatTarget(record, "facility_working", zombie)
    if runtime.arrivalSettled ~= true then
        -- Arrival transfers movement ownership to a stationary interaction.
        -- A queued Behavior2 route otherwise remains visible to the scene
        -- safety arbiter and repeatedly interrupts/restarts the sleep bump.
        if PNC.PathService and PNC.PathService.Reset then
            if PNC.PathService.Commands
                and PNC.PathService.Commands.Reset
            then
                PNC.PathService.Commands.Reset(
                    record,
                    zombie,
                    "facility_arrival"
                )
            else
                PNC.PathService.Reset(zombie, record)
            end
        end
        runtime.arrivalSettled = true
    end
    PNC.BehaviorCommon.HaltMovement(record, zombie, "facility_working")
    if runtime.positioned ~= true and zombie
        and order.interactionX and order.interactionY
        and PNC.LiveBodyControl and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        runtime.approachPosition = {
            x = zombie:getX(), y = zombie:getY(), z = zombie:getZ(),
        }
        PNC.LiveBodyControl.SetAuthoritativePosition(zombie,
            order.interactionX, order.interactionY,
            order.interactionZ or order.z)
        record.x, record.y, record.z = order.interactionX,
            order.interactionY, order.interactionZ or order.z
        runtime.positioned = true
        local directionName = order.interactionFacing
        if order.interactionAxis == "x" then directionName = "E"
        elseif order.interactionAxis == "y" then directionName = "S" end
        if directionName ~= "" and IsoDirections
            and zombie.setForwardIsoDirection
        then
            local ok, direction = pcall(function()
                return IsoDirections[directionName]
            end)
            if ok and direction then
                pcall(zombie.setForwardIsoDirection, zombie, direction)
            end
        end
    end
    scene = record.runtime.animationScene
    if not scene or scene.id ~= sceneId then
        runtime.phase = "STARTING"
        runtime.lastEffectWorldHour = PNC.NeedsUtils
            and PNC.NeedsUtils.WorldAgeHours() or nil
        PNC.AnimationScenes.Request(record, zombie, sceneId, {
            reason = "facility_" .. tostring(order.capability),
            repeatMode = "loop",
        })
    end
    return true
end

PNC.OrderSystem.RegisterNormalizer(KIND, normalize)
PNC.JobSystem.RegisterOrder(KIND, JOB)
PNC.BehaviorRegistry.Register(JOB, Jobs.Tick)

return Jobs
