local T = require "tests/support/test"

local FILE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapHoomansMenu.lua"

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

ISButton = {}
function ISButton:new(x, y, width, height, title, target, onclick)
    local button = { x = x, y = y, width = width, height = height,
        title = title, target = target, onclick = onclick,
        visible = true, enable = true }
    setmetatable(button, { __index = self })
    return button
end
function ISButton:initialise() end
function ISButton:instantiate() end
function ISButton:setTitle(value) self.title = value end
function ISButton:setX(value) self.x = value end
function ISButton:setY(value) self.y = value end
function ISButton:setHeight(value) self.height = value end
function ISButton:setEnable(value) self.enable = value end
function ISButton:setVisible(value) self.visible = value end
function ISButton:setImage(value) self.image = value end
function ISButton:forceImageSize(width, height)
    self.forcedWidthImage = width
    self.forcedHeightImage = height
end

ISWorldMap = {
    createChildren = function(self)
        self.buttonPanel = { x = 300, y = 400, width = 200, height = 48 }
    end,
    prerender = function() end,
    close = function(self) self.closed = true return "vanilla" end,
}
package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISButton"] = function() return ISButton end

getTexture = function(path) return path end
getText = function(key) return key end
getCore = function()
    return {
        getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 720 end,
    }
end

PNC = {}
T.load(FILE)
local Menu = PNC.MapHoomansMenu
local activated = false
T.truthy(Menu.Register("future_tool", {
    order = 50,
    title = "Future Tool",
    tooltip = "A future Hoomans tool",
    icon = "media/ui/MP/mp_ui_mods.png",
    iconSize = 20,
    onActivate = function() activated = true end,
}), "future menu item was not registered")

local map = { children = {}, addChild = ISPanel.addChild }
setmetatable(map, { __index = ISWorldMap })
map:createChildren()
T.truthy(map.pncHoomansButton, "Hoomans settings button was not attached")
T.equal(map.pncHoomansButton.title, "Hoomans",
    "Hoomans settings button has a readable label")
T.equal(map.pncHoomansButton.iconTexture,
    "media/ui/inventoryPanes/Button_Settings.png",
    "Hoomans reuses the vanilla settings cog")
T.equal(map.pncHoomansButton.tooltip, "Open Hoomans map settings",
    "Hoomans tooltip does not expose a raw translation key")
T.equal(map.pncHoomansButton.x, 188,
    "Hoomans button is laid out left of the vanilla map controls")
T.falsy(map.pncNamesButton, "NPC names still owns a map button")
T.falsy(map.pncBasesButton, "NPC world still owns a map button")
T.falsy(map.pncTrackButton, "Track is not registered in the settings menu")

map.pncHoomansButton.onclick()
local modal = Menu.instance
T.truthy(modal and modal.entryButtons.future_tool,
    "registered tool did not appear in the Hoomans menu")
T.equal(modal.entryButtons.future_tool.iconTexture,
    "media/ui/MP/mp_ui_mods.png",
    "menu item retained its icon")
T.truthy(modal:onButton(modal.entryButtons.future_tool),
    "registered tool did not activate")
T.truthy(activated, "registered tool callback was not called")

T.truthy(Menu.Register("later_tool", {
    order = 60,
    title = "Later Tool",
    onActivate = function() return true end,
}), "late menu item was not registered")
T.truthy(modal.entryButtons.later_tool,
    "open menu did not accept a newly registered item")
T.truthy(Menu.Unregister("later_tool"),
    "registered menu item could not be removed")
T.falsy(modal.entryButtons.later_tool.visible,
    "removed menu item stayed visible")

map:close()
T.falsy(Menu.instance, "closing the map did not close Hoomans menu")
T.equal(map.closed, true, "Hoomans close hook did not preserve vanilla close")
T.finish("pnc_map_hoomans_menu_smoke")
