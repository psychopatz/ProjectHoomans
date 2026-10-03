-- Child-window branch adapters for the colony command hub.
--
-- The controller owns lifecycle policy; this provider registers the
-- concrete child modules and their open, close, focus, and sync contracts.
require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.ChildController = PNC.CommandHub.ChildController or {}

local Hub = PNC.CommandHub
local Controller = Hub.ChildController
local Internal = Controller.Internal or {}
local Actions = Internal.Actions
local isVisible = Internal.IsVisible
local moduleIsVisible = Internal.ModuleIsVisible
local provisionWindow = Internal.ProvisionWindow
local colonyNamePromptWindow = Internal.ColonyNamePromptWindow
local colonyEmblemEditorWindow = Internal.ColonyEmblemEditorWindow
local colonyActionsOpen = Internal.ColonyActionsOpen
local moduleIsDetached = Internal.ModuleIsDetached
local focusModule = Internal.FocusModule
local closeModule = Internal.CloseModule
local placeWindow = Internal.PlaceWindow

if type(isVisible) ~= "function"
    or type(moduleIsVisible) ~= "function"
    or type(moduleIsDetached) ~= "function"
    or type(focusModule) ~= "function"
    or type(closeModule) ~= "function"
    or type(placeWindow) ~= "function"
then
    return Controller
end

Controller.Register("colony", {
    open = function(owner)
        if not Actions or not Actions.Open then return false end
        return Actions.Open("colony", owner)
    end,
    close = function(reason)
        if colonyActionsOpen() and Actions and Actions.Close then
            Actions.Close()
        end
        closeModule(PNC.ColonyNamePrompt)
        closeModule(PNC.FactionEmblemEditor)
        local provision = PNC.ProvisionSettingsUI
        if reason == "switch" and moduleIsDetached(provision) then
            return
        end
        closeModule(provision)
    end,
    isOpen = function()
        return colonyActionsOpen()
            or moduleIsVisible(PNC.ProvisionSettingsUI)
            or isVisible(colonyNamePromptWindow())
            or isVisible(colonyEmblemEditorWindow())
    end,
    sync = function(owner)
        if colonyActionsOpen() and Actions and Actions.SyncPosition then
            Actions.SyncPosition(owner)
        end
        placeWindow(provisionWindow(), owner)
    end,
})

Controller.Register("zone", {
    open = function(owner)
        if not Actions or not Actions.Open then return false end
        return Actions.Open("zone", owner)
    end,
    close = function()
        if Hub.ZoneUI and Hub.ZoneUI.CloseAll then Hub.ZoneUI.CloseAll() end
        if Actions and Actions.Close then Actions.Close() end
    end,
    isOpen = function()
        if moduleIsVisible(Actions) then return true end
        local zones = Hub.ZoneUI and Hub.ZoneUI.instances or {}
        for _, window in pairs(zones) do
            if isVisible(window) then return true end
        end
        return false
    end,
    sync = function(owner)
        if Actions and Actions.SyncPosition then
            Actions.SyncPosition(owner)
        end
        if Hub.ZoneUI and Hub.ZoneUI.SyncPositions then
            Hub.ZoneUI.SyncPositions()
        end
    end,
})

Controller.Register("work", {
    open = function(owner)
        return Hub.WorkUI and Hub.WorkUI.Open
            and Hub.WorkUI.Open(owner) or false
    end,
    close = function() closeModule(Hub.WorkUI) end,
    isOpen = function() return moduleIsVisible(Hub.WorkUI) end,
    isDetached = function() return moduleIsDetached(Hub.WorkUI) end,
    focus = function() return focusModule(Hub.WorkUI) end,
    sync = function(owner)
        placeWindow(Hub.WorkUI and Hub.WorkUI.instance, owner)
    end,
})

Controller.Register("workshop", {
    open = function(owner)
        local workshop = PNC.WorkshopUI
        return workshop and workshop.Open
            and workshop.Open(owner) or false
    end,
    close = function()
        local workshop = PNC.WorkshopUI
        if workshop and workshop.Close then workshop.Close() end
    end,
    isOpen = function()
        return PNC.WorkshopUI
            and moduleIsVisible(PNC.WorkshopUI) or false
    end,
    isDetached = function()
        return PNC.WorkshopUI
            and moduleIsDetached(PNC.WorkshopUI) or false
    end,
    focus = function()
        return focusModule(PNC.WorkshopUI)
    end,
    sync = function(owner)
        placeWindow(PNC.WorkshopUI
            and PNC.WorkshopUI.instance or nil, owner)
    end,
})

