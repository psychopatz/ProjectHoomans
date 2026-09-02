-- Owns the lifetime of every window opened from the colony command hub.
-- Categories select one child branch at a time; the hub itself remains alive.

require "PsychopatzCore/UI/PsychopatzUI"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.ChildController = PNC.CommandHub.ChildController or {}

local Hub = PNC.CommandHub
local Controller = Hub.ChildController
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
local Actions = CoreHub.Actions
local Options = CoreHub.Options
local Layout = PsychopatzCore.UI.Layout
local WidgetWindow = PsychopatzCore.UI.WidgetWindow or {}

Controller.entries = Controller.entries or {}
Controller.closeOrder = { "zone", "work", "settings", "events", "colonist",
    "storage" }
Controller.activeID = nil
Controller.closing = false

local function isVisible(window)
    return window ~= nil and window.getIsVisible
        and window:getIsVisible() == true
end

local function moduleIsVisible(module)
    return module ~= nil and isVisible(module.instance)
end

local function moduleWindow(module)
    return module and module.instance or nil
end

local function windowIsDetached(window)
    if not window then return false end
    if WidgetWindow.IsDetached then
        return WidgetWindow.IsDetached(window)
    end
    return window.psychopatzWidgetDetached == true
end

local function moduleIsDetached(module)
    local window = moduleWindow(module)
    return windowIsDetached(window)
end

local function focusModule(module)
    local window = moduleWindow(module)
    if window and window.bringToTop then window:bringToTop() end
    return window ~= nil
end

local function closeModule(module)
    if not module then return end
    if module.Close then
        module.Close()
    elseif module.instance and module.instance.close then
        module.instance:close()
    end
end

local function clampWindow(window, x, y)
    if not window then return end
    local screenWidth, screenHeight = Layout.ScreenSize()
    local width = window.getWidth and window:getWidth() or 0
    local height = window.getHeight and window:getHeight() or 0
    window:setX(Layout.Clamp(x, 0, math.max(0, screenWidth - width)))
    window:setY(Layout.Clamp(y, 0, math.max(0, screenHeight - height)))
end

local function placeWindow(window, owner)
    if not isVisible(window) then return end
    if WidgetWindow.Sync then WidgetWindow.Sync(window) end
    -- A detached widget owns its own position.  The controller may still
    -- refresh its title-bar control, but must never snap it back to the hub.
    if windowIsDetached(window) then return end
    if not owner or not isVisible(owner) then
        return
    end
    local gap = 4
    local x
    if Options.GetBranch() == "left" then
        x = owner:getX() - window:getWidth() - gap
    else
        x = owner:getX() + owner:getWidth() + gap
    end
    clampWindow(window, x, owner:getY())
end

function Controller.Register(id, definition)
    local key = tostring(id or "")
    if key == "" or type(definition) ~= "table" then return false end
    Controller.entries[key] = definition
    return true
end

function Controller.IsOpen(id)
    local entry = Controller.entries[tostring(id or "")]
    return entry and type(entry.isOpen) == "function"
        and entry.isOpen() == true or false
end

function Controller.CloseBranch(id, reason)
    local entry = Controller.entries[tostring(id or "")]
    if not entry then return false end
    if reason == "switch" and type(entry.isDetached) == "function"
        and entry.isDetached()
    then
        if type(entry.focus) == "function" then entry.focus() end
        return true
    end
    if type(entry.close) == "function" then entry.close() end
    if Controller.activeID == tostring(id or "") then
        Controller.activeID = nil
    end
    return true
end

