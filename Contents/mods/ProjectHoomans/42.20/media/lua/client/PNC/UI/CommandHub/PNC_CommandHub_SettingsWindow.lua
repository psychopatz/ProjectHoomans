require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISLabel"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.SettingsUI = PNC.CommandHub.SettingsUI or {}

local Hub = PNC.CommandHub
local SettingsUI = Hub.SettingsUI
local CoreHub = require "PsychopatzCore/UI/PsychopatzCommandHub"
local Options = CoreHub.Options
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local Theme = UI.Theme
local WidgetWindow = UI.WidgetWindow

local function trace(event, message)
    local hub = UI.CommandHub
    if hub and hub.Trace then hub.Trace(event, message) end
end

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function label(parent, text, color, colorName)
    local value = color or Theme.colors.text
    local widget = ISLabel:new(0, 0, 22, text,
        value.r, value.g, value.b, value.a, UIFont.Small, true)
    widget:initialise()
    widget.psychopatzThemeColorName = colorName
        or (color == Theme.colors.textMuted and "textMuted" or "text")
    parent:addChild(widget)
    return widget
end

local function formatOpacity(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function formatLift(value)
    return "+" .. tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function formatControlScale(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function themeTitle()
    return tr("UI_PNC_CommandHub_Settings_Theme", "THEME")
        .. ": " .. Theme.GetPresetLabel()
end

local function branchTitle()
    if Options.GetBranch() == "left" then
        return tr("UI_PNC_CommandHub_Settings_BranchLeft",
            "ACTION PANEL: LEFT")
    end
    return tr("UI_PNC_CommandHub_Settings_BranchRight",
        "ACTION PANEL: RIGHT")
end

ISPNCCommandHubSettingsWindow = PsychopatzWindow:derive(
    "ISPNCCommandHubSettingsWindow"
)

function ISPNCCommandHubSettingsWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCCommandHubSettingsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.fields = {}
    local opacityRow = UI.CreateFormRow(self, {
        id = "command-hub-setting-row:opacity",
        label = tr("UI_PNC_CommandHub_Settings_Opacity", "Opacity"),
        valueLabel = true,
        valueText = formatOpacity(Options.GetOpacityPercent()),
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = "command-hub-opacity",
                target = self,
                min = 20,
                max = 100,
                step = 1,
                value = Options.GetOpacityPercent(),
                onChange = function(_, value)
                    self:updateOpacityLabel(value)
                end,
            })
        end,
    })
    self.fields.opacity = {
        row = opacityRow,
        label = opacityRow.label,
        slider = opacityRow.control,
        valueLabel = opacityRow.valueLabel,
    }
    local function createLiftField(id, labelKey, fallback, value)
        local row
        row = UI.CreateFormRow(self, {
            id = id,
            label = tr(labelKey, fallback),
            valueLabel = true,
            valueText = formatLift(value),
            createControl = function(parent)
                return UI.CreateSlider(parent, {
                    id = id .. ":slider",
                    target = self,
                    min = 0,
                    max = 25,
                    step = 1,
                    value = value,
                    onChange = function(_, nextValue)
                        UI.SetLabelText(row.valueLabel, formatLift(nextValue))
                    end,
                })
            end,
        })
        -- Every field exposes the same contract: the layout owns the row,
        -- while the settings logic owns the control and display label.
        return {
            row = row,
            label = row.label,
            slider = row.control,
            valueLabel = row.valueLabel,
        }
    end
    self.fields.surfaceLift = createLiftField(
        "command-hub-setting-row:surface-lift",
        "UI_PNC_CommandHub_Settings_SurfaceLift",
        "Surface opacity lift", Options.GetSurfaceOpacityLift() * 100)
    self.fields.detailLift = createLiftField(
        "command-hub-setting-row:detail-lift",
        "UI_PNC_CommandHub_Settings_DetailLift",
        "Detail opacity lift", Options.GetDetailOpacityLift() * 100)
    local titlebarScaleRow
    titlebarScaleRow = UI.CreateFormRow(self, {
        id = "command-hub-setting-row:titlebar-scale",
        label = tr("UI_PNC_CommandHub_Settings_TitlebarScale",
            "Title-bar control size"),
        valueLabel = true,
        valueText = formatControlScale(
            Options.GetTitlebarControlScale() * 100),
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = "command-hub-titlebar-scale",
                target = self,
                min = 50,
                max = 125,
                step = 1,
                value = Options.GetTitlebarControlScale() * 100,
                onChange = function(_, value)
                    UI.SetLabelText(titlebarScaleRow.valueLabel,
                        formatControlScale(value))
                end,
            })
        end,
    })
    self.fields.titlebarScale = {
        row = titlebarScaleRow,
        label = titlebarScaleRow.label,
        slider = titlebarScaleRow.control,
        valueLabel = titlebarScaleRow.valueLabel,
    }
    self.helpLabel = label(self,
        tr("UI_PNC_CommandHub_Settings_Help",
            "Adjust opacity, child surface lifts, title-bar controls, theme, and panel side here."),
        Theme.colors.textMuted)
    self.themeButton = UI.CreateButton(self, {
        id = "theme", title = themeTitle(), target = self,
        onclick = ISPNCCommandHubSettingsWindow.onThemeCycle,
        variant = "quiet",
    })
    self.branchButton = UI.CreateButton(self, {
        id = "branch", title = branchTitle(), target = self,
        onclick = ISPNCCommandHubSettingsWindow.onBranchToggle,
        variant = "quiet",
    })
    self.statusLabel = label(self, "", Theme.colors.textMuted)
    self.resetButton = UI.CreateButton(self, {
        id = "reset", title = tr("UI_PNC_CommandHub_Settings_Reset", "RESET"),
        target = self, onclick = ISPNCCommandHubSettingsWindow.onReset,
        variant = "quiet",
    })
    self.closeButton = UI.CreateButton(self, {
        id = "close", title = tr("UI_PNC_CommandHub_Settings_Close", "CLOSE"),
        target = self, onclick = ISPNCCommandHubSettingsWindow.onClose,
        variant = "quiet",
    })
    self.applyButton = UI.CreateButton(self, {
        id = "apply", title = tr("UI_PNC_CommandHub_Settings_Apply", "APPLY"),
        target = self, onclick = ISPNCCommandHubSettingsWindow.onApply,
        variant = "primary",
    })
    self:populate()
    self:requestResponsiveLayout(true)
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-command-hub-settings-widget",
            onDetachedChanged = function()
                local controller = Hub.ChildController
                if controller and controller.SyncPositions then
                    controller.SyncPositions()
                end
            end,
        })
    end
