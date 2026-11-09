local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "PsychopatzCore", "client" },
    { "PsychopatzCore", "common" },
})

local ROOT = T.path("ProjectHoomans", "root", "")
local MENU = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
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

ISButton = {}
function ISButton:new(x, y, width, height, title, target, onclick)
    local button = { x = x, y = y, width = width, height = height,
        title = title, target = target, onclick = onclick, visible = true }
    setmetatable(button, { __index = self })
    return button
end
function ISButton:initialise() end
function ISButton:instantiate() end
function ISButton:setTitle(value) self.title = value end
function ISButton:setX(value) self.x = value end
function ISButton:setY(value) self.y = value end
function ISButton:setHeight(value) self.height = value end
function ISButton:setVisible(value) self.visible = value end

local originalCalls = 0
ISWorldMap = {
    createChildren = function(self)
        self.buttonPanel = { x = 300, y = 400, height = 32 }
    end,
    prerender = function() end,
    onRightMouseUp = function()
        originalCalls = originalCalls + 1
        return "vanilla"
    end,
}
ISContextMenu = {}
function ISContextMenu.get()
    return { addOption = function() end }
end
package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISButton"] = function() return ISButton end
package.preload["ISUI/ISContextMenu"] = function() return ISContextMenu end

local requests = {}
PNC = {
    Client = {
        CanUseDebug = function() return true end,
        RequestWorldDiscovery = function(action, args)
            requests[#requests + 1] = { action = action, args = args }
            return true
        end,
        RequestCommunityDebug = function() return true end,
        RequestDirectorDebug = function() return true end,
    },
    MapTravelLayer = { InvalidateEntryCache = function() end },
}
isDebugEnabled = function() return true end
getText = function(key) return key end
getCore = function()
    return { getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 720 end }
end

T.load(MENU)
T.load(ROOT .. "client/PNC/UI/Map/PNC_MapRawEntityDebug.lua")
local map = { children = {}, addChild = ISPanel.addChild }
setmetatable(map, { __index = ISWorldMap })
map:createChildren()

T.equal(map:onRightMouseUp(10, 20), "vanilla",
    "PNC discovery debug leaves the vanilla teleport menu untouched")
T.equal(originalCalls, 1, "vanilla right-click handler runs exactly once")
T.truthy(map.psychopatzMapToolsButton,
    "authorized map did not receive Core map tools")
map.psychopatzMapToolsButton.onclick()
local menu = PNC.MapHoomansMenu.instance
T.truthy(menu and menu.entryButtons["ProjectHoomans:raw_entities"],
    "shared map menu did not receive the raw-overlay entry")
local rawButton = menu.entryButtons["ProjectHoomans:raw_entities"]
T.equal(PNC.MapRawEntityDebug.ShowRawEntities, false,
    "undiscovered debug overlays start hidden")
menu:onButton(rawButton)
T.equal(PNC.MapRawEntityDebug.ShowRawEntities, true,
    "raw overlays require an explicit shared-menu toggle")
T.finish("pnc_world_discovery_debug_map_smoke")
