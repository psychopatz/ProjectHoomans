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
local lastReservationAuditAt = 0
local markTransition

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

local function reservationItemType()
    return tostring(Const.VEHICLE_RESERVATION_ITEM_TYPE or "PNC.VehicleSeatReservation")
end

local function itemModData(item)
    return safeMethod(item, "getModData")
end

function CompanionVehicle.IsReservationItem(item)
    local modData
    local fullType
    if not item then return false end
    fullType = safeMethod(item, "getFullType")
    if tostring(fullType or "") == reservationItemType() then
        return true
    end
    modData = itemModData(item)
    return modData and modData.PNC_VehicleSeatReservation == true or false
end

local function forEachContainerItem(container, callback)
    local items = safeMethod(container, "getItems")
    local size
    local i
    if not items or type(callback) ~= "function" then return end
    size = tonumber(safeMethod(items, "size"))
    if size ~= nil then
        for i = 0, size - 1 do
            callback(safeMethod(items, "get", i))
        end
        return
    end
    if type(items) == "table" then
        for i = 1, #items do callback(items[i]) end
    end
end

local function reservationData(item)
    local modData
    if not CompanionVehicle.IsReservationItem(item) then return nil end
    modData = itemModData(item)
    return {
        npcId = modData and modData.PNC_NPC_ID and tostring(modData.PNC_NPC_ID) or nil,
        npcName = modData and modData.PNC_NPC_NAME and tostring(modData.PNC_NPC_NAME) or nil,
        vehicleId = modData and modData.PNC_VEHICLE_ID
            and tostring(modData.PNC_VEHICLE_ID) or nil,
        seat = modData and tonumber(modData.PNC_SEAT) or nil,
    }
end

local function findRecord(npcId)
    local found
    if not npcId then return nil end
    if Registry and Registry.Get then
        found = Registry.Get(npcId)
        if found then return found end
    end
    if Registry and Registry.ForEach then
        Registry.ForEach(function(record)
            if not found and record and tostring(record.id) == tostring(npcId) then
                found = record
            end
        end)
    end
    return found
end

local function isActiveReservation(data, expectedVehicleId, expectedSeat)
    local record = data and findRecord(data.npcId) or nil
    local passenger = record and record.runtime and record.runtime.vehiclePassenger or nil
    return record ~= nil
        and record.alive ~= false
        and passenger ~= nil
        and passenger.active == true
        and tostring(passenger.vehicleId or "") == tostring(expectedVehicleId or "")
        and tonumber(passenger.seat) == tonumber(expectedSeat)
end

local function removeContainerItem(container, item)
    if not container or not item then return false end
    local remove = container.Remove
    if type(remove) ~= "function" then return false end
    local ok = pcall(remove, container, item)
    if not ok then return false end
    if sendRemoveItemFromContainer then
        pcall(sendRemoveItemFromContainer, container, item)
    end
    return true
end

local function seatContainer(vehicle, seat)
    local part = safeMethod(vehicle, "getPartForSeatContainer", seat)
    return part, part and safeMethod(part, "getItemContainer") or nil
end

