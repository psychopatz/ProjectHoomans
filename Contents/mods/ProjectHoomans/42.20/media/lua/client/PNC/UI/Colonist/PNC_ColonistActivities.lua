require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISPanel"

local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Selector = require "PNC/UI/Colonist/PNC_ColonistSelector"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Activities = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout

local DEFINITIONS = {
    {
        id = "manual_eat",
        capabilities = { "survival.eat.inventory", "food.dine" },
        key = "UI_PNC_CommandEat",
        fallback = "EAT",
    },
    {
        id = "manual_drink",
        capabilities = { "water.drink", "water.nearby" },
        key = "UI_PNC_CommandDrink",
        fallback = "DRINK",
    },
    {
        id = "manual_sleep",
        capabilities = { "sleep" },
        key = "UI_PNC_CommandSleep",
        fallback = "SLEEP",
    },
    {
        id = "manual_provision",
        operation = "PROVISION_PICKUP",
        key = "UI_PNC_CommandProvision",
        fallback = "GRAB PROVISION",
    },
    {
        id = "manual_corpse_haul",
        operation = "CORPSE_HAUL",
        key = "UI_PNC_CommandCorpseHaul",
        fallback = "GRAB CORPSES",
    },
}

Activities.Definitions = DEFINITIONS

local BY_ID = {}
for _, definition in ipairs(DEFINITIONS) do
    BY_ID[definition.id] = definition
end

local function activityInfo(person)
    return person and person.actionInformation or nil
end

local function itemName(info)
    local fullType = tostring(info and info.activityItemFullType or "")
    if fullType ~= "" and getItemNameFromFullType then
        local resolved = getItemNameFromFullType(fullType)
        if resolved and resolved ~= "" then return tostring(resolved) end
    end
    if fullType ~= "" then
        local shortType = string.match(fullType, "([^%.]+)$") or fullType
        return string.gsub(shortType, "_", " ")
    end
    return nil
end

local function currentActivity(person)
    local info = activityInfo(person)
    if not info then return Shared.Text(person and person.activity, "IDLE") end
    if info.kind == "work_order" then
        local operation = tostring(info.operation or "")
        local label
        if operation == "PROVISION_PICKUP" then
            label = Shared.Tr("UI_PNC_Action_Grabbing", "GRABBING")
        elseif operation == "CORPSE_HAUL" then
            label = Shared.Tr("UI_PNC_CommandCorpseHaul", "GRAB CORPSES")
        else
            label = tostring(info.buildDisplayName or info.recipeId
                or operation or "WORKING")
        end
        local phase = tostring(info.phase or "")
        return phase ~= "" and label .. " (" .. phase .. ")" or label
    end
    local label = info.labelKey
        and Shared.Tr(info.labelKey, info.fallback)
        or Shared.Text(info.fallback or info.activityId, "IDLE")
    local item = itemName(info)
    if not item and info.activityItemLabelKey then
        item = Shared.Tr(info.activityItemLabelKey, "item")
    end
    if item and item ~= "" then label = label .. " - " .. item end
    local phase = tostring(info.phase or "")
    if phase ~= "" then label = label .. " (" .. phase .. ")" end
    return label
end

local function matches(definition, capability)
    for _, value in ipairs(definition.capabilities or {}) do
        if value == tostring(capability or "") then return true end
    end
    return false
end

local function active(definition, person)
    local info = activityInfo(person)
    if definition.operation then
        return info and info.kind == "work_order"
            and tostring(info.operation or "") == definition.operation
    end
    return matches(definition, info and info.capability)
end

local function syncControls(window)
    local person = Selector.GetSelected(window.people)
    for _, definition in ipairs(DEFINITIONS) do
        local button = window.activityControls[definition.id]
        local isActive = active(definition, person)
        local title = Shared.Tr(definition.key, definition.fallback)
        if definition.id == "manual_sleep" then
            title = title .. ": " .. Shared.Tr(
                isActive and "UI_PNC_MonitorOn" or "UI_PNC_MonitorOff",
                isActive and "ON" or "OFF")
        elseif isActive then
            title = title .. " (" .. Shared.Tr(
                "UI_PNC_MonitorActive", "active") .. ")"
        end
        if button.setTitle then button:setTitle(title) else button.title = title end
        button:setEnable(person ~= nil and person.alive ~= false)
        UI.SetButtonVariant(button, isActive and "selected" or "default")
    end
