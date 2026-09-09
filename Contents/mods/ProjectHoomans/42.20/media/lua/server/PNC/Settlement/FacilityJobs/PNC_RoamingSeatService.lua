-- Runtime-only seating for live NPCs that retain a durable roam order.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RoamingSeat = PNC.RoamingSeat or {}

local Service = PNC.RoamingSeat
local Core = PNC.Core
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon
local Jobs = PNC.FacilityJobs
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Reservations = PNC.FacilityReservations
local Targeting = PNC.BehaviorTargeting
local Combat = PNC.BehaviorCombat

Service.NextAttemptAt = Service.NextAttemptAt or {}
Service.CADENCE_MS = 5000
Service.MIN_IDLE_MS = 1200
Service.SEARCH_RADIUS = 6
Service.MAX_OBJECTS = 96
Service.MAX_ATTEMPTS_PER_TICK = 4
Service.SEAT_MIN_MS = 30000
Service.SEAT_MAX_MS = 90000
Service.POST_SEAT_DWELL_MIN_MS = 20000
Service.POST_SEAT_DWELL_MAX_MS = 45000

local SCENE_ID = "ambient.roam.sitFurniture"
local AMBIENT_FACILITY_ID = "ambient:roam"
local RESERVATION_PURPOSE = "ambient_roam_seat"

local function currentTime(value)
    return tonumber(value) or Core.Now()
end

local function isRoamOrder(record)
    local kind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    return kind == tostring(Const.ORDER_ROAM or "roam")
end

local function eachObject(square, visitor)
    local objects = square and square.getObjects
        and square:getObjects() or nil
    if not objects then return end
    if objects.size and objects.get then
        for index = 0, objects:size() - 1 do
            visitor(objects:get(index), index)
        end
        return
    end
    for index = 1, #objects do visitor(objects[index], index) end
end

local function isReserved(resource)
    local key = tostring(resource and resource.resourceKey or "")
    return key ~= "" and Reservations and Reservations.ByResource
        and Reservations.ByResource[key] ~= nil
end

local function distanceTo(zombie, x, y)
    return Core.Distance(zombie:getX(), zombie:getY(), x, y)
end

local function hasActivePath(record)
    local runtime = record and record.runtime or nil
    local pathing = runtime and runtime.pathing or nil
    local navigation = runtime and runtime.localNavigation or nil
    if pathing and (
        pathing.traversalAction ~= nil
            or pathing.vanillaFenceAction ~= nil
            or pathing.blockedStepToX ~= nil
            or pathing.phase == "requested"
            or pathing.phase == "active"
            or pathing.phase == "blocked"
    ) then
        return true
    end
    return navigation and navigation.nativeActive == true or false
end

local function canAttempt(record, zombie, roaming, at)
    local runtime = record and record.runtime or nil
    local target = runtime and runtime.target or nil
    if not Core.IsAuthority() or not record or not zombie
        or record.alive == false or not isRoamOrder(record)
        or not roaming or roaming.phase ~= "idle"
    then
        return false
    end
    if at < (tonumber(roaming.idleSince) or at) + Service.MIN_IDLE_MS then
        return false
    end
    if at < (tonumber(roaming.seatCooldownUntil) or 0) then
        return false
    end
    if runtime and (runtime.facilityActivity or runtime.workOrderId
        or runtime.attackAction or runtime.combatTarget
        or at < (tonumber(runtime.inCombatUntil) or 0))
    then
        return false
    end
    if type(target) == "table" and target.kind ~= nil then return false end
    return runtime.animationScene == nil and not hasActivePath(record)
end

