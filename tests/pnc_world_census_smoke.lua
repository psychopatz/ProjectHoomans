local ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/"

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

dofile(ROOT .. "World/PNC_WorldCensus.lua")
dofile(ROOT .. "Spatial/PNC_SpatialIndex.lua")

assert(PNC.SpatialIndex.Rebuild(now, false) == true,
    "initial spatial rebuild failed")
assert(scans == 1, "spatial rebuild did not use exactly one census scan")
assert(#PNC.WorldCensus.GetAll(now, false) == 25,
    "census did not retain loaded zombies")
assert(scans == 1,
    "second census consumer rescanned inside the refresh window")
assert(#PNC.SpatialIndex.QueryZombies(8, 0, 16) == 25,
    "census zombies were not indexed")

now = 1050
assert(PNC.WorldCensus.Refresh(now, false) == false,
    "census throttle did not hold")
assert(scans == 1, "throttled census still scanned")

now = 1499
assert(PNC.WorldCensus.Refresh(now, false) == false,
    "idle census refreshed before its relaxed interval")
assert(scans == 1, "idle census performed an early scan")

now = 1500
assert(PNC.WorldCensus.Refresh(now, false) == true,
    "census did not refresh after its interval")
assert(scans == 2, "census refresh scan count is incorrect")
assert(PNC.SpatialIndex.Rebuild(now, false) == true,
    "spatial index did not consume a newer census generation")
assert(scans == 2,
    "spatial consumer rescanned an already-fresh census")

print("pnc_world_census_smoke: ok")
