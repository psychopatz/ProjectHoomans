if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.RoamingSeat
local Internal = Service.Internal or {}
local Core = PNC.Core
local Const = PNC.Const or {}
local Common = PNC.BehaviorCommon
local Jobs = PNC.FacilityJobs
local Resources = PNC.FacilityResources
local Targets = PNC.FacilityInteractionTargets
local Reservations = PNC.FacilityReservations
local Diagnostics = PNC.PerformanceScalingDiagnostics
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

local facilityJobs = Internal.facilityJobs
local facilityResources = Internal.facilityResources
local facilityReservations = Internal.facilityReservations
local currentTime = Internal.currentTime
local findSeat = Internal.findSeat
local SCENE_ID = Internal.SCENE_ID
local FLOOR_SCENE_ID = Internal.FLOOR_SCENE_ID
local AMBIENT_FACILITY_ID = Internal.AMBIENT_FACILITY_ID
local RESERVATION_PURPOSE = Internal.RESERVATION_PURPOSE
local GUARD_RESERVATION_PURPOSE = Internal.GUARD_RESERVATION_PURPOSE
local beginAttempt = Internal.beginAttempt

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
    if ActorControl and ActorControl.IsPuppetOwned
        and ActorControl.IsPuppetOwned(record)
    then
        return false
    end
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


Internal.startSeat = startSeat
