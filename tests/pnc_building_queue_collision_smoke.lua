local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" } })

local tile = { getSpriteName = function() return "wide_wall" end }
local face = {
    getzLayers = function() return 1 end,
    getWidth = function() return 2 end,
    getHeight = function() return 1 end,
    getTileInfo = function() return tile end,
}
local info = { getFace = function() return face end }

local Collision = T.load("ProjectHoomans", "shared",
    "PNC/Core/Settlement/PNC_BuildingQueueCollision.lua")
local candidate = Collision.FootprintForBlueprint({
    objectInfoName = "WideWall", nSprite = 1, x = 10, y = 10, z = 0,
}, info)
local resolver = function() return info end

local conflict, overlap = Collision.Find(candidate, {
    { id = "work:blocked", status = "BLOCKED", blueprint = {
        objectInfoName = "WideWall", nSprite = 1,
        x = 11, y = 10, z = 0,
    } },
}, resolver)
T.truthy(conflict, "overlapping multi-tile blueprint was not detected")
T.equal(conflict.id, "work:blocked",
    "collision returned the wrong queued blueprint")
T.truthy(overlap, "collision did not return its intersecting footprint")

local completed = Collision.Find(candidate, {
    { id = "work:done", status = "COMPLETED", blueprint = {
        objectInfoName = "WideWall", nSprite = 1,
        x = 11, y = 10, z = 0,
    } },
}, resolver)
T.falsy(completed, "completed blueprint still blocked placement")

T.finish("pnc_building_queue_collision_smoke")
