local CLIENT_ROOT = "Contents/mods/ProjectHoomans/42.19/media/lua/client/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected) .. " actual=" .. tostring(actual))
    end
end

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function() return true end
package.preload["PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"] = function() return true end
package.preload["PNC/UI/NPCMonitor/PNC_NPCMonitorSupport"] = function() return true end
package.preload["PNC/UI/NPCMonitor/PNC_NPCMonitorView"] = function() return true end

local markerCalls = {}
local removals = {}
local rosterRequests = 0
local onTick
local now = 1000
local selected = {
    id = "npc_anton",
    name = "Anton",
    faction = "colonist",
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

dofile(CLIENT_ROOT .. "PNC/UI/PNC_NPCMonitor.lua")

local window = setmetatable({
    list = {
        getItem = function()
            return { item = selected }
        end,
    },
    updateControlState = function() end,
}, { __index = ISPNCNPCMonitor })

window:onTrack()
assertEqual(PNC.NPCMonitor.trackedId, "npc_anton", "selected NPC tracked")
assertEqual(markerCalls[1].id, "pnc_npc_track:npc_anton", "marker namespace")
assertEqual(markerCalls[1].icon, "friend.png", "colonist marker icon")
assertEqual(markerCalls[1].x, 100, "abstract marker x")
assertEqual(markerCalls[1].y, 200, "abstract marker y")
assertEqual(markerCalls[1].description, "Anton", "marker description")

selected.body = {
    getX = function() return 111 end,
    getY = function() return 222 end,
}
now = 2200
onTick()
assertEqual(rosterRequests, 1, "tracking refreshes roster while monitor is closed")
assertEqual(markerCalls[2].x, 111, "live body marker x")
assertEqual(markerCalls[2].y, 222, "live body marker y")

window:onTrack()
assertEqual(PNC.NPCMonitor.trackedId, nil, "second click clears tracking")
assertEqual(removals[1], "pnc_npc_track:npc_anton", "tracked marker removed")

print("pnc_npc_monitor_track_smoke: ok")
