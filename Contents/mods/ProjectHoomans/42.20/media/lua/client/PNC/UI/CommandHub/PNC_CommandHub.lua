-- Colony command hub composition root.
-- Providers register data; the window owns rendering and interaction.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Hub = PNC.CommandHub
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
local Toolbar = require "PsychopatzCore/UI/Components/PsychopatzWindowToolbar"
local UI = PsychopatzCore.UI
local Theme = UI.Theme

require "PNC/UI/CommandHub/PNC_CommandHub_CorpseHaulUI"
require "PNC/UI/CommandHub/PNC_CommandHub_ZoneOverlay"
require "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow"
require "PNC/UI/CommandHub/PNC_CommandHub_Registry"
require "PNC/UI/CommandHub/PNC_CommandHub_Window"
require "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow"
require "PNC/UI/CommandHub/PNC_CommandHub_WorkRegistry"
require "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow"
require "PNC/UI/CommandHub/PNC_CommandHub_ChildController"

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function toggleSettings(window)
    local controller = Hub.ChildController
    if controller and controller.Toggle then
        return controller.Toggle("settings", window)
    end
    return false
end

local function installToolbar(window)
    if not window or not Toolbar or not Toolbar.Add then return nil end
    local button = Toolbar.Add(window, {
        id = "pnc-command-hub-settings-toolbar",
        title = "",
        image = "media/ui/MP/mp_ui_mods.png",
        imageSize = 14,
        order = 90,
        target = window,
        tooltip = tr("UI_PNC_CommandHub_Settings_Tooltip",
            "Open colony menu settings"),
        onclick = function(target)
            return toggleSettings(target)
        end,
        variant = "quiet",
    })
    if not button then return nil end
    button:setTitle("")
    button:setDisplayBackground(true)
    UI.SetButtonTheme(button, {
        background = "transparent",
        hover = "surfaceHover",
        hoverAlpha = 0.7,
        border = "transparent",
        text = "transparent",
    })
    Toolbar.Sync(window)
    return button
end

-- Keep PNC's child controller synchronized with the Core-owned host even
-- when another mod opens the shared hub directly through PsychopatzCore.
CoreHub.RegisterObserver("ProjectHoomans.CommandHub", function(event, window)
    if event == "closed" then
        if Hub.ChildController and Hub.ChildController.CloseAll then
            Hub.ChildController.CloseAll()
        end
        Hub.instance = nil
        return
    end
    Hub.instance = window
    if event == "opened" or event == "shown" then
        installToolbar(window)
    end
    if event == "prerender" and Hub.ChildController
        and Hub.ChildController.SyncPositions
    then
        Hub.ChildController.SyncPositions()
    end
end)

if CoreHub.instance then
    Hub.instance = CoreHub.instance
    installToolbar(CoreHub.instance)
end

local function isWorldReady()
    return (not isIngameState) or isIngameState()
end

local function openOnWorldStart()
    if not isWorldReady() then return end
    Hub.Open()
end

if not Hub.eventsInstalled then
    if Events and Events.OnGameStart then
        Events.OnGameStart.Add(openOnWorldStart)
    end
    if Events and Events.OnCreatePlayer then
        Events.OnCreatePlayer.Add(openOnWorldStart)
    end
    Hub.eventsInstalled = true
end

Hub.OpenOnWorldStart = openOnWorldStart

return Hub
