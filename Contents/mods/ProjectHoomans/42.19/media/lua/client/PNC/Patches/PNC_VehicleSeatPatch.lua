require "Vehicles/ISUI/ISVehicleMenu"
require "TimedActions/ISInventoryTransferAction"

-- Abstract companions cannot be attached to BaseVehicle as IsoZombie
-- passengers safely. The authority therefore places a private weighted token
-- in the reserved seat container. Vanilla treats that seat as occupied; these
-- guards keep its normal "move seat items" flow from moving the NPC token.

PNC = PNC or {}

if not PNC._VehicleSeatPatchApplied then
    PNC._VehicleSeatPatchApplied = true

    local CompanionVehicle = PNC.CompanionVehicle
    local originalMoveItemsFromSeat = ISVehicleMenu.moveItemsFromSeat
    local originalOnEnter = ISVehicleMenu.onEnter
    local originalOnEnter2 = ISVehicleMenu.onEnter2
    local originalTransferIsValid = ISInventoryTransferAction.isValid

    local function reservationName(vehicle, seat)
        if not CompanionVehicle or not CompanionVehicle.GetSeatReservation then
            return nil
        end
        local reserved, name = CompanionVehicle.GetSeatReservation(vehicle, seat)
        return reserved and name or nil
    end

    local function showOccupied(playerObj, name)
        local text = getText and getText("UI_PNC_VehicleSeatOccupied", tostring(name or "NPC"))
            or ("Seat occupied by " .. tostring(name or "NPC"))
        if HaloTextHelper and HaloTextHelper.addBadText then
            HaloTextHelper.addBadText(playerObj, text)
        end
    end

    function ISVehicleMenu.moveItemsFromSeat(playerObj, vehicle, seat, moveThem, doEnter)
        if reservationName(vehicle, seat) then
            return false
        end
        return originalMoveItemsFromSeat(playerObj, vehicle, seat, moveThem, doEnter)
    end

    function ISVehicleMenu.onEnter(playerObj, vehicle, seat)
        local name = reservationName(vehicle, seat)
        if name then
            showOccupied(playerObj, name)
            return
        end
        return originalOnEnter(playerObj, vehicle, seat)
    end

    function ISVehicleMenu.onEnter2(playerObj, vehicle, seat)
        local name = reservationName(vehicle, seat)
        if name then
            showOccupied(playerObj, name)
            return
        end
        return originalOnEnter2(playerObj, vehicle, seat)
    end

    function ISInventoryTransferAction:isValid()
        if CompanionVehicle and CompanionVehicle.IsReservationItem
            and CompanionVehicle.IsReservationItem(self.item)
        then
            return false
        end
        return originalTransferIsValid(self)
    end
end

return PNC
