local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" }, { "PsychopatzCore", "common" } })

local function event()
    local value = { callback = nil }
    function value.Add(callback) value.callback = callback end
    return value
end

Events = {
    OnDoTileBuilding2 = event(), OnPreUIDraw = event(), OnGameStart = event(),
}
ISBaseObject, ISBuildingObject, ISBuildIsoEntity = nil, nil, nil
ISPNCBuildPlacementCursor = nil

local toolTip = {
    visible = false, title = nil, description = nil,
}
function toolTip:setVisible(value) self.visible = value end
function toolTip:addToUIManager() self.added = true end
function toolTip:removeFromUIManager() self.removed = true end
function toolTip:setName(value) self.title = value end
function toolTip:setTexture(value) self.texture = value end
ISWorldObjectContextMenu = {
    addToolTip = function() return toolTip end,
}

local insideSquare = {
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
local outsideSquare = {
    getX = function() return 30 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
local cell = {}
function cell:setDrag(cursor) self.drag = cursor end
function cell:getDrag() return self.drag end
function cell:getGridSquare(_, x) return x == 30 and outsideSquare or insideSquare end

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
local highlights = 0
addAreaHighlightForPlayer = function() highlights = highlights + 1 end

local queued
PNC = {
    Network = {
        ClientState = {
            colonyManagement = {
                settlement = {
                    geometry = { region = { levels = {
                        [0] = { rows = { [20] = { 0, 20 } } },
                    } } },
                },
            },
        },
    },
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
T.truthy(Placement.Begin(window, {
    recipeKey = "TestWall", objectInfoName = "TestWall",
}), "feedback placement did not start")

Events.OnPreUIDraw.callback()
T.truthy(highlights > 0, "placement did not render the transient base guide")

Events.OnDoTileBuilding2.callback(window.buildPlacement, false,
    30, 20, 0, outsideSquare)
T.falsy(queued, "outside-base placement sent a queue request")
T.equal(window.buildPlacement.pncPlacementError,
    "BUILD_TARGET_OUTSIDE_BASE", "outside-base reason was not retained")
T.equal(toolTip.title, "INVALID PLACEMENT",
    "outside-base tooltip did not expose its title")
T.contains(toolTip.description, "Outside home base",
    "outside-base tooltip did not explain the boundary")

Events.OnDoTileBuilding2.callback(window.buildPlacement, false,
    10, 20, 0, insideSquare)
T.equal(queued.action, "building_queue",
    "valid placement did not use the normal queue request")
T.falsy(toolTip.visible, "placement tooltip remained visible after queueing")

T.finish("pnc_building_placement_feedback_smoke")
