require "PsychopatzCore/UI/PsychopatzUI"

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

PNC = PNC or {}
PNC.ColonyActivitiesTab = PNC.ColonyActivitiesTab or {}

local Activities = PNC.ColonyActivitiesTab
local UI = PsychopatzCore.UI

local DEFINITIONS = {
    {
        id = "manual_eat",
        capability = "survival.eat.inventory",
        capabilities = { "survival.eat.inventory", "food.dine" },
        key = "UI_PNC_CommandEat",
        fallback = "EAT",
    },
    {
        id = "manual_drink",
        capability = "water.drink",
        capabilities = { "water.drink", "water.nearby" },
        key = "UI_PNC_CommandDrink",
        fallback = "DRINK",
    },
    {
        id = "manual_sleep",
        capability = "sleep",
        capabilities = { "sleep" },
        key = "UI_PNC_CommandSleep",
        fallback = "SLEEP",
    },
    {
        id = "manual_provision",
        capabilities = { "provision" },
        key = "UI_PNC_CommandProvision",
        fallback = "GRAB PROVISION",
    },
}

local function definitionFor(id)
    for _, definition in ipairs(DEFINITIONS) do
        if definition.id == tostring(id or "") then return definition end
    end
    return nil
end

local function matches(definition, capability)
    for _, value in ipairs(definition and definition.capabilities or {}) do
        if value == tostring(capability or "") then return true end
    end
    return false
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
    if not info then
        return Shared.Text(person and person.activity, "IDLE")
    end
    if info.kind == "work_order" then
        local operation = tostring(info.operation or "")
        local label
        if operation == "PROVISION_PICKUP" then
            label = Shared.Tr("UI_PNC_Action_Grabbing", "GRABBING")
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
    if not item then
        item = info.activityItemLabelKey
            and Shared.Tr(info.activityItemLabelKey, "item") or nil
    end
    if item and item ~= "" then label = label .. " - " .. item end
    local phase = tostring(info.phase or "")
    if phase ~= "" then label = label .. " (" .. phase .. ")" end
    return label
end

local function active(definition, person)
    local info = activityInfo(person)
    if definition and definition.id == "manual_provision" then
        return tostring(info and info.operation or "") == "PROVISION_PICKUP"
    end
    return matches(definition, info and info.capability)
end

local function updateButton(button, definition, person)
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

local function syncControls(window)
    local person = Shared.ListValue(window.people)
    for _, definition in ipairs(DEFINITIONS) do
        updateButton(window.activityControls[definition.id], definition, person)
    end
end

function Activities.Create(window)
    window.activityControls = {}
    window.activityControlList = {}
    for _, definition in ipairs(DEFINITIONS) do
        local button = UI.CreateButton(window, {
            id = definition.id,
            title = Shared.Tr(definition.key, definition.fallback),
            target = window,
            onclick = ISPNCColonyManagementWindow.onActivitiesControl,
            variant = "default",
        })
        window.activityControls[definition.id] = button
        window.activityControlList[#window.activityControlList + 1] = button
    end
end

function Activities.Apply(window, activeTab, Layout)
    for _, button in ipairs(window.activityControlList or {}) do
        button:setVisible(activeTab)
    end
    if not activeTab then return end
    syncControls(window)
    if not window.layout then return end
    local rect = window.layout.details
    local gap = Layout.Pixels(6, window.uiScale)
    local height = Layout.Pixels(28, window.uiScale)
    local count = #window.activityControlList
    local columns = math.min(4, math.max(1, count))
    local rows = math.ceil(count / columns)
    local width = math.floor((rect.width - gap * (columns - 1)) / columns)
    for index, button in ipairs(window.activityControlList or {}) do
        local row = math.floor((index - 1) / columns)
        local column = (index - 1) % columns
        local x = rect.x + column * (width + gap)
        local y = rect.y + row * (height + gap)
        local lastWidth = column == columns - 1
            and rect.width - (x - rect.x) or width
        Layout.SetBounds(button, x, y, lastWidth, height)
    end
    local paneY = rect.y + rows * height + (rows - 1) * gap + gap
    window:layoutPane(window.detailsPane, rect.x, paneY,
        rect.width, math.max(60, rect.height - (paneY - rect.y)))
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
    return true
end

function Activities.OnControl(window, button)
    local person = Shared.ListValue(window.people)
    local commandID = tostring(button and button.internal or "")
    local definition = definitionFor(commandID)
    if not person or not definition or person.alive == false then return false end
    local client = PNC.Client
    local execute = client and (client.ExecuteCompanionCommand
        or client.SendCompanionCommand) or nil
    if not execute then return false end
    local sent = execute(commandID, person.id)
    if window.requestSnapshot then
        window:requestSnapshot("manual_activity_" .. commandID)
    end
    return sent == true
end

return Activities
