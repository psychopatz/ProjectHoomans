local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapDisplaySettings.lua"
local MENU = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapHoomansMenu.lua"

package.preload["ISUI/Maps/ISWorldMap"] = function() return true end
package.preload["ISUI/ISButton"] = function() return true end
package.preload["ISUI/ISPanel"] = function() return true end

ISPanel = {}
function ISPanel:derive()
    local child = {}
    setmetatable(child, { __index = self })
    child.__index = child
    return child
end
function ISPanel:new(x, y, width, height)
    local panel = { x = x, y = y, width = width, height = height,
        children = {}, visible = true }
    setmetatable(panel, { __index = self })
    return panel
end
function ISPanel:initialise() end
function ISPanel:createChildren() end
function ISPanel:instantiate() self:createChildren() end
function ISPanel:addChild(child) self.children[#self.children + 1] = child end
function ISPanel:addToUIManager() end
function ISPanel:removeFromUIManager() end
function ISPanel:bringToTop() end
function ISPanel:setAlwaysOnTop() end
function ISPanel:setCapture() end
function ISPanel:setVisible(value) self.visible = value end
function ISPanel:drawRect() end
function ISPanel:drawRectBorder() end
function ISPanel:drawTextCentre() end
function ISPanel:drawText() end

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
    function button:setVisible(value) self.visible = value end
    function button:setEnable(value) self.enable = value end
    function button:setImage(value) self.image = value end
    function button:forceImageSize(width, height)
        self.forcedWidthImage = width
        self.forcedHeightImage = height
    end
    return button
end

PNC = {}
T.load(MENU)
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

T.truthy(map.pncHoomansButton ~= nil, "Hoomans button was not attached")
T.falsy(map.pncNamesButton, "NPC names retained a standalone button")
T.falsy(map.pncBasesButton, "NPC world retained a standalone button")
map.pncHoomansButton.onclick()
local menu = PNC.MapHoomansMenu.instance
T.truthy(menu and menu.entryButtons.npc_names,
    "Hoomans menu did not register NPC names")
T.truthy(menu.entryButtons.npc_world,
    "Hoomans menu did not register NPC world")
local namesButton = menu.entryButtons.npc_names
local basesButton = menu.entryButtons.npc_world
T.truthy(namesButton.title == "NPC NAMES: OFF",
    "NPC names default was not off")
T.truthy(basesButton.title == "NPC WORLD: ON",
    "authorized NPC-world map presentation was not enabled by default")
menu:onButton(namesButton)
T.truthy(PNC.MapDisplay.AreNamesVisible(),
    "NPC names button did not enable labels")
T.truthy(namesButton.title == "NPC NAMES: ON",
    "NPC names button title did not update")
menu:onButton(basesButton)
T.truthy(not PNC.MapDisplay.AreBasesVisible(),
    "NPC-world button did not disable strategic markers")
T.truthy(basesButton.title == "NPC WORLD: OFF",
    "NPC-world disabled title did not update")
menu:onButton(basesButton)
T.truthy(PNC.MapDisplay.AreBasesVisible(),
    "NPC-world button did not enable strategic markers")
T.truthy(basesButton.title == "NPC WORLD: ON",
    "NPC-world enabled title did not update")
T.finish("pnc_map_display_settings_smoke")

T.finish("pnc_map_display_settings_smoke")
