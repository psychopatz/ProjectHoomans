local T = require "tests/support/test"

local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function() return true end
package.preload["PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"] = function() return true end
package.preload["PNC/UI/NPCMonitor/PNC_NPCMonitorSupport"] = function() return true end
package.preload["PNC/UI/Communities/ColonyManagement/PNC_ProvisionDiagnosticsModal"] = function() return true end
package.preload["PNC/UI/NPCMonitor/PNC_NPCMonitorView"] = function() return true end
package.preload["ISUI/ISContextMenu"] = function()
    ISContextMenu = ISContextMenu or {}
    return ISContextMenu
end

local markerCalls = {}
local removals = {}
local rosterRequests = 0
local onTick
local now = 1000
local selected = {
    id = "npc_anton",
    name = "Anton",
    tacticalClass = "colonist",
    presenceState = "abstract",
    x = 100,
    y = 200,
}

PsychopatzCore = {
    UI = {
        SetButtonVariant = function() end,
        NewWindow = function() return nil end,
    },
    EventMarkers = {
        markers = {},
        Set = function(id, icon, duration, x, y, color, description)
            markerCalls[#markerCalls + 1] = {
                id = id, icon = icon, duration = duration, x = x, y = y,
                color = color, description = description,
            }
        end,
        Remove = function(id) removals[#removals + 1] = id end,
    },
}

Events = {
    OnTick = { Add = function(callback) onTick = callback end },
    OnResetLua = { Add = function() end },
}

local BaseWindow = {}
BaseWindow.__index = BaseWindow
function BaseWindow:derive(name)
    local class = { Type = name }
    class.__index = class
    setmetatable(class, { __index = self })
    return class
end
function BaseWindow:initialise() end
function BaseWindow:createChildren() end
function BaseWindow:prerender() end
function BaseWindow:render() end
function BaseWindow:new() return setmetatable({}, self) end
PsychopatzWindow = BaseWindow

PNC = {
    EventMarkers = PsychopatzCore.EventMarkers,
    Core = { Now = function() return now end },
    Network = {
        ClientState = {
            debugRoster = { selected },
        },
    },
    Client = {
        RequestDebugRoster = function() rosterRequests = rosterRequests + 1 end,
    },
    NPCMonitorSupport = {
        FindBody = function(item) return item and item.body or nil end,
        SetOutlined = function() end,
    },
    NPCMonitorView = {
        CreateChildren = function() end,
        Layout = function() end,
        Render = function() end,
    },
}

T.load(CLIENT_ROOT .. "PNC/UI/PNC_NPCMonitor.lua")

local window = setmetatable({
    list = {
        getItem = function()
            return { item = selected }
        end,
    },
    updateControlState = function() end,
    requestResponsiveLayout = function() end,
}, { __index = ISPNCNPCMonitor })

window:onTrack()
T.equal(PNC.NPCMonitor.trackedId, "npc_anton", "selected NPC tracked")
T.equal(markerCalls[1].id, "pnc_npc_track:npc_anton", "marker namespace")
T.equal(markerCalls[1].icon, "friend.png", "colonist marker icon")
T.equal(markerCalls[1].x, 100, "abstract marker x")
T.equal(markerCalls[1].y, 200, "abstract marker y")
T.equal(markerCalls[1].description, "Anton", "marker description")

selected.body = {
    getX = function() return 111 end,
    getY = function() return 222 end,
}
now = 2200
onTick()
T.equal(rosterRequests, 1, "tracking refreshes roster while monitor is closed")
T.equal(markerCalls[2].x, 111, "live body marker x")
T.equal(markerCalls[2].y, 222, "live body marker y")

window:onTrack()
T.equal(PNC.NPCMonitor.trackedId, nil, "second click clears tracking")
T.equal(removals[1], "pnc_npc_track:npc_anton", "tracked marker removed")

window:onTrack()
T.equal(PNC.NPCMonitor.trackedId, "npc_anton", "NPC can be tracked again")
PNC.Network.ClientState.debugRoster = {}
now = 3400
onTick()
T.equal(PNC.NPCMonitor.trackedId, nil,
    "tracking clears when authoritative metadata disappears")
T.equal(removals[2], "pnc_npc_track:npc_anton",
    "stale direction marker removed with metadata")
T.finish("pnc_npc_monitor_track_smoke")

T.finish("pnc_npc_monitor_track_smoke")
