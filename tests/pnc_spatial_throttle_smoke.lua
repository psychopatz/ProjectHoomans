local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Spatial/PNC_SpatialIndex.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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

dofile(FILE)

assertEqual(PNC.SpatialIndex.Rebuild(now, false), true, "initial rebuild")
assertEqual(scans, 1, "initial zombie scan")
now = 1050
assertEqual(PNC.SpatialIndex.Rebuild(now, false), false, "throttled rebuild")
assertEqual(scans, 1, "throttled scan count")
assertEqual(PNC.SpatialIndex.Rebuild(now, true), true, "forced rebuild")
assertEqual(scans, 2, "forced scan count")
assertEqual(#PNC.SpatialIndex.QueryZombies(2, 2, 4), 1,
    "indexed zombie query")

print("pnc_spatial_throttle_smoke: ok")
