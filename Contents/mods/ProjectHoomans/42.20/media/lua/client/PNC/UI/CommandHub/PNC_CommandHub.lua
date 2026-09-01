-- Colony command hub composition root.
-- Providers register data; the window owns rendering and interaction.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local Hub = PNC.CommandHub
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"

require "PNC/UI/CommandHub/PNC_CommandHub_CorpseHaulUI"
require "PNC/UI/CommandHub/PNC_CommandHub_ZoneOverlay"
require "PNC/UI/CommandHub/PNC_CommandHub_ZoneWindow"
require "PNC/UI/CommandHub/PNC_CommandHub_Registry"
require "PNC/UI/CommandHub/PNC_CommandHub_Window"
require "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow"
require "PNC/UI/CommandHub/PNC_CommandHub_WorkRegistry"
require "PNC/UI/CommandHub/PNC_CommandHub_WorkWindow"
require "PNC/UI/CommandHub/PNC_CommandHub_ChildController"
require "PNC/UI/CommandHub/PNC_CommandHub_Button"

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
    if event == "prerender" and Hub.ChildController
        and Hub.ChildController.SyncPositions
    then
        Hub.ChildController.SyncPositions()
    end
end)

if CoreHub.instance then Hub.instance = CoreHub.instance end

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