end

function ISPNCCommandHubSettingsWindow:updateOpacityLabel(value)
    local field = self.fields and self.fields.opacity
    if field and field.valueLabel then
        UI.SetLabelText(field.valueLabel, formatOpacity(value))
    end
end

function ISPNCCommandHubSettingsWindow:setStatus(value)
    local text = tostring(value or "")
    self.statusText = text
    if self.statusLabel then
        UI.SetLabelText(self.statusLabel, text)
        self.statusLabel:setVisible(text ~= "")
    end
end

local function applyOpacityToWindows(hub, opacity)
    if Hub.ChildController and Hub.ChildController.ApplyOpacity then
        return Hub.ChildController.ApplyOpacity(opacity)
    end
    Options.ApplyOpacity(hub, opacity)
    local actions = CoreHub.Actions and CoreHub.Actions.instance or nil
    if actions then Options.ApplyOpacity(actions, opacity) end
    local zones = Hub.ZoneUI and Hub.ZoneUI.instances or {}
    for _, window in pairs(zones) do
        if window then Options.ApplyOpacity(window, opacity) end
    end
end

function ISPNCCommandHubSettingsWindow:getHub()
    if Hub.instance then return Hub.instance end
    return Hub.Open and Hub.Open() or nil
end

function ISPNCCommandHubSettingsWindow:populate()
    local hub = self:getHub()
    if not hub then return end
    local opacity = Options.GetOpacityPercent()
    self.fields.opacity.slider:setValue(opacity, true)
    self:updateOpacityLabel(opacity)
    local surfaceLift = Options.GetSurfaceOpacityLift() * 100
    self.fields.surfaceLift.slider:setValue(surfaceLift, true)
    UI.SetLabelText(self.fields.surfaceLift.valueLabel,
        formatLift(surfaceLift))
    local detailLift = Options.GetDetailOpacityLift() * 100
    self.fields.detailLift.slider:setValue(detailLift, true)
    UI.SetLabelText(self.fields.detailLift.valueLabel,
        formatLift(detailLift))
    local titlebarScale = Options.GetTitlebarControlScale() * 100
    self.fields.titlebarScale.slider:setValue(titlebarScale, true)
    UI.SetLabelText(self.fields.titlebarScale.valueLabel,
        formatControlScale(titlebarScale))
    self.branchButton:setTitle(branchTitle())
    self.themeButton:setTitle(themeTitle())
end

