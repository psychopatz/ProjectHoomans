local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local function derive()
    local class = {}
    function class:derive()
        return derive()
    end
    function class:new(character, info, nSprite, containers)
        return setmetatable({ character = character, info = info,
            nSprite = nSprite, containers = containers }, { __index = class })
    end
    return class
end

ISBaseObject = nil
ISBuildingObject = nil
ISBuildIsoEntity = nil
ISInventoryPaneContextMenu = {
    getContainers = function() return { "player-container" } end,
}
package.preload["ISBaseObject"] = function()
    ISBaseObject = {}
    return ISBaseObject
end
package.preload["BuildingObjects/ISBuildingObject"] = function()
    ISBuildingObject = derive()
    return ISBuildingObject
end
package.preload["BuildingObjects/ISBuildIsoEntity"] = function()
    if not ISBuildingObject then error("building base was not loaded") end
    ISBuildIsoEntity = ISBuildingObject:derive("ISBuildIsoEntity")
    return ISBuildIsoEntity
end
-- The production game has this vanilla class loaded by the build menu before
-- the colony UI opens. Seed the same native path for this focused smoke test.
ISBuildIsoEntity = derive()

local character = {
    getPlayerNum = function() return 0 end,
}
local cell = {}
function cell:setDrag(cursor)
    self.drag = cursor
end
function cell:getDrag()
    return self.drag
end

getSpecificPlayer = function() return character end
getCell = function() return cell end
PNC = {
    BuildRecipeCatalog = {
        Get = function()
            return { nativeObjectInfo = {} }
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
T.equal(ok, true, "placement creates a world cursor")
T.falsy(reason, "placement has no failure reason")
T.truthy(window.buildPlacement, "placement cursor is retained by the window")
T.equal(cell:getDrag(), window.buildPlacement,
    "placement cursor is registered with IsoCell")
T.equal(window.buildPlacement.containers[1], "player-container",
    "native placement receives vanilla crafting containers")

Placement.Cancel(window)
T.falsy(window.buildPlacement, "cancel clears the placement cursor")
T.falsy(cell:getDrag(), "cancel clears the IsoCell drag state")

local placementControls
package.preload[
    "PNC/UI/Communities/ColonyManagement/PNC_BuildingPlacementModal"
] = function()
    return { Open = function(options) placementControls = options end }
end
PNC.FacilityBuildUI = {
    RestorePrevious = function() end,
    Reopen = function() end,
}
local facilityWindow = {}
local facilityOk = Placement.Begin(facilityWindow, {
    recipeKey = "TestWorkstation", objectInfoName = "TestWall",
    facilityDefinitionId = "primitive_furnace",
    facilityBaseId = "base-1", facilityExpectedRevision = 2,
})
T.equal(facilityOk, true, "facility placement creates the native cursor")
T.truthy(placementControls,
    "facility placement opens the rotate/back placement controls")
Placement.Cancel(facilityWindow, { restorePrevious = false })
T.falsy(facilityWindow.buildPlacement,
    "facility placement back path clears the native cursor")

T.finish("pnc_building_placement_smoke")
