require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Shared/PNC_ColonyUIComponents"
local LayoutModel = require "PNC/UI/Colonist/PNC_ColonistLayout"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Presentation = require "PNC/UI/Shared/PNC_ColonyPresentation"
local Registry = require "PNC/UI/Colonist/PNC_ColonistRegistry"
local Selector = require "PNC/UI/Colonist/PNC_ColonistSelector"
local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"

local Controller = {}
local UI = PsychopatzCore.UI
local Client = PNC.ColonyManagementClient

local function translate(key, fallback)
    if key == nil or key == "" then return fallback end
    return Shared.Tr(key, fallback)
end

local function tabTitle(definition)
    if type(definition.title) == "function" then
        return tostring(definition.title())
    end
    return translate(definition.titleKey,
        tostring(definition.titleFallback or definition.title
            or definition.id or ""))
end

local function detailTitle(definition)
    if type(definition.detailTitle) == "function" then
        return tostring(definition.detailTitle())
    end
    return translate(definition.detailTitleKey,
        tostring(definition.detailTitleFallback
            or definition.detailTitle or "COLONIST DETAILS"))
end

local function isAvailable(definition, window)
    if type(definition.available) == "function" then
        return definition.available(window) == true
    end
    return definition.available ~= false
end

local function availableDefinitions(window)
    local definitions = {}
    local signature = {}
    for _, definition in ipairs(Registry.All()) do
        if isAvailable(definition, window) then
            definitions[#definitions + 1] = definition
            signature[#signature + 1] = definition.id
        end
    end
    return definitions, table.concat(signature, "|")
end

local function syncTabs(window)
    local definitions, availabilitySignature = availableDefinitions(window)
    if window.tabRegistryRevision == Registry.Revision
        and window.tabAvailabilitySignature == availabilitySignature
        and window.tabOrder then
        return false
    end

    window.tabButtons = window.tabButtons or {}
    window.tabOrder = {}
    window.tabDefinitions = definitions
    local active = {}
    for _, definition in ipairs(definitions) do
        local id = definition.id
        active[id] = true
        local button = window.tabButtons[id]
        if not button then
            button = UI.CreateButton(window, {
                id = "colonist-tab:" .. tostring(id),
                title = tabTitle(definition),
                target = window,
                onclick = UI.ButtonCallback(function(tabButton)
                    return window:onTab(tabButton)
                end),
                variant = "quiet",
            })
            window.tabButtons[id] = button
        end
        button.colonistTabID = id
        button:setTitle(tabTitle(definition))
        button:setVisible(true)
        window.tabOrder[#window.tabOrder + 1] = button
    end
    for id, button in pairs(window.tabButtons) do
        if not active[id] then button:setVisible(false) end
    end

    local current = Registry.Get(window.tab)
    if not current or not isAvailable(current, window) then
        local first = definitions[1]
        window.tab = first and first.id or nil
    end
    window.tabRegistryRevision = Registry.Revision
    window.tabAvailabilitySignature = availabilitySignature
    return true
end

function Controller.SyncTabs(window)
    return syncTabs(window)
end

function Controller.SyncTabComponents(window)
    window.tabComponents = window.tabComponents or {}
    for _, definition in ipairs(window.tabDefinitions or Registry.All()) do
        local id = definition.id
        if window.tabComponents[id] == nil and definition.create then
            local component = definition.create(window, UI)
            window.tabComponents[id] = component or true
        end
    end
end

local function getTabComponent(window, definition)
    local component = definition and window.tabComponents
        and window.tabComponents[definition.id] or nil
    return type(component) == "table" and component or nil
end

local function hideTabComponents(window)
    for _, component in pairs(window.tabComponents or {}) do
        if type(component) == "table" and component.pane then
            component.pane:setVisible(false)
        end
    end
end

function Controller.CreateChildren(window)
    window.tab = "needs"
    window.tabButtons = {}
    window.tabOrder = {}
    window.tabComponents = {}
    window.snapshot = {}
    window.roster = {}
    window.selectedPersonID = nil
    window.lastReceiveRevision = -1
    window.lastReceiveAt = 0
    window.lastRequestAt = 0
    window.pendingTaskBrainCancellations = {}
    window.lastTaskBrainRequestId = nil

    syncTabs(window)
    window.peoplePane, window.people = Selector.Create(window, function()
        window:onPersonSelected()
    end)
    window.detailsPane, window.details = Components.CreateDetailPane(window)

    Controller.SyncTabComponents(window)

    window.details.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local entry = list.items and list.items[list.selected] or nil
        local row = entry and entry.item or nil
        local definition = Registry.Get(window.tab)
        if row and row.action and definition and definition.onRow then
            definition.onRow(window, row, x, y)
        end
    end
    Controller.ApplyContentStyle(window)
end

function Controller.ApplyContentStyle(window)
    local signature = Options.GetContentOpacitySignature()
    if window.lastContentOpacitySignature ~= signature then
        Options.ApplySurfaceOpacity(window.people, "detail")
        Options.ApplySurfaceOpacity(window.details, "detail")
        window.lastContentOpacitySignature = signature
    end
    for _, component in pairs(window.tabComponents or {}) do
        if type(component) == "table" and component.pane
            and component.contentOpacitySignature ~= signature
        then
            Options.ApplySurfaceOpacity(component.pane, "detail")
            component.contentOpacitySignature = signature
        end
    end
end

function Controller.ApplyResponsiveLayout(window)
    syncTabs(window)
    Controller.SyncTabComponents(window)
    local definition = Registry.Get(window.tab)
    local component = getTabComponent(window, definition)
    window.activeTabControlsPane = component and component.pane or nil
    window.layout = LayoutModel.Calculate(window, window.tabOrder, definition,
        component)
    LayoutModel.Apply(window)
    Controller.ApplyTabLayout(window)
end

function Controller.ApplyTabLayout(window)
    if not window.layout then return end
    local definition = Registry.Get(window.tab)
    if not definition or not isAvailable(definition, window) then
        definition = window.tabDefinitions and window.tabDefinitions[1]
    end
    if definition then window.tab = definition.id end
    local count = #(window.snapshot and window.snapshot.people or {})
    Selector.SetHeader(window.peoplePane, "COLONISTS", count)
    window.detailsPane:setHeader(detailTitle(definition or {}))
    -- The roster is intentionally permanent for every colonist tab. A future
    -- tab may change its detail rendering, but cannot orphan selection.
    window.peoplePane:setVisible(true)
    window.detailsPane:setVisible(true)
    hideTabComponents(window)
    local component = getTabComponent(window, definition)
    window.activeTabControlsPane = component and component.pane or nil
    if component and component.pane and window.layout.controls then
        component.pane:setVisible(true)
    end
    if definition and definition.apply then
        definition.apply(window, true, UI.Layout, component)
    end
end

function Controller.UpdateTabStyles(window)
    for _, definition in ipairs(window.tabDefinitions or Registry.All()) do
        local button = window.tabButtons[definition.id]
        if button then
            local selected = definition.id == window.tab
            UI.SetButtonVariant(button, selected and "selected" or "quiet")
        end
    end
end

function Controller.SelectTab(window, button)
    local id = button and (button.colonistTabID or button.internal) or nil
    if type(id) == "string" then
        id = id:gsub("^colonist%-tab:", "")
    end
    local definition = Registry.Get(id)
    if not definition or not isAvailable(definition, window) then return false end
    if definition.action then
        definition.action(window)
        return true
    end
    window.tab = definition.id
    Controller.UpdateTabStyles(window)
    if window.requestResponsiveLayout then
        window:requestResponsiveLayout(true)
    else
        Controller.ApplyResponsiveLayout(window)
    end
    Controller.RebuildDetails(window)
    return true
end

function Controller.OnControl(window, button)
    local definition = Registry.Get(window.tab)
    if definition and isAvailable(definition, window) and definition.onControl then
        return definition.onControl(window, button,
            getTabComponent(window, definition)) == true
    end
    return false
end

function Controller.RebuildDetails(window)
    Components.SetRows(window.details, {})
    local definition = Registry.Get(window.tab)
    if not definition or not isAvailable(definition, window) then
        definition = window.tabDefinitions and window.tabDefinitions[1]
        if definition then window.tab = definition.id end
    end
    if not definition then
        Components.SetRows(window.details, {
            Presentation.Detail("NO COLONIST TABS", "No tab is registered."),
        })
        return
    end
    local context = {
        snapshot = window.snapshot or {},
        selectedPerson = Selector.GetSelected(window.people),
        window = window,
        client = Client,
        component = getTabComponent(window, definition),
    }
    if definition.buildRows then
        Components.SetRows(window.details,
            definition.buildRows(context) or {})
    elseif definition.rebuild then
        definition.rebuild(window, context.snapshot, context)
    end
end

function Controller.OnPersonSelected(window)
    local person = Selector.GetSelected(window.people)
    window.selectedPersonID = person and person.id or nil
    local definition = Registry.Get(window.tab)
    if definition and isAvailable(definition, window)
        and definition.onPersonSelected then
        definition.onPersonSelected(window, person,
            getTabComponent(window, definition))
    end
    Controller.RebuildDetails(window)
end

function Controller.Refresh(window, update)
    local selectedID = window.selectedPersonID
    update = update or Client.ReadSnapshot()
    window.snapshot = update.snapshot or {}
    local roster, person = Selector.SetRows(
        window.people, window.snapshot, selectedID)
    window.roster = roster
    window.selectedPersonID = person and person.id or nil
    syncTabs(window)
    Controller.SyncTabComponents(window)
    Controller.UpdateTabStyles(window)
    Controller.ApplyTabLayout(window)
    local definition = Registry.Get(window.tab)
    if definition and definition.getControlsHeight
        and window.requestResponsiveLayout
        and window.lastTabControlsLayoutRevision
            ~= (tonumber(update.revision) or 0)
    then
        window.lastTabControlsLayoutRevision = tonumber(update.revision) or 0
        window:requestResponsiveLayout(true)
    end
    Controller.RebuildDetails(window)
    Controller.ApplyContentStyle(window)
    window.lastReceiveAt = update.receivedAt or PNC.Core.Now()
    window.lastReceiveRevision = tonumber(update.revision) or 0
end

return Controller
