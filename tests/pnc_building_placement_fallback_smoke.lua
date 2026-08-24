local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local function event()
    local value = { callback = nil }
    function value.Add(callback) value.callback = callback end
    return value
end

Events = { OnDoTileBuilding2 = event(), OnGameStart = event() }
ISBaseObject, ISBuildingObject, ISBuildIsoEntity = nil, nil, nil
ISPNCBuildPlacementCursor = nil

local square = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
local cell = {}
function cell:setDrag(cursor) self.drag = cursor end
function cell:getDrag() return self.drag end
function cell:getGridSquare() return square end

local character = { getPlayerNum = function() return 0 end }
getSpecificPlayer = function() return character end
getCell = function() return cell end
getWorld = function()
    return { isValidSquare = function() return true end }
end

local tile = { getSpriteName = function() return "carpentry_01_1" end }
local face = {
    getzLayers = function() return 1 end,
    getWidth = function() return 1 end,
    getHeight = function() return 1 end,
    getTileInfo = function() return tile end,
}
local info = { getFace = function() return face end }
local queued
PNC = {
    BuildRecipeCatalog = {
        Get = function() return { nativeObjectInfo = info } end,
    },
    Client = {
        RequestColonyAction = function(action, options)
            queued = { action = action, options = options }
        end,
    },
    Core = { LogWarn = function() end },
}

local Placement = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacement.lua")
local window = {}
local ok, reason = Placement.Begin(window, {
    recipeKey = "TestWall", objectInfoName = "TestWall",
})
T.equal(ok, true, "fallback placement creates a cursor without base server classes")
T.falsy(reason, "fallback placement has no failure reason")
T.truthy(window.buildPlacement, "fallback cursor is retained by the window")
T.equal(cell:getDrag(), window.buildPlacement,
    "fallback cursor is registered with IsoCell")

Events.OnDoTileBuilding2.callback(window.buildPlacement, false,
    10, 20, 0, square)
T.equal(queued.action, "building_queue",
    "fallback cursor uses the normal building queue request")
T.equal(queued.options.x, 10, "fallback queue receives target x")
T.equal(queued.options.y, 20, "fallback queue receives target y")
T.falsy(cell:getDrag(), "fallback placement clears the IsoCell drag state")

T.finish("pnc_building_placement_fallback_smoke")
