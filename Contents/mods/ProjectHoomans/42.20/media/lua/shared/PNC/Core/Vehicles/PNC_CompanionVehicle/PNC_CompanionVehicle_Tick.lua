local CompanionVehicle = PNC.CompanionVehicle
local Internal = CompanionVehicle.Internal
local Core = PNC.Core
local Const = PNC.Const

local function waitForSeat(record, vehicle, owner, passenger, reason)
    passenger.seat = nil
    record.runtime.vehicleBlockReason =
        reason or "seat_reservation_failed"
    Internal.SetPassengerPosition(record, vehicle, owner)
    return true, "vehicle_passenger_waiting_seat"
end

local function changeVehicle(
    record,
    vehicle,
    owner,
    passenger,
    currentVehicleId
)
    local seat
    local markerReady
    local markerReason
    Internal.ReleaseReservationMarker(
        record,
        passenger,
        "vehicle_changed"
    )
    seat = Internal.FindSeat(record, vehicle)
    passenger.vehicleId = currentVehicleId
    passenger.seat = seat
    passenger.ownerOnlineID = tonumber(
        Internal.SafeMethod(owner, "getOnlineID")
    )
    passenger._vehicle = vehicle
    if seat ~= nil then
        markerReady, markerReason = Internal.EnsureReservationMarker(
            record,
            vehicle,
            seat,
            currentVehicleId
        )
        if not markerReady then
            passenger.seat = nil
            seat = nil
        end
    end
    record.runtime.vehicleBlockReason =
        seat == nil and "vehicle_full" or nil
    if markerReason and not markerReady then
        record.runtime.vehicleBlockReason = markerReason
    end
    Internal.SetPassengerPosition(record, vehicle, owner)
    Internal.MarkTransition(
        record,
        "vehicle_changed",
        seat and ("seat_" .. tostring(seat)) or "waiting_seat"
    )
    return true,
        seat
            and "vehicle_passenger"
            or "vehicle_passenger_waiting_seat"
end

local function reassignSeat(
    record,
    vehicle,
    owner,
    passenger,
    currentVehicleId
)
    local seat = Internal.FindSeat(record, vehicle)
    local markerReady
    local markerReason
    Internal.ReleaseReservationMarker(record, passenger, "seat_lost")
    if seat == nil then
        return waitForSeat(
            record,
            vehicle,
            owner,
            passenger,
            "reserved_seat_lost"
        )
    end
    passenger.seat = seat
    passenger._vehicle = vehicle
    markerReady, markerReason = Internal.EnsureReservationMarker(
        record,
        vehicle,
        seat,
        currentVehicleId
    )
    if not markerReady then
        return waitForSeat(
            record,
            vehicle,
            owner,
            passenger,
            markerReason or "seat_reservation_failed"
        )
    end
    record.runtime.vehicleBlockReason = nil
    Internal.MarkTransition(
        record,
        "seat_reassigned",
        "seat_" .. tostring(seat)
    )
    return nil
end

local function maintainPassenger(record, vehicle, owner, passenger)
    local currentVehicleId
    local markerReady
    local markerReason
    local handled
    local reason
    if not owner or not vehicle then
        return Internal.Disembark(
            record,
            owner,
            owner and "owner_exited_vehicle" or "owner_missing"
        )
    end
    currentVehicleId = Internal.VehicleKey(vehicle)
    if tostring(currentVehicleId)
        ~= tostring(passenger.vehicleId or "")
    then
        return changeVehicle(
            record,
            vehicle,
            owner,
            passenger,
            currentVehicleId
        )
    end
    if not Internal.SeatUsable(
        vehicle,
        currentVehicleId,
        passenger.seat,
        record.id
    ) then
        handled, reason = reassignSeat(
            record,
            vehicle,
            owner,
            passenger,
            currentVehicleId
        )
        if handled ~= nil then return handled, reason end
    end
    markerReady, markerReason = Internal.EnsureReservationMarker(
        record,
        vehicle,
        passenger.seat,
        currentVehicleId
    )
    if not markerReady then
        Internal.ReleaseReservationMarker(
            record,
            passenger,
            markerReason
        )
        return waitForSeat(
            record,
            vehicle,
            owner,
            passenger,
            markerReason or "seat_reservation_failed"
        )
    end
    Internal.SetPassengerPosition(record, vehicle, owner)
    return true, "vehicle_passenger"
end

local function isNearVehicle(record, owner)
    local distance = Core.Distance(
        tonumber(record.x) or 0,
        tonumber(record.y) or 0,
        tonumber(Internal.SafeMethod(owner, "getX")) or 0,
        tonumber(Internal.SafeMethod(owner, "getY")) or 0
    )
    local heightDifference = math.abs(
        (tonumber(record.z) or 0)
            - (tonumber(Internal.SafeMethod(owner, "getZ")) or 0)
    )
    return heightDifference <= 0.5
        and distance
            <= (tonumber(Const.FOLLOW_VEHICLE_BOARD_DISTANCE) or 3.2)
end

local function attemptBoard(record, zombie, owner, vehicle)
    local seat
    local vehicleId
    if not vehicle then
        record.runtime.vehicleBlockReason = nil
        return false, "owner_on_foot"
    end
    if not isNearVehicle(record, owner) then
        record.runtime.vehicleBlockReason = "approaching_vehicle"
        return false, "approaching_vehicle"
    end
    seat, vehicleId = Internal.FindSeat(record, vehicle)
    if seat == nil then
        record.runtime.vehicleBlockReason = "vehicle_full"
        return false, "vehicle_full"
    end
    return Internal.Board(
        record,
        zombie,
        owner,
        vehicle,
        seat,
        vehicleId
    )
end

function CompanionVehicle.Tick(record, zombie, owner)
    local passenger
    local vehicle
    if not record then return false, "record_missing" end
    record.runtime = record.runtime or {}
    passenger = record.runtime.vehiclePassenger
    vehicle = owner
        and Internal.SafeMethod(owner, "getVehicle")
        or nil
    if passenger and passenger.active == true then
        return maintainPassenger(record, vehicle, owner, passenger)
    end
    return attemptBoard(record, zombie, owner, vehicle)
end
