local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "shared", "PNC/Core/Spatial/PNC_SpatialIndex.lua")

local scans = 0
local now = 1000
local zombies = {
    {
        isDead = function() return false end,
        getX = function() return 2 end,
        getY = function() return 2 end,
        getModData = function(self)
            self.data = self.data or {}
            return self.data
        end,
    },
}

PNC = {
    Const = {
        SPATIAL_CELL_SIZE = 16,
        SPATIAL_REBUILD_MS = 100,
        PRESENCE_CORPSE = "corpse",
    },
    Core = {
        Now = function() return now end,
        GenerateID = function() return "zombie-1" end,
        ForEachPlayer = function() end,
        IsManagedNPCBody = function() return false end,
    },
    Registry = {
        ForEach = function() end,
    },
}
getCell = function()
    return {
        getZombieList = function()
            scans = scans + 1
            return {
                size = function() return #zombies end,
                get = function(_, index) return zombies[index + 1] end,
            }
        end,
    }
end

T.load(FILE)

T.equal(PNC.SpatialIndex.Rebuild(now, false), true, "initial rebuild")
T.equal(scans, 1, "initial zombie scan")
now = 1050
T.equal(PNC.SpatialIndex.Rebuild(now, false), false, "throttled rebuild")
T.equal(scans, 1, "throttled scan count")
T.equal(PNC.SpatialIndex.Rebuild(now, true), true, "forced rebuild")
T.equal(scans, 2, "forced scan count")
T.equal(#PNC.SpatialIndex.QueryZombies(2, 2, 4), 1,
    "indexed zombie query")
T.finish("pnc_spatial_throttle_smoke")

T.finish("pnc_spatial_throttle_smoke")
