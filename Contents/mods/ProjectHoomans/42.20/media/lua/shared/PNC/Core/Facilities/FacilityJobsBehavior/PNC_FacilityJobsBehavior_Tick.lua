PNC = PNC or {}
PNC.FacilityJobsBehaviorInternal = PNC.FacilityJobsBehaviorInternal or {}

local Internal = PNC.FacilityJobsBehaviorInternal
local Definitions = PNC.FacilityJobDefinitions
local KIND = Internal.KIND
local JOB = Internal.JOB
local SEAT_STOP_DISTANCE = Internal.SEAT_STOP_DISTANCE
local SEAT_ARRIVAL_TOLERANCE = Internal.SEAT_ARRIVAL_TOLERANCE
local MAX_SCENE_START_ATTEMPTS = Internal.MAX_SCENE_START_ATTEMPTS
local Diagnostics = PNC.PerformanceScalingDiagnostics

function Internal.Tick(record, zombie)
    local order = record.orderSpec or {}
    local runtime = Internal.State(record)
    local definition = Definitions.Get(order.capability)
    local distance
    local arrivalDistance
    local moveStopDistance
    local refreshed
    local seatReason
    local targetChanged
    local previousSeatKey
    local previousSeatAnchorX
    local previousSeatAnchorY
    local previousSleep
    local positioned
    local positionReason
    local scene
    local sceneId
    local started
    local startReason
    local startupNow
    if order.kind ~= KIND or not runtime or not definition then return false end
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
    if runtime.resourceKind == "nearby_water" and not runtime.resource
        and PNC.NearbyWaterService and PNC.NearbyWaterService.Resolve
    then
        local resolved, resolveReason = PNC.NearbyWaterService.Resolve(record,
            runtime.resourceKey)
        runtime.resource = resolved
        if not resolved then
            local leaseId = runtime.taskLeaseId
            local failure = resolveReason or "WATER_SOURCE_UNAVAILABLE"
            runtime.failedReason = failure
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
        Internal.Finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return true
    end
    if runtime.seating == true and zombie then
        previousSeatKey = runtime.approachKey
        previousSeatAnchorX = runtime.seatAnchor
            and runtime.seatAnchor.x or nil
        previousSeatAnchorY = runtime.seatAnchor
            and runtime.seatAnchor.y or nil
        refreshed, seatReason, targetChanged = Internal.RefreshLiveSeatTarget(
            record, zombie, runtime, order)
        if not refreshed then
            runtime.failedReason = seatReason or "SEAT_TARGET_UNAVAILABLE"
            Internal.Finish(record, zombie, runtime.failedReason)
            return true
        end
        if targetChanged then
            if Diagnostics and Diagnostics.SeatingAuditEnabled == true
                and Diagnostics.LogSeatingAudit
            then
                Diagnostics.LogSeatingAudit("seat_anchor_changed", {
                    "npc=" .. tostring(record and record.id or ""),
                    "oldKey=" .. tostring(previousSeatKey or ""),
                    "newKey=" .. tostring(order.approachKey or ""),
                    "oldX=" .. tostring(previousSeatAnchorX or ""),
                    "oldY=" .. tostring(previousSeatAnchorY or ""),
                    "newX=" .. tostring(order.x or ""),
                    "newY=" .. tostring(order.y or ""),
                    "seatEntered=" .. tostring(runtime.seatEntered == true),
                    "bodyAction=" .. tostring(zombie.getActionStateName
                        and zombie:getActionStateName() or ""),
                })
            end
            if runtime.seatEntered == true then
                Internal.ClearFurnitureSeat(record, zombie, runtime)
            end
            Internal.ResetPath(record, zombie, "seat_anchor_refreshed")
            runtime.arrivalSettled = false
            runtime.positioned = false
            runtime.facingApplied = false
            runtime.seatEntered = false
        end
    end
    if not Internal.RetrySeatApproach(record, zombie, order, runtime) then
        local leaseId = runtime.taskLeaseId
        local failure = runtime.failedReason
        Internal.Finish(record, zombie, failure)
        if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands then
            PNC.Tasking.Commands.CancelForNPC(record.id, failure)
        end
        return true
    end
    sceneId = order.sceneId ~= "" and order.sceneId or definition.sceneId
    runtime.sceneId = sceneId
    runtime.sleepSurface = order.sleepSurface
    distance = Internal.BodyDistance(zombie, order.x, order.y)
        or PNC.Core.Distance(record.x, record.y, order.x, order.y)
    runtime.target = { x = order.x, y = order.y, z = order.z }
    runtime.distance = distance
    arrivalDistance = runtime.seating == true
        and (tonumber(runtime.seatArrivalDistance)
            or tonumber(order.arrivalDistance)
            or SEAT_ARRIVAL_TOLERANCE)
        or (tonumber(definition.arrivalDistance) or 0.85)
    moveStopDistance = runtime.seating == true
        and (tonumber(runtime.seatStopDistance)
            or tonumber(order.stopDistance)
            or SEAT_STOP_DISTANCE)
        or 0.7
    if distance > arrivalDistance
        or math.abs((tonumber(record.z) or 0) - order.z) >= 0.5
    then
        runtime.phase = "TRAVELLING"
        if runtime.taskLeaseId ~= "" and PNC.Tasking
            and PNC.Tasking.Commands
        then PNC.Tasking.Commands.SetPhase(record.id, "TRAVEL") end
        PNC.BehaviorCommon.ClearCombatTarget(record, "facility_travel", zombie)
        PNC.BehaviorCommon.MoveRecord(record, zombie, order.x, order.y, order.z,
            "walk", moveStopDistance, "facility_activity")
        return true
    end
    PNC.BehaviorCommon.ClearCombatTarget(record, "facility_working", zombie)
    if runtime.arrivalSettled ~= true then
        -- Arrival transfers movement ownership to a stationary interaction.
        -- A queued Behavior2 route otherwise remains visible to the scene
        -- safety arbiter and repeatedly interrupts/restarts the sleep bump.
        if Diagnostics and Diagnostics.SeatingAuditEnabled == true
            and Diagnostics.LogSeatingAudit
        then
            Diagnostics.LogSeatingAudit("facility_arrival", {
                "npc=" .. tostring(record and record.id or ""),
                "bodyAction=" .. tostring(zombie.getActionStateName
                    and zombie:getActionStateName() or ""),
                "pathPhase=" .. tostring(runtime.pathing
                    and runtime.pathing.phase or ""),
                "nativeActive=" .. tostring(runtime.localNavigation
                    and runtime.localNavigation.nativeActive == true),
                "seatEntered=" .. tostring(runtime.seatEntered == true),
                "positioned=" .. tostring(runtime.positioned == true),
            })
        end
        Internal.ResetPath(record, zombie, "facility_arrival")
        runtime.arrivalSettled = true
    end
    PNC.BehaviorCommon.HaltMovement(record, zombie, "facility_working")
    if runtime.seating == true and runtime.positioned ~= true then
        positioned, positionReason = Internal.PositionAtSeatAnchor(
            record, zombie, runtime, order)
        if not positioned then
            runtime.failedReason = positionReason or "SEAT_POSITION_FAILED"
            Internal.Finish(record, zombie, runtime.failedReason)
            return true
        end
    end
    if runtime.seating == true and runtime.seatEntered ~= true then
        local seated, seatReason = Internal.EnterFurnitureSeat(
            record, zombie, runtime, order)
        if not seated then
            runtime.failedReason = seatReason or "SEAT_UNAVAILABLE"
            Internal.Finish(record, zombie, runtime.failedReason)
            return true
        end
    end
    if runtime.seating ~= true and runtime.positioned ~= true and zombie
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
    end
    if runtime.facingApplied ~= true and zombie then
        local directionName = tostring(order.interactionFacing or "")
        if order.interactionAxis == "x" then directionName = "E"
        elseif order.interactionAxis == "y" then directionName = "S" end
        if directionName ~= "" and IsoDirections
            and zombie.setForwardIsoDirection
        then
            local direction = IsoDirections[directionName]
            if direction then zombie:setForwardIsoDirection(direction) end
        end
        runtime.facingApplied = true
    end
    if tostring(runtime.capability or "") == "sleep" then
        local prepared, sleepReason = Internal.PrepareSleepSurface(
            record, zombie, runtime, order)
        if not prepared then
            local leaseId = runtime.taskLeaseId
            runtime.failedReason = sleepReason or "SLEEP_SURFACE_UNAVAILABLE"
            Internal.Finish(record, zombie, runtime.failedReason)
            if leaseId ~= "" and PNC.Tasking and PNC.Tasking.Commands
                and PNC.Tasking.Commands.CancelForNPC
            then
                PNC.Tasking.Commands.CancelForNPC(record.id,
                    runtime.failedReason)
            end
            return true
        end
    end
    scene = record.runtime.animationScene
    if not scene or scene.id ~= sceneId then
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
        started, startReason = PNC.AnimationScenes.Request(record, zombie, sceneId, {
            reason = "facility_" .. tostring(order.capability),
            repeatMode = definition.completeWithScene == true
                and "once" or "loop",
        })
        if started ~= true then
            if startReason == "traversal_active" then
                -- Native window/fence passage owns the body until its
                -- bounded completion or recovery edge. Do not count the
                -- deliberately deferred drink as a scene-start failure.
                runtime.phase = "WAITING_TRAVERSAL"
                runtime.interruptReason = "traversal_active"
                runtime.startupAttempts = 0
                runtime.lastProgressAt = startupNow
                runtime.lastProgressReason =
                    "facility_waiting_for_traversal"
                return true
            end
            -- Do not leave the nameplate in STARTING when scene setup fails.
            -- The next decision may retry the activity, but the failure is
            -- now observable and cannot masquerade as a stuck preparation.
            runtime.phase = "INTERRUPTED"
            runtime.interruptReason = tostring(
                startReason or "scene_request_failed"
            )
            if runtime.startupAttempts >= MAX_SCENE_START_ATTEMPTS then
                local leaseId = runtime.taskLeaseId
                local failure = "FACILITY_SCENE_START_FAILED"
                runtime.failedReason = failure
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
    end
    return true
end

return Internal