function ISPNCCommandHubSettingsWindow:onReset()
    trace("pnc_settings_reset_start", "has_hub="
        .. tostring(Hub.instance ~= nil))
    local hub = self:getHub()
    if hub then
        Options.Reset()
        Theme.Reset()
        applyOpacityToWindows(hub, Options.GetOpacity())
        Options.ApplyRegisteredToolbarScale()
    end
    self:populate()
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    trace("pnc_settings_reset_result", "result=true")
end

function ISPNCCommandHubSettingsWindow:onThemeCycle()
    local ids = Theme.GetPresetIDs()
    local current = Theme.GetPresetID()
    local index = 1
    for position, id in ipairs(ids) do
        if id == current then index = position end
    end
    local nextIndex = index + 1
    if nextIndex > #ids then nextIndex = 1 end
    Theme.SetPreset(ids[nextIndex])
    self.themeButton:setTitle(themeTitle())
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
end

function ISPNCCommandHubSettingsWindow:onBranchToggle()
    trace("pnc_settings_branch_start", "current=" .. tostring(Options.GetBranch()))
    local branch = Options.GetBranch() == "right" and "left" or "right"
    Options.SetBranch(branch)
    self.branchButton:setTitle(branchTitle())
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    if Hub.ChildController and Hub.ChildController.SyncPositions then
        Hub.ChildController.SyncPositions()
    else
        local hub = Hub.instance
        if hub and CoreHub.Actions and CoreHub.Actions.SyncPosition then
            CoreHub.Actions.SyncPosition(hub)
        end
        if Hub.ZoneUI and Hub.ZoneUI.SyncPositions then
            Hub.ZoneUI.SyncPositions()
        end
    end
    trace("pnc_settings_branch_result", "branch=" .. tostring(branch))
end

function ISPNCCommandHubSettingsWindow:onApply()
    trace("pnc_settings_apply_start", "has_hub=" .. tostring(Hub.instance ~= nil))
    local hub = self:getHub()
    if not hub then
        trace("pnc_settings_apply_result", "result=false reason=missing_hub")
        return
    end
    local opacity = math.floor(self.fields.opacity.slider:getValue() + 0.5)
    if not opacity then
        self:setStatus(tr("UI_PNC_CommandHub_Settings_Invalid",
            "Enter a valid opacity value."))
        trace("pnc_settings_apply_result", "result=false reason=invalid_values")
        return
    end
    Options.SetOpacityPercent(opacity)
    Options.SetSurfaceOpacityLift(
        math.floor(self.fields.surfaceLift.slider:getValue() + 0.5) / 100)
    Options.SetDetailOpacityLift(
        math.floor(self.fields.detailLift.slider:getValue() + 0.5) / 100)
    Options.SetTitlebarControlScale(
        math.floor(self.fields.titlebarScale.slider:getValue() + 0.5) / 100)
    applyOpacityToWindows(hub, opacity / 100)
    Options.ApplyRegisteredToolbarScale()
    self:populate()
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    trace("pnc_settings_apply_result", "result=true opacity="
        .. tostring(opacity))
end

function ISPNCCommandHubSettingsWindow:onClose()
    self:close()
end

function ISPNCCommandHubSettingsWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCCommandHubSettingsWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    SettingsUI.instance = nil
end

function ISPNCCommandHubSettingsWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

require "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow_Layout"

function SettingsUI.Open(owner)
    trace("pnc_settings_window_open", "has_owner=" .. tostring(owner ~= nil))
    local window = SettingsUI.instance
    if not window then
        window = UI.NewWindow(ISPNCCommandHubSettingsWindow, {
            title = tr("UI_PNC_CommandHub_Settings_Title", "COMMAND HUB SETTINGS"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Settings",
            responsiveSpec = {
                width = 420, height = 410,
                minWidth = 340, minHeight = 390,
                maxWidth = 700, maxHeight = 600,
            },
        })
        window:initialise()
        window:instantiate()
        SettingsUI.instance = window
    end
    window.owner = owner or window.owner
    window:populate()
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    trace("pnc_settings_window_shown", "opacity="
        .. tostring(Options.GetOpacityPercent()))
    return window
end

function SettingsUI.Close()
    if SettingsUI.instance then SettingsUI.instance:close() end
end

function SettingsUI.Toggle()
    if SettingsUI.instance and SettingsUI.instance.getIsVisible
        and SettingsUI.instance:getIsVisible()
    then
        SettingsUI.instance:close()
        return false
    end
    return SettingsUI.Open() ~= nil
end

return SettingsUI
