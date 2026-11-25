local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/Pathing/")

PNC = {
    Const = {},
    Core = {
        Now = function() return 10000 end,
        LogInfo = function() end,
        LogWarn = function() end,
    },
}

T.load(ROOT .. "PNC_TraversalQuery.lua")

local function makeSquare(x, y, z, opts)
    opts = opts or {}
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
        isSolid = function() return opts.solid == true end,
        isSolidTrans = function() return false end,
        isFree = function() return opts.free ~= false end,
        isVehicleIntersecting = function() return opts.vehicle == true end,
        isOnFire = function() return opts.fire == true end,
        getDoorTo = function(_, other)
            return opts.doorTo and opts.doorTo(other) or nil
        end,
        getWindowTo = function(_, other)
            return opts.windowTo and opts.windowTo(other) or nil
        end,
    }
end

-- 1. Direct vehicle and fire occupancy rejection (zero VehicleAvoidance wrapper)
local fireCell = {
    getGridSquare = function(_, x, y, z)
        if x == 5 then return makeSquare(5, 5, 0, { fire = true }) end
        if x == 6 then return makeSquare(6, 5, 0, { vehicle = true }) end
        return makeSquare(x, y, z)
    end,
}
T.equal(PNC.TraversalQuery.GetOccupancyReason(5, 5, 0, fireCell), "fire", "rejects burning square")
T.equal(PNC.TraversalQuery.GetOccupancyReason(6, 5, 0, fireCell), "vehicle", "rejects vehicle-intersecting square directly")
T.equal(PNC.TraversalQuery.CanOccupy(7, 5, 0, fireCell), true, "allows clean open square")

-- 2. Door-over-window priority when an unlocked door sits 1 tile over on the same wall
local windowObj = { id = "win_1", smashWindow = function() end, isGlassRemoved = function() return false end }
local doorObj = { id = "door_1", ToggleDoor = function() end, isBarricaded = function() return false end }

local sqMap = {}
sqMap["10:10"] = makeSquare(10, 10, 0, {
    windowTo = function(o) return o:getX() == 11 and o:getY() == 10 and windowObj or nil end,
})
sqMap["11:10"] = makeSquare(11, 10, 0)
sqMap["10:11"] = makeSquare(10, 11, 0, {
    doorTo = function(o) return o:getX() == 11 and o:getY() == 11 and doorObj or nil end,
})
sqMap["11:11"] = makeSquare(11, 11, 0)

local wallCell = {
    getGridSquare = function(_, x, y)
        return sqMap[tostring(x) .. ":" .. tostring(y)]
    end,
}
local actor = { getX = function() return 10.5 end, getY = function() return 10.5 end, getZ = function() return 0 end }
local chosen = PNC.TraversalQuery.FindPassageToward(actor, 13.5, 10.5, 0, wallCell)
T.truthy(chosen, "finds passage toward goal")
T.equal(chosen.object.id, "door_1", "prioritizes unlocked door 1 tile over instead of climbing window")

-- 3. Falls back to window when adjacent door is barricaded
doorObj.isBarricaded = function() return true end
local chosenBarricaded = PNC.TraversalQuery.FindPassageToward(actor, 13.5, 10.5, 0, wallCell)
T.truthy(chosenBarricaded, "falls back to window when adjacent door is barricaded")
T.equal(chosenBarricaded.object.id, "win_1", "uses window when adjacent door is barricaded")

T.finish("pnc_movement_door_priority_and_fire_smoke")