local function inspectSeatReservations(vehicle, seat, removeStale)
    local vehicleId = vehicleKey(vehicle)
    local _, container = seatContainer(vehicle, seat)
    local ownByNpc = {}
    local validItems = {}
    local staleItems = {}
    if not container then return ownByNpc, validItems, staleItems, nil end
    forEachContainerItem(container, function(item)
        local data = reservationData(item)
        if data then
            local positionMatches = tostring(data.vehicleId or "") == tostring(vehicleId)
                and tonumber(data.seat) == tonumber(seat)
            if positionMatches and isActiveReservation(data, vehicleId, seat) then
                validItems[#validItems + 1] = item
                ownByNpc[tostring(data.npcId)] = item
            else
                staleItems[#staleItems + 1] = item
            end
        end
    end)
    if removeStale and Core.IsAuthority() then
        local i
        for i = 1, #staleItems do
            if removeContainerItem(container, staleItems[i]) then
                Core.LogDebug("companion_vehicle repaired stale seat reservation vehicle="
                    .. tostring(vehicleId) .. " seat=" .. tostring(seat))
            end
        end
    end
    return ownByNpc, validItems, staleItems, container
end

function CompanionVehicle.GetSeatReservation(vehicle, seat)
    local _, container = seatContainer(vehicle, seat)
    local reserved = false
    local name
    if not container then return false, nil end
    forEachContainerItem(container, function(item)
        local data
        if reserved then return end
        data = reservationData(item)
        if data then
            reserved = true
            name = data.npcName or data.npcId or "NPC"
        end
    end)
    return reserved, name
end

local function createReservationItem()
    local ok
    local item
    if type(CompanionVehicle._CreateReservationItem) == "function" then
        ok, item = pcall(CompanionVehicle._CreateReservationItem, reservationItemType())
        if ok and item then return item end
    end
    if InventoryItemFactory and InventoryItemFactory.CreateItem then
        ok, item = pcall(InventoryItemFactory.CreateItem, reservationItemType())
        if ok and item then return item end
    end
    if instanceItem then
        ok, item = pcall(instanceItem, reservationItemType())
        if ok and item then return item end
    end
    return nil
end

local function stampReservationItem(item, record, vehicleId, seat)
    local modData = itemModData(item)
    if not modData then return false end
    modData.PNC_VehicleSeatReservation = true
    modData.PNC_NPC_ID = tostring(record.id)
    modData.PNC_NPC_NAME = tostring(record.name or record.id or "NPC")
    modData.PNC_VEHICLE_ID = tostring(vehicleId)
    modData.PNC_SEAT = tonumber(seat)
    if item.setName then
        pcall(item.setName, item, "Occupied by " .. tostring(record.name or record.id or "NPC"))
    end
    return true
end

local function ensureReservationMarker(record, vehicle, seat, vehicleId)
    local passenger = record and record.runtime and record.runtime.vehiclePassenger or nil
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
    ownByNpc, validItems, _, container = inspectSeatReservations(vehicle, seat, true)
    item = ownByNpc[tostring(record.id)]
    if item then
        passenger._markerItem = item
        passenger._markerContainer = container
        passenger._vehicle = vehicle
        return true, "marker_present"
    end
    if #validItems > 0 then return false, "seat_reserved" end
    if not container then return false, "seat_container_missing" end
    item = createReservationItem()
    if not item then return false, "marker_create_failed" end
    if not stampReservationItem(item, record, vehicleId, seat) then
        return false, "marker_metadata_failed"
    end
    capacity = math.max(1, tonumber(safeMethod(container, "getCapacity")) or 20)
    currentWeight = tonumber(safeMethod(container, "getCapacityWeight"))
        or tonumber(safeMethod(container, "getContentsWeight")) or 0
    markerWeight = math.max(0.1, (capacity * 0.25) - currentWeight + 0.1)
    if item.setWeight then pcall(item.setWeight, item, markerWeight) end
    if item.setActualWeight then pcall(item.setActualWeight, item, markerWeight) end
    added = safeMethod(container, "AddItem", item)
    if not added then return false, "marker_add_failed" end
    if sendAddItemToContainer then
        pcall(sendAddItemToContainer, container, item)
    end
    passenger._markerItem = item
    passenger._markerContainer = container
    passenger._vehicle = vehicle
    return true, "marker_added"
end

local function forEachVehicleContainer(vehicle, callback)
    local partCount = math.max(0, math.floor(tonumber(safeMethod(vehicle, "getPartCount")) or 0))
    local i
    local part
    local container
    for i = 0, partCount - 1 do
        part = safeMethod(vehicle, "getPartByIndex", i)
        container = part and safeMethod(part, "getItemContainer") or nil
        if container then callback(part, container) end
    end
end

local function releaseReservationMarker(record, passenger, reason)
    local npcId = record and tostring(record.id) or nil
    local vehicle = passenger and passenger._vehicle or nil
    local removed = false
    local markerContainer = passenger and passenger._markerContainer or nil
    local markerItem = passenger and passenger._markerItem or nil
    if markerContainer and markerItem and CompanionVehicle.IsReservationItem(markerItem) then
        removed = removeContainerItem(markerContainer, markerItem) or removed
    end
    if vehicle and npcId then
        forEachVehicleContainer(vehicle, function(_, container)
            local matches = {}
            forEachContainerItem(container, function(item)
                local data = reservationData(item)
                if data and tostring(data.npcId or "") == npcId then
                    matches[#matches + 1] = item
                end
            end)
            local i
            for i = 1, #matches do
                if matches[i] ~= markerItem then
                    removed = removeContainerItem(container, matches[i]) or removed
                end
            end
        end)
    end
    if passenger then
        passenger._markerItem = nil
        passenger._markerContainer = nil
        passenger._vehicle = nil
    end
    if removed then markTransition(record, "seat_released", reason or "release") end
    return removed
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
    local ownByNpc
    local validItems
    local ownMarker
    if seat == nil then return false end
    ownByNpc, validItems = inspectSeatReservations(vehicle, seat, true)
    ownMarker = ownByNpc[tostring(ignoredID or "")]
    local installed = safeMethod(vehicle, "isSeatInstalled", seat)
    local occupant = safeMethod(vehicle, "getCharacter", seat)
    local occupied = safeMethod(vehicle, "isSeatOccupied", seat)
    if installed == false or occupant ~= nil then
        return false
    end
    if #validItems > 0 and not ownMarker then
        return false
    end
    if occupied == true and not ownMarker then
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

markTransition = function(record, eventName, reason)
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
    local markerReady
    local markerReason
    record.runtime = record.runtime or {}
    passenger = {
        active = true,
        vehicleId = vehicleId,
        seat = seat,
        ownerOnlineID = tonumber(safeMethod(owner, "getOnlineID")),
        boardedAt = Core.Now(),
    }
    record.runtime.vehiclePassenger = passenger
    markerReady, markerReason = ensureReservationMarker(record, vehicle, seat, vehicleId)
    if not markerReady then
        record.runtime.vehiclePassenger = nil
        record.runtime.vehicleBlockReason = markerReason or "seat_reservation_failed"
        markTransition(record, "board_failed", markerReason or "seat_reservation_failed")
        return false, markerReason or "seat_reservation_failed"
    end
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
        releaseReservationMarker(record, passenger, "abstract_failed")
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
    local passenger
    record.runtime = record.runtime or {}
    passenger = record.runtime.vehiclePassenger
    if owner then
        record.x = tonumber(safeMethod(owner, "getX")) or record.x
        record.y = tonumber(safeMethod(owner, "getY")) or record.y
        record.z = tonumber(safeMethod(owner, "getZ")) or record.z
    end
    releaseReservationMarker(record, passenger, reason or "vehicle_disembark")
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
    local markerReady
    local markerReason
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
            releaseReservationMarker(record, passenger, "vehicle_changed")
            seat = findSeat(record, vehicle)
            passenger.vehicleId = currentVehicleId
            passenger.seat = seat
            passenger.ownerOnlineID = tonumber(safeMethod(owner, "getOnlineID"))
            passenger._vehicle = vehicle
            if seat ~= nil then
                markerReady, markerReason = ensureReservationMarker(
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
            record.runtime.vehicleBlockReason = seat == nil and "vehicle_full" or nil
            if markerReason and not markerReady then
                record.runtime.vehicleBlockReason = markerReason
            end
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
            releaseReservationMarker(record, passenger, "seat_lost")
            if seat == nil then
                -- A real occupant won a race for this seat before the
                -- reservation token replicated. Keep the companion safely
                -- abstract until another seat opens or the owner exits.
                passenger.seat = nil
                record.runtime.vehicleBlockReason = "reserved_seat_lost"
                setPassengerPosition(record, vehicle, owner)
                return true, "vehicle_passenger_waiting_seat"
            end
            passenger.seat = seat
            passenger._vehicle = vehicle
            markerReady, markerReason = ensureReservationMarker(
                record,
                vehicle,
                seat,
                currentVehicleId
            )
            if not markerReady then
                passenger.seat = nil
                record.runtime.vehicleBlockReason = markerReason or "seat_reservation_failed"
                setPassengerPosition(record, vehicle, owner)
                return true, "vehicle_passenger_waiting_seat"
            end
            record.runtime.vehicleBlockReason = nil
            markTransition(record, "seat_reassigned", "seat_" .. tostring(seat))
        end
        markerReady, markerReason = ensureReservationMarker(
            record,
            vehicle,
            passenger.seat,
            currentVehicleId
        )
        if not markerReady then
            releaseReservationMarker(record, passenger, markerReason)
            passenger.seat = nil
            record.runtime.vehicleBlockReason = markerReason or "seat_reservation_failed"
            setPassengerPosition(record, vehicle, owner)
            return true, "vehicle_passenger_waiting_seat"
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

function CompanionVehicle.Release(record, reason)
    local passenger = record and record.runtime and record.runtime.vehiclePassenger or nil
    if not passenger then return false end
    releaseReservationMarker(record, passenger, reason or "released")
    record.runtime.vehiclePassenger = nil
    record.runtime.vehicleBlockReason = nil
    return true
end

local function auditVehicle(vehicle)
    local vehicleId = vehicleKey(vehicle)
    local seen = {}
    local removed = 0
    forEachVehicleContainer(vehicle, function(part, container)
        local actualSeat = tonumber(safeMethod(part, "getContainerSeatNumber"))
        local stale = {}
        forEachContainerItem(container, function(item)
            local data = reservationData(item)
            if data then
                local key = tostring(data.npcId or "") .. ":" .. tostring(data.seat or "")
                local valid = actualSeat ~= nil and actualSeat >= 0
                    and tostring(data.vehicleId or "") == tostring(vehicleId)
                    and tonumber(data.seat) == actualSeat
                    and isActiveReservation(data, vehicleId, actualSeat)
                    and seen[key] ~= true
                if valid then
                    seen[key] = true
                else
                    stale[#stale + 1] = item
                end
            end
        end)
        local i
        for i = 1, #stale do
            if removeContainerItem(container, stale[i]) then
                removed = removed + 1
            end
        end
    end)
    return removed
end

function CompanionVehicle.AuditLoadedReservations(now, force)
    local cell
    local vehicles
    local size
    local i
    local removed = 0
    now = tonumber(now) or Core.Now()
    if not Core.IsAuthority() then return 0 end
    if not force and (now - lastReservationAuditAt)
        < (tonumber(Const.VEHICLE_RESERVATION_AUDIT_MS) or 10000)
    then
        return 0
    end
    lastReservationAuditAt = now
    cell = getCell and getCell() or nil
    vehicles = cell and safeMethod(cell, "getVehicles") or nil
    size = tonumber(safeMethod(vehicles, "size"))
    if size == nil then return 0 end
    for i = 0, size - 1 do
        removed = removed + auditVehicle(safeMethod(vehicles, "get", i))
    end
    if removed > 0 then
        Core.LogDebug("companion_vehicle audit removed stale reservations="
            .. tostring(removed))
    end
    return removed
end

return CompanionVehicle
