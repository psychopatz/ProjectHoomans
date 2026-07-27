--[[
    PNC Companion Vehicle Travel
    Direct IsoZombie vehicle passengers are unstable in Build 42 (notably on
    exit). Companions therefore reserve a real installed/free seat, abstract
    their live body while travelling, and rematerialize through PNC's normal
    safe-square recovery when their owner leaves the vehicle.
]]

PNC = PNC or {}
PNC.CompanionVehicle = PNC.CompanionVehicle or {}

local CompanionVehicle = PNC.CompanionVehicle
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry

local function safeMethod(target, methodName, ...)
    local method
    local ok
    local value
    if not target then return nil end
    method = target[methodName]
    if type(method) ~= "function" then return nil end
    ok, value = pcall(method, target, ...)
    return ok and value or nil
end

local function vehicleKey(vehicle)
    local id = tonumber(safeMethod(vehicle, "getId"))
    if id and id >= 0 then
        return "vehicle:" .. tostring(id)
    end
    return "runtime:" .. tostring(vehicle)
end

local function vehiclePosition(vehicle, owner, record)
    return tonumber(safeMethod(vehicle, "getX"))
            or tonumber(owner and safeMethod(owner, "getX"))
            or tonumber(record.x) or 0,
        tonumber(safeMethod(vehicle, "getY"))
            or tonumber(owner and safeMethod(owner, "getY"))
            or tonumber(record.y) or 0,
        tonumber(safeMethod(vehicle, "getZ"))
            or tonumber(owner and safeMethod(owner, "getZ"))
            or tonumber(record.z) or 0
end

local function seatReservedByOther(vehicleId, seat, ignoredID)
    local reserved = false
    if not Registry or not Registry.ForEach then return false end
    Registry.ForEach(function(other)
        local passenger = other and other.runtime and other.runtime.vehiclePassenger or nil
        if other and tostring(other.id) ~= tostring(ignoredID)
            and passenger and passenger.active == true
            and tostring(passenger.vehicleId or "") == tostring(vehicleId)
            and tonumber(passenger.seat) == tonumber(seat)
        then
            reserved = true
        end
    end)
    return reserved
end

local function seatUsable(vehicle, vehicleId, seat, ignoredID)
    if seat == nil then return false end
    local installed = safeMethod(vehicle, "isSeatInstalled", seat)
    local occupant = safeMethod(vehicle, "getCharacter", seat)
    local occupied = safeMethod(vehicle, "isSeatOccupied", seat)
    if installed == false or occupant ~= nil or occupied == true then
        return false
    end
    return not seatReservedByOther(vehicleId, seat, ignoredID)
end

local function findSeat(record, vehicle)
    local vehicleId = vehicleKey(vehicle)
    local maxPassengers = math.max(0, math.floor(tonumber(safeMethod(vehicle, "getMaxPassengers")) or 0))
    local seat
    for seat = 0, maxPassengers - 1 do
        if seatUsable(vehicle, vehicleId, seat, record.id) then
            return seat, vehicleId
        end
    end
    return nil, vehicleId
end

local function markTransition(record, eventName, reason)
    local message = "companion_vehicle npc=" .. tostring(record and record.id or "nil")
        .. " event=" .. tostring(eventName)
        .. " reason=" .. tostring(reason or "none")
    if Core and Core.LogRecordDebug then
        Core.LogRecordDebug(record, message)
    end
end

local function setPassengerPosition(record, vehicle, owner)
    local x
    local y
    local z
    x, y, z = vehiclePosition(vehicle, owner, record)
    record.x = x
    record.y = y
    record.z = z
    record.activeBehavior = "FollowOwner:vehicle_passenger"
    record.runtime.followState = record.runtime.followState or {}
    record.runtime.followState.mode = "vehicle_passenger"
end

local function board(record, zombie, owner, vehicle, seat, vehicleId)
    local Presence = PNC.Presence
    local passenger
    local abstracted = true
    record.runtime = record.runtime or {}
    passenger = {
        active = true,
        vehicleId = vehicleId,
        seat = seat,
        ownerOnlineID = tonumber(safeMethod(owner, "getOnlineID")),
        boardedAt = Core.Now(),
    }
    record.runtime.vehiclePassenger = passenger
    record.runtime.target = nil
    -- Boarding cancels a committed melee/ranged/reload action. There will be
    -- no live body to finish its animation or pump its delayed hit window.
    record.runtime.attackAction = nil
    record.runtime.vehicleBlockReason = nil
    if PNC.BehaviorCommon and PNC.BehaviorCommon.ClearCombatTarget then
        PNC.BehaviorCommon.ClearCombatTarget(record, "vehicle_board", zombie)
    end
    if record.presenceState == Const.PRESENCE_LIVE then
        abstracted = Presence and Presence.Abstract
            and Presence.Abstract(record, "vehicle_board")
            or false
    end
    if not abstracted then
        record.runtime.vehiclePassenger = nil
        record.runtime.vehicleBlockReason = "abstract_failed"
        markTransition(record, "board_failed", "abstract_failed")
        return false, "abstract_failed"
    end
    setPassengerPosition(record, vehicle, owner)
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "vehicle_board")
    end
    markTransition(record, "boarded", "seat_" .. tostring(seat))
    return true, "boarded"