Controller.Register("settings", {
    open = function(owner)
        return Hub.SettingsUI and Hub.SettingsUI.Open
            and Hub.SettingsUI.Open(owner) or false
    end,
    close = function() closeModule(Hub.SettingsUI) end,
    isOpen = function() return moduleIsVisible(Hub.SettingsUI) end,
    isDetached = function() return moduleIsDetached(Hub.SettingsUI) end,
    focus = function() return focusModule(Hub.SettingsUI) end,
    sync = function(owner)
        placeWindow(Hub.SettingsUI and Hub.SettingsUI.instance, owner)
    end,
})

Controller.Register("events", {
    open = function(owner)
        local journal = PNC.ColonyJournalUI
        return journal and journal.Open and journal.Open(owner) or false
    end,
    close = function()
        local journal = PNC.ColonyJournalUI
        if journal and journal.Close then journal.Close() end
    end,
    isOpen = function()
        return PNC.ColonyJournalUI
            and moduleIsVisible(PNC.ColonyJournalUI) or false
    end,
    isDetached = function()
        return PNC.ColonyJournalUI
            and moduleIsDetached(PNC.ColonyJournalUI) or false
    end,
    focus = function()
        return focusModule(PNC.ColonyJournalUI)
    end,
    sync = function(owner)
        placeWindow(PNC.ColonyJournalUI
            and PNC.ColonyJournalUI.instance or nil, owner)
    end,
})

Controller.Register("colonist", {
    open = function(owner)
        local colonist = PNC.ColonistUI
        return colonist and colonist.Open
            and colonist.Open(owner) or false
    end,
    close = function()
        local colonist = PNC.ColonistUI
        if colonist and colonist.Close then colonist.Close() end
    end,
    isOpen = function()
        return PNC.ColonistUI
            and moduleIsVisible(PNC.ColonistUI) or false
    end,
    isDetached = function()
        return PNC.ColonistUI
            and moduleIsDetached(PNC.ColonistUI) or false
    end,
    focus = function()
        return focusModule(PNC.ColonistUI)
    end,
    sync = function(owner)
        placeWindow(PNC.ColonistUI
            and PNC.ColonistUI.instance or nil, owner)
    end,
})

Controller.Register("storage", {
    open = function(owner)
        local storage = PNC.ColonyStorageUI
        if not storage or type(storage.Open) ~= "function" then
            return false, "storage_ui_unavailable"
        end
        return storage.Open(owner)
    end,
    close = function()
        local storage = PNC.ColonyStorageUI
        if storage and storage.Close then storage.Close() end
    end,
    isOpen = function()
        return PNC.ColonyStorageUI
            and moduleIsVisible(PNC.ColonyStorageUI) or false
    end,
    isDetached = function()
        return PNC.ColonyStorageUI
            and moduleIsDetached(PNC.ColonyStorageUI) or false
    end,
    focus = function()
        return focusModule(PNC.ColonyStorageUI)
    end,
    sync = function(owner)
        placeWindow(PNC.ColonyStorageUI
            and PNC.ColonyStorageUI.instance or nil, owner)
    end,
})

Controller.Register("research", {
    open = function(owner)
        local research = PNC.ResearchUI
        return research and research.Open
            and research.Open(owner) or false
    end,
    close = function()
        local research = PNC.ResearchUI
        if research and research.Close then research.Close() end
    end,
    isOpen = function()
        return PNC.ResearchUI
            and moduleIsVisible(PNC.ResearchUI) or false
    end,
    isDetached = function()
        return PNC.ResearchUI
            and moduleIsDetached(PNC.ResearchUI) or false
    end,
    focus = function()
        return focusModule(PNC.ResearchUI)
    end,
    sync = function(owner)
        placeWindow(PNC.ResearchUI
            and PNC.ResearchUI.instance or nil, owner)
    end,
})

Controller.Register("base", {
    open = function(owner)
        local base = PNC.BaseUI
        return base and base.Open
            and base.Open(owner) or false
    end,
    close = function()
        local base = PNC.BaseUI
        if base and base.Close then base.Close() end
    end,
    isOpen = function()
        local base = PNC.BaseUI
        return base and moduleIsVisible(base) or false
    end,
    isDetached = function()
        local base = PNC.BaseUI
        return base and moduleIsDetached(base) or false
    end,
    focus = function()
        return focusModule(PNC.BaseUI)
    end,
    sync = function(owner)
        local base = PNC.BaseUI
        placeWindow(base and base.instance or nil, owner)
    end,
})


return Controller
