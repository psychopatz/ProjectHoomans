local CompanionVehicle = PNC.CompanionVehicle
local Internal = CompanionVehicle.Internal
local Core = PNC.Core

function Internal.CreateReservationItem()
    local ok
    local item
    if type(CompanionVehicle._CreateReservationItem) == "function" then
        ok, item = pcall(
            CompanionVehicle._CreateReservationItem,
            Internal.ReservationItemType()
        )
        if ok and item then return item end
    end
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        ok, item = pcall(
            InventoryItemFactory.CreateItem,
            Internal.ReservationItemType()
        )
        if ok and item then return item end
    end
    if instanceItem then
        ok, item = pcall(instanceItem, Internal.ReservationItemType())
        if ok and item then return item end
    end
    return nil
end

function Internal.StampReservationItem(item, record, vehicleId, seat)
    local modData = Internal.ItemModData(item)
    local name
    if not modData then return false end
    name = tostring(record.name or record.id or "NPC")
    modData.PNC_VehicleSeatReservation = true
    modData.PNC_NPC_ID = tostring(record.id)
    modData.PNC_NPC_NAME = name
    modData.PNC_VEHICLE_ID = tostring(vehicleId)
    modData.PNC_SEAT = tonumber(seat)
    if item.setName then
        pcall(item.setName, item, "Occupied by " .. name)
    end
    return true
end

local function attachMarker(passenger, vehicle, container, item)
    passenger._markerItem = item
    passenger._markerContainer = container
    passenger._vehicle = vehicle
end

function Internal.EnsureReservationMarker(
    record,
    vehicle,
    seat,
    vehicleId
)
    local passenger = record
        and record.runtime
        and record.runtime.vehiclePassenger
        or nil
    local ownByNpc
    local validItems
    local container
    local item
    local capacity
    local currentWeight
    local markerWeight
    local added
    if not Core.IsAuthority() then return false, "not_authority" end
    if not passenger or passenger.active ~= true or seat == nil then
        return false, "reservation_inactive"
    end
    ownByNpc, validItems, _, container =
        Internal.InspectSeatReservations(vehicle, seat, true)
    item = ownByNpc[tostring(record.id)]
    if item then
        attachMarker(passenger, vehicle, container, item)
        return true, "marker_present"
    end
    if #validItems > 0 then return false, "seat_reserved" end
    if not container then return false, "seat_container_missing" end
    item = Internal.CreateReservationItem()
    if not item then return false, "marker_create_failed" end
    if not Internal.StampReservationItem(
        item,
        record,
        vehicleId,
        seat
    ) then
        return false, "marker_metadata_failed"
    end
    capacity = math.max(
        1,
        tonumber(Internal.SafeMethod(container, "getCapacity")) or 20
    )
    currentWeight =
        tonumber(Internal.SafeMethod(container, "getCapacityWeight"))
        or tonumber(Internal.SafeMethod(container, "getContentsWeight"))
        or 0
    markerWeight = math.max(
        0.1,
        (capacity * 0.25) - currentWeight + 0.1
    )
    if item.setWeight then
        pcall(item.setWeight, item, markerWeight)
    end
    if item.setActualWeight then
        pcall(item.setActualWeight, item, markerWeight)
    end
    added = Internal.SafeMethod(container, "AddItem", item)
    if not added then return false, "marker_add_failed" end
    if sendAddItemToContainer then
        pcall(sendAddItemToContainer, container, item)
    end
    attachMarker(passenger, vehicle, container, item)
    return true, "marker_added"
end

local function removeNpcMarkers(vehicle, npcId, markerItem)
    local removed = false
    Internal.ForEachVehicleContainer(vehicle, function(_, container)
        local matches = {}
        local i
        Internal.ForEachContainerItem(container, function(item)
            local data = Internal.ReservationData(item)
            if data and tostring(data.npcId or "") == npcId then
                matches[#matches + 1] = item
            end
        end)
        for i = 1, #matches do
            if matches[i] ~= markerItem then
                removed =
                    Internal.RemoveContainerItem(container, matches[i])
                    or removed
            end
        end
    end)
    return removed
end

function Internal.ReleaseReservationMarker(record, passenger, reason)
    local npcId = record and tostring(record.id) or nil
    local vehicle = passenger and passenger._vehicle or nil
    local removed = false
    local markerContainer = passenger
        and passenger._markerContainer
        or nil
    local markerItem = passenger and passenger._markerItem or nil
    if markerContainer
        and markerItem
        and CompanionVehicle.IsReservationItem(markerItem)
    then
        removed =
            Internal.RemoveContainerItem(markerContainer, markerItem)
            or removed
    end
    if vehicle and npcId then
        removed = removeNpcMarkers(vehicle, npcId, markerItem) or removed
    end
    if passenger then
        passenger._markerItem = nil
        passenger._markerContainer = nil
        passenger._vehicle = nil
    end
    if removed then
        Internal.MarkTransition(
            record,
            "seat_released",
            reason or "release"
        )
    end
    return removed
end