local function findSeat(zombie)
    local cell = type(getCell) == "function" and getCell() or nil
    local detector = Resources and Resources.GetDetector
        and Resources.GetDetector("seat") or nil
    local originX = math.floor(zombie:getX())
    local originY = math.floor(zombie:getY())
    local originZ = math.floor(zombie:getZ())
    local best
    local bestDistance
    local examined = 0
    if not cell or not cell.getGridSquare or not detector
        or type(detector.matches) ~= "function"
        or type(detector.describe) ~= "function"
        or not Targets or not Targets.ResolveResource
    then
        return nil
    end
    for dx = -Service.SEARCH_RADIUS, Service.SEARCH_RADIUS do
        for dy = -Service.SEARCH_RADIUS, Service.SEARCH_RADIUS do
            if dx * dx + dy * dy <= Service.SEARCH_RADIUS
                * Service.SEARCH_RADIUS
            then
                local square = cell:getGridSquare(
                    originX + dx, originY + dy, originZ)
                eachObject(square, function(object, objectIndex)
                    local resource
                    local targets
                    local target
                    local distance
                    if examined >= Service.MAX_OBJECTS then return end
                    examined = examined + 1
                    if detector.matches(square, object) ~= true then return end
                    resource = detector.describe(square, object, {
                        objectIndex = objectIndex,
                        character = zombie,
                    })
                    if type(resource) ~= "table"
                        or isReserved(resource)
                    then
                        return
                    end
                    targets = Targets.ResolveResource(resource, {
                        abstract = false, character = zombie,
                    })
                    target = targets and targets[1] or nil
                    if not target or target.validSpot == false then return end
                    distance = distanceTo(zombie, target.x, target.y)
                    if not bestDistance or distance < bestDistance then
                        bestDistance = distance
                        best = {
                            object = object,
                            resource = resource,
                            target = target,
                            targets = targets,
                        }
                    end
                end)
            end
        end
    end
    return best
end

local function release(state, reason)
    local id = tostring(state and state.reservationId or "")
    if id ~= "" and Reservations and Reservations.Release then
        Reservations.Release(id, reason or "roaming_seat_stopped")
    end
    if state then state.reservationId = nil end
end

local function resetRoam(record, preserveIdleDwell)
    local roaming = record.runtime and record.runtime.roaming or nil
    local at
    local dwellUntil
    if not roaming then return end
    if preserveIdleDwell == true then
        at = currentTime()
        dwellUntil = math.max(
            tonumber(roaming.waitUntil) or 0,
            at + Service.POST_SEAT_DWELL_MIN_MS
                + ZombRand(Service.POST_SEAT_DWELL_MAX_MS
                    - Service.POST_SEAT_DWELL_MIN_MS + 1)
        )
        roaming.waitUntil = dwellUntil
        roaming.idleSince = at
        roaming.seatCooldownUntil = dwellUntil
        roaming.phase = "idle"
    else
        roaming.waitUntil = nil
        roaming.idleSince = nil
        roaming.seatCooldownUntil = nil
        roaming.phase = nil
    end
    roaming.pausePending = nil
    roaming.goalX, roaming.goalY, roaming.goalZ = nil, nil, nil
end

local function finish(record, zombie, reason, preserveIdleDwell)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local seating = Jobs and Jobs.Seating
    if not state or state.finishing == true then return false end
    state.finishing = true
    if seating and seating.ClearFurnitureSeat then
        seating.ClearFurnitureSeat(record, zombie, state)
    end
    if seating and seating.RestorePosition then
        seating.RestorePosition(record, zombie, state)
    end
    if seating and seating.ResetPath then
        seating.ResetPath(record, zombie, reason or "roaming_seat_stopped")
    end
    release(state, reason)
    if PNC.SeatingRuntime and PNC.SeatingRuntime.LiveObjects then
        PNC.SeatingRuntime.LiveObjects[tostring(record.id)] = nil
    end
    runtime.roamingSeat = nil
    resetRoam(record, preserveIdleDwell ~= false)
    Service.NextAttemptAt[tostring(record.id)] =
        currentTime() + Service.CADENCE_MS
    return true
end

