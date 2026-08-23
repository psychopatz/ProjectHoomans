local CompanionVehicle = PNC.CompanionVehicle
local Internal = CompanionVehicle.Internal
local Core = PNC.Core
local Registry = PNC.Registry

function Internal.InspectSeatReservations(vehicle, seat, removeStale)
    local vehicleId = Internal.VehicleKey(vehicle)
    local _, container = Internal.SeatContainer(vehicle, seat)
    local ownByNpc = {}
    local validItems = {}
    local staleItems = {}
    local i
    if not container then
        return ownByNpc, validItems, staleItems, nil
    end
    Internal.ForEachContainerItem(container, function(item)
        local data = Internal.ReservationData(item)
        local positionMatches
        if data then
            positionMatches =
                tostring(data.vehicleId or "") == tostring(vehicleId)
                and tonumber(data.seat) == tonumber(seat)
            if positionMatches
                and Internal.IsActiveReservation(data, vehicleId, seat)
            then
                validItems[#validItems + 1] = item
                ownByNpc[tostring(data.npcId)] = item
            else
                staleItems[#staleItems + 1] = item
            end
        end
    end)
    if removeStale and Core.IsAuthority() then
        for i = 1, #staleItems do
            if Internal.RemoveContainerItem(container, staleItems[i]) then
                Core.LogDebug(
                    "companion_vehicle repaired stale seat reservation"
                        .. " vehicle=" .. tostring(vehicleId)
                        .. " seat=" .. tostring(seat)
                )
            end
        end
    end
    return ownByNpc, validItems, staleItems, container
end

function CompanionVehicle.GetSeatReservation(vehicle, seat)
    local _, container = Internal.SeatContainer(vehicle, seat)
    local reserved = false
    local name
    if not container then return false, nil end
    Internal.ForEachContainerItem(container, function(item)
        local data
        if reserved then return end
        data = Internal.ReservationData(item)
        if data then
            reserved = true
            name = data.npcName or data.npcId or "NPC"
        end
    end)
    return reserved, name
end

function Internal.SeatReservedByOther(vehicleId, seat, ignoredID)
    local reserved = false
    if not Registry or not Registry.ForEach then return false end
    Registry.ForEach(function(other)
        local passenger = other
            and other.runtime
            and other.runtime.vehiclePassenger
            or nil
        if other
            and tostring(other.id) ~= tostring(ignoredID)
            and passenger
            and passenger.active == true
            and tostring(passenger.vehicleId or "") == tostring(vehicleId)
            and tonumber(passenger.seat) == tonumber(seat)
        then
            reserved = true
        end
    end)
    return reserved
end

function Internal.SeatUsable(vehicle, vehicleId, seat, ignoredID)
    local ownByNpc
    local validItems
    local ownMarker
    local installed
    local occupant
    local occupied
    if seat == nil then return false end
    ownByNpc, validItems =
        Internal.InspectSeatReservations(vehicle, seat, true)
    ownMarker = ownByNpc[tostring(ignoredID or "")]
    installed = Internal.SafeMethod(vehicle, "isSeatInstalled", seat)
    occupant = Internal.SafeMethod(vehicle, "getCharacter", seat)
    occupied = Internal.SafeMethod(vehicle, "isSeatOccupied", seat)
    if installed == false or occupant ~= nil then
        return false
    end
    if #validItems > 0 and not ownMarker then
        return false
    end
    if occupied == true and not ownMarker then
        return false
    end
    return not Internal.SeatReservedByOther(vehicleId, seat, ignoredID)
end

function Internal.FindSeat(record, vehicle)
    local vehicleId = Internal.VehicleKey(vehicle)
    local maxPassengers = math.max(
        0,
        math.floor(
            tonumber(
                Internal.SafeMethod(vehicle, "getMaxPassengers")
            ) or 0
        )
    )
    local seat
    for seat = 0, maxPassengers - 1 do
        if Internal.SeatUsable(vehicle, vehicleId, seat, record.id) then
            return seat, vehicleId
        end
    end
    return nil, vehicleId
end
