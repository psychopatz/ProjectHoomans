local T = require "tests/support/test"
T.addPackagePaths()

local timestamp = 100
local specialObject = {
    getID = function() return 41 end,
}
local square = {
    getX = function() return 2 end,
    getY = function() return 2 end,
    getZ = function() return 0 end,
    getObjects = function()
        return {
            size = function() return 0 end,
            get = function() return nil end,
        }
    end,
}
local cell = {
    getGridSquare = function(_, x, y, z)
        if x == 2 and y == 2 and z == 0 then return square end
        return nil
    end,
}

getTimestampMs = function() return timestamp end
getCell = function() return cell end
PsychopatzCore = {
    RuntimeRole = {
        AllowsServerCode = function() return true end,
    },
}
PNC = {
    NearbyResourceLocator = {},
}

local Locator = T.load(
    "ProjectHoomans",
    "server",
    "PNC/World/PNC_NearbyResourceLocator.lua"
)
local found = Locator.FindObject({
    getX = function() return 2.5 end,
    getY = function() return 2.5 end,
    getZ = function() return 0 end,
}, {
    radius = 0,
    cacheKey = "special-smoke",
    specialObject = function(candidateSquare)
        if candidateSquare ~= square then return nil end
        return {
            object = specialObject,
            source = "global_test_object",
            key = "global@2:2:0",
        }
    end,
    accept = function(candidate)
        return candidate.source == "global_test_object"
    end,
})

T.truthy(found, "special square objects are discoverable")
T.equal(found.source, "global_test_object",
    "special discovery preserves its source")
T.equal(found.key, "global@2:2:0",
    "special discovery preserves its stable key")
T.equal(found.x, 2.5, "special discovery uses the square center")
T.equal(found.object, specialObject,
    "special discovery passes the live object only to the locator result")

T.finish("pnc_nearby_resource_locator_special_smoke")
