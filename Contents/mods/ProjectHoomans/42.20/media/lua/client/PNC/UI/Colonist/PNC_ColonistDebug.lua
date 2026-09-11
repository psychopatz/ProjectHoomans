require "ISUI/ISPanel"
require "ISUI/ISComboBox"
require "PsychopatzCore/UI/PsychopatzUI"

local Actions = require "PNC/UI/Colonist/PNC_ColonistDebugActions"
local Rows = require "PNC/UI/Colonist/PNC_ColonistDebugRows"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Debug = {}
local UI = PsychopatzCore.UI
local Layout = UI.Layout

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

local function controlHeight(window, width, component)
    local options = gridOptions(window, width)
    local scale = options.scale
    local header = Layout.Pixels(25, scale)
    local gap = Layout.Pixels(8, scale)
    local comboHeight = Layout.Pixels(27, scale)
    local result = Layout.Grid(component and component.controls or {}, {
        x = 0,
        y = header + gap + comboHeight + gap,
        width = math.max(1, tonumber(width) or 1),
        height = 1,
    }, options) or {}
    return header + gap + comboHeight + gap
        + (tonumber(result.height) or Layout.Pixels(34, scale))
end

local function hostRender(panel)
    ISPanel.render(panel)
    UI.DrawSectionTitle(panel,
        Shared.Tr("UI_PNC_ColonyDebug_Commands", "DEBUG COMMANDS"),
        0, 0, panel:getWidth())
end

function Debug.IsAvailable()
    return Actions.IsAvailable()
end

function Debug.Create(window, _)
    local pane = UI.CreatePanel(window)
    pane:setVisible(false)
    local component = {
        pane = pane,
        controls = {},
        facilityCombo = ISComboBox:new(0, 0, 220, 26, window, nil),
    }
    window.debugComponent = component
    component.facilityCombo:initialise()
    component.facilityCombo:instantiate()
    pane:addChild(component.facilityCombo)

    local callback = UI.ButtonCallback(function(button)
        return window:onColonistControl(button)
    end)
    for _, action in ipairs(Actions.Definitions) do
        local button = UI.CreateButton(pane, {
            id = action.id,
            title = Shared.Tr(action.key, action.fallback),
            target = window,
            onclick = callback,
            variant = action.id == "force_provision" and "selected" or "quiet",
        })
        component.controls[#component.controls + 1] = button
    end
    pane.render = hostRender
    pane:setVisible(false)
    return component
end

function Debug.GetControlsHeight(window, width, _, component)
    component = component or (window.tabComponents
        and window.tabComponents.debug) or window.debugComponent
    if not component then return 0 end
    return controlHeight(window, width, component)
end

function Debug.Apply(window, active, _, component)
    component = component or (window.tabComponents
        and window.tabComponents.debug) or window.debugComponent
    local pane = component and component.pane
    if not pane then return end
    pane:setVisible(active == true)
    if component.facilityCombo then
        component.facilityCombo:setVisible(active == true)
    end
    for _, button in ipairs(component.controls or {}) do
        button:setVisible(active == true)
    end
    if not active then return end

    Actions.SyncControls(window, component)
    local width = math.max(1, pane:getWidth())
    local options = gridOptions(window, width)
    local scale = options.scale
    local header = Layout.Pixels(25, scale)
    local gap = Layout.Pixels(8, scale)
    local comboHeight = Layout.Pixels(27, scale)
    Layout.SetBounds(component.facilityCombo, 0, header + gap,
        width, comboHeight)
    Layout.Grid(component.controls, {
        x = 0,
        y = header + gap + comboHeight + gap,
        width = width,
        height = 1,
    }, options)
    Rows.SyncFacilities(window, window.snapshot, component)
end

function Debug.BuildRows(person, snapshot, window, component)
    return Rows.Build(person, snapshot, window, component)
end

function Debug.OnPersonSelected(window, _, component)
    component = component or (window.tabComponents
        and window.tabComponents.debug) or window.debugComponent
    Actions.SyncControls(window, component)
    if window.snapshot then Rows.SyncFacilities(window, window.snapshot, component) end
    if window.requestResponsiveLayout then
        window:requestResponsiveLayout(true)
    end
    return true
end

function Debug.OnControl(window, button, component)
    return Actions.OnControl(window, button, component)
end

return Debug