local function stop(record, zombie, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local scene = runtime and runtime.animationScene or nil
    local internal
    if not state then return false end
    state.stopRequested = true
    if scene and scene.id == SCENE_ID
        and PNC.AnimationScenes and PNC.AnimationScenes.Interrupt
    then
        PNC.AnimationScenes.Interrupt(record, zombie, "movement")
        if runtime.animationScene
            and PNC.AnimationScenes.Internal
            and PNC.AnimationScenes.Internal.ClearScene
        then
            internal = PNC.AnimationScenes.Internal
            internal.ClearScene(record, zombie, "roaming_seat_stop", true)
        end
    end
    return finish(record, zombie, reason or "roaming_seat_stopped")
end

local function handleThreat(record, zombie, state, at)
    local runtime = record and record.runtime or nil
    local radius = tonumber(record.orderSpec and record.orderSpec.targetRadius)
        or tonumber(Const.ROAM_TARGET_RADIUS) or 3
    local target
    if runtime and runtime.target and runtime.target.kind then
        target = runtime.target
    elseif at >= (tonumber(state.nextThreatScanAt) or 0)
        and Targeting and Targeting.ResolveRoamingEngageTarget
    then
        state.nextThreatScanAt = at + 250
        target = Targeting.ResolveRoamingEngageTarget(record, radius)
    end
    if not target then return false end
    finish(record, zombie, "roaming_seat_threat", false)
    record.runtime.target = target
    record.activeBehavior = "Roam:seat:combat"
    if Combat and Combat.TickEngage then
        Combat.TickEngage(record, zombie, target)
    end
    return true
end

function Service.TryStart(record, zombie, order, roaming, at)
    local id = tostring(record and record.id or "")
    local candidate
    local ok
    local reservation
    local runtime
    local state
    at = currentTime(at)
    if not canAttempt(record, zombie, roaming, at) then return false end
    if at < (tonumber(Service.NextAttemptAt[id]) or 0) then return false end
    if Service.AttemptAt ~= at then
        Service.AttemptAt = at
        Service.AttemptCount = 0
    end
    if (tonumber(Service.AttemptCount) or 0)
        >= Service.MAX_ATTEMPTS_PER_TICK
    then
        return false
    end
    Service.AttemptCount = (tonumber(Service.AttemptCount) or 0) + 1
    Service.NextAttemptAt[id] = at + Service.CADENCE_MS
    candidate = findSeat(zombie)
    if not candidate or not Reservations
        or not Reservations.ReserveResource
    then
        return false
    end
    ok, reservation = Reservations.ReserveResource(
        AMBIENT_FACILITY_ID, candidate.resource, record.id,
        RESERVATION_PURPOSE, 30000, { automatic = true, ambient = true })
    if not ok or type(reservation) ~= "table" then return false end
    runtime = record.runtime or {}
    state = {
        seating = true,
        phase = "TRAVELLING",
        sceneId = SCENE_ID,
        startedAt = at,
        seatUntil = at + Service.SEAT_MIN_MS
            + ZombRand(Service.SEAT_MAX_MS - Service.SEAT_MIN_MS + 1),
        reservationId = reservation.id,
        facilityId = AMBIENT_FACILITY_ID,
        resourceKey = candidate.resource.resourceKey,
        resourceKind = candidate.resource.resourceKind,
        resource = Resources.CopyDescriptor
            and Resources.CopyDescriptor(candidate.resource)
            or candidate.resource,
        target = { x = candidate.target.x, y = candidate.target.y,
            z = candidate.target.z },
        x = candidate.target.x, y = candidate.target.y,
        z = candidate.target.z,
        seatAnchor = {
            x = candidate.target.seatAnchorX or candidate.target.x,
            y = candidate.target.seatAnchorY or candidate.target.y,
            z = candidate.target.seatAnchorZ or candidate.target.z,
        },
        seatDirection = tostring(candidate.target.seatDirection or ""),
        seatSide = tostring(candidate.target.seatSide or ""),
        approachKey = tostring(candidate.target.approachKey or ""),
        validSpot = candidate.target.validSpot ~= false,
        seatValidation = tostring(candidate.target.validationState or ""),
        seatRouteStatus = tostring(candidate.target.routeStatus or "UNTESTED"),
        seatStopDistance = 0.10,
        seatArrivalDistance = 0.14,
        approachCandidates = candidate.targets,
        approachIndex = 1,
        failedApproaches = {},
        nextSeatValidationAt = at,
        nextReservationRenewAt = at + 10000,
    }
    runtime.roamingSeat = state
    if PNC.SeatingRuntime and PNC.SeatingRuntime.LiveObjects then
        PNC.SeatingRuntime.LiveObjects[id] = candidate.object
    end
    return Service.Tick(record, zombie, at)
end

function Service.Tick(record, zombie, at)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local seating = Jobs and Jobs.Seating
    local scene
    local distance
    local refreshed
    local reason
    local seated
    local started
    at = currentTime(at)
    if not state then return false end
    if not isRoamOrder(record) or not zombie or record.alive == false then
        stop(record, zombie, "roaming_seat_order_changed")
        return true
    end
    if runtime.facilityActivity or runtime.workOrderId
        or runtime.attackAction or runtime.combatTarget
    then
        stop(record, zombie, "roaming_seat_preempted")
        return true
    end
    if state.seatUntil and at >= state.seatUntil then
        stop(record, zombie, "roaming_seat_timeout")
        return true
    end
    if runtime.seatedThreat and runtime.seatedThreat.active == true then
        return false
    end
    scene = runtime.animationScene
    if scene and scene.id == SCENE_ID then return false end
    if scene then
        stop(record, zombie, "roaming_seat_scene_replaced")
        return true
    end
    if handleThreat(record, zombie, state, at) then return true end
    if not seating then
        stop(record, zombie, "roaming_seat_api_unavailable")
        return true
    end
    if at >= (tonumber(state.nextSeatValidationAt) or 0) then
        refreshed, reason = seating.RefreshLiveSeatTarget(
            record, zombie, state, state)
        state.nextSeatValidationAt = at + 1000
        runtime.target = nil
        if not refreshed then
            stop(record, zombie, reason or "roaming_seat_invalid")
            return true
        end
    end
    if runtime.pathing and (runtime.pathing.phase == "blocked"
        or runtime.pathing.ownerMode == "blocked")
    then
        if not seating.RetryApproach(record, zombie, state, state) then
            stop(record, zombie, state.failedReason
                or "roaming_seat_unreachable")
            return true
        end
        runtime.target = nil
        return true
    end
    distance = distanceTo(zombie, state.x, state.y)
    if distance > (tonumber(state.seatArrivalDistance) or 0.14)
        or math.abs((tonumber(zombie:getZ()) or 0)
            - (tonumber(state.z) or 0)) >= 0.5
    then
        state.phase = "TRAVELLING"
        record.activeBehavior = "Roam:seat:travel"
        Common.ClearCombatTarget(record, "roaming_seat_travel", zombie)
        Common.MoveRecord(record, zombie, state.x, state.y, state.z,
            "walk", tonumber(state.seatStopDistance) or 0.10,
            "roaming_seat")
        return true
    end
    if state.arrivalSettled ~= true then
        seating.ResetPath(record, zombie, "roaming_seat_arrival")
        Common.HaltMovement(record, zombie, "roaming_seat_arrival")
        state.arrivalSettled = true
    end
    if state.positioned ~= true then
        local positioned, positionReason = seating.PositionAtSeatAnchor(
            record, zombie, state, state)
        if not positioned then
            stop(record, zombie, positionReason or "roaming_seat_position")
            return true
        end
    end
    if state.seatEntered ~= true then
        seated, reason = seating.EnterFurnitureSeat(
            record, zombie, state, state)
        if not seated then
            stop(record, zombie, reason or "roaming_seat_entry")
            return true
        end
    end
    state.phase = "STARTING"
    record.activeBehavior = "Roam:seat:starting"
    started = PNC.AnimationScenes and PNC.AnimationScenes.Request
        and PNC.AnimationScenes.Request(record, zombie, SCENE_ID, {
            reason = "roaming_ambient_seat",
            repeatMode = "loop",
        })
    if started ~= true then
        stop(record, zombie, "roaming_seat_scene_failed")
        return true
    end
    state.phase = "SEATED"
    return true
end

function Service.OnSceneTick(record, zombie, scene, at)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    at = currentTime(at)
    if not state or not scene or scene.id ~= SCENE_ID then return false end
    if not zombie or not isRoamOrder(record) or record.alive == false then
        return false
    end
    if Reservations and Reservations.Start
        and at >= (tonumber(state.nextReservationRenewAt) or 0)
    then
        Reservations.Start(state.reservationId, 30000)
        state.nextReservationRenewAt = at + 10000
    end
    return at < (tonumber(state.seatUntil) or at)
end

function Service.OnSceneStopped(record, zombie, scene, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local seating = Jobs and Jobs.Seating
    if not state or not scene or scene.id ~= SCENE_ID then return end
    if seating and seating.ClearFurnitureSeat then
        seating.ClearFurnitureSeat(record, zombie, state)
    end
    if seating and seating.RestorePosition then
        seating.RestorePosition(record, zombie, state)
    end
    if seating and seating.ResetPath then
        seating.ResetPath(record, zombie, "roaming_seat_scene_stopped")
    end
    state.positioned = false
    state.arrivalSettled = false
    if tostring(reason or "") == "interrupted:combat"
        and state.stopRequested ~= true
    then
        state.phase = "INTERRUPTED"
        state.nextSeatValidationAt = currentTime() + 1000
        return
    end
    finish(record, zombie, reason or "roaming_seat_scene_stopped")
end

function Service.Stop(record, zombie, reason)
    return stop(record, zombie, reason or "roaming_seat_stopped")
end

return Service
