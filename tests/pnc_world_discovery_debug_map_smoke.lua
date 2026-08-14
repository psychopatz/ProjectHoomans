local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function equal(actual, expected, label)
    if actual ~= expected then
        error((label or "equal") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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
        self.pncBasesButton = { x = 52 }
    end,
    prerender = function() end,
    onRightMouseUp = function()
        originalCalls = originalCalls + 1
        return "vanilla"
    end,
}
package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISButton"] = function() return ISButton end

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
getText = function(key) return key end
getCore = function()
    return { getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 720 end }
end

dofile(ROOT .. "client/PNC/UI/Map/PNC_WorldDiscoveryDebugMap.lua")
local map = { children = {}, addChild = ISPanel.addChild }
setmetatable(map, { __index = ISWorldMap })
map:createChildren()

equal(map:onRightMouseUp(10, 20), "vanilla",
    "PNC discovery debug leaves the vanilla teleport menu untouched")
equal(originalCalls, 1, "vanilla right-click handler runs exactly once")
assert(map.pncDebugButton, "authorized map did not receive a debug button")
equal(map.pncDebugButton.x, -44,
    "debug button is laid out beside the NPC world controls")

map.pncDebugButton.onclick()
local modal = PNC.WorldDiscoveryDebugMap.instance
assert(modal and modal.allButton and modal.resetButton,
    "debug button did not open the scalable settings modal")
modal:onButton(modal.allButton)
equal(requests[#requests].action, "debug_discover_all",
    "modal discover-all uses the authoritative action")
equal(requests[#requests].args.scope, "all",
    "modal discover-all sends an explicit scope")
modal:onButton(modal.resetButton)
equal(requests[#requests].action, "debug_reset",
    "modal exposes recovery from an accidental discover-all")

equal(PNC.WorldDiscoveryDebugMap.ShowRawEntities, false,
    "undiscovered debug overlays start hidden")
modal:onButton(modal.rawButton)
equal(PNC.WorldDiscoveryDebugMap.ShowRawEntities, true,
    "raw overlays require an explicit modal toggle")

print("pnc_world_discovery_debug_map_smoke: ok")
