local CompanionVehicle = PNC.CompanionVehicle
local Internal = CompanionVehicle.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry

local function newPassenger(owner, vehicleId, seat)
    return {
        active = true,
        vehicleId = vehicleId,
        seat = seat,
        ownerOnlineID = tonumber(
            Internal.SafeMethod(owner, "getOnlineID")
        ),
        boardedAt = Core.Now(),
    }
end

local function prepareBoarding(record, zombie)
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.vehicleBlockReason = nil
    if PNC.BehaviorCommon
        and PNC.BehaviorCommon.ClearCombatTarget
    then
        PNC.BehaviorCommon.ClearCombatTarget(
            record,
            "vehicle_board",
            zombie
        )
    end
end

function Internal.Board(
    record,
    zombie,
    owner,
    vehicle,
    seat,
    vehicleId
)
    local Presence = PNC.Presence
    local passenger
    local abstracted = true
    local markerReady
    local markerReason
    record.runtime = record.runtime or {}
    passenger = newPassenger(owner, vehicleId, seat)
    record.runtime.vehiclePassenger = passenger
    markerReady, markerReason = Internal.EnsureReservationMarker(
        record,
        vehicle,
        seat,
        vehicleId
    )
    if not markerReady then
        record.runtime.vehiclePassenger = nil
        record.runtime.vehicleBlockReason =
            markerReason or "seat_reservation_failed"
        Internal.MarkTransition(
            record,
            "board_failed",
            markerReason or "seat_reservation_failed"
        )
        return false, markerReason or "seat_reservation_failed"
    end
    prepareBoarding(record, zombie)
    if record.presenceState == Const.PRESENCE_LIVE then
        abstracted = Presence
            and Presence.Abstract
            and Presence.Abstract(record, "vehicle_board")
            or false
    end
    if not abstracted then
        Internal.ReleaseReservationMarker(
            record,
            passenger,
            "abstract_failed"
        )
        record.runtime.vehiclePassenger = nil
        record.runtime.vehicleBlockReason = "abstract_failed"
        Internal.MarkTransition(record, "board_failed", "abstract_failed")
        return false, "abstract_failed"
    end
    Internal.SetPassengerPosition(record, vehicle, owner)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "vehicle_board")
    end
    Internal.MarkTransition(
        record,
        "boarded",
        "seat_" .. tostring(seat)
    )
    return true, "boarded"
end

function Internal.Disembark(record, owner, reason)
    local Presence = PNC.Presence
    local body
    local passenger
    record.runtime = record.runtime or {}
    passenger = record.runtime.vehiclePassenger
    if owner then
        record.x =
            tonumber(Internal.SafeMethod(owner, "getX")) or record.x
        record.y =
            tonumber(Internal.SafeMethod(owner, "getY")) or record.y
        record.z =
            tonumber(Internal.SafeMethod(owner, "getZ")) or record.z
    end
    Internal.ReleaseReservationMarker(
        record,
        passenger,
        reason or "vehicle_disembark"
    )
    record.runtime.vehiclePassenger = nil
    record.runtime.vehicleBlockReason = nil
    record.activeBehavior = "FollowOwner:vehicle_disembark"
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "vehicle_disembark")
    end
    if record.alive ~= false
        and record.presenceState == Const.PRESENCE_ABSTRACT
        and Presence
        and Presence.Materialize
        and (
            owner ~= nil
            or not Presence.ShouldMaterialize
            or Presence.ShouldMaterialize(record)
        )
    then
        body = Presence.Materialize(
            record,
            reason or "vehicle_disembark"
        )
    end
    Internal.MarkTransition(
        record,
        "disembarked",
        reason or (body and "materialized" or "abstract")
    )
    return true,
        body and "disembarked_live" or "disembarked_abstract"
end

function CompanionVehicle.IsPassenger(record)
    return record
        and record.runtime
        and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
        or false
end

function CompanionVehicle.Release(record, reason)
    local passenger = record
        and record.runtime
        and record.runtime.vehiclePassenger
        or nil
    if not passenger then return false end
    Internal.ReleaseReservationMarker(
        record,
        passenger,
        reason or "released"
    )
    record.runtime.vehiclePassenger = nil
    record.runtime.vehicleBlockReason = nil
    return true
end
