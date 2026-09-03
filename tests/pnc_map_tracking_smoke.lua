local T = require "tests/support/test"

local SERVICE = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapTracking.lua"
local UI = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapTrackingUI.lua"
local MENU = T.path("ProjectHoomans", "client", "PNC/UI/Map/")
    .. "PNC_MapHoomansMenu.lua"

local tickHandlers = {}
local resetHandlers = {}
local markerCalls = {}
local requests = 0
local clock = 1000
local player = { x = 0, y = 0 }
function player:getX() return self.x end
function player:getY() return self.y end

local markerHandler = { markers = {} }
function markerHandler.Set(id, icon, duration, x, y, color, desc)
    local marker = markerHandler.markers[id]
    if not marker then
        marker = {}
        function marker:getDuration() return self.duration end
    end
    marker.icon = icon
    marker.duration = duration
    marker.x = x
    marker.y = y
    marker.color = color
    marker.desc = desc
    markerHandler.markers[id] = marker
    markerCalls[#markerCalls + 1] = marker
    return marker
end
function markerHandler.Remove(id)
    if not markerHandler.markers[id] then return false end
    markerHandler.markers[id] = nil
    return true
end

package.preload["ISUI/Maps/ISWorldMap"] = function() return ISWorldMap end
package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["ISUI/ISButton"] = function() return ISButton end
package.preload["PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"] =
    function() return markerHandler end
package.preload["PsychopatzCore/World/PC_GridRegion"] = function()
    return {
        containsXY = function(region, x, y)
            local level = region and region.levels and region.levels[0]
            local rows = level and (level.rows or level) or {}
            local spans = rows[y]
            for index = 1, #(spans or {}), 2 do
                if x >= spans[index] and x <= spans[index + 1] then
                    return true
                end
            end
            return false
        end,
    }
end

ISPanel = {}
function ISPanel:derive()
    local child = {}
    setmetatable(child, { __index = self })
    child.__index = child
    return child
end
function ISPanel:new(x, y, width, height)
    local panel = {
        x = x, y = y, width = width, height = height,
        children = {}, visible = true,
    }
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
function ISPanel:prerender() end

ISButton = {}
function ISButton:new(x, y, width, height, title, target, onclick)
    local button = {
        x = x, y = y, width = width, height = height,
        title = title, target = target, onclick = onclick,
        enabled = true, visible = true,
    }
    setmetatable(button, { __index = self })
    return button
end
function ISButton:initialise() end
function ISButton:instantiate() end
function ISButton:setTitle(value) self.title = value end
function ISButton:setX(value) self.x = value end
function ISButton:setY(value) self.y = value end
function ISButton:setHeight(value) self.height = value end
function ISButton:setEnable(value) self.enabled = value end
function ISButton:setVisible(value) self.visible = value end
function ISButton:setImage(value) self.image = value end
function ISButton:forceImageSize(width, height)
    self.forcedWidthImage = width
    self.forcedHeightImage = height
end

ISWorldMap = {
    createChildren = function(self)
        self.buttonPanel = { x = 300, y = 400, height = 32 }
        self.pncDebugButton = { x = -44, y = 400, width = 88, height = 32 }
    end,
    prerender = function() end,
    close = function(self) self.closed = true return "vanilla" end,
}

Events = {
    OnTick = { Add = function(handler) tickHandlers[#tickHandlers + 1] = handler end },
    OnResetLua = { Add = function(handler) resetHandlers[#resetHandlers + 1] = handler end },
}

local translations = {
    UI_PNC_MapTrack_Button = "Track",
    UI_PNC_MapTrack_ButtonHelp = "Open Hoomans tracking options.",
    UI_PNC_MapTrack_Title = "Track",
    UI_PNC_MapTrack_Hint = "Choose a location to track.",
    UI_PNC_MapTrack_BaseOn = "BASE: ON",
    UI_PNC_MapTrack_BaseOff = "BASE: OFF",
    UI_PNC_MapTrack_BaseHelp = "Toggle the marker that guides you to your base.",
    UI_PNC_MapTrack_BaseMissing = "Create a base zone before tracking your base.",
    UI_PNC_MapTrack_BaseArrived = "You are already at your base.",
    UI_PNC_MapTrack_Marker = "Base",
}
getText = function(key) return translations[key] or key end
getTexture = function(path) return path end
getCore = function()
    return {
        getScreenWidth = function() return 1280 end,
        getScreenHeight = function() return 720 end,
    }
end
getSpecificPlayer = function() return player end
IsoUtils = {
    DistanceTo = function(x1, y1, x2, y2)
        local dx, dy = x1 - x2, y1 - y2
        return math.sqrt(dx * dx + dy * dy)
    end,
}

PNC = {
    Core = { Now = function() return clock end },
    EventMarkers = markerHandler,
    Client = {
        RequestColonyManagement = function()
            requests = requests + 1
            return true
        end,
    },
    Network = {
        ClientState = {
            colonyManagementRevision = 1,
            colonyManagement = {
                settlement = {
                    id = "base_one",
                    revision = 1,
                    geometry = {
                        region = {
                            levels = {
                                [0] = { rows = {
                                    [100] = { 100, 104 },
                                    [101] = { 100, 104 },
                                    [102] = { 100, 104 },
                                } },
                            },
                        },
                    },
                },
            },
        },
    },
}

T.load(MENU)
T.load(SERVICE)
T.load(UI)
local Tracking = PNC.MapTracking

local map = {
    children = {},
    addChild = function(self, child) self.children[#self.children + 1] = child end,
}
setmetatable(map, { __index = ISWorldMap })
map:createChildren()

T.truthy(map.pncHoomansButton, "map did not receive Hoomans settings")
T.truthy(map.pncTrackButton, "map did not receive standalone Track")
T.equal(map.pncTrackButton.title, "Track", "Track translation")
T.equal(map.pncTrackButton.iconTexture, "media/ui/MP/mp_ui_internet.png",
    "Track uses the multiplayer internet icon")
T.equal(map.pncTrackButton.tooltip, "Open Hoomans tracking options.",
    "Track tooltip does not expose a raw translation key")
map.pncTrackButton.onclick()
local modal = Tracking.instance
T.truthy(modal and modal.baseButton, "Track button did not open its modal")
T.truthy(modal.baseButton.enabled, "Base button disabled despite valid base geometry")
T.truthy(requests > 0, "opening Track did not refresh colony data")

local target = Tracking.GetBaseTarget()
T.near(target.x, 102.5, 0.001, "base target x")
T.near(target.y, 101.5, 0.001, "base target y")
T.equal(target.z, 0, "base target z")

T.truthy(modal:onButton(modal.baseButton), "enabling Base tracking failed")
T.truthy(Tracking.IsBaseTracked(), "Base tracking did not become active")
T.truthy(markerHandler.markers[Tracking.MarkerID], "base marker was not created")
T.equal(markerHandler.markers[Tracking.MarkerID].icon, "tent.png",
    "base marker icon")

clock = 1500
player.x = 20
tickHandlers[1]()
T.truthy(#markerCalls >= 2, "marker distance was not refreshed while moving")

player.x, player.y = target.x + 9, target.y
clock = 2000
tickHandlers[1]()
T.falsy(Tracking.IsBaseTracked(), "arrival did not clear Base tracking")
T.falsy(markerHandler.markers[Tracking.MarkerID],
    "arrival did not remove the base marker")

player.x, player.y = 0, 0
T.truthy(modal:onButton(modal.baseButton), "second Base enable failed")
T.falsy(modal:onButton(modal.baseButton), "Base toggle-off returned active")
T.falsy(markerHandler.markers[Tracking.MarkerID],
    "untoggle did not remove the base marker")

player.x, player.y = target.x, target.y
modal:syncButtons()
T.falsy(modal.baseButton.enabled,
    "Base button stayed enabled when player was already home")
T.equal(modal.baseButton.tooltip, "You are already at your base.",
    "already-home tooltip was not shown")
T.falsy(modal:onButton(modal.baseButton),
    "already-home Base button still attempted to toggle")

local geometry = PNC.Network.ClientState.colonyManagement.settlement.geometry
geometry.revision = 2
geometry.bounds = { minX = 100, minY = 100, maxX = 124, maxY = 100 }
geometry.region = { levels = { [0] = { rows = {
    [100] = { 100, 124 },
} } } }
PNC.Network.ClientState.colonyManagementRevision = 2
player.x, player.y = 100.5, 100.5
modal:syncButtons()
T.truthy(Tracking.IsAtBase(),
    "base containment did not recognize the settlement border")
T.falsy(modal.baseButton.enabled,
    "Base button stayed enabled inside a large settlement")
T.equal(modal.baseButton.tooltip, "You are already at your base.",
    "large-settlement already-home tooltip was not shown")

player.x, player.y = 0, 0
PNC.Network.ClientState.colonyManagementRevision = 2
PNC.Network.ClientState.colonyManagement = {}
modal:syncButtons()
T.falsy(modal.baseButton.enabled, "Base button stayed enabled without a base")
T.falsy(modal:onButton(modal.baseButton),
    "disabled Base button still toggled tracking")

map.pncTrackButton.onclick()
T.truthy(Tracking.instance, "Track modal could not be reopened")
map:close()
T.falsy(Tracking.instance, "closing the map did not close Track modal")
T.equal(map.closed, true, "map close hook did not preserve vanilla close")

T.finish("pnc_map_tracking_smoke")
