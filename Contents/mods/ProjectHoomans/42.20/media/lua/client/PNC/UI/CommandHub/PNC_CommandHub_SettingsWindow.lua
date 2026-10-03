require "PsychopatzCore/UI/PsychopatzUI"
require "PsychopatzCore/UI/Components/PsychopatzCheckbox"
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
local DisplaySettings = require
    "PNC/UI/Nameplates/PNC_NameplateDisplaySettings"
local CoreTranslation = PsychopatzCore.Translation

local function trace(event, message)
    local hub = UI.CommandHub
    if hub and hub.Trace then hub.Trace(event, message) end
end

local function tr(key, fallback)
    if not key or key == "" then return fallback end
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function audioText(key, fallback)
    if CoreTranslation and CoreTranslation.GetKey then
        return CoreTranslation.GetKey(key, fallback)
    end
    return fallback
end

local function getAudio()
    return PsychopatzCore and PsychopatzCore.Audio or nil
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

local function formatRelationshipFeedbackScale(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function formatNameplateTextScale(value)
    return tostring(math.floor((tonumber(value) or 0) + 0.5)) .. "%"
end

local function formatNameplateBarScale(value)
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

local SettingsInternal = Hub.SettingsInternal or {}
Hub.SettingsInternal = SettingsInternal
SettingsInternal.Hub = Hub
SettingsInternal.Options = Options
SettingsInternal.Theme = Theme
SettingsInternal.CoreHub = CoreHub
SettingsInternal.DisplaySettings = DisplaySettings
SettingsInternal.Trace = trace
SettingsInternal.Translate = tr
SettingsInternal.GetAudio = getAudio
SettingsInternal.ThemeTitle = themeTitle
SettingsInternal.BranchTitle = branchTitle

ISPNCCommandHubSettingsWindow = PsychopatzWindow:derive(
    "ISPNCCommandHubSettingsWindow"
)

function ISPNCCommandHubSettingsWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

local function fieldReferences(row)
    return {
        row = row,
        label = row.label,
        slider = row.control,
        valueLabel = row.valueLabel,
    }
end

local function createSliderField(window, config)
    local row
    row = UI.CreateFormRow(window, {
        id = config.id,
        label = tr(config.labelKey, config.fallback),
        valueLabel = true,
        valueText = config.formatter(config.value),
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = config.id .. ':slider',
                target = window,
                min = config.min,
                max = config.max,
                step = 1,
                value = config.value,
                onChange = function(_, nextValue)
                    UI.SetLabelText(row.valueLabel,
                        config.formatter(nextValue))
                end,
            })
        end,
    })
    return fieldReferences(row)
end

local function createOpacityField(window)
    local row
    row = UI.CreateFormRow(window, {
        id = 'command-hub-setting-row:opacity',
        label = tr('UI_PNC_CommandHub_Settings_Opacity', 'Opacity'),
        valueLabel = true,
        valueText = formatOpacity(Options.GetOpacityPercent()),
        createControl = function(parent)
            return UI.CreateSlider(parent, {
                id = 'command-hub-opacity',
                target = window,
                min = 20,
                max = 100,
                step = 1,
                value = Options.GetOpacityPercent(),
                onChange = function(_, value)
                    window:updateOpacityLabel(value)
                end,
            })
        end,
    })
    return fieldReferences(row)
end

local function createSettingsFields(window)
    return {
        opacity = createOpacityField(window),
        surfaceLift = createSliderField(window, {
            id = 'command-hub-setting-row:surface-lift',
            labelKey = 'UI_PNC_CommandHub_Settings_SurfaceLift',
            fallback = 'Surface opacity lift',
            value = Options.GetSurfaceOpacityLift() * 100,
            min = 0,
            max = 25,
            formatter = formatLift,
        }),
        detailLift = createSliderField(window, {
            id = 'command-hub-setting-row:detail-lift',
            labelKey = 'UI_PNC_CommandHub_Settings_DetailLift',
            fallback = 'Detail opacity lift',
            value = Options.GetDetailOpacityLift() * 100,
            min = 0,
            max = 25,
            formatter = formatLift,
        }),
        titlebarScale = createSliderField(window, {
            id = 'command-hub-setting-row:titlebar-scale',
            labelKey = 'UI_PNC_CommandHub_Settings_TitlebarScale',
            fallback = 'Title-bar control size',
            value = Options.GetTitlebarControlScale() * 100,
            min = 50,
            max = 125,
            formatter = formatControlScale,
        }),
        nameplateTextScale = createSliderField(window, {
            id = 'command-hub-setting-row:nameplate-text-scale',
            labelKey = 'UI_PNC_CommandHub_Settings_NameplateTextScale',
            fallback = 'Nameplate text size',
            value = DisplaySettings.GetNameplateTextScale() * 100,
            min = DisplaySettings.MinNameplateTextScale * 100,
            max = DisplaySettings.MaxNameplateTextScale * 100,
            formatter = formatNameplateTextScale,
        }),
        nameplateBarScale = createSliderField(window, {
            id = 'command-hub-setting-row:nameplate-bar-scale',
            labelKey = 'UI_PNC_CommandHub_Settings_NameplateBarScale',
            fallback = 'Nameplate bar size',
            value = DisplaySettings.GetNameplateBarScale() * 100,
            min = DisplaySettings.MinNameplateBarScale * 100,
            max = DisplaySettings.MaxNameplateBarScale * 100,
            formatter = formatNameplateBarScale,
        }),
        relationshipFeedbackScale = createSliderField(window, {
            id = 'command-hub-setting-row:relationship-feedback-scale',
            labelKey = 'UI_PNC_CommandHub_Settings_RelationshipFeedbackScale',
            fallback = 'Relationship feedback size',
            value = DisplaySettings.GetRelationshipFeedbackScale() * 100,
            min = DisplaySettings.MinRelationshipFeedbackScale * 100,
            max = DisplaySettings.MaxRelationshipFeedbackScale * 100,
            formatter = formatRelationshipFeedbackScale,
        }),
    }
