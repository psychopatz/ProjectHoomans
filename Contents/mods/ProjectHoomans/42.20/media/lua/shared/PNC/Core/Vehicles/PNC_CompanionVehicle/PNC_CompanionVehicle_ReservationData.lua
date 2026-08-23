local CompanionVehicle = PNC.CompanionVehicle
local Internal = CompanionVehicle.Internal
local Const = PNC.Const
local Registry = PNC.Registry

function Internal.ReservationItemType()
    return tostring(
        Const.VEHICLE_RESERVATION_ITEM_TYPE
            or "PNC.VehicleSeatReservation"
    )
end

function Internal.ItemModData(item)
    return Internal.SafeMethod(item, "getModData")
end

function CompanionVehicle.IsReservationItem(item)
    local modData
    local fullType
    if not item then return false end
    fullType = Internal.SafeMethod(item, "getFullType")
    if tostring(fullType or "") == Internal.ReservationItemType() then
        return true
    end
    modData = Internal.ItemModData(item)
    return modData
        and modData.PNC_VehicleSeatReservation == true
        or false
end

function Internal.ForEachContainerItem(container, callback)
    local items = Internal.SafeMethod(container, "getItems")
    local size
    local i
    if not items or type(callback) ~= "function" then return end
    size = tonumber(Internal.SafeMethod(items, "size"))
    if size ~= nil then
        for i = 0, size - 1 do
            callback(Internal.SafeMethod(items, "get", i))
        end
        return
    end
    if type(items) == "table" then
        for i = 1, #items do callback(items[i]) end
    end
end

function Internal.ReservationData(item)
    local modData
    if not CompanionVehicle.IsReservationItem(item) then return nil end
    modData = Internal.ItemModData(item)
    return {
        npcId = modData and modData.PNC_NPC_ID
            and tostring(modData.PNC_NPC_ID) or nil,
        npcName = modData and modData.PNC_NPC_NAME
            and tostring(modData.PNC_NPC_NAME) or nil,
        vehicleId = modData and modData.PNC_VEHICLE_ID
            and tostring(modData.PNC_VEHICLE_ID) or nil,
        seat = modData and tonumber(modData.PNC_SEAT) or nil,
    }
end

function Internal.FindRecord(npcId)
    local found
    if not npcId then return nil end
    if Registry and Registry.Get then
        found = Registry.Get(npcId)
        if found then return found end
    end
    if Registry and Registry.ForEach then
        Registry.ForEach(function(record)
            if not found
                and record
                and tostring(record.id) == tostring(npcId)
            then
                found = record
            end
        end)
    end
    return found
end

function Internal.IsActiveReservation(
    data,
    expectedVehicleId,
    expectedSeat
)
    local record = data and Internal.FindRecord(data.npcId) or nil
    local passenger = record
        and record.runtime
        and record.runtime.vehiclePassenger
        or nil
    return record ~= nil
        and record.alive ~= false
        and passenger ~= nil
        and passenger.active == true
        and tostring(passenger.vehicleId or "")
            == tostring(expectedVehicleId or "")
        and tonumber(passenger.seat) == tonumber(expectedSeat)
end

function Internal.RemoveContainerItem(container, item)
    local remove
    local ok
    if not container or not item then return false end
    remove = container.Remove
    if type(remove) ~= "function" then return false end
    ok = pcall(remove, container, item)
    if not ok then return false end
    if sendRemoveItemFromContainer then
        pcall(sendRemoveItemFromContainer, container, item)
    end
    return true
end

function Internal.SeatContainer(vehicle, seat)
    local part = Internal.SafeMethod(
        vehicle,
        "getPartForSeatContainer",
        seat
    )
    return part,
        part and Internal.SafeMethod(part, "getItemContainer") or nil
end

function Internal.ForEachVehicleContainer(vehicle, callback)
    local partCount = math.max(
        0,
        math.floor(
            tonumber(Internal.SafeMethod(vehicle, "getPartCount")) or 0
        )
    )
    local i
    local part
    local container
    for i = 0, partCount - 1 do
        part = Internal.SafeMethod(vehicle, "getPartByIndex", i)
        container = part
            and Internal.SafeMethod(part, "getItemContainer")
            or nil
        if container then callback(part, container) end
    end
end
