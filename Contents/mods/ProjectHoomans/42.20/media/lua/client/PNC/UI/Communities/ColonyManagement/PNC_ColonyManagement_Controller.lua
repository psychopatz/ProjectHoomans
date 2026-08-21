require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Diagnostics = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Diagnostics"
local LayoutModel = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Layout"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Registry = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Registry"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Controller = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Client = PNC.ColonyManagementClient

local function bounds(element)
    if not element then return "none" end
    return table.concat({
        tostring(element:getX()), tostring(element:getY()),
        tostring(element:getWidth()), tostring(element:getHeight()),
    }, ",")
end

local function tabTitle(definition)
    if type(definition.title) == "function" then
        return definition.title()
    end
    return tostring(definition.title or definition.id or "")
end

function Controller.CreateChildren(window)
    window.tab = "overview"
    window.tabButtons = {}
    window.navigation = {}
    for _, definition in ipairs(Registry.All()) do
        local button = UI.CreateButton(window, {
            id = definition.id,
            title = tabTitle(definition),
            target = window,
            onclick = ISPNCColonyManagementWindow.onTab,
            variant = definition.id == window.tab and "selected" or "quiet",
        })
        window.tabButtons[definition.id] = button
        window.navigation[#window.navigation + 1] = button
    end
    window.diagnosticsToggle = Diagnostics.CreateToggle(window)
    if window.diagnosticsToggle then
        window.navigation[#window.navigation + 1] = window.diagnosticsToggle
    end
    window.peoplePane, window.people =
        Components.CreateRosterPane(window)
    window.detailsPane, window.details =
        Components.CreateDetailPane(window)
    for _, definition in ipairs(Registry.All()) do
        if definition.create then definition.create(window, UI) end
    end
    window.people.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        window:onPersonSelected()
    end
    window.details.onMouseDown = function(list, x, y)
        ISScrollingListBox.onMouseDown(list, x, y)
        local entry = list.items and list.items[list.selected] or nil
        local row = entry and entry.item or nil
        local definition = Registry.Get(window.tab)
        if row and row.action and definition and definition.onRow then
            definition.onRow(window, row, x, y)
        end
    end
end

function Controller.ApplyResponsiveLayout(window)
    window.layout = LayoutModel.Calculate(window, window.navigation)
    LayoutModel.ApplyBase(window)
    for _, definition in ipairs(Registry.All()) do
        if definition.layout then
            definition.layout(window, Layout, window.layout.content)
        end
    end
    Controller.ApplyTabLayout(window)
    Diagnostics.Log(window, "layout", {
        tab = window.tab,
        pane = bounds(window.peoplePane) .. "|" .. bounds(window.detailsPane),
        list = bounds(window.people) .. "|" .. bounds(window.details),
        scrollbar = bounds(window.people.vscroll) .. "|"
            .. bounds(window.details.vscroll),
    })
end

function Controller.ApplyTabLayout(window)
    if not window.layout then return end
    local definition = Registry.Get(window.tab) or Registry.Get("overview")
    LayoutModel.ApplyBase(window)
    local peopleCount = #(window.snapshot and window.snapshot.people or {})
    window.peoplePane:setHeader("COMPANIONS", peopleCount)
    window.detailsPane:setHeader(definition.detailTitle or "COLONY STATUS")
    window.peoplePane:setVisible(definition.showRoster ~= false)
    window.detailsPane:setVisible(definition.showDetails ~= false)
    for _, candidate in ipairs(Registry.All()) do
        if candidate.apply then
            candidate.apply(window, candidate == definition, Layout)
        end
    end
end

function Controller.UpdateTabStyles(window)
    for _, definition in ipairs(Registry.All()) do
        local button = window.tabButtons[definition.id]
        local selected = definition.selectable ~= false
            and definition.id == window.tab
        UI.SetButtonVariant(button, selected and "selected" or "quiet")
    end
end

function Controller.SelectTab(window, button)
    local definition = Registry.Get(button and button.internal)
    if not definition then return end
    if definition.action then
        definition.action(window)
        return
    end
    if definition.selectable == false then return end
    window.tab = definition.id
    if window.tab == "tasks" then
        window:requestSnapshot("tasks_opened")
    end
    Controller.UpdateTabStyles(window)
    Controller.ApplyTabLayout(window)
    Controller.RebuildDetails(window)
    Diagnostics.Log(window, "tab_selected", {
        tab = window.tab,
        selected = window.selectedPersonID or "none",
    })
end

function Controller.RebuildDetails(window)
    local snapshot = window.snapshot or {}
    Components.SetRows(window.details, {})
    if window.storageList then Components.SetRows(window.storageList, {}) end
    local definition = Registry.Get(window.tab) or Registry.Get("overview")
    local context = {
        snapshot = snapshot,
        selectedPerson = Shared.ListValue(window.people),
        window = window,
    }
    if definition.buildRows then
        local rows = definition.buildRows(context)
        Components.SetRows(window.details, rows)
        Diagnostics.Log(window, "details_bound", {
            tab = window.tab,
            selected = window.selectedPersonID or "none",
            rows = #rows,
        })
    elseif definition.rebuild then
        definition.rebuild(window, snapshot, context)
        Diagnostics.Log(window, "details_bound", {
            tab = window.tab,
            selected = window.selectedPersonID or "none",
            rows = #(window.details.items or {}),
        })
    end
end

function Controller.OnPersonSelected(window)
    local person = Shared.ListValue(window.people)
    window.selectedPersonID = person and person.id
        or window.selectedPersonID
    local definition = Registry.Get(window.tab)
    if definition and definition.onPersonSelected then
        definition.onPersonSelected(window)
    end
    if definition and definition.showRoster ~= false then
        Controller.RebuildDetails(window)
    end
    Diagnostics.Log(window, "person_selected", {
        tab = window.tab,
        selected = window.selectedPersonID or "none",
    })
end

function Controller.Refresh(window, update)
    local selectedID = window.selectedPersonID
    local selectedIndex
    update = update or Client.ReadSnapshot()
    window.snapshot = update.snapshot or {}
    local roster = Presentation.BuildRoster(window.snapshot)
    Components.SetRows(window.people, roster)
    for index, row in ipairs(roster) do
        if row.id == selectedID then selectedIndex = index end
    end
    if #roster > 0 then
        window.people.selected = selectedIndex or 1
        local person = Shared.ListValue(window.people)
        window.selectedPersonID = person and person.id or nil
    else
        window.people.selected = 0
        window.selectedPersonID = nil
    end
    Controller.UpdateTabStyles(window)
    Controller.ApplyTabLayout(window)
    Controller.RebuildDetails(window)
    window.lastReceiveAt = update.receivedAt
        or PNC.Core.Now()
    window.lastReceiveRevision = tonumber(update.revision) or 0
    Diagnostics.Log(window, "snapshot_applied", {
        tab = window.tab,
        selected = window.selectedPersonID or "none",
        people = #roster,
        attention = #(window.snapshot.attention or {}),
        rows = #(window.details.items or {}),
    })
    if window.pendingBaseAction == "claim" then
        if window.snapshot.settlement then
            window.pendingBaseAction = nil
        elseif window.snapshot.colony then
            window.pendingBaseAction = nil
            window.tab = "base"
            Controller.UpdateTabStyles(window)
            Controller.ApplyTabLayout(window)
            Controller.RebuildDetails(window)
            window:onBaseControl({ internal = "claim" })
        end
    end
end

return Controller
