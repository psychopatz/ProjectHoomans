local T = require "tests/support/test"

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function()
    PsychopatzCore = {
        Layout = {
            ScreenSize = function() return 1280, 720 end,
            Clamp = function(value, minimum, maximum)
                if value < minimum then return minimum end
                if value > maximum then return maximum end
                return value
            end,
        },
    }
    PsychopatzCore.UI = PsychopatzCore
    return PsychopatzCore.UI
end

local function fakeWindow(x, y, width, height)
    local window = {
        visible = false, x = x, y = y,
        width = width, height = height,
    }
    function window:getIsVisible() return self.visible end
    function window:getX() return self.x end
    function window:getY() return self.y end
    function window:getWidth() return self.width end
    function window:getHeight() return self.height end
    function window:setX(value) self.x = value end
    function window:setY(value) self.y = value end
    function window:setVisible(value) self.visible = value end
    function window:close() self.visible = false end
    return window
end

local hub = fakeWindow(100, 80, 260, 390)
hub.visible = true
local actionsWindow = fakeWindow(0, 0, 190, 150)
local workWindow = fakeWindow(0, 0, 760, 560)
local settingsWindow = fakeWindow(0, 0, 420, 340)
local journalWindow = fakeWindow(0, 0, 640, 540)
workWindow.psychopatzWidgetEnabled = true
settingsWindow.psychopatzWidgetEnabled = true
journalWindow.psychopatzWidgetEnabled = true

local actionsUI = { instance = actionsWindow }
function actionsUI.Open()
    actionsWindow.visible = true
    return actionsWindow
end
function actionsUI.Close() actionsWindow.visible = false end
function actionsUI.SyncPosition() end

local coreOptions = {
    GetOpacity = function() return 0.92 end,
    GetBranch = function() return "right" end,
    ApplyOpacity = function(window, value)
        if window then window.opacity = value end
        return value
    end,
}
coreOptions.ApplyWindowOpacity = coreOptions.ApplyOpacity
package.preload["PsychopatzCore/UI/PsychopatzCommandHub"] = function()
    return { Actions = actionsUI, Options = coreOptions }
end

local zoneUI = { instances = {} }
function zoneUI.CloseAll() end
function zoneUI.SyncPositions() end

local workUI = { instance = workWindow }
function workUI.Open() workWindow.visible = true return workWindow end
function workUI.Close() workWindow.visible = false end

local settingsUI = { instance = settingsWindow }
function settingsUI.Open() settingsWindow.visible = true return settingsWindow end
function settingsUI.Close() settingsWindow.visible = false end

local journalUI = { instance = journalWindow }
function journalUI.Open(owner)
    journalWindow.owner = owner
    journalWindow.visible = true
    return journalWindow
end
function journalUI.Close() journalWindow.visible = false end

PNC = {
    CommandHub = {
        instance = hub,
        ZoneUI = zoneUI,
        WorkUI = workUI,
        SettingsUI = settingsUI,
    },
    ColonyJournalUI = journalUI,
}

local Controller = T.load("ProjectHoomans", "client",
    "PNC/UI/CommandHub/PNC_CommandHub_ChildController.lua")

T.truthy(Controller.Toggle("zone", hub),
    "zone did not open its detached action panel")
T.truthy(actionsWindow.visible, "zone action panel is not visible")
T.falsy(Controller.Toggle("zone", hub),
    "second zone click did not close the complete zone branch")
T.falsy(actionsWindow.visible, "zone action panel remained visible")

T.truthy(Controller.Toggle("zone", hub), "zone did not reopen")
T.truthy(Controller.Toggle("work", hub),
    "work did not replace the zone branch")
T.falsy(actionsWindow.visible, "zone branch survived the work switch")
T.truthy(workWindow.visible, "work window is not visible")
T.truthy(hub.visible, "switching branches closed the parent hub")

T.truthy(Controller.Toggle("settings", hub),
    "settings did not replace the work branch")
T.falsy(workWindow.visible, "work branch survived the settings switch")
T.truthy(settingsWindow.visible, "settings window is not visible")

T.truthy(Controller.Toggle("events", hub),
    "events did not open the colony journal child")
T.falsy(settingsWindow.visible, "settings branch survived the events switch")
T.truthy(journalWindow.visible, "colony journal child is not visible")
T.truthy(journalWindow.owner == hub,
    "colony journal child did not receive the hub owner")
T.truthy(Controller.Toggle("work", hub),
    "work did not replace the attached events branch")
T.falsy(journalWindow.visible,
    "attached events branch survived the work switch")

T.truthy(Controller.Toggle("events", hub),
    "events did not reopen after a sibling switch")
journalWindow.psychopatzWidgetDetached = true
T.truthy(Controller.Toggle("zone", hub),
    "zone did not open beside a detached events widget")
T.truthy(journalWindow.visible,
    "detached events widget was closed by a sibling branch switch")
T.truthy(Controller.Toggle("events", hub),
    "detached events widget could not be focused")
T.falsy(Controller.Toggle("events", hub),
    "second events click did not close the detached journal")
T.falsy(journalWindow.visible,
    "detached journal remained visible after its parent was re-clicked")

T.truthy(Controller.Toggle("work", hub), "work did not reopen")
workWindow.psychopatzWidgetDetached = true
T.truthy(Controller.Toggle("zone", hub),
    "zone did not open beside a detached work widget")
T.truthy(workWindow.visible,
    "detached work widget was closed by a sibling branch switch")
T.truthy(actionsWindow.visible, "zone action panel did not open")
T.truthy(Controller.Toggle("work", hub),
    "detached work widget could not be focused")
T.truthy(workWindow.visible, "focusing detached work widget hid it")
T.falsy(actionsWindow.visible,
    "focusing a widget left the attached zone branch open")
T.falsy(Controller.Toggle("work", hub),
    "second click did not close the detached work widget")
T.falsy(workWindow.visible,
    "detached work widget remained visible after its parent was re-clicked")

Controller.ApplyOpacity(0.4)
T.equal(hub.opacity, 0.4, "parent opacity was not propagated")
T.equal(settingsWindow.opacity, 0.4,
    "child opacity was not propagated")
T.equal(journalWindow.opacity, 0.4,
    "journal opacity was not propagated")
Controller.CloseAll()
T.truthy(hub.visible, "closing children closed the parent hub")
T.falsy(settingsWindow.visible, "settings child was not closed")
T.falsy(workWindow.visible, "parent close did not close detached widget")

T.finish("pnc_command_hub_child_controller_smoke")
