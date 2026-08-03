local FILE = "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/UI/Map/"
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
dofile(FILE)

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

assert(map.pncNamesButton ~= nil, "NPC names button was not attached")
assert(map.pncBasesButton ~= nil, "community bases button was not attached")
assert(map.pncNamesButton.x == 176,
    "NPC names button was not placed left of vanilla controls")
assert(map.pncBasesButton.x == 52,
    "community bases button was not placed beside names")
assert(map.pncNamesButton.title == "NPC NAMES: OFF",
    "NPC names default was not off")
assert(map.pncBasesButton.title == "NPC WORLD: ON",
    "authorized NPC-world map presentation was not enabled by default")
map.pncNamesButton.onclick()
assert(PNC.MapDisplay.AreNamesVisible(),
    "NPC names button did not enable labels")
assert(map.pncNamesButton.title == "NPC NAMES: ON",
    "NPC names button title did not update")
map.pncBasesButton.onclick()
assert(not PNC.MapDisplay.AreBasesVisible(),
    "NPC-world button did not disable strategic markers")
assert(map.pncBasesButton.title == "NPC WORLD: OFF",
    "NPC-world disabled title did not update")
map.pncBasesButton.onclick()
assert(PNC.MapDisplay.AreBasesVisible(),
    "NPC-world button did not enable strategic markers")
assert(map.pncBasesButton.title == "NPC WORLD: ON",
    "NPC-world enabled title did not update")

print("pnc_map_display_settings_smoke: ok")
