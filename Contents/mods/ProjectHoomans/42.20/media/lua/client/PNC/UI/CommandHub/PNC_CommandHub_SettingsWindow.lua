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

local function label(parent, text, color)
    local value = color or Theme.colors.text
    local widget = ISLabel:new(0, 0, 22, text,
        value.r, value.g, value.b, value.a, UIFont.Small, true)
    widget:initialise()
    parent:addChild(widget)
    return widget
end

local function readInteger(entry, minimum, maximum)
    local value = tonumber(entry and entry:getText() or nil)
    if not value then return nil end
    value = math.floor(value + 0.5)
    if minimum and value < minimum then return nil end
    if maximum and value > maximum then return nil end
    return value
end

local function setEntry(entry, value)
    if entry then entry:setText(tostring(math.floor(value or 0))) end
end

local function formatOpacity(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
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
    local definitions = {
        { id = "x", labelKey = "UI_PNC_CommandHub_Settings_X" },
        { id = "y", labelKey = "UI_PNC_CommandHub_Settings_Y" },
        { id = "width", labelKey = "UI_PNC_CommandHub_Settings_Width" },
        { id = "height", labelKey = "UI_PNC_CommandHub_Settings_Height" },
        { id = "opacity", labelKey = "UI_PNC_CommandHub_Settings_Opacity" },
    }
    for _, definition in ipairs(definitions) do
        local opacity = definition.id == "opacity"
        local row = UI.CreateFormRow(self, {
            id = "command-hub-setting-row:" .. definition.id,
            label = tr(definition.labelKey, definition.id),
            valueLabel = opacity,
            valueText = opacity and formatOpacity(
                Options.GetOpacityPercent()) or nil,
            createControl = function(parent)
                if opacity then
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
                end
                return UI.CreateTextEntry(parent, {
                    onlyNumbers = true, maxTextLength = 5,
                })
            end,
        })
        local field = { row = row, label = row.label,
            entry = not opacity and row.control or nil,
            slider = opacity and row.control or nil,
            valueLabel = row.valueLabel }
        self.fields[definition.id] = field
    end
    self.helpLabel = label(self,
        tr("UI_PNC_CommandHub_Settings_Help",
            "Edit the hub position, dimensions, and opacity."),
        Theme.colors.textMuted)
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
    setEntry(self.fields.x.entry, hub:getX())
    setEntry(self.fields.y.entry, hub:getY())
    setEntry(self.fields.width.entry, hub:getWidth())
    setEntry(self.fields.height.entry, hub:getHeight())
    local opacity = Options.GetOpacityPercent()
    self.fields.opacity.slider:setValue(opacity, true)
    self:updateOpacityLabel(opacity)
    self.branchButton:setTitle(branchTitle())
end

function ISPNCCommandHubSettingsWindow:onReset()
    trace("pnc_settings_reset_start", "has_hub="
        .. tostring(Hub.instance ~= nil))
    local hub = self:getHub()
    if hub then
        Options.ResetGeometry(hub)
        applyOpacityToWindows(hub, Options.GetOpacity())
    end
    self:populate()
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    trace("pnc_settings_reset_result", "result=true")
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
    local x = readInteger(self.fields.x.entry, 0)
    local y = readInteger(self.fields.y.entry, 0)
    local width = readInteger(self.fields.width.entry, 1)
    local height = readInteger(self.fields.height.entry, 1)
    local opacity = math.floor(self.fields.opacity.slider:getValue() + 0.5)
    if not x or not y or not width or not height or not opacity then
        self:setStatus(tr("UI_PNC_CommandHub_Settings_Invalid",
            "Enter valid numeric values."))
        trace("pnc_settings_apply_result", "result=false reason=invalid_values")
        return
    end
    Options.ApplyGeometry(hub, x, y, width, height)
    Options.SetOpacityPercent(opacity)
    applyOpacityToWindows(hub, opacity / 100)
    self:populate()
    self:setStatus(tr("UI_PNC_CommandHub_Settings_Applied",
        "Settings applied."))
    trace("pnc_settings_apply_result", "result=true x=" .. tostring(x)
        .. " y=" .. tostring(y) .. " width=" .. tostring(width)
        .. " height=" .. tostring(height) .. " opacity=" .. tostring(opacity))
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
            persistenceKey = "PNC.CommandHub.Settings.v2",
            responsiveSpec = {
                width = 420, height = 340,
                minWidth = 360, minHeight = 330,
                maxWidth = 620, maxHeight = 540,
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
