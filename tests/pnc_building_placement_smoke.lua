local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "client" } })

local function derive()
    local class = {}
    function class:derive()
        return derive()
    end
    function class:new(character, info, nSprite)
        return setmetatable({ character = character, info = info,
            nSprite = nSprite }, { __index = class })
    end
    return class
end

ISBaseObject = nil
ISBuildingObject = nil
ISBuildIsoEntity = nil
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

Placement.Cancel(window)
T.falsy(window.buildPlacement, "cancel clears the placement cursor")
T.falsy(cell:getDrag(), "cancel clears the IsoCell drag state")

T.finish("pnc_building_placement_smoke")