end

local function createSupplementalControls(window)
    window.audioSectionLabel = label(window,
        audioText('UI_PsychopatzCore_AudioSettingsTitle', 'Sounds'),
        Theme.colors.textMuted)
    local audio = getAudio()
    window.audioCheckbox = UI.CreateCheckbox(window, {
        id = 'pnc-command-hub-setting:player-speech-tts',
        label = audioText('UI_PsychopatzCore_SettingPlayerSpeechTTS',
            'Speak player dialogue with TTS'),
        target = window,
        value = audio and audio.IsPlayerSpeechEnabled
            and audio.IsPlayerSpeechEnabled() or false,
    })
    window.helpLabel = label(window,
        tr('UI_PNC_CommandHub_Settings_Help',
            'Adjust opacity, nameplate text and bar sizes, relationship feedback, child surface lifts, title-bar controls, theme, panel side, and sound here.'),
        Theme.colors.textMuted)
    window.themeButton = UI.CreateButton(window, {
        id = 'theme', title = themeTitle(), target = window,
        onclick = ISPNCCommandHubSettingsWindow.onThemeCycle,
        variant = 'quiet',
    })
    window.branchButton = UI.CreateButton(window, {
        id = 'branch', title = branchTitle(), target = window,
        onclick = ISPNCCommandHubSettingsWindow.onBranchToggle,
        variant = 'quiet',
    })
    window.statusLabel = label(window, '', Theme.colors.textMuted)
    window.resetButton = UI.CreateButton(window, {
        id = 'reset', title = tr('UI_PNC_CommandHub_Settings_Reset', 'RESET'),
        target = window, onclick = ISPNCCommandHubSettingsWindow.onReset,
        variant = 'quiet',
    })
    window.closeButton = UI.CreateButton(window, {
        id = 'close', title = tr('UI_PNC_CommandHub_Settings_Close', 'CLOSE'),
        target = window, onclick = ISPNCCommandHubSettingsWindow.onClose,
        variant = 'quiet',
    })
    window.applyButton = UI.CreateButton(window, {
        id = 'apply', title = tr('UI_PNC_CommandHub_Settings_Apply', 'APPLY'),
        target = window, onclick = ISPNCCommandHubSettingsWindow.onApply,
        variant = 'primary',
    })
end

local function installWidgetWindow(window)
    if not WidgetWindow then return end
    WidgetWindow.Install(window, {
        id = 'pnc-command-hub-settings-widget',
        onDetachedChanged = function()
            local controller = Hub.ChildController
            if controller and controller.SyncPositions then
                controller.SyncPositions()
            end
        end,
    })
end

function ISPNCCommandHubSettingsWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.fields = createSettingsFields(self)
    createSupplementalControls(self)
    self:populate()
    self:requestResponsiveLayout(true)
    installWidgetWindow(self)
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
    local nameplateTextScale = DisplaySettings.GetNameplateTextScale() * 100
    self.fields.nameplateTextScale.slider:setValue(nameplateTextScale, true)
    UI.SetLabelText(self.fields.nameplateTextScale.valueLabel,
        formatNameplateTextScale(nameplateTextScale))
    local nameplateBarScale = DisplaySettings.GetNameplateBarScale() * 100
    self.fields.nameplateBarScale.slider:setValue(nameplateBarScale, true)
    UI.SetLabelText(self.fields.nameplateBarScale.valueLabel,
        formatNameplateBarScale(nameplateBarScale))
    local relationshipFeedbackScale =
        DisplaySettings.GetRelationshipFeedbackScale() * 100
    self.fields.relationshipFeedbackScale.slider:setValue(
        relationshipFeedbackScale, true)
    UI.SetLabelText(self.fields.relationshipFeedbackScale.valueLabel,
        formatRelationshipFeedbackScale(relationshipFeedbackScale))
    local audio = getAudio()
    if self.audioCheckbox and audio and audio.IsPlayerSpeechEnabled then
        self.audioCheckbox:setChecked(audio.IsPlayerSpeechEnabled())
    end
    self.branchButton:setTitle(branchTitle())
    self.themeButton:setTitle(themeTitle())
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
require "PNC/UI/CommandHub/PNC_CommandHub_SettingsWindow_Actions"

function SettingsUI.Open(owner)
    trace("pnc_settings_window_open", "has_owner=" .. tostring(owner ~= nil))
    local window = SettingsUI.instance
    if not window then
        window = UI.NewWindow(ISPNCCommandHubSettingsWindow, {
            title = tr("UI_PNC_CommandHub_Settings_Title", "COMMAND HUB SETTINGS"),
            resizable = true,
            persistenceKey = "PNC.CommandHub.Settings",
            responsiveSpec = {
                width = 420, height = 590,
                minWidth = 340, minHeight = 590,
                maxWidth = 700, maxHeight = 760,
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
