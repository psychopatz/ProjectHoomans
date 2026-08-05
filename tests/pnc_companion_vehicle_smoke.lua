local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Vehicles/PNC_CompanionVehicle.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local now = 1000
local records = {}
local abstracted = {}
local materialized = {}
local dirty = {}
local occupied = {}
local syncedAdds = 0
local syncedRemoves = 0
local loadedVehicles = {}
local owner

local function makeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function makeItem(fullType)
    local modData = {}
    local weight = 0.1
    local name = fullType
    return {
        getFullType = function() return fullType end,
        getModData = function() return modData end,
        setWeight = function(_, value) weight = value end,
        setActualWeight = function(_, value) weight = value end,
        getActualWeight = function() return weight end,
        setName = function(_, value) name = value end,
        getName = function() return name end,
    }
end

InventoryItemFactory = {
    CreateItem = function(fullType) return makeItem(fullType) end,
}

sendAddItemToContainer = function()
    syncedAdds = syncedAdds + 1
end

sendRemoveItemFromContainer = function()
    syncedRemoves = syncedRemoves + 1
end

local function makeContainer(capacity)
    local values = {}
    local container = {}
    container.getItems = function() return makeList(values) end
    container.getCapacity = function() return capacity end
    container.getCapacityWeight = function()
        local total = 0
        for _, item in ipairs(values) do total = total + item:getActualWeight() end
        return total
    end
    container.getContentsWeight = container.getCapacityWeight
    container.AddItem = function(_, item)
        values[#values + 1] = item
        return item
    end
    container.Remove = function(_, item)
        for i = #values, 1, -1 do
            if values[i] == item then table.remove(values, i) end
        end
    end
    return container
end

local function makeVehicle(id, seats, occupants, x, y)
    local parts = {}
    local vehicle = {}
    for seat = 0, seats - 1 do
        local seatNumber = seat
        local container = makeContainer(20)
        parts[seat + 1] = {
            getContainerSeatNumber = function() return seatNumber end,
            getItemContainer = function() return container end,
        }
    end
    vehicle.getId = function() return id end
    vehicle.getX = function() return x end
    vehicle.getY = function() return y end
    vehicle.getZ = function() return 0 end
    vehicle.getMaxPassengers = function() return seats end
    vehicle.isSeatInstalled = function(_, seat) return seat >= 0 and seat < seats end
    vehicle.getCharacter = function(_, seat)
        if seat == 0 then return owner end
        return occupants[seat]
    end
    vehicle.getPartForSeatContainer = function(_, seat) return parts[seat + 1] end
    vehicle.getPartCount = function() return #parts end
    vehicle.getPartByIndex = function(_, index) return parts[index + 1] end
    vehicle.isSeatOccupied = function(_, seat)
        if seat == 0 or occupants[seat] ~= nil then return true end
        local container = parts[seat + 1]:getItemContainer()
        return container:getCapacityWeight() > container:getCapacity() * 0.25
    end
    return vehicle, parts
end

getCell = function()
    return {
        getVehicles = function() return makeList(loadedVehicles) end,
    }
end

local ownerVehicle
owner = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 42 end,
    getVehicle = function() return ownerVehicle end,
}
local vehicle, vehicleParts = makeVehicle(7, 3, occupied, 10.5, 20.5)
loadedVehicles = { vehicle }
ownerVehicle = vehicle

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        FOLLOW_VEHICLE_BOARD_DISTANCE = 3.2,
    },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
        LogDebug = function() end,
        LogRecordDebug = function() end,
    },
    Registry = {
        ForEach = function(callback)
            for _, record in ipairs(records) do callback(record) end
        end,
        MarkDirty = function(record, domain)
            dirty[record.id] = domain
        end,
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record)
            record.runtime.target = nil
        end,
    },
    Presence = {
        Abstract = function(record, reason)
            abstracted[record.id] = reason
            record.presenceState = "abstract"
            return true
        end,
        Materialize = function(record, reason)
            materialized[record.id] = reason
            record.presenceState = "live"
            return { id = record.id }
        end,
        ShouldMaterialize = function() return false end,
    },
}

dofile(FILE)

local first = {
    id = "companion_1",
    alive = true,
    presenceState = "live",
    x = 9,
    y = 20,
    z = 0,
    runtime = {},
}
local second = {
    id = "companion_2",
    alive = true,
    presenceState = "live",
    x = 9.5,
    y = 20,
    z = 0,
    runtime = {},
}
local third = {
    id = "companion_3",
    alive = true,
    presenceState = "live",
    x = 9.75,
    y = 20,
    z = 0,
    runtime = {},
}
records = { first, second, third }