function Controller.CloseAll(reason)
    if Controller.closing then return false end
    Controller.closing = true
    local preserveDetached = reason == "switch"
    local function closeEntry(entry)
        if not entry then return end
        if preserveDetached and type(entry.isDetached) == "function"
            and entry.isDetached()
        then
            return
        end
        if type(entry.close) == "function" then entry.close() end
    end
    for _, id in ipairs(Controller.closeOrder) do
        local entry = Controller.entries[id]
        closeEntry(entry)
    end
    for id, entry in pairs(Controller.entries) do
        local known = false
        for _, closeID in ipairs(Controller.closeOrder) do
            if closeID == id then known = true break end
        end
        if not known then closeEntry(entry) end
    end
    Controller.activeID = nil
    Controller.closing = false
    return true
end

function Controller.Toggle(id, owner)
    local key = tostring(id or "")
    local entry = Controller.entries[key]
    if not entry then return false end

    if Controller.activeID == key and Controller.IsOpen(key) then
        -- A detached widget is still owned by this branch. Re-clicking its
        -- parent button must close it just like an attached child, without
        -- changing its saved position or destroying the instance.
        Controller.CloseBranch(key)
        return false
    end

    if Controller.IsOpen(key) and type(entry.isDetached) == "function"
        and entry.isDetached()
    then
        -- Switching focus still closes the previously attached branch. Other
        -- detached widgets are preserved, including the target itself.
        Controller.CloseAll("switch")
        if type(entry.focus) == "function" then entry.focus() end
        Controller.activeID = key
        return true
    end

    Controller.CloseAll("switch")
    if type(entry.open) ~= "function" then return false end
    local opened = entry.open(owner)
    if opened == false or opened == nil then return false end
    Controller.activeID = key
    Controller.SyncPositions()
    return true
end

function Controller.ApplyOpacity(opacity)
    local value = opacity or Options.GetOpacity()
    Options.ApplyWindowOpacity(Hub.instance, value)
    Options.ApplyWindowOpacity(Actions and Actions.instance or nil, value)
    local zones = Hub.ZoneUI and Hub.ZoneUI.instances or {}
    for _, window in pairs(zones) do
        Options.ApplyWindowOpacity(window, value)
    end
    Options.ApplyWindowOpacity(Hub.WorkUI and Hub.WorkUI.instance or nil, value)
    Options.ApplyWindowOpacity(Hub.SettingsUI and Hub.SettingsUI.instance or nil, value)
    Options.ApplyWindowOpacity(PNC.ColonyJournalUI
        and PNC.ColonyJournalUI.instance or nil, value)
    Options.ApplyWindowOpacity(PNC.ColonistUI
        and PNC.ColonistUI.instance or nil, value)
    Options.ApplyWindowOpacity(PNC.ColonyStorageUI
        and PNC.ColonyStorageUI.instance or nil, value)
    return value
end

function Controller.SyncPositions()
    local owner = Hub.instance
    if not isVisible(owner) then
        Controller.CloseAll()
        return false
    end

    if Controller.activeID and not Controller.IsOpen(Controller.activeID) then
        Controller.activeID = nil
    end

    local zone = Controller.entries.zone
    if Controller.IsOpen("zone") and zone
        and type(zone.sync) == "function"
    then
        zone.sync(owner)
    end
    local work = Controller.entries.work
    if Controller.IsOpen("work") and work
        and type(work.sync) == "function"
    then
        work.sync(owner)
    end
    local settings = Controller.entries.settings
    if Controller.IsOpen("settings") and settings
        and type(settings.sync) == "function"
    then
        settings.sync(owner)
    end
    local events = Controller.entries.events
    if Controller.IsOpen("events") and events
        and type(events.sync) == "function"
    then
        events.sync(owner)
    end
    local colonist = Controller.entries.colonist
    if Controller.IsOpen("colonist") and colonist
        and type(colonist.sync) == "function"
    then
        colonist.sync(owner)
    end
    local storage = Controller.entries.storage
    if Controller.IsOpen("storage") and storage
        and type(storage.sync) == "function"
    then
        storage.sync(owner)
    end
    Controller.ApplyOpacity(Options.GetOpacity())
    return true
end

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
        return storage and storage.Open
            and storage.Open(owner) or false
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

return Controller
