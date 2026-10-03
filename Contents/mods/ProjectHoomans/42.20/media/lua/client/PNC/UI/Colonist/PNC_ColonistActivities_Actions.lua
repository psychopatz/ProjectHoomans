local Activities = require "PNC/UI/Colonist/PNC_ColonistActivities_Core"
require "PNC/UI/Colonist/PNC_ColonistActivities_Layout"

local Internal = Activities.Internal or {}
local Presentation = Internal.Presentation
local Selector = Internal.Selector
local Shared = Internal.Shared
local UI = Internal.UI
local Layout = Internal.Layout
local DEFINITIONS = Internal.Definitions
local BY_ID = Internal.ByID
local activityInfo = Internal.activityInfo
local currentActivity = Internal.currentActivity
local appendJournalRows = Internal.appendJournalRows
local getComponent = Internal.getComponent
local syncControls = Internal.syncControls
local gridOptions = Internal.gridOptions
local layoutSeparateControls = Internal.layoutSeparateControls
local controlsHeight = Internal.controlsHeight

function Activities.Create(window, _)
    local pane = UI.CreatePanel(window)
    pane:setVisible(false)
    local component = {
        pane = pane,
        controls = {},
        controlList = {},
        separateList = {},
    }
    window.activityComponent = component
    pane.render = function(panel)
        ISPanel.render(panel)
        UI.DrawSectionTitle(panel,
            Shared.Tr("UI_PNC_Activities_Commands", "MANUAL COMMANDS"),
            0, 0, panel:getWidth())
    end
    for _, definition in ipairs(DEFINITIONS) do
        local onclick = UI.ButtonCallback(function(control)
            return window:onColonistControl(control)
        end)
        local button
        if definition.toggle and type(UI.CreateToggleButton) == "function" then
            -- Core's reusable toggle control owns the two-state label and
            -- variant swap; the panel only feeds it state from syncControls.
            button = UI.CreateToggleButton(pane, {
                id = definition.id,
                offTitle = Shared.Tr(definition.offTitleKey,
                    definition.offTitleFallback),
                onTitle = Shared.Tr(definition.onTitleKey,
                    definition.onTitleFallback),
                offVariant = definition.offVariant,
                onVariant = definition.onVariant,
                target = window,
                onclick = onclick,
            })
        else
            button = UI.CreateButton(pane, {
                id = definition.id,
                title = Shared.Tr(definition.key, definition.fallback),
                target = window,
                onclick = onclick,
                variant = "default",
            })
        end
        button.activityCommandID = definition.id
        component.controls[definition.id] = button
        if definition.separate == true then
            component.separateList[#component.separateList + 1] = button
        else
            component.controlList[#component.controlList + 1] = button
        end
    end
    return component
end

function Activities.GetControlsHeight(window, width, _, component)
    return controlsHeight(window, width, component)
end

function Activities.Apply(window, activeTab, Layout, component)
    component = getComponent(window, component)
    if not component then return end
    local pane = component.pane
    if pane then pane:setVisible(activeTab == true) end
    for _, button in ipairs(component.controlList or {}) do
        button:setVisible(activeTab == true)
    end
    for _, button in ipairs(component.separateList or {}) do
        button:setVisible(activeTab == true)
    end
    if not activeTab then return end
    syncControls(window, component)
    if not pane then return end
    local options = gridOptions(window, pane:getWidth())
    local header = Layout.Pixels(25, options.scale)
    local top = header + Layout.Pixels(8, options.scale)
    local result = Layout.Grid(component.controlList, {
        x = 0,
        y = top,
        width = pane:getWidth(),
        height = 1,
    }, options) or {}
    layoutSeparateControls(component, options, pane:getWidth(),
        top + (tonumber(result.height) or 0))
end

function Activities.BuildRows(context)
    local person = context.selectedPerson
    if not person then
        return { Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Select", "SELECT A COLONIST"),
            Shared.Tr("UI_PNC_Activities_SelectHelp",
                "Choose a colonist to command their next personal activity."),
            "warning") }
    end
    local info = activityInfo(person)
    local rows = {
        Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Current", "CURRENT ACTIVITY"),
            currentActivity(person), "accent"),
        Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Mode", "ACTIVITY MODE"),
            info and info.manual == true
                and Shared.Tr("UI_PNC_Activities_Manual", "MANUAL")
                or Shared.Tr("UI_PNC_Activities_Automatic", "AUTOMATIC")),
    }
    if info and tostring(info.phase or "") ~= "" then
        rows[#rows + 1] = Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_Phase", "PHASE"),
            tostring(info.phase))
    end
    local diagnostic = person.manualActivityDiagnostic
        or person.corpseHaulManualDiagnostic
    if type(diagnostic) == "table" and diagnostic.reason then
        local stage = tostring(diagnostic.details
            and diagnostic.details.stage or "request")
        local label = diagnostic.commandID
            and Shared.Tr("UI_PNC_Activities_LastActivityDiagnostic",
                "LAST ACTIVITY COMMAND")
            or Shared.Tr("UI_PNC_Activities_LastCorpseHaulDiagnostic",
                "LAST CORPSE HAUL DIAGNOSTIC")
        rows[#rows + 1] = Presentation.Detail(
            label,
            diagnostic.commandID and tostring(diagnostic.commandID) .. " = "
                .. tostring(diagnostic.reason)
                or stage .. " = " .. tostring(diagnostic.reason),
            diagnostic.result == true and "accent" or "warning")
    end
    if tostring(person.manualActivityDisabled or "") == "sleep" then
        rows[#rows + 1] = Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_SleepDisabled", "SLEEP CONTROL"),
            Shared.Tr("UI_PNC_Activities_SleepDisabledHelp",
            "OFF - automatic sleep is suppressed until Sleep is enabled."),
            "warning")
    end
    appendJournalRows(rows, person)
    return rows
