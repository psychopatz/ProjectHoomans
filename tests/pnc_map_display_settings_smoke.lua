local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapDisplaySettings.lua"

package.preload["ISUI/Maps/ISWorldMap"] = function() return true end
package.preload["ISUI/ISButton"] = function() return true end

ISWorldMap = {
    createChildren = function(self)
        self.buttonPanel = {
            x = 300,
            y = 400,
            height = 32,
        }
    end,
    prerender = function() end,
}

ISButton = {}
function ISButton:new(x, y, width, height, title, target, onclick)
    local button = {
        x = x,
        y = y,
        width = width,
        height = height,
        title = title,
        target = target,
        onclick = onclick,
    }
    function button:initialise() end
    function button:instantiate() end
    function button:setTitle(value) self.title = value end
    function button:setX(value) self.x = value end
    function button:setY(value) self.y = value end
    function button:setHeight(value) self.height = value end
    return button
end

PNC = {}
T.load(FILE)

local map = {
    width = 500,
    height = 500,
    children = {},
    addChild = function(self, child)
        self.children[#self.children + 1] = child
    end,
}
setmetatable(map, { __index = ISWorldMap })
map:createChildren()

T.truthy(map.pncNamesButton ~= nil, "NPC names button was not attached")
T.truthy(map.pncBasesButton ~= nil, "community bases button was not attached")
T.truthy(map.pncNamesButton.x == 176,
    "NPC names button was not placed left of vanilla controls")
T.truthy(map.pncBasesButton.x == 52,
    "community bases button was not placed beside names")
T.truthy(map.pncNamesButton.title == "NPC NAMES: OFF",
    "NPC names default was not off")
T.truthy(map.pncBasesButton.title == "NPC WORLD: ON",
    "authorized NPC-world map presentation was not enabled by default")
map.pncNamesButton.onclick()
T.truthy(PNC.MapDisplay.AreNamesVisible(),
    "NPC names button did not enable labels")
T.truthy(map.pncNamesButton.title == "NPC NAMES: ON",
    "NPC names button title did not update")
map.pncBasesButton.onclick()
T.truthy(not PNC.MapDisplay.AreBasesVisible(),
    "NPC-world button did not disable strategic markers")
T.truthy(map.pncBasesButton.title == "NPC WORLD: OFF",
    "NPC-world disabled title did not update")
map.pncBasesButton.onclick()
T.truthy(PNC.MapDisplay.AreBasesVisible(),
    "NPC-world button did not enable strategic markers")
T.truthy(map.pncBasesButton.title == "NPC WORLD: ON",
    "NPC-world enabled title did not update")
T.finish("pnc_map_display_settings_smoke")

T.finish("pnc_map_display_settings_smoke")