local handled, reason = PNC.CompanionVehicle.Tick(first, {}, owner)
assertEqual(handled, true, "first companion boards")
assertEqual(reason, "boarded", "first board reason")
assertEqual(first.runtime.vehiclePassenger.seat, 1, "first free seat")
assertEqual(first.presenceState, "abstract", "first body abstracted")
assertEqual(vehicle:isSeatOccupied(1), true, "first reservation occupies vanilla seat")
local reserved, reservedName = PNC.CompanionVehicle.GetSeatReservation(vehicle, 1)
assertEqual(reserved, true, "first reservation is visible")
assertEqual(reservedName, first.id, "first reservation identifies npc")
assertEqual(abstracted[first.id], "vehicle_board", "first abstract reason")
assertEqual(first.x, 10.5, "passenger follows vehicle x")
assertEqual(first.activeBehavior, "FollowOwner:vehicle_passenger", "passenger behavior")

handled, reason = PNC.CompanionVehicle.Tick(second, {}, owner)
assertEqual(handled, true, "second companion boards")
assertEqual(second.runtime.vehiclePassenger.seat, 2, "second reservation avoids first")
assertEqual(vehicle:isSeatOccupied(2), true, "second reservation occupies vanilla seat")

handled, reason = PNC.CompanionVehicle.Tick(third, {}, owner)
assertEqual(handled, false, "full vehicle rejects third companion")
assertEqual(reason, "vehicle_full", "full vehicle reason")
assertEqual(third.runtime.vehiclePassenger, nil, "full vehicle did not abstract third")

occupied[1] = { id = "real_player" }
handled, reason = PNC.CompanionVehicle.Tick(first, nil, owner)
assertEqual(handled, true, "lost reserved seat remains safe")
assertEqual(reason, "vehicle_passenger_waiting_seat", "lost seat wait reason")
assertEqual(first.runtime.vehiclePassenger.seat, nil, "lost seat reservation cleared")
assertEqual(first.presenceState, "abstract", "lost seat did not materialize by moving car")
assertEqual(PNC.CompanionVehicle.GetSeatReservation(vehicle, 1), false,
    "lost reservation token removed")

occupied[1] = nil
now = 1200
handled, reason = PNC.CompanionVehicle.Tick(first, nil, owner)
assertEqual(handled, true, "passenger reacquires seat")
assertEqual(reason, "vehicle_passenger", "reacquired passenger reason")
assertEqual(first.runtime.vehiclePassenger.seat, 1, "seat reacquired")

local secondOccupied = {}
local secondVehicle, secondVehicleParts = makeVehicle(8, 2, secondOccupied, 30.5, 40.5)
loadedVehicles[#loadedVehicles + 1] = secondVehicle
ownerVehicle = secondVehicle
handled, reason = PNC.CompanionVehicle.Tick(first, nil, owner)
assertEqual(handled, true, "vehicle change stays abstract")
assertEqual(reason, "vehicle_passenger", "vehicle change passenger reason")
assertEqual(first.runtime.vehiclePassenger.vehicleId, "vehicle:8", "vehicle reservation transferred")
assertEqual(first.runtime.vehiclePassenger.seat, 1, "new vehicle seat reserved")
assertEqual(first.presenceState, "abstract", "vehicle change did not materialize")
assertEqual(PNC.CompanionVehicle.GetSeatReservation(vehicle, 1), false,
    "old vehicle token removed")
assertEqual(PNC.CompanionVehicle.GetSeatReservation(secondVehicle, 1), true,
    "new vehicle token installed")

ownerVehicle = nil
handled, reason = PNC.CompanionVehicle.Tick(first, nil, owner)
assertEqual(handled, true, "owner exit handled")
assertEqual(reason, "disembarked_live", "owner exit materializes companion")
assertEqual(first.runtime.vehiclePassenger, nil, "passenger state cleared")
assertEqual(first.presenceState, "live", "companion rematerialized")
assertEqual(materialized[first.id], "owner_exited_vehicle", "disembark materialize reason")
assertEqual(dirty[first.id], "vehicle_disembark", "disembark marked dirty")
assertEqual(PNC.CompanionVehicle.GetSeatReservation(secondVehicle, 1), false,
    "disembark releases vanilla seat")
assertEqual(syncedAdds >= 4, true, "reservation additions synchronized")
assertEqual(syncedRemoves >= 3, true, "reservation removals synchronized")

local stale = makeItem("PNC.VehicleSeatReservation")
local staleData = stale:getModData()
staleData.PNC_VehicleSeatReservation = true
staleData.PNC_NPC_ID = "missing_npc"
staleData.PNC_NPC_NAME = "Missing NPC"
staleData.PNC_VEHICLE_ID = "vehicle:8"
staleData.PNC_SEAT = 1
secondVehicleParts[2]:getItemContainer():AddItem(stale)
local removed = PNC.CompanionVehicle.AuditLoadedReservations(now, true)
assertEqual(removed, 1, "audit removes stale persisted token")
assertEqual(PNC.CompanionVehicle.GetSeatReservation(secondVehicle, 1), false,
    "stale persisted token no longer occupies seat")

print("pnc_companion_vehicle_smoke: ok")
