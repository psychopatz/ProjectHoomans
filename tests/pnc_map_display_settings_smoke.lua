local FILE = "Contents/mods/ProjectHoomans/42.19/media/lua/client/PNC/UI/Map/"
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
    addChild = function(self, child) self.child = child end,
}
setmetatable(map, { __index = ISWorldMap })
map:createChildren()

assert(map.pncNamesButton ~= nil, "NPC names button was not attached")
assert(map.pncNamesButton.x == 176,
    "NPC names button was not placed left of vanilla controls")
assert(map.pncNamesButton.title == "NPC NAMES: OFF",
    "NPC names default was not off")
map.pncNamesButton.onclick()
assert(PNC.MapDisplay.AreNamesVisible(),
    "NPC names button did not enable labels")
assert(map.pncNamesButton.title == "NPC NAMES: ON",
    "NPC names button title did not update")

print("pnc_map_display_settings_smoke: ok")
