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
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function facilityJobs()
    return PNC.FacilityJobs or Jobs
end

local function facilityResources()
    return PNC.FacilityResources or Resources
end

local function interactionTargets()
    return PNC.FacilityInteractionTargets or Targets
end

local function facilityReservations()
    return PNC.FacilityReservations or Reservations
end

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
local FLOOR_SCENE_ID = "facility.living.sit"
local AMBIENT_FACILITY_ID = "ambient:roam"
local RESERVATION_PURPOSE = "ambient_roam_seat"
local GUARD_RESERVATION_PURPOSE = "guard_seat"

local function currentTime(value)
    return tonumber(value) or Core.Now()
end

local function orderKind(record)
    return tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
end

local function isRoamOrder(record)
    local kind = orderKind(record)
    return kind == tostring(Const.ORDER_ROAM or "roam")
end

local function isGuardOrder(record)
    local kind = orderKind(record)
    return kind == tostring(Const.ORDER_GUARD or "guard")
end

local function isSeatOrder(record, state)
    if isRoamOrder(record) then
        return state == nil
            or tostring(state.ownerKind or "") == ""
            or tostring(state.ownerKind or "") == "roam"
    end
    return isGuardOrder(record) and state
        and tostring(state.ownerKind or "") == "guard"
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
    local reservations = facilityReservations()
    local key = tostring(resource and resource.resourceKey or "")
    return key ~= "" and reservations and reservations.ByResource
        and reservations.ByResource[key] ~= nil
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

local function canAttemptGuard(record, zombie, order, at)
    local runtime = record and record.runtime or nil
    local target = runtime and runtime.target or nil
    local anchorX = tonumber(order and order.x)
        or tonumber(record and record.anchorX)
        or tonumber(record and record.x) or 0
    local anchorY = tonumber(order and order.y)
        or tonumber(record and record.anchorY)
        or tonumber(record and record.y) or 0
    local bodyX = zombie and zombie.getX and zombie:getX()
        or record and record.x or 0
    local bodyY = zombie and zombie.getY and zombie:getY()
        or record and record.y or 0
    local stopDistance = tonumber(Const.GUARD_STOP_DISTANCE)
        or tonumber(Const.GUARD_REACHED_DISTANCE) or 0.55
    if not Core.IsAuthority() or not record or not zombie
        or record.alive == false or not isGuardOrder(record)
    then
        return false
    end
    if runtime and (runtime.facilityActivity or runtime.workOrderId
        or runtime.attackAction or runtime.combatTarget
        or runtime.roamingSeat
        or at < (tonumber(runtime.inCombatUntil) or 0))
    then
        return false
    end
    if type(target) == "table" and target.kind ~= nil then return false end
    if runtime.animationScene ~= nil or hasActivePath(record) then
        return false
    end
    local distance = Core.Distance(bodyX, bodyY, anchorX, anchorY)
    return distance <= math.max(0.45, stopDistance)
end

local function idHash(value, modulus)
    local hash = 0
    local text = tostring(value or "npc")
    for index = 1, #text do
        hash = (hash + (string.byte(text, index) or 0) * index)
            % modulus
    end
    return hash
end

local function floorSquareUsable(square, allowOccupied, x, y, z)
    local pathInternal
    local checked
    local walkable
    if not square then return false end
    if square.isSolid and square:isSolid() == true then return false end
    if square.isSolidTrans and square:isSolidTrans() == true then
        return false
    end
    -- Outdoor terrain is valid sitting ground even when the square has no
    -- room-floor object. Solid/occupancy/path checks below are the actual
    -- movement safety boundary.
    if allowOccupied == true then return true end
    pathInternal = PNC.PathService and PNC.PathService.Internal or nil
    if pathInternal and pathInternal.isSquareWalkable then
        checked, walkable = pcall(pathInternal.isSquareWalkable, x, y, z)
        if checked then return walkable == true end
    end
    if square.isFree and square:isFree(false) ~= true then return false end
    return true
end

