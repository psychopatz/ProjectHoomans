local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

local now = 1000
local scans = 0
local zombies = {}
for i = 1, 25 do
    zombies[i] = {
        isDead = function() return false end,
        getX = function() return i end,
        getY = function() return 0 end,
        getModData = function(self)
            self.data = self.data or {}
            return self.data
        end,
    }
end

PNC = {
    Const = {
        WORLD_CENSUS_REFRESH_MS = 100,
        WORLD_CENSUS_IDLE_REFRESH_MS = 500,
        SPATIAL_REBUILD_MS = 100,
        SPATIAL_CELL_SIZE = 16,
        PRESENCE_CORPSE = "corpse",
    },
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix)
            return prefix .. "_" .. tostring(scans)
        end,
        IsManagedNPCBody = function() return false end,
        ForEachPlayer = function() end,
    },
    Registry = {
        LiveByID = {},
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

T.load(ROOT .. "World/PNC_WorldCensus.lua")
T.load(ROOT .. "Spatial/PNC_SpatialIndex.lua")

T.truthy(PNC.SpatialIndex.Rebuild(now, false) == true,
    "initial spatial rebuild failed")
T.truthy(scans == 1, "spatial rebuild did not use exactly one census scan")
T.truthy(#PNC.WorldCensus.GetAll(now, false) == 25,
    "census did not retain loaded zombies")
T.truthy(scans == 1,
    "second census consumer rescanned inside the refresh window")
T.truthy(#PNC.SpatialIndex.QueryZombies(8, 0, 16) == 25,
    "census zombies were not indexed")

now = 1050
T.truthy(PNC.WorldCensus.Refresh(now, false) == false,
    "census throttle did not hold")
T.truthy(scans == 1, "throttled census still scanned")

now = 1499
T.truthy(PNC.WorldCensus.Refresh(now, false) == false,
    "idle census refreshed before its relaxed interval")
T.truthy(scans == 1, "idle census performed an early scan")

now = 1500
T.truthy(PNC.WorldCensus.Refresh(now, false) == true,
    "census did not refresh after its interval")
T.truthy(scans == 2, "census refresh scan count is incorrect")
T.truthy(PNC.SpatialIndex.Rebuild(now, false) == true,
    "spatial index did not consume a newer census generation")
T.truthy(scans == 2,
    "spatial consumer rescanned an already-fresh census")

-- Spatial refreshes may run after another census consumer in the same census
-- generation. Rebuilding player cells must not erase the retained zombie
-- grid merely because there is no newer zombie snapshot to consume.
now = 1600
T.truthy(PNC.SpatialIndex.Rebuild(now, false) == true,
    "spatial refresh with unchanged census generation failed")
T.truthy(scans == 2,
    "unchanged census generation triggered another engine scan")
T.truthy(#PNC.SpatialIndex.QueryZombies(8, 0, 16) == 25,
    "unchanged census generation erased the zombie index")
T.finish("pnc_world_census_smoke")

T.finish("pnc_world_census_smoke")
