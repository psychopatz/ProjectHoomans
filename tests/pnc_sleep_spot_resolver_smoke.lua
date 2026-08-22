local T = require "tests/support/test"

T.addPackagePaths()

local function javaList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local bedObjects = {}
local squares = {}
local function square(x, y, objects, free)
    local value = {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return 0 end,
        getObjects = function() return javaList(objects or {}) end,
        isFree = function() return free ~= false end,
    }
    squares[x .. ":" .. y .. ":0"] = value
    return value
end

local sleepSquare = square(10, 20, bedObjects, false)
square(10, 21, {}, true)
square(11, 20, {}, true)
square(10, 19, {}, true)
square(9, 20, {}, true)

getCell = function()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[x .. ":" .. y .. ":" .. z]
        end,
    }
end

PNC = {}
local Targets = require "PNC/Settlement/PNC_InteractionTargetResolver"
local component = {
    id = "sleep_a", revision = 1, kind = "anchor", role = "sleep.bed",
    targetResolver = "sleepSpot", x = 10, y = 20, z = 0,
}

local target = Targets.Resolve(component)[1]
T.equal(target.sceneId, "facility.sleep.floor", "empty spot uses floor XML")
T.equal(target.x, 10.5, "floor sleep x")
T.equal(target.y, 20.5, "floor sleep y")
T.equal(target.interactionX, nil, "floor sleep does not teleport")

local properties = {
    get = function(_, key)
        local values = { CustomName = "Bed", BedType = "GoodBed", Facing = "E" }
        return values[key]
    end,
}
local grid = {
    getSpriteGridPosX = function() return 0 end,
    getSpriteGridPosY = function() return 0 end,
    getWidth = function() return 2 end,
    getHeight = function() return 1 end,
}
local sprite = {
    getName = function() return "furniture_bedding_01_0" end,
    getProperties = function() return properties end,
    getSpriteGrid = function() return grid end,
}
bedObjects[1] = {
    getSprite = function() return sprite end,
    getProperties = function() return properties end,
}

target = Targets.Resolve(component)[1]
T.equal(target.sceneId, "facility.sleep.bed", "new bed changes XML without reassignment")
T.equal(target.x, 10.5, "bed approach x")
T.equal(target.y, 21.5, "bed approach y")
T.equal(target.interactionX, 11, "multi-tile bed center x")
T.equal(target.interactionY, 20.5, "multi-tile bed center y")
T.equal(target.interactionAxis, "x", "bed long axis")
T.equal(target.sleepSurface, "bed", "bed surface metadata")

bedObjects[1] = nil
component.targetResolver = nil
target = Targets.Resolve(component)[1]
T.equal(target.sceneId, "facility.sleep.floor",
    "legacy resolver-less spot returns to floor XML")
T.finish("pnc_sleep_spot_resolver_smoke")

T.finish("pnc_sleep_spot_resolver_smoke")