end

local function gridOptions(window, width)
    local scale = window.uiScale or Layout.Scale()
    local available = math.max(1, tonumber(width) or 1)
    return {
        scale = scale,
        columns = available >= Layout.Pixels(460, scale) and 2 or 1,
        gap = 8,
        rowGap = 8,
        height = 34,
        stretchLastRow = true,
    }
end

local function controlsHeight(window, width)
    local options = gridOptions(window, width)
    local header = Layout.Pixels(25, options.scale)
    local result = Layout.Grid(window.activityControlList, {
        x = 0,
        y = header + Layout.Pixels(8, options.scale),
        width = math.max(1, tonumber(width) or 1),
        height = 1,
    }, options)
    return header + Layout.Pixels(8, options.scale) + result.height
end

function Activities.Create(window, _, host)
    window.activityControls = {}
    window.activityControlList = {}
    for _, definition in ipairs(DEFINITIONS) do
        local button = UI.CreateButton(host or window, {
            id = definition.id,
            title = Shared.Tr(definition.key, definition.fallback),
            target = window,
            onclick = UI.ButtonCallback(function(control)
                return window:onColonistControl(control)
            end),
            variant = "default",
        })
        button.activityCommandID = definition.id
        window.activityControls[definition.id] = button
        window.activityControlList[#window.activityControlList + 1] = button
    end
    if host then
        host.render = function(panel)
            ISPanel.render(panel)
            UI.DrawSectionTitle(panel,
                Shared.Tr("UI_PNC_Activities_Commands", "MANUAL COMMANDS"),
                0, 0, panel:getWidth())
        end
    end
end

function Activities.GetControlsHeight(window, width)
    return controlsHeight(window, width)
end

function Activities.Apply(window, activeTab, Layout)
    for _, button in ipairs(window.activityControlList or {}) do
        button:setVisible(activeTab == true)
    end
    if window.tabControlsPane then
        window.tabControlsPane:setVisible(activeTab == true)
    end
    if not activeTab then return end
    syncControls(window)
    local pane = window.tabControlsPane
    if not pane then return end
    local options = gridOptions(window, pane:getWidth())
    local header = Layout.Pixels(25, options.scale)
    Layout.Grid(window.activityControlList, {
        x = 0,
        y = header + Layout.Pixels(8, options.scale),
        width = pane:getWidth(),
        height = 1,
    }, options)
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
    if tostring(person.manualActivityDisabled or "") == "sleep" then
        rows[#rows + 1] = Presentation.Detail(
            Shared.Tr("UI_PNC_Activities_SleepDisabled", "SLEEP CONTROL"),
            Shared.Tr("UI_PNC_Activities_SleepDisabledHelp",
                "OFF - automatic sleep is suppressed until Sleep is enabled."),
            "warning")
    end
    return rows
end

function Activities.OnPersonSelected(window)
    syncControls(window)
    if window.requestResponsiveLayout then window:requestResponsiveLayout(true) end
    return true
end

function Activities.OnControl(window, button)
    local person = Selector.GetSelected(window.people)
    local commandID = button and (button.activityCommandID or button.internal)
    local definition = BY_ID[tostring(commandID or "")]
    if not person or not definition or person.alive == false then return false end
    local client = PNC.Client
    local execute = client and client.ExecuteCompanionCommand or nil
    if not execute then return false end
    local sent = execute(definition.id, person.id, nil, {
        source = "colonist_activities",
    })
    if window.requestSnapshot then
        window:requestSnapshot("colonist_activity_" .. definition.id)
    end
    return sent == true
end

return Activities