end

local function disembark(record, owner, reason)
    local Presence = PNC.Presence
    local body
    record.runtime = record.runtime or {}
    if owner then
        record.x = tonumber(safeMethod(owner, "getX")) or record.x
        record.y = tonumber(safeMethod(owner, "getY")) or record.y
        record.z = tonumber(safeMethod(owner, "getZ")) or record.z
    end
    record.runtime.vehiclePassenger = nil
    record.runtime.vehicleBlockReason = nil
    record.activeBehavior = "FollowOwner:vehicle_disembark"
    if Registry and Registry.MarkDirty then
        Registry.MarkDirty(record, "vehicle_disembark")
    end
    if record.alive ~= false
        and record.presenceState == Const.PRESENCE_ABSTRACT
        and Presence and Presence.Materialize
        and (owner ~= nil
            or not Presence.ShouldMaterialize
            or Presence.ShouldMaterialize(record))
    then
        body = Presence.Materialize(record, reason or "vehicle_disembark")
    end
    markTransition(record, "disembarked", reason or (body and "materialized" or "abstract"))
    return true, body and "disembarked_live" or "disembarked_abstract"
end

function CompanionVehicle.IsPassenger(record)
    return record and record.runtime and record.runtime.vehiclePassenger
        and record.runtime.vehiclePassenger.active == true
        or false
end

function CompanionVehicle.Tick(record, zombie, owner)
    local passenger
    local vehicle
    local currentVehicleId
    local seat
    local vehicleId
    local distance
    if not record then return false, "record_missing" end
    record.runtime = record.runtime or {}
    passenger = record.runtime.vehiclePassenger
    vehicle = owner and safeMethod(owner, "getVehicle") or nil

    if passenger and passenger.active == true then
        if not owner or not vehicle then
            return disembark(record, owner, owner and "owner_exited_vehicle" or "owner_missing")
        end
        currentVehicleId = vehicleKey(vehicle)
        if tostring(currentVehicleId) ~= tostring(passenger.vehicleId or "") then
            seat = findSeat(record, vehicle)
            passenger.vehicleId = currentVehicleId
            passenger.seat = seat
            passenger.ownerOnlineID = tonumber(safeMethod(owner, "getOnlineID"))
            record.runtime.vehicleBlockReason = seat == nil and "vehicle_full" or nil
            setPassengerPosition(record, vehicle, owner)
            markTransition(
                record,
                "vehicle_changed",
                seat and ("seat_" .. tostring(seat)) or "waiting_seat"
            )
            return true, seat and "vehicle_passenger" or "vehicle_passenger_waiting_seat"
        end
        if not seatUsable(vehicle, currentVehicleId, passenger.seat, record.id) then
            seat = findSeat(record, vehicle)
            if seat == nil then
                -- The engine does not know about abstract reservations, so a
                -- real player may claim this seat. Keep the companion safely
                -- abstract until another seat opens or the owner exits rather
                -- than materializing it beside a moving vehicle.
                passenger.seat = nil
                record.runtime.vehicleBlockReason = "reserved_seat_lost"
                setPassengerPosition(record, vehicle, owner)
                return true, "vehicle_passenger_waiting_seat"
            end
            passenger.seat = seat
            record.runtime.vehicleBlockReason = nil
            markTransition(record, "seat_reassigned", "seat_" .. tostring(seat))
        end
        setPassengerPosition(record, vehicle, owner)
        return true, "vehicle_passenger"
    end

    if not vehicle then
        record.runtime.vehicleBlockReason = nil
        return false, "owner_on_foot"
    end
    distance = Core.Distance(
        tonumber(record.x) or 0,
        tonumber(record.y) or 0,
        tonumber(safeMethod(owner, "getX")) or 0,
        tonumber(safeMethod(owner, "getY")) or 0
    )
    if math.abs((tonumber(record.z) or 0) - (tonumber(safeMethod(owner, "getZ")) or 0)) > 0.5
        or distance > (tonumber(Const.FOLLOW_VEHICLE_BOARD_DISTANCE) or 3.2)
    then
        record.runtime.vehicleBlockReason = "approaching_vehicle"
        return false, "approaching_vehicle"
    end
    seat, vehicleId = findSeat(record, vehicle)
    if seat == nil then
        record.runtime.vehicleBlockReason = "vehicle_full"
        return false, "vehicle_full"
    end
    return board(record, zombie, owner, vehicle, seat, vehicleId)
end

return CompanionVehicle