local function floorSeatCandidate(record, zombie, cell)
    local originX = math.floor(zombie:getX())
    local originY = math.floor(zombie:getY())
    local originZ = math.floor(zombie:getZ())
    local offsets = {
        { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 },
    }
    local start = idHash(record and record.id, #offsets) + 1
    local resourceKey = AMBIENT_FACILITY_ID .. ":floor_sit:"
        .. tostring(record and record.id or "npc")
    for offset = 0, #offsets - 1 do
        local index = ((start - 1 + offset) % #offsets) + 1
        local delta = offsets[index]
        local gridX = originX + delta[1]
        local gridY = originY + delta[2]
        local x = gridX + 0.5
        local y = gridY + 0.5
        local square = cell:getGridSquare(gridX, gridY, originZ)
        if floorSquareUsable(
            square,
            delta[1] == 0 and delta[2] == 0,
            x,
            y,
            originZ
        ) then
            local resource = {
                kind = "virtual", detectorId = "virtual",
                targetResolver = "floor", resourceKind = "floor_seating",
                role = "living.floor", resourceKey = resourceKey,
                x = x, y = y, z = originZ,
                originX = gridX, originY = gridY, originZ = originZ,
                exclusive = false, available = true, virtual = true,
                sceneId = FLOOR_SCENE_ID, seating = true,
                floorSeating = true, stopDistance = 0.45,
                arrivalDistance = 0.55,
            }
            local target = {
                x = x, y = y, z = originZ,
                sceneId = FLOOR_SCENE_ID, resourceKey = resourceKey,
                resourceKind = "floor_seating", seating = true,
                floorSeating = true, validSpot = true,
                stopDistance = 0.45, arrivalDistance = 0.55,
            }
            return {
                object = nil, resource = resource, target = target,
                targets = { target },
            }
        end
    end
    return nil
end

local function findSeat(record, zombie)
    local resourcesService = facilityResources()
    local targetsService = interactionTargets()
    local cell = type(getCell) == "function" and getCell() or nil
    local detector = resourcesService and resourcesService.GetDetector
        and resourcesService.GetDetector("seat") or nil
    local originX = math.floor(zombie:getX())
    local originY = math.floor(zombie:getY())
    local originZ = math.floor(zombie:getZ())
    local best
    local bestDistance
    local examined = 0
    if not cell or not cell.getGridSquare then return nil end
    if detector and type(detector.matches) == "function"
        and type(detector.describe) == "function"
        and targetsService and targetsService.ResolveResource
    then
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
                        local called
                        local matched
                        local described
                        local resolved
                        called, matched = pcall(
                            detector.matches,
                            square,
                            object
                        )
                        if not called or matched ~= true then return end
                        -- Count only seat-like objects. Decorative clutter in
                        -- a square should never consume the physical-chair
                        -- search budget before the floor fallback is allowed.
                        if examined >= Service.MAX_OBJECTS then return end
                        examined = examined + 1
                        described, resource = pcall(
                            detector.describe,
                            square,
                            object,
                            {
                                objectIndex = objectIndex,
                                character = zombie,
                            }
                        )
                        if not described or type(resource) ~= "table"
                            or isReserved(resource)
                        then
                            return
                        end
                        resolved, targets = pcall(
                            targetsService.ResolveResource,
                            resource,
                            { abstract = false, character = zombie }
                        )
                        if not resolved then return end
                        target = targets and targets[1] or nil
                        if not target or target.validSpot == false then return end
                        distance = distanceTo(zombie, target.x, target.y)
                        local resourceKey = tostring(resource.resourceKey or "")
                        local bestKey = tostring(best
                            and best.resource
                            and best.resource.resourceKey or "")
                        if not bestDistance or distance < bestDistance
                            or distance == bestDistance
                                and resourceKey < bestKey
                        then
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
    end
    return best or floorSeatCandidate(record, zombie, cell)
end

local function release(state, reason)
    local reservations = facilityReservations()
    local id = tostring(state and state.reservationId or "")
    if id ~= "" and reservations and reservations.Release then
        reservations.Release(id, reason or "roaming_seat_stopped")
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
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
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
    if scene and scene.id == state.sceneId
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

local function beginAttempt(id, at)
    if at < (tonumber(Service.NextAttemptAt[id]) or 0) then
        return false
    end
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
    return true
end

local function startSeat(record, zombie, at, ownerKind)
    local resourcesService = facilityResources()
    local reservationsService = facilityReservations()
    local id = tostring(record and record.id or "")
    local candidate
    local ok
    local reservation
    local runtime
    local state
    local floorSeating
    local sceneId
    local reservationPurpose = ownerKind == "guard"
        and GUARD_RESERVATION_PURPOSE or RESERVATION_PURPOSE
    if not beginAttempt(id, at) then return false end
    candidate = findSeat(record, zombie)
    if not candidate or not reservationsService
        or not reservationsService.ReserveResource
    then
        return false
    end
    ok, reservation = reservationsService.ReserveResource(
        AMBIENT_FACILITY_ID, candidate.resource, record.id,
        reservationPurpose, 30000, {
            automatic = true, ambient = true, ownerKind = ownerKind,
        })
    if not ok or type(reservation) ~= "table" then return false end
    runtime = record.runtime or {}
    floorSeating = candidate.resource.floorSeating == true
        or candidate.target.floorSeating == true
        or tostring(candidate.resource.resourceKind or "") == "floor_seating"
    sceneId = floorSeating and FLOOR_SCENE_ID or SCENE_ID
    state = {
        seating = true,
        floorSeating = floorSeating,
        ownerKind = ownerKind,
        phase = "TRAVELLING",
        sceneId = sceneId,
        startedAt = at,
        seatUntil = ownerKind == "roam"
            and (at + Service.SEAT_MIN_MS
                + ZombRand(Service.SEAT_MAX_MS - Service.SEAT_MIN_MS + 1))
            or nil,
        reservationId = reservation.id,
        facilityId = AMBIENT_FACILITY_ID,
        resourceKey = candidate.resource.resourceKey,
        resourceKind = candidate.resource.resourceKind,
        resource = resourcesService and resourcesService.CopyDescriptor
            and resourcesService.CopyDescriptor(candidate.resource)
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
        seatStopDistance = floorSeating
            and (tonumber(candidate.target.stopDistance) or 0.45) or 0.10,
        seatArrivalDistance = floorSeating
            and (tonumber(candidate.target.arrivalDistance) or 0.55) or 0.14,
        approachCandidates = candidate.targets,
        approachIndex = 1,
        failedApproaches = {},
        nextSeatValidationAt = at,
        nextReservationRenewAt = at + 10000,
        seatSessionId = Diagnostics and Diagnostics.NewSeatingSessionId
            and Diagnostics.NewSeatingSessionId(record.id) or "",
    }
    runtime.roamingSeat = state
    if PNC.SeatingRuntime and PNC.SeatingRuntime.LiveObjects then
        PNC.SeatingRuntime.LiveObjects[id] = candidate.object
    end
    if Diagnostics and Diagnostics.LogSeatingState then
        Diagnostics.LogSeatingState(
            "seat_session_started",
            record,
            zombie,
            nil,
            ownerKind == "guard" and "guard_seat" or "ambient_roam_seat",
            {
                "targetX=" .. tostring(candidate.target.x or ""),
                "targetY=" .. tostring(candidate.target.y or ""),
                "floorSeating=" .. tostring(floorSeating),
                "targetZ=" .. tostring(candidate.target.z or ""),
            }
        )
    end
    return Service.Tick(record, zombie, at)
end

function Service.TryStart(record, zombie, order, roaming, at)
    at = currentTime(at)
    if not canAttempt(record, zombie, roaming, at) then return false end
    return startSeat(record, zombie, at, "roam")
end

function Service.TryStartGuard(record, zombie, order, at)
    at = currentTime(at)
    local allowed = canAttemptGuard(record, zombie, order, at)
    if not allowed then return false end
    return startSeat(record, zombie, at, "guard")
end

function Service.Tick(record, zombie, at)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
    local scene
    local distance
    local refreshed
    local reason
    local seated
    local started
    at = currentTime(at)
    if not state then return false end
    if not isSeatOrder(record, state) or not zombie
        or record.alive == false
    then
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
    scene = runtime.animationScene
    if scene and scene.id == state.sceneId then return false end
    if scene then
        stop(record, zombie, "roaming_seat_scene_replaced")
        return true
    end
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
    if not state.floorSeating and state.positioned ~= true then
        local positioned, positionReason = seating.PositionAtSeatAnchor(
            record, zombie, state, state)
        if not positioned then
            stop(record, zombie, positionReason or "roaming_seat_position")
            return true
        end
    end
    if state.seatEntered ~= true then
        if state.floorSeating == true then
            seated, reason = seating.EnterFloorSeat(
                record, zombie, state, state)
        else
            seated, reason = seating.EnterFurnitureSeat(
                record, zombie, state, state)
        end
        if not seated then
            stop(record, zombie, reason or "roaming_seat_entry")
            return true
        end
    end
    state.phase = "STARTING"
    record.activeBehavior = "Roam:seat:starting"
    started = PNC.AnimationScenes and PNC.AnimationScenes.Request
        and PNC.AnimationScenes.Request(record, zombie, state.sceneId, {
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
    if not state or not scene or scene.id ~= state.sceneId then return false end
    if not zombie or not isSeatOrder(record, state)
        or record.alive == false
    then
        return false
    end
    if state.floorSeating == true and state.seatEntered ~= true then
        -- A released floor seat must not be kept alive by the persistent
        -- scene. The scene owner will perform the normal stop cleanup.
        return false
    end
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
    local reservations = facilityReservations()
    if state.floorSeating == true and seating
        and seating.MaintainFloorSeat
    then
        seating.MaintainFloorSeat(record, zombie, state, state)
    end
    if reservations and reservations.Start
        and at >= (tonumber(state.nextReservationRenewAt) or 0)
    then
        local renewed, renewal = reservations.Start(
            state.reservationId, 30000)
        if Diagnostics and Diagnostics.LogSeatingState then
            Diagnostics.LogSeatingState(
                "seat_reservation_renewed",
                record,
                zombie,
                scene,
                renewed == true and "renewed" or "renew_failed",
                {
                    "renewalResult=" .. tostring(type(renewal) == "table"
                        and renewal.state or renewal or ""),
                    "expiresAt=" .. tostring(type(renewal) == "table"
                        and renewal.expiresAt or ""),
                }
            )
        end
        state.nextReservationRenewAt = at + 10000
    end
    return state.seatUntil == nil
        or at < (tonumber(state.seatUntil) or at)
end

function Service.OnSceneStopped(record, zombie, scene, reason)
    local runtime = record and record.runtime or nil
    local state = runtime and runtime.roamingSeat or nil
    local jobs = facilityJobs()
    local seating = jobs and jobs.Seating
    if not state or not scene or scene.id ~= state.sceneId then return end
    if Diagnostics and Diagnostics.LogSeatingState then
        Diagnostics.LogSeatingState(
            "seat_scene_stopped",
            record,
            zombie,
            scene,
            reason or "roaming_seat_scene_stopped"
        )
    end
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