end

function Activities.OnPersonSelected(window, _, component)
    syncControls(window, component)
    if window.requestResponsiveLayout then window:requestResponsiveLayout(true) end
    return true
end

function Activities.OnControl(window, button)
    local person = Selector.GetSelected(window.people)
    local commandID = button and (button.activityCommandID or button.internal)
    local definition = BY_ID[tostring(commandID or "")]
    if not person or not definition or person.alive == false then return false end
    -- A toggle resolves the order it means to issue from the colonist's current
    -- state, so the same control can both call a colonist and send one home.
    local targetCommandID = definition.resolveCommandID
        and definition.resolveCommandID(person) or definition.id
    if definition.presentation then
        local state = definition.presentation(person, definition)
        if not state or state.enabled ~= true then
            -- The button is disabled in this state; keep the reason visible in
            -- the activity status rows instead of failing silently.
            local client = PNC.Client
            if client and client.RecordManualActivityDiagnostic then
                client.RecordManualActivityDiagnostic(person.id, targetCommandID,
                    false, state and state.reason or "command_unavailable")
            end
            return false
        end
    end
    -- Access Inventory is a client view rather than a dispatched order, so it
    -- resolves here instead of through the companion command transport.
    if definition.opensInventory == true then
        local inventory = PNC.InventoryWindow
        if inventory and type(inventory.Open) == "function" then
            inventory.Open(person.id)
            return true
        end
        return false
    end
    local client = PNC.Client
    local execute = client and client.ExecuteCompanionCommand or nil
    if not execute then return false end
    local requestID = PNC.Core and PNC.Core.GenerateID
        and PNC.Core.GenerateID("colonist_activity")
        or tostring(person.id) .. ":" .. tostring(targetCommandID)
    local sent, reason = execute(targetCommandID, person.id, nil, {
        source = "colonist_activities",
        requestID = requestID,
    })
    if client.RecordManualActivityDiagnostic then
        client.RecordManualActivityDiagnostic(person.id, targetCommandID,
            sent == true, reason, requestID)
    end
    if window.requestSnapshot then
        window:requestSnapshot("colonist_activity_" .. targetCommandID)
    end
    return sent == true
end


return Activities
