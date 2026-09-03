require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local LayoutModel = require "PNC/UI/Colonist/PNC_ColonistLayout"
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Registry = require "PNC/UI/Colonist/PNC_ColonistRegistry"
local Selector = require "PNC/UI/Colonist/PNC_ColonistSelector"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

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

local function syncTabs(window)
    if window.tabRegistryRevision == Registry.Revision
        and window.tabOrder then
        return false
    end

    window.tabButtons = window.tabButtons or {}
    window.tabOrder = {}
    local active = {}
    for _, definition in ipairs(Registry.All()) do
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

    if not Registry.Get(window.tab) then
        local first = Registry.All()[1]
        window.tab = first and first.id or nil
    end
    window.tabRegistryRevision = Registry.Revision
    return true
end

function Controller.SyncTabs(window)
    return syncTabs(window)
end

function Controller.SyncTabComponents(window)
    window.tabComponents = window.tabComponents or {}
    for _, definition in ipairs(Registry.All()) do
        local id = definition.id
        if not window.tabComponents[id] and definition.create then
            definition.create(window, UI, window.tabControlsPane)
            window.tabComponents[id] = true
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
    window.tabControlsPane = UI.CreatePanel(window)
    window.tabControlsPane:setVisible(false)
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
    if window.lastContentOpacitySignature == signature then return end
    Options.ApplySurfaceOpacity(window.people, "detail")
    Options.ApplySurfaceOpacity(window.details, "detail")
    Options.ApplySurfaceOpacity(window.tabControlsPane, "detail")
    window.lastContentOpacitySignature = signature
end

function Controller.ApplyResponsiveLayout(window)
    syncTabs(window)
    Controller.SyncTabComponents(window)
    local definition = Registry.Get(window.tab)
    window.layout = LayoutModel.Calculate(window, window.tabOrder, definition)
    LayoutModel.Apply(window)
    Controller.ApplyTabLayout(window)
end

function Controller.ApplyTabLayout(window)
    if not window.layout then return end
    local definition = Registry.Get(window.tab) or Registry.All()[1]
    if definition then window.tab = definition.id end
    local count = #(window.snapshot and window.snapshot.people or {})
    Selector.SetHeader(window.peoplePane, "COLONISTS", count)
    window.detailsPane:setHeader(detailTitle(definition or {}))
    -- The roster is intentionally permanent for every colonist tab. A future
    -- tab may change its detail rendering, but cannot orphan selection.
    window.peoplePane:setVisible(true)
    window.detailsPane:setVisible(true)
    if window.tabControlsPane then window.tabControlsPane:setVisible(false) end
    for _, candidate in ipairs(Registry.All()) do
        if candidate.apply then
            candidate.apply(window, candidate == definition, UI.Layout)
        end
    end
end

function Controller.UpdateTabStyles(window)
    for _, definition in ipairs(Registry.All()) do
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
    if not definition then return false end
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
    if definition and definition.onControl then
        return definition.onControl(window, button) == true
    end
    return false
end

function Controller.RebuildDetails(window)
    Components.SetRows(window.details, {})
    local definition = Registry.Get(window.tab)
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
    if definition and definition.onPersonSelected then
        definition.onPersonSelected(window, person)
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
