local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Vehicles/PNC_CompanionVehicle.lua"

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
local ownerVehicle
local owner = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 42 end,
    getVehicle = function() return ownerVehicle end,
}
local vehicle = {
    getId = function() return 7 end,
    getX = function() return 10.5 end,
    getY = function() return 20.5 end,
    getZ = function() return 0 end,
    getMaxPassengers = function() return 3 end,
    isSeatInstalled = function(_, seat) return seat >= 0 and seat <= 2 end,
    getCharacter = function(_, seat)
        if seat == 0 then return owner end
        return occupied[seat]
    end,
    isSeatOccupied = function(_, seat)
        return seat == 0 or occupied[seat] ~= nil
    end,
}
ownerVehicle = vehicle

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        PRESENCE_ABSTRACT = "abstract",
        FOLLOW_VEHICLE_BOARD_DISTANCE = 3.2,
    },
    Core = {
        Now = function() return now end,
        Distance = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt((dx * dx) + (dy * dy))
        end,
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
assertEqual(abstracted[first.id], "vehicle_board", "first abstract reason")
assertEqual(first.x, 10.5, "passenger follows vehicle x")
assertEqual(first.activeBehavior, "FollowOwner:vehicle_passenger", "passenger behavior")

handled, reason = PNC.CompanionVehicle.Tick(second, {}, owner)
assertEqual(handled, true, "second companion boards")
assertEqual(second.runtime.vehiclePassenger.seat, 2, "second reservation avoids first")

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

occupied[1] = nil
now = 1200
handled, reason = PNC.CompanionVehicle.Tick(first, nil, owner)
assertEqual(handled, true, "passenger reacquires seat")
assertEqual(reason, "vehicle_passenger", "reacquired passenger reason")
assertEqual(first.runtime.vehiclePassenger.seat, 1, "seat reacquired")

local secondVehicle = {
    getId = function() return 8 end,
    getX = function() return 30.5 end,
    getY = function() return 40.5 end,
    getZ = function() return 0 end,
    getMaxPassengers = function() return 2 end,
    isSeatInstalled = function(_, seat) return seat == 0 or seat == 1 end,
    getCharacter = function(_, seat) return seat == 0 and owner or nil end,
    isSeatOccupied = function(_, seat) return seat == 0 end,
}
ownerVehicle = secondVehicle
handled, reason = PNC.CompanionVehicle.Tick(first, nil, owner)
assertEqual(handled, true, "vehicle change stays abstract")
assertEqual(reason, "vehicle_passenger", "vehicle change passenger reason")
assertEqual(first.runtime.vehiclePassenger.vehicleId, "vehicle:8", "vehicle reservation transferred")
assertEqual(first.runtime.vehiclePassenger.seat, 1, "new vehicle seat reserved")
assertEqual(first.presenceState, "abstract", "vehicle change did not materialize")

ownerVehicle = nil
handled, reason = PNC.CompanionVehicle.Tick(first, nil, owner)
assertEqual(handled, true, "owner exit handled")
assertEqual(reason, "disembarked_live", "owner exit materializes companion")
assertEqual(first.runtime.vehiclePassenger, nil, "passenger state cleared")
assertEqual(first.presenceState, "live", "companion rematerialized")
assertEqual(materialized[first.id], "owner_exited_vehicle", "disembark materialize reason")
assertEqual(dirty[first.id], "vehicle_disembark", "disembark marked dirty")

print("pnc_companion_vehicle_smoke: ok")
